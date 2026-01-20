//
//  ExpenseImportViewModel.swift
//  SoFar
//
//  CSV import parsing and staging for CardDetailView.
//

import Foundation
import CoreData
import CryptoKit

// MARK: - ExpenseImportViewModel
@MainActor
final class ExpenseImportViewModel: ObservableObject {

    // MARK: - LoadState
    enum LoadState: Equatable {
        case idle
        case loading
        case loaded
        case failed(String)
    }

    // MARK: - MatchQuality
    enum MatchQuality: Equatable {
        case exact
        case suggested
        case none
    }

    // MARK: - ImportBucket
    enum ImportBucket: Equatable {
        case ready
        case possible
        case possibleDuplicate
        case needsMoreData
        case payments
        case credits
    }

    // MARK: - ImportKind
    enum ImportKind: Hashable {
        case debit
        case credit
        case payment
    }

    // MARK: - ImportAs
    enum ImportAs: Hashable {
        case expense
        case income
    }

    // MARK: - ImportRow
    struct ImportRow: Identifiable, Hashable {
        let id: UUID
        var originalDescriptionText: String
        var descriptionText: String
        var transactionDate: Date?
        var amountText: String
        var categoryNameFromCSV: String
        var selectedCategoryID: NSManagedObjectID?
        var matchQuality: MatchQuality
        var isPreset: Bool
        var importKind: ImportKind
        var importAs: ImportAs
        var sourceLine: Int
        var initialBucket: ImportBucket
        var isPossibleDuplicate: Bool
        var useNameNextTime: Bool

        var amountValue: Double? {
            ExpenseImportViewModel.parseAmount(amountText)
        }

        var isCredit: Bool { importKind == .credit }
        var isPayment: Bool { importKind == .payment }
        var requiresCategorySelection: Bool { importAs == .expense }

        var isMissingCoreFields: Bool {
            let trimmed = descriptionText.trimmingCharacters(in: .whitespacesAndNewlines)
            return trimmed.isEmpty || transactionDate == nil || amountValue == nil
        }

        var isMissingData: Bool {
            if isMissingCoreFields { return true }
            if !requiresCategorySelection { return false }
            let isOther = categoryNameFromCSV.trimmingCharacters(in: .whitespacesAndNewlines)
                .caseInsensitiveCompare("Other") == .orderedSame
            if isOther, selectedCategoryID == nil { return true }
            return false
        }

        var normalizedAmountForImport: Double? {
            guard let value = amountValue else { return nil }
            switch importKind {
            case .debit:
                return abs(value)
            case .credit, .payment:
                return -abs(value)
            }
        }

        var normalizedAmountForIncomeImport: Double? {
            guard let value = amountValue else { return nil }
            return abs(value)
        }
    }

    // MARK: Published
    @Published private(set) var state: LoadState = .idle
    @Published var rows: [ImportRow] = []
    @Published private(set) var categories: [ExpenseCategory] = []

    // MARK: Inputs
    private let fileURL: URL
    private let context: NSManagedObjectContext
    private let cardUUID: UUID?
    private let cardObjectID: NSManagedObjectID?

    // MARK: Services
    private let categoryService = ExpenseCategoryService()
    private let unplannedService = UnplannedExpenseService()
    private let plannedService = PlannedExpenseService()
    private let cardService = CardService()
    private let incomeService = IncomeService()
    private let nameLearningStore: ExpenseImportNameLearningStore

    // MARK: Init
    init(card: CardItem, fileURL: URL, context: NSManagedObjectContext = CoreDataService.shared.viewContext) {
        UBPerfDI.resolve("Init.ExpenseImportViewModel", every: 1)
        self.fileURL = fileURL
        self.context = context
        self.cardUUID = card.uuid
        self.cardObjectID = card.objectID
        self.nameLearningStore = ExpenseImportNameLearningStore(
            defaults: .standard,
            workspaceID: WorkspaceService.shared.activeWorkspaceID
        )
    }

    // MARK: Load
    func load() async {
        let perfInterval = UBPerf.isEnabled ? UBPerf.signposter.beginInterval("ExpenseImportViewModel.load") : nil
        let perfStart = UBPerf.isEnabled ? DispatchTime.now().uptimeNanoseconds : 0
        defer {
            if UBPerf.isEnabled {
                if let perfInterval { UBPerf.signposter.endInterval("ExpenseImportViewModel.load", perfInterval) }
                let end = DispatchTime.now().uptimeNanoseconds
                let ms = Double(end &- perfStart) / 1_000_000.0
                let line = "ExpenseImportViewModel.load total \(String(format: "%.2f", ms))ms rows=\(self.rows.count)"
                UBPerf.logger.info("\(line, privacy: .public)")
                UBPerf.emit(line)
            }
        }

        state = .loading
        if !CoreDataService.shared.storesLoaded {
            await CoreDataService.shared.waitUntilStoresLoaded()
        }
        await UBPerf.measureAsync("ExpenseImportViewModel.refreshCategories") { await refreshCategories() }

        do {
            let parsedRows: [ImportRow]
            if UBPerfExperiments.importLoadOffMainActor {
                let url = fileURL
                parsedRows = try await UBPerf.measureAsync("ExpenseImport.parseCSVFile.detached") {
                    try await Task.detached(priority: .userInitiated) {
                        try ExpenseImportViewModel.parseCSVFileNonisolated(at: url)
                    }.value
                }
            } else {
                parsedRows = try UBPerf.measure("ExpenseImport.parseCSVFile") { try parseCSVFile(at: fileURL) }
            }
            var updated = UBPerf.measure("ExpenseImport.applyDescriptionSuggestions") { applyDescriptionSuggestions(to: parsedRows) }
            updated = UBPerf.measure("ExpenseImport.applyCategoryMatching") { applyCategoryMatching(to: updated) }
            if let cardID = resolveCardUUID() {
                let existing = UBPerf.measure("ExpenseImport.fetchExistingExpenses") { fetchExistingExpenses(for: cardID, rows: updated) }
                updated = UBPerf.measure("ExpenseImport.applyDuplicateDetection") { applyDuplicateDetection(to: updated, existing: existing) }
            }
            rows = updated
            UBPerf.measure("ExpenseImport.assignInitialBuckets") { assignInitialBuckets() }
            state = .loaded
        } catch {
            state = .failed(error.localizedDescription)
        }
    }

    // MARK: Categories
    func refreshCategories() async {
        do {
            let fetched = try categoryService.fetchAllCategories(sortedByName: true)
            categories = fetched
        } catch {
            categories = []
        }
    }

    func addCategory(name: String, hex: String) {
        do {
            _ = try categoryService.addCategory(name: name, color: hex, ensureUniqueName: true)
            Task { @MainActor in
                await refreshCategories()
                applyCategoryMatchesAfterCategoryInsert()
            }
        } catch {
            // Keep import flow resilient; the UI will surface the error via lack of insertion.
        }
    }

    // MARK: Selection Helpers
    var readyRowIDs: [UUID] {
        rows.filter { $0.initialBucket == .ready }
        .sorted { $0.sourceLine < $1.sourceLine }
        .map { $0.id }
    }

    var possibleMatchRowIDs: [UUID] {
        rows.filter { $0.initialBucket == .possible }
            .sorted { $0.sourceLine < $1.sourceLine }
            .map { $0.id }
    }

    var possibleDuplicateRowIDs: [UUID] {
        rows.filter { $0.initialBucket == .possibleDuplicate }
            .sorted { $0.sourceLine < $1.sourceLine }
            .map { $0.id }
    }

    var paymentRowIDs: [UUID] {
        rows.filter { $0.initialBucket == .payments }
            .sorted { $0.sourceLine < $1.sourceLine }
            .map { $0.id }
    }

    var creditRowIDs: [UUID] {
        rows.filter { $0.initialBucket == .credits }
            .sorted { $0.sourceLine < $1.sourceLine }
            .map { $0.id }
    }

    var missingDataRowIDs: [UUID] {
        rows.filter { $0.initialBucket == .needsMoreData }
        .sorted { $0.sourceLine < $1.sourceLine }
        .map { $0.id }
    }

    var selectableRowIDs: Set<UUID> {
        let ids = rows.filter {
            !$0.isMissingData
            && (!$0.requiresCategorySelection || $0.selectedCategoryID != nil)
        }.map { $0.id }
        return Set(ids)
    }

    var defaultSelectedIDs: Set<UUID> {
        let ids = rows.filter {
            $0.importKind == .debit
            && !$0.isMissingData
            && $0.matchQuality == .exact
            && !$0.isPossibleDuplicate
        }.map { $0.id }
        return Set(ids)
    }

    func categoryName(for objectID: NSManagedObjectID?) -> String {
        guard let objectID else { return "Select Category" }
        return categories.first(where: { $0.objectID == objectID })?.name ?? "Select Category"
    }

    func categoryHex(for objectID: NSManagedObjectID?) -> String? {
        guard let objectID else { return nil }
        return categories.first(where: { $0.objectID == objectID })?.color
    }

    // MARK: Import
    func importRows(with ids: Set<UUID>) throws {
        let importStart = UBPerf.isEnabled ? DispatchTime.now().uptimeNanoseconds : 0
        let importable = rows.filter { ids.contains($0.id) }
        let rowsToImport = importable.filter {
            !$0.isMissingData
            && (!$0.requiresCategorySelection || $0.selectedCategoryID != nil)
        }

        guard let cardID = resolveCardUUID() else {
            throw NSError(domain: "ExpenseImport", code: 1, userInfo: [NSLocalizedDescriptionKey: "Missing card identifier."])
        }

        let batchWrites = UBPerfExperiments.importBatchWrites
        var createdAnyIncome = false
        var createdAnyExpense = false
        for row in rowsToImport {
            guard let date = row.transactionDate else { continue }

            switch row.importAs {
            case .income:
                guard let amount = row.normalizedAmountForIncomeImport else { continue }
                createdAnyIncome = true
                _ = try UBPerf.measure("ExpenseImport.createIncome") {
                    try incomeService.createIncome(
                        source: row.descriptionText,
                        amount: amount,
                        date: date,
                        isPlanned: false,
                        saveImmediately: !batchWrites,
                        notifyScheduleChanged: !batchWrites
                    )
                }

            case .expense:
                guard let amount = row.normalizedAmountForImport else { continue }
                createdAnyExpense = true

                let categoryID: UUID? = {
                    guard let selected = row.selectedCategoryID,
                          let category = try? context.existingObject(with: selected) as? ExpenseCategory
                    else { return nil }
                    return category.value(forKey: "id") as? UUID
                }()
                guard let categoryID else {
                    throw NSError(domain: "ExpenseImport", code: 5, userInfo: [NSLocalizedDescriptionKey: "Missing category selection."])
                }

                _ = try UBPerf.measure("ExpenseImport.createUnplannedExpense") {
                    try unplannedService.create(
                        descriptionText: row.descriptionText,
                        amount: amount,
                        date: date,
                        cardID: cardID,
                        categoryID: categoryID,
                        saveImmediately: !batchWrites,
                        emitSideEffects: !batchWrites
                    )
                }

                if row.isPreset {
                    _ = try UBPerf.measure("ExpenseImport.createPlannedTemplate") {
                        try plannedService.createGlobalTemplate(
                            titleOrDescription: row.descriptionText,
                            plannedAmount: amount,
                            actualAmount: amount,
                            defaultTransactionDate: date,
                            categoryID: categoryID,
                            cardID: cardID,
                            saveImmediately: !batchWrites
                        )
                    }
                }
            }

            if row.useNameNextTime {
                nameLearningStore.savePreferredName(row.descriptionText, forOriginalDescription: row.originalDescriptionText)
            }
        }

        if batchWrites, context.hasChanges {
            try UBPerf.measure("ExpenseImport.context.saveBatch") { try context.save() }
            if createdAnyExpense {
                LocalNotificationScheduler.shared.recordExpenseAdded()
                Task { await LocalNotificationScheduler.shared.refreshDailyReminder() }
            }
            if createdAnyIncome {
                Task { await LocalNotificationScheduler.shared.refreshPlannedIncomeReminders() }
            }
            WidgetRefreshCoordinator.refreshAllTimelines()
        }

        if UBPerf.isEnabled {
            let end = DispatchTime.now().uptimeNanoseconds
            let ms = Double(end &- importStart) / 1_000_000.0
            let line = "ExpenseImport.importRows total \(String(format: "%.2f", ms))ms rows=\(rowsToImport.count)"
            UBPerf.logger.info("\(line, privacy: .public)")
            UBPerf.emit(line)
        }
    }

    func hasMissingCategory(in ids: Set<UUID>) -> Bool {
        rows.contains {
            ids.contains($0.id)
            && $0.requiresCategorySelection
            && !$0.isMissingData
            && $0.selectedCategoryID == nil
        }
    }

    func assignCategoryToAllSelected(ids: Set<UUID>, categoryID: NSManagedObjectID) {
        for index in rows.indices {
            let rowID = rows[index].id
            guard ids.contains(rowID), !rows[index].isMissingData else { continue }
            rows[index].selectedCategoryID = categoryID
            rows[index].matchQuality = .none
        }
    }

    // MARK: - Private
    private func resolveCardUUID() -> UUID? {
        if let uuid = cardUUID { return uuid }
        guard let objectID = cardObjectID,
              let existing = try? context.existingObject(with: objectID) as? Card
        else { return nil }
        return existing.value(forKey: "id") as? UUID
    }

    private func shouldBeInCredits(_ row: ImportRow) -> Bool {
        row.isCredit
    }

    private func applyCategoryMatchesAfterCategoryInsert() {
        guard !categories.isEmpty else { return }
        for index in rows.indices {
            if rows[index].selectedCategoryID != nil { continue }
            if rows[index].categoryNameFromCSV.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { continue }
            let updated = applyCategoryMatch(for: rows[index])
            rows[index] = updated
        }
    }

    private func applyCategoryMatching(to rows: [ImportRow]) -> [ImportRow] {
        guard !categories.isEmpty else { return rows }
        return rows.map { applyCategoryMatch(for: $0) }
    }

    private struct ExistingExpenseSnapshot {
        let description: String
        let amount: Double
        let date: Date
    }

    private func fetchExistingExpenses(for cardID: UUID, rows: [ImportRow]) -> [ExistingExpenseSnapshot] {
        guard let window = dateWindow(for: rows) else { return [] }
        let existing = (try? unplannedService.fetchForCard(cardID, in: window, sortedByDateAscending: true)) ?? []
        return existing.compactMap { expense in
            guard let date = expense.value(forKey: "transactionDate") as? Date else { return nil }
            let desc = (expense.value(forKey: "descriptionText") as? String)
                ?? (expense.value(forKey: "title") as? String) ?? ""
            return ExistingExpenseSnapshot(
                description: desc,
                amount: expense.value(forKey: "amount") as? Double ?? 0,
                date: date
            )
        }
    }

    private func dateWindow(for rows: [ImportRow]) -> DateInterval? {
        let dates = rows.compactMap { $0.transactionDate }
        guard let minDate = dates.min(), let maxDate = dates.max() else { return nil }
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: minDate)
        let endDay = calendar.startOfDay(for: maxDate)
        let end = calendar.date(byAdding: .day, value: 1, to: endDay) ?? maxDate
        return DateInterval(start: start, end: end)
    }

    private func applyDuplicateDetection(to rows: [ImportRow], existing: [ExistingExpenseSnapshot]) -> [ImportRow] {
        guard !existing.isEmpty else { return rows }
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: existing, by: { calendar.startOfDay(for: $0.date) })

        return rows.map { row in
            guard let rowDate = row.transactionDate,
                  let rowAmount = row.normalizedAmountForImport
            else { return row }

            let candidates = grouped[calendar.startOfDay(for: rowDate)] ?? []
            guard !candidates.isEmpty else { return row }

            let rowNameSource = row.originalDescriptionText.isEmpty ? row.descriptionText : row.originalDescriptionText
            let rowName = normalizedDescription(rowNameSource)
            let hasName = !rowName.isEmpty

            let isDuplicate = candidates.contains { candidate in
                var matches = 0
                if calendar.isDate(candidate.date, inSameDayAs: rowDate) {
                    matches += 1
                }
                if hasName {
                    let existingName = normalizedDescription(candidate.description)
                    if !existingName.isEmpty,
                       existingName == rowName || existingName.contains(rowName) || rowName.contains(existingName) {
                        matches += 1
                    }
                }
                let amountMatches = abs(abs(candidate.amount) - abs(rowAmount)) <= 0.01
                if amountMatches { matches += 1 }
                return matches >= 2
            }

            if isDuplicate {
                var updated = row
                updated.isPossibleDuplicate = true
                return updated
            }

            return row
        }
    }

    private func normalizedDescription(_ value: String) -> String {
        normalize(value)
    }

    private func applyDescriptionSuggestions(to rows: [ImportRow]) -> [ImportRow] {
        rows.map { row in
            var updated = row
            let original = row.originalDescriptionText.trimmingCharacters(in: .whitespacesAndNewlines)
            if let learned = nameLearningStore.preferredName(forOriginalDescription: original) {
                updated.descriptionText = learned
                return updated
            }
            updated.descriptionText = Self.suggestedExpenseName(from: original)
            return updated
        }
    }

    private func applyCategoryMatch(for row: ImportRow) -> ImportRow {
        var updated = row
        let raw = row.categoryNameFromCSV.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !raw.isEmpty else { return updated }

        if let exact = categories.first(where: { normalizedKey(for: $0.name ?? "") == normalizedKey(for: raw) }) {
            updated.selectedCategoryID = exact.objectID
            updated.matchQuality = .exact
            return updated
        }

        if let suggested = bestCategoryMatch(for: raw) {
            updated.selectedCategoryID = suggested.objectID
            updated.matchQuality = .suggested
            return updated
        }

        return updated
    }

    private func bestCategoryMatch(for raw: String) -> ExpenseCategory? {
        let rawKey = normalizedKey(for: raw)
        let rawTokens = Set(normalizedTokens(for: raw))
        var best: (ExpenseCategory, Double)? = nil

        for category in categories {
            let name = category.name ?? ""
            let categoryKey = normalizedKey(for: name)
            let nameTokens = Set(normalizedTokens(for: name))
            let synonymTokens = Set(categorySynonyms(for: categoryKey).flatMap { normalizedTokens(for: $0) })
            let combinedTokens = nameTokens.union(synonymTokens)

            let baseScore = similarityScore(lhs: rawTokens, rhs: combinedTokens, lhsRaw: rawKey, rhsRaw: categoryKey)
            let boosted = min(1.0, baseScore + categoryBoostScore(categoryKey: categoryKey, rawTokens: rawTokens))

            if boosted > (best?.1 ?? 0) {
                best = (category, boosted)
            }
        }

        guard let match = best, match.1 >= 0.40 else { return nil }
        return match.0
    }

    private func similarityScore(lhs: Set<String>, rhs: Set<String>, lhsRaw: String, rhsRaw: String) -> Double {
        if lhsRaw == rhsRaw { return 1.0 }
        if lhsRaw.contains(rhsRaw) || rhsRaw.contains(lhsRaw) { return 0.8 }
        if !lhs.isEmpty, lhs.isSubset(of: rhs) { return 0.9 }
        let intersection = lhs.intersection(rhs).count
        let maxCount = max(lhs.count, rhs.count)
        if maxCount == 0 { return 0 }
        return Double(intersection) / Double(maxCount)
    }

    private func normalize(_ value: String) -> String {
        let lowered = value.lowercased()
        let cleaned = lowered.replacingOccurrences(of: "&", with: "and")
        let allowed = cleaned.filter { $0.isLetter || $0.isNumber || $0 == " " }
        return allowed.replacingOccurrences(of: "  +", with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func normalizedTokens(for value: String) -> [String] {
        let base = normalize(value)
        let tokens = base.split(separator: " ").map { String($0) }
        return tokens.compactMap { token in
            let singular = singularize(token)
            guard !stopwords.contains(singular) else { return nil }
            return singular
        }
    }

    private func normalizedKey(for value: String) -> String {
        normalizedTokens(for: value).joined(separator: " ")
    }

    private func singularize(_ token: String) -> String {
        if token.count > 3, token.hasSuffix("ies") {
            return String(token.dropLast(3)) + "y"
        }
        if token.count > 3, token.hasSuffix("es") {
            return String(token.dropLast(2))
        }
        if token.count > 3, token.hasSuffix("s") {
            return String(token.dropLast(1))
        }
        return token
    }

    private let stopwords: Set<String> = ["and", "the", "of", "for", "with", "to", "a", "an"]

    private func categorySynonyms(for categoryKey: String) -> [String] {
        let map: [String: [String]] = [
            "bills utilities": ["utility", "utilities", "electric", "water", "internet", "phone", "mobile", "cable"],
            "cannabis": ["dispensary", "weed", "cbd"],
            "entertainment": ["movie", "movies", "theater", "music", "games", "events"],
            "food drink": ["restaurant", "restaurants", "dining", "cafe", "coffee", "bar", "food", "drink"],
            "groceries": ["grocery", "supermarket", "market"],
            "health": ["medical", "pharmacy", "doctor", "dentist", "hospital", "clinic"],
            "services": ["service", "maintenance", "repair", "cleaning", "government", "govt"],
            "shopping": ["retail", "store", "merchandise", "apparel"],
            "subscriptions": ["subscription", "membership", "recurring"],
            "transportation": ["gas", "fuel", "parking", "rideshare", "uber", "lyft", "toll", "transit", "bus", "train", "metro"],
            "travel": ["airline", "flight", "hotel", "lodging", "airbnb", "rental"]
        ]
        return map[categoryKey, default: []]
    }

    private func categoryBoostScore(categoryKey: String, rawTokens: Set<String>) -> Double {
        switch categoryKey {
        case "food drink":
            return rawTokens.intersection(["restaurant", "restaurants", "dining", "cafe", "coffee", "food", "drink"]).isEmpty ? 0 : 0.35
        case "groceries":
            return rawTokens.intersection(["grocery", "groceries", "supermarket", "market"]).isEmpty ? 0 : 0.35
        case "transportation":
            return rawTokens.intersection(["gas", "fuel", "parking", "rideshare", "uber", "lyft", "toll", "transit", "bus", "train"]).isEmpty ? 0 : 0.35
        case "health":
            return rawTokens.intersection(["medical", "pharmacy", "doctor", "dentist", "clinic", "hospital"]).isEmpty ? 0 : 0.35
        case "bills utilities":
            return rawTokens.intersection(["utility", "utilities", "electric", "water", "internet", "phone", "mobile", "cable"]).isEmpty ? 0 : 0.35
        default:
            return 0
        }
    }

    // MARK: CSV Parsing
    private func parseCSVFile(at url: URL) throws -> [ImportRow] {
        let didAccess = url.startAccessingSecurityScopedResource()
        defer {
            if didAccess { url.stopAccessingSecurityScopedResource() }
        }

        let data = try Data(contentsOf: url)
        let text = String(data: data, encoding: .utf8) ?? String(data: data, encoding: .isoLatin1) ?? ""
        guard !text.isEmpty else {
            throw NSError(domain: "ExpenseImport", code: 3, userInfo: [NSLocalizedDescriptionKey: "The CSV file is empty."])
        }

        let rows = parseCSV(text)
        guard rows.count > 1 else {
            throw NSError(domain: "ExpenseImport", code: 4, userInfo: [NSLocalizedDescriptionKey: "No rows found in the CSV file."])
        }

        let headers = rows[0].map { $0.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() }
        let dataRows = rows.dropFirst()

        let dateIndex = headerIndex(in: headers, matching: ["transaction date", "date", "posted date", "clearing date"])
        let descriptionIndex = headerIndex(in: headers, matching: ["description", "merchant", "name", "details"])
        let categoryIndex = headerIndex(in: headers, matching: ["category"])
        let typeIndex = headerIndex(in: headers, matching: ["type", "transaction type"])
        let amountIndex = headerIndex(in: headers, matching: ["amount", "amount (usd)", "amount usd", "amount (us$)"])

        return dataRows.enumerated().map { offset, row in
            let line = offset + 2
            let description = value(at: descriptionIndex, in: row)
            let dateString = value(at: dateIndex, in: row)
            let amountString = value(at: amountIndex, in: row)
            let categoryName = value(at: categoryIndex, in: row)
            let typeString = value(at: typeIndex, in: row)
            let date = parseDate(dateString)

            let kind = importKind(amountText: amountString, type: typeString, category: categoryName)
            let importAs: ImportAs = (kind == .payment) ? .income : .expense

            return ImportRow(
                id: UUID(),
                originalDescriptionText: description,
                descriptionText: description,
                transactionDate: date,
                amountText: amountString,
                categoryNameFromCSV: categoryName,
                selectedCategoryID: nil,
                matchQuality: .none,
                isPreset: false,
                importKind: kind,
                importAs: importAs,
                sourceLine: line,
                initialBucket: .needsMoreData,
                isPossibleDuplicate: false,
                useNameNextTime: false
            )
        }
    }

    private func assignInitialBuckets() {
        for index in rows.indices {
            let row = rows[index]
            let bucket: ImportBucket
            if row.isMissingData || (row.requiresCategorySelection && row.selectedCategoryID == nil) {
                bucket = .needsMoreData
            } else if row.isPossibleDuplicate {
                bucket = .possibleDuplicate
            } else if row.isPayment {
                bucket = .payments
            } else if shouldBeInCredits(row) {
                bucket = .credits
            } else if row.matchQuality == .suggested {
                bucket = .possible
            } else {
                bucket = .ready
            }
            rows[index].initialBucket = bucket
        }
    }

    private func headerIndex(in headers: [String], matching candidates: [String]) -> Int? {
        for (index, header) in headers.enumerated() {
            if candidates.contains(where: { header == $0 }) { return index }
            if candidates.contains(where: { header.contains($0) }) { return index }
        }
        return nil
    }

    private func value(at index: Int?, in row: [String]) -> String {
        guard let index, row.indices.contains(index) else { return "" }
        return row[index].trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func parseCSV(_ text: String) -> [[String]] {
        var rows: [[String]] = []
        var currentRow: [String] = []
        var currentField = ""
        var insideQuotes = false
        var iterator = text.makeIterator()

        while let char = iterator.next() {
            switch char {
            case "\"":
                if insideQuotes {
                    if let next = iterator.next() {
                        if next == "\"" {
                            currentField.append("\"")
                        } else {
                            insideQuotes = false
                            if next == "," {
                                currentRow.append(currentField)
                                currentField = ""
                            } else if next == "\n" {
                                currentRow.append(currentField)
                                rows.append(currentRow)
                                currentRow = []
                                currentField = ""
                            } else if next == "\r" {
                                continue
                            } else {
                                currentField.append(next)
                            }
                        }
                    } else {
                        insideQuotes = false
                    }
                } else {
                    insideQuotes = true
                }
            case "," where !insideQuotes:
                currentRow.append(currentField)
                currentField = ""
            case "\n" where !insideQuotes:
                currentRow.append(currentField)
                rows.append(currentRow)
                currentRow = []
                currentField = ""
            case "\r":
                continue
            default:
                currentField.append(char)
            }
        }

        if !currentField.isEmpty || !currentRow.isEmpty {
            currentRow.append(currentField)
            rows.append(currentRow)
        }

        return rows.filter { row in
            row.contains { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        }
    }

    // MARK: CSV Parsing (nonisolated; perf experiment)
    nonisolated static func parseCSVFileNonisolated(at url: URL) throws -> [ImportRow] {
        let didAccess = url.startAccessingSecurityScopedResource()
        defer {
            if didAccess { url.stopAccessingSecurityScopedResource() }
        }

        let data = try Data(contentsOf: url)
        let text = String(data: data, encoding: .utf8) ?? String(data: data, encoding: .isoLatin1) ?? ""
        guard !text.isEmpty else {
            throw NSError(domain: "ExpenseImport", code: 3, userInfo: [NSLocalizedDescriptionKey: "The CSV file is empty."])
        }

        let rows = parseCSVNonisolated(text)
        guard rows.count > 1 else {
            throw NSError(domain: "ExpenseImport", code: 4, userInfo: [NSLocalizedDescriptionKey: "No rows found in the CSV file."])
        }

        let headers = rows[0].map { $0.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() }
        let dataRows = rows.dropFirst()

        let dateIndex = headerIndexNonisolated(in: headers, matching: ["transaction date", "date", "posted date", "clearing date"])
        let descriptionIndex = headerIndexNonisolated(in: headers, matching: ["description", "merchant", "name", "details"])
        let categoryIndex = headerIndexNonisolated(in: headers, matching: ["category"])
        let typeIndex = headerIndexNonisolated(in: headers, matching: ["type", "transaction type"])
        let amountIndex = headerIndexNonisolated(in: headers, matching: ["amount", "amount (usd)", "amount usd", "amount (us$)"])

        return dataRows.enumerated().map { offset, row in
            let line = offset + 2
            let description = valueNonisolated(at: descriptionIndex, in: row)
            let dateString = valueNonisolated(at: dateIndex, in: row)
            let amountString = valueNonisolated(at: amountIndex, in: row)
            let categoryName = valueNonisolated(at: categoryIndex, in: row)
            let typeString = valueNonisolated(at: typeIndex, in: row)
            let kind = importKindNonisolated(amountText: amountString, type: typeString, category: categoryName)
            let importAs: ImportAs = (kind == .payment) ? .income : .expense
            return ImportRow(
                id: UUID(),
                originalDescriptionText: description,
                descriptionText: description,
                transactionDate: parseDateNonisolated(dateString),
                amountText: amountString,
                categoryNameFromCSV: categoryName,
                selectedCategoryID: nil,
                matchQuality: .none,
                isPreset: false,
                importKind: kind,
                importAs: importAs,
                sourceLine: line,
                initialBucket: .needsMoreData,
                isPossibleDuplicate: false,
                useNameNextTime: false
            )
        }
    }

    nonisolated private static func headerIndexNonisolated(in headers: [String], matching candidates: [String]) -> Int? {
        for (idx, header) in headers.enumerated() {
            for candidate in candidates {
                if header == candidate { return idx }
                if header.contains(candidate) { return idx }
            }
        }
        return nil
    }

    nonisolated private static func valueNonisolated(at index: Int?, in row: [String]) -> String {
        guard let index, index >= 0, index < row.count else { return "" }
        return row[index]
    }

    nonisolated private static func parseDateNonisolated(_ value: String) -> Date? {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        let formats = [
            "M/d/yyyy",
            "MM/dd/yyyy",
            "yyyy-MM-dd",
            "yyyy/MM/dd",
            "dd/MM/yyyy",
            "dd-MM-yyyy"
        ]
        for format in formats {
            let df = DateFormatter()
            df.locale = Locale(identifier: "en_US_POSIX")
            df.dateFormat = format
            if let date = df.date(from: trimmed) {
                return date
            }
        }

        let iso = ISO8601DateFormatter()
        if let date = iso.date(from: trimmed) { return date }

        return nil
    }

    nonisolated private static func importKindNonisolated(amountText: String, type: String, category: String) -> ImportKind {
        let combined = [type, category].joined(separator: " ").lowercased()
        if combined.contains("payment") || combined.contains("payments") {
            return .payment
        }
        if hasLeadingPlusNonisolated(amountText) { return .credit }
        if combined.contains("credit") || combined.contains("refund") {
            return .credit
        }
        return .debit
    }

    nonisolated private static func hasLeadingPlusNonisolated(_ value: String) -> Bool {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.hasPrefix("+")
    }

    nonisolated private static func parseCSVNonisolated(_ text: String) -> [[String]] {
        var rows: [[String]] = []
        var currentRow: [String] = []
        var currentField = ""
        var insideQuotes = false

        for char in text {
            switch char {
            case "\"":
                if insideQuotes {
                    insideQuotes = false
                } else {
                    insideQuotes = true
                }
            case "," where !insideQuotes:
                currentRow.append(currentField)
                currentField = ""
            case "\n" where !insideQuotes:
                currentRow.append(currentField)
                rows.append(currentRow)
                currentRow = []
                currentField = ""
            case "\r":
                continue
            default:
                currentField.append(char)
            }
        }

        if !currentField.isEmpty || !currentRow.isEmpty {
            currentRow.append(currentField)
            rows.append(currentRow)
        }

        return rows.filter { row in
            row.contains { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        }
    }

    private func parseDate(_ value: String) -> Date? {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        let formats = [
            "M/d/yyyy",
            "MM/dd/yyyy",
            "yyyy-MM-dd",
            "yyyy/MM/dd",
            "dd/MM/yyyy",
            "dd-MM-yyyy"
        ]
        for format in formats {
            let df = DateFormatter()
            df.locale = Locale(identifier: "en_US_POSIX")
            df.dateFormat = format
            if let date = df.date(from: trimmed) {
                return date
            }
        }

        let iso = ISO8601DateFormatter()
        if let date = iso.date(from: trimmed) { return date }

        return nil
    }

    private func importKind(amountText: String, type: String, category: String) -> ImportKind {
        let combined = [type, category].joined(separator: " ").lowercased()
        if combined.contains("payment") || combined.contains("payments") {
            return .payment
        }
        if hasLeadingPlus(amountText) { return .credit }
        if combined.contains("credit") || combined.contains("refund") {
            return .credit
        }
        return .debit
    }

    private func hasLeadingPlus(_ value: String) -> Bool {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.hasPrefix("+")
    }

    // MARK: Amount Parsing
    nonisolated static func parseAmount(_ raw: String) -> Double? {
        let stripped = raw
            .replacingOccurrences(of: "$", with: "")
            .replacingOccurrences(of: " ", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        guard !stripped.isEmpty else { return nil }

        let containsComma = stripped.contains(",")
        let containsDot = stripped.contains(".")
        let normalized: String
        if containsComma && !containsDot {
            normalized = stripped.replacingOccurrences(of: ",", with: ".")
        } else {
            normalized = stripped.replacingOccurrences(of: ",", with: "")
        }

        return Double(normalized)
    }

    // MARK: Name Suggestion (Offline, On-Device)
    nonisolated static func suggestedExpenseName(from raw: String) -> String {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return "" }

        var text = collapseWhitespace(trimmed)
        text = removeLeadingPrefixes(from: text)
        text = collapseWhitespace(
            text.replacingOccurrences(of: "*", with: " ")
                .replacingOccurrences(of: ".", with: " ")
        )

        let originalTokens = text.split(whereSeparator: { $0.isWhitespace }).map { String($0) }
        let cleanedTokens = originalTokens.map { cleanDisplayToken($0) }

        var removal = Set<Int>()

        // Cut at common separators (ex: "... ACH DEBIT ...")
        let cutIndex: Int? = cleanedTokens.firstIndex { token in
            token.caseInsensitiveCompare("ACH") == .orderedSame
        }

        // NOTE: ArraySlice hack above is unsafe; build a safe slice below.
        var indexedTokens: [(Int, String)] = []
        if let cutIndex {
            indexedTokens = Array(cleanedTokens.prefix(cutIndex)).enumerated().map { ($0.offset, $0.element) }
        } else {
            indexedTokens = cleanedTokens.enumerated().map { ($0.offset, $0.element) }
        }

        for (index, token) in indexedTokens {
            if token.isEmpty { removal.insert(index); continue }
            let upper = token.uppercased()
            if defaultNoiseTokens.contains(upper) { removal.insert(index); continue }
            if upper.hasPrefix("POS"), upper.range(of: #"\d"#, options: .regularExpression) != nil {
                removal.insert(index); continue
            }
            if containsMaskedCardFragment(token) { removal.insert(index); continue }
            if upper.range(of: #"\d{4,}"#, options: .regularExpression) != nil { removal.insert(index); continue }
            if upper.range(of: #"^(X{2,}|\*{2,})$"#, options: [.regularExpression]) != nil { removal.insert(index); continue }
            if token.count <= 2 { removal.insert(index); continue }
        }

        // Remove trailing state abbreviations, plus the immediately preceding token (usually a city/descriptor).
        let stateIndices = indexedTokens.compactMap { (index, token) -> Int? in
            let upper = token.uppercased()
            return usStateAbbreviations.contains(upper) ? index : nil
        }
        for stateIndex in stateIndices {
            removal.insert(stateIndex)
            let previousIndex = stateIndex - 1
            guard previousIndex >= 0, cleanedTokens.indices.contains(previousIndex) else { continue }
            let prev = cleanedTokens[previousIndex]
            if prev.range(of: #"^[A-Za-z]{3,}$"#, options: .regularExpression) != nil {
                removal.insert(previousIndex)
            }
        }

        var candidateTokens: [String] = []
        candidateTokens.reserveCapacity(indexedTokens.count)
        for (index, token) in indexedTokens where !removal.contains(index) {
            candidateTokens.append(token)
        }

        // If we have a short acronym-like lead token that also appears as a prefix of a longer token,
        // prefer the acronym to keep names compact (ex: "HPSO ... HPSOCOVER" -> "HPSO").
        if let first = candidateTokens.first,
           first.range(of: #"^[A-Za-z]{3,4}$"#, options: .regularExpression) != nil,
           candidateTokens.dropFirst().contains(where: { $0.uppercased().hasPrefix(first.uppercased()) && $0.count > first.count }) {
            return first
        }

        // Drop known "concatenated" tail tokens (e.g., "BURSTORALCA") when earlier words already represent the merchant.
        if candidateTokens.count >= 3 {
            let head = candidateTokens.prefix(3).joined(separator: " ").uppercased().replacingOccurrences(of: " ", with: "")
            if let last = candidateTokens.last, last.count >= 8 {
                let lastKey = last.uppercased()
                if lastKey.hasPrefix(String(head.prefix(4))) {
                    candidateTokens.removeLast()
                }
            }
        }

        candidateTokens = Array(candidateTokens.prefix(5))
        var result = collapseWhitespace(candidateTokens.joined(separator: " "))
        if result.count > 32, candidateTokens.count >= 2 {
            result = collapseWhitespace(candidateTokens.prefix(2).joined(separator: " "))
        }

        if result.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return collapseWhitespace(trimmed)
        }

        return result
    }

    nonisolated static func signatureKey(forOriginalDescription raw: String) -> String {
        let signature = canonicalSignature(forOriginalDescription: raw)
        return sha256Hex(signature)
    }

    nonisolated static func canonicalSignature(forOriginalDescription raw: String) -> String {
        let normalized = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalized.isEmpty else { return "" }
        let tokens = normalizeForSignature(normalized)
        return tokens.prefix(6).joined(separator: " ")
    }

    nonisolated private static func normalizeForSignature(_ raw: String) -> [String] {
        let lowered = raw.lowercased()
        let allowed = lowered.filter { $0.isLetter || $0.isNumber || $0 == " " }
        let collapsed = allowed.replacingOccurrences(of: "  +", with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let tokens = collapsed.split(separator: " ").map { String($0).uppercased() }
        return tokens.filter { token in
            if token.count <= 2 { return false }
            if token.range(of: #"\d"#, options: .regularExpression) != nil { return false }
            if defaultNoiseTokens.contains(token) { return false }
            return true
        }
    }

    nonisolated private static func collapseWhitespace(_ value: String) -> String {
        value.replacingOccurrences(of: #"[\s\u{00A0}]+"#, with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    nonisolated private static func removeLeadingPrefixes(from value: String) -> String {
        var result = collapseWhitespace(value)
        while true {
            let upper = result.uppercased()
            guard let prefix = leadingNoisePrefixes.first(where: { upper.hasPrefix($0) }) else { break }
            let dropCount = prefix.count
            let index = result.index(result.startIndex, offsetBy: min(dropCount, result.count))
            result = collapseWhitespace(String(result[index...]))
        }
        return result
    }

    nonisolated private static func cleanDisplayToken(_ token: String) -> String {
        let trimmed = token.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return "" }
        let filtered = trimmed.filter { $0.isLetter || $0.isNumber || $0 == "-" || $0 == "&" }
        return filtered.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    nonisolated private static func containsMaskedCardFragment(_ token: String) -> Bool {
        let upper = token.uppercased()
        if upper.range(of: #"^(X{2,}|\*{2,})\d{2,}$"#, options: .regularExpression) != nil { return true }
        if upper.range(of: #"\b(X{2,}|\*{2,})\b"#, options: .regularExpression) != nil { return true }
        if upper.range(of: #"^\w*(X{2,}|\*{2,})\d{2,}\w*$"#, options: .regularExpression) != nil { return true }
        return false
    }

    nonisolated private static func sha256Hex(_ value: String) -> String {
        let data = Data(value.utf8)
        let digest = SHA256.hash(data: data)
        return digest.map { String(format: "%02x", $0) }.joined()
    }

    nonisolated private static let leadingNoisePrefixes: [String] = [
        "RECURRING DEBIT CARD",
        "DEBIT CARD PURCHASE",
        "DEBIT CARD",
        "CREDIT CARD PURCHASE",
        "CARD PURCHASE"
    ]

    nonisolated private static let defaultNoiseTokens: Set<String> = [
        "DEBIT", "CREDIT", "CARD", "PURCHASE", "RECURRING",
        "PAYMENT", "PAYMENTS", "POS", "ONLINE", "TRANSFER", "TRANSFERS",
        "ACH", "ATM", "P2P", "FEE", "INSURANCE"
    ]

    nonisolated private static let usStateAbbreviations: Set<String> = [
        "AL","AK","AZ","AR","CA","CO","CT","DE","FL","GA","HI","ID","IL","IN","IA","KS","KY","LA","ME","MD","MA","MI","MN","MS","MO",
        "MT","NE","NV","NH","NJ","NM","NY","NC","ND","OH","OK","OR","PA","RI","SC","SD","TN","TX","UT","VT","VA","WA","WV","WI","WY","DC"
    ]
}

// MARK: - ExpenseImportNameLearningStore (On-Device)
struct ExpenseImportNameLearningStore {
    private let defaults: UserDefaults
    private let workspaceID: UUID

    init(defaults: UserDefaults, workspaceID: UUID) {
        self.defaults = defaults
        self.workspaceID = workspaceID
    }

    func preferredName(forOriginalDescription original: String) -> String? {
        let key = ExpenseImportViewModel.signatureKey(forOriginalDescription: original)
        guard let map = loadMap() else { return nil }
        return map[key]
    }

    func savePreferredName(_ preferred: String, forOriginalDescription original: String) {
        let trimmed = preferred.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        let key = ExpenseImportViewModel.signatureKey(forOriginalDescription: original)
        var map = loadMap() ?? [:]
        map[key] = trimmed
        saveMap(map)
    }

    private func storageKey() -> String {
        "expenseImport.nameLearning.v1.\(workspaceID.uuidString)"
    }

    private func loadMap() -> [String: String]? {
        guard let data = defaults.data(forKey: storageKey()) else { return nil }
        return (try? JSONDecoder().decode([String: String].self, from: data)) ?? nil
    }

    private func saveMap(_ map: [String: String]) {
        guard let data = try? JSONEncoder().encode(map) else { return }
        defaults.set(data, forKey: storageKey())
    }
}

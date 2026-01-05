//
//  ExpenseImportViewModel.swift
//  SoFar
//
//  CSV import parsing and staging for CardDetailView.
//

import Foundation
import CoreData

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
        case needsMoreData
        case payments
        case credits
    }

    // MARK: - ImportKind
    enum ImportKind: Equatable {
        case debit
        case credit
        case payment
    }

    // MARK: - ImportRow
    struct ImportRow: Identifiable, Hashable {
        let id: UUID
        var descriptionText: String
        var transactionDate: Date?
        var amountText: String
        var categoryNameFromCSV: String
        var selectedCategoryID: NSManagedObjectID?
        var matchQuality: MatchQuality
        var isPreset: Bool
        var importKind: ImportKind
        var sourceLine: Int
        var initialBucket: ImportBucket

        var amountValue: Double? {
            ExpenseImportViewModel.parseAmount(amountText)
        }

        var isCredit: Bool { importKind == .credit }
        var isPayment: Bool { importKind == .payment }

        var isMissingCoreFields: Bool {
            let trimmed = descriptionText.trimmingCharacters(in: .whitespacesAndNewlines)
            return trimmed.isEmpty || transactionDate == nil || amountValue == nil
        }

        var isMissingData: Bool {
            if isMissingCoreFields { return true }
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

    // MARK: Init
    init(card: CardItem, fileURL: URL, context: NSManagedObjectContext = CoreDataService.shared.viewContext) {
        self.fileURL = fileURL
        self.context = context
        self.cardUUID = card.uuid
        self.cardObjectID = card.objectID
    }

    // MARK: Load
    func load() async {
        state = .loading
        if !CoreDataService.shared.storesLoaded {
            await CoreDataService.shared.waitUntilStoresLoaded()
        }
        await refreshCategories()

        do {
            let parsedRows = try parseCSVFile(at: fileURL)
            rows = applyCategoryMatching(to: parsedRows)
            assignInitialBuckets()
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
        let new = ExpenseCategory(context: context)
        new.id = UUID()
        new.name = name
        new.color = hex
        WorkspaceService.shared.applyWorkspaceID(on: new)
        do {
            try context.save()
            Task { @MainActor in
                await refreshCategories()
                applyCategoryMatchesAfterCategoryInsert()
            }
        } catch {
            if context.hasChanges { context.rollback() }
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
            && $0.selectedCategoryID != nil
        }.map { $0.id }
        return Set(ids)
    }

    var defaultSelectedIDs: Set<UUID> {
        let ids = rows.filter {
            $0.importKind == .debit
            && !$0.isMissingData
            && $0.matchQuality == .exact
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
        let importable = rows.filter { ids.contains($0.id) }
        let rowsToImport = importable.filter {
            !$0.isMissingData
            && $0.selectedCategoryID != nil
        }

        guard let cardID = resolveCardUUID() else {
            throw NSError(domain: "ExpenseImport", code: 1, userInfo: [NSLocalizedDescriptionKey: "Missing card identifier."])
        }

        let card = try cardService.findCard(byID: cardID)
        for row in rowsToImport {
            guard let amount = row.normalizedAmountForImport,
                  let date = row.transactionDate
            else { continue }

            let categoryID: UUID? = {
                guard let selected = row.selectedCategoryID,
                      let category = try? context.existingObject(with: selected) as? ExpenseCategory
                else { return nil }
                return category.value(forKey: "id") as? UUID
            }()
            guard let categoryID else {
                throw NSError(domain: "ExpenseImport", code: 5, userInfo: [NSLocalizedDescriptionKey: "Missing category selection."])
            }

            _ = try unplannedService.create(
                descriptionText: row.descriptionText,
                amount: amount,
                date: date,
                cardID: cardID,
                categoryID: categoryID
            )

            if row.isPreset {
                let template = try plannedService.createGlobalTemplate(
                    titleOrDescription: row.descriptionText,
                    plannedAmount: amount,
                    actualAmount: amount,
                    defaultTransactionDate: date
                )

                if let categoryObjectID = row.selectedCategoryID,
                   let category = try? context.existingObject(with: categoryObjectID) as? ExpenseCategory {
                    template.expenseCategory = category
                }
                if let card {
                    template.card = card
                }
                if context.hasChanges {
                    try context.save()
                }
            }
        }
    }

    func hasMissingCategory(in ids: Set<UUID>) -> Bool {
        rows.contains { ids.contains($0.id) && !$0.isMissingData && $0.selectedCategoryID == nil }
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

            return ImportRow(
                id: UUID(),
                descriptionText: description,
                transactionDate: date,
                amountText: amountString,
                categoryNameFromCSV: categoryName,
                selectedCategoryID: nil,
                matchQuality: .none,
                isPreset: false,
                importKind: kind,
                sourceLine: line,
                initialBucket: .needsMoreData
            )
        }
    }

    private func assignInitialBuckets() {
        for index in rows.indices {
            let row = rows[index]
            let bucket: ImportBucket
            if row.isMissingData || row.selectedCategoryID == nil {
                bucket = .needsMoreData
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
}

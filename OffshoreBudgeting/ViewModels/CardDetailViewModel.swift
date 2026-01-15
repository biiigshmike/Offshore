//
//  CardDetailViewModel.swift
//  SoFar
//
//  Shows advanced details for a single Card:
//  - Total variable spend
//  - Breakdown by ExpenseCategory
//  - List of expenses with search
//

import Foundation
import SwiftUI
import CoreData

// MARK: - CardCategoryTotal
struct CardCategoryTotal: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let amount: Double
    let colorHex: String?
    let categoryObjectID: NSManagedObjectID?
    
    var color: Color {
        UBColorFromHex(colorHex) ?? .secondary
    }
}

// MARK: - CardExpense
/// Unified expense model for card details, combining planned and unplanned expenses.
struct CardExpense: Identifiable, Hashable {
    let objectID: NSManagedObjectID?
    let uuid: UUID?
    let description: String
    let amount: Double
    let date: Date?
    let category: ExpenseCategory?
    let isPlanned: Bool
    let isPreset: Bool

    var id: String {
        if let oid = objectID { return oid.uriRepresentation().absoluteString }
        if let uuid { return "uuid:\(uuid.uuidString)" }
        return "temp:\(description)\(date?.timeIntervalSince1970 ?? 0)"
    }
}

// MARK: - CardDetailLoadState
enum CardDetailLoadState: Equatable {
    case initial
    case loading
    // expenses: actual-only (counts toward totals)
    case loaded(total: Double, categories: [CardCategoryTotal], expenses: [CardExpense])
    case empty
    case error(String)
}

enum CardDetailViewModelError: LocalizedError {
    case missingObjectID
    case expenseNotFound
    case unsupportedExpenseType

    var errorDescription: String? {
        switch self {
        case .missingObjectID:
            return "This expense could not be identified for deletion."
        case .expenseNotFound:
            return "The expense could not be found. It may have already been removed."
        case .unsupportedExpenseType:
            return "This expense could not be deleted because its data type was unexpected."
        }
    }
}

// MARK: - CardDetailViewModel
@MainActor
final class CardDetailViewModel: ObservableObject {

    // MARK: Inputs
    let card: CardItem
    // Date interval used to scope fetches. Defaults to the current budget period's range.
    private(set) var allowedInterval: DateInterval?
    
    // MARK: Services
    private let unplannedService = UnplannedExpenseService()
    private let plannedService = PlannedExpenseService()
    private let viewContext: NSManagedObjectContext
    
    // MARK: Outputs
    @Published var state: CardDetailLoadState = .initial
    @Published var searchText: String = ""
    // Segment & sorting state
    enum Segment { case planned, variable, all }
    @Published var segment: Segment = .planned
    enum Sort: String, CaseIterable, Identifiable { case titleAZ, amountLowHigh, amountHighLow, dateOldNew, dateNewOld; var id: String { rawValue } }
    @Published var sort: Sort = .dateNewOld
    // Category filter (by Core Data object identity when available)
    @Published var selectedCategoryID: NSManagedObjectID? = nil

    // Filtered view of expenses
    var filteredExpenses: [CardExpense] {
        guard case .loaded(_, _, let expensesAll) = state else { return [] }
        // Segment base
        var items: [CardExpense]
        switch segment {
        case .planned:
            items = expensesAll.filter { $0.isPlanned }
        case .variable:
            items = expensesAll.filter { !$0.isPlanned }
        case .all:
            items = expensesAll
        }
        // Category filter
        if let target = selectedCategoryID {
            items = items.filter { $0.category?.objectID == target }
        }
        // Search filter
        if !searchText.isEmpty {
            let q = searchText.lowercased()
            let df = DateFormatter(); df.dateStyle = .medium
            items = items.filter { exp in
                if exp.description.lowercased().contains(q) { return true }
                if let date = exp.date, df.string(from: date).lowercased().contains(q) { return true }
                if let name = exp.category?.name?.lowercased(), name.contains(q) { return true }
                return false
            }
        }
        // Sort
        items = applySort(sort, to: items)
        return items
    }

    // Upcoming section removed; no filteredUpcoming

    /// Category totals derived from the currently filtered expenses
    var filteredCategories: [CardCategoryTotal] {
        guard case .loaded = state else { return [] }
        return buildCategories(from: filteredExpenses)
    }

    /// Total from current filters (used by UI Total Spent section)
    var filteredTotal: Double { filteredExpenses.reduce(0) { $0 + $1.amount } }
    
    // MARK: Init
    init(card: CardItem, allowedInterval: DateInterval? = nil, context: NSManagedObjectContext = CoreDataService.shared.viewContext) {
        self.card = card
        // Default to current workspace budget period range if not provided
        if let allowedInterval {
            self.allowedInterval = allowedInterval
        } else {
            let p = WorkspaceService.shared.currentBudgetPeriod(in: context)
            let r = p.range(containing: Date())
            self.allowedInterval = DateInterval(start: r.start, end: r.end)
        }
        self.viewContext = context
    }
    
    // MARK: load()
    func load() async {
        // Resolve a UUID for this card. If missing but we have an objectID,
        // attempt to read/write a UUID on the managed object so downstream
        // fetches can proceed.
        var resolvedUUID: UUID? = card.uuid
        if resolvedUUID == nil, let oid = card.objectID {
            if let managed = try? viewContext.existingObject(with: oid) as? Card {
                if let current = managed.value(forKey: "id") as? UUID {
                    resolvedUUID = current
                } else {
                    let newID = UUID()
                    managed.setValue(newID, forKey: "id")
                    do { try viewContext.save() } catch { /* fall through with nil UUID */ }
                    resolvedUUID = newID
                }
            }
        }
        guard let uuid = resolvedUUID else {
            state = .error("Missing card ID")
            return
        }
        let shouldShowLoadingState: Bool
        switch state {
        case .initial, .loading, .error:
            shouldShowLoadingState = true
        default:
            shouldShowLoadingState = false
        }
        if shouldShowLoadingState { state = .loading }
        do {
            let unplanned = try unplannedService.fetchForCard(uuid, in: allowedInterval, sortedByDateAscending: false)
            let planned: [PlannedExpense]
            if let interval = allowedInterval {
                planned = try plannedService.fetchForCard(uuid, in: interval, sortedByDateAscending: false)
            } else {
                planned = try plannedService.fetchForCard(uuid, sortedByDateAscending: false)
            }

            // Map unplanned (variable) expenses – always actual spend
            let mappedUnplanned: [CardExpense] = unplanned.map { exp in
                let desc = (exp.value(forKey: "descriptionText") as? String)
                    ?? (exp.value(forKey: "title") as? String) ?? ""
                let uuid = exp.value(forKey: "id") as? UUID
                let cat = exp.value(forKey: "expenseCategory") as? ExpenseCategory
                return CardExpense(objectID: exp.objectID,
                                   uuid: uuid,
                                   description: desc,
                                   amount: exp.value(forKey: "amount") as? Double ?? 0,
                                   date: exp.value(forKey: "transactionDate") as? Date,
                                   category: cat,
                                   isPlanned: false,
                                   isPreset: false)
            }

            // Split planned expenses into actuals vs upcoming, with duplicate guard
            // for template-children duplicated under the same budget.
            var seenPlannedKeys = Set<String>()
            let plannedActuals: [CardExpense] = planned.compactMap { exp in
                guard exp.actualAmount != 0 else { return nil }
                // Build a strict key only when it's a template child; otherwise don't dedupe.
                if let templateID = exp.globalTemplateID, let budget = exp.budget {
                    let dateKey = String(format: "%.0f", (exp.transactionDate ?? .distantPast).timeIntervalSince1970)
                    let key = "\(templateID.uuidString)|\(budget.objectID.uriRepresentation().absoluteString)|\(dateKey)|\(exp.actualAmount)|\(exp.plannedAmount)"
                    if seenPlannedKeys.contains(key) { return nil }
                    seenPlannedKeys.insert(key)
                }

                let desc = (exp.value(forKey: "descriptionText") as? String)
                    ?? (exp.value(forKey: "title") as? String) ?? ""
                let uuid = exp.value(forKey: "id") as? UUID
                let cat = exp.expenseCategory
                return CardExpense(objectID: exp.objectID,
                                   uuid: uuid,
                                   description: desc,
                                   amount: exp.actualAmount,
                                   date: exp.transactionDate,
                                   category: cat,
                                   isPlanned: true,
                                   isPreset: false)
            }

            // Remove upcoming/planned-only and template mapping from card details

            // Build final collections
            let actualCombined = (mappedUnplanned + plannedActuals).sorted { (a, b) in
                let ad = a.date ?? .distantPast
                let bd = b.date ?? .distantPast
                return ad > bd
            }
            if actualCombined.isEmpty {
                state = .empty
                return
            }

            let total = actualCombined.reduce(0) { $0 + $1.amount }
            let categories = buildCategories(from: actualCombined)
            state = .loaded(total: total, categories: categories, expenses: actualCombined)
        } catch {
            state = .error(error.localizedDescription)
        }
    }

    /// Update the date range used for fetches and reload.
    func setDateRange(_ start: Date, _ end: Date) {
        self.allowedInterval = DateInterval(start: start, end: end)
    }

    func delete(expense: CardExpense) async throws {
        guard let objectID = expense.objectID else {
            AppLog.ui.error("CardDetailViewModel.delete missing objectID for expense id=\(expense.id)")
            throw CardDetailViewModelError.missingObjectID
        }

        do {
            let managedObject: NSManagedObject
            if let obj = try? viewContext.existingObject(with: objectID) {
                managedObject = obj
            } else {
                AppLog.ui.error("CardDetailViewModel.delete missing managed object for id=\(objectID)")
                throw CardDetailViewModelError.expenseNotFound
            }

            if expense.isPlanned {
                guard let planned = managedObject as? PlannedExpense else {
                    AppLog.ui.error("CardDetailViewModel.delete unexpected managed object type for planned expense: \(type(of: managedObject))")
                    throw CardDetailViewModelError.unsupportedExpenseType
                }
                try plannedService.delete(planned)
            } else {
                guard let unplanned = managedObject as? UnplannedExpense else {
                    AppLog.ui.error("CardDetailViewModel.delete unexpected managed object type for unplanned expense: \(type(of: managedObject))")
                    throw CardDetailViewModelError.unsupportedExpenseType
                }
                try unplannedService.delete(unplanned)
            }

            if viewContext.hasChanges {
                try viewContext.save()
            }

        } catch let error as CardDetailViewModelError {
            AppLog.ui.error("CardDetailViewModel.delete error: \(error.localizedDescription)")
            throw error
        } catch {
            AppLog.ui.error("CardDetailViewModel.delete error: \(error.localizedDescription)")
            throw error
        }
    }

    /// Builds category totals from a list of expenses
    private func buildCategories(from expenses: [CardExpense]) -> [CardCategoryTotal] {
        // Bucket by category object identity primarily; fall back to name when missing.
        struct BucketKey: Hashable { let objectIDURI: URL?; let name: String }
        var buckets: [BucketKey: (amount: Double, colorHex: String?, objectID: NSManagedObjectID?)] = [:]
        for exp in expenses {
            let amount = exp.amount
            let name = (exp.category?.name ?? "Uncategorized").trimmingCharacters(in: .whitespacesAndNewlines)
            let objectID = exp.category?.objectID
            let uri = objectID?.uriRepresentation()
            let key = BucketKey(objectIDURI: uri, name: name)
            let hex = exp.category?.color
            let current = buckets[key] ?? (0, hex, objectID)
            buckets[key] = (current.amount + amount, current.colorHex ?? hex, current.objectID ?? objectID)
        }
        return buckets
            .map { (k, v) in CardCategoryTotal(name: k.name, amount: v.amount, colorHex: v.colorHex, categoryObjectID: v.objectID) }
            .sorted { $0.amount > $1.amount }
    }

    private func applySort(_ sort: Sort, to items: [CardExpense]) -> [CardExpense] {
        switch sort {
        case .titleAZ:
            return items.sorted { a, b in a.description.localizedCaseInsensitiveCompare(b.description) == .orderedAscending }
        case .amountLowHigh:
            return items.sorted { a, b in a.amount < b.amount }
        case .amountHighLow:
            return items.sorted { a, b in a.amount > b.amount }
        case .dateOldNew:
            return items.sorted { a, b in (a.date ?? .distantPast) < (b.date ?? .distantPast) }
        case .dateNewOld:
            return items.sorted { a, b in (a.date ?? .distantPast) > (b.date ?? .distantPast) }
        }
    }
}

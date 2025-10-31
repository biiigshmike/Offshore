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

// MARK: - Local Hex Color Helper
fileprivate func UBColorFromHex(_ hex: String?) -> Color? {
    guard var value = hex?.trimmingCharacters(in: .whitespacesAndNewlines), !value.isEmpty else { return nil }
    if value.hasPrefix("#") { value.removeFirst() }
    guard value.count == 6, let intVal = Int(value, radix: 16) else { return nil }
    let r = Double((intVal >> 16) & 0xFF) / 255.0
    let g = Double((intVal >> 8) & 0xFF) / 255.0
    let b = Double(intVal & 0xFF) / 255.0
    return Color(red: r, green: g, blue: b)
}

// MARK: - CardCategoryTotal
struct CardCategoryTotal: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let amount: Double
    let colorHex: String?
    
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
    let allowedInterval: DateInterval?   // nil = all time
    
    // MARK: Services
    private let unplannedService = UnplannedExpenseService()
    private let plannedService = PlannedExpenseService()
    private let viewContext: NSManagedObjectContext
    
    // MARK: Outputs
    @Published var state: CardDetailLoadState = .initial
    @Published var searchText: String = ""

    // Filtered view of expenses
    var filteredExpenses: [CardExpense] {
        guard case .loaded(_, _, let expenses) = state else { return [] }
        guard !searchText.isEmpty else { return expenses }

        let q = searchText.lowercased()
        let df = DateFormatter()
        df.dateStyle = .medium

        return expenses.filter { exp in
            if exp.description.lowercased().contains(q) { return true }
            if let date = exp.date, df.string(from: date).lowercased().contains(q) { return true }
            if let name = exp.category?.name?.lowercased(), name.contains(q) { return true }
            return false
        }
    }

    // Upcoming section removed; no filteredUpcoming

    /// Category totals derived from the currently filtered expenses
    var filteredCategories: [CardCategoryTotal] {
        guard case .loaded = state else { return [] }
        return buildCategories(from: filteredExpenses)
    }
    
    // MARK: Init
    init(card: CardItem, allowedInterval: DateInterval? = nil, context: NSManagedObjectContext = CoreDataService.shared.viewContext) {
        self.card = card
        self.allowedInterval = allowedInterval
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

            if case .loaded(_, _, var expenses) = state {
                if let idx = expenses.firstIndex(of: expense) {
                    expenses.remove(at: idx)
                }

                if expenses.isEmpty {
                    withAnimation { state = .empty }
                } else {
                    let total = expenses.reduce(0) { $0 + $1.amount }
                    let categories = buildCategories(from: expenses)
                    withAnimation {
                        state = .loaded(total: total, categories: categories, expenses: expenses)
                    }
                }
            } else {
                await load()
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
        var buckets: [String: (amount: Double, colorHex: String?)] = [:]
        for exp in expenses {
            let amount = exp.amount
            let name = exp.category?.name ?? "Uncategorized"
            let hex = exp.category?.color
            let current = buckets[name] ?? (0, hex)
            buckets[name] = (current.amount + amount, current.colorHex ?? hex)
        }
        return buckets
            .map { CardCategoryTotal(name: $0.key, amount: $0.value.amount, colorHex: $0.value.colorHex) }
            .sorted { $0.amount > $1.amount }
    }
}

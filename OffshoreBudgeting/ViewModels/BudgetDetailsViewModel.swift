//
//  BudgetDetailsViewModel.swift
//  SoFar
//
//  View model for Budget Details. Loads a budget by objectID,
//  fetches planned & unplanned expenses in the current filter window,
//  and exposes filtered/sorted arrays for display.
//

import Foundation
import CoreData
import SwiftUI

// MARK: - BudgetDetailsViewModel
@MainActor
final class BudgetDetailsViewModel: ObservableObject {
    deinit {
        AppLog.viewModel.debug("BudgetDetailsViewModel.deinit – objectID: \(self.budgetObjectID)")
    }

    // MARK: Inputs
    let budgetObjectID: NSManagedObjectID

    // MARK: Core Data
    private let context: NSManagedObjectContext
    @Published private(set) var budget: Budget?

    // Services
    private let unplannedService = UnplannedExpenseService()

    // MARK: Filter/Search/Sort
    enum Segment: String, CaseIterable, Identifiable { case planned, variable; var id: String { rawValue } }
    enum SortOption: String, CaseIterable, Identifiable {
        case titleAZ, amountLowHigh, amountHighLow, dateOldNew, dateNewOld
        var id: String { rawValue }
    }

    struct BudgetDetailsAlert: Identifiable {
        enum Kind {
            case error(message: String)
        }
        let id = UUID()
        let kind: Kind
    }

    enum LoadState: Equatable {
        case idle
        case loading
        case loaded
        case failed(message: String)
    }

    @Published var selectedSegment: Segment = .planned
    @Published var searchQuery: String = ""

    // MARK: Date Window
    @Published var startDate: Date = Date() // set after load
    @Published var endDate: Date = Date()   // set after load
    private var didInitializeDateWindow = false

    // MARK: Sort
    @Published var sort: SortOption = .dateNewOld

    // MARK: Loaded data (derived)
    @Published private(set) var loadState: LoadState = .idle
    @Published var alert: BudgetDetailsAlert?
    @Published private(set) var summary: BudgetSummary?
    @Published private(set) var incomeTotals: IncomeTotals = .zero
    @Published private(set) var firstPlannedExpenseUUID: UUID?

    /// Tracks the first load to avoid resetting `loadState` if multiple observers request it simultaneously.
    private var isInitialLoadInFlight = false
    private var isLoadInFlight = false
    private var shouldReloadAfterCurrentRun = false

    struct IncomeTotals: Equatable {
        var planned: Double
        var actual: Double

        static let zero = IncomeTotals(planned: 0, actual: 0)
    }

    nonisolated private static func normalizedCategoryName(_ name: String) -> String {
        name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }

    nonisolated private static func fallbackCategoryURI(for name: String) -> URL {
        let encoded = name.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? UUID().uuidString
        return URL(string: "offshore-local://category/\(encoded)") ?? URL(string: "offshore-local://category/unknown")!
    }

    // MARK: Init
    init(budgetObjectID: NSManagedObjectID,
         context: NSManagedObjectContext = CoreDataService.shared.viewContext) {
        self.budgetObjectID = budgetObjectID
        self.context = context
        AppLog.viewModel.debug("BudgetDetailsViewModel.init – objectID: \(self.budgetObjectID)")
    }

    // MARK: Public API

    /// Loads budget, initializes date window, and fetches rows.
    func load() async {
        // Fast-path: if we already resolved the budget and initialized the
        // date window, avoid re-running the full load. Row refreshes are
        // triggered explicitly by user actions (onSaved/onTotalsChanged)
        // and lists update via @FetchRequest.
        if loadState == .loaded, budget != nil, didInitializeDateWindow {
            AppLog.viewModel.debug("BudgetDetailsViewModel.load() no-op – already loaded")
            return
        }

        if isLoadInFlight {
            shouldReloadAfterCurrentRun = true
            AppLog.viewModel.debug("BudgetDetailsViewModel.load() coalesced – load already in flight")
            return
        }

        isLoadInFlight = true
        AppLog.viewModel.debug("BudgetDetailsViewModel.load() started – current state: \(String(describing: self.loadState))")
        defer {
            isLoadInFlight = false
            if shouldReloadAfterCurrentRun {
                shouldReloadAfterCurrentRun = false
                AppLog.viewModel.debug("BudgetDetailsViewModel.load() scheduling coalesced reload")
                Task { [weak self] in
                    await self?.load()
                }
            }
        }

        if budget != nil, didInitializeDateWindow {
            await refreshRows()
            if case .failed = loadState {
                // Preserve failure state if we previously surfaced an error.
            } else {
                loadState = .loaded
                AppLog.viewModel.debug("BudgetDetailsViewModel.load() reused existing budget – transitioning to .loaded")
            }
            return
        }

        if isInitialLoadInFlight {
            AppLog.viewModel.debug("BudgetDetailsViewModel.load() exiting early – initial load already in flight")
            return
        }

        isInitialLoadInFlight = true
        defer { isInitialLoadInFlight = false }

        loadState = .loading
        AppLog.viewModel.debug("BudgetDetailsViewModel.load() awaiting persistent stores…")
        if !CoreDataService.shared.storesLoaded {
            await CoreDataService.shared.waitUntilStoresLoaded()
        }
        AppLog.viewModel.debug("BudgetDetailsViewModel.load() continuing – storesLoaded: \(CoreDataService.shared.storesLoaded)")

        // Resolve the Budget instance (use existingObject to avoid stale faults)
        let resolvedBudget: Budget?
        if let b = try? context.existingObject(with: budgetObjectID) as? Budget {
            resolvedBudget = b
        } else {
            resolvedBudget = context.object(with: budgetObjectID) as? Budget
        }

        guard let budget = resolvedBudget else {
            let message = "We couldn't load this budget. It may have been deleted or moved."
            AppLog.viewModel.error("BudgetDetailsViewModel failed to resolve budget with objectID: \(String(describing: self.budgetObjectID))")
            loadState = .failed(message: message)
            alert = BudgetDetailsAlert(kind: .error(message: message))
            return
        }

        self.budget = budget

        let defaultStart = budget.startDate ?? Month.start(of: Date())
        let defaultEnd   = budget.endDate ?? Month.end(of: Date())

        if !didInitializeDateWindow {
            startDate = defaultStart
            endDate = defaultEnd
            didInitializeDateWindow = true
        }

        await refreshRows()
        loadState = .loaded
        AppLog.viewModel.debug("BudgetDetailsViewModel.load() finished – transitioning to .loaded")
    }

    /// Re-fetches rows for current filters (date window driven on fetch).
    func refreshRows() async {
        struct CategoryRow {
            let name: String
            let hex: String?
            let uri: URL
        }
        struct RefreshResult {
            let summary: BudgetSummary?
            let incomeTotals: IncomeTotals
            let firstPlannedExpenseUUID: UUID?
        }

        let periodStart = self.startDate
        let periodEnd = self.endDate
        let range = normalizedRange()
        let budgetObjectID = self.budgetObjectID
        let sort = self.sort
        let workspaceID = WorkspaceService.shared.activeWorkspaceID
        let container = CoreDataService.shared.container
        let bg = container.newBackgroundContext()

        let result: RefreshResult = await bg.perform {
            guard let budget = try? bg.existingObject(with: budgetObjectID) as? Budget else {
                return RefreshResult(summary: nil, incomeTotals: .zero, firstPlannedExpenseUUID: nil)
            }

            let budgetName = budget.name ?? "Untitled"
            let start = range.lowerBound
            let end = range.upperBound

            // Planned expenses (budget-linked)
            let plannedReq = NSFetchRequest<PlannedExpense>(entityName: "PlannedExpense")
            plannedReq.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
                NSPredicate(format: "budget == %@", budget),
                NSPredicate(format: "transactionDate >= %@ AND transactionDate <= %@", start as NSDate, end as NSDate),
                WorkspaceService.predicate(for: workspaceID)
            ])
            plannedReq.sortDescriptors = Self.plannedSortDescriptors(for: sort)
            plannedReq.fetchBatchSize = 128
            plannedReq.returnsObjectsAsFaults = true
            let plannedRows = (try? bg.fetch(plannedReq)) ?? []

            // Variable expenses (budget via ANY card.budget.id)
            let variableReq = NSFetchRequest<UnplannedExpense>(entityName: "UnplannedExpense")
            let budgetID = budget.value(forKey: "id") as? UUID
            let budgetPredicate: NSPredicate = {
                if let budgetID {
                    return NSPredicate(format: "ANY card.budget.id == %@", budgetID as CVarArg)
                } else {
                    // Fallback: any card's budget relationship contains this budget object
                    return NSPredicate(format: "ANY card.budget == %@", budget)
                }
            }()
            variableReq.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
                NSPredicate(format: "transactionDate >= %@ AND transactionDate <= %@", start as NSDate, end as NSDate),
                budgetPredicate,
                WorkspaceService.predicate(for: workspaceID)
            ])
            variableReq.fetchBatchSize = 128
            variableReq.sortDescriptors = [NSSortDescriptor(key: "transactionDate", ascending: false)]
            variableReq.returnsObjectsAsFaults = true
            let variableRows = (try? bg.fetch(variableReq)) ?? []

            // All categories (for zero rows)
            let catReq = NSFetchRequest<ExpenseCategory>(entityName: "ExpenseCategory")
            catReq.predicate = WorkspaceService.predicate(for: workspaceID)
            catReq.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true, selector: #selector(NSString.localizedCaseInsensitiveCompare(_:)))]
            let cats = (try? bg.fetch(catReq)) ?? []
            let allCats: [CategoryRow] = cats.compactMap { cat in
                let name = (cat.name ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
                guard !name.isEmpty else { return nil }
                return CategoryRow(name: name, hex: cat.color, uri: cat.objectID.uriRepresentation())
            }

            // Income totals
            let incomeTotals: IncomeTotals = {
                if let totals = try? BudgetIncomeCalculator.totals(
                    for: DateInterval(start: start, end: end),
                    context: bg,
                    workspaceID: workspaceID
                ) {
                    return IncomeTotals(planned: totals.planned, actual: totals.actual)
                }
                return .zero
            }()

            // First planned UUID (for UI-test scroll stabilization)
            let firstPlannedUUID = plannedRows.first?.value(forKey: "id") as? UUID

            // Build planned + variable breakdown maps (exclude Uncategorized)
            var plannedCatMap: [String: (hex: String?, total: Double, uri: URL?)] = [:]
            var plannedCapDefaults: [String: Double] = [:]
            var variableCatMap: [String: (hex: String?, total: Double, uri: URL?)] = [:]

            var plannedPlannedTotal: Double = 0
            var plannedActualTotal: Double = 0
            for e in plannedRows {
                plannedPlannedTotal += e.plannedAmount
                plannedActualTotal += e.actualAmount
                guard let rawName = e.expenseCategory?.name else { continue }
                let name = rawName.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !name.isEmpty else { continue }
                let existing = plannedCatMap[name] ?? (hex: e.expenseCategory?.color, total: 0, uri: e.expenseCategory?.objectID.uriRepresentation())
                plannedCatMap[name] = (
                    hex: e.expenseCategory?.color ?? existing.hex,
                    total: existing.total + e.actualAmount,
                    uri: existing.uri ?? e.expenseCategory?.objectID.uriRepresentation()
                )
                let norm = Self.normalizedCategoryName(name)
                plannedCapDefaults[norm, default: 0] += e.plannedAmount
            }

            var variableTotal: Double = 0
            for e in variableRows {
                variableTotal += e.amount
                guard let rawName = e.expenseCategory?.name else { continue }
                let name = rawName.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !name.isEmpty else { continue }
                let existing = variableCatMap[name] ?? (hex: e.expenseCategory?.color, total: 0, uri: e.expenseCategory?.objectID.uriRepresentation())
                variableCatMap[name] = (
                    hex: e.expenseCategory?.color ?? existing.hex,
                    total: existing.total + e.amount,
                    uri: existing.uri ?? e.expenseCategory?.objectID.uriRepresentation()
                )
            }

            // Union with all categories to ensure stable/complete breakdowns
            for cat in allCats {
                if plannedCatMap[cat.name] == nil {
                    plannedCatMap[cat.name] = (hex: cat.hex, total: 0, uri: cat.uri)
                } else if plannedCatMap[cat.name]?.uri == nil {
                    plannedCatMap[cat.name]?.uri = cat.uri
                }
                if variableCatMap[cat.name] == nil {
                    variableCatMap[cat.name] = (hex: cat.hex, total: 0, uri: cat.uri)
                } else if variableCatMap[cat.name]?.uri == nil {
                    variableCatMap[cat.name]?.uri = cat.uri
                }
            }

            let plannedBreakdown = plannedCatMap
                .map { entry in
                    let uri = entry.value.uri ?? Self.fallbackCategoryURI(for: entry.key)
                    return BudgetSummary.CategorySpending(
                        categoryURI: uri,
                        categoryName: entry.key,
                        hexColor: entry.value.hex,
                        amount: entry.value.total
                    )
                }
                .sorted { lhs, rhs in
                    if lhs.amount == rhs.amount {
                        return lhs.categoryName.localizedCaseInsensitiveCompare(rhs.categoryName) == .orderedAscending
                    }
                    return lhs.amount > rhs.amount
                }

            let variableBreakdown = variableCatMap
                .map { entry in
                    let uri = entry.value.uri ?? Self.fallbackCategoryURI(for: entry.key)
                    return BudgetSummary.CategorySpending(
                        categoryURI: uri,
                        categoryName: entry.key,
                        hexColor: entry.value.hex,
                        amount: entry.value.total
                    )
                }
                .sorted { lhs, rhs in
                    if lhs.amount == rhs.amount {
                        return lhs.categoryName.localizedCaseInsensitiveCompare(rhs.categoryName) == .orderedAscending
                    }
                    return lhs.amount > rhs.amount
                }

            let categoryBreakdown = (plannedBreakdown + variableBreakdown)
                .reduce(into: [String: BudgetSummary.CategorySpending]()) { dict, item in
                    let existing = dict[item.categoryName]
                    let sum = (existing?.amount ?? 0) + item.amount
                    dict[item.categoryName] = BudgetSummary.CategorySpending(
                        categoryURI: existing?.categoryURI ?? item.categoryURI,
                        categoryName: item.categoryName,
                        hexColor: existing?.hexColor ?? item.hexColor,
                        amount: sum
                    )
                }
                .values
                .sorted { $0.amount > $1.amount }

            let summary = BudgetSummary(
                id: budgetObjectID,
                budgetName: budgetName,
                periodStart: periodStart,
                periodEnd: periodEnd,
                categoryBreakdown: categoryBreakdown,
                plannedCategoryBreakdown: plannedBreakdown,
                variableCategoryBreakdown: variableBreakdown,
                plannedCategoryDefaultCaps: plannedCapDefaults,
                variableExpensesTotal: variableTotal,
                plannedExpensesPlannedTotal: plannedPlannedTotal,
                plannedExpensesActualTotal: plannedActualTotal,
                potentialIncomeTotal: incomeTotals.planned,
                actualIncomeTotal: incomeTotals.actual
            )

            return RefreshResult(
                summary: summary,
                incomeTotals: incomeTotals,
                firstPlannedExpenseUUID: firstPlannedUUID
            )
        }

        self.summary = result.summary
        self.incomeTotals = result.incomeTotals
        self.firstPlannedExpenseUUID = result.firstPlannedExpenseUUID
        AppLog.viewModel.debug("BudgetDetailsViewModel.refreshRows() updated – incomeTotals: planned=\(self.incomeTotals.planned) actual=\(self.incomeTotals.actual)")
    }

    /// Resets the date window to the budget's own period.
    func resetDateWindowToBudget() {
        guard let b = budget else { return }
        startDate = b.startDate ?? startDate
        endDate = b.endDate ?? endDate
    }

    // MARK: - Fetch helpers

    /// Planned expenses attached to this budget (optionally filtered by date).
    private func fetchPlannedExpenses(for budget: Budget?, in range: ClosedRange<Date>) -> [PlannedExpense] {
        guard let budget else { return [] }
        let req = NSFetchRequest<PlannedExpense>(entityName: "PlannedExpense")
        let workspaceID = (budget.value(forKey: "workspaceID") as? UUID)
            ?? WorkspaceService.shared.activeWorkspaceID
        req.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
            NSPredicate(format: "budget == %@", budget),
            NSPredicate(format: "transactionDate >= %@ AND transactionDate <= %@", range.lowerBound as NSDate, range.upperBound as NSDate),
            WorkspaceService.predicate(for: workspaceID)
        ])
        req.sortDescriptors = [
            NSSortDescriptor(key: "transactionDate", ascending: false),
            NSSortDescriptor(key: "descriptionText", ascending: true, selector: #selector(NSString.localizedCaseInsensitiveCompare(_:)))
        ]
        return (try? context.fetch(req)) ?? []
    }

    /// Unplanned expenses that should be considered for a budget.
    /// Primary path uses UnplannedExpenseService (ANY card.budget.id == budget.id).
    /// Fallback path uses the Budget.cards relationship directly.
    private func fetchUnplannedExpenses(for budget: Budget?, in range: ClosedRange<Date>) -> [UnplannedExpense] {
        guard let budget else { return [] }
        let interval = DateInterval(start: range.lowerBound, end: range.upperBound)

        // Preferred: via service using Budget UUID (more tolerant of schema naming on Card side)
        if let bid = budget.value(forKey: "id") as? UUID {
            if let rows = try? unplannedService.fetchForBudget(bid, in: interval, sortedByDateAscending: false) {
                return rows
            }
        }

        // Fallback: via explicit cards set (works regardless of inverse name on Card)
        guard let cards = (budget.cards as? Set<Card>), !cards.isEmpty else { return [] }
        let req = NSFetchRequest<UnplannedExpense>(entityName: "UnplannedExpense")
        let workspaceID = (budget.value(forKey: "workspaceID") as? UUID)
            ?? WorkspaceService.shared.activeWorkspaceID
        req.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
            NSPredicate(format: "card IN %@", cards),
            NSPredicate(format: "transactionDate >= %@ AND transactionDate <= %@", range.lowerBound as NSDate, range.upperBound as NSDate),
            WorkspaceService.predicate(for: workspaceID)
        ])
        req.sortDescriptors = [
            NSSortDescriptor(key: "transactionDate", ascending: false),
            NSSortDescriptor(key: "descriptionText", ascending: true, selector: #selector(NSString.localizedCaseInsensitiveCompare(_:)))
        ]
        return (try? context.fetch(req)) ?? []
    }

    private func normalizedRange() -> ClosedRange<Date> {
        let lower = min(startDate, endDate)
        let upper = max(startDate, endDate)
        return lower...upper
    }

    nonisolated private static func plannedSortDescriptors(for sort: SortOption) -> [NSSortDescriptor] {
        switch sort {
        case .titleAZ:
            return [NSSortDescriptor(key: "descriptionText", ascending: true, selector: #selector(NSString.localizedCaseInsensitiveCompare(_:)))]
        case .amountLowHigh:
            return [NSSortDescriptor(key: "actualAmount", ascending: true)]
        case .amountHighLow:
            return [NSSortDescriptor(key: "actualAmount", ascending: false)]
        case .dateOldNew:
            return [NSSortDescriptor(key: "transactionDate", ascending: true)]
        case .dateNewOld:
            return [NSSortDescriptor(key: "transactionDate", ascending: false)]
        }
    }

    var placeholderText: String {
        switch loadState {
        case .failed(let message):
            return message
        case .idle, .loading:
            return "Loading…"
        case .loaded:
            return "Budget unavailable."
        }
    }
}

//
//  HomeViewModel.swift
//  SoFar
//
//  Drives the home screen: loads budgets for the selected month and
//  computes per-budget summaries (planned/actual income & expenses and
//  variable spend by category). NOTE: Income is fetched by DATE RANGE
//  only; there is no Budget↔Income link.
//

import Foundation
import SwiftUI
import CoreData
#if canImport(UIKit)
import UIKit
#endif

// MARK: - BudgetLoadState
/// Represents the loading state for budgets to prevent UI flickering
enum BudgetLoadState: Equatable {
    /// The view has not started loading yet.
    case initial
    /// Loading is in progress (and has taken >200ms).
    case loading
    /// Loading is complete, and there are no items.
    case empty
    /// Loading is complete, and there are items to display.
    case loaded([BudgetSummary])
}

// MARK: - HomeViewAlert
/// Alert types surfaced by the home screen.
struct HomeViewAlert: Identifiable {
    enum Kind {
        case error(message: String)
        case confirmDelete(budgetID: NSManagedObjectID)
    }
    let id = UUID()
    let kind: Kind
}

// MARK: - BudgetSummary (View Model DTO)
/// Immutable data passed to the card view for rendering.
struct BudgetSummary: Identifiable, Equatable, Sendable {

    // MARK: Identity
    /// Stable identifier derived from the managed object's ID.
    let id: NSManagedObjectID

    // MARK: Budget Basics
    let budgetName: String
    let periodStart: Date
    let periodEnd: Date

    // MARK: Variable Spend (Unplanned) by Category
    struct CategorySpending: Identifiable, Equatable, Sendable {
        let id: UUID
        let categoryID: UUID?
        let categoryName: String
        let hexColor: String?
        let amount: Double

        init(categoryID: UUID?, categoryName: String, hexColor: String?, amount: Double) {
            self.categoryID = categoryID
            self.categoryName = categoryName
            self.hexColor = hexColor
            self.amount = amount
            self.id = categoryID ?? UUID()
        }
    }
    // Combined (legacy) – kept for backwards compatibility
    let categoryBreakdown: [CategorySpending]
    // New: per‑segment breakdowns so UI can respect the selected segment
    let plannedCategoryBreakdown: [CategorySpending]
    let variableCategoryBreakdown: [CategorySpending]
    let variableExpensesTotal: Double

    // MARK: Planned Expenses (line items attached to budget)
    let plannedExpensesPlannedTotal: Double
    let plannedExpensesActualTotal: Double

    // MARK: Income (date-based; no relationship)
    /// Total income expected for the period (e.g. paychecks not yet received).
    let potentialIncomeTotal: Double
    /// Income actually received so far in the period.
    let actualIncomeTotal: Double

    // MARK: Savings
    /// Savings you could have if all potential income arrives and only planned expenses occur.
    var potentialSavingsTotal: Double { potentialIncomeTotal - plannedExpensesPlannedTotal }
    /// Savings based on actual income received minus both actual planned expenses and variable expenses.
    var actualSavingsTotal: Double {
        actualIncomeTotal - (plannedExpensesActualTotal + variableExpensesTotal)
    }

    // MARK: Convenience
    var periodString: String {
        let f = DateFormatter()
        f.dateFormat = "MMM d, yyyy"
        return "\(f.string(from: periodStart)) through \(f.string(from: periodEnd))"
    }
}

// MARK: - Month (Helper)
/// Utilities for deriving month ranges.
enum Month {
    // MARK: start(of:)
    static func start(of date: Date) -> Date {
        let cal = Calendar.current
        let comps = cal.dateComponents([.year, .month], from: date)
        return cal.date(from: comps) ?? date
    }

    // MARK: end(of:)
    static func end(of date: Date) -> Date {
        let cal = Calendar.current
        guard let start = cal.date(from: cal.dateComponents([.year, .month], from: date)),
              let end = cal.date(byAdding: DateComponents(month: 1, day: -1), to: start) else {
            return date
        }
        // Set to end of day for inclusive comparisons
        return cal.date(bySettingHour: 23, minute: 59, second: 59, of: end) ?? end
    }

    // MARK: range(for:)
    static func range(for date: Date) -> (start: Date, end: Date) {
        (start(of: date), end(of: date))
    }
}

// MARK: - HomeViewModel
@MainActor
final class HomeViewModel: ObservableObject {

    // MARK: Published State
    @AppStorage(AppSettingsKeys.budgetPeriod.rawValue)
    private var budgetPeriodRawValue: String = BudgetPeriod.monthly.rawValue {
        didSet {
            guard budgetPeriodRawValue != oldValue else { return }
            selectedDate = period.start(of: Date())
            Task { [weak self] in
                await self?.refresh()
            }
        }
    }

    private var period: BudgetPeriod {
        BudgetPeriod(rawValue: budgetPeriodRawValue) ?? .monthly
    }

    @Published var selectedDate: Date = BudgetPeriod.monthly.start(of: Date()) {
        didSet {
            guard selectedDate != oldValue else { return }
            Task { [weak self] in
                await self?.refresh()
            }
        }
    }
    @Published private(set) var state: BudgetLoadState = .initial
    @Published var alert: HomeViewAlert?

    // MARK: Dependencies
    private let context: NSManagedObjectContext
    private let budgetService = BudgetService()
    private var dataStoreObserver: NSObjectProtocol?
    private var hasStarted = false
    private var isRefreshing = false
    private var needsAnotherRefresh = false

    // MARK: init()
    /// - Parameter context: The Core Data context to use (defaults to main viewContext).
    init(context: NSManagedObjectContext = CoreDataService.shared.viewContext) {
        self.context = context
        self.selectedDate = period.start(of: Date())
    }

    // MARK: startIfNeeded()
    /// Starts loading budgets exactly once.
    /// This uses a delayed transition to the `.loading` state to prevent
    /// the loading indicator from flashing on screen for fast loads.
    func startIfNeeded() {
        guard !hasStarted else { return }
        hasStarted = true

        if dataStoreObserver == nil {
            dataStoreObserver = NotificationCenter.default.addObserver(
                forName: .dataStoreDidChange,
                object: nil,
                queue: .main
            ) { [weak self] _ in
                guard let self else { return }
                Task { await self.refresh() }
            }
        }

        // After a 200ms delay, if we are still in the `initial` state,
        // we transition to the `loading` state.
        Task {
            try? await Task.sleep(nanoseconds: 200_000_000)
            if case .initial = self.state {
                self.state = .loading
            }
        }

        // Immediately start the actual data fetch.
        Task { await refresh() }
    }

    // MARK: refresh()
    /// Loads budgets that overlap the selected period and computes summaries.
    /// - Important: This uses each budget's own start/end when computing totals.
    func refresh() async {
        if isRefreshing {
            needsAnotherRefresh = true
            AppLog.viewModel.debug("HomeViewModel.refresh() coalesced – refresh already in flight")
            return
        }

        isRefreshing = true
        AppLog.viewModel.debug("HomeViewModel.refresh() started – current state: \(String(describing: self.state))")
        CoreDataService.shared.ensureLoaded()
        AppLog.viewModel.debug("HomeViewModel.refresh() awaiting persistent stores…")
        await CoreDataService.shared.waitUntilStoresLoaded()
        AppLog.viewModel.debug("HomeViewModel.refresh() continuing – storesLoaded: \(CoreDataService.shared.storesLoaded)")

        let requestedPeriod = period
        let requestedDate = selectedDate
        let (start, end) = requestedPeriod.range(containing: requestedDate)

        let summaries = await loadSummaries(period: requestedPeriod, dateRange: start...end)
        AppLog.viewModel.debug("HomeViewModel.refresh() finished fetching summaries – count: \(summaries.count)")

        // Even if this task was cancelled (for example, by a rapid burst of
        // .dataStoreDidChange notifications), finalize the UI state once we
        // have computed summaries so the view never gets stuck showing the
        // "Loading…" placeholder. This mirrors the Budget Details fix and
        // keeps HomeView responsive for non‑iCloud accounts as well.
        let calendar = Calendar.current
        let periodChanged = self.period != requestedPeriod
        let dateChanged = !calendar.isDate(self.selectedDate, inSameDayAs: requestedDate)
        if periodChanged || dateChanged {
            AppLog.viewModel.debug("HomeViewModel.refresh() discarding fetched summaries – selection changed during fetch")
        } else {
            let newState: BudgetLoadState = summaries.isEmpty ? .empty : .loaded(summaries)
            if self.state != newState {
                self.state = newState
                if summaries.isEmpty {
                    AppLog.viewModel.debug("HomeViewModel.refresh() transitioning to .empty state")
                } else {
                    AppLog.viewModel.debug("HomeViewModel.refresh() transitioning to .loaded state")
                }
            }
        }

        isRefreshing = false
        if periodChanged || dateChanged {
            let hadPendingRefresh = needsAnotherRefresh
            needsAnotherRefresh = false
            AppLog.viewModel.debug("HomeViewModel.refresh() restarting refresh for updated selection – coalesced: \(hadPendingRefresh)")
            Task { [weak self] in
                await self?.refresh()
            }
            return
        }
        if needsAnotherRefresh {
            needsAnotherRefresh = false
            AppLog.viewModel.debug("HomeViewModel.refresh() scheduling coalesced refresh")
            Task { [weak self] in
                await self?.refresh()
            }
        }
    }

    deinit {
        if let observer = dataStoreObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }

    private func loadSummaries(period: BudgetPeriod, dateRange: ClosedRange<Date>) async -> [BudgetSummary] {
        await withCheckedContinuation { continuation in
            let backgroundContext = CoreDataService.shared.newBackgroundContext()
            backgroundContext.perform {
                // Include any budgets that overlap the selected range. Do NOT
                // require exact period alignment so empty or partial budgets
                // still appear on Home and do not cause empty/loaded flapping.
                let budgets = Self.fetchBudgets(overlapping: dateRange, in: backgroundContext)

                let summaries: [BudgetSummary] = budgets.compactMap { budget -> BudgetSummary? in
                    guard let startDate = budget.startDate, let endDate = budget.endDate else { return nil }
                    return Self.buildSummary(
                        for: budget,
                        periodStart: startDate,
                        periodEnd: endDate,
                        in: backgroundContext
                    )
                }
                .sorted { (first: BudgetSummary, second: BudgetSummary) -> Bool in
                    (first.periodStart, first.budgetName) < (second.periodStart, second.budgetName)
                }

                backgroundContext.reset()
                continuation.resume(returning: summaries)
            }
        }
    }

    // MARK: updateBudgetPeriod(to:)
    /// Updates the budget period preference and triggers a refresh.
    /// - Parameter newPeriod: The newly selected budget period.
    func updateBudgetPeriod(to newPeriod: BudgetPeriod) {
        guard budgetPeriodRawValue != newPeriod.rawValue else { return }
        budgetPeriodRawValue = newPeriod.rawValue
    }

    // MARK: adjustSelectedPeriod(by:)
    /// Moves the selected period forward/backward.
    /// - Parameter delta: Positive to go forward, negative to go backward.
    func adjustSelectedPeriod(by delta: Int) {
        selectedDate = period.advance(selectedDate, by: delta)
    }

    // MARK: Deletion
    /// Requests deletion for the provided budget object ID, honoring the user's confirm setting.
    func requestDelete(budgetID: NSManagedObjectID) {
        let confirm = UserDefaults.standard.object(
            forKey: AppSettingsKeys.confirmBeforeDelete.rawValue
        ) as? Bool ?? true
        if confirm {
            alert = HomeViewAlert(kind: .confirmDelete(budgetID: budgetID))
        } else {
            Task { await confirmDelete(budgetID: budgetID) }
        }
    }

    /// Permanently deletes a budget and refreshes state.
    func confirmDelete(budgetID: NSManagedObjectID) async {
        do {
            if let budget = try context.existingObject(with: budgetID) as? Budget {
                try budgetService.deleteBudget(budget)
                await refresh()
            }
        } catch {
            alert = HomeViewAlert(kind: .error(message: error.localizedDescription))
        }
    }

    // MARK: - Private: Fetching

    // MARK: fetchBudgets(overlapping:)
    /// Returns budgets that overlap the given date range.
    /// - Parameter range: The date window to match against budget start/end.
    private nonisolated static func fetchBudgets(overlapping range: ClosedRange<Date>, in context: NSManagedObjectContext) -> [Budget] {
        let req = NSFetchRequest<Budget>(entityName: "Budget")
        let start = range.lowerBound
        let end = range.upperBound

        // Overlap predicate: (startDate <= end) AND (endDate >= start)
        req.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
            NSPredicate(format: "startDate <= %@", end as NSDate),
            NSPredicate(format: "endDate >= %@", start as NSDate)
        ])
        req.sortDescriptors = [
            NSSortDescriptor(key: "startDate", ascending: true),
            NSSortDescriptor(key: "name", ascending: true, selector: #selector(NSString.localizedCaseInsensitiveCompare(_:)))
        ]
        do { return try context.fetch(req) } catch { return [] }
    }

    // MARK: buildSummary(for:periodStart:periodEnd:)
    /// Computes totals and category breakdown for a single budget.
    /// - Parameters:
    ///   - budget: The budget record.
    ///   - periodStart: Inclusive start date for calculations.
    ///   - periodEnd: Inclusive end date for calculations.
    /// - Returns: A `BudgetSummary` for display.
    private nonisolated static func buildSummary(
        for budget: Budget,
        periodStart: Date,
        periodEnd: Date,
        in context: NSManagedObjectContext
    ) -> BudgetSummary {
        // MARK: Planned Expenses (attached to budget)
        let plannedFetch = NSFetchRequest<PlannedExpense>(entityName: "PlannedExpense")
        plannedFetch.predicate = NSPredicate(format: "budget == %@", budget)
        let plannedExpenses: [PlannedExpense] = (try? context.fetch(plannedFetch)) ?? []

        let plannedExpensesPlannedTotal = plannedExpenses.reduce(0.0) { $0 + $1.plannedAmount }
        let plannedExpensesActualTotal  = plannedExpenses.reduce(0.0) { $0 + $1.actualAmount }

        // MARK: Income (DATE-ONLY; no relationship)
        // Income events exist globally on the calendar; we include any whose date falls within the budget window.
        let incomeFetch = NSFetchRequest<Income>(entityName: "Income")
        incomeFetch.predicate = NSPredicate(format: "date >= %@ AND date <= %@", periodStart as NSDate, periodEnd as NSDate)
        let incomes: [Income] = (try? context.fetch(incomeFetch)) ?? []
        let potentialIncomeTotal = incomes.filter { $0.isPlanned }.reduce(0.0) { $0 + $1.amount }
        let actualIncomeTotal    = incomes.filter { !$0.isPlanned }.reduce(0.0) { $0 + $1.amount }

        // MARK: Expense Categories – separate maps (exclude Uncategorized) and include zero-amount categories
        struct CategoryIdentifier: Hashable {
            let id: UUID?
            let name: String
        }

        struct CategoryAccumulator {
            let id: UUID?
            let name: String
            var hex: String?
            var total: Double
        }

        func trimmedName(for category: ExpenseCategory?) -> String? {
            guard let rawName = category?.name?.trimmingCharacters(in: .whitespacesAndNewlines), !rawName.isEmpty else {
                return nil
            }
            return rawName
        }

        func update(_ map: inout [CategoryIdentifier: CategoryAccumulator],
                    with category: ExpenseCategory?,
                    amount: Double) {
            guard let name = trimmedName(for: category) else { return }
            let key = CategoryIdentifier(id: category?.id, name: name)
            var entry = map[key] ?? CategoryAccumulator(id: category?.id, name: name, hex: nil, total: 0)
            if entry.hex == nil, let hex = category?.color, !hex.isEmpty {
                entry.hex = hex
            }
            entry.total += amount
            map[key] = entry
        }

        func ensureCategoryPresence(_ map: inout [CategoryIdentifier: CategoryAccumulator],
                                    category: ExpenseCategory) {
            guard let name = trimmedName(for: category) else { return }
            let key = CategoryIdentifier(id: category.id, name: name)
            var entry = map[key] ?? CategoryAccumulator(id: category.id, name: name, hex: nil, total: 0)
            if entry.hex == nil, let hex = category.color, !hex.isEmpty {
                entry.hex = hex
            }
            map[key] = entry
        }

        var plannedCatMap: [CategoryIdentifier: CategoryAccumulator] = [:]
        var variableCatMap: [CategoryIdentifier: CategoryAccumulator] = [:]

        for e in plannedExpenses {
            let amt = e.plannedAmount
            update(&plannedCatMap, with: e.expenseCategory, amount: amt)
        }

        let cards = (budget.cards as? Set<Card>) ?? []
        var variableTotal: Double = 0
        if !cards.isEmpty {
            let unplannedReq = NSFetchRequest<UnplannedExpense>(entityName: "UnplannedExpense")
            unplannedReq.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
                NSPredicate(format: "card IN %@", cards),
                NSPredicate(format: "transactionDate >= %@ AND transactionDate <= %@", periodStart as NSDate, periodEnd as NSDate)
            ])
            let unplanned: [UnplannedExpense] = (try? context.fetch(unplannedReq)) ?? []
            for e in unplanned {
                let amt = e.amount
                variableTotal += amt

                update(&variableCatMap, with: e.expenseCategory, amount: amt)
            }
        }

        // Union with all categories to include zero-amount chips
        let allCategoriesFetch = NSFetchRequest<ExpenseCategory>(entityName: "ExpenseCategory")
        allCategoriesFetch.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true, selector: #selector(NSString.localizedCaseInsensitiveCompare(_:)))]
        let allCategories: [ExpenseCategory] = (try? context.fetch(allCategoriesFetch)) ?? []
        for cat in allCategories {
            ensureCategoryPresence(&plannedCatMap, category: cat)
            ensureCategoryPresence(&variableCatMap, category: cat)
        }

        // Build breakdowns, sort by amount desc, then name A–Z for stable tie-breaks
        let plannedBreakdown: [BudgetSummary.CategorySpending] = plannedCatMap
            .map { BudgetSummary.CategorySpending(categoryID: $0.value.id,
                                                  categoryName: $0.value.name,
                                                  hexColor: $0.value.hex,
                                                  amount: $0.value.total) }
            .sorted { lhs, rhs in
                if lhs.amount == rhs.amount { return lhs.categoryName.localizedCaseInsensitiveCompare(rhs.categoryName) == .orderedAscending }
                return lhs.amount > rhs.amount
            }

        let variableBreakdown: [BudgetSummary.CategorySpending] = variableCatMap
            .map { BudgetSummary.CategorySpending(categoryID: $0.value.id,
                                                  categoryName: $0.value.name,
                                                  hexColor: $0.value.hex,
                                                  amount: $0.value.total) }
            .sorted { lhs, rhs in
                if lhs.amount == rhs.amount { return lhs.categoryName.localizedCaseInsensitiveCompare(rhs.categoryName) == .orderedAscending }
                return lhs.amount > rhs.amount
            }

        // Combined (legacy)
        var combinedCatMap = plannedCatMap
        for (key, value) in variableCatMap {
            var entry = combinedCatMap[key] ?? CategoryAccumulator(id: value.id, name: value.name, hex: nil, total: 0)
            if entry.hex == nil { entry.hex = value.hex }
            entry.total += value.total
            combinedCatMap[key] = entry
        }

        let categoryBreakdown: [BudgetSummary.CategorySpending] = combinedCatMap
            .values
            .map { BudgetSummary.CategorySpending(categoryID: $0.id,
                                                  categoryName: $0.name,
                                                  hexColor: $0.hex,
                                                  amount: $0.total) }
            .sorted { lhs, rhs in
                if lhs.amount == rhs.amount { return lhs.categoryName.localizedCaseInsensitiveCompare(rhs.categoryName) == .orderedAscending }
                return lhs.amount > rhs.amount
            }

        return BudgetSummary(
            id: budget.objectID,
            budgetName: budget.name ?? "Untitled",
            periodStart: periodStart,
            periodEnd: periodEnd,
            categoryBreakdown: categoryBreakdown,
            plannedCategoryBreakdown: plannedBreakdown,
            variableCategoryBreakdown: variableBreakdown,
            variableExpensesTotal: variableTotal,
            plannedExpensesPlannedTotal: plannedExpensesPlannedTotal,
            plannedExpensesActualTotal: plannedExpensesActualTotal,
            potentialIncomeTotal: potentialIncomeTotal,
            actualIncomeTotal: actualIncomeTotal
        )
    }
}

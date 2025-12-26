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
import Combine

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
        // Use the stable category URI as identity so refreshes with identical
        // data don't appear as different items (prevents flicker and state churn).
        var id: URL { categoryURI }
        // Stable identity for category-specific actions; URL is Sendable
        let categoryURI: URL
        let categoryName: String
        let hexColor: String?
        let amount: Double
    }

    // Back-compat convenience initializer is defined below at file scope.
    // Combined (legacy) – kept for backwards compatibility
    let categoryBreakdown: [CategorySpending]
    // New: per‑segment breakdowns so UI can respect the selected segment
    let plannedCategoryBreakdown: [CategorySpending]
    let variableCategoryBreakdown: [CategorySpending]
    /// Default max caps derived from planned amounts per category (normalized name).
    let plannedCategoryDefaultCaps: [String: Double]
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

// MARK: - BudgetSummary.CategorySpending Back-Compat Init
extension BudgetSummary.CategorySpending {
    /// Convenience initializer for call sites that don't have a Core Data category object ID.
    /// Generates a stable local URI using the category name for identity.
    init(categoryName: String, hexColor: String?, amount: Double) {
        let encoded = categoryName.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? UUID().uuidString
        let uri = URL(string: "offshore-local://category/\(encoded)") ?? URL(string: "offshore-local://category/unknown")!
        self.init(categoryURI: uri, categoryName: categoryName, hexColor: hexColor, amount: amount)
    }
}

private func normalizedCategoryName(_ name: String) -> String {
    name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
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
    @Published private(set) var period: BudgetPeriod = .monthly

    @Published var selectedDate: Date = BudgetPeriod.monthly.start(of: Date()) {
        didSet {
            guard selectedDate != oldValue else { return }
            Task { [weak self] in
                await self?.refresh()
            }
        }
    }
    @Published private(set) var customDateRange: ClosedRange<Date>? = nil
    @Published private(set) var state: BudgetLoadState = .initial
    @Published private(set) var loadedBudgetIDs: [NSManagedObjectID] = []
    @Published var alert: HomeViewAlert?

    // MARK: Dependencies
    private let context: NSManagedObjectContext
    private let budgetService = BudgetService()
    private var dataStoreObserver: NSObjectProtocol?
    private var entityChangeMonitor: CoreDataEntityChangeMonitor?
    private var cancellables: Set<AnyCancellable> = []
    private var hasStarted = false
    private var isRefreshing = false
    private var needsAnotherRefresh = false
    private var pendingApply: DispatchWorkItem?
    private var lastLoadedAt: Date? = nil
    private var hasPostedInitialDataNotification = false

    // MARK: init()
    /// - Parameter context: The Core Data context to use (defaults to main viewContext).
    init(context: NSManagedObjectContext = CoreDataService.shared.viewContext) {
        self.context = context
        self.period = WorkspaceService.shared.currentBudgetPeriod(in: context)
        self.selectedDate = period.start(of: Date())
    }

    var currentDateRange: ClosedRange<Date> {
        if let customDateRange { return customDateRange }
        let bounds = period.range(containing: selectedDate)
        return bounds.start...bounds.end
    }

    var isUsingCustomRange: Bool { customDateRange != nil }

    // MARK: startIfNeeded()
    /// Starts loading budgets exactly once.
    /// This uses a delayed transition to the `.loading` state to prevent
    /// the loading indicator from flashing on screen for fast loads.
    func startIfNeeded() {
        guard !hasStarted else { return }
        hasStarted = true

        if entityChangeMonitor == nil {
            // Refresh only on relevant entity changes to reduce churn and flicker.
            // Budget + expenses + income + categories + card membership affect summaries.
            entityChangeMonitor = CoreDataEntityChangeMonitor(
                entityNames: ["Budget", "PlannedExpense", "UnplannedExpense", "Income", "ExpenseCategory", "Card", "Workspace"],
                debounceMilliseconds: DataChangeDebounce.milliseconds()
            ) { [weak self] in
                Task { await self?.refresh() }
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
        if !CoreDataService.shared.storesLoaded {
            AppLog.viewModel.debug("HomeViewModel.refresh() awaiting persistent stores…")
            await CoreDataService.shared.waitUntilStoresLoaded()
            AppLog.viewModel.debug("HomeViewModel.refresh() continuing – storesLoaded: \(CoreDataService.shared.storesLoaded)")
        }

        // Refresh local period from Workspace in case it changed remotely
        self.period = WorkspaceService.shared.currentBudgetPeriod(in: context)
        let requestedPeriod = period
        let requestedDate = selectedDate
        let requestedRange: ClosedRange<Date>
        if let customDateRange {
            requestedRange = customDateRange
        } else {
            let (start, end) = requestedPeriod.range(containing: requestedDate)
            requestedRange = start...end
        }

        let (summaries, budgetIDs) = await loadSummaries(period: requestedPeriod, dateRange: requestedRange)
        AppLog.viewModel.debug("HomeViewModel.refresh() finished fetching summaries – count: \(summaries.count)")

        // Even if this task was cancelled (for example, by a rapid burst of
        // .dataStoreDidChange notifications), finalize the UI state once we
        // have computed summaries so the view never gets stuck showing the
        // "Loading…" placeholder. This mirrors the Budget Details fix and
        // keeps HomeView responsive for non‑iCloud accounts as well.
        let calendar = Calendar.current
        let periodChanged = self.period != requestedPeriod
        let dateChanged = !calendar.isDate(self.selectedDate, inSameDayAs: requestedDate)
        let rangeChanged = !calendar.isDate(self.currentDateRange.lowerBound, inSameDayAs: requestedRange.lowerBound) ||
                           !calendar.isDate(self.currentDateRange.upperBound, inSameDayAs: requestedRange.upperBound)
        if periodChanged || dateChanged || rangeChanged {
            AppLog.viewModel.debug("HomeViewModel.refresh() discarding fetched summaries – selection changed during fetch")
        } else {
            let newState: BudgetLoadState = summaries.isEmpty ? .empty : .loaded(summaries)
            emitStateDebounced(newState)
            self.loadedBudgetIDs = budgetIDs
        }

        isRefreshing = false
        if periodChanged || dateChanged || rangeChanged {
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

        Task { [weak self] in
            await self?.updateIncomeWidgetsForAllPeriods(referenceDate: requestedDate)
            await self?.updateExpenseToIncomeWidgetsForAllPeriods(referenceDate: requestedDate)
            await self?.updateSavingsOutlookWidgetsForAllPeriods(referenceDate: requestedDate)
            await self?.updateCategorySpotlightWidgetsForAllPeriods(referenceDate: requestedDate)
        }
    }

    // MARK: - Debounced state emission
    /// Apply state changes with a short debounce to coalesce CloudKit bursts
    /// and avoid visible flicker on Home.
    private func emitStateDebounced(_ newState: BudgetLoadState) {
        // If the target equals current, skip.
        if self.state == newState { return }

        pendingApply?.cancel()
        // Base delay tuned for general change bursts
        var delayMS = DataChangeDebounce.outputMilliseconds()

        // If we're about to emit an .empty state shortly after a .loaded state,
        // hold the transition a bit longer to avoid visible flapping during
        // CloudKit imports or batched Core Data merges. Any subsequent .loaded
        // will cancel this pending apply automatically.
        if case .empty = newState {
            let now = Date()
            if let last = lastLoadedAt {
                let secondsSinceLoaded = now.timeIntervalSince(last)
                if secondsSinceLoaded < 1.2 { // recent successful load
                    delayMS = max(delayMS, 900)
                }
            }
            #if canImport(UIKit)
            if UserDefaults.standard.bool(forKey: AppSettingsKeys.enableCloudSync.rawValue), CloudSyncMonitor.shared.isImporting {
                delayMS = max(delayMS, 1100)
            }
            #endif
        }
        let work = DispatchWorkItem { [weak self] in
            guard let self else { return }
            if self.state != newState {
                self.state = newState
                switch newState {
                case .empty:
                    AppLog.viewModel.debug("HomeViewModel.refresh() transitioning to .empty state")
                case .loaded:
                    AppLog.viewModel.debug("HomeViewModel.refresh() transitioning to .loaded state")
                    self.lastLoadedAt = Date()
                    if case .loaded(let summaries) = newState {
                        self.updateIncomeWidget(from: summaries, period: self.period)
                        self.updateExpenseToIncomeWidget(from: summaries, period: self.period)
                        self.updateSavingsOutlookWidget(from: summaries, period: self.period)
                        self.updateCategorySpotlightWidget(from: summaries, period: self.period)
                    }
                default:
                    break
                }

                if !self.hasPostedInitialDataNotification {
                    switch newState {
                    case .loaded, .empty:
                        self.hasPostedInitialDataNotification = true
                        NotificationCenter.default.post(name: .homeViewInitialDataLoaded, object: nil)
                    default:
                        break
                    }
                }
            }
        }
        pendingApply = work
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(delayMS), execute: work)
    }

    private func updateIncomeWidget(from summaries: [BudgetSummary], period: BudgetPeriod) {
        guard let summary = summaries.first else { return }
        let planned = max(summary.potentialIncomeTotal, 0)
        let actual = max(summary.actualIncomeTotal, 0)
        let percent = planned > 0 ? min(max(actual / planned, 0), 1) : 0
        let rangeLabel = summary.periodString
        let snapshot = WidgetSharedStore.IncomeSnapshot(
            actualIncome: actual,
            plannedIncome: planned,
            percentReceived: percent,
            rangeLabel: rangeLabel,
            updatedAt: Date()
        )
        WidgetSharedStore.writeIncomeSnapshot(snapshot, periodRaw: period.rawValue)
    }

    private func updateExpenseToIncomeWidget(from summaries: [BudgetSummary], period: BudgetPeriod) {
        guard let summary = summaries.first else { return }
        let expenses = max(summary.plannedExpensesActualTotal + summary.variableExpensesTotal, 0)
        let actualIncome = max(summary.actualIncomeTotal, 0)
        let rangeLabel = summary.periodString
        let snapshot = WidgetSharedStore.ExpenseToIncomeSnapshot(
            expenses: expenses,
            actualIncome: actualIncome,
            rangeLabel: rangeLabel,
            updatedAt: Date()
        )
        WidgetSharedStore.writeExpenseToIncomeSnapshot(snapshot, periodRaw: period.rawValue)
    }

    private func updateSavingsOutlookWidget(from summaries: [BudgetSummary], period: BudgetPeriod) {
        guard let summary = summaries.first else { return }
        let outlook = BudgetMetrics.savingsOutlook(
            actualSavings: summary.actualSavingsTotal,
            expectedIncome: summary.potentialIncomeTotal,
            incomeReceived: summary.actualIncomeTotal,
            plannedExpensesPlanned: summary.plannedExpensesPlannedTotal,
            plannedExpensesActual: summary.plannedExpensesActualTotal
        )
        let rangeLabel = summary.periodString
        let snapshot = WidgetSharedStore.SavingsOutlookSnapshot(
            actualSavings: outlook.actual,
            projectedSavings: outlook.projected,
            rangeLabel: rangeLabel,
            updatedAt: Date()
        )
        WidgetSharedStore.writeSavingsOutlookSnapshot(snapshot, periodRaw: period.rawValue)
    }

    private func updateCategorySpotlightWidget(from summaries: [BudgetSummary], period: BudgetPeriod) {
        guard let summary = summaries.first else { return }
        let categories = summary.categoryBreakdown
            .filter { $0.amount > 0 }
            .map {
                WidgetSharedStore.CategorySpotlightSnapshot.CategoryItem(
                    name: $0.categoryName,
                    amount: $0.amount,
                    hexColor: $0.hexColor
                )
            }
        let snapshot = WidgetSharedStore.CategorySpotlightSnapshot(
            categories: categories,
            rangeLabel: summary.periodString,
            updatedAt: Date()
        )
        WidgetSharedStore.writeCategorySpotlightSnapshot(snapshot, periodRaw: period.rawValue)
    }


    private func updateIncomeWidgetsForAllPeriods(referenceDate: Date) async {
        let defaultPeriod: BudgetPeriod = period == .custom ? .monthly : period
        WidgetSharedStore.writeIncomeDefaultPeriod(defaultPeriod.rawValue)
        for period in BudgetPeriod.selectableCases {
            let range = period.range(containing: referenceDate)
            let (summaries, _) = await loadSummaries(period: period, dateRange: range.start...range.end)
            guard !summaries.isEmpty else { continue }
            updateIncomeWidget(from: summaries, period: period)
        }
    }

    private func updateExpenseToIncomeWidgetsForAllPeriods(referenceDate: Date) async {
        let defaultPeriod: BudgetPeriod = period == .custom ? .monthly : period
        WidgetSharedStore.writeExpenseToIncomeDefaultPeriod(defaultPeriod.rawValue)
        for period in BudgetPeriod.selectableCases {
            let range = period.range(containing: referenceDate)
            let (summaries, _) = await loadSummaries(period: period, dateRange: range.start...range.end)
            guard !summaries.isEmpty else { continue }
            updateExpenseToIncomeWidget(from: summaries, period: period)
        }
    }

    private func updateSavingsOutlookWidgetsForAllPeriods(referenceDate: Date) async {
        let defaultPeriod: BudgetPeriod = period == .custom ? .monthly : period
        WidgetSharedStore.writeSavingsOutlookDefaultPeriod(defaultPeriod.rawValue)
        for period in BudgetPeriod.selectableCases {
            let range = period.range(containing: referenceDate)
            let (summaries, _) = await loadSummaries(period: period, dateRange: range.start...range.end)
            guard !summaries.isEmpty else { continue }
            updateSavingsOutlookWidget(from: summaries, period: period)
        }
    }

    private func updateCategorySpotlightWidgetsForAllPeriods(referenceDate: Date) async {
        let defaultPeriod: BudgetPeriod = period == .custom ? .monthly : period
        WidgetSharedStore.writeCategorySpotlightDefaultPeriod(defaultPeriod.rawValue)
        for period in BudgetPeriod.selectableCases {
            let range = period.range(containing: referenceDate)
            let (summaries, _) = await loadSummaries(period: period, dateRange: range.start...range.end)
            guard !summaries.isEmpty else { continue }
            updateCategorySpotlightWidget(from: summaries, period: period)
        }
    }

    deinit {
        if let observer = dataStoreObserver { NotificationCenter.default.removeObserver(observer) }
        cancellables.forEach { $0.cancel() }
    }

    private func loadSummaries(period: BudgetPeriod, dateRange: ClosedRange<Date>) async -> (summaries: [BudgetSummary], budgetIDs: [NSManagedObjectID]) {
        await withCheckedContinuation { continuation in
            let backgroundContext = CoreDataService.shared.newBackgroundContext()
            backgroundContext.perform {
                // Include any budgets that overlap the selected range. Do NOT
                // require exact period alignment so empty or partial budgets
                // still appear on Home and do not cause empty/loaded flapping.
                let budgets = Self.fetchBudgets(overlapping: dateRange, in: backgroundContext)
                let allCategories = Self.fetchAllCategories(in: backgroundContext)
                let allIncomes = Self.fetchIncomes(overlapping: dateRange, in: backgroundContext)

                let summaries: [BudgetSummary] = budgets.compactMap { budget -> BudgetSummary? in
                    // Use the intersection between the selected range and the budget itself
                    let budgetStart = budget.startDate ?? dateRange.lowerBound
                    let budgetEnd = budget.endDate ?? dateRange.upperBound
                    let rangeStart = max(budgetStart, dateRange.lowerBound)
                    let rangeEnd = min(budgetEnd, dateRange.upperBound)
                    guard rangeStart <= rangeEnd else { return nil }
                    return Self.buildSummary(
                        for: budget,
                        periodStart: rangeStart,
                        periodEnd: rangeEnd,
                        allCategories: allCategories,
                        allIncomes: allIncomes,
                        in: backgroundContext
                    )
                }
                .sorted { (first: BudgetSummary, second: BudgetSummary) -> Bool in
                    (first.periodStart, first.budgetName) < (second.periodStart, second.budgetName)
                }

                let budgetIDs = budgets.map { $0.objectID }
                backgroundContext.reset()
                continuation.resume(returning: (summaries: summaries, budgetIDs: budgetIDs))
            }
        }
    }

    // MARK: Custom Date Range
    func applyCustomRange(start: Date, end: Date) {
        guard let normalized = Self.normalizedRange(start: start, end: end) else { return }
        customDateRange = normalized
        Task { [weak self] in
            await self?.refresh()
        }
    }

    func clearCustomRange() {
        guard customDateRange != nil else { return }
        customDateRange = nil
        Task { [weak self] in
            await self?.refresh()
        }
    }

    private static func normalizedRange(start: Date, end: Date) -> ClosedRange<Date>? {
        let cal = Calendar.current
        let lower = cal.startOfDay(for: start)
        guard let upper = cal.date(bySettingHour: 23, minute: 59, second: 59, of: end) else { return nil }
        guard lower <= upper else { return nil }
        return lower...upper
    }


    // MARK: updateBudgetPeriod(to:)
    /// Updates the budget period preference and triggers a refresh.
    /// - Parameter newPeriod: The newly selected budget period.
    func updateBudgetPeriod(to newPeriod: BudgetPeriod) {
        let desiredStart = newPeriod.start(of: Date())
        let cal = Calendar.current
        let needsUpdate = period != newPeriod ||
                          customDateRange != nil ||
                          !cal.isDate(selectedDate, inSameDayAs: desiredStart)
        guard needsUpdate else { return }
        if period != newPeriod {
            WorkspaceService.shared.setBudgetPeriod(newPeriod, in: context)
        }
        self.period = newPeriod
        selectedDate = desiredStart
        customDateRange = nil
        Task { [weak self] in
            await self?.refresh()
        }
    }

    // MARK: adjustSelectedPeriod(by:)
    /// Moves the selected period forward/backward.
    /// - Parameter delta: Positive to go forward, negative to go backward.
    func adjustSelectedPeriod(by delta: Int) {
        customDateRange = nil
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

    private nonisolated static func fetchAllCategories(in context: NSManagedObjectContext) -> [ExpenseCategory] {
        let req = NSFetchRequest<ExpenseCategory>(entityName: "ExpenseCategory")
        req.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true, selector: #selector(NSString.localizedCaseInsensitiveCompare(_:)))]
        return (try? context.fetch(req)) ?? []
    }

    private nonisolated static func fetchIncomes(overlapping range: ClosedRange<Date>, in context: NSManagedObjectContext) -> [Income] {
        let req = NSFetchRequest<Income>(entityName: "Income")
        req.predicate = incomeDatePredicate(for: range)
        return (try? context.fetch(req)) ?? []
    }

    // MARK: Income Date Range Helpers
    private nonisolated static func incomeDatePredicate(for range: ClosedRange<Date>) -> NSPredicate {
        let calendar = Calendar.current
        let startDay = calendar.startOfDay(for: range.lowerBound)
        let endDay = calendar.startOfDay(for: range.upperBound)
        let endExclusive = calendar.date(byAdding: .day, value: 1, to: endDay) ?? range.upperBound
        return NSPredicate(format: "date >= %@ AND date < %@", startDay as NSDate, endExclusive as NSDate)
    }

    // MARK: buildSummary(for:periodStart:periodEnd:)
    /// Computes totals and category breakdown for a single budget.
    /// - Parameters:
    ///   - budget: The budget record.
    ///   - periodStart: Inclusive start date for calculations.
    ///   - periodEnd: Inclusive end date for calculations.
    /// - Returns: A `BudgetSummary` for display.
    nonisolated static func buildSummary(
        for budget: Budget,
        periodStart: Date,
        periodEnd: Date,
        allCategories: [ExpenseCategory],
        allIncomes: [Income],
        in context: NSManagedObjectContext
    ) -> BudgetSummary {
        // MARK: Planned Expenses (attached to budget)
        let plannedFetch = NSFetchRequest<PlannedExpense>(entityName: "PlannedExpense")
        plannedFetch.predicate = NSPredicate(format: "budget == %@", budget)
        let plannedRaw: [PlannedExpense] = (try? context.fetch(plannedFetch)) ?? []
        // Deduplicate strict duplicates of template-children within this budget to avoid double-counting
        var seenTemplateChildKeys = Set<String>()
        let plannedExpenses: [PlannedExpense] = plannedRaw.filter { exp in
            if let templateID = exp.globalTemplateID {
                let dateKey = String(format: "%.0f", (exp.transactionDate ?? .distantPast).timeIntervalSince1970)
                let key = "\(templateID.uuidString)|\(dateKey)|\(exp.plannedAmount)|\(exp.actualAmount)"
                if seenTemplateChildKeys.contains(key) { return false }
                seenTemplateChildKeys.insert(key)
            }
            return true
        }

        let plannedExpensesPlannedTotal = plannedExpenses.reduce(0.0) { $0 + $1.plannedAmount }
        let plannedExpensesActualTotal  = plannedExpenses.reduce(0.0) { $0 + $1.actualAmount }

        // MARK: Income (DATE-ONLY; no relationship)
        let calendar = Calendar.current
        let incomeStartDay = calendar.startOfDay(for: periodStart)
        let incomeEndDay = calendar.startOfDay(for: periodEnd)
        let incomeEndExclusive = calendar.date(byAdding: .day, value: 1, to: incomeEndDay) ?? periodEnd
        let incomes: [Income] = allIncomes.filter { income in
            guard let date = income.date else { return false }
            return date >= incomeStartDay && date < incomeEndExclusive
        }
        let potentialIncomeTotal = incomes.filter { $0.isPlanned }.reduce(0.0) { $0 + $1.amount }
        let actualIncomeTotal    = incomes.filter { !$0.isPlanned }.reduce(0.0) { $0 + $1.amount }

        // MARK: Expense Categories – separate maps (exclude Uncategorized) and include zero-amount categories
        // Key by NSManagedObjectID to avoid ambiguity when names are not unique
        var plannedCatMap: [NSManagedObjectID: (name: String, hex: String?, total: Double)] = [:]
        var plannedCapDefaults: [String: Double] = [:]
        var variableCatMap: [NSManagedObjectID: (name: String, hex: String?, total: Double)] = [:]

        for e in plannedExpenses {
            let amt = e.actualAmount
            guard let cat = e.expenseCategory else { continue }
            let name = (cat.name ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
            let hex = cat.color
            let existing = plannedCatMap[cat.objectID] ?? (name: name, hex: hex, total: 0)
            plannedCatMap[cat.objectID] = (name: existing.name.isEmpty ? name : existing.name,
                                           hex: hex ?? existing.hex,
                                           total: existing.total + amt)
            if let catName = cat.name {
                let norm = normalizedCategoryName(catName)
                plannedCapDefaults[norm, default: 0] += e.plannedAmount
            }
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

                guard let cat = e.expenseCategory else { continue }
                let name = (cat.name ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
                let hex = cat.color
                let existing = variableCatMap[cat.objectID] ?? (name: name, hex: hex, total: 0)
                variableCatMap[cat.objectID] = (name: existing.name.isEmpty ? name : existing.name,
                                                hex: hex ?? existing.hex,
                                                total: existing.total + amt)
            }
        }

        // Union with all categories to include zero-amount chips
        for cat in allCategories {
            let name = (cat.name ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
            if plannedCatMap[cat.objectID] == nil { plannedCatMap[cat.objectID] = (name: name, hex: cat.color, total: 0) }
            if variableCatMap[cat.objectID] == nil { variableCatMap[cat.objectID] = (name: name, hex: cat.color, total: 0) }
        }

        // Build breakdowns, sort by amount desc, then name A–Z for stable tie-breaks
        let plannedBreakdown: [BudgetSummary.CategorySpending] = plannedCatMap
            .map { BudgetSummary.CategorySpending(categoryURI: $0.key.uriRepresentation(), categoryName: $0.value.name, hexColor: $0.value.hex, amount: $0.value.total) }
            .sorted { lhs, rhs in
                if lhs.amount == rhs.amount { return lhs.categoryName.localizedCaseInsensitiveCompare(rhs.categoryName) == .orderedAscending }
                return lhs.amount > rhs.amount
            }

        let variableBreakdown: [BudgetSummary.CategorySpending] = variableCatMap
            .map { BudgetSummary.CategorySpending(categoryURI: $0.key.uriRepresentation(), categoryName: $0.value.name, hexColor: $0.value.hex, amount: $0.value.total) }
            .sorted { lhs, rhs in
                if lhs.amount == rhs.amount { return lhs.categoryName.localizedCaseInsensitiveCompare(rhs.categoryName) == .orderedAscending }
                return lhs.amount > rhs.amount
            }

        // Combined (legacy)
        let categoryBreakdown: [BudgetSummary.CategorySpending] = (plannedBreakdown + variableBreakdown)
            .reduce(into: [URL: BudgetSummary.CategorySpending]()) { dict, item in
                let existing = dict[item.categoryURI]
                let sum = (existing?.amount ?? 0) + item.amount
                dict[item.categoryURI] = BudgetSummary.CategorySpending(
                    categoryURI: item.categoryURI,
                    categoryName: existing?.categoryName ?? item.categoryName,
                    hexColor: existing?.hexColor ?? item.hexColor,
                    amount: sum
                )
            }
            .values
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
            plannedCategoryDefaultCaps: plannedCapDefaults,
            variableExpensesTotal: variableTotal,
            plannedExpensesPlannedTotal: plannedExpensesPlannedTotal,
            plannedExpensesActualTotal: plannedExpensesActualTotal,
            potentialIncomeTotal: potentialIncomeTotal,
            actualIncomeTotal: actualIncomeTotal
        )
    }
}

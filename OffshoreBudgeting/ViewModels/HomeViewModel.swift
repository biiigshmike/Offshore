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

private func capsPeriodKey(start: Date, end: Date, segment: String) -> String {
    let f = DateFormatter()
    f.calendar = Calendar(identifier: .gregorian)
    f.locale = Locale(identifier: "en_US_POSIX")
    f.timeZone = TimeZone(secondsFromGMT: 0)
    f.dateFormat = "yyyy-MM-dd"
    let s = f.string(from: start)
    let e = f.string(from: end)
    return "\(s)|\(e)|\(segment)"
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
    private var activeWorkspaceID: UUID { WorkspaceService.shared.activeWorkspaceID }
    private var workspaceObserver: NSObjectProtocol?
    private var widgetRefreshTask: Task<Void, Never>?
    private var lastWidgetRefreshAt: Date?
    private let widgetRefreshMinimumInterval: TimeInterval = 20.0

    // MARK: init()
    /// - Parameter context: The Core Data context to use (defaults to main viewContext).
    init(context: NSManagedObjectContext = CoreDataService.shared.viewContext) {
        self.context = context
        self.period = WorkspaceService.shared.currentBudgetPeriod(in: context)
        self.selectedDate = period.start(of: Date())

        workspaceObserver = NotificationCenter.default.addObserver(
            forName: .workspaceDidChange,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { await self?.refresh() }
        }
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

        scheduleWidgetSnapshotRefresh(referenceDate: requestedDate, preferDeferred: state == .initial || state == .loading)
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
            if (UserDefaultsAppSettingsStore().bool(for: .enableCloudSync) ?? false), CloudSyncMonitor.shared.isImporting {
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
                        Task { [weak self] in
                            await self?.updateDayOfWeekWidget(from: summaries, period: self?.period ?? .monthly, referenceDate: Date())
                        }
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

    private func scheduleWidgetSnapshotRefresh(referenceDate: Date, preferDeferred: Bool) {
        let now = Date()
        if let last = lastWidgetRefreshAt, now.timeIntervalSince(last) < widgetRefreshMinimumInterval {
            return
        }

        widgetRefreshTask?.cancel()
        widgetRefreshTask = Task { [weak self] in
            guard let self else { return }
            if preferDeferred {
                try? await Task.sleep(nanoseconds: 1_200_000_000)
            }
            if Task.isCancelled { return }
            if let last = self.lastWidgetRefreshAt, Date().timeIntervalSince(last) < self.widgetRefreshMinimumInterval {
                return
            }
            self.lastWidgetRefreshAt = Date()
            let widgetPeriod: BudgetPeriod = self.period == .custom ? .monthly : self.period
            let targetPeriods = [widgetPeriod]
            await self.updateIncomeWidgetsForAllPeriods(referenceDate: referenceDate, periods: targetPeriods)
            await self.updateExpenseToIncomeWidgetsForAllPeriods(referenceDate: referenceDate, periods: targetPeriods)
            await self.updateSavingsOutlookWidgetsForAllPeriods(referenceDate: referenceDate, periods: targetPeriods)
            await self.updateCategorySpotlightWidgetsForAllPeriods(referenceDate: referenceDate, periods: targetPeriods)
            await self.updateCategoryAvailabilityWidgetsForAllPeriods(referenceDate: referenceDate, periods: targetPeriods)
            await self.updateDayOfWeekWidgetsForAllPeriods(referenceDate: Date(), periods: targetPeriods)
            await self.updateCardWidgetsForAllPeriods(referenceDate: referenceDate, periods: targetPeriods)
        }
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

    private func updateDayOfWeekWidget(from summaries: [BudgetSummary], period: BudgetPeriod, referenceDate: Date) async {
        guard let summary = summaries.first else { return }
        let displayRange = rangeForWidgetPeriod(period, referenceDate: referenceDate)
        let dayTotals = await daySpendTotalsForWidget(summaryID: summary.id, in: displayRange)
        let buckets = widgetBuckets(for: period, range: displayRange, dayTotals: dayTotals)
        let fallbackHexes = widgetFallbackHexes(from: dayTotals)
        let snapshot = WidgetSharedStore.DayOfWeekSnapshot(
            buckets: buckets.map {
                WidgetSharedStore.DayOfWeekSnapshot.Bucket(label: $0.label, amount: $0.amount, hexColors: $0.hexColors)
            },
            rangeLabel: widgetRangeLabel(for: displayRange),
            fallbackHexes: fallbackHexes,
            updatedAt: Date()
        )
        WidgetSharedStore.writeDayOfWeekSnapshot(snapshot, periodRaw: period.rawValue)
    }


    private func updateIncomeWidgetsForAllPeriods(referenceDate: Date,
                                                  periods: [BudgetPeriod] = BudgetPeriod.selectableCases) async {
        let defaultPeriod: BudgetPeriod = period == .custom ? .monthly : period
        WidgetSharedStore.writeIncomeDefaultPeriod(defaultPeriod.rawValue)
        for period in periods {
            let range = period.range(containing: referenceDate)
            let (summaries, _) = await loadSummaries(period: period, dateRange: range.start...range.end)
            guard !summaries.isEmpty else { continue }
            updateIncomeWidget(from: summaries, period: period)
        }
    }

    private func updateExpenseToIncomeWidgetsForAllPeriods(referenceDate: Date,
                                                           periods: [BudgetPeriod] = BudgetPeriod.selectableCases) async {
        let defaultPeriod: BudgetPeriod = period == .custom ? .monthly : period
        WidgetSharedStore.writeExpenseToIncomeDefaultPeriod(defaultPeriod.rawValue)
        for period in periods {
            let range = period.range(containing: referenceDate)
            let (summaries, _) = await loadSummaries(period: period, dateRange: range.start...range.end)
            guard !summaries.isEmpty else { continue }
            updateExpenseToIncomeWidget(from: summaries, period: period)
        }
    }

    private func updateSavingsOutlookWidgetsForAllPeriods(referenceDate: Date,
                                                          periods: [BudgetPeriod] = BudgetPeriod.selectableCases) async {
        let defaultPeriod: BudgetPeriod = period == .custom ? .monthly : period
        WidgetSharedStore.writeSavingsOutlookDefaultPeriod(defaultPeriod.rawValue)
        for period in periods {
            let range = period.range(containing: referenceDate)
            let (summaries, _) = await loadSummaries(period: period, dateRange: range.start...range.end)
            guard !summaries.isEmpty else { continue }
            updateSavingsOutlookWidget(from: summaries, period: period)
        }
    }

    private func updateCategorySpotlightWidgetsForAllPeriods(referenceDate: Date,
                                                             periods: [BudgetPeriod] = BudgetPeriod.selectableCases) async {
        let defaultPeriod: BudgetPeriod = period == .custom ? .monthly : period
        WidgetSharedStore.writeCategorySpotlightDefaultPeriod(defaultPeriod.rawValue)
        for period in periods {
            let range = period.range(containing: referenceDate)
            let (summaries, _) = await loadSummaries(period: period, dateRange: range.start...range.end)
            guard !summaries.isEmpty else { continue }
            updateCategorySpotlightWidget(from: summaries, period: period)
        }
    }

    private func updateDayOfWeekWidgetsForAllPeriods(referenceDate: Date,
                                                     periods: [BudgetPeriod] = BudgetPeriod.selectableCases) async {
        let defaultPeriod: BudgetPeriod = period == .custom ? .monthly : period
        WidgetSharedStore.writeDayOfWeekDefaultPeriod(defaultPeriod.rawValue)
        for period in periods {
            let displayRange = rangeForWidgetPeriod(period, referenceDate: referenceDate)
            let (summaries, _) = await loadSummaries(period: period, dateRange: displayRange)
            guard !summaries.isEmpty else { continue }
            await updateDayOfWeekWidget(from: summaries, period: period, referenceDate: referenceDate)
        }
    }

    private func updateCategoryAvailabilityWidgetsForAllPeriods(referenceDate: Date,
                                                                periods: [BudgetPeriod] = BudgetPeriod.selectableCases) async {
        let defaultPeriod: BudgetPeriod = period == .custom ? .monthly : period
        WidgetSharedStore.writeCategoryAvailabilityDefaultPeriod(defaultPeriod.rawValue)
        WidgetSharedStore.writeCategoryAvailabilityDefaultSegment(CategoryAvailabilitySegment.combined.rawValue)
        WidgetSharedStore.writeCategoryAvailabilityDefaultSort("alphabetical")

        var categoryNames: Set<String> = []
        for period in periods {
            let range = period.range(containing: referenceDate)
            let (summaries, _) = await loadSummaries(period: period, dateRange: range.start...range.end)
            guard let summary = summaries.first else { continue }
            let caps = categoryCapsWidget(for: summary)
            for segment in CategoryAvailabilitySegment.allCases {
                let items = computeCategoryAvailabilityWidget(summary: summary, caps: caps, segment: segment)
                let snapshot = WidgetSharedStore.CategoryAvailabilitySnapshot(
                    items: items,
                    rangeLabel: summary.periodString,
                    updatedAt: Date()
                )
                WidgetSharedStore.writeCategoryAvailabilitySnapshot(snapshot, periodRaw: period.rawValue, segmentRaw: segment.rawValue)
                if segment == .combined {
                    categoryNames.formUnion(items.map(\.name))
                }
            }
        }
        let sortedNames = categoryNames.sorted { $0.localizedCaseInsensitiveCompare($1) == .orderedAscending }
        WidgetSharedStore.writeCategoryAvailabilityCategories(sortedNames)
    }

    private struct CardWidgetExpense {
        let name: String
        let amount: Double
        let date: Date?
        let hexColor: String?
    }

    private func updateCardWidgetsForAllPeriods(referenceDate: Date,
                                                periods: [BudgetPeriod] = BudgetPeriod.selectableCases) async {
        let defaultPeriod: BudgetPeriod = period == .custom ? .monthly : period
        WidgetSharedStore.writeCardWidgetDefaultPeriod(defaultPeriod.rawValue)

        let cardService = CardService()
        let plannedService = PlannedExpenseService()
        let unplannedService = UnplannedExpenseService()
        let context = CoreDataService.shared.viewContext

        var cardsForPicker: [WidgetSharedStore.CardWidgetCard] = []
        for period in periods {
            let range = period.range(containing: referenceDate)
            let interval = DateInterval(start: range.start, end: range.end)
            let (summaries, _) = await loadSummaries(period: period, dateRange: range.start...range.end)
            guard let summary = summaries.first else { continue }

            guard let budgetUUID = resolveBudgetUUID(for: summary.id, context: context) else { continue }
            let cards = (try? cardService.fetchCards(forBudgetID: budgetUUID)) ?? []
            if cardsForPicker.isEmpty, !cards.isEmpty {
                cardsForPicker = cards.compactMap { card in
                    guard let uuid = resolveCardUUID(for: card, context: context) else { return nil }
                    let cardItem = CardItem(from: card)
                    let themeColors = cardItem.theme.colors
                    let primaryHex = colorToHex(themeColors.0)
                    let secondaryHex = colorToHex(themeColors.1)
                    return WidgetSharedStore.CardWidgetCard(
                        id: uuid.uuidString,
                        name: cardItem.name,
                        themeName: cardItem.theme.rawValue,
                        primaryHex: primaryHex,
                        secondaryHex: secondaryHex,
                        patternName: nil
                    )
                }
            }

            for card in cards {
                guard let uuid = resolveCardUUID(for: card, context: context) else { continue }
                let cardItem = CardItem(from: card)
                let themeColors = cardItem.theme.colors
                let primaryHex = colorToHex(themeColors.0)
                let secondaryHex = colorToHex(themeColors.1)

                let unplanned = (try? unplannedService.fetchForCard(uuid, in: interval, sortedByDateAscending: false)) ?? []
                let planned = (try? plannedService.fetchForCard(uuid, in: interval, sortedByDateAscending: false)) ?? []

                let mappedUnplanned: [CardWidgetExpense] = unplanned.map { exp in
                    let desc = (exp.value(forKey: "descriptionText") as? String)
                        ?? (exp.value(forKey: "title") as? String) ?? ""
                    let cat = exp.value(forKey: "expenseCategory") as? ExpenseCategory
                    return CardWidgetExpense(
                        name: desc,
                        amount: exp.value(forKey: "amount") as? Double ?? 0,
                        date: exp.value(forKey: "transactionDate") as? Date,
                        hexColor: cat?.color
                    )
                }

                var seenPlannedKeys = Set<String>()
                let plannedActuals: [CardWidgetExpense] = planned.compactMap { exp in
                    guard exp.actualAmount != 0 else { return nil }
                    if let templateID = exp.globalTemplateID, let budget = exp.budget {
                        let dateKey = String(format: "%.0f", (exp.transactionDate ?? .distantPast).timeIntervalSince1970)
                        let key = "\(templateID.uuidString)|\(budget.objectID.uriRepresentation().absoluteString)|\(dateKey)|\(exp.actualAmount)|\(exp.plannedAmount)"
                        if seenPlannedKeys.contains(key) { return nil }
                        seenPlannedKeys.insert(key)
                    }
                    let desc = (exp.value(forKey: "descriptionText") as? String)
                        ?? (exp.value(forKey: "title") as? String) ?? ""
                    return CardWidgetExpense(
                        name: desc,
                        amount: exp.actualAmount,
                        date: exp.transactionDate,
                        hexColor: exp.expenseCategory?.color
                    )
                }

                let combined = mappedUnplanned + plannedActuals
                let totalSpent = combined.reduce(0) { $0 + $1.amount }
                let recent = combined.sorted {
                    let lhs = $0.date ?? .distantPast
                    let rhs = $1.date ?? .distantPast
                    return lhs > rhs
                }
                let top = combined.sorted { $0.amount > $1.amount }

                let recentTransactions = Array(recent.prefix(3)).map { expense in
                    WidgetSharedStore.CardWidgetSnapshot.Transaction(
                        name: expense.name,
                        amount: expense.amount,
                        date: expense.date ?? summary.periodStart,
                        hexColor: expense.hexColor
                    )
                }
                let topTransactions = Array(top.prefix(3)).map { expense in
                    WidgetSharedStore.CardWidgetSnapshot.Transaction(
                        name: expense.name,
                        amount: expense.amount,
                        date: expense.date ?? summary.periodStart,
                        hexColor: expense.hexColor
                    )
                }

                let snapshot = WidgetSharedStore.CardWidgetSnapshot(
                    cardID: uuid.uuidString,
                    cardName: cardItem.name,
                    cardThemeName: cardItem.theme.rawValue,
                    cardPrimaryHex: primaryHex,
                    cardSecondaryHex: secondaryHex,
                    cardPattern: nil,
                    totalSpent: totalSpent,
                    recentTransactions: recentTransactions,
                    topTransactions: topTransactions,
                    rangeLabel: summary.periodString,
                    updatedAt: Date()
                )
                WidgetSharedStore.writeCardWidgetSnapshot(snapshot, periodRaw: period.rawValue, cardID: uuid.uuidString)
            }
        }

        WidgetSharedStore.writeCardWidgetCards(cardsForPicker)
    }

    private func resolveCardUUID(for card: Card, context: NSManagedObjectContext) -> UUID? {
        if let existing = card.value(forKey: "id") as? UUID { return existing }
        let newID = UUID()
        card.setValue(newID, forKey: "id")
        try? context.save()
        return newID
    }

    private func resolveBudgetUUID(for budgetID: NSManagedObjectID, context: NSManagedObjectContext) -> UUID? {
        guard let budget = try? context.existingObject(with: budgetID) as? Budget else { return nil }
        if let existing = budget.value(forKey: "id") as? UUID { return existing }
        let newID = UUID()
        budget.setValue(newID, forKey: "id")
        try? context.save()
        return newID
    }

    private func colorToHex(_ color: Color) -> String? {
        #if canImport(UIKit)
        let uiColor = UIColor(color)
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        guard uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha) else { return nil }
        return String(
            format: "#%02X%02X%02X",
            Int(red * 255),
            Int(green * 255),
            Int(blue * 255)
        )
        #else
        return nil
        #endif
    }

    private struct CategorySpendKey: Hashable {
        let name: String
        let hex: String
    }

    private func categoryCapsWidget(for summary: BudgetSummary) -> [String: (planned: Double?, variable: Double?)] {
        let ctx = CoreDataService.shared.viewContext
        var map: [String: (planned: Double?, variable: Double?)] = [:]

        func fetchCaps(segment: String) {
            let key = capsPeriodKey(start: summary.periodStart, end: summary.periodEnd, segment: segment)
            let fetch = NSFetchRequest<CategorySpendingCap>(entityName: "CategorySpendingCap")
            fetch.predicate = NSPredicate(format: "period == %@", key)
            let results = (try? ctx.fetch(fetch)) ?? []
            for cap in results {
                guard let category = cap.category,
                      let name = category.name else { continue }
                let norm = normalizedCategoryName(name)
                var entry = map[norm] ?? (planned: nil, variable: nil)
                if (cap.expenseType ?? "").lowercased() == "max" {
                    if segment == "planned" { entry.planned = cap.amount } else { entry.variable = cap.amount }
                    map[norm] = entry
                }
            }
        }

        fetchCaps(segment: "planned")
        fetchCaps(segment: "variable")
        return map
    }

    private func computeCategoryAvailabilityWidget(summary: BudgetSummary, caps: [String: (planned: Double?, variable: Double?)], segment: CategoryAvailabilitySegment) -> [WidgetSharedStore.CategoryAvailabilitySnapshot.Item] {
        let remainingIncome = max(summary.actualIncomeTotal - (summary.plannedExpensesActualTotal + summary.variableExpensesTotal), 0)
        let breakdown: [BudgetSummary.CategorySpending]
        switch segment {
        case .combined:
            breakdown = summary.categoryBreakdown
        case .planned:
            breakdown = summary.plannedCategoryBreakdown
        case .variable:
            breakdown = summary.variableCategoryBreakdown
        }

        let items = breakdown.map { cat -> WidgetSharedStore.CategoryAvailabilitySnapshot.Item in
            let norm = normalizedCategoryName(cat.categoryName)
            let capTuple = caps[norm]
            let plannedDefault = summary.plannedCategoryDefaultCaps[norm]
            let capValue: Double?
            switch segment {
            case .combined:
                let plannedCap = capTuple?.planned ?? plannedDefault
                let variableCap = capTuple?.variable
                let combined = (plannedCap ?? 0) + (variableCap ?? 0)
                capValue = combined > 0 ? combined : nil
            case .planned:
                capValue = capTuple?.planned ?? plannedDefault
            case .variable:
                capValue = capTuple?.variable
            }
            let hasCap = capValue != nil
            let capAmount = capValue ?? 0
            let capRemaining = max(capAmount - cat.amount, 0)
            let available = hasCap ? capRemaining : remainingIncome
            return WidgetSharedStore.CategoryAvailabilitySnapshot.Item(
                name: cat.categoryName,
                spent: cat.amount,
                cap: capValue,
                available: available,
                hexColor: cat.hexColor
            )
        }

        return items.sorted { lhs, rhs in
            lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending
        }
    }

    private struct DaySpendTotal {
        var total: Double
        var categoryTotals: [CategorySpendKey: Double]
    }

    private struct WidgetSpendBucket {
        let label: String
        let amount: Double
        let hexColors: [String]
    }

    private func daySpendTotalsForWidget(summaryID: NSManagedObjectID, in range: ClosedRange<Date>) async -> [Date: DaySpendTotal] {
        await withCheckedContinuation { continuation in
            let ctx = CoreDataService.shared.newBackgroundContext()
            ctx.perform {
                guard let budget = try? ctx.existingObject(with: summaryID) as? Budget else {
                    continuation.resume(returning: [:])
                    return
                }
                let cal = Calendar.current
                var totals: [Date: DaySpendTotal] = [:]

                func add(amount: Double, date: Date?, category: ExpenseCategory?) {
                    guard let date else { return }
                    let day = cal.startOfDay(for: date)
                    var entry = totals[day] ?? DaySpendTotal(total: 0, categoryTotals: [:])
                    entry.total += amount
                    if amount > 0 {
                        let name = category?.name?.trimmingCharacters(in: .whitespacesAndNewlines)
                        let safeName = name?.isEmpty == false ? name! : "Uncategorized"
                        let hex = category?.color?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
                        let key = CategorySpendKey(name: safeName, hex: hex)
                        entry.categoryTotals[key, default: 0] += amount
                    }
                    totals[day] = entry
                }

                let plannedReq = NSFetchRequest<PlannedExpense>(entityName: "PlannedExpense")
                let budgetWorkspaceID = budget.value(forKey: "workspaceID") as? UUID
                plannedReq.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
                    NSPredicate(format: "budget == %@", budget),
                    NSPredicate(format: "transactionDate >= %@ AND transactionDate <= %@", range.lowerBound as NSDate, range.upperBound as NSDate),
                    budgetWorkspaceID.map { WorkspaceService.predicate(for: $0) } ?? NSPredicate(value: true)
                ])
                if let planned = try? ctx.fetch(plannedReq) {
                    for exp in planned {
                        add(amount: exp.actualAmount, date: exp.transactionDate, category: exp.expenseCategory)
                    }
                }

                if let cards = budget.cards as? Set<Card>, !cards.isEmpty {
                    let varReq = NSFetchRequest<UnplannedExpense>(entityName: "UnplannedExpense")
                    varReq.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
                        NSPredicate(format: "card IN %@", cards as NSSet),
                        NSPredicate(format: "transactionDate >= %@ AND transactionDate <= %@", range.lowerBound as NSDate, range.upperBound as NSDate),
                        budgetWorkspaceID.map { WorkspaceService.predicate(for: $0) } ?? NSPredicate(value: true)
                    ])
                    if let vars = try? ctx.fetch(varReq) {
                        for exp in vars {
                            add(amount: exp.amount, date: exp.transactionDate, category: exp.expenseCategory)
                        }
                    }
                }

                continuation.resume(returning: totals)
            }
        }
    }

    private func widgetBuckets(for period: BudgetPeriod, range: ClosedRange<Date>, dayTotals: [Date: DaySpendTotal]) -> [WidgetSpendBucket] {
        switch period {
        case .daily:
            return bucketsForDays(range: range, dayTotals: dayTotals, labelMode: .date)
        case .weekly:
            return bucketsForDays(range: range, dayTotals: dayTotals, labelMode: .weekdayInitial)
        case .biWeekly:
            let weekRanges = splitRange(range, daysPerBucket: 7)
            return bucketsForRanges(weekRanges, dayTotals: dayTotals, labelMode: .biWeeklyWeek)
        case .monthly:
            let weekRanges = splitRange(range, daysPerBucket: 7)
            return bucketsForRanges(weekRanges, dayTotals: dayTotals, labelMode: .dayRange)
        case .quarterly:
            return bucketsForMonths(range: range, dayTotals: dayTotals)
        case .yearly:
            return bucketsForMonths(range: range, dayTotals: dayTotals)
        case .custom:
            return bucketsForDays(range: range, dayTotals: dayTotals, labelMode: .date)
        }
    }

    private enum DayLabelMode {
        case weekdayInitial
        case date
        case dayRange
        case biWeeklyWeek
    }

    private func bucketsForDays(range: ClosedRange<Date>, dayTotals: [Date: DaySpendTotal], labelMode: DayLabelMode) -> [WidgetSpendBucket] {
        let cal = Calendar.current
        let weekdaySymbols = cal.shortWeekdaySymbols
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        let dates = daysInRange(range)
        return dates.map { day in
            let entry = dayTotals[day] ?? DaySpendTotal(total: 0, categoryTotals: [:])
        let label: String
        switch labelMode {
        case .weekdayInitial:
            let weekdayIndex = cal.component(.weekday, from: day) - 1
            let symbol = weekdaySymbols.indices.contains(weekdayIndex) ? weekdaySymbols[weekdayIndex] : "D"
            label = String(symbol.prefix(1))
        case .date:
            label = formatter.string(from: day)
        case .dayRange:
            label = formatter.string(from: day)
        case .biWeeklyWeek:
            label = formatter.string(from: day)
        }
            let hexes = hexesForCategoryTotals(entry.categoryTotals)
            return WidgetSpendBucket(label: label, amount: entry.total, hexColors: hexes)
        }
    }

    private func bucketsForRanges(_ ranges: [ClosedRange<Date>], dayTotals: [Date: DaySpendTotal], labelMode: DayLabelMode) -> [WidgetSpendBucket] {
        let cal = Calendar.current
        let rangeFormatter = DateFormatter()
        rangeFormatter.dateFormat = "MMM d"
        return ranges.map { range in
            let days = daysInRange(range)
            var total = 0.0
            var catTotals: [CategorySpendKey: Double] = [:]
            for day in days {
                let entry = dayTotals[day] ?? DaySpendTotal(total: 0, categoryTotals: [:])
                total += entry.total
                for (key, amt) in entry.categoryTotals {
                    catTotals[key, default: 0] += amt
                }
            }
            let label: String
            switch labelMode {
            case .dayRange:
                label = dayRangeLabel(for: range)
            case .biWeeklyWeek:
                let weekIndex = ranges.firstIndex(where: { $0.lowerBound == range.lowerBound }) ?? 0
                label = "W\(weekIndex + 1)"
            case .weekdayInitial:
                let weekdayIndex = cal.component(.weekday, from: range.lowerBound) - 1
                let symbol = cal.shortWeekdaySymbols.indices.contains(weekdayIndex) ? cal.shortWeekdaySymbols[weekdayIndex] : "D"
                label = String(symbol.prefix(1))
            case .date:
                let startLabel = rangeFormatter.string(from: range.lowerBound)
                let endLabel = rangeFormatter.string(from: range.upperBound)
                label = "\(startLabel)–\(endLabel)"
            }
            let hexes = hexesForCategoryTotals(catTotals)
            return WidgetSpendBucket(label: label, amount: total, hexColors: hexes)
        }
    }

    private func bucketsForMonths(range: ClosedRange<Date>, dayTotals: [Date: DaySpendTotal]) -> [WidgetSpendBucket] {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM"
        return monthsInRange(range).map { monthRange in
            let days = daysInRange(monthRange)
            var total = 0.0
            var catTotals: [CategorySpendKey: Double] = [:]
            for day in days {
                let entry = dayTotals[day] ?? DaySpendTotal(total: 0, categoryTotals: [:])
                total += entry.total
                for (key, amt) in entry.categoryTotals {
                    catTotals[key, default: 0] += amt
                }
            }
            let label = formatter.string(from: monthRange.lowerBound)
            let hexes = hexesForCategoryTotals(catTotals)
            return WidgetSpendBucket(label: label, amount: total, hexColors: hexes)
        }
    }

    private func widgetRangeLabel(for range: ClosedRange<Date>) -> String {
        let f = DateFormatter()
        f.dateStyle = .medium
        let cal = Calendar.current
        if cal.isDate(range.lowerBound, inSameDayAs: range.upperBound) {
            return f.string(from: range.lowerBound)
        }
        return "\(f.string(from: range.lowerBound)) – \(f.string(from: range.upperBound))"
    }

    private func rangeForWidgetPeriod(_ period: BudgetPeriod, referenceDate: Date) -> ClosedRange<Date> {
        let cal = Calendar(identifier: .gregorian)
        switch period {
        case .daily:
            let start = cal.startOfDay(for: referenceDate)
            let end = cal.date(byAdding: .day, value: 1, to: start)?.addingTimeInterval(-1) ?? start
            return start...end
        case .weekly:
            return sundayWeekRange(containing: referenceDate)
        case .biWeekly:
            let weekStart = sundayWeekRange(containing: referenceDate).lowerBound
            let end = cal.date(byAdding: .day, value: 14, to: weekStart)?.addingTimeInterval(-1) ?? weekStart
            return weekStart...end
        case .monthly, .quarterly, .yearly:
            let r = period.range(containing: referenceDate)
            return r.start...r.end
        case .custom:
            let start = cal.startOfDay(for: referenceDate)
            let end = cal.date(byAdding: .day, value: 1, to: start)?.addingTimeInterval(-1) ?? start
            return start...end
        }
    }

    private func sundayWeekRange(containing date: Date) -> ClosedRange<Date> {
        var cal = Calendar(identifier: .gregorian)
        cal.firstWeekday = 1
        let comps = cal.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)
        let start = cal.date(from: comps) ?? cal.startOfDay(for: date)
        let end = cal.date(byAdding: .day, value: 7, to: start)?.addingTimeInterval(-1) ?? start
        return start...end
    }

    private func splitRange(_ range: ClosedRange<Date>, daysPerBucket: Int) -> [ClosedRange<Date>] {
        var ranges: [ClosedRange<Date>] = []
        let cal = Calendar.current
        var cursor = cal.startOfDay(for: range.lowerBound)
        let end = cal.startOfDay(for: range.upperBound)
        while cursor <= end {
            let next = cal.date(byAdding: .day, value: daysPerBucket - 1, to: cursor) ?? cursor
            let bucketEnd = min(next, end)
            ranges.append(cursor...bucketEnd)
            guard let advance = cal.date(byAdding: .day, value: daysPerBucket, to: cursor) else { break }
            cursor = advance
        }
        return ranges
    }

    private func dayRangeLabel(for range: ClosedRange<Date>) -> String {
        let cal = Calendar.current
        let startDay = cal.component(.day, from: range.lowerBound)
        let endDay = cal.component(.day, from: range.upperBound)
        let sameMonth = cal.isDate(range.lowerBound, equalTo: range.upperBound, toGranularity: .month)
        if sameMonth {
            return "\(startDay)–\(endDay)"
        }
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        let startLabel = formatter.string(from: range.lowerBound)
        let endLabel = formatter.string(from: range.upperBound)
        return "\(startLabel)–\(endLabel)"
    }

    private func daysInRange(_ range: ClosedRange<Date>) -> [Date] {
        var dates: [Date] = []
        let cal = Calendar.current
        var current = cal.startOfDay(for: range.lowerBound)
        let end = cal.startOfDay(for: range.upperBound)
        while current <= end {
            dates.append(current)
            guard let next = cal.date(byAdding: .day, value: 1, to: current) else { break }
            current = next
        }
        return dates
    }

    private func monthsInRange(_ range: ClosedRange<Date>) -> [ClosedRange<Date>] {
        var ranges: [ClosedRange<Date>] = []
        let cal = Calendar.current
        var cursor = BudgetPeriod.monthly.start(of: range.lowerBound)
        let end = range.upperBound
        while cursor <= end {
            let monthRange = BudgetPeriod.monthly.range(containing: cursor)
            let boundedStart = max(monthRange.start, range.lowerBound)
            let boundedEnd = min(monthRange.end, end)
            ranges.append(boundedStart...boundedEnd)
            guard let next = cal.date(byAdding: .month, value: 1, to: cursor) else { break }
            cursor = next
        }
        return ranges
    }

    private func hexesForCategoryTotals(_ totals: [CategorySpendKey: Double]) -> [String] {
        let sorted = totals.sorted { $0.value > $1.value }.map(\.key)
        let hexes = sorted.map(\.hex).filter { !$0.isEmpty }
        return hexes
    }

    private func widgetFallbackHexes(from dayTotals: [Date: DaySpendTotal]) -> [String] {
        var totals: [CategorySpendKey: Double] = [:]
        for entry in dayTotals.values {
            for (key, amt) in entry.categoryTotals {
                totals[key, default: 0] += amt
            }
        }
        let hexes = totals.sorted { $0.value > $1.value }.map(\.key.hex).filter { !$0.isEmpty }
        return Array(hexes.prefix(2))
    }

    deinit {
        if let observer = dataStoreObserver { NotificationCenter.default.removeObserver(observer) }
        if let workspaceObserver { NotificationCenter.default.removeObserver(workspaceObserver) }
        cancellables.forEach { $0.cancel() }
    }

    private func loadSummaries(period: BudgetPeriod, dateRange: ClosedRange<Date>) async -> (summaries: [BudgetSummary], budgetIDs: [NSManagedObjectID]) {
        let workspaceID = activeWorkspaceID
        return await withCheckedContinuation { continuation in
            let backgroundContext = CoreDataService.shared.newBackgroundContext()
            backgroundContext.perform {
                // Include any budgets that overlap the selected range. Do NOT
                // require exact period alignment so empty or partial budgets
                // still appear on Home and do not cause empty/loaded flapping.
                let budgets = Self.fetchBudgets(overlapping: dateRange, in: backgroundContext, workspaceID: workspaceID)
                let allCategories = Self.fetchAllCategories(in: backgroundContext, workspaceID: workspaceID)
                let allIncomes = Self.fetchIncomes(overlapping: dateRange, in: backgroundContext, workspaceID: workspaceID)

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
                        in: backgroundContext,
                        workspaceID: workspaceID
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
        let confirm = UserDefaultsAppSettingsStore().bool(for: .confirmBeforeDelete) ?? true
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
    private nonisolated static func fetchBudgets(overlapping range: ClosedRange<Date>,
                                                 in context: NSManagedObjectContext,
                                                 workspaceID: UUID) -> [Budget] {
        let req = NSFetchRequest<Budget>(entityName: "Budget")
        let start = range.lowerBound
        let end = range.upperBound

        // Overlap predicate: (startDate <= end) AND (endDate >= start)
        req.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
            NSPredicate(format: "startDate <= %@", end as NSDate),
            NSPredicate(format: "endDate >= %@", start as NSDate),
            WorkspaceService.predicate(for: workspaceID)
        ])
        req.sortDescriptors = [
            NSSortDescriptor(key: "startDate", ascending: true),
            NSSortDescriptor(key: "name", ascending: true, selector: #selector(NSString.localizedCaseInsensitiveCompare(_:)))
        ]
        do { return try context.fetch(req) } catch { return [] }
    }

    private nonisolated static func fetchAllCategories(in context: NSManagedObjectContext,
                                                       workspaceID: UUID) -> [ExpenseCategory] {
        let req = NSFetchRequest<ExpenseCategory>(entityName: "ExpenseCategory")
        req.predicate = WorkspaceService.predicate(for: workspaceID)
        req.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true, selector: #selector(NSString.localizedCaseInsensitiveCompare(_:)))]
        return (try? context.fetch(req)) ?? []
    }

    private nonisolated static func fetchIncomes(overlapping range: ClosedRange<Date>,
                                                 in context: NSManagedObjectContext,
                                                 workspaceID: UUID) -> [Income] {
        let req = NSFetchRequest<Income>(entityName: "Income")
        req.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
            incomeDatePredicate(for: range),
            WorkspaceService.predicate(for: workspaceID)
        ])
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
        in context: NSManagedObjectContext,
        workspaceID: UUID
    ) -> BudgetSummary {
        // MARK: Planned Expenses (attached to budget)
        let plannedFetch = NSFetchRequest<PlannedExpense>(entityName: "PlannedExpense")
        plannedFetch.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
            NSPredicate(format: "budget == %@", budget),
            WorkspaceService.predicate(for: workspaceID)
        ])
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
                NSPredicate(format: "transactionDate >= %@ AND transactionDate <= %@", periodStart as NSDate, periodEnd as NSDate),
                WorkspaceService.predicate(for: workspaceID)
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

//
//  IncomeScreenViewModel.swift
//  SoFar
//
//  Holds selected date, fetches incomes for the date, and performs CRUD via IncomeService.
//

import Foundation
import CoreData
import Combine

// MARK: - IncomeScreenViewModel
@MainActor
final class IncomeScreenViewModel: ObservableObject {
    // MARK: Public, @Published
    @Published var selectedDate: Date? = Date()
    @Published private(set) var incomesForDay: [Income] = []
    @Published private(set) var plannedTotalForSelectedDate: Double = 0
    @Published private(set) var actualTotalForSelectedDate: Double = 0
    @Published private(set) var totalForSelectedDate: Double = 0
    @Published private(set) var plannedTotalForSelectedWeek: Double = 0
    @Published private(set) var actualTotalForSelectedWeek: Double = 0
    @Published private(set) var totalForSelectedWeek: Double = 0
    @Published private(set) var eventsByDay: [Date: [IncomeService.IncomeEvent]] = [:]
    
    // MARK: Private
    private let incomeService: IncomeService
    private let calendar: Calendar
    private var cancellables: Set<AnyCancellable> = []

    /// Cache of month-start anchors → day/event mappings to avoid re-fetching
    /// the entire multi-year range on every selection change. Each entry holds
    /// the results of `IncomeService.eventsByDay(inMonthContaining:)`.
    private var cachedMonthlyEvents: [Date: [Date: [IncomeService.IncomeEvent]]] = [:]

    /// Maximum number of distinct months to keep in memory at once. Older
    /// months are pruned when this limit is exceeded.
    private let maxCachedMonths: Int = 24
    
    // MARK: Init
    init(incomeService: IncomeService = IncomeService()) {
        self.incomeService = incomeService
        self.calendar = .current

        let ms = DataChangeDebounce.milliseconds()
        NotificationCenter.default.publisher(for: .dataStoreDidChange)
            .debounce(for: .milliseconds(ms), scheduler: RunLoop.main)
            .sink { [weak self] _ in
                guard let self else { return }
                // Defer mutations to avoid publishing during view updates
                DispatchQueue.main.async { [weak self] in
                    guard let self else { return }
                    self.clearEventCaches()
                    if self.selectedDate == nil {
                        self.selectedDate = Date()
                    }
                    self.reloadForSelectedDay(forceMonthReload: true)
                }
            }
            .store(in: &cancellables)
    }

    deinit {
        cancellables.forEach { $0.cancel() }
    }
    
    // MARK: Titles
    var selectedDateTitle: String {
        guard let d = selectedDate else { return "—" }
        return DateFormatter.localizedString(from: d, dateStyle: .full, timeStyle: .none)
    }
    
    var totalForSelectedDateText: String {
        NumberFormatter.currency.string(from: totalForSelectedDate as NSNumber) ?? ""
    }
    
    // MARK: Loading
    func reloadForSelectedDay(forceMonthReload: Bool = false) {
        // Defer to next run loop tick to ensure we don't publish during view updates
        DispatchQueue.main.async { [weak self] in
            guard let self = self, let d = self.selectedDate else { return }
            self.load(day: d, forceMonthReload: forceMonthReload)
        }
    }

    func load(day: Date, forceMonthReload: Bool = false) {
        do {
            incomesForDay = try incomeService.fetchIncomes(on: day)

            let dayTotals = totals(from: incomesForDay)
            plannedTotalForSelectedDate = dayTotals.planned
            actualTotalForSelectedDate = dayTotals.actual
            totalForSelectedDate = dayTotals.planned + dayTotals.actual

            let weekTotals = try totalsForWeek(containing: day)
            plannedTotalForSelectedWeek = weekTotals.planned
            actualTotalForSelectedWeek = weekTotals.actual
            totalForSelectedWeek = weekTotals.planned + weekTotals.actual
            refreshEventsCache(for: day, force: forceMonthReload)
        } catch {
            AppLog.viewModel.error("Income fetch error: \(String(describing: error))")
            incomesForDay = []
            plannedTotalForSelectedDate = 0
            actualTotalForSelectedDate = 0
            totalForSelectedDate = 0
            plannedTotalForSelectedWeek = 0
            actualTotalForSelectedWeek = 0
            totalForSelectedWeek = 0
            eventsByDay = [:]
            cachedMonthlyEvents.removeAll()
        }
    }

    // MARK: CRUD
    func delete(income: Income, scope: RecurrenceScope = .all) {
        do {
            try incomeService.deleteIncome(income, scope: scope)
            let day = selectedDate ?? income.date ?? Date()
            // Defer cache clearing and reload to avoid publishing during view updates
            DispatchQueue.main.async { [weak self] in
                guard let self else { return }
                if scope == .future || scope == .all {
                    self.clearEventCaches()
                }
                self.load(day: day, forceMonthReload: true)
            }
        } catch {
            AppLog.viewModel.error("Income delete error: \(String(describing: error))")
        }
    }
    
    // MARK: Formatting
    func currencyString(for amount: Double) -> String {
        NumberFormatter.currency.string(from: amount as NSNumber) ?? String(format: "%.2f", amount)
    }

    // MARK: Events Summary
    func summary(for date: Date) -> (planned: Double, actual: Double)? {
        let day = calendar.startOfDay(for: date)
        guard let events = eventsByDay[day] else { return nil }
        let planned = events.filter { $0.isPlanned }.reduce(0) { $0 + $1.amount }
        let actual = events.filter { !$0.isPlanned }.reduce(0) { $0 + $1.amount }
        if planned == 0 && actual == 0 { return nil }
        return (planned, actual)
    }

    // MARK: - Event Cache Management
    /// Refreshes the cached calendar events for the month containing `date`.
    /// When `force` is `true` the month is re-fetched even if it already
    /// exists in the cache.
    private func refreshEventsCache(for date: Date, force: Bool) {
        let monthAnchor = monthStart(for: date)
        if !force, cachedMonthlyEvents[monthAnchor] != nil {
            let horizon = dynamicHorizon(for: date)
            prefetchMonths(from: date, monthsBefore: horizon.before, monthsAfter: horizon.after)
            return
        }

        if let rawMonthEvents = try? incomeService.eventsByDay(inMonthContaining: date) {
            let remapped = remapEventsToDisplayCalendar(rawMonthEvents)
            cachedMonthlyEvents[monthAnchor] = remapped
            trimCacheIfNeeded()
            rebuildEventsByDay()
        }

        let horizon = dynamicHorizon(for: date)
        prefetchMonths(from: date, monthsBefore: horizon.before, monthsAfter: horizon.after)
    }

    /// Prefetches a horizon of months around the provided date to keep
    /// calendar scrolling responsive without requiring a tap to load.
    private func prefetchMonths(from date: Date, monthsBefore: Int, monthsAfter: Int) {
        guard monthsBefore >= 0 || monthsAfter >= 0 else { return }

        if monthsBefore > 0 {
            for delta in stride(from: -monthsBefore, through: -1, by: 1) {
                if let d = calendar.date(byAdding: .month, value: delta, to: date) {
                    _ = ensureMonthCached(for: d)
                }
            }
        }
        if monthsAfter > 0 {
            for delta in 1...monthsAfter {
                if let d = calendar.date(byAdding: .month, value: delta, to: date) {
                    _ = ensureMonthCached(for: d)
                }
            }
        }
    }

    /// Computes a dynamic prefetch horizon based on the earliest and latest
    /// persisted income dates. Incomes without explicit end dates still have
    /// children persisted for roughly a year, so the latest persisted date
    /// naturally bounds the horizon.
    private func dynamicHorizon(for date: Date) -> (before: Int, after: Int) {
        // Default small horizon when store is empty.
        let defaults = (before: 2, after: 3)
        guard let all = try? incomeService.fetchAllIncomes(sortedByDateAscending: true),
              let firstDate = all.first?.date else {
            return defaults
        }
        let lastDate = all.last?.date ?? firstDate

        let selectedMonth = monthStart(for: date)
        let firstMonth = monthStart(for: firstDate)
        let lastMonth = monthStart(for: lastDate)

        let before = max(0, calendar.dateComponents([.month], from: firstMonth, to: selectedMonth).month ?? 0)
        let after  = max(0, calendar.dateComponents([.month], from: selectedMonth, to: lastMonth).month ?? 0)

        // Cap total span to cache capacity to avoid memory churn.
        let maxSpan = max(0, maxCachedMonths - 1)
        if before + after > maxSpan {
            let cappedAfter = max(0, maxSpan - before)
            return (before: before, after: cappedAfter)
        }
        return (before: before, after: after)
    }

    /// Ensures the month containing `date` is cached. Returns `true` when a
    /// fetch occurred.
    @discardableResult
    private func ensureMonthCached(for date: Date) -> Bool {
        let monthAnchor = monthStart(for: date)
        guard cachedMonthlyEvents[monthAnchor] == nil else { return false }
        guard let rawMonthEvents = try? incomeService.eventsByDay(inMonthContaining: date) else {
            return false
        }
        let remapped = remapEventsToDisplayCalendar(rawMonthEvents)
        cachedMonthlyEvents[monthAnchor] = remapped
        trimCacheIfNeeded()
        rebuildEventsByDay()
        return true
    }

    /// Removes older cached months when the limit is exceeded.
    private func trimCacheIfNeeded() {
        guard cachedMonthlyEvents.count > maxCachedMonths else { return }
        let sortedKeys = cachedMonthlyEvents.keys.sorted()
        let overflow = cachedMonthlyEvents.count - maxCachedMonths
        for key in sortedKeys.prefix(overflow) {
            cachedMonthlyEvents.removeValue(forKey: key)
        }
    }

    /// Rebuilds the published `eventsByDay` dictionary from the cached months.
    private func rebuildEventsByDay() {
        eventsByDay = cachedMonthlyEvents.values.reduce(into: [:]) { partial, monthMap in
            for (day, events) in monthMap {
                partial[day] = events
            }
        }
    }

    /// Converts service-grouped events (keyed by the service's calendar) into
    /// a map keyed by this view model's display calendar.
    private func remapEventsToDisplayCalendar(_ monthEvents: [Date: [IncomeService.IncomeEvent]]) -> [Date: [IncomeService.IncomeEvent]] {
        var remapped: [Date: [IncomeService.IncomeEvent]] = [:]
        for events in monthEvents.values {
            for e in events {
                let key = calendar.startOfDay(for: e.date)
                remapped[key, default: []].append(e)
            }
        }
        return remapped
    }

    /// Clears all cached month data and published summaries.
    private func clearEventCaches() {
        cachedMonthlyEvents.removeAll()
        eventsByDay = [:]
    }

    /// Normalized start-of-month date for caching keys.
    private func monthStart(for date: Date) -> Date {
        calendar.date(from: calendar.dateComponents([.year, .month], from: date))
        ?? calendar.startOfDay(for: date)
    }

    /// Calculates the totals for the provided incomes, broken out by planned vs actual.
    private func totals(from incomes: [Income]) -> (planned: Double, actual: Double) {
        incomes.reduce(into: (planned: 0.0, actual: 0.0)) { partial, income in
            if income.isPlanned {
                partial.planned += income.amount
            } else {
                partial.actual += income.amount
            }
        }
    }

    /// Calculates the sum of incomes for the week containing the provided date, separated by planned/actual.
    private func totalsForWeek(containing date: Date) throws -> (planned: Double, actual: Double) {
        guard let interval = weekInterval(containing: date) else { return (0, 0) }
        let incomes = try incomeService.fetchIncomes(in: interval)
        return totals(from: incomes)
    }

    /// Returns the closed date interval for the week containing `date` using a Sunday-based calendar.
    private func weekInterval(containing date: Date) -> DateInterval? {
        var cal = calendar
        cal.firstWeekday = 1
        guard let start = cal.dateInterval(of: .weekOfYear, for: date)?.start,
              let end = cal.date(byAdding: DateComponents(day: 7, second: -1), to: start) else {
            return nil
        }
        return DateInterval(start: start, end: end)
    }
}

// MARK: - Currency NumberFormatter
private extension NumberFormatter {
    static let currency: NumberFormatter = {
        let f = NumberFormatter()
        f.numberStyle = .currency
        return f
    }()
}

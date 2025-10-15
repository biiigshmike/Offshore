import Foundation
import Testing
@testable import Offshore

@MainActor
struct IncomeScreenViewModelTests {

    private func freshIncomeService(calendar: Calendar = TestUtils.utcCalendar()) throws -> IncomeService {
        _ = try TestUtils.resetStore()
        return IncomeService(calendar: calendar)
    }

    private func monthStart(_ date: Date, calendar: Calendar) -> Date {
        calendar.date(from: calendar.dateComponents([.year, .month], from: date))
        ?? calendar.startOfDay(for: date)
    }

    @Test
    func load_refreshes_totals_and_handles_recurring_deletion() throws {
        let calendar = TestUtils.utcCalendar()
        let service = try freshIncomeService(calendar: calendar)

        let january13 = TestUtils.makeDate(2025, 1, 13)
        let january15 = TestUtils.makeDate(2025, 1, 15)
        let january17 = TestUtils.makeDate(2025, 1, 17)
        let february15 = TestUtils.makeDate(2025, 2, 15)
        let april15 = TestUtils.makeDate(2025, 4, 15)

        _ = try service.createIncome(
            source: "Salary",
            amount: 2_000,
            date: january15,
            isPlanned: true,
            recurrence: "monthly",
            recurrenceEndDate: april15
        )

        _ = try service.createIncome(
            source: "Freelance",
            amount: 500,
            date: january15,
            isPlanned: false
        )

        _ = try service.createIncome(
            source: "Gig Prep",
            amount: 300,
            date: january13,
            isPlanned: true
        )

        _ = try service.createIncome(
            source: "Weekend Work",
            amount: 200,
            date: january17,
            isPlanned: false
        )

        _ = try service.createIncome(
            source: "Contract",
            amount: 650,
            date: TestUtils.makeDate(2025, 3, 20),
            isPlanned: false
        )

        let viewModel = IncomeScreenViewModel(incomeService: service)
        let tolerance = 0.0001

        viewModel.selectedDate = january15
        viewModel.load(day: january15, forceMonthReload: true)

        #expect(abs(viewModel.plannedTotalForSelectedDate - 2_000) < tolerance)
        #expect(abs(viewModel.actualTotalForSelectedDate - 500) < tolerance)
        #expect(abs(viewModel.plannedTotalForSelectedWeek - 2_300) < tolerance)
        #expect(abs(viewModel.actualTotalForSelectedWeek - 700) < tolerance)

        let januaryKey = Calendar.current.startOfDay(for: january15)
        let januaryEvents = viewModel.eventsByDay[januaryKey] ?? []
        #expect(januaryEvents.contains(where: { $0.source == "Salary" && $0.isPlanned && abs($0.amount - 2_000) < tolerance }))
        #expect(januaryEvents.contains(where: { $0.source == "Freelance" && !$0.isPlanned && abs($0.amount - 500) < tolerance }))

        let marchKey = Calendar.current.startOfDay(for: TestUtils.makeDate(2025, 3, 20))
        let marchEvents = viewModel.eventsByDay[marchKey] ?? []
        #expect(marchEvents.contains(where: { $0.source == "Contract" && !$0.isPlanned }))

        viewModel.selectedDate = february15
        viewModel.load(day: february15, forceMonthReload: true)

        #expect(abs(viewModel.plannedTotalForSelectedDate - 2_000) < tolerance)
        #expect(abs(viewModel.actualTotalForSelectedDate) < tolerance)

        let februaryIncomes = try service.fetchIncomes(on: february15)
        guard let child = februaryIncomes.first(where: { $0.parentID != nil }) else {
            #expect(false, "Expected a recurring child instance on February 15")
            return
        }

        viewModel.delete(income: child, scope: .instance)

        #expect(abs(viewModel.plannedTotalForSelectedDate) < tolerance)
        #expect(abs(viewModel.plannedTotalForSelectedWeek) < tolerance)

        let februaryKey = Calendar.current.startOfDay(for: february15)
        let februaryEvents = viewModel.eventsByDay[februaryKey] ?? []
        #expect(februaryEvents.isEmpty)

        let cachedAfterDelete = Mirror(reflecting: viewModel).descendant("cachedMonthlyEvents") as? [Date: [Date: [IncomeService.IncomeEvent]]]
        let februaryMonthStart = monthStart(february15, calendar: Calendar.current)
        let cachedFebruaryDays = cachedAfterDelete?[februaryMonthStart] ?? [:]
        #expect((cachedFebruaryDays[februaryKey] ?? []).isEmpty)
    }

    @Test
    func cache_prefetch_respects_dynamic_horizon_limits() throws {
        let calendar = TestUtils.utcCalendar()
        let service = try freshIncomeService(calendar: calendar)

        let base = TestUtils.makeDate(2024, 1, 1)
        var seededMonths: [Date] = []
        for offset in 0..<40 {
            guard let rawDate = calendar.date(byAdding: DateComponents(month: offset), to: base) else { continue }
            guard let normalized = calendar.date(bySettingHour: 12, minute: 0, second: 0, of: rawDate) else { continue }
            seededMonths.append(normalized)
            _ = try service.createIncome(
                source: "Income \(offset)",
                amount: Double(100 + offset),
                date: normalized,
                isPlanned: offset % 2 == 0
            )
        }

        let viewModel = IncomeScreenViewModel(incomeService: service)

        let selected = seededMonths[20]
        viewModel.selectedDate = selected
        viewModel.load(day: selected, forceMonthReload: true)

        func cachedMonths(_ vm: IncomeScreenViewModel) -> [Date] {
            let cache = Mirror(reflecting: vm).descendant("cachedMonthlyEvents") as? [Date: [Date: [IncomeService.IncomeEvent]]]
            return cache?.keys.sorted() ?? []
        }

        var months = cachedMonths(viewModel)
        #expect(!months.isEmpty)
        #expect(months.count <= 24)

        let calendarCurrent = Calendar.current
        let selectedMonth = monthStart(selected, calendar: calendarCurrent)

        let incomes = try service.fetchAllIncomes(sortedByDateAscending: true)
        guard let firstDate = incomes.first?.date, let lastDate = incomes.last?.date else {
            #expect(false, "Expected seeded incomes")
            return
        }

        let firstMonth = monthStart(firstDate, calendar: calendarCurrent)
        let lastMonth = monthStart(lastDate, calendar: calendarCurrent)

        let beforeSpan = max(0, calendarCurrent.dateComponents([.month], from: firstMonth, to: selectedMonth).month ?? 0)
        let afterSpan = max(0, calendarCurrent.dateComponents([.month], from: selectedMonth, to: lastMonth).month ?? 0)
        let capacity = 24
        let maxSpan = max(0, capacity - 1)
        let cappedBefore = min(beforeSpan, maxSpan)
        let cappedAfter = min(afterSpan, max(0, maxSpan - cappedBefore))

        let beforeCount = months.filter { $0 < selectedMonth }.count
        let afterCount = months.filter { $0 > selectedMonth }.count

        #expect(beforeCount <= cappedBefore)
        #expect(afterCount <= cappedAfter)
        #expect(months.contains(selectedMonth))

        let earliestBeforeUpdate = months.first

        guard let future = seededMonths.last else {
            #expect(false, "Expected a future month")
            return
        }

        viewModel.selectedDate = future
        viewModel.load(day: future, forceMonthReload: false)

        months = cachedMonths(viewModel)
        #expect(months.count <= 24)
        #expect(months.contains(monthStart(future, calendar: calendarCurrent)))

        if let earliestBeforeUpdate, let newEarliest = months.first {
            #expect(newEarliest >= earliestBeforeUpdate)
        }
    }
}

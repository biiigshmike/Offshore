//
//  IncomeScreenViewModelTests.swift
//  OffshoreBudgetingTests
//

import XCTest
import CoreData
import Combine
#if canImport(Offshore)
@testable import Offshore
#elseif canImport(OffshoreBudgeting)
@testable import OffshoreBudgeting
#elseif canImport(SoFar)
@testable import SoFar
#else
#error("App module not found. Ensure the test target depends on the app target and update the conditional import.")
#endif

// MARK: - IncomeScreenViewModelTests
@MainActor
final class IncomeScreenViewModelTests: XCTestCase {
    private var stack: TestCoreDataStack! = nil
    private var service: IncomeService! = nil
    private var vm: IncomeScreenViewModel! = nil
    private var cancellables: Set<AnyCancellable> = []

    private var cal: Calendar {
        var c = Calendar(identifier: .gregorian)
        c.timeZone = TimeZone(secondsFromGMT: 0)!
        return c
    }

    override func setUp() async throws {
        stack = TestCoreDataStack()
        service = IncomeService(stack: stack, calendar: cal)
        vm = IncomeScreenViewModel(incomeService: service)
    }

    override func tearDown() {
        cancellables.removeAll()
        vm = nil
        service = nil
        stack = nil
    }

    private func date(_ y: Int, _ m: Int, _ d: Int) -> Date {
        var comps = DateComponents(); comps.year = y; comps.month = m; comps.day = d
        return cal.date(from: comps)!
    }

    // MARK: - Totals and events after initial load
    func testTotalsAndEventsForSelectedDay() throws {
        let day = date(2024, 1, 10)
        // Planned 100, Actual 50
        _ = try service.createIncome(source: "Planned", amount: 100, date: day, isPlanned: true)
        _ = try service.createIncome(source: "Actual", amount: 50, date: day, isPlanned: false)

        vm.selectedDate = day
        vm.load(day: day, forceMonthReload: true)

        XCTAssertEqual(vm.plannedTotalForSelectedDate, 100, accuracy: 0.000001)
        XCTAssertEqual(vm.actualTotalForSelectedDate, 50, accuracy: 0.000001)
        XCTAssertEqual(vm.totalForSelectedDate, 150, accuracy: 0.000001)

        // Week equals day here since there are no other incomes
        XCTAssertEqual(vm.totalForSelectedWeek, 150, accuracy: 0.000001)

        // Events map contains that day with two events
        let dayKey = Calendar.current.startOfDay(for: day)
        XCTAssertEqual(vm.eventsByDay[dayKey]?.count, 2)
    }

    // MARK: - Reacts to dataStoreDidChange and refreshes
    func testRefreshOnDataStoreDidChange() async throws {
        let day = date(2024, 1, 11)
        vm.selectedDate = day
        vm.load(day: day, forceMonthReload: true)
        XCTAssertEqual(vm.totalForSelectedDate, 0)

        // Add an income and post the app-wide change notification
        _ = try service.createIncome(source: "Planned", amount: 75, date: day, isPlanned: true)
        NotificationCenter.default.post(name: .dataStoreDidChange, object: nil)

        // Give the main runloop a moment to deliver the Combine event and reload
        try await Task.sleep(nanoseconds: 150_000_000) // 150ms

        XCTAssertEqual(vm.plannedTotalForSelectedDate, 75, accuracy: 0.000001)
        XCTAssertEqual(vm.totalForSelectedDate, 75, accuracy: 0.000001)
        let dayKey = Calendar.current.startOfDay(for: day)
        XCTAssertEqual(vm.eventsByDay[dayKey]?.count, 1)
    }
}

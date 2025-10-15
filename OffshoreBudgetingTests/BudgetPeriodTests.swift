//
//  BudgetPeriodTests.swift
//  OffshoreBudgetingTests
//

import XCTest
#if canImport(Offshore)
@testable import Offshore
#elseif canImport(OffshoreBudgeting)
@testable import OffshoreBudgeting
#elseif canImport(SoFar)
@testable import SoFar
#else
#error("App module not found. Ensure the test target depends on the app target and update the conditional import.")
#endif

// MARK: - BudgetPeriodTests
final class BudgetPeriodTests: XCTestCase {

    private func date(_ y: Int, _ m: Int, _ d: Int) -> Date {
        var comps = DateComponents(); comps.year = y; comps.month = m; comps.day = d
        return Calendar(identifier: .gregorian).date(from: comps)!
    }

    func testMonthlyRangeAndStart() {
        let d = date(2024, 1, 15)
        let period = BudgetPeriod.monthly
        let (start, end) = period.range(containing: d)

        let cal = Calendar.current
        let expectedStart = cal.date(from: DateComponents(year: 2024, month: 1, day: 1))!
        let expectedEnd = cal.date(byAdding: DateComponents(month: 1, second: -1), to: expectedStart)!

        XCTAssertEqual(start, expectedStart)
        XCTAssertEqual(end, expectedEnd)
        XCTAssertTrue(period.matches(startDate: start, endDate: end))
    }

    func testWeeklyRangeMatchesCalendarWeek() {
        let period = BudgetPeriod.weekly
        let d = date(2024, 1, 18)

        let (start, end) = period.range(containing: d)

        // Use system Calendar to derive canonical week for comparison
        let cal = Calendar.current
        let ci = cal.dateInterval(of: .weekOfYear, for: d)!
        let expectedStart = ci.start
        let expectedEnd = cal.date(byAdding: DateComponents(day: 7, second: -1), to: expectedStart)!

        XCTAssertEqual(start, expectedStart)
        XCTAssertEqual(end, expectedEnd)
        XCTAssertTrue(period.matches(startDate: start, endDate: end))
    }

    func testAdvancePeriods() {
        let d = date(2024, 1, 31)
        XCTAssertEqual(BudgetPeriod.daily.advance(d, by: 1), date(2024,2,1))
        XCTAssertEqual(BudgetPeriod.weekly.advance(d, by: 1), Calendar.current.date(byAdding: .weekOfYear, value: 1, to: d))
        XCTAssertEqual(BudgetPeriod.biWeekly.advance(d, by: 1), Calendar.current.date(byAdding: .day, value: 14, to: d))
        XCTAssertEqual(BudgetPeriod.monthly.advance(d, by: 1), Calendar.current.date(byAdding: .month, value: 1, to: d))
        XCTAssertEqual(BudgetPeriod.quarterly.advance(d, by: 1), Calendar.current.date(byAdding: .month, value: 3, to: d))
        XCTAssertEqual(BudgetPeriod.yearly.advance(d, by: 1), Calendar.current.date(byAdding: .year, value: 1, to: d))
    }
}

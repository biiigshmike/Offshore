//
//  RecurrenceRuleTests.swift
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

// MARK: - RecurrenceRuleTests
final class RecurrenceRuleTests: XCTestCase {

    private func date(_ y: Int, _ m: Int, _ d: Int) -> Date {
        var comps = DateComponents(); comps.year = y; comps.month = m; comps.day = d
        return Calendar(identifier: .gregorian).date(from: comps)!
    }

    func testToRRuleWeeklyMonday() {
        let rule = RecurrenceRule.weekly(weekday: .monday, endDate: nil)
        let built = rule.toRRule(starting: date(2024, 1, 1))
        XCTAssertEqual(built?.string, "FREQ=WEEKLY;BYDAY=MO")
        XCTAssertEqual(built?.secondBiMonthlyPayDay, 0)
    }

    func testToRRuleSemiMonthlyClampsDays() {
        let rule = RecurrenceRule.semiMonthly(firstDay: 1, secondDay: 32, endDate: nil)
        let built = rule.toRRule(starting: date(2024, 1, 1))
        XCTAssertEqual(built?.string, "FREQ=MONTHLY;BYMONTHDAY=1,31")
        XCTAssertEqual(built?.secondBiMonthlyPayDay, 31)
    }

    func testParseRoundTrip() {
        let end = date(2024, 12, 31)
        let inputs: [RecurrenceRule] = [
            .daily(endDate: end),
            .weekly(weekday: .wednesday, endDate: end),
            .biWeekly(weekday: .friday, endDate: end),
            .semiMonthly(firstDay: 1, secondDay: 15, endDate: end),
            .monthly(endDate: end),
            .quarterly(endDate: end),
            .annually(endDate: end)
        ]

        for rule in inputs {
            let built = rule.toRRule(starting: date(2024, 1, 1))!
            let parsed = RecurrenceRule.parse(from: built.string, endDate: built.until, secondBiMonthlyPayDay: built.secondBiMonthlyPayDay)
            XCTAssertEqual(parsed, rule)
        }
    }
}

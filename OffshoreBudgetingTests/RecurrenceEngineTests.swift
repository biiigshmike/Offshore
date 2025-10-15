//
//  RecurrenceEngineTests.swift
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

// MARK: - RecurrenceEngineTests
final class RecurrenceEngineTests: XCTestCase {

    // MARK: - Helpers
    private func utcCalendar() -> Calendar {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(secondsFromGMT: 0)!
        return cal
    }

    private func date(_ y: Int, _ m: Int, _ d: Int) -> Date {
        var comps = DateComponents()
        comps.year = y; comps.month = m; comps.day = d
        return Calendar(identifier: .gregorian).date(from: comps)!
    }

    // MARK: - Monthly clamping (31st across short months)
    func testMonthlyClampsEndOfMonth() {
        let cal = utcCalendar()
        let base = date(2024, 1, 31) // Jan has 31; 2024 Feb has 29
        let interval = DateInterval(start: date(2024, 1, 1), end: date(2024, 3, 31))

        let out = RecurrenceEngine.projectedDates(recurrence: "monthly",
                                                  baseDate: base,
                                                  in: interval,
                                                  calendar: cal)
        XCTAssertEqual(out.count, 3)
        // Build expected using the same calendar semantics as the engine
        var expected: [Date] = []
        var cursor = base
        for _ in 0..<3 { expected.append(cursor); cursor = cal.date(byAdding: .month, value: 1, to: cursor)! }
        XCTAssertTrue(cal.isDate(out[0], inSameDayAs: expected[0]))
        XCTAssertTrue(cal.isDate(out[1], inSameDayAs: expected[1]))
        XCTAssertTrue(cal.isDate(out[2], inSameDayAs: expected[2]))
    }

    // MARK: - Weekly and bi-weekly strides
    func testWeeklyAndBiWeekly() {
        let cal = utcCalendar()
        let base = date(2024, 1, 1) // Monday
        let interval = DateInterval(start: date(2024, 1, 1), end: date(2024, 1, 22))

        let weekly = RecurrenceEngine.projectedDates(recurrence: "weekly",
                                                     baseDate: base,
                                                     in: interval,
                                                     calendar: cal)
        let weeklyExpected = [date(2024,1,1), date(2024,1,8), date(2024,1,15), date(2024,1,22)]
        XCTAssertEqual(weekly.count, weeklyExpected.count)
        zip(weekly, weeklyExpected).forEach { a, b in XCTAssertTrue(cal.isDate(a, inSameDayAs: b)) }

        let biweekly = RecurrenceEngine.projectedDates(recurrence: "biweekly",
                                                       baseDate: base,
                                                       in: interval,
                                                       calendar: cal)
        let biweeklyExpected = [date(2024,1,1), date(2024,1,15)]
        XCTAssertEqual(biweekly.count, biweeklyExpected.count)
        zip(biweekly, biweeklyExpected).forEach { a, b in XCTAssertTrue(cal.isDate(a, inSameDayAs: b)) }
    }

    // MARK: - Semi-monthly using explicit second day
    func testSemiMonthlySecondDay() {
        let cal = utcCalendar()
        let base = date(2024, 1, 10)
        let interval = DateInterval(start: date(2024, 1, 1), end: date(2024, 2, 29))

        let out = RecurrenceEngine.projectedDates(recurrence: "semimonthly",
                                                  baseDate: base,
                                                  in: interval,
                                                  calendar: cal,
                                                  secondBiMonthlyDay: 25,
                                                  secondBiMonthlyDate: nil)
        let expected = [date(2024,1,10), date(2024,1,25), date(2024,2,10), date(2024,2,25)]
        XCTAssertEqual(out.count, expected.count)
        zip(out, expected).forEach { a, b in XCTAssertTrue(cal.isDate(a, inSameDayAs: b)) }
    }

    // MARK: - Yearly around leap day anchor
    func testYearlyFromLeapDayAnchorsToEndOfFeb() {
        let cal = utcCalendar()
        let base = date(2020, 2, 29)
        let interval = DateInterval(start: date(2020, 1, 1), end: date(2023, 3, 1))

        let out = RecurrenceEngine.projectedDates(recurrence: "yearly",
                                                  baseDate: base,
                                                  in: interval,
                                                  calendar: cal)
        // Expect Feb 29, 2020; Feb 28, 2021; Feb 28, 2022; Feb 28, 2023
        XCTAssertEqual(out.count, 4)
        let leapExpected = [date(2020,2,29), date(2021,2,28), date(2022,2,28), date(2023,2,28)]
        zip(out, leapExpected).forEach { a, b in XCTAssertTrue(cal.isDate(a, inSameDayAs: b)) }
    }

    // MARK: - Keyword vs ICS parity for simple weekly
    func testKeywordAndRRULEParityWeekly() {
        let cal = utcCalendar()
        let base = date(2024, 1, 3) // Wednesday
        let interval = DateInterval(start: date(2024, 1, 1), end: date(2024, 1, 17))

        let keyword = RecurrenceEngine.projectedDates(recurrence: "weekly",
                                                      baseDate: base,
                                                      in: interval,
                                                      calendar: cal)
        let ics = RecurrenceEngine.projectedDates(recurrence: "FREQ=WEEKLY;BYDAY=WE",
                                                  baseDate: base,
                                                  in: interval,
                                                  calendar: cal)
        XCTAssertEqual(keyword.count, ics.count)
        zip(keyword, ics).forEach { a, b in XCTAssertTrue(cal.isDate(a, inSameDayAs: b)) }
        let weeklyWedExpected = [date(2024,1,3), date(2024,1,10), date(2024,1,17)]
        zip(keyword, weeklyWedExpected).forEach { a, b in XCTAssertTrue(cal.isDate(a, inSameDayAs: b)) }
    }
}

//
//  BudgetIncomeCalculatorTests.swift
//  OffshoreBudgetingTests
//

import XCTest
import CoreData
#if canImport(Offshore)
@testable import Offshore
#elseif canImport(OffshoreBudgeting)
@testable import OffshoreBudgeting
#elseif canImport(SoFar)
@testable import SoFar
#else
#error("App module not found. Ensure the test target depends on the app target and update the conditional import.")
#endif

// MARK: - BudgetIncomeCalculatorTests
final class BudgetIncomeCalculatorTests: XCTestCase {

    private var stack: TestCoreDataStack! = nil
    private var context: NSManagedObjectContext { stack.container.viewContext }

    override func setUp() {
        super.setUp()
        stack = TestCoreDataStack()
    }

    override func tearDown() {
        stack = nil
        super.tearDown()
    }

    // MARK: - Helpers
    @discardableResult
    private func makeIncome(date: Date, amount: Double, isPlanned: Bool) throws -> Income {
        let inc = Income(context: context)
        inc.setValue(UUID(), forKey: "id")
        inc.source = isPlanned ? "Planned" : "Actual"
        inc.amount = amount
        inc.isPlanned = isPlanned
        inc.date = date
        try context.save()
        return inc
    }

    private func date(_ y: Int, _ m: Int, _ d: Int) -> Date {
        var comps = DateComponents(); comps.year = y; comps.month = m; comps.day = d
        return Calendar(identifier: .gregorian).date(from: comps)!
    }

    private func monthInterval(_ y: Int, _ m: Int) -> DateInterval {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(secondsFromGMT: 0)!
        let start = cal.date(from: DateComponents(year: y, month: m, day: 1))!
        let end = cal.date(byAdding: DateComponents(month: 1, second: -1), to: start)!
        return DateInterval(start: start, end: end)
    }

    // MARK: - Totals bucket planned vs actual
    func testTotalsPlannedVsActualInRange() throws {
        // Jan 2024
        try makeIncome(date: date(2024,1,5), amount: 1000.00, isPlanned: true)
        try makeIncome(date: date(2024,1,12), amount: 2000.00, isPlanned: true)
        try makeIncome(date: date(2024,1,20), amount: 500.00, isPlanned: false)
        // Feb (outside)
        try makeIncome(date: date(2024,2,1), amount: 777.00, isPlanned: true)

        let interval = monthInterval(2024, 1)
        let (planned, actual) = try BudgetIncomeCalculator.totals(for: interval, context: context)
        XCTAssertEqual(planned, 3000.00, accuracy: 0.000001)
        XCTAssertEqual(actual, 500.00, accuracy: 0.000001)
    }

    // MARK: - Sum variants (planned-only, actual-only, combined)
    func testSumPlannedActualCombined() throws {
        try makeIncome(date: date(2024,1,1), amount: 10.25, isPlanned: true)
        try makeIncome(date: date(2024,1,2), amount: 5.75, isPlanned: false)

        let interval = monthInterval(2024, 1)
        XCTAssertEqual(try BudgetIncomeCalculator.sum(in: interval, isPlanned: true, context: context), 10.25, accuracy: 0.000001)
        XCTAssertEqual(try BudgetIncomeCalculator.sum(in: interval, isPlanned: false, context: context), 5.75, accuracy: 0.000001)
        XCTAssertEqual(try BudgetIncomeCalculator.sum(in: interval, isPlanned: nil, context: context), 16.00, accuracy: 0.000001)
    }

    // MARK: - Ignores out-of-range incomes
    func testIgnoresOutsideRange() throws {
        try makeIncome(date: date(2024,1,31), amount: 100, isPlanned: true)
        try makeIncome(date: date(2024,2,1), amount: 999, isPlanned: true) // outside

        let interval = monthInterval(2024, 1)
        let (planned, actual) = try BudgetIncomeCalculator.totals(for: interval, context: context)
        XCTAssertEqual(planned + actual, 100, accuracy: 0.000001)
    }

    // MARK: - Many small adds remain stable within tolerance
    func testDoublePrecisionWithinTolerance() throws {
        for day in 1...10 {
            try makeIncome(date: date(2024,1,day), amount: 0.10, isPlanned: true)
        }
        let interval = monthInterval(2024, 1)
        let total = try BudgetIncomeCalculator.sum(in: interval, isPlanned: true, context: context)
        XCTAssertEqual(total, 1.0, accuracy: 0.000001)
    }
}

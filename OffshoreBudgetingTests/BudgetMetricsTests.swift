import XCTest
@testable import OffshoreBudgeting

final class BudgetMetricsTests: XCTestCase {

    func testExpenseToIncomeFlagsCashDeficitWhenExpensesExceedReceivedIncome() {
        let metrics = BudgetMetrics.expenseToIncome(
            expenses: 2448.77,
            expectedIncome: 5350.50,
            receivedIncome: 1843.62
        )

        XCTAssertEqual(metrics.status, .cashDeficit)
        XCTAssertEqual(metrics.percentOfExpected, 45.77, accuracy: 0.01)
        XCTAssertEqual(metrics.percentOfReceived ?? 0, 132.84, accuracy: 0.01)
        XCTAssertEqual(metrics.gaugeProgress, 0.46, accuracy: 0.01)
    }

    func testExpenseToIncomeDetectsOverExpectedWhenCashPositive() {
        let metrics = BudgetMetrics.expenseToIncome(
            expenses: 4200,
            expectedIncome: 4000,
            receivedIncome: 4500
        )

        XCTAssertEqual(metrics.status, .overExpected)
        XCTAssertEqual(metrics.percentOfExpected, 105, accuracy: 0.1)
        XCTAssertEqual(metrics.percentOfReceived ?? 0, 93.33, accuracy: 0.1)
        XCTAssertEqual(metrics.gaugeProgress, 1.0, accuracy: 0.001)
    }

    func testSavingsOutlookUsesRemainingIncomeWithoutDoubleCounting() {
        let outlook = BudgetMetrics.savingsOutlook(
            actualSavings: -605.15,
            expectedIncome: 5350.50,
            incomeReceived: 1843.62,
            plannedExpensesPlanned: 1200,
            plannedExpensesActual: 1200
        )

        XCTAssertEqual(outlook.remainingIncome, 3506.88, accuracy: 0.01)
        XCTAssertEqual(outlook.remainingPlannedExpenses, 0, accuracy: 0.001)
        XCTAssertEqual(outlook.projected, 2901.73, accuracy: 0.01)
    }

    func testSavingsOutlookSubtractsRemainingPlannedExpenses() {
        let outlook = BudgetMetrics.savingsOutlook(
            actualSavings: 500,
            expectedIncome: 4000,
            incomeReceived: 2000,
            plannedExpensesPlanned: 1500,
            plannedExpensesActual: 1000
        )

        XCTAssertEqual(outlook.remainingIncome, 2000, accuracy: 0.001)
        XCTAssertEqual(outlook.remainingPlannedExpenses, 500, accuracy: 0.001)
        XCTAssertEqual(outlook.projected, 2000, accuracy: 0.001)
    }
}

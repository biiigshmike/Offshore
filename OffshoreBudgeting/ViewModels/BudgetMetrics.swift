import Foundation

/// Derives display-ready metrics for widgets without duplicating math in the view layer.
enum BudgetMetrics {

    struct ExpenseToIncomeMetrics: Equatable {
        enum Status: Equatable {
            case onTrack
            case cashDeficit
            case overExpected
        }

        let expenses: Double
        let expectedIncome: Double
        let receivedIncome: Double
        let percentOfExpected: Double
        let percentOfReceived: Double?
        let gaugeProgress: Double
        let status: Status
    }

    struct SavingsOutlookMetrics: Equatable {
        let actual: Double
        let projected: Double
        let remainingIncome: Double
        let remainingPlannedExpenses: Double
    }

    /// Computes expense-to-income pacing using both expected and received income.
    static func expenseToIncome(expenses: Double, expectedIncome: Double, receivedIncome: Double) -> ExpenseToIncomeMetrics {
        let expected = max(expectedIncome, 0)
        let received = max(receivedIncome, 0)
        let percentOfExpected = expected > 0 ? (expenses / expected) * 100 : 0
        let percentOfReceived = received > 0 ? (expenses / received) * 100 : nil
        let gaugeProgress = expected > 0 ? min(max(expenses / expected, 0), 1) : (expenses > 0 ? 1 : 0)

        let status: ExpenseToIncomeMetrics.Status
        if received == 0 && expenses > 0 {
            status = .cashDeficit
        } else if expenses > received {
            status = .cashDeficit
        } else if expected > 0 && expenses > expected {
            status = .overExpected
        } else {
            status = .onTrack
        }

        return ExpenseToIncomeMetrics(
            expenses: expenses,
            expectedIncome: expected,
            receivedIncome: received,
            percentOfExpected: percentOfExpected,
            percentOfReceived: percentOfReceived,
            gaugeProgress: gaugeProgress,
            status: status
        )
    }

    /// Projects savings using what is already saved plus remaining income minus remaining planned expenses.
    static func savingsOutlook(
        actualSavings: Double,
        expectedIncome: Double,
        incomeReceived: Double,
        plannedExpensesPlanned: Double,
        plannedExpensesActual: Double
    ) -> SavingsOutlookMetrics {
        let remainingIncome = max(expectedIncome - incomeReceived, 0)
        let remainingPlannedExpenses = max(plannedExpensesPlanned - plannedExpensesActual, 0)
        let projected = actualSavings + remainingIncome - remainingPlannedExpenses
        return SavingsOutlookMetrics(
            actual: actualSavings,
            projected: projected,
            remainingIncome: remainingIncome,
            remainingPlannedExpenses: remainingPlannedExpenses
        )
    }
}

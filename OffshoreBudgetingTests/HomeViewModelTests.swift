import Foundation
import CoreData
import Testing
@testable import Offshore

@MainActor
struct HomeViewModelTests {

    @Test
    func refresh_populates_budget_summary_totals() async throws {
        UserDefaults.standard.set(BudgetPeriod.monthly.rawValue, forKey: AppSettingsKeys.budgetPeriod.rawValue)

        let container = try TestUtils.resetStore()
        let context = container.viewContext

        let budgetService = BudgetService()
        let cardService = CardService()
        let categoryService = ExpenseCategoryService()
        let plannedExpenseService = PlannedExpenseService()
        let unplannedExpenseService = UnplannedExpenseService()
        let incomeService = IncomeService()

        let groceries = try categoryService.addCategory(name: "Groceries", color: "#00FF00")
        let dining = try categoryService.addCategory(name: "Dining", color: "#FF3300")

        let budgetStart = TestUtils.makeDate(2025, 7, 1)
        let budgetEnd = TestUtils.makeDate(2025, 7, 31)
        let budget = try budgetService.createBudget(name: "July 2025", startDate: budgetStart, endDate: budgetEnd)
        _ = try budgetService.createBudget(name: "Archive", startDate: TestUtils.makeDate(2025, 5, 1), endDate: TestUtils.makeDate(2025, 5, 31))

        guard let budgetID = budget.value(forKey: "id") as? UUID else {
            #expect(false, "Expected budget to have UUID")
            return
        }

        let card = try cardService.createCard(name: "Everyday Card", ensureUniqueName: false, attachToBudgetIDs: [budgetID])
        guard let cardID = card.value(forKey: "id") as? UUID else {
            #expect(false, "Expected card to have UUID")
            return
        }

        let groceriesPlanned = try plannedExpenseService.create(
            inBudgetID: budgetID,
            titleOrDescription: "Groceries Plan",
            plannedAmount: 500,
            actualAmount: 450,
            transactionDate: TestUtils.makeDate(2025, 7, 5)
        )
        groceriesPlanned.expenseCategory = groceries

        let diningPlanned = try plannedExpenseService.create(
            inBudgetID: budgetID,
            titleOrDescription: "Dining Plan",
            plannedAmount: 300,
            actualAmount: 310,
            transactionDate: TestUtils.makeDate(2025, 7, 12)
        )
        diningPlanned.expenseCategory = dining

        try context.save()

        let groceriesCategoryID = groceries.value(forKey: "id") as? UUID
        let diningCategoryID = dining.value(forKey: "id") as? UUID

        _ = try unplannedExpenseService.create(
            descriptionText: "Farmers Market",
            amount: 45,
            date: TestUtils.makeDate(2025, 7, 6),
            cardID: cardID,
            categoryID: groceriesCategoryID
        )
        _ = try unplannedExpenseService.create(
            descriptionText: "Late Night Snack",
            amount: 55,
            date: TestUtils.makeDate(2025, 7, 20),
            cardID: cardID,
            categoryID: diningCategoryID
        )

        _ = try incomeService.createIncome(
            source: "Salary",
            amount: 2_000,
            date: TestUtils.makeDate(2025, 7, 1),
            isPlanned: true
        )
        _ = try incomeService.createIncome(
            source: "Freelance",
            amount: 1_500,
            date: TestUtils.makeDate(2025, 7, 15),
            isPlanned: false
        )

        try context.save()

        let vm = HomeViewModel(context: context)
        vm.selectedDate = TestUtils.makeDate(2025, 7, 10)
        await vm.refresh()

        guard case let .loaded(summaries) = vm.state else {
            #expect(false, "Expected loaded state, found \(vm.state)")
            return
        }

        #expect(summaries.count == 1)
        guard let summary = summaries.first else {
            #expect(false, "Expected a summary")
            return
        }

        let tolerance = 0.0001
        #expect(abs(summary.plannedExpensesPlannedTotal - 800) < tolerance)
        #expect(abs(summary.plannedExpensesActualTotal - 760) < tolerance)
        #expect(abs(summary.variableExpensesTotal - 100) < tolerance)
        #expect(abs(summary.potentialIncomeTotal - 2_000) < tolerance)
        #expect(abs(summary.actualIncomeTotal - 1_500) < tolerance)
        #expect(abs(summary.potentialSavingsTotal - 1_200) < tolerance)
        #expect(abs(summary.actualSavingsTotal - 640) < tolerance)

        let plannedBreakdown = summary.plannedCategoryBreakdown.reduce(into: [String: (amount: Double, color: String?)]()) { dict, entry in
            dict[entry.categoryName] = (entry.amount, entry.hexColor)
        }
        #expect(abs((plannedBreakdown["Groceries"]?.amount ?? 0) - 500) < tolerance)
        #expect(abs((plannedBreakdown["Dining"]?.amount ?? 0) - 300) < tolerance)
        #expect(plannedBreakdown["Groceries"]?.color == groceries.color)
        #expect(plannedBreakdown["Dining"]?.color == dining.color)

        let variableBreakdown = summary.variableCategoryBreakdown.reduce(into: [String: (amount: Double, color: String?)]()) { dict, entry in
            dict[entry.categoryName] = (entry.amount, entry.hexColor)
        }
        #expect(abs((variableBreakdown["Groceries"]?.amount ?? 0) - 45) < tolerance)
        #expect(abs((variableBreakdown["Dining"]?.amount ?? 0) - 55) < tolerance)

        let combinedBreakdown = summary.categoryBreakdown.reduce(into: [String: Double]()) { dict, entry in
            dict[entry.categoryName] = entry.amount
        }
        #expect(abs((combinedBreakdown["Groceries"] ?? 0) - 545) < tolerance)
        #expect(abs((combinedBreakdown["Dining"] ?? 0) - 355) < tolerance)
    }

    @Test
    func updateBudgetPeriod_resets_selection_and_triggers_refresh() async throws {
        UserDefaults.standard.set(BudgetPeriod.monthly.rawValue, forKey: AppSettingsKeys.budgetPeriod.rawValue)
        _ = try TestUtils.resetStore()
        let context = CoreDataService.shared.viewContext
        let vm = HomeViewModel(context: context)

        await vm.refresh()

        let now = Date()
        vm.updateBudgetPeriod(to: .weekly)

        let expectedStart = BudgetPeriod.weekly.start(of: now)
        let calendar = Calendar.current
        #expect(calendar.isDate(vm.selectedDate, inSameDayAs: expectedStart))

        for _ in 0..<10 { await Task.yield() }

        #expect({
            if case .initial = vm.state {
                return false
            }
            return true
        }(), "Expected refresh to start after updating period")

        let storedPeriod = UserDefaults.standard.string(forKey: AppSettingsKeys.budgetPeriod.rawValue)
        #expect(storedPeriod == BudgetPeriod.weekly.rawValue)
    }
}

import Foundation
import CoreData
import Testing
@testable import Offshore

@MainActor
struct BudgetDetailsViewModelTests {

    // MARK: - Seed Fixtures
    private struct SeededBudget {
        let context: NSManagedObjectContext
        let budget: Budget
        let startDate: Date
        let endDate: Date
        let plannedInRange: [PlannedExpense]
        let plannedOutOfRange: PlannedExpense
        let unplannedInRange: [UnplannedExpense]
        let unplannedOutOfRange: UnplannedExpense
        let categories: [String: ExpenseCategory]
        let zeroCategoryNames: [String]
        let incomeTotals: (planned: Double, actual: Double)
    }

    private enum SeedError: Error {
        case missingID(String)
    }

    private func seedBudget() throws -> SeededBudget {
        let container = try TestUtils.resetStore()
        let context = container.viewContext

        let budgetService = BudgetService()
        let cardService = CardService()
        let categoryService = ExpenseCategoryService()
        let plannedExpenseService = PlannedExpenseService()
        let unplannedExpenseService = UnplannedExpenseService()
        let incomeService = IncomeService()

        let groceries = try categoryService.addCategory(name: "Groceries", color: "#00FF00")
        let dining = try categoryService.addCategory(name: "Dining", color: "#FF6600")
        let travel = try categoryService.addCategory(name: "Travel", color: "#0033FF")
        let utilities = try categoryService.addCategory(name: "Utilities", color: "#999999")
        let entertainment = try categoryService.addCategory(name: "Entertainment", color: "#9900FF")

        let startDate = TestUtils.makeDate(2024, 1, 1)
        let endDate = TestUtils.makeDate(2024, 1, 31)
        let budget = try budgetService.createBudget(name: "January 2024", startDate: startDate, endDate: endDate)

        guard let budgetID = budget.value(forKey: "id") as? UUID else { throw SeedError.missingID("Budget") }

        let card = try cardService.createCard(name: "Primary", ensureUniqueName: false, attachToBudgetIDs: [budgetID])
        guard let cardID = card.value(forKey: "id") as? UUID else { throw SeedError.missingID("Card") }

        let groceriesPlanned = try plannedExpenseService.create(
            inBudgetID: budgetID,
            titleOrDescription: "Groceries Run",
            plannedAmount: 150,
            actualAmount: 120,
            transactionDate: TestUtils.makeDate(2024, 1, 5)
        )
        groceriesPlanned.expenseCategory = groceries

        let diningPlanned = try plannedExpenseService.create(
            inBudgetID: budgetID,
            titleOrDescription: "Date Night",
            plannedAmount: 110,
            actualAmount: 95,
            transactionDate: TestUtils.makeDate(2024, 1, 10)
        )
        diningPlanned.expenseCategory = dining

        let travelPlanned = try plannedExpenseService.create(
            inBudgetID: budgetID,
            titleOrDescription: "Business Trip",
            plannedAmount: 220,
            actualAmount: 220,
            transactionDate: TestUtils.makeDate(2024, 1, 20)
        )
        travelPlanned.expenseCategory = travel

        let plannedOutsideRange = try plannedExpenseService.create(
            inBudgetID: budgetID,
            titleOrDescription: "Post Month Dinner",
            plannedAmount: 60,
            actualAmount: 60,
            transactionDate: TestUtils.makeDate(2024, 2, 5)
        )
        plannedOutsideRange.expenseCategory = dining

        try context.save()

        guard let groceriesCategoryID = groceries.value(forKey: "id") as? UUID else { throw SeedError.missingID("Groceries Category") }
        guard let diningCategoryID = dining.value(forKey: "id") as? UUID else { throw SeedError.missingID("Dining Category") }
        guard let travelCategoryID = travel.value(forKey: "id") as? UUID else { throw SeedError.missingID("Travel Category") }

        let unplannedGroceries = try unplannedExpenseService.create(
            descriptionText: "Farmers Market",
            amount: 35,
            date: TestUtils.makeDate(2024, 1, 6),
            cardID: cardID,
            categoryID: groceriesCategoryID
        )
        let unplannedTravel = try unplannedExpenseService.create(
            descriptionText: "Airport Transfer",
            amount: 80,
            date: TestUtils.makeDate(2024, 1, 18),
            cardID: cardID,
            categoryID: travelCategoryID
        )
        let unplannedDining = try unplannedExpenseService.create(
            descriptionText: "Coffee Shop",
            amount: 12,
            date: TestUtils.makeDate(2024, 1, 9),
            cardID: cardID,
            categoryID: diningCategoryID
        )
        let unplannedOutsideRange = try unplannedExpenseService.create(
            descriptionText: "Souvenir",
            amount: 25,
            date: TestUtils.makeDate(2024, 2, 3),
            cardID: cardID,
            categoryID: travelCategoryID
        )

        try context.save()

        _ = try incomeService.createIncome(
            source: "Salary",
            amount: 5_000,
            date: TestUtils.makeDate(2024, 1, 3),
            isPlanned: true
        )
        _ = try incomeService.createIncome(
            source: "Contract",
            amount: 3_200,
            date: TestUtils.makeDate(2024, 1, 14),
            isPlanned: false
        )
        _ = try incomeService.createIncome(
            source: "Off Cycle",
            amount: 450,
            date: TestUtils.makeDate(2024, 2, 10),
            isPlanned: false
        )

        try context.save()

        let interval = DateInterval(start: startDate, end: endDate)
        let incomeTotals = try BudgetIncomeCalculator.totals(for: interval, context: context)

        return SeededBudget(
            context: context,
            budget: budget,
            startDate: startDate,
            endDate: endDate,
            plannedInRange: [groceriesPlanned, diningPlanned, travelPlanned],
            plannedOutOfRange: plannedOutsideRange,
            unplannedInRange: [unplannedTravel, unplannedDining, unplannedGroceries],
            unplannedOutOfRange: unplannedOutsideRange,
            categories: [
                "Groceries": groceries,
                "Dining": dining,
                "Travel": travel,
                "Utilities": utilities,
                "Entertainment": entertainment
            ],
            zeroCategoryNames: ["Entertainment", "Utilities"],
            incomeTotals: incomeTotals
        )
    }

    // MARK: - Helpers
    private func plannedDescription(_ expense: PlannedExpense) -> String {
        if let text = expense.value(forKey: "descriptionText") as? String, !text.isEmpty {
            return text
        }
        if let title = expense.value(forKey: "title") as? String, !title.isEmpty {
            return title
        }
        return ""
    }

    private func unplannedDescription(_ expense: UnplannedExpense) -> String {
        if let text = expense.value(forKey: "descriptionText") as? String, !text.isEmpty {
            return text
        }
        if let title = expense.value(forKey: "title") as? String, !title.isEmpty {
            return title
        }
        return ""
    }

    // MARK: - Tests
    @Test
    func summary_reflects_seeded_totals_and_breakdown() async throws {
        let seed = try seedBudget()
        let vm = BudgetDetailsViewModel(budgetObjectID: seed.budget.objectID, context: seed.context)

        await vm.load()
        vm.startDate = seed.startDate
        vm.endDate = seed.endDate
        await vm.refreshRows()

        guard let summary = vm.summary else {
            #expect(false, "Expected summary to be available after refresh")
            return
        }

        let tolerance = 0.0001
        let expectedPlannedTotal = seed.plannedInRange.reduce(0) { $0 + $1.plannedAmount }
        let expectedActualTotal = seed.plannedInRange.reduce(0) { $0 + $1.actualAmount }
        let expectedVariableTotal = seed.unplannedInRange.reduce(0) { $0 + $1.amount }

        #expect(abs(summary.plannedExpensesPlannedTotal - expectedPlannedTotal) < tolerance)
        #expect(abs(summary.plannedExpensesActualTotal - expectedActualTotal) < tolerance)
        #expect(abs(summary.variableExpensesTotal - expectedVariableTotal) < tolerance)
        #expect(abs(summary.potentialIncomeTotal - seed.incomeTotals.planned) < tolerance)
        #expect(abs(summary.actualIncomeTotal - seed.incomeTotals.actual) < tolerance)
        #expect(abs(vm.incomeTotals.planned - seed.incomeTotals.planned) < tolerance)
        #expect(abs(vm.incomeTotals.actual - seed.incomeTotals.actual) < tolerance)

        let plannedBreakdownNames = summary.plannedCategoryBreakdown.map { $0.categoryName }
        let expectedPlannedNames = ["Travel", "Groceries", "Dining"] + seed.zeroCategoryNames
        #expect(plannedBreakdownNames == expectedPlannedNames)

        let plannedAmounts = Dictionary(uniqueKeysWithValues: summary.plannedCategoryBreakdown.map { ($0.categoryName, $0.amount) })
        #expect(abs((plannedAmounts["Travel"] ?? 0) - 220) < tolerance)
        #expect(abs((plannedAmounts["Groceries"] ?? 0) - 120) < tolerance)
        #expect(abs((plannedAmounts["Dining"] ?? 0) - 95) < tolerance)
        for zeroName in seed.zeroCategoryNames {
            if let value = plannedAmounts[zeroName] {
                #expect(abs(value) < tolerance)
            } else {
                #expect(false, "Expected planned breakdown to include \(zeroName)")
            }
        }

        let variableBreakdownNames = summary.variableCategoryBreakdown.map { $0.categoryName }
        let expectedVariableNames = ["Travel", "Groceries", "Dining"] + seed.zeroCategoryNames
        #expect(variableBreakdownNames == expectedVariableNames)

        let variableAmounts = Dictionary(uniqueKeysWithValues: summary.variableCategoryBreakdown.map { ($0.categoryName, $0.amount) })
        #expect(abs((variableAmounts["Travel"] ?? 0) - 80) < tolerance)
        #expect(abs((variableAmounts["Groceries"] ?? 0) - 35) < tolerance)
        #expect(abs((variableAmounts["Dining"] ?? 0) - 12) < tolerance)
        for zeroName in seed.zeroCategoryNames {
            if let value = variableAmounts[zeroName] {
                #expect(abs(value) < tolerance)
            } else {
                #expect(false, "Expected variable breakdown to include \(zeroName)")
            }
        }

        let combined = Dictionary(uniqueKeysWithValues: summary.categoryBreakdown.map { ($0.categoryName, $0.amount) })
        #expect(abs((combined["Travel"] ?? 0) - 300) < tolerance)
        #expect(abs((combined["Groceries"] ?? 0) - 155) < tolerance)
        #expect(abs((combined["Dining"] ?? 0) - 107) < tolerance)
        for zeroName in seed.zeroCategoryNames {
            if let value = combined[zeroName] {
                #expect(abs(value) < tolerance)
            } else {
                #expect(false, "Expected combined breakdown to include \(zeroName)")
            }
        }
    }

    @Test
    func plannedFilteredSorted_applies_filters_and_sorting() async throws {
        let seed = try seedBudget()
        let vm = BudgetDetailsViewModel(budgetObjectID: seed.budget.objectID, context: seed.context)

        await vm.load()
        vm.startDate = seed.startDate
        vm.endDate = seed.endDate
        await vm.refreshRows()

        // Default (.dateNewOld)
        vm.sort = .dateNewOld
        vm.searchQuery = ""
        let defaultOrder = vm.plannedFilteredSorted.map(plannedDescription)
        #expect(defaultOrder == ["Business Trip", "Date Night", "Groceries Run"])

        // Date filtering by adjusting start date without refetching
        vm.startDate = TestUtils.makeDate(2024, 1, 9)
        let dateFiltered = vm.plannedFilteredSorted.map(plannedDescription)
        #expect(dateFiltered == ["Business Trip", "Date Night"])

        // Restore full window and apply search
        vm.startDate = seed.startDate
        vm.searchQuery = "trip"
        let searchFiltered = vm.plannedFilteredSorted.map(plannedDescription)
        #expect(searchFiltered == ["Business Trip"])

        // Reset search for sort assertions
        vm.searchQuery = ""

        vm.sort = .titleAZ
        let titleOrder = vm.plannedFilteredSorted.map(plannedDescription)
        #expect(titleOrder == ["Business Trip", "Date Night", "Groceries Run"])

        vm.sort = .amountLowHigh
        let amountLowHighOrder = vm.plannedFilteredSorted.map(plannedDescription)
        #expect(amountLowHighOrder == ["Date Night", "Groceries Run", "Business Trip"])

        vm.sort = .amountHighLow
        let amountHighLowOrder = vm.plannedFilteredSorted.map(plannedDescription)
        #expect(amountHighLowOrder == ["Business Trip", "Groceries Run", "Date Night"])

        vm.sort = .dateOldNew
        let dateOldNewOrder = vm.plannedFilteredSorted.map(plannedDescription)
        #expect(dateOldNewOrder == ["Groceries Run", "Date Night", "Business Trip"])

        vm.sort = .dateNewOld
        let dateNewOldOrder = vm.plannedFilteredSorted.map(plannedDescription)
        #expect(dateNewOldOrder == ["Business Trip", "Date Night", "Groceries Run"])
    }

    @Test
    func unplannedFilteredSorted_applies_filters_and_sorting() async throws {
        let seed = try seedBudget()
        let vm = BudgetDetailsViewModel(budgetObjectID: seed.budget.objectID, context: seed.context)

        await vm.load()
        vm.startDate = seed.startDate
        vm.endDate = seed.endDate
        await vm.refreshRows()

        vm.sort = .dateNewOld
        vm.searchQuery = ""
        let defaultOrder = vm.unplannedFilteredSorted.map(unplannedDescription)
        #expect(defaultOrder == ["Airport Transfer", "Coffee Shop", "Farmers Market"])

        vm.startDate = TestUtils.makeDate(2024, 1, 9)
        let dateFiltered = vm.unplannedFilteredSorted.map(unplannedDescription)
        #expect(dateFiltered == ["Airport Transfer", "Coffee Shop"])

        vm.startDate = seed.startDate
        vm.searchQuery = "travel"
        let categorySearch = vm.unplannedFilteredSorted.map(unplannedDescription)
        #expect(categorySearch == ["Airport Transfer"])

        vm.searchQuery = ""

        vm.sort = .titleAZ
        let titleOrder = vm.unplannedFilteredSorted.map(unplannedDescription)
        #expect(titleOrder == ["Airport Transfer", "Coffee Shop", "Farmers Market"])

        vm.sort = .amountLowHigh
        let amountLowHighOrder = vm.unplannedFilteredSorted.map(unplannedDescription)
        #expect(amountLowHighOrder == ["Coffee Shop", "Farmers Market", "Airport Transfer"])

        vm.sort = .amountHighLow
        let amountHighLowOrder = vm.unplannedFilteredSorted.map(unplannedDescription)
        #expect(amountHighLowOrder == ["Airport Transfer", "Farmers Market", "Coffee Shop"])

        vm.sort = .dateOldNew
        let dateOldNewOrder = vm.unplannedFilteredSorted.map(unplannedDescription)
        #expect(dateOldNewOrder == ["Farmers Market", "Coffee Shop", "Airport Transfer"])

        vm.sort = .dateNewOld
        let dateNewOldOrder = vm.unplannedFilteredSorted.map(unplannedDescription)
        #expect(dateNewOldOrder == ["Airport Transfer", "Coffee Shop", "Farmers Market"])
    }

    @Test
    func load_coalesces_concurrent_calls_and_finishes_loaded() async throws {
        let seed = try seedBudget()
        let vm = BudgetDetailsViewModel(budgetObjectID: seed.budget.objectID, context: seed.context)

        async let firstLoad: Void = vm.load()
        async let secondLoad: Void = vm.load()
        _ = try await (firstLoad, secondLoad)

        #expect(vm.loadState == .loaded)
        vm.startDate = seed.startDate
        vm.endDate = seed.endDate
        await vm.refreshRows()
        #expect(vm.plannedExpenses.count == seed.plannedInRange.count)
        #expect(vm.unplannedExpenses.count == seed.unplannedInRange.count)
    }

    @Test
    func refreshRows_uses_card_fallback_when_budget_uuid_missing() async throws {
        let seed = try seedBudget()
        let vm = BudgetDetailsViewModel(budgetObjectID: seed.budget.objectID, context: seed.context)

        await vm.load()
        vm.startDate = seed.startDate
        vm.endDate = seed.endDate
        await vm.refreshRows()

        let baselineDescriptions = vm.unplannedFilteredSorted.map(unplannedDescription)
        #expect(baselineDescriptions.count == seed.unplannedInRange.count)

        seed.budget.setValue(nil, forKey: "id")
        #expect((seed.budget.value(forKey: "id") as? UUID) == nil)

        await vm.refreshRows()
        let fallbackDescriptions = vm.unplannedFilteredSorted.map(unplannedDescription)
        #expect(Set(fallbackDescriptions) == Set(baselineDescriptions))
        #expect(fallbackDescriptions.count == seed.unplannedInRange.count)
    }
}

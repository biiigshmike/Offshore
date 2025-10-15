import Foundation
import CoreData
import Testing
@testable import Offshore

@MainActor
struct HomeViewModelTests {

    @Test
    func refresh_withMixedBudgets_generatesCorrectSummaries() async throws {
        UserDefaults.standard.set(BudgetPeriod.monthly.rawValue, forKey: AppSettingsKeys.budgetPeriod.rawValue)

        _ = try TestUtils.resetStore()
        let context = CoreDataService.shared.viewContext

        let budgetService = BudgetService()
        let cardService = CardService()
        let categoryService = ExpenseCategoryService()
        let plannedExpenseService = PlannedExpenseService()
        let unplannedExpenseService = UnplannedExpenseService()
        let incomeService = IncomeService()

        let groceries = try categoryService.addCategory(name: "Groceries", color: "#00FF00")
        let travel = try categoryService.addCategory(name: "Travel", color: "#0033FF")
        let utilities = try categoryService.addCategory(name: "Utilities", color: "#FF33FF")

        let bridgeBudget = try budgetService.createBudget(
            name: "Bridge Budget",
            startDate: TestUtils.makeDate(2025, 6, 25),
            endDate: TestUtils.makeDate(2025, 7, 5)
        )
        let julyBudget = try budgetService.createBudget(
            name: "Primary July",
            startDate: TestUtils.makeDate(2025, 7, 1),
            endDate: TestUtils.makeDate(2025, 7, 31)
        )
        _ = try budgetService.createBudget(
            name: "Outside May",
            startDate: TestUtils.makeDate(2025, 5, 1),
            endDate: TestUtils.makeDate(2025, 5, 31)
        )
        _ = try budgetService.createBudget(
            name: "Outside August",
            startDate: TestUtils.makeDate(2025, 8, 1),
            endDate: TestUtils.makeDate(2025, 8, 31)
        )

        guard
            let bridgeBudgetID = bridgeBudget.value(forKey: "id") as? UUID,
            let julyBudgetID = julyBudget.value(forKey: "id") as? UUID
        else {
            #expect(false, "Expected budgets to expose UUID identifiers")
            return
        }

        let bridgeCard = try cardService.createCard(
            name: "Bridge Card",
            ensureUniqueName: false,
            attachToBudgetIDs: [bridgeBudgetID]
        )
        let julyCard = try cardService.createCard(
            name: "July Card",
            ensureUniqueName: false,
            attachToBudgetIDs: [julyBudgetID]
        )

        guard
            let bridgeCardID = bridgeCard.value(forKey: "id") as? UUID,
            let julyCardID = julyCard.value(forKey: "id") as? UUID
        else {
            #expect(false, "Expected cards to expose UUID identifiers")
            return
        }

        let bridgeGroceries = try plannedExpenseService.create(
            inBudgetID: bridgeBudgetID,
            titleOrDescription: "Bridge Groceries",
            plannedAmount: 150,
            actualAmount: 120,
            transactionDate: TestUtils.makeDate(2025, 6, 26)
        )
        bridgeGroceries.expenseCategory = groceries

        let bridgeTravel = try plannedExpenseService.create(
            inBudgetID: bridgeBudgetID,
            titleOrDescription: "Bridge Travel",
            plannedAmount: 200,
            actualAmount: 180,
            transactionDate: TestUtils.makeDate(2025, 7, 3)
        )
        bridgeTravel.expenseCategory = travel

        let julyGroceries = try plannedExpenseService.create(
            inBudgetID: julyBudgetID,
            titleOrDescription: "July Groceries",
            plannedAmount: 400,
            actualAmount: 390,
            transactionDate: TestUtils.makeDate(2025, 7, 5)
        )
        julyGroceries.expenseCategory = groceries

        let julyUtilities = try plannedExpenseService.create(
            inBudgetID: julyBudgetID,
            titleOrDescription: "July Utilities",
            plannedAmount: 150,
            actualAmount: 120,
            transactionDate: TestUtils.makeDate(2025, 7, 15)
        )
        julyUtilities.expenseCategory = utilities

        try context.save()

        let groceriesCategoryID = groceries.value(forKey: "id") as? UUID
        let travelCategoryID = travel.value(forKey: "id") as? UUID
        let utilitiesCategoryID = utilities.value(forKey: "id") as? UUID

        _ = try unplannedExpenseService.create(
            descriptionText: "Bridge Farmers Market",
            amount: 30,
            date: TestUtils.makeDate(2025, 6, 27),
            cardID: bridgeCardID,
            categoryID: groceriesCategoryID
        )
        _ = try unplannedExpenseService.create(
            descriptionText: "Bridge Travel Snacks",
            amount: 50,
            date: TestUtils.makeDate(2025, 7, 4),
            cardID: bridgeCardID,
            categoryID: travelCategoryID
        )
        _ = try unplannedExpenseService.create(
            descriptionText: "July Grocery Run",
            amount: 60,
            date: TestUtils.makeDate(2025, 7, 7),
            cardID: julyCardID,
            categoryID: groceriesCategoryID
        )
        _ = try unplannedExpenseService.create(
            descriptionText: "July Utility Repair",
            amount: 40,
            date: TestUtils.makeDate(2025, 7, 20),
            cardID: julyCardID,
            categoryID: utilitiesCategoryID
        )

        _ = try incomeService.createIncome(
            source: "Bridge Planned",
            amount: 800,
            date: TestUtils.makeDate(2025, 6, 28),
            isPlanned: true
        )
        _ = try incomeService.createIncome(
            source: "Bridge Actual",
            amount: 450,
            date: TestUtils.makeDate(2025, 6, 29),
            isPlanned: false
        )
        _ = try incomeService.createIncome(
            source: "July Planned",
            amount: 2_500,
            date: TestUtils.makeDate(2025, 7, 10),
            isPlanned: true
        )
        _ = try incomeService.createIncome(
            source: "July Actual",
            amount: 1_800,
            date: TestUtils.makeDate(2025, 7, 18),
            isPlanned: false
        )
        _ = try incomeService.createIncome(
            source: "Future Planned",
            amount: 900,
            date: TestUtils.makeDate(2025, 8, 10),
            isPlanned: true
        )

        try context.save()

        let vm = HomeViewModel(context: context)
        vm.selectedDate = TestUtils.makeDate(2025, 7, 15)
        await vm.refresh()

        guard case let .loaded(summaries) = vm.state else {
            #expect(false, "Expected loaded state, found \(vm.state)")
            return
        }

        #expect(summaries.count == 2)

        let summaryByName = Dictionary(uniqueKeysWithValues: summaries.map { ($0.budgetName, $0) })
        let tolerance = 0.0001

        guard let bridgeSummary = summaryByName["Bridge Budget"] else {
            #expect(false, "Missing bridge budget summary")
            return
        }

        #expect(abs(bridgeSummary.plannedExpensesPlannedTotal - 350) < tolerance)
        #expect(abs(bridgeSummary.plannedExpensesActualTotal - 300) < tolerance)
        #expect(abs(bridgeSummary.variableExpensesTotal - 80) < tolerance)
        #expect(abs(bridgeSummary.potentialIncomeTotal - 800) < tolerance)
        #expect(abs(bridgeSummary.actualIncomeTotal - 450) < tolerance)
        #expect(abs(bridgeSummary.potentialSavingsTotal - 450) < tolerance)
        #expect(abs(bridgeSummary.actualSavingsTotal - 70) < tolerance)

        let bridgePlannedBreakdown = Dictionary(uniqueKeysWithValues: bridgeSummary.plannedCategoryBreakdown.map { ($0.categoryName, ($0.amount, $0.hexColor)) })
        #expect(abs((bridgePlannedBreakdown["Travel"]?.0 ?? -1) - 200) < tolerance)
        #expect(abs((bridgePlannedBreakdown["Groceries"]?.0 ?? -1) - 150) < tolerance)
        #expect(abs(bridgePlannedBreakdown["Utilities"]?.0 ?? 0) < tolerance)
        #expect(bridgePlannedBreakdown["Travel"]?.1 == travel.color)
        #expect(bridgePlannedBreakdown["Groceries"]?.1 == groceries.color)

        let bridgeVariableBreakdown = Dictionary(uniqueKeysWithValues: bridgeSummary.variableCategoryBreakdown.map { ($0.categoryName, ($0.amount, $0.hexColor)) })
        #expect(abs((bridgeVariableBreakdown["Travel"]?.0 ?? -1) - 50) < tolerance)
        #expect(abs((bridgeVariableBreakdown["Groceries"]?.0 ?? -1) - 30) < tolerance)
        #expect(abs(bridgeVariableBreakdown["Utilities"]?.0 ?? 0) < tolerance)

        let bridgeCombinedBreakdown = Dictionary(uniqueKeysWithValues: bridgeSummary.categoryBreakdown.map { ($0.categoryName, $0.amount) })
        #expect(abs((bridgeCombinedBreakdown["Travel"] ?? -1) - 250) < tolerance)
        #expect(abs((bridgeCombinedBreakdown["Groceries"] ?? -1) - 180) < tolerance)
        #expect(abs(bridgeCombinedBreakdown["Utilities"] ?? 0) < tolerance)

        guard let julySummary = summaryByName["Primary July"] else {
            #expect(false, "Missing July budget summary")
            return
        }

        #expect(abs(julySummary.plannedExpensesPlannedTotal - 550) < tolerance)
        #expect(abs(julySummary.plannedExpensesActualTotal - 510) < tolerance)
        #expect(abs(julySummary.variableExpensesTotal - 100) < tolerance)
        #expect(abs(julySummary.potentialIncomeTotal - 2_500) < tolerance)
        #expect(abs(julySummary.actualIncomeTotal - 1_800) < tolerance)
        #expect(abs(julySummary.potentialSavingsTotal - 1_950) < tolerance)
        #expect(abs(julySummary.actualSavingsTotal - 1_190) < tolerance)

        let julyPlannedBreakdown = Dictionary(uniqueKeysWithValues: julySummary.plannedCategoryBreakdown.map { ($0.categoryName, ($0.amount, $0.hexColor)) })
        #expect(abs((julyPlannedBreakdown["Groceries"]?.0 ?? -1) - 400) < tolerance)
        #expect(abs((julyPlannedBreakdown["Utilities"]?.0 ?? -1) - 150) < tolerance)
        #expect(julyPlannedBreakdown["Groceries"]?.1 == groceries.color)
        #expect(julyPlannedBreakdown["Utilities"]?.1 == utilities.color)

        let julyVariableBreakdown = Dictionary(uniqueKeysWithValues: julySummary.variableCategoryBreakdown.map { ($0.categoryName, ($0.amount, $0.hexColor)) })
        #expect(abs((julyVariableBreakdown["Groceries"]?.0 ?? -1) - 60) < tolerance)
        #expect(abs((julyVariableBreakdown["Utilities"]?.0 ?? -1) - 40) < tolerance)

        let julyCombinedBreakdown = Dictionary(uniqueKeysWithValues: julySummary.categoryBreakdown.map { ($0.categoryName, $0.amount) })
        #expect(abs((julyCombinedBreakdown["Groceries"] ?? -1) - 460) < tolerance)
        #expect(abs((julyCombinedBreakdown["Utilities"] ?? -1) - 190) < tolerance)
    }

    @Test
    func refresh_withoutOverlappingBudgets_setsEmptyState() async throws {
        UserDefaults.standard.set(BudgetPeriod.monthly.rawValue, forKey: AppSettingsKeys.budgetPeriod.rawValue)

        _ = try TestUtils.resetStore()
        let context = CoreDataService.shared.viewContext
        let budgetService = BudgetService()

        _ = try budgetService.createBudget(
            name: "Spring",
            startDate: TestUtils.makeDate(2025, 3, 1),
            endDate: TestUtils.makeDate(2025, 3, 31)
        )
        _ = try budgetService.createBudget(
            name: "Autumn",
            startDate: TestUtils.makeDate(2025, 9, 1),
            endDate: TestUtils.makeDate(2025, 9, 30)
        )

        let vm = HomeViewModel(context: context)
        vm.selectedDate = TestUtils.makeDate(2025, 7, 15)
        await vm.refresh()

        #expect(vm.state == .empty)
    }

    @Test
    func refresh_includesBudgetsWithPartialOverlap() async throws {
        UserDefaults.standard.set(BudgetPeriod.monthly.rawValue, forKey: AppSettingsKeys.budgetPeriod.rawValue)

        _ = try TestUtils.resetStore()
        let context = CoreDataService.shared.viewContext
        let budgetService = BudgetService()

        let leading = try budgetService.createBudget(
            name: "Leading Edge",
            startDate: TestUtils.makeDate(2025, 6, 20),
            endDate: TestUtils.makeDate(2025, 7, 2)
        )
        let trailing = try budgetService.createBudget(
            name: "Trailing Edge",
            startDate: TestUtils.makeDate(2025, 7, 25),
            endDate: TestUtils.makeDate(2025, 8, 5)
        )
        _ = try budgetService.createBudget(
            name: "Non Overlap",
            startDate: TestUtils.makeDate(2025, 8, 10),
            endDate: TestUtils.makeDate(2025, 8, 20)
        )

        let vm = HomeViewModel(context: context)
        vm.selectedDate = TestUtils.makeDate(2025, 7, 10)
        await vm.refresh()

        guard case let .loaded(summaries) = vm.state else {
            #expect(false, "Expected loaded state for partial overlaps, found \(vm.state)")
            return
        }

        #expect(summaries.count == 2)
        let names = summaries.map { $0.budgetName }.sorted()
        #expect(names == ["Leading Edge", "Trailing Edge"])

        guard
            let leadingSummary = summaries.first(where: { $0.budgetName == "Leading Edge" }),
            let trailingSummary = summaries.first(where: { $0.budgetName == "Trailing Edge" }),
            let leadingStart = leading.startDate,
            let leadingEnd = leading.endDate,
            let trailingStart = trailing.startDate,
            let trailingEnd = trailing.endDate
        else {
            #expect(false, "Expected summaries and budget dates to be available")
            return
        }

        #expect(leadingSummary.periodStart == leadingStart)
        #expect(leadingSummary.periodEnd == leadingEnd)
        #expect(trailingSummary.periodStart == trailingStart)
        #expect(trailingSummary.periodEnd == trailingEnd)
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

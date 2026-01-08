import XCTest
import CoreData
@testable import Offshore

final class HomeViewSummaryTests: XCTestCase {

    private var originalTimeZone: TimeZone?
    private var calendar: Calendar = {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(secondsFromGMT: 0) ?? .current
        return cal
    }()

    override func setUp() {
        super.setUp()
        originalTimeZone = NSTimeZone.default
        NSTimeZone.default = calendar.timeZone
    }

    override func tearDown() {
        if let originalTimeZone {
            NSTimeZone.default = originalTimeZone
        }
        super.tearDown()
    }

    func testSummaryForCurrentMonth() throws {
        let anchor = makeDate(year: 2025, month: 1, day: 15)
        let range = BudgetPeriod.monthly.range(containing: anchor)
        let context = try makeInMemoryContext()

        let incomes: [IncomeSeed] = [
            .init(amount: 1000, date: makeDate(year: 2025, month: 1, day: 1, hour: 9), isPlanned: false),
            .init(amount: 500, date: makeDate(year: 2025, month: 1, day: 15, hour: 12), isPlanned: false),
            .init(amount: 250, date: makeDate(year: 2025, month: 1, day: 31, hour: 23, minute: 59, second: 59), isPlanned: false),
            .init(amount: 2000, date: makeDate(year: 2025, month: 1, day: 5, hour: 10), isPlanned: true),
            .init(amount: 300, date: makeDate(year: 2025, month: 1, day: 31), isPlanned: true),
            .init(amount: 999, date: makeDate(year: 2025, month: 2, day: 1), isPlanned: false),
            .init(amount: 111, date: makeDate(year: 2024, month: 12, day: 31, hour: 23, minute: 59, second: 59), isPlanned: true)
        ]

        let plannedExpenses: [PlannedExpenseSeed] = [
            .init(planned: 300, actual: 280, date: makeDate(year: 2025, month: 1, day: 10, hour: 8)),
            .init(planned: 200, actual: 210, date: makeDate(year: 2025, month: 1, day: 20, hour: 18))
        ]

        let unplannedExpenses: [UnplannedExpenseSeed] = [
            .init(amount: 75, date: makeDate(year: 2025, month: 1, day: 12, hour: 14)),
            .init(amount: 25, date: makeDate(year: 2025, month: 1, day: 31, hour: 23, minute: 59, second: 59)),
            .init(amount: 40, date: makeDate(year: 2025, month: 2, day: 1))
        ]

        let seed = try seedData(
            in: context,
            budgetRange: range.start...range.end,
            incomes: incomes,
            plannedExpenses: plannedExpenses,
            unplannedExpenses: unplannedExpenses
        )
        let summary = try buildSummary(in: context, seed: seed, range: range.start...range.end)
        let expected = expectedTotals(range: range.start...range.end, incomes: incomes, plannedExpenses: plannedExpenses, unplannedExpenses: unplannedExpenses)

        assertSummary(summary, matches: expected)
        assertWidgetMetrics(summary, matches: expected)
    }

    func testSummaryForCustomRange() throws {
        let start = makeDate(year: 2025, month: 2, day: 10)
        let end = makeDate(year: 2025, month: 3, day: 5, hour: 23, minute: 59, second: 59)
        let range = start...end
        let context = try makeInMemoryContext()

        let incomes: [IncomeSeed] = [
            .init(amount: 400, date: makeDate(year: 2025, month: 2, day: 10, hour: 8), isPlanned: false),
            .init(amount: 600, date: makeDate(year: 2025, month: 2, day: 20, hour: 9), isPlanned: true),
            .init(amount: 300, date: makeDate(year: 2025, month: 3, day: 1, hour: 13), isPlanned: false),
            .init(amount: 200, date: makeDate(year: 2025, month: 3, day: 5, hour: 23, minute: 59, second: 59), isPlanned: true),
            .init(amount: 100, date: makeDate(year: 2025, month: 2, day: 9, hour: 23, minute: 59, second: 59), isPlanned: false),
            .init(amount: 500, date: makeDate(year: 2025, month: 3, day: 6), isPlanned: true)
        ]

        let plannedExpenses: [PlannedExpenseSeed] = [
            .init(planned: 150, actual: 140, date: makeDate(year: 2025, month: 2, day: 15, hour: 11)),
            .init(planned: 250, actual: 260, date: makeDate(year: 2025, month: 3, day: 3, hour: 16))
        ]

        let unplannedExpenses: [UnplannedExpenseSeed] = [
            .init(amount: 90, date: makeDate(year: 2025, month: 2, day: 12, hour: 15)),
            .init(amount: 60, date: makeDate(year: 2025, month: 3, day: 5, hour: 23, minute: 59, second: 59)),
            .init(amount: 30, date: makeDate(year: 2025, month: 3, day: 6))
        ]

        let seed = try seedData(
            in: context,
            budgetRange: range,
            incomes: incomes,
            plannedExpenses: plannedExpenses,
            unplannedExpenses: unplannedExpenses
        )
        let summary = try buildSummary(in: context, seed: seed, range: range)
        let expected = expectedTotals(range: range, incomes: incomes, plannedExpenses: plannedExpenses, unplannedExpenses: unplannedExpenses)

        assertSummary(summary, matches: expected)
        assertWidgetMetrics(summary, matches: expected)
    }

    func testSummaryForCurrentQuarter() throws {
        let anchor = makeDate(year: 2025, month: 5, day: 15)
        let range = BudgetPeriod.quarterly.range(containing: anchor)
        let context = try makeInMemoryContext()

        let incomes: [IncomeSeed] = [
            .init(amount: 1200, date: makeDate(year: 2025, month: 4, day: 1), isPlanned: false),
            .init(amount: 1000, date: makeDate(year: 2025, month: 4, day: 15, hour: 9), isPlanned: true),
            .init(amount: 800, date: makeDate(year: 2025, month: 5, day: 20, hour: 18), isPlanned: false),
            .init(amount: 900, date: makeDate(year: 2025, month: 6, day: 30, hour: 23, minute: 59, second: 59), isPlanned: true),
            .init(amount: 700, date: makeDate(year: 2025, month: 3, day: 31, hour: 23, minute: 59, second: 59), isPlanned: false),
            .init(amount: 600, date: makeDate(year: 2025, month: 7, day: 1), isPlanned: true)
        ]

        let plannedExpenses: [PlannedExpenseSeed] = [
            .init(planned: 500, actual: 480, date: makeDate(year: 2025, month: 4, day: 10, hour: 7)),
            .init(planned: 300, actual: 320, date: makeDate(year: 2025, month: 6, day: 5, hour: 19))
        ]

        let unplannedExpenses: [UnplannedExpenseSeed] = [
            .init(amount: 150, date: makeDate(year: 2025, month: 4, day: 20, hour: 13)),
            .init(amount: 200, date: makeDate(year: 2025, month: 6, day: 30, hour: 23, minute: 59, second: 59)),
            .init(amount: 90, date: makeDate(year: 2025, month: 7, day: 1))
        ]

        let seed = try seedData(
            in: context,
            budgetRange: range.start...range.end,
            incomes: incomes,
            plannedExpenses: plannedExpenses,
            unplannedExpenses: unplannedExpenses
        )
        let summary = try buildSummary(in: context, seed: seed, range: range.start...range.end)
        let expected = expectedTotals(range: range.start...range.end, incomes: incomes, plannedExpenses: plannedExpenses, unplannedExpenses: unplannedExpenses)

        assertSummary(summary, matches: expected)
        assertWidgetMetrics(summary, matches: expected)
    }

    func testSummaryForYearlyRange() throws {
        let anchor = makeDate(year: 2025, month: 9, day: 15)
        let range = BudgetPeriod.yearly.range(containing: anchor)
        let context = try makeInMemoryContext()

        let incomes: [IncomeSeed] = [
            .init(amount: 1000, date: makeDate(year: 2025, month: 1, day: 1), isPlanned: false),
            .init(amount: 2000, date: makeDate(year: 2025, month: 2, day: 1, hour: 12), isPlanned: true),
            .init(amount: 1500, date: makeDate(year: 2025, month: 7, day: 4, hour: 14), isPlanned: false),
            .init(amount: 1200, date: makeDate(year: 2025, month: 12, day: 31, hour: 23, minute: 59, second: 59), isPlanned: true),
            .init(amount: 500, date: makeDate(year: 2024, month: 12, day: 31, hour: 23, minute: 59, second: 59), isPlanned: false),
            .init(amount: 900, date: makeDate(year: 2026, month: 1, day: 1), isPlanned: true)
        ]

        let plannedExpenses: [PlannedExpenseSeed] = [
            .init(planned: 700, actual: 650, date: makeDate(year: 2025, month: 3, day: 10, hour: 10)),
            .init(planned: 400, actual: 420, date: makeDate(year: 2025, month: 10, day: 5, hour: 9)),
            .init(planned: 300, actual: 300, date: makeDate(year: 2025, month: 12, day: 20, hour: 17))
        ]

        let unplannedExpenses: [UnplannedExpenseSeed] = [
            .init(amount: 200, date: makeDate(year: 2025, month: 5, day: 15, hour: 11)),
            .init(amount: 350, date: makeDate(year: 2025, month: 11, day: 30, hour: 16)),
            .init(amount: 30, date: makeDate(year: 2026, month: 1, day: 1))
        ]

        let seed = try seedData(
            in: context,
            budgetRange: range.start...range.end,
            incomes: incomes,
            plannedExpenses: plannedExpenses,
            unplannedExpenses: unplannedExpenses
        )
        let summary = try buildSummary(in: context, seed: seed, range: range.start...range.end)
        let expected = expectedTotals(range: range.start...range.end, incomes: incomes, plannedExpenses: plannedExpenses, unplannedExpenses: unplannedExpenses)

        assertSummary(summary, matches: expected)
        assertWidgetMetrics(summary, matches: expected)
    }

    // MARK: - Seed Types
    private struct IncomeSeed {
        let amount: Double
        let date: Date
        let isPlanned: Bool
    }

    private struct PlannedExpenseSeed {
        let planned: Double
        let actual: Double
        let date: Date
    }

    private struct UnplannedExpenseSeed {
        let amount: Double
        let date: Date
    }

    private struct SeededData {
        let workspaceID: UUID
        let budget: Budget
        let category: ExpenseCategory
        let incomes: [IncomeSeed]
        let plannedExpenses: [PlannedExpenseSeed]
        let unplannedExpenses: [UnplannedExpenseSeed]
    }

    // MARK: - Expected Totals
    private struct ExpectedTotals {
        let plannedIncome: Double
        let actualIncome: Double
        let plannedExpensesPlanned: Double
        let plannedExpensesActual: Double
        let variableExpenses: Double

        var expensesTotal: Double { plannedExpensesActual + variableExpenses }
        var actualSavings: Double { actualIncome - expensesTotal }
        var projectedSavings: Double {
            let remainingIncome = max(plannedIncome - actualIncome, 0)
            let remainingPlannedExpenses = max(plannedExpensesPlanned - plannedExpensesActual, 0)
            return actualSavings + remainingIncome - remainingPlannedExpenses
        }
    }

    // MARK: - Seed Helpers
    private func seedData(
        in context: NSManagedObjectContext,
        budgetRange: ClosedRange<Date>,
        incomes: [IncomeSeed],
        plannedExpenses: [PlannedExpenseSeed],
        unplannedExpenses: [UnplannedExpenseSeed]
    ) throws -> SeededData {
        let workspaceID = UUID()
        let budget = NSEntityDescription.insertNewObject(
            forEntityName: String(describing: Budget.self),
            into: context
        ) as! Budget
        budget.id = UUID()
        budget.name = "Test Budget"
        budget.startDate = budgetRange.lowerBound
        budget.endDate = budgetRange.upperBound
        budget.workspaceID = workspaceID

        let category = NSEntityDescription.insertNewObject(
            forEntityName: String(describing: ExpenseCategory.self),
            into: context
        ) as! ExpenseCategory
        category.id = UUID()
        category.name = "General"
        category.workspaceID = workspaceID

        let card = NSEntityDescription.insertNewObject(
            forEntityName: String(describing: Card.self),
            into: context
        ) as! Card
        card.id = UUID()
        card.name = "Primary"
        card.workspaceID = workspaceID
        budget.addToCards(card)

        for income in incomes {
            let inc = NSEntityDescription.insertNewObject(
                forEntityName: String(describing: Income.self),
                into: context
            ) as! Income
            inc.id = UUID()
            inc.amount = income.amount
            inc.date = income.date
            inc.isPlanned = income.isPlanned
            inc.workspaceID = workspaceID
        }

        for planned in plannedExpenses {
            let exp = NSEntityDescription.insertNewObject(
                forEntityName: String(describing: PlannedExpense.self),
                into: context
            ) as! PlannedExpense
            exp.id = UUID()
            exp.transactionDate = planned.date
            exp.plannedAmount = planned.planned
            exp.actualAmount = planned.actual
            exp.budget = budget
            exp.expenseCategory = category
            exp.workspaceID = workspaceID
        }

        for unplanned in unplannedExpenses {
            let exp = NSEntityDescription.insertNewObject(
                forEntityName: String(describing: UnplannedExpense.self),
                into: context
            ) as! UnplannedExpense
            exp.id = UUID()
            exp.transactionDate = unplanned.date
            exp.amount = unplanned.amount
            exp.card = card
            exp.expenseCategory = category
            exp.workspaceID = workspaceID
        }

        try context.save()
        return SeededData(
            workspaceID: workspaceID,
            budget: budget,
            category: category,
            incomes: incomes,
            plannedExpenses: plannedExpenses,
            unplannedExpenses: unplannedExpenses
        )
    }

    // MARK: - Summary Helpers
    private func buildSummary(
        in context: NSManagedObjectContext,
        seed: SeededData,
        range: ClosedRange<Date>
    ) throws -> BudgetSummary {
        let incomeReq = NSFetchRequest<Income>(entityName: "Income")
        let allIncomes = (try? context.fetch(incomeReq)) ?? []
        return HomeViewModel.buildSummary(
            for: seed.budget,
            periodStart: range.lowerBound,
            periodEnd: range.upperBound,
            allCategories: [seed.category],
            allIncomes: allIncomes,
            in: context,
            workspaceID: seed.workspaceID
        )
    }

    private func expectedTotals(
        range: ClosedRange<Date>,
        incomes: [IncomeSeed],
        plannedExpenses: [PlannedExpenseSeed],
        unplannedExpenses: [UnplannedExpenseSeed]
    ) -> ExpectedTotals {
        let startDay = calendar.startOfDay(for: range.lowerBound)
        let endDay = calendar.startOfDay(for: range.upperBound)
        let endExclusive = calendar.date(byAdding: .day, value: 1, to: endDay) ?? range.upperBound
        let inRangeIncome = incomes.filter { $0.date >= startDay && $0.date < endExclusive }
        let plannedIncome = inRangeIncome.filter { $0.isPlanned }.reduce(0) { $0 + $1.amount }
        let actualIncome = inRangeIncome.filter { !$0.isPlanned }.reduce(0) { $0 + $1.amount }
        let plannedTotal = plannedExpenses.reduce(0) { $0 + $1.planned }
        let actualTotal = plannedExpenses.reduce(0) { $0 + $1.actual }
        let variableTotal = unplannedExpenses
            .filter { $0.date >= startDay && $0.date < endExclusive }
            .reduce(0) { $0 + $1.amount }

        return ExpectedTotals(
            plannedIncome: plannedIncome,
            actualIncome: actualIncome,
            plannedExpensesPlanned: plannedTotal,
            plannedExpensesActual: actualTotal,
            variableExpenses: variableTotal
        )
    }

    // MARK: - Assertions
    private func assertSummary(_ summary: BudgetSummary, matches expected: ExpectedTotals, file: StaticString = #file, line: UInt = #line) {
        XCTAssertEqual(summary.potentialIncomeTotal, expected.plannedIncome, accuracy: 0.001, file: file, line: line)
        XCTAssertEqual(summary.actualIncomeTotal, expected.actualIncome, accuracy: 0.001, file: file, line: line)
        XCTAssertEqual(summary.plannedExpensesPlannedTotal, expected.plannedExpensesPlanned, accuracy: 0.001, file: file, line: line)
        XCTAssertEqual(summary.plannedExpensesActualTotal, expected.plannedExpensesActual, accuracy: 0.001, file: file, line: line)
        XCTAssertEqual(summary.variableExpensesTotal, expected.variableExpenses, accuracy: 0.001, file: file, line: line)
        XCTAssertEqual(summary.actualSavingsTotal, expected.actualSavings, accuracy: 0.001, file: file, line: line)
    }

    private func assertWidgetMetrics(_ summary: BudgetSummary, matches expected: ExpectedTotals, file: StaticString = #file, line: UInt = #line) {
        let expenses = expected.expensesTotal
        let ratio = BudgetMetrics.expenseToIncome(
            expenses: expenses,
            expectedIncome: expected.plannedIncome,
            receivedIncome: expected.actualIncome
        )
        let expectedPercentOfExpected = expected.plannedIncome == 0 ? 0 : (expenses / expected.plannedIncome) * 100
        let expectedPercentOfReceived = expected.actualIncome == 0 ? 0 : (expenses / expected.actualIncome) * 100

        XCTAssertEqual(ratio.percentOfExpected, expectedPercentOfExpected, accuracy: 0.01, file: file, line: line)
        XCTAssertEqual(ratio.percentOfReceived ?? 0, expectedPercentOfReceived, accuracy: 0.01, file: file, line: line)

        let outlook = BudgetMetrics.savingsOutlook(
            actualSavings: summary.actualSavingsTotal,
            expectedIncome: summary.potentialIncomeTotal,
            incomeReceived: summary.actualIncomeTotal,
            plannedExpensesPlanned: summary.plannedExpensesPlannedTotal,
            plannedExpensesActual: summary.plannedExpensesActualTotal
        )
        XCTAssertEqual(outlook.projected, expected.projectedSavings, accuracy: 0.001, file: file, line: line)
    }

    // MARK: - Core Data Helpers
    private func makeInMemoryContext(file: StaticString = #file, line: UInt = #line) throws -> NSManagedObjectContext {
        let bundle = Bundle(identifier: "com.mb.offshore-budgeting") ?? Bundle(for: CoreDataService.self)
        let modelURL = try XCTUnwrap(bundle.url(forResource: "OffshoreBudgetingModel", withExtension: "momd"), file: file, line: line)
        let model = try XCTUnwrap(NSManagedObjectModel(contentsOf: modelURL), file: file, line: line)
        let container = NSPersistentContainer(name: "OffshoreBudgetingModel", managedObjectModel: model)
        let description = NSPersistentStoreDescription()
        description.type = NSInMemoryStoreType
        description.shouldAddStoreAsynchronously = false
        container.persistentStoreDescriptions = [description]

        var loadError: Error?
        container.loadPersistentStores { _, error in
            loadError = error
        }
        XCTAssertNil(loadError, file: file, line: line)
        return container.viewContext
    }

    // MARK: - Date Helpers
    private func makeDate(
        year: Int,
        month: Int,
        day: Int,
        hour: Int = 0,
        minute: Int = 0,
        second: Int = 0
    ) -> Date {
        let components = DateComponents(
            calendar: calendar,
            timeZone: calendar.timeZone,
            year: year,
            month: month,
            day: day,
            hour: hour,
            minute: minute,
            second: second
        )
        return calendar.date(from: components) ?? Date()
    }
}

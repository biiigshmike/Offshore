import XCTest
import CoreData
@testable import Offshore

final class MasterBudgetCRUDIntegrationTests: XCTestCase {
    private let workspaceDefaultsKey = AppSettingsKeys.activeWorkspaceID.rawValue

    private var stack: TestCoreDataStack!
    private var context: NSManagedObjectContext!
    private var budgetService: BudgetService!
    private var cardService: CardService!
    private var categoryService: ExpenseCategoryService!
    private var plannedService: PlannedExpenseService!
    private var unplannedService: UnplannedExpenseService!
    private var incomeService: IncomeService!

    private var originalWorkspaceID: String?
    private var originalTimeZone: TimeZone?

    private var calendar: Calendar = {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(secondsFromGMT: 0) ?? .current
        return cal
    }()

    override func setUpWithError() throws {
        try super.setUpWithError()

        originalWorkspaceID = UserDefaults.standard.string(forKey: workspaceDefaultsKey)
        originalTimeZone = NSTimeZone.default
        NSTimeZone.default = calendar.timeZone

        stack = try TestCoreDataStack()
        context = stack.container.viewContext
        budgetService = BudgetService(stack: stack)
        cardService = CardService(stack: stack)
        categoryService = ExpenseCategoryService(stack: stack)
        plannedService = PlannedExpenseService(stack: stack)
        unplannedService = UnplannedExpenseService(stack: stack, calendar: calendar)
        incomeService = IncomeService(stack: stack, calendar: calendar)
    }

    override func tearDownWithError() throws {
        if let originalWorkspaceID {
            UserDefaults.standard.set(originalWorkspaceID, forKey: workspaceDefaultsKey)
        } else {
            UserDefaults.standard.removeObject(forKey: workspaceDefaultsKey)
        }
        if let originalTimeZone {
            NSTimeZone.default = originalTimeZone
        }

        incomeService = nil
        unplannedService = nil
        plannedService = nil
        categoryService = nil
        cardService = nil
        budgetService = nil
        context = nil
        stack = nil

        try super.tearDownWithError()
    }

    func testMonthlyScenario_masterCRUD() throws {
        let anchor = makeDate(year: 2025, month: 1, day: 15)
        let scenario = try buildScenario(period: .monthly,
                                         anchorDate: anchor,
                                         seed: Self.monthlySeed,
                                         foreignSeed: Self.foreignSeed,
                                         name: "Monthly")
        try assertScenario(scenario)
    }

    func testQuarterlyScenario_masterCRUD() throws {
        let anchor = makeDate(year: 2025, month: 2, day: 12)
        let scenario = try buildScenario(period: .quarterly,
                                         anchorDate: anchor,
                                         seed: Self.quarterlySeed,
                                         foreignSeed: Self.foreignSeed,
                                         name: "Q1")
        try assertScenario(scenario)
    }

    func testYearlyScenario_masterCRUD() throws {
        let anchor = makeDate(year: 2025, month: 7, day: 4)
        let scenario = try buildScenario(period: .yearly,
                                         anchorDate: anchor,
                                         seed: Self.yearlySeed,
                                         foreignSeed: Self.foreignSeed,
                                         name: "Yearly")
        try assertScenario(scenario)
    }

    // MARK: - Scenario Types

    private struct ScenarioSeed {
        let workspaceID: UUID
        let budgetID: UUID
        let cardID: UUID
        let categoryID: UUID
        let plannedTemplateID: UUID
        let plannedExpenseID: UUID
        let unplannedExpenseID: UUID
        let plannedIncomeID: UUID
        let actualIncomeID: UUID
    }

    private struct ScenarioData {
        let workspaceID: UUID
        let budgetID: UUID
        let cardID: UUID
        let categoryID: UUID
        let plannedTemplateID: UUID
        let plannedExpenseID: UUID
        let unplannedExpenseID: UUID
        let plannedIncomeID: UUID
        let actualIncomeID: UUID
        let range: DateInterval
    }

    private struct Scenario {
        let primary: ScenarioData
        let foreign: ScenarioData
    }

    private static let monthlySeed = ScenarioSeed(
        workspaceID: UUID(uuidString: "11111111-1111-1111-1111-111111111111")!,
        budgetID: UUID(uuidString: "11111111-2222-3333-4444-555555555555")!,
        cardID: UUID(uuidString: "11111111-aaaa-bbbb-cccc-000000000001")!,
        categoryID: UUID(uuidString: "11111111-aaaa-bbbb-cccc-000000000002")!,
        plannedTemplateID: UUID(uuidString: "11111111-aaaa-bbbb-cccc-000000000003")!,
        plannedExpenseID: UUID(uuidString: "11111111-aaaa-bbbb-cccc-000000000004")!,
        unplannedExpenseID: UUID(uuidString: "11111111-aaaa-bbbb-cccc-000000000005")!,
        plannedIncomeID: UUID(uuidString: "11111111-aaaa-bbbb-cccc-000000000006")!,
        actualIncomeID: UUID(uuidString: "11111111-aaaa-bbbb-cccc-000000000007")!
    )

    private static let quarterlySeed = ScenarioSeed(
        workspaceID: UUID(uuidString: "22222222-1111-1111-1111-111111111111")!,
        budgetID: UUID(uuidString: "22222222-2222-3333-4444-555555555555")!,
        cardID: UUID(uuidString: "22222222-aaaa-bbbb-cccc-000000000001")!,
        categoryID: UUID(uuidString: "22222222-aaaa-bbbb-cccc-000000000002")!,
        plannedTemplateID: UUID(uuidString: "22222222-aaaa-bbbb-cccc-000000000003")!,
        plannedExpenseID: UUID(uuidString: "22222222-aaaa-bbbb-cccc-000000000004")!,
        unplannedExpenseID: UUID(uuidString: "22222222-aaaa-bbbb-cccc-000000000005")!,
        plannedIncomeID: UUID(uuidString: "22222222-aaaa-bbbb-cccc-000000000006")!,
        actualIncomeID: UUID(uuidString: "22222222-aaaa-bbbb-cccc-000000000007")!
    )

    private static let yearlySeed = ScenarioSeed(
        workspaceID: UUID(uuidString: "33333333-1111-1111-1111-111111111111")!,
        budgetID: UUID(uuidString: "33333333-2222-3333-4444-555555555555")!,
        cardID: UUID(uuidString: "33333333-aaaa-bbbb-cccc-000000000001")!,
        categoryID: UUID(uuidString: "33333333-aaaa-bbbb-cccc-000000000002")!,
        plannedTemplateID: UUID(uuidString: "33333333-aaaa-bbbb-cccc-000000000003")!,
        plannedExpenseID: UUID(uuidString: "33333333-aaaa-bbbb-cccc-000000000004")!,
        unplannedExpenseID: UUID(uuidString: "33333333-aaaa-bbbb-cccc-000000000005")!,
        plannedIncomeID: UUID(uuidString: "33333333-aaaa-bbbb-cccc-000000000006")!,
        actualIncomeID: UUID(uuidString: "33333333-aaaa-bbbb-cccc-000000000007")!
    )

    private static let foreignSeed = ScenarioSeed(
        workspaceID: UUID(uuidString: "99999999-1111-1111-1111-111111111111")!,
        budgetID: UUID(uuidString: "99999999-2222-3333-4444-555555555555")!,
        cardID: UUID(uuidString: "99999999-aaaa-bbbb-cccc-000000000001")!,
        categoryID: UUID(uuidString: "99999999-aaaa-bbbb-cccc-000000000002")!,
        plannedTemplateID: UUID(uuidString: "99999999-aaaa-bbbb-cccc-000000000003")!,
        plannedExpenseID: UUID(uuidString: "99999999-aaaa-bbbb-cccc-000000000004")!,
        unplannedExpenseID: UUID(uuidString: "99999999-aaaa-bbbb-cccc-000000000005")!,
        plannedIncomeID: UUID(uuidString: "99999999-aaaa-bbbb-cccc-000000000006")!,
        actualIncomeID: UUID(uuidString: "99999999-aaaa-bbbb-cccc-000000000007")!
    )

    // MARK: - Scenario Builder

    private func buildScenario(period: BudgetPeriod,
                               anchorDate: Date,
                               seed: ScenarioSeed,
                               foreignSeed: ScenarioSeed,
                               name: String) throws -> Scenario {
        let range = period.range(containing: anchorDate)
        let interval = DateInterval(start: range.start, end: range.end)

        UserDefaults.standard.set(seed.workspaceID.uuidString, forKey: workspaceDefaultsKey)
        let primary = try createScenarioData(seed: seed, name: name, interval: interval)

        let foreign = try withActiveWorkspaceID(foreignSeed.workspaceID) {
            try createScenarioData(seed: foreignSeed, name: "Foreign \(name)", interval: interval)
        }

        UserDefaults.standard.set(seed.workspaceID.uuidString, forKey: workspaceDefaultsKey)
        return Scenario(primary: primary, foreign: foreign)
    }

    private func createScenarioData(seed: ScenarioSeed,
                                    name: String,
                                    interval: DateInterval) throws -> ScenarioData {
        let templateDate = offsetDate(from: interval.start, days: 2, hour: 9)
        let plannedDate = offsetDate(from: interval.start, days: 6, hour: 11)
        let unplannedDate = offsetDate(from: interval.start, days: 9, hour: 14)
        let plannedIncomeDate = offsetDate(from: interval.start, days: 12, hour: 10)
        let actualIncomeDate = offsetDate(from: interval.start, days: 18, hour: 15)

        let budget = try budgetService.createBudget(
            name: "\(name) Budget",
            startDate: interval.start,
            endDate: interval.end
        )
        try setEntityID(budget, id: seed.budgetID)

        let card = try cardService.createCard(
            name: "\(name) Card",
            attachToBudgetIDs: [seed.budgetID]
        )
        try setEntityID(card, id: seed.cardID)

        let category = try categoryService.addCategory(
            name: "\(name) Category",
            color: "#112233"
        )
        try setEntityID(category, id: seed.categoryID)

        let template = try plannedService.createGlobalTemplate(
            titleOrDescription: "\(name) Template",
            plannedAmount: 120,
            actualAmount: 0,
            defaultTransactionDate: templateDate
        )
        try setEntityID(template, id: seed.plannedTemplateID)

        let planned = try plannedService.create(
            inBudgetID: seed.budgetID,
            titleOrDescription: "\(name) Planned",
            plannedAmount: 75,
            actualAmount: 60,
            transactionDate: plannedDate,
            isGlobal: false,
            globalTemplateID: seed.plannedTemplateID
        )
        try setEntityID(planned, id: seed.plannedExpenseID)
        planned.setValue(card, forKey: "card")
        planned.setValue(category, forKey: "expenseCategory")
        try context.save()

        let unplanned = try unplannedService.create(
            descriptionText: "\(name) Unplanned",
            amount: 45,
            date: unplannedDate,
            cardID: seed.cardID,
            categoryID: seed.categoryID
        )
        try setEntityID(unplanned, id: seed.unplannedExpenseID)

        let plannedIncome = try incomeService.createIncome(
            source: "\(name) Planned Income",
            amount: 2000,
            date: plannedIncomeDate,
            isPlanned: true
        )
        try setEntityID(plannedIncome, id: seed.plannedIncomeID)

        let actualIncome = try incomeService.createIncome(
            source: "\(name) Actual Income",
            amount: 1800,
            date: actualIncomeDate,
            isPlanned: false
        )
        try setEntityID(actualIncome, id: seed.actualIncomeID)

        return ScenarioData(
            workspaceID: seed.workspaceID,
            budgetID: seed.budgetID,
            cardID: seed.cardID,
            categoryID: seed.categoryID,
            plannedTemplateID: seed.plannedTemplateID,
            plannedExpenseID: seed.plannedExpenseID,
            unplannedExpenseID: seed.unplannedExpenseID,
            plannedIncomeID: seed.plannedIncomeID,
            actualIncomeID: seed.actualIncomeID,
            range: interval
        )
    }

    // MARK: - Assertions

    private func assertScenario(_ scenario: Scenario, file: StaticString = #file, line: UInt = #line) throws {
        UserDefaults.standard.set(scenario.primary.workspaceID.uuidString, forKey: workspaceDefaultsKey)

        try assertFetchesAndScoping(scenario, file: file, line: line)
        try assertRelationships(scenario.primary, file: file, line: line)
        try assertCRUDUpdates(scenario.primary, file: file, line: line)
        try assertDeleteSemantics(scenario.primary, file: file, line: line)
    }

    private func assertFetchesAndScoping(_ scenario: Scenario,
                                         file: StaticString = #file,
                                         line: UInt = #line) throws {
        let budget = try budgetService.findBudget(byID: scenario.primary.budgetID)
        XCTAssertNotNil(budget, file: file, line: line)
        XCTAssertNil(try budgetService.findBudget(byID: scenario.foreign.budgetID), file: file, line: line)

        let budgets = try budgetService.fetchAllBudgets()
        XCTAssertEqual(entityIDs(from: budgets), [scenario.primary.budgetID], file: file, line: line)

        let card = try cardService.findCard(byID: scenario.primary.cardID)
        XCTAssertNotNil(card, file: file, line: line)
        XCTAssertNil(try cardService.findCard(byID: scenario.foreign.cardID), file: file, line: line)

        let cards = try cardService.fetchAllCards(sortedByName: true)
        XCTAssertEqual(entityIDs(from: cards), [scenario.primary.cardID], file: file, line: line)

        let category = try categoryService.findCategory(byID: scenario.primary.categoryID)
        XCTAssertNotNil(category, file: file, line: line)
        XCTAssertNil(try categoryService.findCategory(byID: scenario.foreign.categoryID), file: file, line: line)

        let categories = try categoryService.fetchAllCategories(sortedByName: true)
        XCTAssertEqual(entityIDs(from: categories), [scenario.primary.categoryID], file: file, line: line)

        let planned = try plannedService.find(byID: scenario.primary.plannedExpenseID)
        XCTAssertNotNil(planned, file: file, line: line)
        XCTAssertNil(try plannedService.find(byID: scenario.foreign.plannedExpenseID), file: file, line: line)

        let plannedTemplate = try plannedService.find(byID: scenario.primary.plannedTemplateID)
        XCTAssertNotNil(plannedTemplate, file: file, line: line)
        XCTAssertNil(try plannedService.find(byID: scenario.foreign.plannedTemplateID), file: file, line: line)

        let plannedAll = try plannedService.fetchAll(sortedByDateAscending: true)
        XCTAssertEqual(Set(entityIDs(from: plannedAll)),
                       Set([scenario.primary.plannedExpenseID, scenario.primary.plannedTemplateID]),
                       file: file,
                       line: line)

        let unplanned = try unplannedService.find(byID: scenario.primary.unplannedExpenseID)
        XCTAssertNotNil(unplanned, file: file, line: line)
        XCTAssertNil(try unplannedService.find(byID: scenario.foreign.unplannedExpenseID), file: file, line: line)

        let unplannedAll = try unplannedService.fetchAll(sortedByDateAscending: true)
        XCTAssertEqual(entityIDs(from: unplannedAll), [scenario.primary.unplannedExpenseID], file: file, line: line)

        let plannedIncome = try incomeService.findIncome(byID: scenario.primary.plannedIncomeID)
        XCTAssertNotNil(plannedIncome, file: file, line: line)
        XCTAssertNil(try incomeService.findIncome(byID: scenario.foreign.plannedIncomeID), file: file, line: line)

        let actualIncome = try incomeService.findIncome(byID: scenario.primary.actualIncomeID)
        XCTAssertNotNil(actualIncome, file: file, line: line)
        XCTAssertNil(try incomeService.findIncome(byID: scenario.foreign.actualIncomeID), file: file, line: line)

        let allIncomes = try incomeService.fetchAllIncomes(sortedByDateAscending: true)
        XCTAssertEqual(Set(entityIDs(from: allIncomes)),
                       Set([scenario.primary.plannedIncomeID, scenario.primary.actualIncomeID]),
                       file: file,
                       line: line)
    }

    private func assertRelationships(_ scenario: ScenarioData,
                                     file: StaticString = #file,
                                     line: UInt = #line) throws {
        let planned = try XCTUnwrap(plannedService.find(byID: scenario.plannedExpenseID), file: file, line: line)
        XCTAssertFalse(planned.isGlobal, file: file, line: line)
        XCTAssertEqual(planned.globalTemplateID, scenario.plannedTemplateID, file: file, line: line)

        let plannedBudget = planned.value(forKey: "budget") as? Budget
        XCTAssertEqual(entityID(from: plannedBudget), scenario.budgetID, file: file, line: line)

        let plannedCard = planned.value(forKey: "card") as? Card
        XCTAssertEqual(entityID(from: plannedCard), scenario.cardID, file: file, line: line)

        let plannedCategory = planned.value(forKey: "expenseCategory") as? ExpenseCategory
        XCTAssertEqual(entityID(from: plannedCategory), scenario.categoryID, file: file, line: line)

        let template = try XCTUnwrap(plannedService.find(byID: scenario.plannedTemplateID), file: file, line: line)
        XCTAssertTrue(template.isGlobal, file: file, line: line)
        XCTAssertNil(template.globalTemplateID, file: file, line: line)
        XCTAssertNil(template.value(forKey: "budget") as? Budget, file: file, line: line)

        let unplanned = try XCTUnwrap(unplannedService.find(byID: scenario.unplannedExpenseID), file: file, line: line)
        let unplannedCategory = unplanned.value(forKey: "expenseCategory") as? ExpenseCategory
        XCTAssertEqual(entityID(from: unplannedCategory), scenario.categoryID, file: file, line: line)
        let unplannedCard = unplanned.value(forKey: "card") as? Card
        XCTAssertEqual(entityID(from: unplannedCard), scenario.cardID, file: file, line: line)

        let incomesInRange = try incomeService.fetchIncomes(in: scenario.range)
        XCTAssertEqual(Set(entityIDs(from: incomesInRange)),
                       Set([scenario.plannedIncomeID, scenario.actualIncomeID]),
                       file: file,
                       line: line)
    }

    private func assertCRUDUpdates(_ scenario: ScenarioData,
                                   file: StaticString = #file,
                                   line: UInt = #line) throws {
        let category = try XCTUnwrap(categoryService.findCategory(byID: scenario.categoryID), file: file, line: line)
        try categoryService.updateCategory(category, name: "Updated Category", color: "#AABBCC")

        let updatedCategory = try categoryService.findCategory(byID: scenario.categoryID)
        XCTAssertEqual(updatedCategory?.name, "Updated Category", file: file, line: line)
        XCTAssertEqual(updatedCategory?.color, "#AABBCC", file: file, line: line)

        let planned = try XCTUnwrap(plannedService.find(byID: scenario.plannedExpenseID), file: file, line: line)
        try plannedService.update(planned, plannedAmount: 99, actualAmount: 88)

        let updatedPlanned = try plannedService.find(byID: scenario.plannedExpenseID)
        XCTAssertEqual(updatedPlanned?.plannedAmount, 99, file: file, line: line)
        XCTAssertEqual(updatedPlanned?.actualAmount, 88, file: file, line: line)

        let income = try XCTUnwrap(incomeService.findIncome(byID: scenario.actualIncomeID), file: file, line: line)
        try incomeService.updateIncome(income, scope: .instance, amount: 1550, isPlanned: true)

        let updatedIncome = try incomeService.findIncome(byID: scenario.actualIncomeID)
        XCTAssertEqual(updatedIncome?.amount, 1550, file: file, line: line)
        XCTAssertEqual(updatedIncome?.isPlanned, true, file: file, line: line)
    }

    private func assertDeleteSemantics(_ scenario: ScenarioData,
                                       file: StaticString = #file,
                                       line: UInt = #line) throws {
        let budget = try XCTUnwrap(budgetService.findBudget(byID: scenario.budgetID), file: file, line: line)
        try budgetService.deleteBudget(budget)

        XCTAssertNil(try budgetService.findBudget(byID: scenario.budgetID), file: file, line: line)

        let plannedAfterBudgetDelete = try plannedService.find(byID: scenario.plannedExpenseID)
        XCTAssertNotNil(plannedAfterBudgetDelete, file: file, line: line)
        XCTAssertNil(plannedAfterBudgetDelete?.value(forKey: "budget") as? Budget, file: file, line: line)

        XCTAssertNotNil(try plannedService.find(byID: scenario.plannedTemplateID), file: file, line: line)
        XCTAssertNotNil(try unplannedService.find(byID: scenario.unplannedExpenseID), file: file, line: line)
        XCTAssertNotNil(try incomeService.findIncome(byID: scenario.plannedIncomeID), file: file, line: line)
        XCTAssertNotNil(try incomeService.findIncome(byID: scenario.actualIncomeID), file: file, line: line)
        XCTAssertNotNil(try cardService.findCard(byID: scenario.cardID), file: file, line: line)
        XCTAssertNotNil(try categoryService.findCategory(byID: scenario.categoryID), file: file, line: line)

        let category = try XCTUnwrap(categoryService.findCategory(byID: scenario.categoryID), file: file, line: line)
        try categoryService.deleteCategory(category)

        XCTAssertNil(try categoryService.findCategory(byID: scenario.categoryID), file: file, line: line)
        XCTAssertNil(try plannedService.find(byID: scenario.plannedExpenseID), file: file, line: line)
        XCTAssertNil(try unplannedService.find(byID: scenario.unplannedExpenseID), file: file, line: line)
        XCTAssertNotNil(try plannedService.find(byID: scenario.plannedTemplateID), file: file, line: line)
        XCTAssertNotNil(try cardService.findCard(byID: scenario.cardID), file: file, line: line)
        XCTAssertNotNil(try incomeService.findIncome(byID: scenario.plannedIncomeID), file: file, line: line)
        XCTAssertNotNil(try incomeService.findIncome(byID: scenario.actualIncomeID), file: file, line: line)
    }

    // MARK: - Helpers

    private func withActiveWorkspaceID<T>(_ id: UUID, perform: () throws -> T) rethrows -> T {
        let original = UserDefaults.standard.string(forKey: workspaceDefaultsKey)
        UserDefaults.standard.set(id.uuidString, forKey: workspaceDefaultsKey)
        defer {
            if let original {
                UserDefaults.standard.set(original, forKey: workspaceDefaultsKey)
            } else {
                UserDefaults.standard.removeObject(forKey: workspaceDefaultsKey)
            }
        }
        return try perform()
    }

    private func setEntityID(_ object: NSManagedObject, id: UUID) throws {
        object.setValue(id, forKey: "id")
        try context.save()
    }

    private func entityID(from object: NSManagedObject?) -> UUID? {
        object?.value(forKey: "id") as? UUID
    }

    private func entityIDs(from objects: [NSManagedObject]) -> [UUID] {
        objects.compactMap { $0.value(forKey: "id") as? UUID }
    }

    private func offsetDate(from base: Date, days: Int, hour: Int) -> Date {
        let shifted = calendar.date(byAdding: .day, value: days, to: base) ?? base
        return calendar.date(bySettingHour: hour, minute: 0, second: 0, of: shifted) ?? shifted
    }

    private func makeDate(year: Int, month: Int, day: Int) -> Date {
        let components = DateComponents(
            calendar: calendar,
            timeZone: calendar.timeZone,
            year: year,
            month: month,
            day: day
        )
        return calendar.date(from: components) ?? Date()
    }
}

import XCTest
import CoreData
@testable import Offshore

final class PlannedExpenseServiceTests: XCTestCase {
    private let workspaceDefaultsKey = AppSettingsKeys.activeWorkspaceID.rawValue

    private var stack: TestCoreDataStack!
    private var service: PlannedExpenseService!
    private var context: NSManagedObjectContext!
    private var originalWorkspaceID: String?

    override func setUpWithError() throws {
        try super.setUpWithError()
        originalWorkspaceID = UserDefaults.standard.string(forKey: workspaceDefaultsKey)
        UserDefaults.standard.removeObject(forKey: workspaceDefaultsKey)

        stack = try TestCoreDataStack()
        service = PlannedExpenseService(stack: stack)
        context = stack.container.viewContext
    }

    override func tearDownWithError() throws {
        if let originalWorkspaceID {
            UserDefaults.standard.set(originalWorkspaceID, forKey: workspaceDefaultsKey)
        } else {
            UserDefaults.standard.removeObject(forKey: workspaceDefaultsKey)
        }
        context = nil
        service = nil
        stack = nil
        try super.tearDownWithError()
    }

    func testFetchAll_sortedByDateAscending_defaultTrue() throws {
        let budget = try makeBudget()
        let dateA = Date(timeIntervalSince1970: 100)
        let dateB = Date(timeIntervalSince1970: 200)
        let dateC = Date(timeIntervalSince1970: 150)

        _ = try makePlannedExpense(budget: budget, date: dateB, plannedAmount: 20, actualAmount: 10)
        _ = try makePlannedExpense(budget: budget, date: dateA, plannedAmount: 30, actualAmount: 15)
        _ = try makePlannedExpense(budget: budget, date: dateC, plannedAmount: 10, actualAmount: 5)

        let results = try service.fetchAll()
        let dates = results.compactMap { $0.transactionDate }
        XCTAssertEqual(dates, [dateA, dateC, dateB])
    }

    func testFindByID_returnsInsertedExpense() throws {
        let budget = try makeBudget()
        let id = UUID()
        _ = try makePlannedExpense(budget: budget, id: id, date: Date(), plannedAmount: 10, actualAmount: 2)

        let found = try service.find(byID: id)
        XCTAssertNotNil(found)
        XCTAssertEqual(found?.value(forKey: "id") as? UUID, id)
    }

    func testFindByID_returnsNilForUnknownID() throws {
        _ = try makeBudget()
        let found = try service.find(byID: UUID())
        XCTAssertNil(found)
    }

    func testFetchForBudget_returnsOnlyMatchingBudgetExpenses() throws {
        let budgetA = try makeBudget(id: UUID())
        let budgetB = try makeBudget(id: UUID())

        let expA1 = try makePlannedExpense(budget: budgetA, date: Date(), plannedAmount: 10, actualAmount: 1)
        let expA2 = try makePlannedExpense(budget: budgetA, date: Date().addingTimeInterval(10), plannedAmount: 20, actualAmount: 2)
        _ = try makePlannedExpense(budget: budgetB, date: Date().addingTimeInterval(20), plannedAmount: 30, actualAmount: 3)

        let results = try service.fetchForBudget(budgetAID(from: budgetA))
        let ids = results.compactMap { $0.value(forKey: "id") as? UUID }

        XCTAssertEqual(Set(ids), Set([
            expA1.value(forKey: "id") as? UUID,
            expA2.value(forKey: "id") as? UUID
        ].compactMap { $0 }))
    }

    func testFetchAll_inDateInterval_inclusiveBoundaries() throws {
        let budget = try makeBudget()
        let start = Date(timeIntervalSince1970: 100)
        let end = Date(timeIntervalSince1970: 200)
        let inside = Date(timeIntervalSince1970: 150)
        let outside = Date(timeIntervalSince1970: 250)

        let expStart = try makePlannedExpense(budget: budget, date: start, plannedAmount: 5, actualAmount: 1)
        let expEnd = try makePlannedExpense(budget: budget, date: end, plannedAmount: 6, actualAmount: 2)
        _ = try makePlannedExpense(budget: budget, date: inside, plannedAmount: 7, actualAmount: 3)
        _ = try makePlannedExpense(budget: budget, date: outside, plannedAmount: 8, actualAmount: 4)

        let results = try service.fetchAll(in: DateInterval(start: start, end: end))
        let ids = results.compactMap { $0.value(forKey: "id") as? UUID }
        let expStartID = expStart.value(forKey: "id") as? UUID
        let expEndID = expEnd.value(forKey: "id") as? UUID

        XCTAssertNotNil(expStartID)
        XCTAssertNotNil(expEndID)
        if let expStartID { XCTAssertTrue(ids.contains(expStartID)) }
        if let expEndID { XCTAssertTrue(ids.contains(expEndID)) }
        XCTAssertEqual(results.count, 3)
    }

    func testDeleteExpense_removesFromStore() throws {
        let budget = try makeBudget()
        let id = UUID()
        let expense = try makePlannedExpense(budget: budget, id: id, date: Date(), plannedAmount: 10, actualAmount: 2)

        try service.delete(expense)
        let found = try service.find(byID: id)
        XCTAssertNil(found)
    }

    func testTemplate_createGlobalTemplate_thenInstantiateIntoBudget_ifAPIsExist() throws {
        let budget = try makeBudget()
        let template = try service.createGlobalTemplate(
            titleOrDescription: "Rent",
            plannedAmount: 500,
            actualAmount: 0,
            defaultTransactionDate: Date(timeIntervalSince1970: 100)
        )

        let instanceDate = Date(timeIntervalSince1970: 200)
        let instance = try service.instantiateTemplate(template, intoBudgetID: budgetAID(from: budget), on: instanceDate)

        XCTAssertFalse(instance.isGlobal)
        XCTAssertEqual(instance.globalTemplateID, template.value(forKey: "id") as? UUID)
        XCTAssertEqual(instance.transactionDate, instanceDate)
        XCTAssertEqual(instance.value(forKey: "descriptionText") as? String, "Rent")
        XCTAssertEqual(instance.value(forKey: "budget") as? Budget, budget)
    }

    func testWorkspacePredicate_appliesWhenActiveWorkspaceIDSet_ifWorkspaceServiceUsed() throws {
        let workspaceA = UUID()
        let workspaceB = UUID()
        UserDefaults.standard.set(workspaceA.uuidString, forKey: workspaceDefaultsKey)

        let budget = try makeBudget()
        _ = try makePlannedExpense(budget: budget, date: Date(), plannedAmount: 10, actualAmount: 1, workspaceID: workspaceA)
        _ = try makePlannedExpense(budget: budget, date: Date().addingTimeInterval(10), plannedAmount: 20, actualAmount: 2, workspaceID: workspaceB)

        let results = try service.fetchAll()
        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results.first?.value(forKey: "workspaceID") as? UUID, workspaceA)
    }

    func testCreatePlannedExpense_appliesWorkspaceIDWhenActiveWorkspaceSet() throws {
        let workspaceA = UUID()
        UserDefaults.standard.set(workspaceA.uuidString, forKey: workspaceDefaultsKey)

        let budget = try makeBudget(workspaceID: workspaceA)
        let expense = try service.create(
            inBudgetID: budgetAID(from: budget),
            titleOrDescription: "Utilities",
            plannedAmount: 40,
            actualAmount: 0,
            transactionDate: Date()
        )

        let appliedID = expense.value(forKey: "workspaceID") as? UUID
        XCTAssertEqual(appliedID, workspaceA)
    }

    // MARK: - Helpers
    private func budgetAID(from budget: Budget) -> UUID {
        if let id = budget.value(forKey: "id") as? UUID { return id }
        let fallback = UUID()
        budget.setValue(fallback, forKey: "id")
        try? context.save()
        return fallback
    }

    private func makeBudget(id: UUID = UUID(), workspaceID: UUID? = nil) throws -> Budget {
        let budget = NSEntityDescription.insertNewObject(
            forEntityName: String(describing: Budget.self),
            into: context
        ) as! Budget
        budget.setValue(id, forKey: "id")
        budget.setValue("Test Budget", forKey: "name")
        if let workspaceID {
            budget.setValue(workspaceID, forKey: "workspaceID")
        }
        try context.save()
        return budget
    }

    private func makePlannedExpense(
        budget: Budget,
        id: UUID = UUID(),
        date: Date,
        plannedAmount: Double,
        actualAmount: Double,
        isGlobal: Bool = false,
        globalTemplateID: UUID? = nil,
        workspaceID: UUID? = nil
    ) throws -> PlannedExpense {
        let expense = NSEntityDescription.insertNewObject(
            forEntityName: String(describing: PlannedExpense.self),
            into: context
        ) as! PlannedExpense
        expense.setValue(id, forKey: "id")
        expense.setValue("Test", forKey: "descriptionText")
        expense.plannedAmount = plannedAmount
        expense.actualAmount = actualAmount
        expense.transactionDate = date
        expense.isGlobal = isGlobal
        expense.globalTemplateID = globalTemplateID
        expense.setValue(budget, forKey: "budget")
        if let workspaceID {
            expense.setValue(workspaceID, forKey: "workspaceID")
        }
        try context.save()
        return expense
    }
}

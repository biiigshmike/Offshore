import XCTest
import CoreData
@testable import Offshore

final class CoreDataMergeAndWipeTests: XCTestCase {
    private let workspaceDefaultsKey = AppSettingsKeys.activeWorkspaceID.rawValue

    private var stack: TestCoreDataStack!
    private var context: NSManagedObjectContext!
    private var repo: CoreDataRepository<ExpenseCategory>!
    private var coreDataService: CoreDataService!
    private var observerToken: NSObjectProtocol?
    private var originalWorkspaceID: String?
    private var workspaceID: UUID!
    private var storeURL: URL?

    override func setUpWithError() throws {
        try super.setUpWithError()

        originalWorkspaceID = UserDefaults.standard.string(forKey: workspaceDefaultsKey)
        workspaceID = UUID()
        UserDefaults.standard.set(workspaceID.uuidString, forKey: workspaceDefaultsKey)

        storeURL = makeTemporaryStoreURL()
        stack = try TestCoreDataStack(storeType: NSSQLiteStoreType, storeURL: storeURL)
        context = stack.container.viewContext
        repo = CoreDataRepository<ExpenseCategory>(stack: stack)
        coreDataService = CoreDataService(
            testContainer: stack.container,
            notificationCenter: NotificationCenterAdapter.shared
        )
    }

    override func tearDownWithError() throws {
        if let observerToken {
            NotificationCenter.default.removeObserver(observerToken)
        }

        if let originalWorkspaceID {
            UserDefaults.standard.set(originalWorkspaceID, forKey: workspaceDefaultsKey)
        } else {
            UserDefaults.standard.removeObject(forKey: workspaceDefaultsKey)
        }

        coreDataService = nil
        repo = nil
        context = nil
        stack = nil
        workspaceID = nil
        storeURL = nil

        try super.tearDownWithError()
    }

    func testBatchDelete_mergeChanges_reflectsInViewContextAndRegisteredObjects() throws {
        let firstCategory = try makeCategory(id: UUID(), name: "A")
        _ = try makeCategory(id: UUID(), name: "B")

        let request = NSFetchRequest<ExpenseCategory>(entityName: "ExpenseCategory")
        let fetched = try context.fetch(request)
        XCTAssertEqual(fetched.count, 2)
        XCTAssertTrue(fetched.contains { $0.objectID == firstCategory.objectID })

        try repo.deleteAll()
        context.processPendingChanges()

        let remaining = try context.fetch(request)
        XCTAssertEqual(remaining.count, 0)
        XCTAssertTrue(firstCategory.isDeleted)
        let nonDeleted = context.registeredObjects.contains { object in
            object.entity.name == "ExpenseCategory" && !object.isDeleted
        }
        XCTAssertFalse(nonDeleted)
    }

    func testWipeAllData_mergesDeletes_resetsContextAndPostsChange() throws {
        let category = try makeCategory(id: UUID(), name: "Temp")
        let budget = try makeBudget(id: UUID(), name: "Budget")
        let card = try makeCard(id: UUID(), name: "Card")
        let planned = try makePlannedExpense(id: UUID(), budget: budget, card: card, category: category)
        let unplanned = try makeUnplannedExpense(id: UUID(), card: card, category: category)
        let income = try makeIncome(id: UUID(), source: "Work")

        let expectation = XCTestExpectation(description: "dataStoreDidChange posted on wipe")
        observerToken = NotificationCenter.default.addObserver(
            forName: .dataStoreDidChange,
            object: nil,
            queue: .main
        ) { _ in
            expectation.fulfill()
        }

        try coreDataService.wipeAllData()

        wait(for: [expectation], timeout: 1.0)
        XCTAssertEqual(try fetchCount(entityName: "ExpenseCategory"), 0)
        XCTAssertEqual(try fetchCount(entityName: "Budget"), 0)
        XCTAssertEqual(try fetchCount(entityName: "Card"), 0)
        XCTAssertEqual(try fetchCount(entityName: "PlannedExpense"), 0)
        XCTAssertEqual(try fetchCount(entityName: "UnplannedExpense"), 0)
        XCTAssertEqual(try fetchCount(entityName: "Income"), 0)
        XCTAssertTrue(context.registeredObjects.isEmpty)
        XCTAssertFalse(context.hasChanges)
        XCTAssertNoThrow(_ = category.objectID)
        XCTAssertNoThrow(_ = planned.objectID)
        XCTAssertNoThrow(_ = unplanned.objectID)
        XCTAssertNoThrow(_ = budget.objectID)
        XCTAssertNoThrow(_ = card.objectID)
        XCTAssertNoThrow(_ = income.objectID)
    }

    // MARK: - Helpers

    private func makeCategory(id: UUID, name: String) throws -> ExpenseCategory {
        let category = NSEntityDescription.insertNewObject(
            forEntityName: String(describing: ExpenseCategory.self),
            into: context
        ) as! ExpenseCategory
        category.setValue(id, forKey: "id")
        category.name = name
        category.color = "#123456"
        category.setValue(workspaceID, forKey: "workspaceID")
        try context.save()
        return category
    }

    private func makeBudget(id: UUID, name: String) throws -> Budget {
        let budget = NSEntityDescription.insertNewObject(
            forEntityName: String(describing: Budget.self),
            into: context
        ) as! Budget
        budget.setValue(id, forKey: "id")
        budget.setValue(name, forKey: "name")
        budget.setValue(workspaceID, forKey: "workspaceID")
        try context.save()
        return budget
    }

    private func makeCard(id: UUID, name: String) throws -> Card {
        let card = NSEntityDescription.insertNewObject(
            forEntityName: String(describing: Card.self),
            into: context
        ) as! Card
        card.setValue(id, forKey: "id")
        card.setValue(name, forKey: "name")
        card.setValue(workspaceID, forKey: "workspaceID")
        try context.save()
        return card
    }

    private func makePlannedExpense(id: UUID,
                                    budget: Budget,
                                    card: Card,
                                    category: ExpenseCategory) throws -> PlannedExpense {
        let expense = NSEntityDescription.insertNewObject(
            forEntityName: String(describing: PlannedExpense.self),
            into: context
        ) as! PlannedExpense
        expense.setValue(id, forKey: "id")
        expense.setValue("Planned", forKey: "descriptionText")
        expense.plannedAmount = 10
        expense.actualAmount = 0
        expense.transactionDate = Date()
        expense.isGlobal = false
        expense.setValue(budget, forKey: "budget")
        expense.setValue(card, forKey: "card")
        expense.setValue(category, forKey: "expenseCategory")
        expense.setValue(workspaceID, forKey: "workspaceID")
        try context.save()
        return expense
    }

    private func makeUnplannedExpense(id: UUID,
                                      card: Card,
                                      category: ExpenseCategory) throws -> UnplannedExpense {
        let expense = NSEntityDescription.insertNewObject(
            forEntityName: String(describing: UnplannedExpense.self),
            into: context
        ) as! UnplannedExpense
        expense.setValue(id, forKey: "id")
        expense.setValue("Unplanned", forKey: "descriptionText")
        expense.amount = 5
        expense.transactionDate = Date()
        expense.setValue(card, forKey: "card")
        expense.setValue(category, forKey: "expenseCategory")
        expense.setValue(workspaceID, forKey: "workspaceID")
        try context.save()
        return expense
    }

    private func makeIncome(id: UUID, source: String) throws -> Income {
        let income = NSEntityDescription.insertNewObject(
            forEntityName: String(describing: Income.self),
            into: context
        ) as! Income
        income.setValue(id, forKey: "id")
        income.setValue(source, forKey: "source")
        income.amount = 50
        income.date = Date()
        income.setValue(workspaceID, forKey: "workspaceID")
        try context.save()
        return income
    }

    private func fetchCount(entityName: String) throws -> Int {
        let request = NSFetchRequest<NSNumber>(entityName: entityName)
        request.resultType = .countResultType
        return try context.fetch(request).first?.intValue ?? 0
    }

    private func makeTemporaryStoreURL() -> URL {
        let filename = "test-\(UUID().uuidString).sqlite"
        return FileManager.default.temporaryDirectory.appendingPathComponent(filename)
    }
}

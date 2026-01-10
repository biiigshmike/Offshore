import XCTest
import CoreData
@testable import Offshore

final class CategoryDeletionCharacterizationTests: XCTestCase {
    private let workspaceDefaultsKey = AppSettingsKeys.activeWorkspaceID.rawValue

    private var stack: TestCoreDataStack!
    private var context: NSManagedObjectContext!
    private var originalWorkspaceID: String?
    private var workspaceID: UUID!

    override func setUpWithError() throws {
        try super.setUpWithError()
        originalWorkspaceID = UserDefaults.standard.string(forKey: workspaceDefaultsKey)
        workspaceID = UUID()
        UserDefaults.standard.set(workspaceID.uuidString, forKey: workspaceDefaultsKey)

        stack = try TestCoreDataStack()
        context = stack.container.viewContext
    }

    override func tearDownWithError() throws {
        if let originalWorkspaceID {
            UserDefaults.standard.set(originalWorkspaceID, forKey: workspaceDefaultsKey)
        } else {
            UserDefaults.standard.removeObject(forKey: workspaceDefaultsKey)
        }

        context = nil
        stack = nil
        workspaceID = nil

        try super.tearDownWithError()
    }

    func testDeleteCategory_withLinkedPlannedAndUnplanned_viewPath_characterization() throws {
        let categoryID = UUID()
        let plannedID = UUID()
        let unplannedID = UUID()

        let category = try makeCategory(id: categoryID, name: "Food", color: "#00AAFF")
        let budget = try makeBudget(id: UUID(), name: "Test Budget")
        _ = try makePlannedExpense(id: plannedID, budget: budget, category: category)
        _ = try makeUnplannedExpense(id: unplannedID, category: category)

        deleteCategoryAndLinkedExpensesAsViewDoes(category)

        // Characterized current behavior: the view-level deletion removes the category and its linked expenses.
        XCTAssertNil(try fetchCategory(by: categoryID))
        XCTAssertNil(try fetchPlannedExpense(by: plannedID))
        XCTAssertNil(try fetchUnplannedExpense(by: unplannedID))
        XCTAssertEqual(try fetchAllCategories().count, 0)
        XCTAssertEqual(try fetchAllPlannedExpenses().count, 0)
        XCTAssertEqual(try fetchAllUnplannedExpenses().count, 0)
    }

    // MARK: - Helpers

    private func makeCategory(id: UUID, name: String, color: String) throws -> ExpenseCategory {
        let category = NSEntityDescription.insertNewObject(
            forEntityName: String(describing: ExpenseCategory.self),
            into: context
        ) as! ExpenseCategory
        category.setValue(id, forKey: "id")
        category.name = name
        category.color = color
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

    private func makePlannedExpense(id: UUID, budget: Budget, category: ExpenseCategory) throws -> PlannedExpense {
        let expense = NSEntityDescription.insertNewObject(
            forEntityName: String(describing: PlannedExpense.self),
            into: context
        ) as! PlannedExpense
        expense.setValue(id, forKey: "id")
        expense.setValue("Test Planned", forKey: "descriptionText")
        expense.plannedAmount = 10
        expense.actualAmount = 0
        expense.transactionDate = Date()
        expense.isGlobal = false
        expense.setValue(budget, forKey: "budget")
        expense.setValue(category, forKey: "expenseCategory")
        expense.setValue(workspaceID, forKey: "workspaceID")
        try context.save()
        return expense
    }

    private func makeUnplannedExpense(id: UUID, category: ExpenseCategory) throws -> UnplannedExpense {
        let expense = NSEntityDescription.insertNewObject(
            forEntityName: String(describing: UnplannedExpense.self),
            into: context
        ) as! UnplannedExpense
        expense.setValue(id, forKey: "id")
        expense.setValue("Test Unplanned", forKey: "descriptionText")
        expense.amount = 5
        expense.transactionDate = Date()
        expense.setValue(category, forKey: "expenseCategory")
        expense.setValue(workspaceID, forKey: "workspaceID")
        try context.save()
        return expense
    }

    private func fetchCategory(by id: UUID) throws -> ExpenseCategory? {
        let request = NSFetchRequest<ExpenseCategory>(entityName: "ExpenseCategory")
        request.fetchLimit = 1
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        return try context.fetch(request).first
    }

    private func fetchPlannedExpense(by id: UUID) throws -> PlannedExpense? {
        let request = NSFetchRequest<PlannedExpense>(entityName: "PlannedExpense")
        request.fetchLimit = 1
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        return try context.fetch(request).first
    }

    private func fetchUnplannedExpense(by id: UUID) throws -> UnplannedExpense? {
        let request = NSFetchRequest<UnplannedExpense>(entityName: "UnplannedExpense")
        request.fetchLimit = 1
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        return try context.fetch(request).first
    }

    private func fetchAllCategories() throws -> [ExpenseCategory] {
        let request = NSFetchRequest<ExpenseCategory>(entityName: "ExpenseCategory")
        return try context.fetch(request)
    }

    private func fetchAllPlannedExpenses() throws -> [PlannedExpense] {
        let request = NSFetchRequest<PlannedExpense>(entityName: "PlannedExpense")
        return try context.fetch(request)
    }

    private func fetchAllUnplannedExpenses() throws -> [UnplannedExpense] {
        let request = NSFetchRequest<UnplannedExpense>(entityName: "UnplannedExpense")
        return try context.fetch(request)
    }

    private func deleteCategoryAndLinkedExpensesAsViewDoes(_ category: ExpenseCategory) {
        let plannedRequest = NSFetchRequest<PlannedExpense>(entityName: "PlannedExpense")
        plannedRequest.predicate = NSPredicate(format: "expenseCategory == %@", category)
        let planned = (try? context.fetch(plannedRequest)) ?? []

        let unplannedRequest = NSFetchRequest<UnplannedExpense>(entityName: "UnplannedExpense")
        unplannedRequest.predicate = NSPredicate(format: "expenseCategory == %@", category)
        let unplanned = (try? context.fetch(unplannedRequest)) ?? []

        planned.forEach { context.delete($0) }
        unplanned.forEach { context.delete($0) }
        context.delete(category)
        try? context.save()
    }
}

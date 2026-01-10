import XCTest
import CoreData
@testable import Offshore

final class ExpenseCategoryServiceTests: XCTestCase {
    private let workspaceDefaultsKey = AppSettingsKeys.activeWorkspaceID.rawValue

    private var stack: TestCoreDataStack!
    private var service: ExpenseCategoryService!
    private var context: NSManagedObjectContext!

    private var originalWorkspaceID: String?
    private var workspaceID: UUID!

    override func setUpWithError() throws {
        try super.setUpWithError()

        originalWorkspaceID = UserDefaults.standard.string(forKey: workspaceDefaultsKey)

        workspaceID = UUID()
        UserDefaults.standard.set(workspaceID.uuidString, forKey: workspaceDefaultsKey)

        stack = try TestCoreDataStack()
        service = ExpenseCategoryService(stack: stack)
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

    // MARK: - Existing baseline tests (kept)

    func testCreateCategory_persistsAndFetches() throws {
        _ = try service.addCategory(name: "Food", color: "#FF0000")
        let results = try service.fetchAllCategories(sortedByName: true)

        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results.first?.name, "Food")
        XCTAssertEqual(results.first?.color, "#FF0000")
    }

    func testFetchAll_sortedByNameAscending() throws {
        _ = try service.addCategory(name: "b", color: "#111111")
        _ = try service.addCategory(name: "A", color: "#222222")
        _ = try service.addCategory(name: "c", color: "#333333")

        let results = try service.fetchAllCategories(sortedByName: true)
        let names = results.compactMap { $0.name }

        XCTAssertEqual(names, ["A", "b", "c"])
    }

    func testWorkspacePredicate_filtersCategoriesToActiveWorkspace() throws {
        _ = try service.addCategory(name: "Active", color: "#AAAAAA")
        let otherID = UUID()
        _ = try makeCategory(id: UUID(), name: "Other", color: "#BBBBBB", workspaceID: otherID)

        let results = try service.fetchAllCategories(sortedByName: true)
        let names = results.compactMap { $0.name }

        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(names, ["Active"])
    }

    func testRenameOrUpdateCategory_persists() throws {
        let category = try service.addCategory(name: "Old", color: "#000000")
        try service.updateCategory(category, name: "New", color: "#FFFFFF")

        let categoryID = categoryID(for: category)
        XCTAssertNotNil(categoryID)

        let found = try service.findCategory(byID: categoryID!)
        XCTAssertEqual(found?.name, "New")
        XCTAssertEqual(found?.color, "#FFFFFF")
    }

    func testDeleteCategory_removesCategory() throws {
        let category = try service.addCategory(name: "Temp", color: "#123456")
        try service.deleteCategory(category)

        let results = try service.fetchAllCategories(sortedByName: true)
        XCTAssertEqual(results.count, 0)
    }

    // MARK: - New high-value characterization tests
    func testAddCategory_appliesWorkspaceIDWhenActiveWorkspaceSet() throws {
        let category = try service.addCategory(name: "Bills", color: "#123123")
        let appliedID = category.value(forKey: "workspaceID") as? UUID
        XCTAssertEqual(appliedID, workspaceID)
    }

    func testAddCategory_ensureUniqueName_returnsExisting_caseInsensitive() throws {
        let first = try service.addCategory(name: "Food", color: "#111111", ensureUniqueName: true)
        let second = try service.addCategory(name: "food", color: "#222222", ensureUniqueName: true)

        let firstID = categoryID(for: first)
        let secondID = categoryID(for: second)
        XCTAssertNotNil(firstID)
        XCTAssertNotNil(secondID)
        XCTAssertEqual(firstID, secondID, "ensureUniqueName should return the existing category for duplicate names")

        let results = try service.fetchAllCategories(sortedByName: true)
        XCTAssertEqual(results.count, 1)
        // Note: color is not updated when returning existing; characterize current behavior:
        XCTAssertEqual(results.first?.color, "#111111")
    }

    func testAddCategory_allowDuplicates_whenEnsureUniqueNameFalse() throws {
        _ = try service.addCategory(name: "Food", color: "#111111", ensureUniqueName: true)
        _ = try service.addCategory(name: "Food", color: "#222222", ensureUniqueName: false)

        let results = try service.fetchAllCategories(sortedByName: true)
        XCTAssertEqual(results.count, 2)
    }

    func testFindCategoryNamed_isWorkspaceScoped() throws {
        // Active workspace
        let active = try service.addCategory(name: "Food", color: "#AAAAAA")
        let activeID = categoryID(for: active)
        XCTAssertNotNil(activeID)

        // Other workspace: manually insert same name
        let otherWorkspaceID = UUID()
        let otherID = UUID()
        _ = try makeCategory(id: otherID, name: "Food", color: "#BBBBBB", workspaceID: otherWorkspaceID)

        // findCategory(named:) should respect active workspace scoping
        let found = try service.findCategory(named: "Food")
        XCTAssertNotNil(found)
        XCTAssertEqual(categoryID(for: found!), activeID)
    }

    func testFindCategoryByID_returnsNilWhenIDIsInDifferentWorkspace() throws {
        let otherWorkspaceID = UUID()
        let foreignID = UUID()
        _ = try makeCategory(id: foreignID, name: "Foreign", color: "#CCCCCC", workspaceID: otherWorkspaceID)

        // Active workspace is set to workspaceID; find by foreign ID should return nil
        let found = try service.findCategory(byID: foreignID)
        XCTAssertNil(found)
    }

    // MARK: - Helpers

    private func categoryID(for category: ExpenseCategory) -> UUID? {
        // Prefer the typed property if generated; fall back to KVC for schema drift.
        if let id = category.id { return id }
        return category.value(forKey: "id") as? UUID
    }

    private func makeCategory(id: UUID = UUID(), name: String, color: String, workspaceID: UUID) throws -> ExpenseCategory {
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

}

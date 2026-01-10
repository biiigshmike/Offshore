import XCTest
import CoreData
@testable import Offshore

final class CoreDataNotificationsTests: XCTestCase {
    private let workspaceDefaultsKey = AppSettingsKeys.activeWorkspaceID.rawValue

    private var stack: TestCoreDataStack!
    private var categoryService: ExpenseCategoryService!
    private var coreDataService: CoreDataService!
    private var observerToken: NSObjectProtocol?
    private var originalWorkspaceID: String?

    override func setUpWithError() throws {
        try super.setUpWithError()

        originalWorkspaceID = UserDefaults.standard.string(forKey: workspaceDefaultsKey)
        UserDefaults.standard.set(UUID().uuidString, forKey: workspaceDefaultsKey)

        stack = try TestCoreDataStack()
        categoryService = ExpenseCategoryService(stack: stack)
        coreDataService = CoreDataService(
            testContainer: stack.container,
            notificationCenter: NotificationCenterAdapter.shared
        )
        coreDataService.enableChangeNotificationsForTests()
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
        categoryService = nil
        stack = nil

        try super.tearDownWithError()
    }

    func testCreateCategory_postsDataStoreDidChangeNotification() throws {
        let expectation = XCTestExpectation(description: "dataStoreDidChange posted on create")
        var notificationCount = 0
        observerToken = NotificationCenter.default.addObserver(
            forName: .dataStoreDidChange,
            object: nil,
            queue: .main
        ) { _ in
            notificationCount += 1
            expectation.fulfill()
        }

        _ = try categoryService.addCategory(name: "Notify", color: "#121212")

        wait(for: [expectation], timeout: 1.0)
        XCTAssertGreaterThanOrEqual(notificationCount, 1)
    }

    func testDeleteCategory_postsDataStoreDidChangeNotification() throws {
        let category = try categoryService.addCategory(name: "Delete", color: "#222222")

        let expectation = XCTestExpectation(description: "dataStoreDidChange posted on delete")
        var notificationCount = 0
        observerToken = NotificationCenter.default.addObserver(
            forName: .dataStoreDidChange,
            object: nil,
            queue: .main
        ) { _ in
            notificationCount += 1
            expectation.fulfill()
        }

        try categoryService.deleteCategory(category)

        wait(for: [expectation], timeout: 1.0)
        XCTAssertGreaterThanOrEqual(notificationCount, 1)
    }
}

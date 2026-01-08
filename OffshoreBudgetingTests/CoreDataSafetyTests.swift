import XCTest
import CoreData
import Combine
@testable import Offshore

final class CoreDataMergeTests: XCTestCase {
    private var stack: TestCoreDataStack!
    private var context: NSManagedObjectContext!
    private var storeURL: URL?

    override func setUpWithError() throws {
        try super.setUpWithError()
        storeURL = makeTemporaryStoreURL()
        stack = try TestCoreDataStack(storeType: NSSQLiteStoreType, storeURL: storeURL)
        context = stack.container.viewContext
    }

    override func tearDownWithError() throws {
        context = nil
        stack = nil
        storeURL = nil
        try super.tearDownWithError()
    }

    func testBatchDelete_mergeChanges_reflectsInViewContext() throws {
        let repo = CoreDataRepository<ExpenseCategory>(stack: stack)
        _ = repo.create { cat in
            cat.setValue(UUID(), forKey: "id")
            cat.name = "A"
        }
        _ = repo.create { cat in
            cat.setValue(UUID(), forKey: "id")
            cat.name = "B"
        }
        try repo.saveIfNeeded()

        try repo.deleteAll()

        let request = NSFetchRequest<ExpenseCategory>(entityName: "ExpenseCategory")
        let remaining = try context.fetch(request)
        XCTAssertEqual(remaining.count, 0)
    }
}

final class CoreDataWipeTests: XCTestCase {
    private var stack: TestCoreDataStack!
    private var service: CoreDataService!
    private var context: NSManagedObjectContext!
    private var storeURL: URL?

    override func setUpWithError() throws {
        try super.setUpWithError()
        storeURL = makeTemporaryStoreURL()
        stack = try TestCoreDataStack(storeType: NSSQLiteStoreType, storeURL: storeURL)
        context = stack.container.viewContext
        service = CoreDataService(testContainer: stack.container)
    }

    override func tearDownWithError() throws {
        context = nil
        service = nil
        stack = nil
        storeURL = nil
        try super.tearDownWithError()
    }

    func testWipeAllData_mergesDeletes_andResetsContextSafely() throws {
        let category = NSEntityDescription.insertNewObject(
            forEntityName: String(describing: ExpenseCategory.self),
            into: context
        ) as! ExpenseCategory
        category.setValue(UUID(), forKey: "id")
        category.name = "Temp"

        let planned = NSEntityDescription.insertNewObject(
            forEntityName: String(describing: PlannedExpense.self),
            into: context
        ) as! PlannedExpense
        planned.setValue(UUID(), forKey: "id")
        planned.setValue("Temp Planned", forKey: "descriptionText")
        planned.plannedAmount = 5
        planned.actualAmount = 0
        planned.transactionDate = Date()
        planned.isGlobal = false

        try context.save()

        try service.wipeAllData()

        let categories = try context.fetch(NSFetchRequest<ExpenseCategory>(entityName: "ExpenseCategory"))
        let plannedExpenses = try context.fetch(NSFetchRequest<PlannedExpense>(entityName: "PlannedExpense"))

        XCTAssertEqual(categories.count, 0)
        XCTAssertEqual(plannedExpenses.count, 0)
        XCTAssertNoThrow(_ = category.objectID)
        XCTAssertNoThrow(_ = planned.objectID)
    }
}

@MainActor
final class CloudSyncGatingTests: XCTestCase {
    private var stack: TestCoreDataStack!
    private var service: CoreDataService!

    override func setUpWithError() throws {
        try super.setUpWithError()
        stack = try TestCoreDataStack()
        service = CoreDataService(testContainer: stack.container, cloudAvailabilityProvider: FakeCloudAvailabilityProvider(available: false))
    }

    override func tearDownWithError() throws {
        service = nil
        stack = nil
        try super.tearDownWithError()
    }

    func testCloudSyncPreference_disabled_staysLocal() {
        XCTAssertFalse(service.isCloudStoreActive)
        XCTAssertEqual(service.storeModeDescription, "Local")
        let description = service.container.persistentStoreDescriptions.first
        XCTAssertNil(description?.cloudKitContainerOptions)
    }

    func testCloudSyncPreference_enabled_butUnavailable_staysLocal() async {
        await service.applyCloudSyncPreferenceChange(enableSync: true)
        XCTAssertFalse(service.isCloudStoreActive)
        XCTAssertEqual(service.storeModeDescription, "Local")
        let description = service.container.persistentStoreDescriptions.first
        XCTAssertNil(description?.cloudKitContainerOptions)
    }
}

final class DataStoreNotificationTests: XCTestCase {
    private let workspaceDefaultsKey = AppSettingsKeys.activeWorkspaceID.rawValue

    private var stack: TestCoreDataStack!
    private var categoryService: ExpenseCategoryService!
    private var observerToken: NSObjectProtocol?
    private var originalWorkspaceID: String?
    private var coreDataService: CoreDataService!

    override func setUpWithError() throws {
        try super.setUpWithError()

        originalWorkspaceID = UserDefaults.standard.string(forKey: workspaceDefaultsKey)
        UserDefaults.standard.set(UUID().uuidString, forKey: workspaceDefaultsKey)

        stack = try TestCoreDataStack()
        categoryService = ExpenseCategoryService(stack: stack)
        coreDataService = CoreDataService(testContainer: stack.container, notificationCenter: NotificationCenterAdapter.shared)
        coreDataService.enableChangeNotificationsForTests()
    }

    override func tearDownWithError() throws {
        if let token = observerToken {
            NotificationCenter.default.removeObserver(token)
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

    func testDeleteCategory_postsDataStoreDidChangeNotification_characterization() throws {
        let category = try categoryService.addCategory(name: "Notify", color: "#121212")

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

private func makeTemporaryStoreURL() -> URL {
    let filename = "test-\(UUID().uuidString).sqlite"
    return FileManager.default.temporaryDirectory.appendingPathComponent(filename)
}

@MainActor
private final class FakeCloudAvailabilityProvider: CloudAvailabilityProviding {
    private let available: Bool
    private let subject: CurrentValueSubject<CloudAccountStatusProvider.Availability, Never>

    var isCloudAccountAvailable: Bool? { available }

    var availabilityPublisher: AnyPublisher<CloudAccountStatusProvider.Availability, Never> {
        subject.eraseToAnyPublisher()
    }

    init(available: Bool) {
        self.available = available
        self.subject = CurrentValueSubject(available ? .available : .unavailable)
    }

    func requestAccountStatusCheck(force: Bool) { }

    func resolveAvailability(forceRefresh: Bool) async -> Bool {
        available
    }

    func invalidateCache() { }
}

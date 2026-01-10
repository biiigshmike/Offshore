import XCTest
import Combine
@testable import Offshore

@MainActor
final class CloudSyncGatingTests: XCTestCase {
    private let workspaceDefaultsKey = AppSettingsKeys.activeWorkspaceID.rawValue
    private let cloudDefaultsKey = AppSettingsKeys.enableCloudSync.rawValue

    private var stack: TestCoreDataStack!
    private var service: CoreDataService!
    private var originalWorkspaceID: String?
    private var originalCloudSetting: Bool?

    override func setUpWithError() throws {
        try super.setUpWithError()
        originalWorkspaceID = UserDefaults.standard.string(forKey: workspaceDefaultsKey)
        originalCloudSetting = UserDefaults.standard.object(forKey: cloudDefaultsKey) as? Bool
        UserDefaults.standard.set(UUID().uuidString, forKey: workspaceDefaultsKey)
        UserDefaults.standard.set(false, forKey: cloudDefaultsKey)

        stack = try TestCoreDataStack()
        service = CoreDataService(
            testContainer: stack.container,
            cloudAvailabilityProvider: FakeCloudAvailabilityProvider(available: false)
        )
    }

    override func tearDownWithError() throws {
        if let originalWorkspaceID {
            UserDefaults.standard.set(originalWorkspaceID, forKey: workspaceDefaultsKey)
        } else {
            UserDefaults.standard.removeObject(forKey: workspaceDefaultsKey)
        }

        if let originalCloudSetting {
            UserDefaults.standard.set(originalCloudSetting, forKey: cloudDefaultsKey)
        } else {
            UserDefaults.standard.removeObject(forKey: cloudDefaultsKey)
        }

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
        UserDefaults.standard.set(true, forKey: cloudDefaultsKey)
        await service.applyCloudSyncPreferenceChange(enableSync: true)
        XCTAssertFalse(service.isCloudStoreActive)
        XCTAssertEqual(service.storeModeDescription, "Local")
        let description = service.container.persistentStoreDescriptions.first
        XCTAssertNil(description?.cloudKitContainerOptions)
    }
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

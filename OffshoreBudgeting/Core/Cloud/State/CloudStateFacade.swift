import Foundation

// MARK: - CloudStateFacade
/// Single façade for Cloud-related local state:
/// - Cloud sync enablement (user setting)
/// - App-level iCloud K/V flags
/// - A thin wrapper around `NSUbiquitousKeyValueStore`
enum CloudStateFacade {

    // MARK: Cloud Availability (Settings)
    static var isCloudSyncEnabled: Bool {
        UserDefaults.standard.bool(forKey: AppSettingsKeys.enableCloudSync.rawValue)
    }

    // MARK: Ubiquitous Key-Value Store
    private static var ubiquitousStore: NSUbiquitousKeyValueStore {
        NSUbiquitousKeyValueStore.default
    }

    static func bool(forKey key: String) -> Bool {
        ubiquitousStore.bool(forKey: key)
    }

    static func string(forKey key: String) -> String? {
        ubiquitousStore.string(forKey: key)
    }

    static func set(_ value: Any?, forKey key: String) {
        ubiquitousStore.set(value, forKey: key)
    }

    static func synchronize() {
        ubiquitousStore.synchronize()
    }

    // MARK: Cloud Flags
    enum Flags {
        private static let hasCloudDataKey = "hasCloudData"

        static func hasCloudData() -> Bool {
            CloudStateFacade.bool(forKey: hasCloudDataKey)
        }

        static func setHasCloudDataTrue() {
            if CloudStateFacade.bool(forKey: hasCloudDataKey) == true { return }
            CloudStateFacade.set(true, forKey: hasCloudDataKey)
            CloudStateFacade.synchronize()
        }

        static func clearHasCloudData() {
            CloudStateFacade.set(false, forKey: hasCloudDataKey)
            CloudStateFacade.synchronize()
        }
    }

    // MARK: Cloud Account Availability (Cached)
    @MainActor
    static var cloudAccountAvailability: CloudAccountStatusProvider.Availability {
        CloudAccountStatusProvider.shared.availability
    }

    @MainActor
    static func requestCloudAccountStatusCheck(force: Bool = false) {
        CloudAccountStatusProvider.shared.requestAccountStatusCheck(force: force)
    }
}


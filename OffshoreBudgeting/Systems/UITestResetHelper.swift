import Foundation

// MARK: - UITestResetHelper
/// Centralized helper that clears persisted state when UI tests request a reset via
/// a launch argument. This keeps the main app target free of test-only logic while
/// still allowing deterministic end-to-end flows.
enum UITestResetHelper {
    /// Launch argument that triggers a full reset of user defaults and the Core Data store.
    static let resetArgument = "--uitest-reset"

    /// Performs a reset when the launch arguments contain ``resetArgument``.
    /// - Parameters:
    ///   - processInfo: Injected for testability; defaults to ``ProcessInfo.processInfo``.
    ///   - coreDataService: Injected for testability; defaults to ``CoreDataService.shared``.
    @MainActor
    static func resetIfNeeded(
        processInfo: ProcessInfo = .processInfo,
        coreDataService: CoreDataService = .shared
    ) {
        guard processInfo.arguments.contains(resetArgument) else { return }

        resetUserDefaults()
        coreDataService.disableCloudSyncPreferences()
        coreDataService.resetForUITesting()
    }

    /// Removes the persisted defaults domain so onboarding and settings start fresh.
    private static func resetUserDefaults(defaults: UserDefaults = .standard) {
        if let bundleIdentifier = Bundle.main.bundleIdentifier {
            defaults.removePersistentDomain(forName: bundleIdentifier)
        } else {
            defaults.dictionaryRepresentation().keys.forEach { defaults.removeObject(forKey: $0) }
        }
        defaults.synchronize()
    }
}

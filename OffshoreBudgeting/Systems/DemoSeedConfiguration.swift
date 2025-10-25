#if DEBUG
import Foundation

// MARK: - DemoSeedConfiguration
/// Utilities for toggling demo data seeding during debug builds.
///
/// Environment opt-in (`UB_DEMO_SEED`):
/// - `off` (default) — Disable demo seeding.
/// - `once` — Seed once per `seedVersion` sentinel.
/// - `reset` — Reset existing data, then seed and record the sentinel.
///
/// A matching `UserDefaults` override (`UBDemoSeedMode`) may be supplied for
/// local testing when environment variables are inconvenient.
///
/// Release builds default to `.off` so shipping behavior is unchanged.
enum DemoSeedConfiguration {
    enum SeedMode: String {
        case off
        case once
        case reset
    }

    private static let environmentKey = "UB_DEMO_SEED"
    private static let userDefaultsModeKey = "UBDemoSeedMode"
    private static let userDefaultsVersionKey = "UBDemoSeedVersion"
    private static let currentSeedVersion = 1

    static var seedVersion: Int { currentSeedVersion }

    private static var isSupportedDebugTarget: Bool {
        #if targetEnvironment(simulator)
        return true
        #elseif targetEnvironment(macCatalyst)
        return true
        #else
        return false
#endif
    }

    static func seedMode(
        userDefaults: UserDefaults = .standard,
        processInfo: ProcessInfo = .processInfo
    ) -> SeedMode {
        guard isSupportedDebugTarget else { return .off }

        if let environmentValue = processInfo.environment[environmentKey]?.lowercased(),
           let environmentMode = SeedMode(rawValue: environmentValue) {
            return environmentMode
        }

        if let overrideValue = userDefaults.string(forKey: userDefaultsModeKey)?.lowercased(),
           let overrideMode = SeedMode(rawValue: overrideValue) {
            return overrideMode
        }

        return .off
    }

    static func shouldSeedOnLaunch(
        userDefaults: UserDefaults = .standard,
        processInfo: ProcessInfo = .processInfo
    ) -> Bool {
        guard isSupportedDebugTarget else { return false }

        switch seedMode(userDefaults: userDefaults, processInfo: processInfo) {
        case .off:
            return false
        case .reset:
            return true
        case .once:
            return storedSeedVersion(in: userDefaults) < currentSeedVersion
        }
    }

    static func shouldResetBeforeSeed(
        userDefaults: UserDefaults = .standard,
        processInfo: ProcessInfo = .processInfo
    ) -> Bool {
        guard isSupportedDebugTarget else { return false }
        return seedMode(userDefaults: userDefaults, processInfo: processInfo) == .reset
    }

    static func markSeedCompleted(userDefaults: UserDefaults = .standard) {
        userDefaults.set(currentSeedVersion, forKey: userDefaultsVersionKey)
    }

    static func clearSeedVersion(userDefaults: UserDefaults = .standard) {
        userDefaults.removeObject(forKey: userDefaultsVersionKey)
    }

    private static func storedSeedVersion(in userDefaults: UserDefaults) -> Int {
        let version = userDefaults.integer(forKey: userDefaultsVersionKey)
        return version
    }
}
#endif

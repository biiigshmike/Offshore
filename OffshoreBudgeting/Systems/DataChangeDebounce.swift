import Foundation

/// Provides a dynamic debounce interval for coalescing UI refreshes triggered
/// by Core Data/CloudKit changes. During initial Cloud import, use a slightly
/// longer window to avoid flicker; otherwise prefer a short debounce for snap.
enum DataChangeDebounce {
    /// Debounce in milliseconds.
    @MainActor
    static func milliseconds() -> Int {
        let cloudOn = UserDefaults.standard.bool(forKey: AppSettingsKeys.enableCloudSync.rawValue)
        if cloudOn, CloudSyncMonitor.shared.isImporting {
            return 250
        } else {
            return 100
        }
    }

    /// Slightly longer debounce for emitting full UI state changes (e.g., Home summaries)
    /// to avoid visible flicker during CloudKit imports.
    @MainActor
    static func outputMilliseconds() -> Int {
        let cloudOn = UserDefaults.standard.bool(forKey: AppSettingsKeys.enableCloudSync.rawValue)
        if cloudOn, CloudSyncMonitor.shared.isImporting {
            return 300
        } else {
            return 140
        }
    }
}

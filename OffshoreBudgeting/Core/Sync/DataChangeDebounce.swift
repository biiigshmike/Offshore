//
//  DataChangeDebounce.swift
//  Offshore
//

import Foundation

// MARK: - DataChangeDebounce
/// Provides a dynamic debounce interval for coalescing UI refreshes triggered
/// by Core Data/CloudKit changes. During initial Cloud import, use a slightly
/// longer window to avoid flicker; otherwise prefer a short debounce for snap.
enum DataChangeDebounce {
    /// Debounce in milliseconds.
    @MainActor
    static func milliseconds() -> Int {
        let cloudOn = UserDefaults.standard.bool(forKey: AppSettingsKeys.enableCloudSync.rawValue)
        let isImporting = cloudOn && CloudSyncMonitor.shared.isImporting
        return Debouncer<Void>.intervalMilliseconds(isImporting: isImporting, normal: 100, importing: 250)
    }

    /// Slightly longer debounce for emitting full UI state changes (e.g., Home summaries)
    /// to avoid visible flicker during CloudKit imports.
    @MainActor
    static func outputMilliseconds() -> Int {
        let cloudOn = UserDefaults.standard.bool(forKey: AppSettingsKeys.enableCloudSync.rawValue)
        let isImporting = cloudOn && CloudSyncMonitor.shared.isImporting
        return Debouncer<Void>.intervalMilliseconds(isImporting: isImporting, normal: 140, importing: 300)
    }
}

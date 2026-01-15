//
//  CloudKitConfig.swift
//  Offshore
//

import Foundation

// MARK: - CloudKitConfig
/// Central location for CloudKit configuration constants that must be
/// accessible from non-MainActor contexts.
enum CloudKitConfig {
    // Must match the container configured on the App ID and in the
    // target's entitlements (Debug and Release) and CloudKit Dashboard.
    static let containerIdentifier = "iCloud.com.mb.offshore-budgeting"
}

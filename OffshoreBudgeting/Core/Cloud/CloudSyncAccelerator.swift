//
//  CloudSyncAccelerator.swift
//  Offshore
//

import CloudKit
import Foundation

// MARK: - CloudSyncAccelerator
/// Lightweight helper to improve perceived cross‑device sync latency while the app is active.
///
/// Notes:
/// - NSPersistentCloudKitContainer already registers CloudKit subscriptions and responds to
///   silent push to import changes. However, APNs delivery can occasionally be delayed or
///   coalesced. Performing a tiny foreground CloudKit read when the scene becomes active
///   helps warm the connection and often causes pending pushes to arrive faster.
/// - This does not replace the container’s import pipeline; it simply nudges the system
///   and avoids the “stale for a few seconds after open” feeling.
@MainActor
final class CloudSyncAccelerator {
    // MARK: Shared
    static let shared = CloudSyncAccelerator()

    // MARK: Private
    private var lastNudge: Date?

    /// Minimum time between foreground nudges to avoid excessive traffic.
    private let minNudgeInterval: TimeInterval = 5.0

    // MARK: Init
    private init() {}

    // MARK: Public API
    /// Trigger a tiny CloudKit read to warm the pipe and encourage prompt
    /// delivery of any pending pushes for the app’s private database.
    func nudgeOnForeground() {
        guard UserDefaultsAppSettingsStore().bool(for: .enableCloudSync) ?? false else { return }

        let now = Date()
        if let last = lastNudge, now.timeIntervalSince(last) < minNudgeInterval { return }
        lastNudge = now

        Task.detached(priority: .utility) {
            let client = CloudClient()
            do {
                // 1) Warm up by checking account status quickly.
                _ = try await CloudStatus.shared.accountStatus(forceRefresh: true, client: client)

                // 2) Issue a minimal query for a single lightweight mirrored record type.
                //    We don’t use the result; the goal is to tickle the connection.
                let query = CKQuery(recordType: "CD_Budget", predicate: NSPredicate(value: true))
                let op = CKQueryOperation(query: query)
                op.resultsLimit = 1
                op.desiredKeys = ["id"]
                op.qualityOfService = .utility
                // Drain callbacks without doing anything heavy.
                op.recordMatchedBlock = { _, _ in }
                op.queryResultBlock = { _ in }
                client.privateDatabase.add(op)
            } catch {
                // Non‑fatal; this is best‑effort.
                AppLog.iCloud.debug("CloudSyncAccelerator nudge error: \(String(describing: error))")
            }
        }
    }
}

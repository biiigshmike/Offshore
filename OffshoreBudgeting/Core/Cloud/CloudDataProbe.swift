//
//  CloudDataProbe.swift
//  Offshore
//

import Foundation
import CoreData

// MARK: - CloudDataProbe
/// Lightweight helper to detect whether any app data exists in the current store.
/// In CloudKit mode, this can be used after enabling sync to determine if remote
/// records are present (once mirroring/import has begun).
@MainActor
final class CloudDataProbe {
    // MARK: Public API
    /// Quick, synchronous check for any data in the current store.
    func hasAnyData() -> Bool {
        LocalCloudDataProbeRunner().hasAnyDataOnce()
    }

    /// Polls for existing data across key entities for a short window.
    /// - Parameters:
    ///   - timeout: Maximum time to wait for import to surface any records.
    ///   - pollInterval: Interval between checks.
    /// - Returns: `true` if any known entity reports at least one record.
    func scanForExistingData(timeout: TimeInterval = 3.0,
                             pollInterval: TimeInterval = 0.3) async -> Bool {
        await LocalCloudDataProbeRunner().scanForExistingData(timeout: timeout, pollInterval: pollInterval)
    }
}

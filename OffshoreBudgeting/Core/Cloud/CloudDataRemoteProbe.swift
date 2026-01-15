//
//  CloudDataRemoteProbe.swift
//  Offshore
//

import Foundation

// MARK: - CloudDataRemoteProbe
/// Performs lightweight CloudKit queries to detect whether any app records
/// exist remotely in the user's private database.
struct CloudDataRemoteProbe {
    // MARK: Stored
    private let runner: RemoteCloudDataProbeRunner

    // MARK: Init
    init(containerIdentifier: String = CloudKitConfig.containerIdentifier) {
        self.runner = RemoteCloudDataProbeRunner(client: CloudClient(containerIdentifier: containerIdentifier))
    }

    // MARK: Public API
    /// Returns true if any of the app's record types have at least one record in iCloud.
    func hasAnyRemoteData(timeout: TimeInterval = 6.0) async -> Bool {
        await runner.hasAnyRemoteData(timeout: timeout)
    }
}

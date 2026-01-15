//
//  CloudStatus.swift
//  Offshore
//

import CloudKit
import CoreData
import Foundation

// MARK: - CloudStatus
/// Centralizes CloudKit account status caching and container reachability checks.
@MainActor
final class CloudStatus {
    // MARK: Shared
    static let shared = CloudStatus()

    // MARK: Notifications
    /// Used by CloudKit event monitors to observe import/setup progress.
    static let cloudKitEventChangedNotification = NSPersistentCloudKitContainer.eventChangedNotification

    // MARK: Private
    private var lastStatus: CKAccountStatus?

    // MARK: Init
    private init() {}

    // MARK: Public API
    func invalidateCache() {
        lastStatus = nil
    }

    func accountStatus(forceRefresh: Bool = false, client: CloudClient = CloudClient()) async throws -> CKAccountStatus {
        if !forceRefresh, let lastStatus {
            return lastStatus
        }
        let status = try await client.container.accountStatus()
        lastStatus = status
        return status
    }

    /// Determines whether iCloud/CloudKit is usable for the app’s named container.
    /// This mirrors the prior behavior in `CloudAccountStatusProvider`:
    /// - Cache the last `CKAccountStatus`.
    /// - If `.available`, do a minimal named-container probe.
    func resolveAvailability(
        forceRefresh: Bool = false,
        client: CloudClient = CloudClient(),
        coreDataZoneID: CKRecordZone.ID?
    ) async -> Bool {
        if !forceRefresh, let cached = lastStatus {
            return cached == .available
        }

        let status: CKAccountStatus
        do {
            status = try await client.container.accountStatus()
        } catch {
            AppLog.iCloud.error("CKContainer.accountStatus() error: \(String(describing: error))")
            lastStatus = .noAccount
            return false
        }

        guard status == .available else {
            lastStatus = status
            return false
        }

        let ok = await probeNamedContainer(client, coreDataZoneID: coreDataZoneID)
        lastStatus = ok ? .available : .noAccount
        return ok
    }

    // MARK: Private
    private func probeNamedContainer(_ client: CloudClient, coreDataZoneID: CKRecordZone.ID?) async -> Bool {
        await withCheckedContinuation { continuation in
            let query = CKQuery(recordType: "CD_Budget", predicate: NSPredicate(value: true))
            let op = CKQueryOperation(query: query)
            op.resultsLimit = 1
            if let zoneID = coreDataZoneID {
                op.zoneID = zoneID
            }
            op.queryResultBlock = { result in
                switch result {
                case .success:
                    continuation.resume(returning: true)
                case .failure(let error):
                    if Self.shouldTreatErrorAsReachable(error) {
                        if AppLog.isVerbose {
                            AppLog.iCloud.info("Cloud container probe zone missing but treating as reachable: \(String(describing: error))")
                        }
                        continuation.resume(returning: true)
                    } else {
                        AppLog.iCloud.error("Cloud container probe failed: \(String(describing: error))")
                        continuation.resume(returning: false)
                    }
                }
            }
            client.privateDatabase.add(op)
        }
    }

    private static func shouldTreatErrorAsReachable(_ error: Error) -> Bool {
        guard let ckError = error as? CKError else { return false }
        switch ckError.code {
        case .zoneNotFound, .unknownItem:
            return true
        case .partialFailure:
            let partialErrors = ckError.partialErrorsByItemID ?? [:]
            guard !partialErrors.isEmpty else { return false }
            return partialErrors.values.allSatisfy { value in
                guard let innerError = value as? CKError else { return false }
                return innerError.code == .zoneNotFound
            }
        default:
            return false
        }
    }
}

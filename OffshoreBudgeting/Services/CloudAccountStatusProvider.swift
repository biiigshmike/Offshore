//
//  CloudAccountStatusProvider.swift
//  SoFar
//
//  Reports iCloud account availability for the configured CloudKit container
//  and caches results for lightweight decisions across the app.
//

import Combine
import Foundation
import CloudKit

/// Centralized helper that reports whether the user currently has access to the
/// configured iCloud container. The provider caches the most recent
/// `CKAccountStatus` value so multiple features (Core Data setup, onboarding,
/// settings) can make a fast decision without repeatedly hitting CloudKit.
@MainActor
final class CloudAccountStatusProvider: ObservableObject {

    // MARK: Shared Instance

    /// CloudKit container identifier matching the app's entitlements.
    /// Ensure this value stays in sync with `com.apple.developer.icloud-container-identifiers`.
    static let containerIdentifier = CloudKitConfig.containerIdentifier

    static let shared = CloudAccountStatusProvider()

    // MARK: Availability State

    enum Availability: Equatable {
        case unknown
        case available
        case unavailable
    }

    @Published private(set) var availability: Availability = .unknown

    /// Returns `true` when `availability == .available` and `false` when the
    /// check has finished and determined that iCloud is not usable. Returns
    /// `nil` while the provider is still determining availability.
    var isCloudAccountAvailable: Bool? {
        switch availability {
        case .available:   return true
        case .unavailable: return false
        case .unknown:     return nil
        }
    }

    // MARK: Private State
    private var isChecking = false
    private var lastStatus: CKAccountStatus?

    // MARK: Init
    init() {
        NotificationCenter.default.addObserver(
            forName: .CKAccountChanged,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self else { return }
                self.invalidateCache()
                self.requestAccountStatusCheck(force: true)
            }
        }
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: Public API

    /// Starts a background task (if one is not already running) to refresh the
    /// CloudKit account status. Useful for callers that do not need the result
    /// immediately but want to make sure the cache stays fresh.
    func requestAccountStatusCheck(force: Bool = false) {
        guard !isChecking else { return }
        isChecking = true
        Task { @MainActor in
            defer { isChecking = false }
            _ = await resolveAvailability(forceRefresh: force)
        }
    }

    /// Returns whether iCloud is currently available for the app's named container.
    /// When the status has not been fetched yet this method queries CloudKit and caches the result.
    /// After confirming general iCloud availability, this also performs a minimal
    /// container‑specific probe to guard against entitlement or production schema issues.
    /// - Parameter forceRefresh: When `true`, bypasses any cached value and re-queries CloudKit.
    func resolveAvailability(forceRefresh: Bool = false) async -> Bool {
        if !forceRefresh, let cached = lastStatus {
            let isAvailable = cached == .available
            availability = isAvailable ? .available : .unavailable
            return isAvailable
        }

        // Use the app's named container.
        let container = CKContainer(identifier: Self.containerIdentifier)
        let status: CKAccountStatus
        do {
            status = try await container.accountStatus()
        } catch {
            AppLog.iCloud.error("CKContainer.accountStatus() error: \(String(describing: error))")
            lastStatus = .noAccount
            availability = .unavailable
            return false
        }

        // If the account itself isn't available, short‑circuit.
        guard status == .available else {
            lastStatus = status
            availability = .unavailable
            return false
        }

        // Perform a tiny query against a mirrored record type to validate that the
        // specified container is reachable and the Production schema is deployed.
        // We treat "no results" as success; only transport/authorization/schema errors
        // should flip availability to unavailable.
        let ok = await probeNamedContainer(container)
        lastStatus = ok ? .available : .noAccount
        availability = ok ? .available : .unavailable
        return ok
    }

    /// Runs a minimal query on the private database for a mirrored Core Data record type.
    /// Returns true on success (even with zero results), false on any error.
    private func probeNamedContainer(_ container: CKContainer) async -> Bool {
        await withCheckedContinuation { continuation in
            let db = container.privateCloudDatabase
            let query = CKQuery(recordType: "CD_Budget", predicate: NSPredicate(value: true))
            let op = CKQueryOperation(query: query)
            op.resultsLimit = 1
            // Only errors matter here
            op.queryResultBlock = { result in
                switch result {
                case .success:
                    continuation.resume(returning: true)
                case .failure(let error):
                    AppLog.iCloud.error("Cloud container probe failed: \(String(describing: error))")
                    continuation.resume(returning: false)
                }
            }
            db.add(op)
        }
    }

    /// Removes any cached status so the next call to `resolveAvailability`
    /// fetches from CloudKit again.
    func invalidateCache() {
        lastStatus = nil
        availability = .unknown
    }
}

// MARK: - CloudAvailabilityProviding

@MainActor
protocol CloudAvailabilityProviding: AnyObject {
    var isCloudAccountAvailable: Bool? { get }
    var availabilityPublisher: AnyPublisher<CloudAccountStatusProvider.Availability, Never> { get }
    func requestAccountStatusCheck(force: Bool)
    func resolveAvailability(forceRefresh: Bool) async -> Bool
    func invalidateCache()
}

@MainActor
extension CloudAccountStatusProvider: CloudAvailabilityProviding {
    var availabilityPublisher: AnyPublisher<Availability, Never> {
        $availability.eraseToAnyPublisher()
    }
}

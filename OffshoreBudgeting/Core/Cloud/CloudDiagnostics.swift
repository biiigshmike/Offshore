//
//  CloudDiagnostics.swift
//  Offshore
//

import CloudKit
import CoreData
import Foundation

// MARK: - CloudDiagnostics
/// Presents a lightweight, user-facing view of cloud sync status for Settings.
@MainActor
final class CloudDiagnostics: ObservableObject {
    // MARK: Shared
    static let shared = CloudDiagnostics()

    // MARK: Published
    @Published private(set) var storeMode: String = "Local"
    @Published private(set) var containerReachable: Bool? = nil
    @Published private(set) var lastCloudKitErrorDescription: String? = nil

    // MARK: Private
    private var cloudEventObserver: NSObjectProtocol?
    private var isRefreshing: Bool = false

    // MARK: Init
    private init() {
        // Observe CloudKit events to capture the most recent error (if any).
        cloudEventObserver = NotificationCenter.default.addObserver(
            forName: CloudStatus.cloudKitEventChangedNotification,
            object: nil,
            queue: .main
        ) { note in
            // Extract minimal values outside the MainActor mutation.
            let errDesc: String?
            let succeeded: Bool
            if let event = note.userInfo?[NSPersistentCloudKitContainer.eventNotificationUserInfoKey] as? NSPersistentCloudKitContainer.Event {
                errDesc = event.error?.localizedDescription
                succeeded = event.succeeded
            } else {
                errDesc = nil
                succeeded = false
            }
            Task { @MainActor [weak self] in
                guard let self else { return }
                if let errDesc {
                    self.lastCloudKitErrorDescription = errDesc
                } else if succeeded {
                    // Clear error on success to reduce stale warnings.
                    self.lastCloudKitErrorDescription = nil
                }
            }
        }
    }

    // MARK: Deinit
    deinit { if let obs = cloudEventObserver { NotificationCenter.default.removeObserver(obs) } }

    // MARK: Public API
    /// Refreshes all diagnostic fields.
    func refresh() async {
        guard !isRefreshing else { return }
        isRefreshing = true
        defer { isRefreshing = false }

        // Named-container reachability (also validates Production schema presence)
        let nextStoreMode = CoreDataService.shared.storeModeDescription
        let reachable = await CloudAccountStatusProvider.shared.resolveAvailability(forceRefresh: true)

        // Assign only when changed to reduce redundant SwiftUI invalidations during navigation.
        if storeMode != nextStoreMode {
            storeMode = nextStoreMode
        }
        if containerReachable != reachable {
            containerReachable = reachable
        }
    }
}

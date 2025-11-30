
//
//  ForceReuploadHelper.swift
//  Offshore
//
//  Created by Michael Brown on 11/30/25.
//

import Foundation
import CoreData

/// Debug/maintenance helper to force existing local records to generate new
/// Core Data history transactions so NSPersistentCloudKitContainer will
/// re-export them to CloudKit. This is intentionally a standalone utility so
/// it can be reused in future builds when you need to nudge legacy data.
///
/// Usage (manual, one-time):
/// 1) Build a debug/test build with Cloud sync enabled and launch the app.
/// 2) From a safe, temporary entry point (e.g., a hidden Settings button or an
///    `onAppear` guarded by `#if DEBUG`), call:
///        `Task { try? await ForceReuploadHelper.forceReuploadAll(reason: "2025-<tag>") }`
///    Update the `reason` tag each time you purposely run this so logs show why.
/// 3) Keep the app in the foreground for a few minutes so CloudKit can upload.
///    Watch the Cloud Diagnostics card for errors. You can also pull-to-refresh
///    on data screens to nudge a fetch while uploads are in flight.
/// 4) Remove the call after you see your data on another device/simulator.
///
/// What it does:
/// - Ensures stores are loaded and CloudKit mode is active.
/// - Runs a batch update across all syncable entities to rewrite `workspaceID`
///   to the current workspace. Even when the value is the same, the batch
///   update produces history entries, which CloudKit mirroring treats as
///   updates to export. No user-visible fields are changed.
/// - Merges the updated object IDs back into the view context so UI can refresh.
///
/// Safety notes:
/// - Intended for debug/maintenance only, do not call automatically in release.
/// - Wrap any caller in a debug flag or a temporary button so it is obvious
///   when it runs. The helper itself does not gate on build configuration.
enum ForceReuploadHelper {

    enum ForceReuploadError: Error {
        case storesNotLoaded
        case cloudNotActive
    }

    struct Result {
        let updatedCounts: [String: Int]
        var totalUpdated: Int {
            updatedCounts.values.reduce(0, +)
        }
    }

    /// Runs a batch "touch" of all syncable entities so CloudKit will re-export them.
    /// - Parameter reason: Optional tag to include in logs to track why this was run.
    @MainActor
    static func forceReuploadAll(reason: String = "manual") async throws -> Result {

        // Ensure the stack is ready and CloudKit mode is active
        await CoreDataService.shared.waitUntilStoresLoaded(timeout: 10.0)

        guard CoreDataService.shared.storesLoaded else {
            throw ForceReuploadError.storesNotLoaded
        }

        guard CoreDataService.shared.isCloudStoreActive else {
            throw ForceReuploadError.cloudNotActive
        }

        let workspaceID = WorkspaceService.shared.ensureActiveWorkspaceID()

        let entityNames = [
            "Budget",
            "Card",
            "Income",
            "PlannedExpense",
            "UnplannedExpense",
            "ExpenseCategory"
        ]

        let backgroundContext = CoreDataService.shared.container.newBackgroundContext()
        backgroundContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        backgroundContext.automaticallyMergesChangesFromParent = true

        var updated: [String: Int] = [:]

        for name in entityNames {
            try backgroundContext.performAndWait {

                let request = NSBatchUpdateRequest(entityName: name)
                request.propertiesToUpdate = ["workspaceID": workspaceID]
                request.resultType = .updatedObjectIDsResultType

                let result = try backgroundContext.execute(request) as? NSBatchUpdateResult
                let ids = (result?.result as? [NSManagedObjectID]) ?? []

                updated[name] = ids.count

                if !ids.isEmpty {
                    // Merge into viewContext so UI updates without relaunch
                    let changes: [AnyHashable: Any] = [
                        NSUpdatedObjectsKey: ids
                    ]

                    NSManagedObjectContext.mergeChanges(
                        fromRemoteContextSave: changes,
                        into: [CoreDataService.shared.viewContext]
                    )
                }
            }
        }

        if AppLog.isVerbose {
            AppLog.iCloud.info("Force reupload complete (\(reason)): \(updated)")
        }

        return Result(updatedCounts: updated)
    }
}

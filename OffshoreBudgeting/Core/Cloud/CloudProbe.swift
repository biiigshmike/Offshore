//
//  CloudProbe.swift
//  Offshore
//

import CloudKit
import CoreData
import Foundation

// MARK: - CloudProbe
/// Shared façade for Cloud/local data presence probes.
protocol CloudProbe {
    associatedtype Output
    func run() async throws -> Output
}

// MARK: - CloudProbeDefaults
enum CloudProbeDefaults {
    /// Representative set of Core Data entities that indicates a prior setup.
    static let coreDataEntityNames: [String] = [
        "Budget", "Card", "Income", "PlannedExpense", "UnplannedExpense", "ExpenseCategory"
    ]

    /// NSPersistentCloudKitContainer mirrors Core Data entities using the "CD_<EntityName>" record type convention by default.
    static let mirroredRecordTypes: [String] = [
        "CD_Budget", "CD_Card", "CD_Income", "CD_PlannedExpense", "CD_UnplannedExpense", "CD_ExpenseCategory"
    ]
}

// MARK: - LocalCloudDataProbeRunner
struct LocalCloudDataProbeRunner {
    // MARK: Stored
    let service: CoreDataService
    let entityNames: [String]

    // MARK: Init
    init(service: CoreDataService = .shared, entityNames: [String] = CloudProbeDefaults.coreDataEntityNames) {
        self.service = service
        self.entityNames = entityNames
    }

    // MARK: Public API
    func hasAnyDataOnce() -> Bool {
        let context = service.viewContext
        for name in entityNames {
            if (try? count(name, in: context)) ?? 0 > 0 { return true }
        }
        return false
    }

    func scanForExistingData(timeout: TimeInterval, pollInterval: TimeInterval) async -> Bool {
        // Ensure the container is ready.
        await service.waitUntilStoresLoaded(timeout: 10.0)

        let deadline = Date().addingTimeInterval(timeout)
        repeat {
            if hasAnyDataOnce() { return true }
            try? await Task.sleep(nanoseconds: UInt64(pollInterval * 1_000_000_000))
        } while Date() < deadline

        return hasAnyDataOnce()
    }

    private func count(_ entityName: String, in context: NSManagedObjectContext) throws -> Int {
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: entityName)
        return try context.count(for: request)
    }
}

// MARK: - RemoteCloudDataProbeRunner
struct RemoteCloudDataProbeRunner {
    // MARK: Stored
    let client: CloudClient
    let recordTypes: [String]

    // MARK: Init
    init(client: CloudClient = CloudClient(), recordTypes: [String] = CloudProbeDefaults.mirroredRecordTypes) {
        self.client = client
        self.recordTypes = recordTypes
    }

    // MARK: Public API
    func hasAnyRemoteData(timeout: TimeInterval) async -> Bool {
        let deadline = Date().addingTimeInterval(timeout)
        for type in recordTypes {
            if Date() > deadline { break }
            do {
                let found = try await hasRecord(ofType: type)
                if found { return true }
            } catch {
                continue
            }
        }
        return false
    }

    private func hasRecord(ofType recordType: String) async throws -> Bool {
        try await withCheckedThrowingContinuation { continuation in
            let query = CKQuery(recordType: recordType, predicate: NSPredicate(value: true))
            let op = CKQueryOperation(query: query)
            op.resultsLimit = 1
            var foundAny = false
            op.recordMatchedBlock = { _, result in
                if case .success(_) = result {
                    foundAny = true
                }
            }
            op.queryResultBlock = { _ in
                continuation.resume(returning: foundAny)
            }
            client.privateDatabase.add(op)
        }
    }
}

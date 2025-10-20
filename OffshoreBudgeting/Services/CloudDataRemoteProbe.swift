import Foundation
import CloudKit

/// Performs lightweight CloudKit queries to detect whether any app records
/// exist remotely in the user's private database.
struct CloudDataRemoteProbe {
    private let container: CKContainer
    private let database: CKDatabase
    private let recordTypes = [
        "Budget", "Card", "Income", "PlannedExpense", "UnplannedExpense", "ExpenseCategory"
    ]

    init(containerIdentifier: String = CloudKitConfig.containerIdentifier) {
        self.container = CKContainer(identifier: containerIdentifier)
        self.database = container.privateCloudDatabase
    }

    /// Returns true if any of the app's record types have at least one record in iCloud.
    func hasAnyRemoteData(timeout: TimeInterval = 6.0) async -> Bool {
        let deadline = Date().addingTimeInterval(timeout)
        for type in recordTypes {
            if Date() > deadline { break }
            do {
                let found = try await hasRecord(ofType: type)
                if found { return true }
            } catch {
                // Non-fatal: continue to next type
                continue
            }
        }
        return false
    }

    private func hasRecord(ofType recordType: String) async throws -> Bool {
        return try await withCheckedThrowingContinuation { continuation in
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
            database.add(op)
        }
    }
}

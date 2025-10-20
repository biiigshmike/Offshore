import Foundation
import CoreData

/// Lightweight helper to detect whether any app data exists in the current store.
/// In CloudKit mode, this can be used after enabling sync to determine if remote
/// records are present (once mirroring/import has begun).
@MainActor
final class CloudDataProbe {
    /// Quick, synchronous check for any data in the current store.
    func hasAnyData() -> Bool {
        hasAnyDataOnce()
    }
    /// Polls for existing data across key entities for a short window.
    /// - Parameters:
    ///   - timeout: Maximum time to wait for import to surface any records.
    ///   - pollInterval: Interval between checks.
    /// - Returns: `true` if any known entity reports at least one record.
    func scanForExistingData(timeout: TimeInterval = 3.0,
                             pollInterval: TimeInterval = 0.3) async -> Bool {
        // Ensure the container is ready.
        await CoreDataService.shared.waitUntilStoresLoaded(timeout: 10.0)

        let deadline = Date().addingTimeInterval(timeout)
        repeat {
            if hasAnyDataOnce() { return true }
            try? await Task.sleep(nanoseconds: UInt64(pollInterval * 1_000_000_000))
        } while Date() < deadline

        return hasAnyDataOnce()
    }

    private func hasAnyDataOnce() -> Bool {
        let ctx = CoreDataService.shared.viewContext
        // Check a representative set of entities that indicates a prior setup.
        let entities = ["Budget", "Card", "Income", "PlannedExpense", "UnplannedExpense", "ExpenseCategory"]
        for name in entities {
            if (try? count(name, in: ctx)) ?? 0 > 0 { return true }
        }
        return false
    }

    private func count(_ entityName: String, in ctx: NSManagedObjectContext) throws -> Int {
        let req = NSFetchRequest<NSFetchRequestResult>(entityName: entityName)
        // Count is efficient; no properties needed.
        return try ctx.count(for: req)
    }
}

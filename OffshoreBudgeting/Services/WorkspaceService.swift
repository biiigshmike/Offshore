import Foundation
import CoreData

/// Manages the app's active workspace identity and assigns it to records.
@MainActor
final class WorkspaceService {
    static let shared = WorkspaceService()

    private init() {}

    private let defaultsLocalKey = "workspace.active.local"
    private let defaultsCloudKey = "workspace.active.cloud"
    private let ubiquitousKey = "workspace.active.id"

    private var defaults: UserDefaults { .standard }

    private var cloudEnabled: Bool {
        UserDefaults.standard.bool(forKey: AppSettingsKeys.enableCloudSync.rawValue)
    }

    /// Returns the active workspace ID, creating one if necessary. Uses
    /// NSUbiquitousKeyValueStore when Cloud is enabled to keep the ID the same
    /// across devices.
    var activeWorkspaceID: UUID {
        get { ensureActiveWorkspaceID() }
    }

    @discardableResult
    func ensureActiveWorkspaceID() -> UUID {
        if cloudEnabled {
            let kv = NSUbiquitousKeyValueStore.default
            if let raw = kv.string(forKey: ubiquitousKey), let id = UUID(uuidString: raw) {
                // Mirror to defaults for quick reads
                defaults.set(raw, forKey: defaultsCloudKey)
                return id
            }
            if let raw = defaults.string(forKey: defaultsCloudKey), let id = UUID(uuidString: raw) {
                kv.set(raw, forKey: ubiquitousKey)
                kv.synchronize()
                return id
            }
            let fresh = UUID()
            let s = fresh.uuidString
            kv.set(s, forKey: ubiquitousKey)
            kv.synchronize()
            defaults.set(s, forKey: defaultsCloudKey)
            return fresh
        } else {
            if let raw = defaults.string(forKey: defaultsLocalKey), let id = UUID(uuidString: raw) {
                return id
            }
            let fresh = UUID()
            defaults.set(fresh.uuidString, forKey: defaultsLocalKey)
            return fresh
        }
    }

    /// Applies the active workspace ID to any records missing it.
    func assignWorkspaceIDIfMissing() async {
        await CoreDataService.shared.waitUntilStoresLoaded(timeout: 10.0)
        let ctx = CoreDataService.shared.viewContext
        let id = ensureActiveWorkspaceID()

        let entities = [
            "Budget", "Card", "Income", "PlannedExpense", "UnplannedExpense", "ExpenseCategory"
        ]
        var changed = false
        for name in entities {
            let req = NSFetchRequest<NSManagedObject>(entityName: name)
            req.predicate = NSPredicate(format: "workspaceID == nil")
            let items = (try? ctx.fetch(req)) ?? []
            for obj in items {
                obj.setValue(id, forKey: "workspaceID")
                changed = true
            }
        }
        if changed {
            try? ctx.save()
        }
    }

    /// Sets `workspaceID` on a newly created object if the attribute exists.
    func applyWorkspaceID(on object: NSManagedObject) {
        guard object.entity.attributesByName.keys.contains("workspaceID") else { return }
        if (object.value(forKey: "workspaceID") as? UUID) == nil {
            object.setValue(ensureActiveWorkspaceID(), forKey: "workspaceID")
        }
    }

    /// Launch-time convenience to make sure IDs are set and records are assigned.
    func initializeOnLaunch() async {
        _ = ensureActiveWorkspaceID()
        await assignWorkspaceIDIfMissing()
    }
}


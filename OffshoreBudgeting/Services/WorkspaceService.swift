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
        seedBudgetPeriodIfNeeded()
    }
}

// MARK: - Workspace helpers (budget period persistence)
extension WorkspaceService {
    /// Returns the Workspace row for the active workspace ID, creating it when missing.
    func fetchOrCreateWorkspace(in context: NSManagedObjectContext = CoreDataService.shared.viewContext) -> NSManagedObject? {
        let id = ensureActiveWorkspaceID()
        let req = NSFetchRequest<NSManagedObject>(entityName: "Workspace")
        req.fetchLimit = 1
        req.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        if let existing = try? context.fetch(req).first {
            return existing
        }
        guard let entity = NSEntityDescription.entity(forEntityName: "Workspace", in: context) else { return nil }
        let ws = NSManagedObject(entity: entity, insertInto: context)
        ws.setValue(id, forKey: "id")
        // Best-effort defaults
        if ws.entity.attributesByName.keys.contains("name") && (ws.value(forKey: "name") as? String) == nil {
            ws.setValue("Default", forKey: "name")
        }
        if ws.entity.attributesByName.keys.contains("isCloud") && (ws.value(forKey: "isCloud") as? Bool) == nil {
            ws.setValue(cloudEnabled, forKey: "isCloud")
        }
        try? context.save()
        return ws
    }

    /// Reads the current budget period stored on the Workspace row.
    func currentBudgetPeriod(in context: NSManagedObjectContext = CoreDataService.shared.viewContext) -> BudgetPeriod {
        guard let ws = fetchOrCreateWorkspace(in: context) else { return .monthly }
        if ws.entity.attributesByName.keys.contains("budgetPeriod"),
           let raw = ws.value(forKey: "budgetPeriod") as? String,
           let p = BudgetPeriod(rawValue: raw) {
            return p
        }
        return .monthly
    }

    /// Persists the budget period to the Workspace row.
    func setBudgetPeriod(_ period: BudgetPeriod, in context: NSManagedObjectContext = CoreDataService.shared.viewContext) {
        guard let ws = fetchOrCreateWorkspace(in: context) else { return }
        if ws.entity.attributesByName.keys.contains("budgetPeriod") {
            ws.setValue(period.rawValue, forKey: "budgetPeriod")
        }
        if ws.entity.attributesByName.keys.contains("budgetPeriodUpdatedAt") {
            ws.setValue(Date(), forKey: "budgetPeriodUpdatedAt")
        }
        try? context.save()
    }

    /// One-time seed: if Workspace.budgetPeriod is nil, copy from UserDefaults and persist.
    func seedBudgetPeriodIfNeeded() {
        let ctx = CoreDataService.shared.viewContext
        guard let ws = fetchOrCreateWorkspace(in: ctx) else { return }
        if ws.entity.attributesByName.keys.contains("budgetPeriod"),
           (ws.value(forKey: "budgetPeriod") as? String) == nil {
            let localRaw = UserDefaults.standard.string(forKey: AppSettingsKeys.budgetPeriod.rawValue) ?? BudgetPeriod.monthly.rawValue
            ws.setValue(localRaw, forKey: "budgetPeriod")
            if ws.entity.attributesByName.keys.contains("budgetPeriodUpdatedAt") {
                ws.setValue(Date(), forKey: "budgetPeriodUpdatedAt")
            }
            try? ctx.save()
        }
    }
}

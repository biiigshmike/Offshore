import Foundation
import CoreData

/// Manages the app's active workspace identity and assigns it to records.
@MainActor
final class WorkspaceService {
    static let shared = WorkspaceService()
    static let defaultNewWorkspaceColorHex = "#4E9CFF"

    private init() {}

    private let defaultsLocalKey = "workspace.active.local"
    private let defaultsCloudKey = "workspace.active.cloud"
    private let ubiquitousKey = "workspace.active.id"
    private let defaultsActiveKey = AppSettingsKeys.activeWorkspaceID.rawValue
    private let defaultsSeedPersonalKey = "workspace.seed.personal"
    private let defaultsSeedWorkKey = "workspace.seed.work"
    private let defaultsSeedEducationKey = "workspace.seed.education"

    private var defaults: UserDefaults { .standard }

    private var cloudEnabled: Bool {
        CloudStateFacade.isCloudSyncEnabled
    }

    /// Returns the active workspace ID, creating one if necessary.
    var activeWorkspaceID: UUID {
        get { ensureActiveWorkspaceID() }
    }

    @discardableResult
    func ensureActiveWorkspaceID() -> UUID {
        let context = CoreDataService.shared.viewContext
        let workspaces = ensureDefaultWorkspaces(in: context)
        if let stored = loadActiveWorkspaceID(),
           let existing = fetchWorkspace(byID: stored, in: context) {
            return existing.id ?? stored
        }

        if let personal = personalWorkspace(in: context), let id = personal.id {
            setActiveWorkspaceID(id, notify: false)
            return id
        }

        if let first = workspaces.first, let id = first.id {
            setActiveWorkspaceID(id, notify: false)
            return id
        }

        let created = ensureDefaultWorkspaces(in: context)
        if let fallback = created.first, let id = fallback.id {
            setActiveWorkspaceID(id, notify: false)
            return id
        }

        let fresh = UUID()
        setActiveWorkspaceID(fresh, notify: false)
        return fresh
    }

    /// Applies the provided workspace ID to any records missing it.
    func assignWorkspaceIDIfMissing(to workspaceID: UUID) async {
        await CoreDataService.shared.waitUntilStoresLoaded(timeout: 10.0)
        let ctx = CoreDataService.shared.viewContext
        let id = workspaceID

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
        await CoreDataService.shared.waitUntilStoresLoaded(timeout: 10.0)
        let ctx = CoreDataService.shared.viewContext
        _ = ensureDefaultWorkspaces(in: ctx)
        cleanupDuplicateWorkspaces(in: ctx)
        let personalID = personalWorkspace(in: ctx)?.id ?? ensureActiveWorkspaceID()
        await assignWorkspaceIDIfMissing(to: personalID)
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
            ws.setValue(defaultWorkspaceName(for: id), forKey: "name")
        }
        if ws.entity.attributesByName.keys.contains("isCloud") && (ws.value(forKey: "isCloud") as? Bool) == nil {
            ws.setValue(cloudEnabled, forKey: "isCloud")
        }
        if ws.entity.attributesByName.keys.contains("color"),
           let existing = ws.value(forKey: "color") as? String,
           existing.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            ws.setValue(defaultWorkspaceColorHex(for: id), forKey: "color")
        } else if ws.entity.attributesByName.keys.contains("color"),
                  (ws.value(forKey: "color") as? String) == nil {
            ws.setValue(defaultWorkspaceColorHex(for: id), forKey: "color")
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

// MARK: - Workspace selection + CRUD
extension WorkspaceService {
    nonisolated static func predicate(for workspaceID: UUID) -> NSPredicate {
        NSPredicate(format: "workspaceID == %@", workspaceID as CVarArg)
    }

    nonisolated static func activeWorkspaceIDFromDefaults() -> UUID? {
        guard let raw = UserDefaults.standard.string(forKey: AppSettingsKeys.activeWorkspaceID.rawValue) else {
            return nil
        }
        return UUID(uuidString: raw)
    }

    nonisolated static func combinedPredicate(_ predicate: NSPredicate?, workspaceID: UUID) -> NSPredicate {
        let workspacePredicate = Self.predicate(for: workspaceID)
        if let predicate {
            return NSCompoundPredicate(andPredicateWithSubpredicates: [predicate, workspacePredicate])
        }
        return workspacePredicate
    }

    nonisolated static func applyWorkspaceIDIfPossible(on object: NSManagedObject) {
        guard object.entity.attributesByName.keys.contains("workspaceID") else { return }
        if (object.value(forKey: "workspaceID") as? UUID) != nil { return }
        if let id = activeWorkspaceIDFromDefaults() {
            object.setValue(id, forKey: "workspaceID")
        }
    }

    enum WorkspaceSeed: CaseIterable {
        case personal
        case work
        case education

        var name: String {
            switch self {
            case .personal: return "Personal"
            case .work: return "Work"
            case .education: return "Education"
            }
        }

        var defaultsKey: String {
            switch self {
            case .personal: return "workspace.seed.personal"
            case .work: return "workspace.seed.work"
            case .education: return "workspace.seed.education"
            }
        }
    }

    func setActiveWorkspaceID(_ id: UUID, notify: Bool = true) {
        defaults.set(id.uuidString, forKey: defaultsActiveKey)
        if notify {
            NotificationCenter.default.post(name: .workspaceDidChange, object: nil)
            NotificationCenter.default.post(name: .dataStoreDidChange, object: nil)
        }
    }

    func fetchAllWorkspaces(in context: NSManagedObjectContext = CoreDataService.shared.viewContext) -> [Workspace] {
        let req: NSFetchRequest<Workspace> = Workspace.fetchRequest()
        req.sortDescriptors = [
            NSSortDescriptor(key: "name", ascending: true, selector: #selector(NSString.localizedCaseInsensitiveCompare(_:)))
        ]
        return (try? context.fetch(req)) ?? []
    }

    func fetchWorkspace(byID id: UUID, in context: NSManagedObjectContext = CoreDataService.shared.viewContext) -> Workspace? {
        let req: NSFetchRequest<Workspace> = Workspace.fetchRequest()
        req.fetchLimit = 1
        req.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        return (try? context.fetch(req))?.first
    }

    func createWorkspace(named name: String, in context: NSManagedObjectContext = CoreDataService.shared.viewContext) -> Workspace? {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        guard isWorkspaceNameAvailable(trimmed, excluding: nil, in: context) else { return nil }

        let ws = Workspace(context: context)
        ws.id = UUID()
        ws.name = trimmed
        if ws.entity.attributesByName.keys.contains("isCloud") {
            ws.isCloud = cloudEnabled
        }
        if ws.entity.attributesByName.keys.contains("color") {
            ws.setValue(Self.defaultNewWorkspaceColorHex, forKey: "color")
        }
        try? context.save()
        return ws
    }

    func renameWorkspace(_ workspace: Workspace, to name: String, in context: NSManagedObjectContext = CoreDataService.shared.viewContext) -> Bool {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return false }
        guard isWorkspaceNameAvailable(trimmed, excluding: workspace, in: context) else { return false }
        workspace.name = trimmed
        do {
            try context.save()
            return true
        } catch {
            return false
        }
    }

    func deleteWorkspace(_ workspace: Workspace, in context: NSManagedObjectContext = CoreDataService.shared.viewContext) -> Bool {
        if isPersonalWorkspace(workspace) { return false }
        let all = fetchAllWorkspaces(in: context)
        if all.count <= 1 { return false }

        if let activeID = loadActiveWorkspaceID(),
           let workspaceID = workspace.id,
           activeID == workspaceID {
            if let personal = personalWorkspace(in: context), let personalID = personal.id {
                setActiveWorkspaceID(personalID)
            }
        }

        context.delete(workspace)
        do {
            try context.save()
            return true
        } catch {
            return false
        }
    }

    func personalWorkspace(in context: NSManagedObjectContext = CoreDataService.shared.viewContext) -> Workspace? {
        let personalID = seedWorkspaceID(for: .personal)
        if let ws = fetchWorkspace(byID: personalID, in: context) { return ws }
        let req: NSFetchRequest<Workspace> = Workspace.fetchRequest()
        req.fetchLimit = 1
        req.predicate = NSPredicate(format: "name =[c] %@", WorkspaceSeed.personal.name)
        if let ws = (try? context.fetch(req))?.first, let id = ws.id {
            persistSeedWorkspaceID(id, for: .personal)
            return ws
        }
        return nil
    }

    func isPersonalWorkspace(_ workspace: Workspace) -> Bool {
        guard let id = workspace.id else { return false }
        return id == seedWorkspaceID(for: .personal)
    }

    func colorHex(for workspace: Workspace) -> String {
        if let color = workspace.value(forKey: "color") as? String,
           !color.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return color
        }
        if let id = workspace.id {
            return defaultWorkspaceColorHex(for: id)
        }
        return Self.defaultNewWorkspaceColorHex
    }

    func isWorkspaceNameAvailable(_ name: String, excluding workspace: Workspace?, in context: NSManagedObjectContext) -> Bool {
        !workspaceNameExists(name, excluding: workspace, in: context)
    }

    func activeWorkspacePredicate() -> NSPredicate {
        WorkspaceService.predicate(for: ensureActiveWorkspaceID())
    }

    func activeWorkspacePredicate(for workspaceID: UUID) -> NSPredicate {
        WorkspaceService.predicate(for: workspaceID)
    }

    func combinedPredicate(_ predicate: NSPredicate?, workspaceID: UUID) -> NSPredicate {
        let workspacePredicate = activeWorkspacePredicate(for: workspaceID)
        if let predicate {
            return NSCompoundPredicate(andPredicateWithSubpredicates: [predicate, workspacePredicate])
        }
        return workspacePredicate
    }
}

private extension WorkspaceService {
    func loadActiveWorkspaceID() -> UUID? {
        guard let raw = defaults.string(forKey: defaultsActiveKey),
              let id = UUID(uuidString: raw) else {
            return nil
        }
        return id
    }

    func workspaceNameExists(_ name: String, excluding workspace: Workspace?, in context: NSManagedObjectContext) -> Bool {
        let req: NSFetchRequest<Workspace> = Workspace.fetchRequest()
        req.fetchLimit = 1
        if let workspaceID = workspace?.id {
            req.predicate = NSPredicate(format: "name =[c] %@ AND id != %@", name, workspaceID as CVarArg)
        } else {
            req.predicate = NSPredicate(format: "name =[c] %@", name)
        }
        return ((try? context.fetch(req))?.isEmpty == false)
    }

    func cleanupDuplicateWorkspaces(in context: NSManagedObjectContext) {
        let workspaces = fetchAllWorkspaces(in: context)
        guard !workspaces.isEmpty else { return }

        let personalID = seedWorkspaceID(for: .personal)
        let workID = seedWorkspaceID(for: .work)
        let educationID = seedWorkspaceID(for: .education)
        let seedIDs: [UUID] = [personalID, workID, educationID]
        let seedNameMap: [(String, UUID)] = [
            (WorkspaceSeed.personal.name, personalID),
            (WorkspaceSeed.work.name, workID),
            (WorkspaceSeed.education.name, educationID)
        ]
        let activeID = loadActiveWorkspaceID()
        var deletedIDs = Set<UUID>()
        var didChange = false

        func mergeWorkspaceData(from sourceID: UUID, to targetID: UUID) {
            guard sourceID != targetID else { return }
            let entities = [
                "Budget", "Card", "Income", "PlannedExpense", "UnplannedExpense", "ExpenseCategory"
            ]
            for name in entities {
                let req = NSFetchRequest<NSManagedObject>(entityName: name)
                req.predicate = NSPredicate(format: "workspaceID == %@", sourceID as CVarArg)
                let items = (try? context.fetch(req)) ?? []
                for obj in items {
                    obj.setValue(targetID, forKey: "workspaceID")
                }
                if !items.isEmpty {
                    didChange = true
                }
            }
        }

        // Drop any invalid rows with no ID (cannot be referenced by data).
        for ws in workspaces where ws.id == nil {
            context.delete(ws)
            didChange = true
        }

        // Merge legacy "Default" workspaces into Personal.
        let legacyDefaults = workspaces.filter {
            guard let name = $0.name?.trimmingCharacters(in: .whitespacesAndNewlines),
                  name.caseInsensitiveCompare("Default") == .orderedSame,
                  let id = $0.id else { return false }
            return id != personalID
        }
        for ws in legacyDefaults {
            if let id = ws.id {
                mergeWorkspaceData(from: id, to: personalID)
                deletedIDs.insert(id)
            }
            context.delete(ws)
            didChange = true
        }

        // Merge any seed-name duplicates into their canonical seed IDs.
        for (seedName, seedID) in seedNameMap {
            let matches = workspaces.filter {
                guard let name = $0.name, let id = $0.id else { return false }
                return name.localizedCaseInsensitiveCompare(seedName) == .orderedSame && id != seedID
            }
            for ws in matches {
                if let id = ws.id {
                    mergeWorkspaceData(from: id, to: seedID)
                    deletedIDs.insert(id)
                }
                context.delete(ws)
                didChange = true
            }
        }

        // Dedupe any remaining workspaces with identical IDs.
        let remaining = workspaces.filter { ws in
            if ws.isDeleted { return false }
            guard let id = ws.id else { return false }
            return !deletedIDs.contains(id)
        }
        let grouped = Dictionary(grouping: remaining, by: { $0.id })
        for (_, group) in grouped {
            guard group.count > 1 else { continue }
            let keep = preferredWorkspace(from: group, seedIDs: seedIDs)
            for ws in group where ws.objectID != keep.objectID {
                context.delete(ws)
                didChange = true
            }
        }

        // Ensure seed names are present when missing or legacy.
        if let personal = fetchWorkspace(byID: personalID, in: context) {
            if let name = personal.name?.trimmingCharacters(in: .whitespacesAndNewlines), name.isEmpty || name.caseInsensitiveCompare("Default") == .orderedSame {
                personal.name = WorkspaceSeed.personal.name
                didChange = true
            } else if personal.name == nil {
                personal.name = WorkspaceSeed.personal.name
                didChange = true
            }
        }
        if let work = fetchWorkspace(byID: workID, in: context) {
            if let name = work.name?.trimmingCharacters(in: .whitespacesAndNewlines), name.isEmpty || name.caseInsensitiveCompare("Default") == .orderedSame {
                work.name = WorkspaceSeed.work.name
                didChange = true
            } else if work.name == nil {
                work.name = WorkspaceSeed.work.name
                didChange = true
            }
        }
        if let education = fetchWorkspace(byID: educationID, in: context) {
            if let name = education.name?.trimmingCharacters(in: .whitespacesAndNewlines), name.isEmpty || name.caseInsensitiveCompare("Default") == .orderedSame {
                education.name = WorkspaceSeed.education.name
                didChange = true
            } else if education.name == nil {
                education.name = WorkspaceSeed.education.name
                didChange = true
            }
        }

        if let activeID, deletedIDs.contains(activeID) {
            setActiveWorkspaceID(personalID)
            didChange = true
        }

        if didChange, context.hasChanges {
            try? context.save()
        }
    }

    func preferredWorkspace(from candidates: [Workspace], seedIDs: [UUID]) -> Workspace {
        if let seed = candidates.first(where: { ws in
            guard let id = ws.id else { return false }
            return seedIDs.contains(id)
        }) {
            return seed
        }
        if let named = candidates.first(where: { ws in
            guard let name = ws.name?.trimmingCharacters(in: .whitespacesAndNewlines) else { return false }
            return !name.isEmpty && name.caseInsensitiveCompare("Default") != .orderedSame
        }) {
            return named
        }
        return candidates[0]
    }

    func defaultWorkspaceName(for id: UUID) -> String {
        if let name = seedName(for: id) { return name }
        return "Profile"
    }

    func seedColorHex(for seed: WorkspaceSeed) -> String {
        switch seed {
        case .personal:
            return "#6EB0E7"
        case .work:
            return "#152F4B"
        case .education:
            return "#D7C893"
        }
    }

    func defaultWorkspaceColorHex(for id: UUID) -> String {
        for seed in WorkspaceSeed.allCases where seedWorkspaceID(for: seed) == id {
            return seedColorHex(for: seed)
        }
        return Self.defaultNewWorkspaceColorHex
    }

    func applySeedColorIfNeeded(_ workspace: Workspace, seed: WorkspaceSeed) {
        guard workspace.entity.attributesByName.keys.contains("color") else { return }
        let existing = (workspace.value(forKey: "color") as? String)?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard existing.isEmpty else { return }
        workspace.setValue(seedColorHex(for: seed), forKey: "color")
    }

    func ensureDefaultWorkspaces(in context: NSManagedObjectContext) -> [Workspace] {
        var existing = fetchAllWorkspaces(in: context)

        for seed in WorkspaceSeed.allCases {
            let seedID = seedWorkspaceID(for: seed)
            if let matched = existing.first(where: { $0.id == seedID }) {
                applySeedColorIfNeeded(matched, seed: seed)
                continue
            }

            if let byName = existing.first(where: { ($0.name ?? "").localizedCaseInsensitiveCompare(seed.name) == .orderedSame }) {
                if let id = byName.id {
                    persistSeedWorkspaceID(id, for: seed)
                }
                applySeedColorIfNeeded(byName, seed: seed)
                continue
            }

            let ws = Workspace(context: context)
            ws.id = seedID
            ws.name = seed.name
            if ws.entity.attributesByName.keys.contains("isCloud") {
                ws.isCloud = cloudEnabled
            }
            if ws.entity.attributesByName.keys.contains("color") {
                ws.setValue(seedColorHex(for: seed), forKey: "color")
            }
            existing.append(ws)
        }

        if context.hasChanges {
            try? context.save()
        }
        return existing
    }

    func seedWorkspaceID(for seed: WorkspaceSeed) -> UUID {
        if let stored = readSeedWorkspaceID(for: seed) { return stored }

        if seed == .personal, let legacy = legacyActiveWorkspaceID() {
            persistSeedWorkspaceID(legacy, for: seed)
            return legacy
        }

        let fresh = UUID()
        persistSeedWorkspaceID(fresh, for: seed)
        return fresh
    }

    func readSeedWorkspaceID(for seed: WorkspaceSeed) -> UUID? {
        let key = seed.defaultsKey
        if cloudEnabled {
            if let raw = CloudStateFacade.string(forKey: key), let id = UUID(uuidString: raw) {
                defaults.set(raw, forKey: key)
                return id
            }
        }
        if let raw = defaults.string(forKey: key), let id = UUID(uuidString: raw) {
            return id
        }
        return nil
    }

    func seedName(for id: UUID) -> String? {
        for seed in WorkspaceSeed.allCases {
            if readSeedWorkspaceID(for: seed) == id {
                return seed.name
            }
        }
        return nil
    }

    func persistSeedWorkspaceID(_ id: UUID, for seed: WorkspaceSeed) {
        let raw = id.uuidString
        let key = seed.defaultsKey
        defaults.set(raw, forKey: key)
        if cloudEnabled {
            CloudStateFacade.set(raw, forKey: key)
            CloudStateFacade.synchronize()
        }
    }

    func legacyActiveWorkspaceID() -> UUID? {
        if cloudEnabled {
            if let raw = CloudStateFacade.string(forKey: ubiquitousKey), let id = UUID(uuidString: raw) {
                defaults.set(raw, forKey: defaultsCloudKey)
                return id
            }
            if let raw = defaults.string(forKey: defaultsCloudKey), let id = UUID(uuidString: raw) {
                return id
            }
        }
        if let raw = defaults.string(forKey: defaultsLocalKey), let id = UUID(uuidString: raw) {
            return id
        }
        return nil
    }
}

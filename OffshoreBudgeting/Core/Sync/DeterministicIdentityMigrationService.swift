import CoreData
import Foundation

// MARK: - DeterministicIdentityMigrationService
/// One-time maintenance job that:
/// - canonicalizes IDs (deterministic UUIDs) for Cards, Categories, Budgets, and Preset templates
/// - collapses duplicates that share the same canonical identity
/// - rewrites Preset child links (globalTemplateID) when template IDs change
///
/// This is intended to reduce duplicates that appear when previously-local datasets are later merged via Cloud sync.
final class DeterministicIdentityMigrationService {
    static let shared = DeterministicIdentityMigrationService()

    private init() {}

    private let doneKey = "migration.deterministicIDs.v1.done"
    private let lockKey = "migration.deterministicIDs.v1.lock"
    private let lockTimestampKey = "migration.deterministicIDs.v1.lockedAt"
    private let deviceIDKey = "migration.device.installID"

    func runIfNeeded(reason: String = "app-launch") async {
        if isDone() { return }
        guard acquireLockIfPossible() else { return }
        defer { releaseLock() }

        await CoreDataService.shared.waitUntilStoresLoaded(timeout: 15.0)
        let bg = CoreDataService.shared.newBackgroundContext()

        var cardIDMap: [UUID: UUID] = [:]

        do {
            try await bg.perform {
                let workspaceIDs = Self.fetchWorkspaceIDs(in: bg)
                for workspaceID in workspaceIDs {
                    try Self.canonicalizeCategories(in: bg, workspaceID: workspaceID)
                    try Self.canonicalizeCards(in: bg, workspaceID: workspaceID, cardIDMap: &cardIDMap)
                    try Self.canonicalizeBudgets(in: bg, workspaceID: workspaceID)
                    try Self.canonicalizePresetTemplates(in: bg, workspaceID: workspaceID)
                }

                if bg.hasChanges {
                    try bg.save()
                }
            }

            if !cardIDMap.isEmpty {
                let stringMap = Dictionary(uniqueKeysWithValues: cardIDMap.map { ($0.key.uuidString, $0.value.uuidString) })
                WidgetSharedStore.migrateCardWidgetSnapshots(cardIDMap: stringMap)
            }

            markDone()
            if AppLog.isVerbose {
                AppLog.iCloud.info("Deterministic identity migration complete (\(reason))")
            }
        } catch {
            if AppLog.isVerbose {
                AppLog.iCloud.error("Deterministic identity migration failed (\(reason)): \(String(describing: error))")
            }
        }
    }

    // MARK: - Locking / Flags
    private func isDone() -> Bool {
        if UserDefaults.standard.bool(forKey: doneKey) { return true }
        if CloudStateFacade.bool(forKey: doneKey) { return true }
        return false
    }

    private func markDone() {
        UserDefaults.standard.set(true, forKey: doneKey)
        UserDefaults.standard.synchronize()
        CloudStateFacade.set(true, forKey: doneKey)
        CloudStateFacade.synchronize()
    }

    private func deviceInstallID() -> String {
        if let existing = UserDefaults.standard.string(forKey: deviceIDKey), !existing.isEmpty {
            return existing
        }
        let id = UUID().uuidString
        UserDefaults.standard.set(id, forKey: deviceIDKey)
        UserDefaults.standard.synchronize()
        return id
    }

    private func acquireLockIfPossible() -> Bool {
        let now = Date().timeIntervalSince1970
        let ttl: TimeInterval = 12 * 60

        let existingTSString = CloudStateFacade.string(forKey: lockTimestampKey)
        let existingTS = existingTSString.flatMap(Double.init)

        if let existingTS, now - existingTS < ttl {
            // Someone else is migrating right now.
            return false
        }

        let owner = deviceInstallID()
        CloudStateFacade.set(owner, forKey: lockKey)
        CloudStateFacade.set(String(now), forKey: lockTimestampKey)
        CloudStateFacade.synchronize()

        // Best-effort verification (KVS is eventually consistent).
        let confirmedOwner = CloudStateFacade.string(forKey: lockKey)
        return confirmedOwner == owner
    }

    private func releaseLock() {
        CloudStateFacade.set(nil, forKey: lockKey)
        CloudStateFacade.set(nil, forKey: lockTimestampKey)
        CloudStateFacade.synchronize()
    }
}

// MARK: - Core Canonicalization
private extension DeterministicIdentityMigrationService {
    static func fetchWorkspaceIDs(in context: NSManagedObjectContext) -> [UUID] {
        let req = NSFetchRequest<NSManagedObject>(entityName: "Workspace")
        let rows = (try? context.fetch(req)) ?? []
        let ids = rows.compactMap { $0.value(forKey: "id") as? UUID }
        return ids.isEmpty ? [WorkspaceService.activeWorkspaceIDFromDefaults() ?? UUID()] : Array(Set(ids))
    }

    static func canonicalizeCards(in context: NSManagedObjectContext, workspaceID: UUID, cardIDMap: inout [UUID: UUID]) throws {
        let req = NSFetchRequest<Card>(entityName: "Card")
        req.predicate = WorkspaceService.predicate(for: workspaceID)
        let cards = (try? context.fetch(req)) ?? []

        let groups = Dictionary(grouping: cards) { card -> UUID in
            let name = (card.name ?? "")
            return DeterministicID.cardID(workspaceID: workspaceID, name: name)
        }

        for (desiredID, group) in groups {
            guard !group.isEmpty else { continue }
            let keeper = preferredRecord(in: group, desiredID: desiredID) { $0.value(forKey: "id") as? UUID }

            let oldID = keeper.value(forKey: "id") as? UUID
            if oldID != desiredID {
                keeper.setValue(desiredID, forKey: "id")
                if let oldID {
                    cardIDMap[oldID] = desiredID
                }
            }

            for dup in group where dup.objectID != keeper.objectID {
                // Merge budgets (many-to-many)
                if let budgets = dup.budget as? Set<Budget>, !budgets.isEmpty {
                    let set = keeper.mutableSetValue(forKey: "budget")
                    budgets.forEach { set.add($0) }
                }

                // Repoint expenses to keeper
                let plannedReq = NSFetchRequest<PlannedExpense>(entityName: "PlannedExpense")
                plannedReq.predicate = NSPredicate(format: "card == %@", dup)
                let planned = (try? context.fetch(plannedReq)) ?? []
                planned.forEach { $0.card = keeper }

                let unplannedReq = NSFetchRequest<UnplannedExpense>(entityName: "UnplannedExpense")
                unplannedReq.predicate = NSPredicate(format: "card == %@", dup)
                let unplanned = (try? context.fetch(unplannedReq)) ?? []
                unplanned.forEach { $0.card = keeper }

                context.delete(dup)
            }
        }
    }

    static func canonicalizeCategories(in context: NSManagedObjectContext, workspaceID: UUID) throws {
        let req = NSFetchRequest<ExpenseCategory>(entityName: "ExpenseCategory")
        req.predicate = WorkspaceService.predicate(for: workspaceID)
        let categories = (try? context.fetch(req)) ?? []

        let groups = Dictionary(grouping: categories) { category -> UUID in
            let name = (category.name ?? "")
            return DeterministicID.categoryID(workspaceID: workspaceID, name: name)
        }

        for (desiredID, group) in groups {
            guard !group.isEmpty else { continue }
            let keeper = preferredRecord(in: group, desiredID: desiredID) { $0.value(forKey: "id") as? UUID }

            if (keeper.value(forKey: "id") as? UUID) != desiredID {
                keeper.setValue(desiredID, forKey: "id")
            }

            for dup in group where dup.objectID != keeper.objectID {
                let plannedReq = NSFetchRequest<PlannedExpense>(entityName: "PlannedExpense")
                plannedReq.predicate = NSPredicate(format: "expenseCategory == %@", dup)
                let planned = (try? context.fetch(plannedReq)) ?? []
                planned.forEach { $0.expenseCategory = keeper }

                let unplannedReq = NSFetchRequest<UnplannedExpense>(entityName: "UnplannedExpense")
                unplannedReq.predicate = NSPredicate(format: "expenseCategory == %@", dup)
                let unplanned = (try? context.fetch(unplannedReq)) ?? []
                unplanned.forEach { $0.expenseCategory = keeper }

                let capReq = NSFetchRequest<CategorySpendingCap>(entityName: "CategorySpendingCap")
                capReq.predicate = NSPredicate(format: "category == %@", dup)
                let caps = (try? context.fetch(capReq)) ?? []
                caps.forEach { $0.category = keeper }

                context.delete(dup)
            }
        }
    }

    static func canonicalizeBudgets(in context: NSManagedObjectContext, workspaceID: UUID) throws {
        let req = NSFetchRequest<Budget>(entityName: "Budget")
        req.predicate = WorkspaceService.predicate(for: workspaceID)
        let budgets = (try? context.fetch(req)) ?? []

        let groups = Dictionary(grouping: budgets) { budget -> UUID? in
            guard let s = budget.startDate, let e = budget.endDate else { return nil }
            return DeterministicID.budgetID(workspaceID: workspaceID, startDate: s, endDate: e)
        }

        for (desiredIDOpt, group) in groups {
            guard let desiredID = desiredIDOpt else { continue }
            guard !group.isEmpty else { continue }
            let keeper = preferredRecord(in: group, desiredID: desiredID) { $0.value(forKey: "id") as? UUID }

            if (keeper.value(forKey: "id") as? UUID) != desiredID {
                keeper.setValue(desiredID, forKey: "id")
            }

            for dup in group where dup.objectID != keeper.objectID {
                // Merge cards (many-to-many)
                if let cards = dup.cards as? Set<Card>, !cards.isEmpty {
                    let set = keeper.mutableSetValue(forKey: "cards")
                    cards.forEach { set.add($0) }
                }

                // Repoint planned expenses to keeper
                let plannedReq = NSFetchRequest<PlannedExpense>(entityName: "PlannedExpense")
                plannedReq.predicate = NSPredicate(format: "budget == %@", dup)
                let planned = (try? context.fetch(plannedReq)) ?? []
                planned.forEach { $0.budget = keeper }

                context.delete(dup)
            }
        }
    }

    static func canonicalizePresetTemplates(in context: NSManagedObjectContext, workspaceID: UUID) throws {
        let req = NSFetchRequest<PlannedExpense>(entityName: "PlannedExpense")
        req.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
            NSPredicate(format: "isGlobal == YES"),
            WorkspaceService.predicate(for: workspaceID)
        ])
        let templates = (try? context.fetch(req)) ?? []

        let groups = Dictionary(grouping: templates) { template -> UUID in
            let title = (template.descriptionText ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
            let planned = template.plannedAmount
            let categoryID = template.expenseCategory?.id ?? (template.expenseCategory?.value(forKey: "id") as? UUID)
            let cardID = (template.card?.value(forKey: "id") as? UUID)
            return DeterministicID.presetTemplateID(
                workspaceID: workspaceID,
                title: title,
                plannedAmount: planned,
                categoryID: categoryID,
                cardID: cardID
            )
        }

        for (desiredID, group) in groups {
            guard !group.isEmpty else { continue }
            let keeper = preferredRecord(in: group, desiredID: desiredID) { $0.value(forKey: "id") as? UUID }

            let oldKeeperID = keeper.id
            if oldKeeperID != desiredID {
                keeper.id = desiredID
            }

            if let oldKeeperID, oldKeeperID != desiredID {
                rewritePresetLinks(in: context, workspaceID: workspaceID, from: oldKeeperID, to: desiredID)
            }

            for dup in group where dup.objectID != keeper.objectID {
                if let oldID = dup.id {
                    rewritePresetLinks(in: context, workspaceID: workspaceID, from: oldID, to: desiredID)
                }
                context.delete(dup)
            }
        }
    }

    static func rewritePresetLinks(in context: NSManagedObjectContext, workspaceID: UUID, from oldID: UUID, to newID: UUID) {
        let childReq = NSFetchRequest<PlannedExpense>(entityName: "PlannedExpense")
        childReq.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
            NSPredicate(format: "isGlobal == NO"),
            NSPredicate(format: "globalTemplateID == %@", oldID as CVarArg),
            WorkspaceService.predicate(for: workspaceID)
        ])
        let children = (try? context.fetch(childReq)) ?? []
        children.forEach { $0.globalTemplateID = newID }
    }

    static func preferredRecord<T: NSManagedObject>(
        in records: [T],
        desiredID: UUID,
        idProvider: (T) -> UUID?
    ) -> T {
        if let exact = records.first(where: { idProvider($0) == desiredID }) {
            return exact
        }
        // Stable fallback: keep the lexicographically smallest UUID to make results deterministic.
        return records.min { a, b in
            let au = idProvider(a)?.uuidString ?? ""
            let bu = idProvider(b)?.uuidString ?? ""
            return au < bu
        } ?? records[0]
    }
}

//
//  MergeService.swift
//  Offshore
//

import Foundation
import CoreData

// MARK: - MergeService
/// Performs a conservative merge that collapses likely-duplicate records after
/// enabling iCloud on a device that already had local data. This is a stepping
/// stone toward a full Workspace-based merge; it avoids modifying fetch logic.
@MainActor
final class MergeService {
    // MARK: Shared
    static let shared = MergeService()

    // MARK: Init
    private init() {}

    // MARK: Public API
    func mergeLocalDataIntoCloud() throws {
        let ctx = CoreDataService.shared.viewContext
        var didChange = false

        // Safety: When Cloud sync is enabled, avoid destructive dedupe since
        // deletions will propagate to iCloud and other devices. Let Core Data
        // mirroring upload local records and rely on manual review for
        // duplicates. We can add a preview-based dedupe later.
        if UserDefaultsAppSettingsStore().bool(for: .enableCloudSync) ?? false {
            // Under cloud sync, perform only a strict, safe dedupe for template children
            // scoped to (workspaceID, budget, globalTemplateID).
            didChange = try mergeStrictTemplateChildren(ctx) || didChange
            if didChange { try ctx.save() }
            return
        }

        // Order matters a bit: collapse leaf types before parents when possible.
        didChange = try mergeExpenseCategories(ctx) || didChange
        didChange = try mergeCards(ctx) || didChange
        didChange = try mergeBudgets(ctx) || didChange
        didChange = try mergeIncomes(ctx) || didChange
        didChange = try mergePlannedExpenses(ctx) || didChange
        didChange = try mergeUnplannedExpenses(ctx) || didChange

        if didChange {
            try ctx.save()
            NotificationCenter.default.post(name: .dataStoreDidChange, object: nil)
        }
    }

    // MARK: - Entity Mergers

    private func mergeExpenseCategories(_ ctx: NSManagedObjectContext) throws -> Bool {
        let req: NSFetchRequest<ExpenseCategory> = ExpenseCategory.fetchRequest()
        let categories = try ctx.fetch(req)
        var seen = Set<String>()
        var changed = false
        for cat in categories {
            let name = (cat.name ?? "").trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            guard !name.isEmpty else { continue }
            let ws = (cat.value(forKey: "workspaceID") as? UUID)?.uuidString ?? "nil"
            let key = ws + "|" + name
            if seen.contains(key) {
                ctx.delete(cat)
                changed = true
            } else {
                seen.insert(key)
            }
        }
        return changed
    }

    private func mergeCards(_ ctx: NSManagedObjectContext) throws -> Bool {
        let req: NSFetchRequest<Card> = Card.fetchRequest()
        let cards = try ctx.fetch(req)
        var seen = Set<String>()
        var changed = false
        for card in cards {
            let ws = (card.value(forKey: "workspaceID") as? UUID)?.uuidString ?? "nil"
            let key = (card.name ?? "").trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            guard !key.isEmpty else { continue }
            let sig = ws + "|" + key
            if seen.contains(sig) {
                ctx.delete(card)
                changed = true
            } else {
                seen.insert(sig)
            }
        }
        return changed
    }

    private func mergeBudgets(_ ctx: NSManagedObjectContext) throws -> Bool {
        let req: NSFetchRequest<Budget> = Budget.fetchRequest()
        let budgets = try ctx.fetch(req)
        var seen = Set<String>()
        var changed = false
        for b in budgets {
            let ws = (b.value(forKey: "workspaceID") as? UUID)?.uuidString ?? "nil"
            let n = (b.name ?? "").trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            let s = b.startDate?.startOfDay ?? .distantPast
            let e = b.endDate?.startOfDay ?? .distantPast
            let key = "\(ws)|\(n)|\(s.timeIntervalSince1970)|\(e.timeIntervalSince1970)"
            if seen.contains(key) {
                ctx.delete(b)
                changed = true
            } else {
                seen.insert(key)
            }
        }
        return changed
    }

    private func mergeIncomes(_ ctx: NSManagedObjectContext) throws -> Bool {
        let req: NSFetchRequest<Income> = Income.fetchRequest()
        let incomes = try ctx.fetch(req)
        var seen = Set<String>()
        var changed = false
        for inc in incomes {
            let ws = (inc.value(forKey: "workspaceID") as? UUID)?.uuidString ?? "nil"
            let day = (inc.date ?? Date.distantPast).startOfDay
            let src = (inc.source ?? "").trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            let planned = inc.isPlanned
            let amt = (inc.amount as NSNumber).roundedTwoDecimals
            let key = "\(ws)|\(day.timeIntervalSince1970)|\(src)|\(planned ? 1 : 0)|\(amt)"
            if seen.contains(key) {
                ctx.delete(inc)
                changed = true
            } else {
                seen.insert(key)
            }
        }
        return changed
    }

    private func mergePlannedExpenses(_ ctx: NSManagedObjectContext) throws -> Bool {
        let req: NSFetchRequest<PlannedExpense> = PlannedExpense.fetchRequest()
        let items = try ctx.fetch(req)
        var seen = Set<String>()
        var changed = false
        for p in items {
            let ws = (p.value(forKey: "workspaceID") as? UUID)?.uuidString ?? "nil"
            let day = (p.transactionDate ?? Date.distantPast).startOfDay
            let desc = (p.descriptionText ?? "").trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            let amt = (p.plannedAmount as NSNumber).roundedTwoDecimals
            let cardRef = p.card?.objectID.uriRepresentation().absoluteString ?? "nil"
            let catRef = p.expenseCategory?.objectID.uriRepresentation().absoluteString ?? "nil"
            let key = "\(ws)|\(day.timeIntervalSince1970)|\(amt)|\(desc)|\(cardRef)|\(catRef)"
            if seen.contains(key) {
                ctx.delete(p)
                changed = true
            } else {
                seen.insert(key)
            }
        }
        return changed
    }

    /// Strictly deduplicates non-global PlannedExpense children that reference the same
    /// template (globalTemplateID) in the same budget. Keeps the record with the highest
    /// actualAmount to preserve any recorded spend; ties break by latest transactionDate.
    private func mergeStrictTemplateChildren(_ ctx: NSManagedObjectContext) throws -> Bool {
        let req: NSFetchRequest<PlannedExpense> = PlannedExpense.fetchRequest()
        // Only non-global with a template link
        req.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
            NSPredicate(format: "isGlobal == NO"),
            NSPredicate(format: "globalTemplateID != nil")
        ])
        let items = try ctx.fetch(req)
        // Group by (workspaceID | budgetRef | templateID)
        var buckets: [String: [PlannedExpense]] = [:]
        for p in items {
            guard let budget = p.budget, let templateID = p.globalTemplateID else { continue }
            let ws = (p.value(forKey: "workspaceID") as? UUID)?.uuidString
                ?? (budget.value(forKey: "workspaceID") as? UUID)?.uuidString
                ?? "nil"
            let budgetRef = budget.objectID.uriRepresentation().absoluteString
            let key = "\(ws)|\(budgetRef)|\(templateID.uuidString)"
            buckets[key, default: []].append(p)
        }

        var changed = false
        for (_, group) in buckets where group.count > 1 {
            // Choose the best to keep
            let keep = group.max { a, b in
                if a.actualAmount == b.actualAmount {
                    let ad = a.transactionDate ?? .distantPast
                    let bd = b.transactionDate ?? .distantPast
                    return ad < bd
                }
                return a.actualAmount < b.actualAmount
            }
            for item in group {
                if item != keep {
                    ctx.delete(item)
                    changed = true
                }
            }
        }
        return changed
    }

    private func mergeUnplannedExpenses(_ ctx: NSManagedObjectContext) throws -> Bool {
        let req: NSFetchRequest<UnplannedExpense> = UnplannedExpense.fetchRequest()
        let items = try ctx.fetch(req)
        var seen = Set<String>()
        var changed = false
        for u in items {
            let ws = (u.value(forKey: "workspaceID") as? UUID)?.uuidString ?? "nil"
            let day = (u.transactionDate ?? Date.distantPast).startOfDay
            let desc = (u.descriptionText ?? "").trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            let amt = (u.amount as NSNumber).roundedTwoDecimals
            let cardRef = u.card?.objectID.uriRepresentation().absoluteString ?? "nil"
            let catRef = u.expenseCategory?.objectID.uriRepresentation().absoluteString ?? "nil"
            let key = "\(ws)|\(day.timeIntervalSince1970)|\(amt)|\(desc)|\(cardRef)|\(catRef)"
            if seen.contains(key) {
                ctx.delete(u)
                changed = true
            } else {
                seen.insert(key)
            }
        }
        return changed
    }
}

private extension Date {
    var startOfDay: Date { Calendar.current.startOfDay(for: self) }
}

private extension NSNumber {
    var roundedTwoDecimals: String {
        let v = self.doubleValue
        // Round to cents deterministically for signature
        let rounded = (v * 100.0).rounded() / 100.0
        return String(format: "%.2f", rounded)
    }
}

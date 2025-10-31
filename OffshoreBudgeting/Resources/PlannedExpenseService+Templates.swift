//
//  PlannedExpenseService+Templates.swift
//  SoFar
//
//  Created by Michael Brown on 8/14/25.
//

import Foundation
import CoreData

// MARK: - PlannedExpenseService + Templates
/// Template (global planned expense) helpers used by PresetsView.
/// This extends your existing service (no extra class here).
extension PlannedExpenseService {

    // MARK: Date Alignment
    private func alignedTransactionDate(for template: PlannedExpense, budget: Budget) -> Date? {
        guard let budgetStart = budget.startDate else {
            return template.transactionDate ?? budget.startDate
        }

        let calendar = Calendar.current
        let templateDate = template.transactionDate ?? budgetStart

        var components = calendar.dateComponents([.year, .month, .day, .hour, .minute, .second, .nanosecond], from: budgetStart)

        let templateComponents = calendar.dateComponents([.day, .hour, .minute, .second, .nanosecond], from: templateDate)
        if let day = templateComponents.day {
            components.day = day
        }
        if let hour = templateComponents.hour {
            components.hour = hour
        }
        if let minute = templateComponents.minute {
            components.minute = minute
        }
        if let second = templateComponents.second {
            components.second = second
        }
        if let nanosecond = templateComponents.nanosecond {
            components.nanosecond = nanosecond
        }

        let candidate = calendar.date(from: components) ?? budgetStart
        var aligned = candidate

        if aligned < budgetStart {
            aligned = budgetStart
        }

        if let budgetEnd = budget.endDate, aligned > budgetEnd {
            aligned = budgetEnd
        }

        return aligned
    }

    // MARK: Fetch Global Templates
    /// Returns all PlannedExpense where isGlobal == true.
    /// - Parameter context: NSManagedObjectContext
    /// - Returns: [PlannedExpense]
    func fetchGlobalTemplates(in context: NSManagedObjectContext) -> [PlannedExpense] {
        let request: NSFetchRequest<PlannedExpense> = PlannedExpense.fetchRequest()
        request.predicate = NSPredicate(format: "isGlobal == YES")
        request.sortDescriptors = [
            NSSortDescriptor(keyPath: \PlannedExpense.descriptionText, ascending: true)
        ]
        do {
            return try context.fetch(request)
        } catch {
            AppLog.service.error("fetchGlobalTemplates error: \(String(describing: error))")
            return []
        }
    }

    // MARK: Fetch Children
    /// Fetches non-global PlannedExpense children that reference a template via globalTemplateID.
    /// - Parameters:
    ///   - template: The global PlannedExpense template.
    ///   - context: NSManagedObjectContext
    func fetchChildren(of template: PlannedExpense, in context: NSManagedObjectContext) -> [PlannedExpense] {
        guard let templateID = template.id else { return [] }
        let request: NSFetchRequest<PlannedExpense> = PlannedExpense.fetchRequest()
        request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
            NSPredicate(format: "isGlobal == NO"),
            NSPredicate(format: "globalTemplateID == %@", templateID as CVarArg)
        ])
        do {
            return try context.fetch(request)
        } catch {
            AppLog.service.error("fetchChildren error: \(String(describing: error))")
            return []
        }
    }

    // MARK: Ensure Child (Assign)
    /// Ensures a child PlannedExpense exists for the given budget, copying fields from the template.
    /// - Parameters:
    ///   - template: Global template.
    ///   - budget: Target budget.
    ///   - context: NSManagedObjectContext.
    /// - Returns: The child record (new or existing).
    @discardableResult
    func ensureChild(from template: PlannedExpense,
                     attachedTo budget: Budget,
                     in context: NSManagedObjectContext) -> PlannedExpense {
        // First, collapse any accidental duplicates for this template+budget pair.
        if let templateID = template.id {
            let req: NSFetchRequest<PlannedExpense> = PlannedExpense.fetchRequest()
            req.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
                NSPredicate(format: "isGlobal == NO"),
                NSPredicate(format: "budget == %@", budget),
                NSPredicate(format: "globalTemplateID == %@", templateID as CVarArg)
            ])
            if let matches = try? context.fetch(req), matches.count > 1 {
                // Prefer keeping the one with the greatest actualAmount (preserves recorded spend)
                let keep = matches.max(by: { $0.actualAmount < $1.actualAmount })
                for m in matches {
                    if m != keep { context.delete(m) }
                }
                if context.hasChanges {
                    do { try context.save() } catch {
                        AppLog.service.error("ensureChild dedupe save error: \(String(describing: error))")
                    }
                }
            }
        }

        if let existing = child(of: template, for: budget, in: context) {
            let correctedDate = alignedTransactionDate(for: template, budget: budget)

            var didUpdate = false
            if let correctedDate {
                if let currentDate = existing.transactionDate {
                    var needsCorrection = false
                    if let startDate = budget.startDate, currentDate < startDate {
                        needsCorrection = true
                    }
                    if let endDate = budget.endDate, currentDate > endDate {
                        needsCorrection = true
                    }

                    if needsCorrection {
                        existing.transactionDate = correctedDate
                        didUpdate = true
                    }
                } else {
                    existing.transactionDate = correctedDate
                    didUpdate = true
                }
            }

            if didUpdate, context.hasChanges {
                do {
                    try context.save()
                } catch {
                    AppLog.service.error("ensureChild save error: \(String(describing: error))")
                }
            }

            return existing
        }

        let child = PlannedExpense(context: context)
        child.id = UUID()
        child.descriptionText = template.descriptionText
        child.plannedAmount = template.plannedAmount
        child.actualAmount = template.actualAmount
        // Use the template's transactionDate as a default due date if present; otherwise, align to budget start.
        child.transactionDate = alignedTransactionDate(for: template, budget: budget)
            ?? template.transactionDate
            ?? budget.startDate
            ?? Date()
        child.isGlobal = false
        child.globalTemplateID = template.id
        child.budget = budget
        child.card = template.card
        child.expenseCategory = template.expenseCategory
        // Propagate workspace from template or budget if available
        if let ws = (template.value(forKey: "workspaceID") as? UUID)
            ?? (budget.value(forKey: "workspaceID") as? UUID) {
            child.setValue(ws, forKey: "workspaceID")
        }

        return child
    }

    // MARK: Remove Child (Unassign)
    /// Removes a child PlannedExpense created from the template for a specific budget.
    func removeChild(from template: PlannedExpense,
                     for budget: Budget,
                     in context: NSManagedObjectContext) {
        guard let target = child(of: template, for: budget, in: context) else { return }
        context.delete(target)
    }

    // MARK: Child Lookup
    /// Returns the child PlannedExpense for a specific budget if it exists.
    func child(of template: PlannedExpense,
               for budget: Budget,
               in context: NSManagedObjectContext) -> PlannedExpense? {
        guard let templateID = template.id else { return nil }
        let request: NSFetchRequest<PlannedExpense> = PlannedExpense.fetchRequest()
        request.fetchLimit = 1
        request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
            NSPredicate(format: "isGlobal == NO"),
            NSPredicate(format: "budget == %@", budget),
            NSPredicate(format: "globalTemplateID == %@", templateID as CVarArg)
        ])
        do {
            return try context.fetch(request).first
        } catch {
            AppLog.service.error("child(of:for:) error: \(String(describing: error))")
            return nil
        }
    }

    // MARK: Fetch Budgets (helper)
    /// Returns all budgets sorted by start date descending.
    func fetchAllBudgets(in context: NSManagedObjectContext) -> [Budget] {
        let request: NSFetchRequest<Budget> = Budget.fetchRequest()
        request.sortDescriptors = [
            NSSortDescriptor(keyPath: \Budget.startDate, ascending: false)
        ]
        do {
            return try context.fetch(request)
        } catch {
            AppLog.service.error("fetchAllBudgets error: \(String(describing: error))")
            return []
        }
    }

    // MARK: Delete Template + Children
    /// Deletes a global template and any children linked to it.
    func deleteTemplateAndChildren(template: PlannedExpense, in context: NSManagedObjectContext) throws {
        let kids = fetchChildren(of: template, in: context)
        for k in kids {
            context.delete(k)
        }
        context.delete(template)

        if context.hasChanges {
            try context.save()
        }
    }

    // MARK: Update Template Hierarchy
    /// Applies updates to a template hierarchy using the provided propagation scope.
    /// - Parameters:
    ///   - expense: The expense that was directly edited (template or child).
    ///   - scope: Determines which related records should also be updated.
    ///   - title: Optional replacement description/title.
    ///   - plannedAmount: Optional planned amount to apply.
    ///   - actualAmount: Optional actual amount to apply.
    ///   - transactionDate: Optional transaction date to apply.
    ///   - context: Managed object context for fetches.
    func updateTemplateHierarchy(for expense: PlannedExpense,
                                scope: PlannedExpenseUpdateScope,
                                title: String? = nil,
                                plannedAmount: Double? = nil,
                                actualAmount: Double? = nil,
                                transactionDate: Date? = nil,
                                in context: NSManagedObjectContext) {
        let template: PlannedExpense?
        if expense.isGlobal {
            template = expense
        } else if let templateID = expense.globalTemplateID {
            template = fetchTemplate(withID: templateID, in: context)
        } else {
            template = nil
        }

        let fallbackReferenceDate = scope.referenceDate ?? expense.transactionDate

        func applyUpdates(to target: PlannedExpense) {
            if let title { target.descriptionText = title }
            if let plannedAmount { target.plannedAmount = plannedAmount }
            if let actualAmount { target.actualAmount = actualAmount }
            if let transactionDate { target.transactionDate = transactionDate }
        }

        applyUpdates(to: expense)

        if let template, template != expense, scope.includesTemplate {
            applyUpdates(to: template)
        }

        guard let template else { return }
        let children = fetchChildren(of: template, in: context)
        for child in children {
            if child == expense { continue }
            if scope.shouldIncludeChild(with: child.transactionDate, fallbackReferenceDate: fallbackReferenceDate) {
                applyUpdates(to: child)
            }
        }
    }

    private func fetchTemplate(withID id: UUID, in context: NSManagedObjectContext) -> PlannedExpense? {
        let request: NSFetchRequest<PlannedExpense> = PlannedExpense.fetchRequest()
        request.fetchLimit = 1
        request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
            NSPredicate(format: "id == %@", id as CVarArg),
            NSPredicate(format: "isGlobal == YES")
        ])
        return try? context.fetch(request).first
    }
}

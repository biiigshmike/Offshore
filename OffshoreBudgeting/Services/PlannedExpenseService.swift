//
//  PlannedExpenseService.swift
//  SoFar
//
//  Purpose:
//  - CRUD for PlannedExpense entities (Budget ↔ PlannedExpense is to-one from expense to budget)
//  - Query helpers (by budget, by date range, totals)
//  - Global template helpers (create template; instantiate into a budget)
//  - Future-proofing: never touch `.id` directly; use KVC for 'id' and for 'title' vs 'descriptionText' drift.
//
//  Model expectations (from your snapshot):
//    PlannedExpense:
//      id: UUID
//      descriptionText (String) OR title (String)   // schema drift; we support either via KVC
//      plannedAmount: Double
//      actualAmount: Double
//      transactionDate: Date
//      isGlobal: Bool
//      globalTemplateID: UUID?
//      budget: Budget (to-one)
//
//  Notes:
//  - Sorting uses string keys to avoid compile-time keypath issues.
//  - Predicates use literal "id" / "budget.id" to avoid Identifiable collisions.
//  - For templates: `isGlobal == true` marks a reusable template. Instantiated copies set
//    `isGlobal = false` and `globalTemplateID = template.id`.
//

import Foundation
import CoreData

// MARK: - PlannedExpenseServiceError
/// Errors specific to PlannedExpense operations.
enum PlannedExpenseServiceError: Error {
    case budgetNotFound(UUID)
    case templateNotGlobal
}

// MARK: - PlannedExpenseService
/// Public API for managing `PlannedExpense` entities.
final class PlannedExpenseService {
    
    // MARK: Singleton (for convenience across SwiftUI)
    /// Global access used by views like PresetsView.
    static let shared = PlannedExpenseService()
    
    // MARK: Properties
    private let expenseRepo: CoreDataRepository<PlannedExpense>
    private let budgetRepo: CoreDataRepository<Budget>
    
    // MARK: Init
    /// Initialize with an optional custom Core Data stack (useful for tests).
    init(stack: CoreDataStackProviding = CoreDataService.shared) {
        self.expenseRepo = CoreDataRepository<PlannedExpense>(stack: stack)
        self.budgetRepo  = CoreDataRepository<Budget>(stack: stack)
    }
    
    // MARK: - FETCH
    
    // MARK: fetchAll(sortedByDateAscending:)
    /// Fetch all planned expenses in the store.
    /// - Parameter sortedByDateAscending: If true (default), sort by `transactionDate` ascending.
    /// - Returns: Array of PlannedExpense.
    func fetchAll(sortedByDateAscending: Bool = true) throws -> [PlannedExpense] {
        let sort = NSSortDescriptor(key: "transactionDate", ascending: sortedByDateAscending)
        if let workspaceID = WorkspaceService.activeWorkspaceIDFromDefaults() {
            let predicate = WorkspaceService.predicate(for: workspaceID)
            return try expenseRepo.fetchAll(predicate: predicate, sortDescriptors: [sort])
        }
        return try expenseRepo.fetchAll(sortDescriptors: [sort])
    }

    // MARK: fetchAll(in:sortedByDateAscending:)
    /// Fetch all planned expenses constrained to a date interval (inclusive).
    /// - Parameters:
    ///   - interval: Date interval filter (inclusive).
    ///   - sortedByDateAscending: Sort ascending (default true).
    func fetchAll(in interval: DateInterval,
                  sortedByDateAscending: Bool = true) throws -> [PlannedExpense] {
        let base = NSPredicate(format: "transactionDate >= %@ AND transactionDate <= %@",
                               interval.start as CVarArg, interval.end as CVarArg)
        let predicate: NSPredicate
        if let workspaceID = WorkspaceService.activeWorkspaceIDFromDefaults() {
            predicate = WorkspaceService.combinedPredicate(base, workspaceID: workspaceID)
        } else {
            predicate = base
        }
        let sort = NSSortDescriptor(key: "transactionDate", ascending: sortedByDateAscending)
        return try expenseRepo.fetchAll(predicate: predicate, sortDescriptors: [sort])
    }
    
    // MARK: find(byID:)
    /// Find a PlannedExpense by UUID.
    /// - Parameter id: Expense ID.
    /// - Returns: PlannedExpense or nil.
    func find(byID id: UUID) throws -> PlannedExpense? {
        let base = NSPredicate(format: "id == %@", id as CVarArg)
        let predicate: NSPredicate
        if let workspaceID = WorkspaceService.activeWorkspaceIDFromDefaults() {
            predicate = WorkspaceService.combinedPredicate(base, workspaceID: workspaceID)
        } else {
            predicate = base
        }
        return try expenseRepo.fetchFirst(predicate: predicate)
    }
    
    // MARK: fetchForBudget(_:sortedByDateAscending:)
    /// Fetch expenses for a given budget (all dates).
    /// - Parameters:
    ///   - budgetID: Budget UUID.
    ///   - sortedByDateAscending: Sort ascending (default true).
    /// - Returns: Array of PlannedExpense linked to that budget.
    func fetchForBudget(_ budgetID: UUID,
                        sortedByDateAscending: Bool = true) throws -> [PlannedExpense] {
        let base = NSPredicate(format: "budget.id == %@", budgetID as CVarArg)
        let predicate: NSPredicate
        if let workspaceID = WorkspaceService.activeWorkspaceIDFromDefaults() {
            predicate = WorkspaceService.combinedPredicate(base, workspaceID: workspaceID)
        } else {
            predicate = base
        }
        let sort = NSSortDescriptor(key: "transactionDate", ascending: sortedByDateAscending)
        return try expenseRepo.fetchAll(predicate: predicate, sortDescriptors: [sort])
    }
    
    // MARK: fetchForBudget(_:in:sortedByDateAscending:)
    /// Fetch expenses for a budget constrained to a date interval (inclusive).
    /// - Parameters:
    ///   - budgetID: Budget UUID.
    ///   - interval: Date interval filter (inclusive).
    ///   - sortedByDateAscending: Sort ascending (default true).
    func fetchForBudget(_ budgetID: UUID,
                        in interval: DateInterval,
                        sortedByDateAscending: Bool = true) throws -> [PlannedExpense] {
        let base = NSPredicate(format: "budget.id == %@ AND transactionDate >= %@ AND transactionDate <= %@",
                               budgetID as CVarArg, interval.start as CVarArg, interval.end as CVarArg)
        let predicate: NSPredicate
        if let workspaceID = WorkspaceService.activeWorkspaceIDFromDefaults() {
            predicate = WorkspaceService.combinedPredicate(base, workspaceID: workspaceID)
        } else {
            predicate = base
        }
        let sort = NSSortDescriptor(key: "transactionDate", ascending: sortedByDateAscending)
        return try expenseRepo.fetchAll(predicate: predicate, sortDescriptors: [sort])
    }

    // MARK: fetchForCard(_:sortedByDateAscending:)
    /// Fetch planned expenses for a given card (all dates).
    /// - Parameters:
    ///   - cardID: Card UUID.
    ///   - sortedByDateAscending: Sort ascending (default true).
    /// - Returns: Array of PlannedExpense linked to that card.
    func fetchForCard(_ cardID: UUID,
                      sortedByDateAscending: Bool = true) throws -> [PlannedExpense] {
        let base = NSPredicate(format: "card.id == %@ AND isGlobal == NO", cardID as CVarArg)
        let predicate: NSPredicate
        if let workspaceID = WorkspaceService.activeWorkspaceIDFromDefaults() {
            predicate = WorkspaceService.combinedPredicate(base, workspaceID: workspaceID)
        } else {
            predicate = base
        }
        let sort = NSSortDescriptor(key: "transactionDate", ascending: sortedByDateAscending)
        return try expenseRepo.fetchAll(predicate: predicate, sortDescriptors: [sort])
    }

    // MARK: fetchForCard(_:in:sortedByDateAscending:)
    /// Fetch planned expenses for a card constrained to a date interval (inclusive).
    /// - Parameters:
    ///   - cardID: Card UUID.
    ///   - interval: Date interval filter (inclusive).
    ///   - sortedByDateAscending: Sort ascending (default true).
    func fetchForCard(_ cardID: UUID,
                      in interval: DateInterval,
                      sortedByDateAscending: Bool = true) throws -> [PlannedExpense] {
        let base = NSPredicate(format: "card.id == %@ AND isGlobal == NO AND transactionDate >= %@ AND transactionDate <= %@",
                               cardID as CVarArg, interval.start as CVarArg, interval.end as CVarArg)
        let predicate: NSPredicate
        if let workspaceID = WorkspaceService.activeWorkspaceIDFromDefaults() {
            predicate = WorkspaceService.combinedPredicate(base, workspaceID: workspaceID)
        } else {
            predicate = base
        }
        let sort = NSSortDescriptor(key: "transactionDate", ascending: sortedByDateAscending)
        return try expenseRepo.fetchAll(predicate: predicate, sortDescriptors: [sort])
    }

    // MARK: fetchTemplatesForCard(_:sortedByDateAscending:)
    /// Fetch global planned expense templates attached to a card.
    /// - Parameters:
    ///   - cardID: Card UUID.
    ///   - sortedByDateAscending: Sort ascending (default true).
    /// - Returns: Array of global PlannedExpense templates for the card.
    func fetchTemplatesForCard(_ cardID: UUID,
                               sortedByDateAscending: Bool = true) throws -> [PlannedExpense] {
        let base = NSPredicate(format: "card.id == %@ AND isGlobal == YES", cardID as CVarArg)
        let predicate: NSPredicate
        if let workspaceID = WorkspaceService.activeWorkspaceIDFromDefaults() {
            predicate = WorkspaceService.combinedPredicate(base, workspaceID: workspaceID)
        } else {
            predicate = base
        }
        let sort = NSSortDescriptor(key: "transactionDate", ascending: sortedByDateAscending)
        return try expenseRepo.fetchAll(predicate: predicate, sortDescriptors: [sort])
    }

    // MARK: fetchTemplatesForCard(_:in:sortedByDateAscending:)
    /// Fetch global planned expense templates for a card constrained to a date interval (inclusive).
    /// - Parameters:
    ///   - cardID: Card UUID.
    ///   - interval: Date interval filter (inclusive).
    ///   - sortedByDateAscending: Sort ascending (default true).
    func fetchTemplatesForCard(_ cardID: UUID,
                               in interval: DateInterval,
                               sortedByDateAscending: Bool = true) throws -> [PlannedExpense] {
        let base = NSPredicate(format: "card.id == %@ AND isGlobal == YES AND transactionDate >= %@ AND transactionDate <= %@",
                               cardID as CVarArg, interval.start as CVarArg, interval.end as CVarArg)
        let predicate: NSPredicate
        if let workspaceID = WorkspaceService.activeWorkspaceIDFromDefaults() {
            predicate = WorkspaceService.combinedPredicate(base, workspaceID: workspaceID)
        } else {
            predicate = base
        }
        let sort = NSSortDescriptor(key: "transactionDate", ascending: sortedByDateAscending)
        return try expenseRepo.fetchAll(predicate: predicate, sortDescriptors: [sort])
    }

    // MARK: - CREATE
    
    // MARK: create(inBudgetID:titleOrDescription:plannedAmount:actualAmount:transactionDate:isGlobal:globalTemplateID:)
    /// Create a planned expense **attached to a budget**.
    /// - Parameters:
    ///   - budgetID: Budget to attach to.
    ///   - titleOrDescription: Title/description text (stored under `descriptionText` or `title`, whichever exists).
    ///   - plannedAmount: Planned amount (Double).
    ///   - actualAmount: Actual amount (Double, default 0).
    ///   - transactionDate: Date the expense is planned to occur.
    ///   - isGlobal: Should be false for regular instances (default false).
    ///   - globalTemplateID: Optional link to a template it was derived from.
    /// - Returns: Newly created PlannedExpense.
    @discardableResult
    func create(inBudgetID budgetID: UUID,
                titleOrDescription: String,
                plannedAmount: Double,
                actualAmount: Double = 0,
                transactionDate: Date,
                isGlobal: Bool = false,
                globalTemplateID: UUID? = nil) throws -> PlannedExpense {
        let budgetBase = NSPredicate(format: "id == %@", budgetID as CVarArg)
        let budgetPredicate: NSPredicate
        if let workspaceID = WorkspaceService.activeWorkspaceIDFromDefaults() {
            budgetPredicate = WorkspaceService.combinedPredicate(budgetBase, workspaceID: workspaceID)
        } else {
            budgetPredicate = budgetBase
        }
        guard let budget = try budgetRepo.fetchFirst(predicate: budgetPredicate) else {
            throw PlannedExpenseServiceError.budgetNotFound(budgetID)
        }
        
        let expense = expenseRepo.create { exp in
            // ✅ Assign a fresh UUID via KVC to avoid .id ambiguity.
            exp.setValue(UUID(), forKey: "id")
            // Support 'title' vs 'descriptionText'
            Self.setTitleOrDescription(on: exp, value: titleOrDescription)
            
            exp.plannedAmount   = plannedAmount
            exp.actualAmount    = actualAmount
            exp.transactionDate = transactionDate
            exp.isGlobal        = isGlobal
            exp.globalTemplateID = globalTemplateID
            // Relationship set via strong reference (codegen-safe), fallback to KVC if needed.
            exp.setValue(budget, forKey: "budget")
            WorkspaceService.applyWorkspaceIDIfPossible(on: exp)
        }
        try expenseRepo.saveIfNeeded()
        return expense
    }
    
    // MARK: createGlobalTemplate(titleOrDescription:plannedAmount:defaultTransactionDate:categoryID:cardID:)
    /// Create a **global template** (not linked to any budget).
    /// - Parameters:
    ///   - titleOrDescription: Display text.
    ///   - plannedAmount: Planned amount baked into the template.
    ///   - actualAmount: Optional actual amount (defaults to 0).
    ///   - defaultTransactionDate: Some UIs want a default date (e.g., next due date). If your model
    ///                             makes this non-optional, pass something meaningful (default = now).
    ///   - categoryID: Optional category to associate (part of deterministic preset identity).
    ///   - cardID: Optional card to associate (part of deterministic preset identity).
    /// - Returns: The template PlannedExpense (isGlobal = true).
    @discardableResult
    func createGlobalTemplate(titleOrDescription: String,
                              plannedAmount: Double,
                              actualAmount: Double = 0,
                              defaultTransactionDate: Date = Date(),
                              categoryID: UUID? = nil,
                              cardID: UUID? = nil,
                              saveImmediately: Bool = true) throws -> PlannedExpense {
        let ctx = expenseRepo.context
        let workspaceID = WorkspaceService.activeWorkspaceIDFromDefaults()
            ?? UUID()

        let desiredID = DeterministicID.presetTemplateID(
            workspaceID: workspaceID,
            title: titleOrDescription,
            plannedAmount: plannedAmount,
            categoryID: categoryID,
            cardID: cardID
        )

        let existing = try expenseRepo.fetchFirst(predicate: {
            let base = NSPredicate(format: "id == %@ AND isGlobal == YES", desiredID as CVarArg)
            if let ws = WorkspaceService.activeWorkspaceIDFromDefaults() {
                return WorkspaceService.combinedPredicate(base, workspaceID: ws)
            }
            return base
        }())
        if existing != nil {
            throw NSError(domain: "PlannedExpenseService", code: 2001, userInfo: [
                NSLocalizedDescriptionKey: "A preset with the same card, category, title, and planned amount already exists."
            ])
        }

        let resolvedCategory: ExpenseCategory? = {
            guard let categoryID else { return nil }
            let req = NSFetchRequest<ExpenseCategory>(entityName: "ExpenseCategory")
            req.fetchLimit = 1
            let base = NSPredicate(format: "id == %@", categoryID as CVarArg)
            if let ws = WorkspaceService.activeWorkspaceIDFromDefaults() {
                req.predicate = WorkspaceService.combinedPredicate(base, workspaceID: ws)
            } else {
                req.predicate = base
            }
            return try? ctx.fetch(req).first
        }()

        let resolvedCard: Card? = {
            guard let cardID else { return nil }
            let req = NSFetchRequest<Card>(entityName: "Card")
            req.fetchLimit = 1
            let base = NSPredicate(format: "id == %@", cardID as CVarArg)
            if let ws = WorkspaceService.activeWorkspaceIDFromDefaults() {
                req.predicate = WorkspaceService.combinedPredicate(base, workspaceID: ws)
            } else {
                req.predicate = base
            }
            return try? ctx.fetch(req).first
        }()

        let template = expenseRepo.create { exp in
            exp.setValue(desiredID, forKey: "id")
            Self.setTitleOrDescription(on: exp, value: titleOrDescription)
            exp.plannedAmount   = plannedAmount
            exp.actualAmount    = actualAmount
            exp.transactionDate = defaultTransactionDate
            exp.isGlobal        = true
            exp.globalTemplateID = nil
            // No budget for global templates
            exp.setValue(nil, forKey: "budget")
            if let resolvedCategory { exp.expenseCategory = resolvedCategory }
            if let resolvedCard { exp.card = resolvedCard }
            WorkspaceService.applyWorkspaceIDIfPossible(on: exp)
        }
        if saveImmediately {
            try expenseRepo.saveIfNeeded()
        }
        return template
    }
    
    // MARK: instantiateTemplate(_:intoBudgetID:on:)
    /// Instantiate a **global template** into a specific budget, copying fields.
    /// - Parameters:
    ///   - template: A PlannedExpense with `isGlobal == true`.
    ///   - budgetID: Target budget ID.
    ///   - date: The planned transaction date for the instance (often within the budget range).
    /// - Returns: The created instance (isGlobal = false, globalTemplateID set).
    @discardableResult
    func instantiateTemplate(_ template: PlannedExpense,
                             intoBudgetID budgetID: UUID,
                             on date: Date) throws -> PlannedExpense {
        guard template.isGlobal else {
            throw PlannedExpenseServiceError.templateNotGlobal
        }
        let title = Self.getTitleOrDescription(from: template) ?? ""
        let instance = try create(inBudgetID: budgetID,
                                  titleOrDescription: title,
                                  plannedAmount: template.plannedAmount,
                                  actualAmount: template.actualAmount,
                                  transactionDate: date,
                                  isGlobal: false,
                                  globalTemplateID: template.value(forKey: "id") as? UUID)
        return instance
    }
    
    // MARK: duplicate(_:intoBudgetID:on:)
    /// Duplicate an existing planned expense (instance) into the same or another budget.
    /// - Parameters:
    ///   - expense: Existing expense to clone.
    ///   - budgetID: Destination budget.
    ///   - date: Date for the new copy.
    @discardableResult
    func duplicate(_ expense: PlannedExpense,
                   intoBudgetID budgetID: UUID,
                   on date: Date) throws -> PlannedExpense {
        let title = Self.getTitleOrDescription(from: expense) ?? ""
        let clone = try create(inBudgetID: budgetID,
                               titleOrDescription: title,
                               plannedAmount: expense.plannedAmount,
                               actualAmount: expense.actualAmount,
                               transactionDate: date,
                               isGlobal: false,
                               globalTemplateID: expense.globalTemplateID)
        clone.card = expense.card
        clone.expenseCategory = expense.expenseCategory
        try expenseRepo.saveIfNeeded()
        return clone
    }
    
    // MARK: - UPDATE
    
    // MARK: update(_:titleOrDescription:plannedAmount:actualAmount:transactionDate:isGlobal:globalTemplateID:)
    /// Update fields on a planned expense (only what you pass will change).
    func update(_ expense: PlannedExpense,
                titleOrDescription: String? = nil,
                plannedAmount: Double? = nil,
                actualAmount: Double? = nil,
                transactionDate: Date? = nil,
                isGlobal: Bool? = nil,
                globalTemplateID: UUID?? = nil) throws {
        if let titleOrDescription {
            Self.setTitleOrDescription(on: expense, value: titleOrDescription)
        }
        if let plannedAmount { expense.plannedAmount = plannedAmount }
        if let actualAmount  { expense.actualAmount  = actualAmount }
        if let transactionDate { expense.transactionDate = transactionDate }
        if let isGlobal { expense.isGlobal = isGlobal }
        if let globalTemplateID { expense.globalTemplateID = globalTemplateID }
        try expenseRepo.saveIfNeeded()
    }
    
    // MARK: move(_:toBudgetID:)
    /// Move an expense to another budget.
    func move(_ expense: PlannedExpense, toBudgetID budgetID: UUID) throws {
        let budgetBase = NSPredicate(format: "id == %@", budgetID as CVarArg)
        let budgetPredicate: NSPredicate
        if let workspaceID = WorkspaceService.activeWorkspaceIDFromDefaults() {
            budgetPredicate = WorkspaceService.combinedPredicate(budgetBase, workspaceID: workspaceID)
        } else {
            budgetPredicate = budgetBase
        }
        guard let budget = try budgetRepo.fetchFirst(predicate: budgetPredicate) else {
            throw PlannedExpenseServiceError.budgetNotFound(budgetID)
        }
        expense.setValue(budget, forKey: "budget")
        try expenseRepo.saveIfNeeded()
    }
    
    // MARK: adjustActualAmount(_:delta:)
    /// Increment/decrement the actual amount by a delta (can be negative).
    func adjustActualAmount(_ expense: PlannedExpense, delta: Double) throws {
        expense.actualAmount += delta
        try expenseRepo.saveIfNeeded()
    }
    
    // MARK: - DELETE
    
    // MARK: delete(_:)
    /// Delete a planned expense.
    func delete(_ expense: PlannedExpense) throws {
        expenseRepo.delete(expense)
        try expenseRepo.saveIfNeeded()
    }
    
    // MARK: deleteAllForBudget(_:)
    /// Delete all planned expenses for a budget (dangerous; mostly for testing/reset).
    func deleteAllForBudget(_ budgetID: UUID) throws {
        let base = NSPredicate(format: "budget.id == %@", budgetID as CVarArg)
        let predicate: NSPredicate
        if let workspaceID = WorkspaceService.activeWorkspaceIDFromDefaults() {
            predicate = WorkspaceService.combinedPredicate(base, workspaceID: workspaceID)
        } else {
            predicate = base
        }
        try expenseRepo.deleteAll(predicate: predicate)
    }
    
    // MARK: - TOTALS
    
    // MARK: totalsForBudget(_:in:)
    /// Compute `(plannedTotal, actualTotal)` for a budget, optionally limited to a date interval.
    /// - Parameters:
    ///   - budgetID: Budget UUID.
    ///   - interval: Optional date interval constraint; pass nil for all dates.
    /// - Returns: Tuple with planned and actual totals.
    func totalsForBudget(_ budgetID: UUID,
                         in interval: DateInterval? = nil) throws -> (planned: Double, actual: Double) {
        let expenses: [PlannedExpense]
        if let interval {
            expenses = try fetchForBudget(budgetID, in: interval, sortedByDateAscending: true)
        } else {
            expenses = try fetchForBudget(budgetID, sortedByDateAscending: true)
        }
        let planned = expenses.reduce(0.0) { $0 + $1.plannedAmount }
        let actual  = expenses.reduce(0.0) { $0 + $1.actualAmount }
        return (planned, actual)
    }
    
    // MARK: - Private: Title/Description drift
    
    // MARK: setTitleOrDescription(on:value:)
    /// Writes to `descriptionText` if it exists, otherwise to `title` if it exists.
    private static func setTitleOrDescription(on object: NSManagedObject, value: String) {
        let keys = object.entity.attributesByName.keys
        if keys.contains("descriptionText") {
            object.setValue(value, forKey: "descriptionText")
        } else if keys.contains("title") {
            object.setValue(value, forKey: "title")
        } else {
            // If neither exists (unexpected), fall back to KVC to a safe key to avoid crash.
            // You can log here if you want:
            // assertionFailure("Neither `descriptionText` nor `title` exists on PlannedExpense entity.")
        }
    }
    
    // MARK: getTitleOrDescription(from:)
    /// Reads `descriptionText` or `title` (prefers descriptionText).
    private static func getTitleOrDescription(from object: NSManagedObject) -> String? {
        let keys = object.entity.attributesByName.keys
        if keys.contains("descriptionText") {
            return object.value(forKey: "descriptionText") as? String
        } else if keys.contains("title") {
            return object.value(forKey: "title") as? String
        } else {
            return nil
        }
    }
}

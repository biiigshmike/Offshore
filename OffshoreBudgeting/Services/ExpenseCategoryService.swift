//
//  ExpenseCategoryService.swift
//  SoFar
//
//  Manage ExpenseCategory CRUD with clear, testable methods.
//  Notes:
//  - Model currently uses attribute name "color" (String).
//  - IDs are UUID (optional in model, we will always set on create).
//

import Foundation
import CoreData

// MARK: - ExpenseCategoryService
/// Public API to manage `ExpenseCategory` records.
final class ExpenseCategoryService {

    // MARK: - Errors
    enum ExpenseCategoryServiceError: LocalizedError {
        case emptyName
        case duplicateName(String)

        var errorDescription: String? {
            switch self {
            case .emptyName:
                return "Please enter a category name."
            case .duplicateName(let name):
                return "A category named “\(name)” already exists."
            }
        }
    }
    
    // MARK: Properties
    /// Generic repository for ExpenseCategory entity.
    private let repo: CoreDataRepository<ExpenseCategory>

    // MARK: Init
    /// Initialize with a custom Core Data stack (useful for tests).
    init(stack: CoreDataStackProviding = CoreDataService.shared) {
        self.repo = CoreDataRepository<ExpenseCategory>(stack: stack)
    }
    
    // MARK: fetchAllCategories(sortedByName:)
    /// Fetch all categories, optionally sorting by name ascending.
    /// - Parameter sortedByName: If true, results are A→Z by name.
    /// - Returns: Array of ExpenseCategory
    func fetchAllCategories(sortedByName: Bool = true) throws -> [ExpenseCategory] {
        let sort = sortedByName
        ? [NSSortDescriptor(
            key: #keyPath(ExpenseCategory.name),
            ascending: true,
            selector: #selector(NSString.localizedCaseInsensitiveCompare(_:))
        )]
        : []
        if let workspaceID = WorkspaceService.activeWorkspaceIDFromDefaults() {
            let predicate = WorkspaceService.predicate(for: workspaceID)
            return try repo.fetchAll(predicate: predicate, sortDescriptors: sort)
        }
        return try repo.fetchAll(sortDescriptors: sort)
    }
    
    // MARK: findCategory(byID:)
    /// Fetch a single category by UUID.
    /// - Parameter id: The category's UUID.
    /// - Returns: Category or nil.
    func findCategory(byID id: UUID) throws -> ExpenseCategory? {
        // Literal "id" avoids ambiguity with Identifiable.
        let base = NSPredicate(format: "id == %@", id as CVarArg)
        let predicate: NSPredicate
        if let workspaceID = WorkspaceService.activeWorkspaceIDFromDefaults() {
            predicate = WorkspaceService.combinedPredicate(base, workspaceID: workspaceID)
        } else {
            predicate = base
        }
        return try repo.fetchFirst(predicate: predicate)
    }
    
    // MARK: findCategory(named:)
    /// Fetch a single category by exact name match (case-insensitive).
    /// - Parameter name: Category name.
    /// - Returns: Category or nil.
    func findCategory(named name: String) throws -> ExpenseCategory? {
        let base = NSPredicate(format: "name =[c] %@", name)
        let predicate: NSPredicate
        if let workspaceID = WorkspaceService.activeWorkspaceIDFromDefaults() {
            predicate = WorkspaceService.combinedPredicate(base, workspaceID: workspaceID)
        } else {
            predicate = base
        }
        return try repo.fetchFirst(predicate: predicate)
    }
    
    // MARK: addCategory(name:color:ensureUniqueName:)
    /// Create a category. If `ensureUniqueName` is true and a duplicate exists, returns the existing category.
    /// - Parameters:
    ///   - name: Display name (required).
    ///   - color: Hex or arbitrary string (stored only, parsing is a UI layer concern).x
    ///   - ensureUniqueName: Avoid duplicate names if desired.
    /// - Returns: The created or existing category.
    @discardableResult
    func addCategory(name: String,
                     color: String,
                     ensureUniqueName: Bool = true) throws -> ExpenseCategory {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { throw ExpenseCategoryServiceError.emptyName }

        if ensureUniqueName {
            let workspaceID = WorkspaceService.activeWorkspaceIDFromDefaults() ?? UUID()
            let desiredID = DeterministicID.categoryID(workspaceID: workspaceID, name: trimmed)

            if let existing = try? findCategory(byID: desiredID) {
                return existing
            }
            if let existing = try? findCategory(named: trimmed) {
                return existing
            }
        }

        let category = repo.create { cat in
            let id: UUID = {
                guard ensureUniqueName else { return UUID() }
                let workspaceID = WorkspaceService.activeWorkspaceIDFromDefaults() ?? UUID()
                return DeterministicID.categoryID(workspaceID: workspaceID, name: trimmed)
            }()
            cat.setValue(id, forKey: "id")
            cat.name = trimmed
            cat.color = color
            WorkspaceService.applyWorkspaceIDIfPossible(on: cat)
        }
        try repo.saveIfNeeded()
        return category
    }
    
    // MARK: updateCategory(_:name:color:)
    /// Update a category’s name and/or color.
    /// - Parameters:
    ///   - category: The managed object to update.
    ///   - name: New name (optional).
    ///   - color: New color string (optional).
    func updateCategory(_ category: ExpenseCategory,
                        name: String? = nil,
                        color: String? = nil) throws {
        if let name {
            let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else { throw ExpenseCategoryServiceError.emptyName }

            let base = NSPredicate(format: "name =[c] %@", trimmed)
            let predicate: NSPredicate = {
                guard let ws = WorkspaceService.activeWorkspaceIDFromDefaults() else { return base }
                return WorkspaceService.combinedPredicate(base, workspaceID: ws)
            }()
            if let other = try? repo.fetchFirst(predicate: predicate),
               other.objectID != category.objectID
            {
                throw ExpenseCategoryServiceError.duplicateName(trimmed)
            }

            category.name = trimmed
        }
        if let color { category.color = color }
        try repo.saveIfNeeded()
    }
    
    // MARK: deleteCategory(_:)
    /// Delete a category. Consider validating if it’s in use first.
    /// - Parameter category: The category to delete.
    func deleteCategory(_ category: ExpenseCategory) throws {
        repo.delete(category)
        try repo.saveIfNeeded()
    }
    
    // MARK: deleteAllCategories()
    /// Remove all categories (dangerous; mainly for testing/reset).
    func deleteAllCategories() throws {
        try repo.deleteAll()
    }
}

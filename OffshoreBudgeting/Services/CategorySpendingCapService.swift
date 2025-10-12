//
//  CategorySpendingCapService.swift
//  SoFar
//
//  Typed helper around CategorySpendingCap for loading and managing
//  category-based spending limits.
//

import Foundation
import CoreData

// MARK: - CategorySpendingCapService
final class CategorySpendingCapService {

    // MARK: Types
    enum ExpenseType: String, CaseIterable {
        case planned
        case variable

        static func fromStorageString(_ rawValue: String?) -> ExpenseType? {
            guard let rawValue else { return nil }
            return ExpenseType(rawValue: rawValue)
        }

        var storageString: String { rawValue }
    }

    enum ServiceError: Error {
        case categoryNotFound
    }

    // MARK: Properties
    private let repo = CoreDataRepository<CategorySpendingCap>()
    private let categoryService = ExpenseCategoryService()

    // MARK: Fetch
    func loadCap(categoryID: UUID,
                 expenseType: ExpenseType,
                 periodRawValue: String) throws -> CategorySpendingCap? {
        let predicate = makePredicate(categoryID: categoryID,
                                      expenseType: expenseType,
                                      periodRawValue: periodRawValue)
        return try repo.fetchFirst(predicate: predicate)
    }

    func loadCap(categoryID: UUID,
                 expenseType: ExpenseType,
                 period: BudgetPeriod) throws -> CategorySpendingCap? {
        try loadCap(categoryID: categoryID,
                    expenseType: expenseType,
                    periodRawValue: period.storageString)
    }

    // MARK: Upsert
    @discardableResult
    func upsertCap(amount: Double,
                   categoryID: UUID,
                   expenseType: ExpenseType,
                   periodRawValue: String) throws -> CategorySpendingCap {
        let normalizedPeriod = periodRawValue
        let predicate = makePredicate(categoryID: categoryID,
                                      expenseType: expenseType,
                                      periodRawValue: normalizedPeriod)
        let cap = try repo.fetchFirst(predicate: predicate) ?? repo.create { _ in }

        ensureIdentifier(on: cap)

        let category: ExpenseCategory
        if let existingCategory = cap.category,
           (existingCategory.value(forKey: "id") as? UUID) == categoryID {
            category = existingCategory
        } else {
            category = try resolveCategory(with: categoryID)
        }
        if cap.category?.objectID != category.objectID {
            cap.category = category
        }

        cap.amount = amount
        cap.period = normalizedPeriod
        cap.expenseType = expenseType.storageString

        try repo.saveIfNeeded()
        return cap
    }

    @discardableResult
    func upsertCap(amount: Double,
                   categoryID: UUID,
                   expenseType: ExpenseType,
                   period: BudgetPeriod) throws -> CategorySpendingCap {
        try upsertCap(amount: amount,
                      categoryID: categoryID,
                      expenseType: expenseType,
                      periodRawValue: period.storageString)
    }

    // MARK: Delete / Reset
    func deleteCap(categoryID: UUID,
                   expenseType: ExpenseType,
                   periodRawValue: String) throws {
        if let cap = try loadCap(categoryID: categoryID,
                                 expenseType: expenseType,
                                 periodRawValue: periodRawValue) {
            repo.delete(cap)
            try repo.saveIfNeeded()
        }
    }

    func deleteCap(categoryID: UUID,
                   expenseType: ExpenseType,
                   period: BudgetPeriod) throws {
        try deleteCap(categoryID: categoryID,
                      expenseType: expenseType,
                      periodRawValue: period.storageString)
    }

    func resetCaps(for categoryID: UUID) throws {
        let predicate = NSPredicate(format: "category.id == %@", categoryID as CVarArg)
        try repo.deleteAll(predicate: predicate)
    }

    // MARK: Helpers
    private func makePredicate(categoryID: UUID,
                               expenseType: ExpenseType,
                               periodRawValue: String) -> NSPredicate {
        NSPredicate(format: "category.id == %@ AND expenseType == %@ AND period == %@",
                    categoryID as CVarArg,
                    expenseType.storageString,
                    periodRawValue)
    }

    private func resolveCategory(with id: UUID) throws -> ExpenseCategory {
        if let category = try categoryService.findCategory(byID: id) {
            return category
        }
        throw ServiceError.categoryNotFound
    }

    private func ensureIdentifier(on cap: CategorySpendingCap) {
        if (cap.value(forKey: "id") as? UUID) == nil {
            cap.setValue(UUID(), forKey: "id")
        }
    }
}

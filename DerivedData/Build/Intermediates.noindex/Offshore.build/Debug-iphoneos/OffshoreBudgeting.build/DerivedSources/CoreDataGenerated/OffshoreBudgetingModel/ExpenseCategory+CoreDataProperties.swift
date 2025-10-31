//
//  ExpenseCategory+CoreDataProperties.swift
//  
//
//  Created by Michael Brown on 10/30/25.
//
//  This file was automatically generated and should not be edited.
//

public import Foundation
public import CoreData


public typealias ExpenseCategoryCoreDataPropertiesSet = NSSet

extension ExpenseCategory {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<ExpenseCategory> {
        return NSFetchRequest<ExpenseCategory>(entityName: "ExpenseCategory")
    }

    @NSManaged public var color: String?
    @NSManaged public var id: UUID?
    @NSManaged public var name: String?
    @NSManaged public var workspaceID: UUID?
    @NSManaged public var plannedExpense: NSSet?
    @NSManaged public var spendingCaps: NSSet?
    @NSManaged public var unplannedExpense: NSSet?

}

// MARK: Generated accessors for plannedExpense
extension ExpenseCategory {

    @objc(addPlannedExpenseObject:)
    @NSManaged public func addToPlannedExpense(_ value: PlannedExpense)

    @objc(removePlannedExpenseObject:)
    @NSManaged public func removeFromPlannedExpense(_ value: PlannedExpense)

    @objc(addPlannedExpense:)
    @NSManaged public func addToPlannedExpense(_ values: NSSet)

    @objc(removePlannedExpense:)
    @NSManaged public func removeFromPlannedExpense(_ values: NSSet)

}

// MARK: Generated accessors for spendingCaps
extension ExpenseCategory {

    @objc(addSpendingCapsObject:)
    @NSManaged public func addToSpendingCaps(_ value: CategorySpendingCap)

    @objc(removeSpendingCapsObject:)
    @NSManaged public func removeFromSpendingCaps(_ value: CategorySpendingCap)

    @objc(addSpendingCaps:)
    @NSManaged public func addToSpendingCaps(_ values: NSSet)

    @objc(removeSpendingCaps:)
    @NSManaged public func removeFromSpendingCaps(_ values: NSSet)

}

// MARK: Generated accessors for unplannedExpense
extension ExpenseCategory {

    @objc(addUnplannedExpenseObject:)
    @NSManaged public func addToUnplannedExpense(_ value: UnplannedExpense)

    @objc(removeUnplannedExpenseObject:)
    @NSManaged public func removeFromUnplannedExpense(_ value: UnplannedExpense)

    @objc(addUnplannedExpense:)
    @NSManaged public func addToUnplannedExpense(_ values: NSSet)

    @objc(removeUnplannedExpense:)
    @NSManaged public func removeFromUnplannedExpense(_ values: NSSet)

}

extension ExpenseCategory : Identifiable {

}

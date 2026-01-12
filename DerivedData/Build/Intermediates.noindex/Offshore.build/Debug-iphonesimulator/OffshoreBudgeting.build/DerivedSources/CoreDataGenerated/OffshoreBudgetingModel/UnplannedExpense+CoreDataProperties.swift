//
//  UnplannedExpense+CoreDataProperties.swift
//  
//
//  Created by Michael Brown on 1/12/26.
//
//  This file was automatically generated and should not be edited.
//

public import Foundation
public import CoreData


public typealias UnplannedExpenseCoreDataPropertiesSet = NSSet

extension UnplannedExpense {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<UnplannedExpense> {
        return NSFetchRequest<UnplannedExpense>(entityName: "UnplannedExpense")
    }

    @NSManaged public var amount: Double
    @NSManaged public var descriptionText: String?
    @NSManaged public var id: UUID?
    @NSManaged public var parentID: UUID?
    @NSManaged public var recurrence: String?
    @NSManaged public var recurrenceEndDate: Date?
    @NSManaged public var secondBiMonthlyDate: Int16
    @NSManaged public var transactionDate: Date?
    @NSManaged public var workspaceID: UUID?
    @NSManaged public var card: Card?
    @NSManaged public var childExpense: NSSet?
    @NSManaged public var expenseCategory: ExpenseCategory?
    @NSManaged public var parentExpense: UnplannedExpense?

}

// MARK: Generated accessors for childExpense
extension UnplannedExpense {

    @objc(addChildExpenseObject:)
    @NSManaged public func addToChildExpense(_ value: UnplannedExpense)

    @objc(removeChildExpenseObject:)
    @NSManaged public func removeFromChildExpense(_ value: UnplannedExpense)

    @objc(addChildExpense:)
    @NSManaged public func addToChildExpense(_ values: NSSet)

    @objc(removeChildExpense:)
    @NSManaged public func removeFromChildExpense(_ values: NSSet)

}

extension UnplannedExpense : Identifiable {

}

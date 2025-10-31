//
//  Budget+CoreDataProperties.swift
//  
//
//  Created by Michael Brown on 10/30/25.
//
//  This file was automatically generated and should not be edited.
//

public import Foundation
public import CoreData


public typealias BudgetCoreDataPropertiesSet = NSSet

extension Budget {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Budget> {
        return NSFetchRequest<Budget>(entityName: "Budget")
    }

    @NSManaged public var endDate: Date?
    @NSManaged public var id: UUID?
    @NSManaged public var isRecurring: Bool
    @NSManaged public var name: String?
    @NSManaged public var parentID: UUID?
    @NSManaged public var recurrenceEndDate: Date?
    @NSManaged public var recurrenceType: String?
    @NSManaged public var startDate: Date?
    @NSManaged public var workspaceID: UUID?
    @NSManaged public var cards: NSSet?
    @NSManaged public var plannedExpense: NSSet?

}

// MARK: Generated accessors for cards
extension Budget {

    @objc(addCardsObject:)
    @NSManaged public func addToCards(_ value: Card)

    @objc(removeCardsObject:)
    @NSManaged public func removeFromCards(_ value: Card)

    @objc(addCards:)
    @NSManaged public func addToCards(_ values: NSSet)

    @objc(removeCards:)
    @NSManaged public func removeFromCards(_ values: NSSet)

}

// MARK: Generated accessors for plannedExpense
extension Budget {

    @objc(addPlannedExpenseObject:)
    @NSManaged public func addToPlannedExpense(_ value: PlannedExpense)

    @objc(removePlannedExpenseObject:)
    @NSManaged public func removeFromPlannedExpense(_ value: PlannedExpense)

    @objc(addPlannedExpense:)
    @NSManaged public func addToPlannedExpense(_ values: NSSet)

    @objc(removePlannedExpense:)
    @NSManaged public func removeFromPlannedExpense(_ values: NSSet)

}

extension Budget : Identifiable {

}

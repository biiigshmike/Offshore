//
//  Card+CoreDataProperties.swift
//  
//
//  Created by Michael Brown on 10/30/25.
//
//  This file was automatically generated and should not be edited.
//

public import Foundation
public import CoreData


public typealias CardCoreDataPropertiesSet = NSSet

extension Card {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Card> {
        return NSFetchRequest<Card>(entityName: "Card")
    }

    @NSManaged public var id: UUID?
    @NSManaged public var name: String?
    @NSManaged public var workspaceID: UUID?
    @NSManaged public var budget: NSSet?
    @NSManaged public var plannedExpenses: NSSet?
    @NSManaged public var unplannedExpenses: NSSet?

}

// MARK: Generated accessors for budget
extension Card {

    @objc(addBudgetObject:)
    @NSManaged public func addToBudget(_ value: Budget)

    @objc(removeBudgetObject:)
    @NSManaged public func removeFromBudget(_ value: Budget)

    @objc(addBudget:)
    @NSManaged public func addToBudget(_ values: NSSet)

    @objc(removeBudget:)
    @NSManaged public func removeFromBudget(_ values: NSSet)

}

// MARK: Generated accessors for plannedExpenses
extension Card {

    @objc(addPlannedExpensesObject:)
    @NSManaged public func addToPlannedExpenses(_ value: PlannedExpense)

    @objc(removePlannedExpensesObject:)
    @NSManaged public func removeFromPlannedExpenses(_ value: PlannedExpense)

    @objc(addPlannedExpenses:)
    @NSManaged public func addToPlannedExpenses(_ values: NSSet)

    @objc(removePlannedExpenses:)
    @NSManaged public func removeFromPlannedExpenses(_ values: NSSet)

}

// MARK: Generated accessors for unplannedExpenses
extension Card {

    @objc(addUnplannedExpensesObject:)
    @NSManaged public func addToUnplannedExpenses(_ value: UnplannedExpense)

    @objc(removeUnplannedExpensesObject:)
    @NSManaged public func removeFromUnplannedExpenses(_ value: UnplannedExpense)

    @objc(addUnplannedExpenses:)
    @NSManaged public func addToUnplannedExpenses(_ values: NSSet)

    @objc(removeUnplannedExpenses:)
    @NSManaged public func removeFromUnplannedExpenses(_ values: NSSet)

}

extension Card : Identifiable {

}

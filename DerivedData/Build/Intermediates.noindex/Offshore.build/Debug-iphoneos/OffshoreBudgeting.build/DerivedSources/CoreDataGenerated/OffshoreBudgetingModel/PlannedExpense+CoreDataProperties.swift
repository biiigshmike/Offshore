//
//  PlannedExpense+CoreDataProperties.swift
//  
//
//  Created by Michael Brown on 10/30/25.
//
//  This file was automatically generated and should not be edited.
//

public import Foundation
public import CoreData


public typealias PlannedExpenseCoreDataPropertiesSet = NSSet

extension PlannedExpense {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<PlannedExpense> {
        return NSFetchRequest<PlannedExpense>(entityName: "PlannedExpense")
    }

    @NSManaged public var actualAmount: Double
    @NSManaged public var descriptionText: String?
    @NSManaged public var globalTemplateID: UUID?
    @NSManaged public var id: UUID?
    @NSManaged public var isGlobal: Bool
    @NSManaged public var plannedAmount: Double
    @NSManaged public var transactionDate: Date?
    @NSManaged public var workspaceID: UUID?
    @NSManaged public var budget: Budget?
    @NSManaged public var card: Card?
    @NSManaged public var expenseCategory: ExpenseCategory?

}

extension PlannedExpense : Identifiable {

}

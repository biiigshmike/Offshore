//
//  CategorySpendingCap+CoreDataProperties.swift
//  
//
//  Created by Michael Brown on 10/30/25.
//
//  This file was automatically generated and should not be edited.
//

public import Foundation
public import CoreData


public typealias CategorySpendingCapCoreDataPropertiesSet = NSSet

extension CategorySpendingCap {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<CategorySpendingCap> {
        return NSFetchRequest<CategorySpendingCap>(entityName: "CategorySpendingCap")
    }

    @NSManaged public var amount: Double
    @NSManaged public var expenseType: String?
    @NSManaged public var id: UUID?
    @NSManaged public var period: String?
    @NSManaged public var category: ExpenseCategory?

}

extension CategorySpendingCap : Identifiable {

}

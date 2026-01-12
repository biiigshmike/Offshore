//
//  Income+CoreDataProperties.swift
//  
//
//  Created by Michael Brown on 1/12/26.
//
//  This file was automatically generated and should not be edited.
//

public import Foundation
public import CoreData


public typealias IncomeCoreDataPropertiesSet = NSSet

extension Income {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Income> {
        return NSFetchRequest<Income>(entityName: "Income")
    }

    @NSManaged public var amount: Double
    @NSManaged public var date: Date?
    @NSManaged public var id: UUID?
    @NSManaged public var isPlanned: Bool
    @NSManaged public var parentID: UUID?
    @NSManaged public var recurrence: String?
    @NSManaged public var recurrenceEndDate: Date?
    @NSManaged public var secondPayDay: Int16
    @NSManaged public var source: String?
    @NSManaged public var workspaceID: UUID?

}

extension Income : Identifiable {

}

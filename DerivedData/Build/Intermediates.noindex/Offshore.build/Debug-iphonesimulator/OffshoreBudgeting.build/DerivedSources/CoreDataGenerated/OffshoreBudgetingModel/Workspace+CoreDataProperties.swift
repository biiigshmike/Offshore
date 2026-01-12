//
//  Workspace+CoreDataProperties.swift
//  
//
//  Created by Michael Brown on 1/12/26.
//
//  This file was automatically generated and should not be edited.
//

public import Foundation
public import CoreData


public typealias WorkspaceCoreDataPropertiesSet = NSSet

extension Workspace {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Workspace> {
        return NSFetchRequest<Workspace>(entityName: "Workspace")
    }

    @NSManaged public var budgetPeriod: String?
    @NSManaged public var budgetPeriodUpdatedAt: Date?
    @NSManaged public var color: String?
    @NSManaged public var id: UUID?
    @NSManaged public var isCloud: Bool
    @NSManaged public var name: String?

}

extension Workspace : Identifiable {

}

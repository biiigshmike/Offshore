//
//  Workspace+CoreDataProperties.swift
//  
//
//  Created by Michael Brown on 10/30/25.
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

    @NSManaged public var id: UUID?
    @NSManaged public var name: String?
    @NSManaged public var isCloud: Bool

}

extension Workspace : Identifiable {

}

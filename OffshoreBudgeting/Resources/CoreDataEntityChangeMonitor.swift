//
//  CoreDataEntityChangeMonitor.swift
//  SoFar
//
//  A small helper that watches Core Data change notifications and fires
//  a debounced callback only when specified entities are inserted/updated/deleted.
//  Use this to auto-refresh view models without flashing loaders.
//
//  Usage:
//    changeMonitor = CoreDataEntityChangeMonitor(
//        entityNames: ["Card"]
//    ) { [weak self] in
//        Task { await self?.loadAllCards(preserveLoadedFlag: true) }
//    }
//

import Foundation
import CoreData
import Combine

// MARK: - CoreDataEntityChangeMonitor
final class CoreDataEntityChangeMonitor {

    // MARK: Private
    private var cancellable: AnyCancellable?

    // MARK: Init
    /// - Parameters:
    ///   - entityNames: Entity names to listen for (e.g., ["Card"])
    ///   - debounceMilliseconds: Debounce to coalesce bursts of saves
    ///   - onRelevantChange: Called on the main thread when relevant entities change
    init(
        entityNames: [String],
        debounceMilliseconds: Int = 150,
        onRelevantChange: @escaping () -> Void
    ) {
        // IMPORTANT: Use the global Notification.Name constant.
        // (There is no `NSManagedObjectContext.objectsDidChangeNotification` static.)
        let entityNameSet = Set(entityNames)
        let relevantObjectKeys: [String] = [
            NSInsertedObjectsKey,
            NSUpdatedObjectsKey,
            NSDeletedObjectsKey,
            NSRefreshedObjectsKey,
            NSInvalidatedObjectsKey
        ]
        let relevantObjectIDKeys: [String] = [
            NSInsertedObjectIDsKey,
            NSUpdatedObjectIDsKey,
            NSDeletedObjectIDsKey,
            NSRefreshedObjectIDsKey,
            NSInvalidatedObjectIDsKey
        ]

        let objectsDidChangePublisher = NotificationCenter.default
            .publisher(for: .NSManagedObjectContextObjectsDidChange, object: nil)
            .compactMap { notification -> NotificationDedupToken? in
                guard
                    let userInfo = notification.userInfo,
                    CoreDataEntityChangeMonitor.containsRelevantObjects(
                        in: userInfo,
                        keys: relevantObjectKeys,
                        entityNameSet: entityNameSet
                    )
                else {
                    return nil
                }

                return NotificationDedupToken(notification: notification)
            }

        let didSavePublisher = NotificationCenter.default
            .publisher(for: .NSManagedObjectContextDidSave, object: nil)
            .compactMap { notification -> NotificationDedupToken? in
                guard
                    let userInfo = notification.userInfo,
                    CoreDataEntityChangeMonitor.containsRelevantObjects(
                        in: userInfo,
                        keys: relevantObjectKeys,
                        entityNameSet: entityNameSet
                    )
                else {
                    return nil
                }

                return NotificationDedupToken(notification: notification)
            }

        let didMergeObjectIDsPublisher = NotificationCenter.default
            .publisher(for: .NSManagedObjectContextDidMergeChangesObjectIDs, object: nil)
            .compactMap { notification -> NotificationDedupToken? in
                guard
                    let userInfo = notification.userInfo,
                    CoreDataEntityChangeMonitor.containsRelevantObjectIDs(
                        in: userInfo,
                        keys: relevantObjectIDKeys + relevantObjectKeys,
                        entityNameSet: entityNameSet
                    )
                else {
                    return nil
                }

                return NotificationDedupToken(notification: notification)
            }

        cancellable = objectsDidChangePublisher
            .merge(with: didSavePublisher)
            .merge(with: didMergeObjectIDsPublisher)
            .removeDuplicates()
            .debounce(for: .milliseconds(debounceMilliseconds), scheduler: RunLoop.main)
            .sink { _ in
                onRelevantChange()
            }
    }

    deinit {
        cancellable?.cancel()
    }
}

// MARK: - Private Helpers
private extension CoreDataEntityChangeMonitor {
    struct NotificationDedupToken: Equatable {
        let name: Notification.Name
        let objectIdentifier: ObjectIdentifier?

        init(notification: Notification) {
            name = notification.name
            if let object = notification.object as AnyObject? {
                objectIdentifier = ObjectIdentifier(object)
            } else {
                objectIdentifier = nil
            }
        }
    }

    static func containsRelevantObjects(
        in userInfo: [AnyHashable: Any],
        keys: [String],
        entityNameSet: Set<String>
    ) -> Bool {
        keys.contains { key in
            guard let objects = extractManagedObjects(from: userInfo[key]) else { return false }
            return objects.contains { object in
                guard let name = object.entity.name else { return false }
                return entityNameSet.contains(name)
            }
        }
    }

    static func containsRelevantObjectIDs(
        in userInfo: [AnyHashable: Any],
        keys: [String],
        entityNameSet: Set<String>
    ) -> Bool {
        keys.contains { key in
            guard let objectIDs = extractManagedObjectIDs(from: userInfo[key]) else { return false }
            return objectIDs.contains { objectID in
                guard let name = objectID.entity.name else { return false }
                return entityNameSet.contains(name)
            }
        }
    }

    static func extractManagedObjects(from value: Any?) -> [NSManagedObject]? {
        if let set = value as? Set<NSManagedObject> {
            return Array(set)
        }
        if let nsSet = value as? NSSet {
            return nsSet.compactMap { $0 as? NSManagedObject }
        }
        if let array = value as? [NSManagedObject] {
            return array
        }
        if let array = value as? [Any] {
            return array.compactMap { $0 as? NSManagedObject }
        }
        if let nsArray = value as? NSArray {
            return nsArray.compactMap { $0 as? NSManagedObject }
        }
        return nil
    }

    static func extractManagedObjectIDs(from value: Any?) -> [NSManagedObjectID]? {
        if let set = value as? Set<NSManagedObjectID> {
            return Array(set)
        }
        if let nsSet = value as? NSSet {
            return nsSet.compactMap { $0 as? NSManagedObjectID }
        }
        if let array = value as? [NSManagedObjectID] {
            return array
        }
        if let array = value as? [Any] {
            return array.compactMap { $0 as? NSManagedObjectID }
        }
        if let nsArray = value as? NSArray {
            return nsArray.compactMap { $0 as? NSManagedObjectID }
        }
        if let objects = extractManagedObjects(from: value) {
            return objects.map { $0.objectID }
        }
        return nil
    }
}

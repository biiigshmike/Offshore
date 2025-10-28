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
        let relevantKeys: [String] = [NSInsertedObjectsKey, NSUpdatedObjectsKey, NSDeletedObjectsKey]

        let objectsDidChangePublisher = NotificationCenter.default
            .publisher(for: .NSManagedObjectContextObjectsDidChange, object: nil)
            .compactMap { $0.userInfo }
            .map { userInfo -> Bool in
                relevantKeys.contains { key in
                    guard let objects = userInfo[key] as? Set<NSManagedObject> else { return false }
                    return objects.contains { object in
                        guard let name = object.entity.name else { return false }
                        return entityNameSet.contains(name)
                    }
                }
            }

        let didSavePublisher = NotificationCenter.default
            .publisher(for: .NSManagedObjectContextDidSave, object: nil)
            .compactMap { $0.userInfo }
            .map { userInfo -> Bool in
                relevantKeys.contains { key in
                    guard let objects = userInfo[key] as? Set<NSManagedObject> else { return false }
                    return objects.contains { object in
                        guard let name = object.entity.name else { return false }
                        return entityNameSet.contains(name)
                    }
                }
            }

        let didMergeObjectIDsPublisher = NotificationCenter.default
            .publisher(for: .NSManagedObjectContextDidMergeChangesObjectIDs, object: nil)
            .compactMap { $0.userInfo }
            .map { userInfo -> Bool in
                relevantKeys.contains { key in
                    guard let objectIDs = userInfo[key] as? Set<NSManagedObjectID> else { return false }
                    return objectIDs.contains { objectID in
                        guard let name = objectID.entity.name else { return false }
                        return entityNameSet.contains(name)
                    }
                }
            }

        cancellable = objectsDidChangePublisher
            .merge(with: didSavePublisher)
            .merge(with: didMergeObjectIDsPublisher)
            .filter { $0 } // keep only relevant changes
            .debounce(for: .milliseconds(debounceMilliseconds), scheduler: RunLoop.main)
            .sink { _ in
                onRelevantChange()
            }
    }

    deinit {
        cancellable?.cancel()
    }
}

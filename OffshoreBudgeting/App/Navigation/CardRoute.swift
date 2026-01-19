import Foundation
import CoreData

/// Stable navigation identity for Card detail routes.
///
/// Why this exists:
/// SwiftUI `NavigationLink(value:)` destinations can be re-created if the `Hashable`
/// value changes. `CardItem` is a UI model whose synthesized `Hashable` includes
/// display fields (name/theme/effect/balance), so normal updates can produce a new
/// value and cause destination re-creation (resetting local state like segmented
/// pickers). `CardRoute` keeps navigation identity stable by keying only on
/// persistent identity (Core Data objectID URI or UUID).
struct CardRoute: Hashable {
    enum Key: Hashable {
        case objectIDURI(URL)
        case uuid(UUID)
    }

    let key: Key

    init(objectID: NSManagedObjectID) {
        self.key = .objectIDURI(objectID.uriRepresentation())
    }

    init(uuid: UUID) {
        self.key = .uuid(uuid)
    }

    init?(cardItem: CardItem) {
        if let objectID = cardItem.objectID {
            self.init(objectID: objectID)
            return
        }
        if let uuid = cardItem.uuid {
            self.init(uuid: uuid)
            return
        }
        return nil
    }

    func resolveObjectID(using coordinator: NSPersistentStoreCoordinator) -> NSManagedObjectID? {
        switch key {
        case .objectIDURI(let url):
            return coordinator.managedObjectID(forURIRepresentation: url)
        case .uuid:
            return nil
        }
    }
}


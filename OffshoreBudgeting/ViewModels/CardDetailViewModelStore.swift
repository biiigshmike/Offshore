import Foundation
import CoreData

/// Keeps a single CardDetailViewModel instance per Card identity so that SwiftUI
/// view reconstruction does not recreate the view model and reset transient UI
/// state (e.g., segmented pickers for segment/sort).
@MainActor
final class CardDetailViewModelStore {
    static let shared = CardDetailViewModelStore()

    enum Key: Hashable {
        case objectID(NSManagedObjectID)
        case uuid(UUID)
    }

    private var cache: [Key: CardDetailViewModel] = [:]

    func viewModel(for card: CardItem,
                   context: NSManagedObjectContext = CoreDataService.shared.viewContext) -> CardDetailViewModel {
        let key: Key = {
            if let objectID = card.objectID {
                return .objectID(objectID)
            }
            if let uuid = card.uuid {
                return .uuid(uuid)
            }
            // Preview-only fallback: CardItem.id is stable enough within a session.
            return .uuid(UUID(uuidString: card.id) ?? UUID())
        }()

        if let existing = cache[key] {
            return existing
        }

        let vm = CardDetailViewModel(card: card, context: context)
        cache[key] = vm
        return vm
    }
}


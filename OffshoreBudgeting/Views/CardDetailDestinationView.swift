import SwiftUI
import CoreData

/// Navigation destination wrapper for Card detail that caches the resolved `CardItem`.
///
/// Rationale:
/// Even when the navigation value is stable (e.g., `CardRoute`), parent view updates can
/// cause the destination builder to re-run. If that builder re-resolves a *new* `CardItem`
/// (whose `Hashable` includes display fields like name/theme/balance), SwiftUI may treat
/// the destination as "new" and recreate `CardDetailView` / its `@StateObject` view model,
/// resetting segmented pickers.
///
/// This wrapper resolves once per route presentation and holds the snapshot in `@State`.
struct CardDetailDestinationView: View {
    let route: CardRoute
    @Binding var isPresentingAddExpense: Bool
    let onDone: () -> Void

    @State private var resolvedCard: CardItem?
    @State private var didResolve = false

    var body: some View {
        Group {
            if let resolvedCard {
                CardDetailView(
                    card: resolvedCard,
                    isPresentingAddExpense: $isPresentingAddExpense,
                    onDone: onDone
                )
            } else {
                ProgressView("Loading…")
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            }
        }
        .task {
            guard !didResolve else { return }
            didResolve = true
            resolvedCard = resolveCardItem(for: route)
        }
    }

    private func resolveCardItem(for route: CardRoute) -> CardItem? {
        switch route.key {
        case .objectIDURI:
            let coordinator = CoreDataService.shared.container.persistentStoreCoordinator
            guard let objectID = route.resolveObjectID(using: coordinator) else { return nil }
            let ctx = CoreDataService.shared.viewContext
            guard let card = try? ctx.existingObject(with: objectID) as? Card else { return nil }
            return CardItem(from: card)
        case .uuid(let uuid):
            let service = CardService()
            guard let card = (try? service.findCard(byID: uuid)) ?? nil else { return nil }
            return CardItem(from: card)
        }
    }
}


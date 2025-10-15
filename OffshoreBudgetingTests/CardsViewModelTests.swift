import Foundation
import CoreData
import Testing
@testable import Offshore

@MainActor
struct CardsViewModelTests {

    // MARK: - Helpers
    private func seedCard(name: String = "Primary Card", theme: CardTheme = .forest) throws -> (service: CardService, uuid: UUID, context: NSManagedObjectContext) {
        let container = try TestUtils.resetStore()
        let context = container.viewContext

        let cardService = CardService()
        let card = try cardService.createCard(name: name, ensureUniqueName: false)
        guard let uuid = card.value(forKey: "id") as? UUID else {
            #expect(false, "Expected card to expose UUID")
            throw NSError(domain: "CardsViewModelTests", code: 1)
        }

        CardAppearanceStore.shared.setTheme(theme, for: uuid)

        return (cardService, uuid, context)
    }

    private func waitForLoadedCards(
        in viewModel: CardsViewModel,
        timeout: TimeInterval = 2.0,
        predicate: ([CardItem]) -> Bool = { _ in true }
    ) async -> [CardItem]? {
        let step: UInt64 = 50_000_000
        let iterations = Int(timeout / 0.05)

        for _ in 0..<iterations {
            if case .loaded(let cards) = viewModel.state, predicate(cards) {
                return cards
            }
            try? await Task.sleep(nanoseconds: step)
        }

        if case .loaded(let cards) = viewModel.state, predicate(cards) {
            return cards
        }

        return nil
    }

    private func waitUntil(
        _ condition: () -> Bool,
        timeout: TimeInterval = 2.0
    ) async -> Bool {
        let step: UInt64 = 50_000_000
        let iterations = Int(timeout / 0.05)

        for _ in 0..<iterations {
            if condition() { return true }
            try? await Task.sleep(nanoseconds: step)
        }

        return condition()
    }

    // MARK: - Tests
    @Test
    func startIfNeeded_loads_seeded_card_and_theme() async throws {
        let (cardService, uuid, context) = try seedCard(theme: .sunset)
        defer { CardAppearanceStore.shared.removeTheme(for: uuid) }

        let viewModel = CardsViewModel(cardService: cardService)
        viewModel.startIfNeeded()

        guard let cards = await waitForLoadedCards(in: viewModel) else {
            #expect(false, "Expected loaded state, found \(viewModel.state)")
            return
        }

        #expect(cards.count == 1)
        guard let item = cards.first else {
            #expect(false, "Expected first card item")
            return
        }

        #expect(item.uuid == uuid)
        #expect(item.name == "Primary Card")
        #expect(item.theme == .sunset)
        #expect(!context.hasChanges)
    }

    @Test
    func reapplyThemes_refreshes_loaded_cards_without_coredata_writes() async throws {
        let (cardService, uuid, context) = try seedCard(theme: .ocean)
        defer { CardAppearanceStore.shared.removeTheme(for: uuid) }

        let viewModel = CardsViewModel(cardService: cardService)
        viewModel.startIfNeeded()

        guard let initialCards = await waitForLoadedCards(in: viewModel) else {
            #expect(false, "Expected loaded state, found \(viewModel.state)")
            return
        }

        guard let initialItem = initialCards.first else {
            #expect(false, "Expected an initial card")
            return
        }

        #expect(initialItem.theme == .ocean)
        #expect(!context.hasChanges)

        let updatedTheme: CardTheme = .midnight
        CardAppearanceStore.shared.setTheme(updatedTheme, for: uuid)
        NotificationCenter.default.post(name: UserDefaults.didChangeNotification, object: UserDefaults.standard)

        guard let updatedCards = await waitForLoadedCards(in: viewModel, predicate: { cards in
            cards.first?.theme == updatedTheme
        }) else {
            #expect(false, "Expected theme reapplication, found \(viewModel.state)")
            return
        }

        #expect(updatedCards.count == 1)
        #expect(updatedCards.first?.theme == updatedTheme)
        #expect(!context.hasChanges)
        #expect(context.insertedObjects.isEmpty)
        #expect(context.updatedObjects.isEmpty)
    }

    @Test
    func edit_handles_rename_and_theme_only_updates() async throws {
        let (cardService, uuid, context) = try seedCard(theme: .forest)
        defer { CardAppearanceStore.shared.removeTheme(for: uuid) }

        let viewModel = CardsViewModel(cardService: cardService)
        viewModel.startIfNeeded()

        guard let initialCards = await waitForLoadedCards(in: viewModel) else {
            #expect(false, "Expected loaded state, found \(viewModel.state)")
            return
        }

        guard let originalItem = initialCards.first else {
            #expect(false, "Expected initial card item")
            return
        }

        let renamed = "Renamed Card"
        await viewModel.edit(card: originalItem, name: renamed, theme: originalItem.theme)

        let renameObserved = await waitForLoadedCards(in: viewModel, predicate: { cards in
            cards.first?.name == renamed
        })

        guard let renamedCards = renameObserved, let renamedItem = renamedCards.first else {
            #expect(false, "Expected rename to propagate, found \(viewModel.state)")
            return
        }

        let fetchedCards = try cardService.fetchAllCards()
        #expect(fetchedCards.count == 1)
        #expect(fetchedCards.first?.name == renamed)

        let newTheme: CardTheme = renamedItem.theme == .midnight ? .sunset : .midnight
        await viewModel.edit(card: renamedItem, name: renamedItem.name, theme: newTheme)
        await Task.yield()

        guard case let .loaded(finalCards) = viewModel.state, let themedItem = finalCards.first else {
            #expect(false, "Expected loaded state after theme edit, found \(viewModel.state)")
            return
        }

        #expect(themedItem.theme == newTheme)
        #expect(themedItem.name == renamed)
        #expect(!context.hasChanges)
    }

    @Test
    func request_and_confirm_delete_honor_settings_and_cleanup_theme() async throws {
        let (cardService, uuid, _) = try seedCard(theme: .blossom)

        let viewModel = CardsViewModel(cardService: cardService)
        viewModel.startIfNeeded()

        guard let cards = await waitForLoadedCards(in: viewModel) else {
            #expect(false, "Expected loaded state, found \(viewModel.state)")
            return
        }

        guard let item = cards.first else {
            #expect(false, "Expected seeded card")
            return
        }

        UserDefaults.standard.set(true, forKey: AppSettingsKeys.confirmBeforeDelete.rawValue)
        defer { UserDefaults.standard.removeObject(forKey: AppSettingsKeys.confirmBeforeDelete.rawValue) }

        viewModel.requestDelete(card: item)
        guard let alert = viewModel.alert else {
            #expect(false, "Expected confirmation alert")
            return
        }

        switch alert.kind {
        case .confirmDelete(let pending):
            #expect(pending.id == item.id)
        default:
            #expect(false, "Expected confirm delete alert")
        }

        UserDefaults.standard.set(false, forKey: AppSettingsKeys.confirmBeforeDelete.rawValue)
        viewModel.alert = nil

        viewModel.requestDelete(card: item)
        let becameEmpty = await waitUntil({
            if case .empty = viewModel.state { return true }
            if case .loaded(let cards) = viewModel.state { return cards.isEmpty }
            return false
        })

        #expect(becameEmpty, "Expected state to become empty, found \(viewModel.state)")

        let remaining = try cardService.fetchAllCards()
        #expect(remaining.isEmpty)
        #expect(CardAppearanceStore.shared.theme(for: uuid) == .rose)
    }
}

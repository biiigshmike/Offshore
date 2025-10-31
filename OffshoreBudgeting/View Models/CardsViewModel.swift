//
//  CardsViewModel.swift
//  SoFar
//
//  Streams Cards via a CoreDataListObserver (NSFetchedResultsController).
//  Hardened against jitter by using stable identity when available (Core Data objectID)
//  and avoiding array animations after first load. Also supports preview items
//  (no Core Data) by allowing an optional objectID.
//
//  OOP-style notes:
//  - CardItem exposes optional `objectID` (stable identity when present) and optional
//    Core Data UUID attribute `uuid` for CardService interop.
//  - On rename/delete, we prefer CardService by UUID when available; otherwise fall
//    back to resolving the object via objectID.
//  - Previews (e.g., AddCardFormView live preview) can construct CardItem without
//    objectID/uuid.
//

import SwiftUI
import CoreData
import Combine   // NEW: for reactive theme refresh

// MARK: - CardsLoadState
enum CardsLoadState: Equatable {
    /// The view has not started loading yet.
    case initial
    /// Loading is in progress (and has taken >200ms).
    case loading
    /// Loading is complete, and there are no items.
    case empty
    /// Loading is complete, and there are items to display.
    case loaded([CardItem])
}

// MARK: - CardsViewAlert
struct CardsViewAlert: Identifiable {
    enum Kind {
        case error(message: String)
        case confirmDelete(card: CardItem)
        case rename(card: CardItem)
    }
    let id = UUID()
    let kind: Kind
}

// MARK: - CardsViewModel
@MainActor
final class CardsViewModel: ObservableObject {

    // MARK: Published State
    /// The single source of truth for the view's current state.
    @Published var state: CardsLoadState = .initial
    /// Alert state for errors/confirmations.
    @Published var alert: CardsViewAlert?
    /// Target card for rename sheet.
    @Published var renameTarget: CardItem?

    // MARK: Dependencies
    private let cardService: CardService
    private let appearanceStore: CardAppearanceStore
    private var observer: CoreDataListObserver<Card>?
    private var hasStarted = false
    private var pendingApply: DispatchWorkItem?
    private var latestSnapshot: [CardItem] = []
    private var lastLoadedAt: Date? = nil
    private var pendingThemeCleanup = Set<UUID>()
    private var dataStoreObserver: NSObjectProtocol?

    // MARK: Combine
    /// Holds reactive subscriptions (e.g., for theme refresh).
    private var cancellables = Set<AnyCancellable>() // NEW

    // MARK: Init
    init(cardService: CardService = CardService(),
         appearanceStore: CardAppearanceStore? = nil) {
        self.cardService = cardService
        let resolvedAppearanceStore = appearanceStore ?? CardAppearanceStore.shared
        self.appearanceStore = resolvedAppearanceStore

        // Reactive Theme Refresh (no store changes required)
        // Listens for UserDefaults changes (where CardAppearanceStore persists).
        // When themes change, re-apply values onto the current items without waiting for Core Data.
        NotificationCenter.default.publisher(for: UserDefaults.didChangeNotification)
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.reapplyThemes()
            }
            .store(in: &cancellables)
    }

    // MARK: startIfNeeded()
    /// Starts the Core Data stream exactly once.
    /// This uses a delayed transition to the `.loading` state to prevent
    /// the loading indicator from flashing on screen for fast loads.
    func startIfNeeded() {
        guard !hasStarted else { return }
        hasStarted = true

        if AppLog.isVerbose {
            AppLog.viewModel.info("CardsViewModel.startIfNeeded()")
        }

        // After a 200ms delay, if we are still in the `initial` state,
        // we transition to the `loading` state to show the shimmer UI.
        Task {
            try? await Task.sleep(nanoseconds: 200_000_000)
            if self.state == .initial {
                self.state = .loading
                if AppLog.isVerbose {
                    AppLog.viewModel.info("CardsViewModel -> state = loading")
                }
            }
        }

        // Immediately start the actual data fetch.
        Task { [weak self] in
            guard let self else { return }
            if !CoreDataService.shared.storesLoaded {
                await CoreDataService.shared.waitUntilStoresLoaded(timeout: 3.0, pollInterval: 0.05)
            }
            if AppLog.isVerbose {
                AppLog.viewModel.info("CardsViewModel configuring observer")
            }
            self.configureAndStartObserver()
        }

        // Also listen for broad data store changes (e.g., remote CloudKit imports),
        // and force a refresh so deletions from other devices disappear without
        // requiring an app restart.
        if dataStoreObserver == nil {
            dataStoreObserver = NotificationCenter.default.addObserver(
                forName: .dataStoreDidChange,
                object: nil,
                queue: .main
            ) { [weak self] _ in
                Task { await self?.refresh() }
            }
        }
    }

    // MARK: refresh()
    /// Rebuilds the observer to force a manual reload of cards.
    func refresh() async {
        guard hasStarted else {
            startIfNeeded()
            return
        }

        observer?.stop()
        observer = nil

        if !CoreDataService.shared.storesLoaded {
            await CoreDataService.shared.waitUntilStoresLoaded(timeout: 3.0, pollInterval: 0.05)
        }
        configureAndStartObserver()
    }

    // MARK: configureAndStartObserver()
    /// Builds the fetch request/observer and starts streaming updates.
    private func configureAndStartObserver() {
        let request: NSFetchRequest<Card> = Card.fetchRequest()
        request.sortDescriptors = [
            NSSortDescriptor(key: "name", ascending: true, selector: #selector(NSString.localizedCaseInsensitiveCompare(_:)))
        ]

        observer = CoreDataListObserver(
            request: request,
            context: CoreDataService.shared.viewContext
        ) { [weak self] managedObjects in
            guard let self else { return }

            // Map Core Data -> UI items (use stable objectID)
            let mappedItems: [CardItem] = managedObjects.map { managedObject in
                let uuid = managedObject.value(forKey: "id") as? UUID
                let theme: CardTheme = {
                    if let uuid { return self.appearanceStore.theme(for: uuid) }
                    // If an old row is missing `id`, show a stable local default.
                    return .graphite
                }()

                return CardItem(
                    objectID: managedObject.objectID,
                    uuid: uuid,
                    name: managedObject.name ?? "Untitled",
                    theme: theme
                )
            }

            // Debounce UI application to coalesce bursts during imports
            self.latestSnapshot = mappedItems
            self.pendingApply?.cancel()
            var delayMS = DataChangeDebounce.milliseconds()
            // If we're about to emit an empty state shortly after a loaded state,
            // hold the transition a bit longer to avoid visible flapping during
            // CloudKit imports or batched merges. Any subsequent non-empty will
            // cancel the pending apply.
            if mappedItems.isEmpty {
                let now = Date()
                if let last = self.lastLoadedAt, now.timeIntervalSince(last) < 1.2 {
                    delayMS = max(delayMS, 900)
                }
                #if canImport(UIKit)
                if UserDefaults.standard.bool(forKey: AppSettingsKeys.enableCloudSync.rawValue), CloudSyncMonitor.shared.isImporting {
                    delayMS = max(delayMS, 1100)
                }
                #endif
            }
            let work = DispatchWorkItem { [weak self] in
                guard let self else { return }
                let items = self.latestSnapshot
                // If any theme deletions are pending for cards that are no longer present,
                // clean them up now to avoid triggering a defaults change while the row exists.
                let presentUUIDs = Set(items.compactMap { $0.uuid })
                let readyToRemove = self.pendingThemeCleanup.subtracting(presentUUIDs)
                if !readyToRemove.isEmpty {
                    for uuid in readyToRemove { self.appearanceStore.removeTheme(for: uuid) }
                    self.pendingThemeCleanup.subtract(readyToRemove)
                }
                if items.isEmpty {
                    self.state = .empty
                    if AppLog.isVerbose {
                        AppLog.viewModel.info("CardsViewModel -> state = empty")
                    }
                } else {
                    self.state = .loaded(items)
                    self.lastLoadedAt = Date()
                    if AppLog.isVerbose {
                        AppLog.viewModel.info("CardsViewModel -> state = loaded (\(items.count))")
                    }
                }
            }
            self.pendingApply = work
            DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(delayMS), execute: work)
        }

        observer?.start()
    }

    // MARK: addCard(name:theme:)
    /// Creates a new card and persists the user's chosen theme.
    /// - Parameters:
    ///   - name: Display name.
    ///   - theme: Initial card theme.
    func addCard(name: String, theme: CardTheme) async {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            self.alert = CardsViewAlert(kind: .error(message: "Please enter a card name."))
            return
        }

        do {
            let created = try cardService.createCard(name: trimmed, ensureUniqueName: true)
            if let newUUID = created.value(forKey: "id") as? UUID {
                // Persist theme first so the next FRC snapshot uses it instead of default .rose
                appearanceStore.setTheme(theme, for: newUUID)
                // Force a refresh to ensure the newly-inserted row picks up the stored theme
                await refresh()
                // Also re-apply on existing snapshot in case we're already loaded
                reapplyThemes()
            }
        } catch {
            self.alert = CardsViewAlert(kind: .error(message: error.localizedDescription))
        }
    }

    // MARK: promptRename(for:)
    /// Opens rename flow for a specific card item.
    func promptRename(for card: CardItem) {
        renameTarget = card
    }

    // MARK: rename(card:to:)
    /// Renames a card via service. UI auto-updates via observer.
    func rename(card: CardItem, to newName: String) async {
        do {
            if let uuid = card.uuid, let managed = try cardService.findCard(byID: uuid) {
                try cardService.renameCard(managed, to: newName)
            } else if let oid = card.objectID, let managed = try? CoreDataService.shared.viewContext.existingObject(with: oid) as? Card {
                try cardService.renameCard(managed, to: newName)
            }
            renameTarget = nil
        } catch {
            self.alert = CardsViewAlert(kind: .error(message: error.localizedDescription))
        }
    }

    // MARK: requestDelete(card:)
    /// Presents confirmation to delete a card.
    func requestDelete(card: CardItem) {
        let confirm = UserDefaults.standard.object(
            forKey: AppSettingsKeys.confirmBeforeDelete.rawValue
        ) as? Bool ?? true
        if confirm {
            alert = CardsViewAlert(kind: .confirmDelete(card: card))
        } else {
            Task { await confirmDelete(card: card) }
        }
    }

    // MARK: confirmDelete(card:)
    /// Deletes a card and cleans up its theme.
    func confirmDelete(card: CardItem) async {
        do {
            if let uuid = card.uuid, let managed = try cardService.findCard(byID: uuid) {
                try cardService.deleteCard(managed)
            } else if let oid = card.objectID, let managed = try? CoreDataService.shared.viewContext.existingObject(with: oid) as? Card {
                try cardService.deleteCard(managed)
            }
            // Defer theme cleanup until after the row disappears from the grid to avoid
            // a UserDefaults change reapplying a default `.rose` before removal.
            if let uuid = card.uuid { pendingThemeCleanup.insert(uuid) }
        } catch {
            self.alert = CardsViewAlert(kind: .error(message: error.localizedDescription))
        }
    }

    // MARK: edit(card:name:theme:)
    /// Updates a card's name and/or theme. Triggers immediate UI refresh if only theme changes.
    /// - Parameters:
    ///   - card: The UI card item being edited.
    ///   - name: New display name.
    ///   - theme: New theme selection.
    func edit(card: CardItem, name: String, theme: CardTheme) async {
        do {
            var didRename = false
            if let uuid = card.uuid, let managed = try cardService.findCard(byID: uuid) {
                if (managed.value(forKey: "name") as? String) != name {
                    try cardService.renameCard(managed, to: name)
                    didRename = true
                }
            } else if let oid = card.objectID, let managed = try? CoreDataService.shared.viewContext.existingObject(with: oid) as? Card {
                if (managed.value(forKey: "name") as? String) != name {
                    try cardService.renameCard(managed, to: name)
                    didRename = true
                }
            }
            if let uuid = card.uuid {
                appearanceStore.setTheme(theme, for: uuid)
            }
            // If only the theme changed (no rename/Core Data write), re-apply themes to update UI right away.
            if !didRename {
                reapplyThemes()
            }
        } catch {
            self.alert = CardsViewAlert(kind: .error(message: error.localizedDescription))
        }
    }

    // MARK: reapplyThemes()
    /// Re-reads the theme for each currently loaded item from `CardAppearanceStore`
    /// and emits a new `.loaded` state so the grid re-renders without Core Data changes.
    private func reapplyThemes() {
        guard case .loaded(let items) = state else { return }
        let updated = items.map { item -> CardItem in
            var copy = item
            if let uuid = item.uuid {
                copy.theme = appearanceStore.theme(for: uuid)
            } else {
                copy.theme = .graphite
            }
            return copy
        }
        state = .loaded(updated)
    }

    deinit {
        if let observer = dataStoreObserver { NotificationCenter.default.removeObserver(observer) }
    }
}

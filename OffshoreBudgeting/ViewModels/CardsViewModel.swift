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
    
    private var observer: CoreDataListObserver<Card>?
    private var hasStarted = false
    private var pendingApply: DispatchWorkItem?
    private var latestSnapshot: [CardItem] = []
    private var lastLoadedAt: Date? = nil
    
    private var dataStoreObserver: NSObjectProtocol?

    // MARK: Combine
    

    // MARK: Init
    init(cardService: CardService = CardService()) {
        UBPerfDI.resolve("Init.CardsViewModel", every: 1)
        self.cardService = cardService

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
        UBPerfDI.resolve("CardsViewModel.configureAndStartObserver", every: 10)
        let request: NSFetchRequest<Card> = Card.fetchRequest()
        request.predicate = WorkspaceService.shared.activeWorkspacePredicate()
        request.sortDescriptors = [
            NSSortDescriptor(key: "name", ascending: true, selector: #selector(NSString.localizedCaseInsensitiveCompare(_:)))
        ]

        observer = CoreDataListObserver(
            request: request,
            context: CoreDataService.shared.viewContext
        ) { [weak self] managedObjects in
            guard let self else { return }

            // Map Core Data -> UI items (use stable objectID)
            let mappedItems: [CardItem] = UBPerf.measure("CardsViewModel.mapSnapshot") {
                managedObjects.map { managedObject in
                    let uuid = managedObject.value(forKey: "id") as? UUID
                    // Prefer Core Data attribute first; fallback to legacy appearance store
                    let theme: CardTheme = {
                        if managedObject.entity.attributesByName["theme"] != nil,
                           let raw = managedObject.value(forKey: "theme") as? String,
                           let t = CardTheme(rawValue: raw) { return t }
                        // Default neutral theme if missing
                        return .graphite
                    }()

                    let effect: CardEffect = {
                        guard managedObject.entity.attributesByName["effect"] != nil else { return .plastic }
                        let raw = managedObject.value(forKey: "effect") as? String
                        return CardEffect.fromStoredValue(raw)
                    }()

                    return CardItem(
                        objectID: managedObject.objectID,
                        uuid: uuid,
                        name: managedObject.name ?? "Untitled",
                        theme: theme,
                        effect: effect
                    )
                }
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
                if (UserDefaultsAppSettingsStore().bool(for: .enableCloudSync) ?? false), CloudSyncMonitor.shared.isImporting {
                    delayMS = max(delayMS, 1100)
                }
                #endif
            }
            let work = DispatchWorkItem { [weak self] in
                guard let self else { return }
                let items = self.latestSnapshot
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
    /// Creates a new card and persists the user's chosen theme and effect.
    /// - Parameters:
    ///   - name: Display name.
    ///   - theme: Initial card theme.
    ///   - effect: Initial card effect.
    func addCard(name: String, theme: CardTheme, effect: CardEffect) async {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            self.alert = CardsViewAlert(kind: .error(message: "Please enter a card name."))
            return
        }

        do {
            let created = try cardService.createCard(name: trimmed, ensureUniqueName: true)
            // Persist theme to Core Data so the FRC snapshot includes it atomically
            try cardService.updateCard(created, name: nil, theme: theme, effect: effect)
            // Force a refresh to ensure the newly-inserted row picks up the stored theme
            await refresh()
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
        let confirm = UserDefaultsAppSettingsStore().bool(for: .confirmBeforeDelete) ?? true
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
            // Post-delete nudge to encourage prompt CloudKit push delivery
            CloudSyncAccelerator.shared.nudgeOnForeground()
        } catch {
            self.alert = CardsViewAlert(kind: .error(message: error.localizedDescription))
        }
    }

    // MARK: edit(card:name:theme:)
    /// Updates a card's name/theme/effect. Triggers immediate UI refresh if only theme/effect changes.
    /// - Parameters:
    ///   - card: The UI card item being edited.
    ///   - name: New display name.
    ///   - theme: New theme selection.
    ///   - effect: New effect selection.
    func edit(card: CardItem, name: String, theme: CardTheme, effect: CardEffect) async {
        do {
            var didRename = false
            if let uuid = card.uuid, let managed = try cardService.findCard(byID: uuid) {
                if (managed.value(forKey: "name") as? String) != name {
                    try cardService.renameCard(managed, to: name)
                    didRename = true
                }
                // Persist theme on Core Data
                try cardService.updateCard(managed, name: nil, theme: theme, effect: effect)
            } else if let oid = card.objectID, let managed = try? CoreDataService.shared.viewContext.existingObject(with: oid) as? Card {
                if (managed.value(forKey: "name") as? String) != name {
                    try cardService.renameCard(managed, to: name)
                    didRename = true
                }
                // Persist theme on Core Data (uuid may be nil here)
                try cardService.updateCard(managed, name: nil, theme: theme, effect: effect)
            }
            // If only the theme/effect changed (no rename), refresh UI promptly
            if !didRename { reapplyThemes() }
        } catch {
            self.alert = CardsViewAlert(kind: .error(message: error.localizedDescription))
        }
    }

    // MARK: reapplyThemes()
    /// Re-reads the theme/effect for each currently loaded item from Core Data
    /// and emits a new `.loaded` state so the grid re-renders immediately.
    private func reapplyThemes() {
        guard case .loaded(let items) = state else { return }
        let ctx = CoreDataService.shared.viewContext
        let updated = items.map { item -> CardItem in
            var copy = item
            if let oid = item.objectID,
               let managed = try? ctx.existingObject(with: oid) as? Card,
               managed.entity.attributesByName["theme"] != nil,
               let raw = managed.value(forKey: "theme") as? String,
               let t = CardTheme(rawValue: raw) {
                copy.theme = t
            } else {
                copy.theme = .graphite
            }
            if let oid = item.objectID,
               let managed = try? ctx.existingObject(with: oid) as? Card,
               managed.entity.attributesByName["effect"] != nil {
                let raw = managed.value(forKey: "effect") as? String
                copy.effect = CardEffect.fromStoredValue(raw)
            } else {
                copy.effect = .plastic
            }
            return copy
        }
        state = .loaded(updated)
    }

    deinit {
        if let observer = dataStoreObserver { NotificationCenter.default.removeObserver(observer) }
    }
}

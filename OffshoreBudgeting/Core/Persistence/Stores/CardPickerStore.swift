//
//  CardPickerStore.swift
//  OffshoreBudgeting
//
//  Centralizes card fetching for picker UIs so that sheets can render
//  instantly and react to Core Data changes without performing repeated
//  fetch requests.
//

import Foundation
import CoreData

// MARK: - CardPickerStore
@MainActor
final class CardPickerStore: ObservableObject {

    // MARK: Published State
    @Published private(set) var cards: [Card] = []
    @Published private(set) var isReady = false

    // MARK: Dependencies
    private var contextProvider: (() -> NSManagedObjectContext)?
    private var context: NSManagedObjectContext?

    // MARK: Observation
    private var observer: CoreDataListObserver<Card>?
    private var hasStarted = false
    private var workspaceObserver: NSObjectProtocol?

    // MARK: Init
    /// Defer resolving the Core Data context until `start()` to avoid
    /// performing main-thread I/O during app initialization.
    init(contextProvider: @escaping () -> NSManagedObjectContext = { CoreDataService.shared.viewContext }) {
        self.contextProvider = contextProvider
    }

    // MARK: start()
    func start() {
        guard !hasStarted else { return }
        hasStarted = true

        Task { @MainActor [weak self] in
            guard let self else { return }
            if self.context == nil {
                self.context = self.contextProvider?()
                self.contextProvider = nil
            }
            await CoreDataService.shared.waitUntilStoresLoaded()
            configureObserverIfNeeded()
            observer?.start()
            observeWorkspaceChanges()
        }
    }

    // MARK: Private Helpers
    private func configureObserverIfNeeded() {
        guard observer == nil else { return }
        guard let context else { return }

        let request = makeFetchRequest()
        observer = CoreDataListObserver(request: request, context: context) { [weak self] cards in
            Task { @MainActor [weak self] in
                guard let self else { return }
                self.cards = cards
                self.isReady = true
            }
        }
    }

    private func makeFetchRequest() -> NSFetchRequest<Card> {
        let request = NSFetchRequest<Card>(entityName: "Card")
        if let workspaceID = WorkspaceService.activeWorkspaceIDFromDefaults() {
            request.predicate = WorkspaceService.predicate(for: workspaceID)
        }
        request.sortDescriptors = [
            NSSortDescriptor(
                key: "name",
                ascending: true,
                selector: #selector(NSString.localizedCaseInsensitiveCompare(_:))
            )
        ]
        return request
    }

    private func observeWorkspaceChanges() {
        guard workspaceObserver == nil else { return }
        workspaceObserver = NotificationCenter.default.addObserver(
            forName: .workspaceDidChange,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self else { return }
                self.observer?.stop()
                self.observer = nil
                self.configureObserverIfNeeded()
                self.observer?.start()
            }
        }
    }

    deinit {
        observer?.stop()
        if let workspaceObserver { NotificationCenter.default.removeObserver(workspaceObserver) }
    }
}

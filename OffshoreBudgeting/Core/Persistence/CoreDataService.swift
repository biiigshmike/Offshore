//
//  CoreDataService.swift
//  SoFar
//
//  Created by Michael Brown on 8/11/25.
//

import Foundation
import CoreData

// MARK: - CoreDataService
/// Centralized Core Data stack with optional iCloud/CloudKit mirroring.
/// Defaults to local-only; can rebuild stores to enable CloudKit when requested.
final class CoreDataService: ObservableObject {

    // MARK: Singleton
    static let shared = CoreDataService()

    private let notificationCenter: NotificationCentering
    private var cloudAvailabilityProvider: CloudAvailabilityProviding?

    private init(notificationCenter: NotificationCentering = NotificationCenterAdapter.shared,
                 cloudAvailabilityProvider: CloudAvailabilityProviding? = nil) {
        self.notificationCenter = notificationCenter
        self.cloudAvailabilityProvider = cloudAvailabilityProvider
    }

#if DEBUG
    private static var isUITesting: Bool {
        ProcessInfo.processInfo.arguments.contains("-ui-testing")
    }

    private static func uiTestStoreOverride() -> NSPersistentStoreDescription? {
        guard isUITesting else { return nil }
        let env = ProcessInfo.processInfo.environment
        if let path = env["UITEST_STORE_PATH"], !path.isEmpty {
            let url = URL(fileURLWithPath: path)
            return NSPersistentStoreDescription(url: url)
        }
        guard let raw = env["UITEST_STORE"]?.lowercased(), !raw.isEmpty else { return nil }
        switch raw {
        case "memory", "inmemory", "in-memory":
            let description = NSPersistentStoreDescription()
            description.type = NSInMemoryStoreType
            return description
        case "temp", "temporary":
            let base = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
            let url = base.appendingPathComponent("OffshoreBudgetingUITest-\(UUID().uuidString).sqlite")
            return NSPersistentStoreDescription(url: url)
        default:
            return nil
        }
    }
#endif
    
    // MARK: Configuration
    /// Name of the .xcdatamodeld file (without extension).
    /// IMPORTANT: Ensure your model is named "SoFarModel.xcdatamodeld".
    private let modelName = "OffshoreBudgetingModel"
    /// CloudKit container identifier (must match entitlements / dashboard).
    /// Use the single source of truth from CloudKitConfig to avoid drift.
    private var cloudKitContainerIdentifier: String { CloudKitConfig.containerIdentifier }
    
    /// Reads the user's preference to enable CloudKit sync.
    private var enableCloudKitSync: Bool {
        UserDefaults.standard.bool(forKey: AppSettingsKeys.enableCloudSync.rawValue)
    }

    private var loadingTask: Task<Void, Never>?
    
    // MARK: Load State
    /// Tracks whether persistent stores have been loaded at least once.
    private(set) var storesLoaded: Bool = false

    // MARK: Change Observers
    /// Observers for Core Data saves and remote changes that trigger view updates.
    private var didSaveObserver: NSObjectProtocol?
    private var remoteChangeObserver: NSObjectProtocol?
    private var cloudKitEventObserver: NSObjectProtocol?
    private var isRebuildingStores: Bool = false
    
    // Tracks the currently-configured mode of the persistent store description.
    private var _currentMode: PersistentStoreMode = .local
    private var currentMode: PersistentStoreMode { _currentMode }

    /// Human‑readable description of the active persistent store mode for diagnostics.
    public var storeModeDescription: String { _currentMode == .cloudKit ? "CloudKit" : "Local" }
    /// Convenience flag used by diagnostics/UI to indicate whether CloudKit mirroring is active.
    public var isCloudStoreActive: Bool { _currentMode == .cloudKit }

#if DEBUG
    // MARK: Test Helpers
    /// Debug-only initializer for tests that supply an already-loaded container.
    /// Keeps production behavior unchanged (shared still uses the default init).
    init(testContainer: NSPersistentContainer,
         notificationCenter: NotificationCentering = NotificationCenterAdapter.shared,
         cloudAvailabilityProvider: CloudAvailabilityProviding? = nil) {
        self.notificationCenter = notificationCenter
        self.cloudAvailabilityProvider = cloudAvailabilityProvider
        self.container = testContainer
        self.storesLoaded = true
        self._currentMode = .local
    }

    /// Enables dataStoreDidChange posts for test-driven context saves.
    func enableChangeNotificationsForTests() {
        startObservingChanges()
    }
#endif
    
    // MARK: Persistent Container
    /// Expose the container as NSPersistentContainer (backed by NSPersistentCloudKitContainer).
    /// In local mode, CloudKit options are omitted; in cloud mode, mirroring is configured.
    public lazy var container: NSPersistentContainer = {
        // Always use the CloudKit-capable subclass so we can toggle modes without recreating the type.
        let cloudContainer = NSPersistentCloudKitContainer(name: modelName)

        var description: NSPersistentStoreDescription
#if DEBUG
        if let override = Self.uiTestStoreOverride() {
            description = override
        } else {
            let storeURL = NSPersistentContainer.defaultDirectoryURL()
                .appendingPathComponent("\(modelName).sqlite")
            description = NSPersistentStoreDescription(url: storeURL)
        }
#else
        let storeURL = NSPersistentContainer.defaultDirectoryURL()
            .appendingPathComponent("\(modelName).sqlite")
        description = NSPersistentStoreDescription(url: storeURL)
#endif

        // MARK: Store Options (common)
        // Keep history ON to support merges and avoid read-only reopen issues.
        description.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
        description.setOption(true as NSNumber, forKey: NSMigratePersistentStoresAutomaticallyOption)
        description.setOption(true as NSNumber, forKey: NSInferMappingModelAutomaticallyOption)

        // Initial mode selection: if the user has already enabled CloudKit sync,
        // start in CloudKit mode to avoid an immediate rebuild after launch.
        // This is safe even if iCloud account is temporarily unavailable —
        // the store still loads and begins mirroring when possible.
        let initialMode: PersistentStoreMode = {
#if DEBUG
            if Self.isUITesting, Self.uiTestStoreOverride() != nil {
                return .local
            }
#endif
            return enableCloudKitSync ? .cloudKit : .local
        }()
        configure(description: description, for: initialMode)

        cloudContainer.persistentStoreDescriptions = [description]
        _currentMode = initialMode
        return cloudContainer
    }()
    
    // MARK: Contexts
    /// Main thread context for UI work.
    public var viewContext: NSManagedObjectContext {
        container.viewContext
    }
    
    /// Background context (on-demand) for write-heavy operations.
    func newBackgroundContext() -> NSManagedObjectContext {
        let context = container.newBackgroundContext()
        context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        context.automaticallyMergesChangesFromParent = true
        return context
    }
    
    // MARK: Lifecycle
    /// Preferred: call this once during app launch. Safe to call multiple times.
    @MainActor
    func ensureLoaded(file: StaticString = #file, line: UInt = #line) {
        guard !storesLoaded else { return }

        if loadingTask != nil { return }

        loadingTask = Task { @MainActor [weak self] in
            guard let self else { return }
            await self.loadStores(file: file, line: line)
        }
    }
    
    /// Backwards-compat alias for older call sites.
    @MainActor
    func loadPersistentStores() {
        ensureLoaded()
    }
    
    // MARK: Post-Load Configuration
    /// Configure viewContext behaviors after stores load.
    private func postLoadConfiguration() {
        // Merge changes from background contexts so UI updates automatically.
        viewContext.automaticallyMergesChangesFromParent = true
        // Align with Apple guidance for UI contexts: prefer in‑memory edits over store values
        // on conflict, and automatically merge background/imported changes so FRCs update
        // live when CloudKit mirroring applies remote transactions (including deletions).
        viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        // Optional: performance niceties
        viewContext.undoManager = nil

        // Begin monitoring Core Data saves and remote changes.
        startObservingChanges()
        startObservingRemoteChangesIfNeeded()
        startObservingCloudKitEventsIfNeeded()

        // Note: Schema initialization is intentionally not performed automatically to
        // avoid blocking the main thread during enablement.
    }

    // MARK: Change Observation
    /// Listens for context saves and posts a unified `.dataStoreDidChange`
    /// notification so views can react centrally.
    private func startObservingChanges() {
        // Avoid duplicate observers if called more than once.
        if didSaveObserver != nil { return }

        let center = notificationCenter

        didSaveObserver = center.addObserver(
            forName: .NSManagedObjectContextDidSave,
            object: nil,
            queue: .main
        ) { _ in
            center.post(name: .dataStoreDidChange, object: nil)
        }

        // Remote change observation is configured separately when CloudKit is enabled.
    }

    private func startObservingRemoteChangesIfNeeded() {
        guard remoteChangeObserver == nil else { return }
        guard currentMode == .cloudKit else { return }
        remoteChangeObserver = notificationCenter.addObserver(
            forName: .NSPersistentStoreRemoteChange,
            object: container.persistentStoreCoordinator,
            queue: .main
        ) { [weak self] _ in
            guard let self else { return }
            self.notificationCenter.post(name: .dataStoreDidChange, object: nil)
        }
    }

    private func startObservingCloudKitEventsIfNeeded() {
        guard cloudKitEventObserver == nil else { return }
        guard currentMode == .cloudKit else { return }
        cloudKitEventObserver = notificationCenter.addObserver(
            forName: NSPersistentCloudKitContainer.eventChangedNotification,
            object: nil,
            queue: .main
        ) { note in
            if let event = note.userInfo?[NSPersistentCloudKitContainer.eventNotificationUserInfoKey] as? NSPersistentCloudKitContainer.Event {
                AppLog.iCloud.info("CloudKit event: type=\(event.type.rawValue, privacy: .public) succeeded=\(event.succeeded, privacy: .public) error=\(String(describing: event.error), privacy: .public)")
            } else {
                AppLog.iCloud.info("CloudKit event changed")
            }
        }
    }
    
    // MARK: Save
    /// Saves the main context if there are changes. Call from the main thread.
    /// - Throws: Propagates save errors for calling site to handle (or convert to alerts).
    func saveIfNeeded() throws {
        // Defensive: make sure at least one store is attached
        let hasStores = !(viewContext.persistentStoreCoordinator?.persistentStores.isEmpty ?? true)
        guard hasStores else {
            throw NSError(domain: "SoFar.CoreData", code: 1001, userInfo: [
                NSLocalizedDescriptionKey: "Persistent stores are not loaded. Call CoreDataService.shared.ensureLoaded() at app launch."
            ])
        }
        guard viewContext.hasChanges else { return }
        try viewContext.save()
    }

    // MARK: Await Stores Loaded (Tiny helper)
    /// Suspends until `storesLoaded` is true. Optionally provide a timeout to
    /// prevent indefinite waiting when debugging store configuration issues.
    @MainActor
    func waitUntilStoresLoaded(timeout: TimeInterval? = nil, pollInterval: TimeInterval = 0.05) async {
        if storesLoaded { return }
        ensureLoaded()

        let start = Date()
        while !storesLoaded {
            if Task.isCancelled { return }

            if let timeout, Date().timeIntervalSince(start) >= timeout {
                if AppLog.isVerbose {
                    AppLog.coreData.info("waitUntilStoresLoaded() timed out after \(timeout)s while awaiting persistent stores")
                }
                return
            }

            try? await Task.sleep(nanoseconds: UInt64(pollInterval * 1_000_000_000))
        }
        if AppLog.isVerbose {
            AppLog.coreData.debug("waitUntilStoresLoaded() finished after \(String(format: "%.2f", Date().timeIntervalSince(start)))s")
        }
    }

    // MARK: - Reset
    /// Completely remove all data from the persistent store.
    func wipeAllData() throws {
        let context = viewContext
        var didMergeDeletes = false
        let storeTypes = container.persistentStoreCoordinator.persistentStores.map(\.type)
        let usesBatchDelete = !storeTypes.contains(NSInMemoryStoreType)

        try context.performAndWait {
            var deletedObjectIDs = Set<NSManagedObjectID>()

            for entity in container.managedObjectModel.entities {
                guard let name = entity.name else { continue }
                let fetch = NSFetchRequest<NSFetchRequestResult>(entityName: name)
                if usesBatchDelete {
                    let request = NSBatchDeleteRequest(fetchRequest: fetch)
                    request.resultType = .resultTypeObjectIDs

                    let result = try context.execute(request) as? NSBatchDeleteResult
                    if let ids = result?.result as? [NSManagedObjectID] {
                        deletedObjectIDs.formUnion(ids)
                    }
                } else {
                    fetch.includesPropertyValues = false
                    let objects = try context.fetch(fetch)
                    for case let object as NSManagedObject in objects {
                        context.delete(object)
                    }
                }
            }

            if !usesBatchDelete, context.hasChanges {
                try context.save()
                if !context.registeredObjects.isEmpty {
                    context.reset()
                }
                didMergeDeletes = true
                return
            }

            guard !deletedObjectIDs.isEmpty else { return }

            let changes: [AnyHashable: Any] = [
                NSDeletedObjectsKey: Array(deletedObjectIDs)
            ]
            NSManagedObjectContext.mergeChanges(fromRemoteContextSave: changes, into: [context])

            if !context.registeredObjects.isEmpty {
                context.reset()
            }

            didMergeDeletes = true
        }

        if didMergeDeletes {
            notificationCenter.post(name: .dataStoreDidChange, object: nil)
        }
    }
}

// MARK: - Cloud Sync Preferences

extension CoreDataService {

    /// Applies the user's Cloud Sync preference and reconfigures persistent stores accordingly.
    /// - Parameter enableSync: When `true`, persistent stores rebuild for CloudKit mode; otherwise they revert to local mode.
    @MainActor
    func applyCloudSyncPreferenceChange(enableSync: Bool) async {
        // Yield to the runloop so any pending UI (e.g., spinners) can render
        await Task.yield()
        if isRebuildingStores { return }
        isRebuildingStores = true
        defer { isRebuildingStores = false }

        // Avoid concurrent loads/rebuilds. Let any in-flight load complete first.
        await waitUntilStoresLoaded(timeout: 10.0)

        if enableSync {
            if currentMode == .cloudKit { return }
            let available = await resolvedCloudAvailabilityProvider.resolveAvailability(forceRefresh: true)
            guard available else {
                // iCloud (named container) currently unavailable. Keep the user's
                // preference intact, but remain in local mode to avoid breaking UX.
                if AppLog.isVerbose { AppLog.iCloud.info("Cloud unavailable – staying in local mode while keeping preference enabled") }
                await reconfigurePersistentStoresForLocalMode()
                return
            }
            await rebuildPersistentStores(for: .cloudKit)
        } else {
            if currentMode == .local { return }
            await reconfigurePersistentStoresForLocalMode()
        }
    }
}

// MARK: - Private Helpers

private extension CoreDataService {
    @MainActor
    var resolvedCloudAvailabilityProvider: CloudAvailabilityProviding {
        if let provider = cloudAvailabilityProvider { return provider }
        let provider = CloudAccountStatusProvider.shared
        cloudAvailabilityProvider = provider
        return provider
    }

    @MainActor
    func loadStores(file: StaticString, line: UInt) async {
        defer { loadingTask = nil }

        do {
            // Avoid double-adding the same store if already attached.
            let psc = container.persistentStoreCoordinator
            if !psc.persistentStores.isEmpty {
                if AppLog.isVerbose {
                    let urls = psc.persistentStores.compactMap { $0.url?.lastPathComponent }.joined(separator: ", ")
                    AppLog.coreData.debug("Skipping loadPersistentStores() – stores already attached: \(urls)")
                }
            } else {
                try await loadPersistentStores()
            }

            postLoadConfiguration()
            storesLoaded = true

            let urls = container.persistentStoreCoordinator.persistentStores.compactMap { $0.url }
            let names = urls.map { $0.lastPathComponent }.joined(separator: ", ")
            if AppLog.isVerbose {
                AppLog.coreData.info("Core Data stores loaded (\(urls.count)): \(names)")
            }
        } catch {
            let nsError = error as NSError
            fatalError("❌ Core Data failed to load at \(file):\(line): \(nsError), \(nsError.userInfo)")
        }
    }

    func loadPersistentStores() async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            container.loadPersistentStores { _, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: ())
                }
            }
        }
    }

    func disableCloudSyncPreferences() {
        let defaults = UserDefaults.standard
        defaults.set(false, forKey: AppSettingsKeys.enableCloudSync.rawValue)
    }

    @MainActor
    func reconfigurePersistentStoresForLocalMode() async {
        await rebuildPersistentStores(for: .local)
    }

    private enum PersistentStoreMode: Equatable { case local, cloudKit
        var logDescription: String {
            switch self {
            case .local: return "local mode"
            case .cloudKit: return "CloudKit mode"
            }
        }
    }

    private func configure(description: NSPersistentStoreDescription, for mode: PersistentStoreMode) {
        switch mode {
        case .local:
            description.setOption(false as NSNumber, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)
            description.cloudKitContainerOptions = nil
        case .cloudKit:
            description.setOption(true as NSNumber, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)
            let options = NSPersistentCloudKitContainerOptions(containerIdentifier: cloudKitContainerIdentifier)
            description.cloudKitContainerOptions = options
        }
    }

    @MainActor
    private func rebuildPersistentStores(for mode: PersistentStoreMode) async {
        // Allow UI to update prior to heavy store operations
        await Task.yield()
        guard container.persistentStoreDescriptions.first != nil else { return }
        let currentMode: PersistentStoreMode = _currentMode

        if currentMode == mode, storesLoaded {
            if AppLog.isVerbose {
                AppLog.coreData.debug("Skipping persistent store rebuild – already configured for \(mode.logDescription)")
            }
            return
        }

        // Wait for any in-flight load to complete to avoid double-adding stores.
        await waitUntilStoresLoaded(timeout: 10.0)

        let coordinator = container.persistentStoreCoordinator
        viewContext.reset()

        for store in coordinator.persistentStores {
            do {
                try coordinator.remove(store)
            } catch {
                assertionFailure("❌ Failed to detach persistent store: \(error)")
            }
        }

        storesLoaded = false

        // Rebuild store description for the new mode
        let storeURL = NSPersistentContainer.defaultDirectoryURL()
            .appendingPathComponent("\(modelName).sqlite")
        let description = NSPersistentStoreDescription(url: storeURL)
        if let existingType = container.persistentStoreDescriptions.first?.type {
            description.type = existingType
        }
        description.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
        description.setOption(true as NSNumber, forKey: NSMigratePersistentStoresAutomaticallyOption)
        description.setOption(true as NSNumber, forKey: NSInferMappingModelAutomaticallyOption)
        configure(description: description, for: mode)

        container.persistentStoreDescriptions = [description]

        do {
            try await loadPersistentStores()
            _currentMode = mode
            postLoadConfiguration()
            storesLoaded = true
            notificationCenter.post(name: .dataStoreDidChange, object: nil)
            if AppLog.isVerbose {
                AppLog.coreData.info("Rebuilt persistent stores for \(mode.logDescription)")
            }
        } catch {
            assertionFailure("❌ Failed to rebuild persistent stores for \(mode.logDescription): \(error)")
        }
    }
}

#if DEBUG
// MARK: - Development: CloudKit Schema Initialization
extension CoreDataService {
    /// Initializes the CloudKit schema for the current container in the
    /// Development environment. No-ops in Release builds.
    ///
    /// Call this from a debug-only UI or via an environment flag after stores load.
    @MainActor
    func initializeCloudKitSchemaIfNeeded() async {
        guard isCloudStoreActive else { return }
        // Ensure stores are loaded and container is configured for CloudKit.
        await waitUntilStoresLoaded(timeout: 10.0)
        guard let cloudContainer = container as? NSPersistentCloudKitContainer else { return }
        do {
            try cloudContainer.initializeCloudKitSchema(options: [])
            AppLog.iCloud.info("Initialized CloudKit schema in Development environment")
        } catch {
            AppLog.iCloud.error("Failed to initialize CloudKit schema: \(String(describing: error))")
        }
    }
}
#endif

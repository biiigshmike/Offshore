import Foundation
import Combine

/// Mirrors the selected `BudgetPeriod` preference via iCloud KVS when enabled.
/// Keeps local `UserDefaults` and `NSUbiquitousKeyValueStore` in sync.
@MainActor
final class BudgetPreferenceSync {
    static let shared = BudgetPreferenceSync()

    private let userDefaults: UserDefaults
    private let ubiquitousStoreFactory: () -> UbiquitousKeyValueStoring
    private var cachedUbiquitousStore: UbiquitousKeyValueStoring?
    private let notificationCenter: NotificationCentering
    private let defaultCloudStatusProviderFactory: () -> CloudAvailabilityProviding
    private var pendingInjectedCloudStatusProvider: CloudAvailabilityProviding?
    private var cloudStatusProvider: CloudAvailabilityProviding?
    private var availabilityCancellable: AnyCancellable?

    private let storageKey = "budget.period.v1"
    private let defaultsKey = AppSettingsKeys.budgetPeriod.rawValue

    private var hasRequestedCloudAvailabilityCheck = false
    private var ubiquitousObserver: NSObjectProtocol?
    private var defaultsObserver: NSObjectProtocol?

    private var lastKnownLocalValue: String?

    private var isBudgetPeriodSyncEnabled: Bool {
        let bpSync = userDefaults.object(forKey: AppSettingsKeys.syncBudgetPeriod.rawValue) as? Bool ?? false
        let cloud = userDefaults.object(forKey: AppSettingsKeys.enableCloudSync.rawValue) as? Bool ?? false
        return bpSync && cloud
    }

    private var shouldUseICloud: Bool {
        guard isBudgetPeriodSyncEnabled else { return false }
        let provider = resolveCloudStatusProvider()
        guard let available = provider.isCloudAccountAvailable else { return false }
        return available
    }

    init(
        userDefaults: UserDefaults = .standard,
        ubiquitousStoreFactory: @escaping () -> UbiquitousKeyValueStoring = { NSUbiquitousKeyValueStore.default },
        cloudStatusProvider: CloudAvailabilityProviding? = nil,
        notificationCenter: NotificationCentering = NotificationCenterAdapter.shared
    ) {
        self.userDefaults = userDefaults
        self.ubiquitousStoreFactory = ubiquitousStoreFactory
        self.pendingInjectedCloudStatusProvider = cloudStatusProvider
        self.defaultCloudStatusProviderFactory = { CloudAccountStatusProvider.shared }
        self.notificationCenter = notificationCenter
    }

    private func resolveCloudStatusProvider() -> CloudAvailabilityProviding {
        if let provider = cloudStatusProvider {
            scheduleAvailabilityCheckIfNeeded(for: provider)
            return provider
        }
        let provider = pendingInjectedCloudStatusProvider ?? defaultCloudStatusProviderFactory()
        pendingInjectedCloudStatusProvider = nil
        cloudStatusProvider = provider
        availabilityCancellable?.cancel()
        availabilityCancellable = provider.availabilityPublisher
            .sink { [weak self] _ in
                Task { @MainActor [weak self] in self?.applySettingsChanged() }
            }
        scheduleAvailabilityCheckIfNeeded(for: provider)
        return provider
    }

    private func scheduleAvailabilityCheckIfNeeded(for provider: CloudAvailabilityProviding) {
        guard !hasRequestedCloudAvailabilityCheck else { return }
        hasRequestedCloudAvailabilityCheck = true
        Task { @MainActor in _ = await provider.resolveAvailability(forceRefresh: false) }
    }

    // MARK: Public API
    func applySettingsChanged() {
        if shouldUseICloud {
            startObserving()
            bootstrapFromCloudIfNeeded()
        } else {
            stopObserving()
        }
    }

    // MARK: Observing
    private func startObserving() {
        guard ubiquitousObserver == nil else { return }
        guard let store = ubiquitousStoreIfAvailable() else { return }

        ubiquitousObserver = notificationCenter.addObserver(
            forName: NSUbiquitousKeyValueStore.didChangeExternallyNotification,
            object: store as AnyObject,
            queue: nil
        ) { [weak self] note in
            Task { @MainActor [weak self, note] in
                self?.handleUbiquitousChange(note)
            }
        }

        if defaultsObserver == nil {
            defaultsObserver = notificationCenter.addObserver(
                forName: UserDefaults.didChangeNotification,
                object: nil,
                queue: nil
            ) { [weak self] _ in
                Task { @MainActor [weak self] in self?.handleDefaultsChange() }
            }
        }
    }

    private func stopObserving() {
        if let obs = ubiquitousObserver { notificationCenter.removeObserver(obs); ubiquitousObserver = nil }
        if let obs = defaultsObserver { notificationCenter.removeObserver(obs); defaultsObserver = nil }
    }

    private func handleUbiquitousChange(_ note: Notification) {
        guard shouldUseICloud else { return }
        guard let store = ubiquitousStoreIfAvailable() else { return }
        _ = store.synchronize()
        if let remote = store.string(forKey: storageKey), remote != lastKnownLocalValue {
            lastKnownLocalValue = remote
            userDefaults.set(remote, forKey: defaultsKey)
        }
    }

    private func handleDefaultsChange() {
        guard shouldUseICloud else { return }
        let local = userDefaults.string(forKey: defaultsKey)
        guard local != lastKnownLocalValue else { return }
        lastKnownLocalValue = local
        guard let store = ubiquitousStoreIfAvailable(), store.synchronize() else { return }
        store.set(local, forKey: storageKey)
        _ = store.synchronize()
    }

    private func ubiquitousStoreIfAvailable() -> UbiquitousKeyValueStoring? {
        guard shouldUseICloud else { return nil }
        if let s = cachedUbiquitousStore { return s }
        let s = ubiquitousStoreFactory()
        cachedUbiquitousStore = s
        return s
    }

    private func bootstrapFromCloudIfNeeded() {
        guard let store = ubiquitousStoreIfAvailable() else { return }
        _ = store.synchronize()
        let local = userDefaults.string(forKey: defaultsKey)
        if let remote = store.string(forKey: storageKey) {
            // Prefer remote on first enable; update local if different.
            if remote != local {
                lastKnownLocalValue = remote
                userDefaults.set(remote, forKey: defaultsKey)
            } else {
                lastKnownLocalValue = local
            }
        } else {
            // No remote; push local up.
            lastKnownLocalValue = local
            store.set(local, forKey: storageKey)
            _ = store.synchronize()
        }
    }
}

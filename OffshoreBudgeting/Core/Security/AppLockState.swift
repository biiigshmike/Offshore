import Foundation

@MainActor
final class AppLockState: ObservableObject {
    // MARK: Keys
    private enum Keys {
        static let appLockEnabled = "appLockEnabled"
    }

    // MARK: Stored
    @Published var isEnabled: Bool = false {
        didSet {
            guard !isSyncingFromDefaults else { return }
            defaults.set(isEnabled, forKey: Keys.appLockEnabled)
        }
    }

    private let defaults: UserDefaults
    private var defaultsObserver: NSObjectProtocol?
    private var isSyncingFromDefaults = false

    // MARK: Init
    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        syncFromDefaults()
        defaultsObserver = NotificationCenter.default.addObserver(
            forName: UserDefaults.didChangeNotification,
            object: defaults,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.syncFromDefaults()
            }
        }
    }

    deinit {
        if let defaultsObserver {
            NotificationCenter.default.removeObserver(defaultsObserver)
        }
    }

    // MARK: Private
    private func syncFromDefaults() {
        isSyncingFromDefaults = true
        if let stored = defaults.object(forKey: Keys.appLockEnabled) as? Bool {
            isEnabled = stored
        } else {
            isEnabled = false
        }
        isSyncingFromDefaults = false
    }
}


import Foundation

@MainActor
final class UITestingState: ObservableObject {
    // MARK: Keys
    private enum Keys {
        static let seedDone = "uitest_seed_done"
    }

    // MARK: Stored
    @Published var seedDone: Bool = false {
        didSet {
            guard !isSyncingFromDefaults else { return }
            defaults.set(seedDone, forKey: Keys.seedDone)
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
        seedDone = defaults.bool(forKey: Keys.seedDone)
        isSyncingFromDefaults = false
    }
}


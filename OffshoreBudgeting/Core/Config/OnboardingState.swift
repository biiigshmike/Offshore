import Foundation

@MainActor
final class OnboardingState: ObservableObject {
    // MARK: Keys
    private enum Keys {
        static let didCompleteOnboarding = "didCompleteOnboarding"
        static let didChooseCloudDataOnboarding = "didChooseCloudDataOnboarding"
    }

    // MARK: Stored
    @Published var didCompleteOnboarding: Bool = false {
        didSet {
            guard !isSyncingFromDefaults else { return }
            defaults.set(didCompleteOnboarding, forKey: Keys.didCompleteOnboarding)
        }
    }

    @Published var didChooseCloudDataOnboarding: Bool = false {
        didSet {
            guard !isSyncingFromDefaults else { return }
            defaults.set(didChooseCloudDataOnboarding, forKey: Keys.didChooseCloudDataOnboarding)
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
        didCompleteOnboarding = defaults.bool(forKey: Keys.didCompleteOnboarding)
        didChooseCloudDataOnboarding = defaults.bool(forKey: Keys.didChooseCloudDataOnboarding)
        isSyncingFromDefaults = false
    }
}

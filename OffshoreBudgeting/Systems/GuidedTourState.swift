import Foundation
import SwiftUI

// MARK: - GuidedTourScreen
/// Logical destinations that participate in the guided walkthrough.
enum GuidedTourScreen: CaseIterable {
    case home
    case income
    case cards
    case cardDetail
    case presets
    case settings

    var identifier: String {
        switch self {
        case .home: return "home"
        case .income: return "income"
        case .cards: return "cards"
        case .cardDetail: return "cardDetail"
        case .presets: return "presets"
        case .settings: return "settings"
        }
    }
}

// MARK: - GuidedTourState
@MainActor
final class GuidedTourState: ObservableObject {

    // MARK: Shared Instance
    static let shared = GuidedTourState(defaults: .standard, notificationCenter: .default)

    // MARK: Dependencies
    private let defaults: UserDefaults
    private let notificationCenter: NotificationCenter

    // MARK: Runtime Overrides
    private var forcedOverlays: Set<GuidedTourScreen> = []
    private var forcedHints: Set<GuidedTourScreen> = []

    // MARK: Init
    init(defaults: UserDefaults, notificationCenter: NotificationCenter) {
        self.defaults = defaults
        self.notificationCenter = notificationCenter
    }

    // MARK: Public API
    func needsOverlay(for screen: GuidedTourScreen) -> Bool {
        if forcedOverlays.contains(screen) { return true }
        return defaults.bool(forKey: screen.overlayKey) == false
    }

    func needsHints(for screen: GuidedTourScreen) -> Bool {
        if forcedHints.contains(screen) { return true }
        return defaults.bool(forKey: screen.hintsKey) == false
    }

    func markOverlaySeen(for screen: GuidedTourScreen) {
        forcedOverlays.remove(screen)
        defaults.set(true, forKey: screen.overlayKey)
        objectWillChange.send()
        AppLog.ui.info("GuidedTour overlayCompleted screen=\(screen.identifier, privacy: .public)")
    }

    func markHintsDismissed(for screen: GuidedTourScreen) {
        forcedHints.remove(screen)
        defaults.set(true, forKey: screen.hintsKey)
        objectWillChange.send()
        AppLog.ui.info("GuidedTour hintsDismissed screen=\(screen.identifier, privacy: .public)")
    }

    func resetAll() {
        for screen in GuidedTourScreen.allCases {
            defaults.removeObject(forKey: screen.overlayKey)
            defaults.removeObject(forKey: screen.hintsKey)
        }
        forcedOverlays.removeAll()
        forcedHints.removeAll()
        objectWillChange.send()
        notificationCenter.post(name: .guidedTourDidReset, object: nil)
        AppLog.ui.info("GuidedTour resetAll")
    }

    func reset(screen: GuidedTourScreen) {
        defaults.removeObject(forKey: screen.overlayKey)
        defaults.removeObject(forKey: screen.hintsKey)
        forcedOverlays.remove(screen)
        forcedHints.remove(screen)
        objectWillChange.send()
        notificationCenter.post(name: .guidedTourDidReset, object: screen, userInfo: ["screen": screen.identifier])
        AppLog.ui.info("GuidedTour reset screen=\(screen.identifier, privacy: .public)")
    }

    func prepareForNewUser() {
        resetAll()
        AppLog.ui.debug("GuidedTour prepareForNewUser")
    }

    func forceAllOverlaysOnce() {
        forcedOverlays = Set(GuidedTourScreen.allCases)
        objectWillChange.send()
    }

    func forceOverlay(for screen: GuidedTourScreen) {
        forcedOverlays.insert(screen)
        objectWillChange.send()
    }

    func forceHints(for screen: GuidedTourScreen) {
        forcedHints.insert(screen)
        objectWillChange.send()
    }
}

// MARK: - Keys
private extension GuidedTourScreen {
    var overlayKey: String {
        switch self {
        case .home: return GuidedTourDefaults.homeOverlaySeen
        case .income: return GuidedTourDefaults.incomeOverlaySeen
        case .cards: return GuidedTourDefaults.cardsOverlaySeen
        case .cardDetail: return GuidedTourDefaults.cardDetailOverlaySeen
        case .presets: return GuidedTourDefaults.presetsOverlaySeen
        case .settings: return GuidedTourDefaults.settingsOverlaySeen
        }
    }

    var hintsKey: String {
        switch self {
        case .home: return GuidedTourDefaults.homeHintsDismissed
        case .income: return GuidedTourDefaults.incomeHintsDismissed
        case .cards: return GuidedTourDefaults.cardsHintsDismissed
        case .cardDetail: return GuidedTourDefaults.cardDetailHintsDismissed
        case .presets: return GuidedTourDefaults.presetsHintsDismissed
        case .settings: return GuidedTourDefaults.settingsHintsDismissed
        }
    }
}

// MARK: - Notification Name
extension Notification.Name {
    static let guidedTourDidReset = Notification.Name("GuidedTourDidReset")
}

// MARK: - Environment
private struct GuidedTourScreenKey: EnvironmentKey {
    static let defaultValue: GuidedTourScreen? = nil
}

extension EnvironmentValues {
    var guidedTourScreen: GuidedTourScreen? {
        get { self[GuidedTourScreenKey.self] }
        set { self[GuidedTourScreenKey.self] = newValue }
    }
}

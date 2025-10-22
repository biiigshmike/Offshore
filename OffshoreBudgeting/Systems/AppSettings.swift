import Foundation

// MARK: - AppSettingsKeys
/// Keys for storing user preferences in UserDefaults.
/// Unless otherwise noted, new keys default to `true`. Cloud-sync related
/// options default to `false` so the app starts in a purely local mode.
enum AppSettingsKeys: String {
    case confirmBeforeDelete
    case calendarHorizontal
    case presetsDefaultUseInFutureBudgets
    case budgetPeriod
    case syncCardThemes
    case syncBudgetPeriod
    case enableCloudSync
}

// MARK: - Guided Tour Keys
enum GuidedTourDefaults {
    static let homeOverlaySeen = "tour.home.overlay.seen"
    static let homeHintsDismissed = "tour.home.hints.dismissed"

    static let incomeOverlaySeen = "tour.income.overlay.seen"
    static let incomeHintsDismissed = "tour.income.hints.dismissed"

    static let cardsOverlaySeen = "tour.cards.overlay.seen"
    static let cardsHintsDismissed = "tour.cards.hints.dismissed"

    static let cardDetailOverlaySeen = "tour.cardDetail.overlay.seen"
    static let cardDetailHintsDismissed = "tour.cardDetail.hints.dismissed"

    static let presetsOverlaySeen = "tour.presets.overlay.seen"
    static let presetsHintsDismissed = "tour.presets.hints.dismissed"

    static let settingsOverlaySeen = "tour.settings.overlay.seen"
    static let settingsHintsDismissed = "tour.settings.hints.dismissed"
}

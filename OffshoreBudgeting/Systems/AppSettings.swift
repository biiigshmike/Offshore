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
    case enableCloudSync
    case syncHomeWidgetsAcrossDevices
    case enableDailyReminder
    case enablePlannedIncomeReminder
    case notificationReminderTimeMinutes
    case lastAppOpenDate
    case lastExpenseAddedDate
    case tipsHintsResetToken
    case activeWorkspaceID
    case sidebarVisibility
    case sidebarCompactTabsOverride
}

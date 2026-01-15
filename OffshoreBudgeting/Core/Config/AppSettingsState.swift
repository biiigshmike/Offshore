import Combine
import Foundation

// MARK: - AppSettingsState
@MainActor
final class AppSettingsState: ObservableObject {
    private let store: AppSettingsStore
    private var defaultsObserver: NSObjectProtocol?
    private var isSyncingFromDefaults = false

    // MARK: Published Settings
    @Published var confirmBeforeDelete: Bool { didSet { guard !isSyncingFromDefaults else { return }; store.set(confirmBeforeDelete, for: .confirmBeforeDelete) } }
    @Published var calendarHorizontal: Bool { didSet { guard !isSyncingFromDefaults else { return }; store.set(calendarHorizontal, for: .calendarHorizontal) } }
    @Published var presetsDefaultUseInFutureBudgets: Bool { didSet { guard !isSyncingFromDefaults else { return }; store.set(presetsDefaultUseInFutureBudgets, for: .presetsDefaultUseInFutureBudgets) } }
    @Published var budgetPeriod: String { didSet { guard !isSyncingFromDefaults else { return }; store.set(budgetPeriod, for: .budgetPeriod) } }
    @Published var enableCloudSync: Bool { didSet { guard !isSyncingFromDefaults else { return }; store.set(enableCloudSync, for: .enableCloudSync) } }
    @Published var syncHomeWidgetsAcrossDevices: Bool { didSet { guard !isSyncingFromDefaults else { return }; store.set(syncHomeWidgetsAcrossDevices, for: .syncHomeWidgetsAcrossDevices) } }
    @Published var enableDailyReminder: Bool { didSet { guard !isSyncingFromDefaults else { return }; store.set(enableDailyReminder, for: .enableDailyReminder) } }
    @Published var enablePlannedIncomeReminder: Bool { didSet { guard !isSyncingFromDefaults else { return }; store.set(enablePlannedIncomeReminder, for: .enablePlannedIncomeReminder) } }
    @Published var enablePresetExpenseDueReminder: Bool { didSet { guard !isSyncingFromDefaults else { return }; store.set(enablePresetExpenseDueReminder, for: .enablePresetExpenseDueReminder) } }
    @Published var silencePresetWithActualAmount: Bool { didSet { guard !isSyncingFromDefaults else { return }; store.set(silencePresetWithActualAmount, for: .silencePresetWithActualAmount) } }
    @Published var excludeNonGlobalPresetExpenses: Bool { didSet { guard !isSyncingFromDefaults else { return }; store.set(excludeNonGlobalPresetExpenses, for: .excludeNonGlobalPresetExpenses) } }
    @Published var notificationReminderTimeMinutes: Int { didSet { guard !isSyncingFromDefaults else { return }; store.set(notificationReminderTimeMinutes, for: .notificationReminderTimeMinutes) } }
    @Published var lastAppOpenDate: Double { didSet { guard !isSyncingFromDefaults else { return }; store.set(lastAppOpenDate, for: .lastAppOpenDate) } }
    @Published var lastExpenseAddedDate: Double { didSet { guard !isSyncingFromDefaults else { return }; store.set(lastExpenseAddedDate, for: .lastExpenseAddedDate) } }
    @Published var tipsHintsResetToken: String { didSet { guard !isSyncingFromDefaults else { return }; store.set(tipsHintsResetToken, for: .tipsHintsResetToken) } }
    @Published var activeWorkspaceID: String { didSet { guard !isSyncingFromDefaults else { return }; store.set(activeWorkspaceID, for: .activeWorkspaceID) } }

    init(store: AppSettingsStore) {
        self.store = store

        self.confirmBeforeDelete = store.bool(for: .confirmBeforeDelete) ?? true
        self.calendarHorizontal = store.bool(for: .calendarHorizontal) ?? true
        self.presetsDefaultUseInFutureBudgets = store.bool(for: .presetsDefaultUseInFutureBudgets) ?? true
        self.budgetPeriod = store.string(for: .budgetPeriod) ?? BudgetPeriod.monthly.rawValue
        self.enableCloudSync = store.bool(for: .enableCloudSync) ?? false
        self.syncHomeWidgetsAcrossDevices = store.bool(for: .syncHomeWidgetsAcrossDevices) ?? false
        self.enableDailyReminder = store.bool(for: .enableDailyReminder) ?? false
        self.enablePlannedIncomeReminder = store.bool(for: .enablePlannedIncomeReminder) ?? false
        self.enablePresetExpenseDueReminder = store.bool(for: .enablePresetExpenseDueReminder) ?? false
        self.silencePresetWithActualAmount = store.bool(for: .silencePresetWithActualAmount) ?? false
        self.excludeNonGlobalPresetExpenses = store.bool(for: .excludeNonGlobalPresetExpenses) ?? false
        self.notificationReminderTimeMinutes = store.int(for: .notificationReminderTimeMinutes) ?? (20 * 60)
        self.lastAppOpenDate = store.double(for: .lastAppOpenDate) ?? 0
        self.lastExpenseAddedDate = store.double(for: .lastExpenseAddedDate) ?? 0
        self.tipsHintsResetToken = store.string(for: .tipsHintsResetToken) ?? ""
        self.activeWorkspaceID = store.string(for: .activeWorkspaceID) ?? ""

        observeUserDefaultsIfPossible()
    }

    deinit {
        if let defaultsObserver {
            NotificationCenter.default.removeObserver(defaultsObserver)
        }
    }

    // MARK: Sync
    private func observeUserDefaultsIfPossible() {
        guard let userDefaultsStore = store as? UserDefaultsAppSettingsStore else { return }

        defaultsObserver = NotificationCenter.default.addObserver(
            forName: UserDefaults.didChangeNotification,
            object: userDefaultsStore.defaults,
            queue: .main
        ) { [weak self] _ in
            guard let self else { return }
            Task { @MainActor in
                self.syncFromStore()
            }
        }
    }

    private func syncFromStore() {
        isSyncingFromDefaults = true
        defer { isSyncingFromDefaults = false }

        confirmBeforeDelete = store.bool(for: .confirmBeforeDelete) ?? true
        calendarHorizontal = store.bool(for: .calendarHorizontal) ?? true
        presetsDefaultUseInFutureBudgets = store.bool(for: .presetsDefaultUseInFutureBudgets) ?? true
        budgetPeriod = store.string(for: .budgetPeriod) ?? BudgetPeriod.monthly.rawValue
        enableCloudSync = store.bool(for: .enableCloudSync) ?? false
        syncHomeWidgetsAcrossDevices = store.bool(for: .syncHomeWidgetsAcrossDevices) ?? false
        enableDailyReminder = store.bool(for: .enableDailyReminder) ?? false
        enablePlannedIncomeReminder = store.bool(for: .enablePlannedIncomeReminder) ?? false
        enablePresetExpenseDueReminder = store.bool(for: .enablePresetExpenseDueReminder) ?? false
        silencePresetWithActualAmount = store.bool(for: .silencePresetWithActualAmount) ?? false
        excludeNonGlobalPresetExpenses = store.bool(for: .excludeNonGlobalPresetExpenses) ?? false
        notificationReminderTimeMinutes = store.int(for: .notificationReminderTimeMinutes) ?? (20 * 60)
        lastAppOpenDate = store.double(for: .lastAppOpenDate) ?? 0
        lastExpenseAddedDate = store.double(for: .lastExpenseAddedDate) ?? 0
        tipsHintsResetToken = store.string(for: .tipsHintsResetToken) ?? ""
        activeWorkspaceID = store.string(for: .activeWorkspaceID) ?? ""
    }
}

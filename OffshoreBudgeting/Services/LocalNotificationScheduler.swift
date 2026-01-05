import Foundation
import CoreData
import UserNotifications

// MARK: - LocalNotificationScheduler
/// Centralizes local notification scheduling for privacy-first reminders.
final class LocalNotificationScheduler {
    static let shared = LocalNotificationScheduler()

    private let center: UNUserNotificationCenter
    private let calendar: Calendar
    private let defaults: UserDefaults
    private let incomeService: IncomeService
    private let plannedExpenseService: PlannedExpenseService

    private let dailyReminderPrefix = "dailyReminder-"
    private let plannedIncomePrefix = "plannedIncome-"
    private let presetExpensePrefix = "presetExpense-"
    private let dailyLookaheadDays = 30
    private let plannedIncomeLookaheadDays = 45
    private let presetExpenseLookaheadDays = 45

    private init(center: UNUserNotificationCenter = .current(),
                 calendar: Calendar = .current,
                 defaults: UserDefaults = .standard,
                 incomeService: IncomeService = IncomeService(),
                 plannedExpenseService: PlannedExpenseService = PlannedExpenseService()) {
        self.center = center
        self.calendar = calendar
        self.defaults = defaults
        self.incomeService = incomeService
        self.plannedExpenseService = plannedExpenseService
    }

    func requestAuthorization() async -> Bool {
        do {
            return try await center.requestAuthorization(options: [.alert, .badge, .sound])
        } catch {
            return false
        }
    }

    func recordAppOpen() {
        defaults.set(Date(), forKey: AppSettingsKeys.lastAppOpenDate.rawValue)
    }

    func recordExpenseAdded() {
        defaults.set(Date(), forKey: AppSettingsKeys.lastExpenseAddedDate.rawValue)
    }

    func refreshAll() async {
        await refreshDailyReminder()
        await refreshPlannedIncomeReminders()
        await refreshPresetExpenseReminders()
    }

    func refreshDailyReminder() async {
        await removePendingRequests(prefix: dailyReminderPrefix)
        guard defaults.bool(forKey: AppSettingsKeys.enableDailyReminder.rawValue) else { return }

        let now = Date()
        let todayStart = calendar.startOfDay(for: now)
        let (hour, minute) = reminderTimeComponents()
        let hasOpenedToday = isSameDay(defaults.object(forKey: AppSettingsKeys.lastAppOpenDate.rawValue), now)
        let hasExpenseToday = isSameDay(defaults.object(forKey: AppSettingsKeys.lastExpenseAddedDate.rawValue), now)

        for offset in 0..<dailyLookaheadDays {
            guard let day = calendar.date(byAdding: .day, value: offset, to: todayStart),
                  let fireDate = calendar.date(bySettingHour: hour, minute: minute, second: 0, of: day) else { continue }
            if fireDate <= now { continue }
            if offset == 0, (hasOpenedToday || hasExpenseToday) { continue }
            scheduleDailyReminder(on: fireDate)
        }
    }

    func refreshPlannedIncomeReminders() async {
        await removePendingRequests(prefix: plannedIncomePrefix)
        guard defaults.bool(forKey: AppSettingsKeys.enablePlannedIncomeReminder.rawValue) else { return }

        let now = Date()
        let (hour, minute) = reminderTimeComponents()
        let start = calendar.startOfDay(for: now)
        guard let end = calendar.date(byAdding: .day, value: plannedIncomeLookaheadDays, to: start) else { return }

        let interval = DateInterval(start: start, end: end)
        let incomes = (try? incomeService.fetchIncomes(in: interval)) ?? []
        let grouped = groupIncomesByDay(incomes)

        for (day, status) in grouped where status.hasPlanned && !status.hasActual {
            guard let fireDate = calendar.date(bySettingHour: hour, minute: minute, second: 0, of: day),
                  fireDate > now else { continue }
            schedulePlannedIncomeReminder(on: fireDate, day: day)
        }
    }

    func refreshPresetExpenseReminders() async {
        await removePendingRequests(prefix: presetExpensePrefix)
        guard defaults.bool(forKey: AppSettingsKeys.enablePresetExpenseDueReminder.rawValue) else { return }

        let now = Date()
        let (hour, minute) = reminderTimeComponents()
        let start = calendar.startOfDay(for: now)
        guard let end = calendar.date(byAdding: .day, value: presetExpenseLookaheadDays, to: start) else { return }

        let interval = DateInterval(start: start, end: end)
        let expenses = (try? plannedExpenseService.fetchAll(in: interval, sortedByDateAscending: true)) ?? []
        let excludeNonGlobal = defaults.bool(forKey: AppSettingsKeys.excludeNonGlobalPresetExpenses.rawValue)
        let silenceIfActual = defaults.bool(forKey: AppSettingsKeys.silencePresetWithActualAmount.rawValue)

        for expense in expenses {
            if excludeNonGlobal && expense.isGlobal == false { continue }
            if silenceIfActual && expense.actualAmount > 0 { continue }
            guard let transactionDate = expense.transactionDate else { continue }
            let day = calendar.startOfDay(for: transactionDate)
            guard let fireDate = calendar.date(bySettingHour: hour, minute: minute, second: 0, of: day),
                  fireDate > now else { continue }
            schedulePresetExpenseReminder(on: fireDate, expense: expense)
        }
    }

    private func scheduleDailyReminder(on date: Date) {
        let content = UNMutableNotificationContent()
        content.title = "Log Variable Expenses"
        content.body = "If you haven’t added any variable expenses today, take a moment to log them now."
        content.sound = .default

        let trigger = UNCalendarNotificationTrigger(dateMatching: calendar.dateComponents([.year, .month, .day, .hour, .minute], from: date),
                                                    repeats: false)
        let identifier = dailyReminderPrefix + dayIdentifier(for: date)
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        center.add(request)
    }

    private func schedulePlannedIncomeReminder(on date: Date, day: Date) {
        let content = UNMutableNotificationContent()
        content.title = "Log Actual Income"
        content.body = "You planned income for today. Log the actual amount to compare planned vs actual."
        content.sound = .default

        let trigger = UNCalendarNotificationTrigger(dateMatching: calendar.dateComponents([.year, .month, .day, .hour, .minute], from: date),
                                                    repeats: false)
        let identifier = plannedIncomePrefix + dayIdentifier(for: day)
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        center.add(request)
    }

    private func schedulePresetExpenseReminder(on date: Date, expense: PlannedExpense) {
        let content = UNMutableNotificationContent()
        let name = (expense.descriptionText ?? "Preset Expense").trimmingCharacters(in: .whitespacesAndNewlines)
        let titleBase = name.isEmpty ? "Preset Expense" : name
        content.title = "\(titleBase) Due Today"
        content.body = "This preset expense is due today. Log it to keep your budgets accurate."
        content.sound = .default

        let trigger = UNCalendarNotificationTrigger(dateMatching: calendar.dateComponents([.year, .month, .day, .hour, .minute], from: date),
                                                    repeats: false)
        let identifier = presetExpensePrefix + expenseIdentifier(expense) + "-" + dayIdentifier(for: date)
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        center.add(request)
    }

    private func removePendingRequests(prefix: String) async {
        let requests = await pendingRequests()
        let identifiers = requests
            .map(\.identifier)
            .filter { $0.hasPrefix(prefix) }
        guard !identifiers.isEmpty else { return }
        center.removePendingNotificationRequests(withIdentifiers: identifiers)
    }

    private func pendingRequests() async -> [UNNotificationRequest] {
        await withCheckedContinuation { continuation in
            center.getPendingNotificationRequests { requests in
                continuation.resume(returning: requests)
            }
        }
    }

    private func reminderTimeComponents() -> (hour: Int, minute: Int) {
        let minutes = defaults.object(forKey: AppSettingsKeys.notificationReminderTimeMinutes.rawValue) as? Int ?? 20 * 60
        let clamped = max(0, min(24 * 60 - 1, minutes))
        return (clamped / 60, clamped % 60)
    }

    private func isSameDay(_ storedValue: Any?, _ date: Date) -> Bool {
        guard let storedDate = storedValue as? Date else { return false }
        return calendar.isDate(storedDate, inSameDayAs: date)
    }

    private func dayIdentifier(for date: Date) -> String {
        let comps = calendar.dateComponents([.year, .month, .day], from: date)
        let year = comps.year ?? 0
        let month = comps.month ?? 0
        let day = comps.day ?? 0
        return String(format: "%04d-%02d-%02d", year, month, day)
    }

    private func expenseIdentifier(_ expense: PlannedExpense) -> String {
        if let id = expense.id {
            return id.uuidString
        }
        return String(expense.objectID.hashValue)
    }

    private func groupIncomesByDay(_ incomes: [Income]) -> [Date: (hasPlanned: Bool, hasActual: Bool)] {
        incomes.reduce(into: [:]) { partial, income in
            let day = calendar.startOfDay(for: income.date ?? Date.distantPast)
            var status = partial[day] ?? (hasPlanned: false, hasActual: false)
            if income.isPlanned {
                status.hasPlanned = true
            } else {
                status.hasActual = true
            }
            partial[day] = status
        }
    }
}

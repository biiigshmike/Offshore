import Foundation
#if canImport(WidgetKit)
import WidgetKit
#endif

// Lightweight shared storage for WidgetKit snapshots.
enum WidgetSharedStore {
    static let appGroupID = "group.com.mb.offshore-budgeting"
    private static let incomeKeyPrefix = "widget.income.snapshot."
    private static let incomeDefaultPeriodKey = "widget.income.defaultPeriod"
    static let incomeWidgetKind = "com.mb.offshore.income.widget"
    private static let expenseToIncomeKeyPrefix = "widget.expenseToIncome.snapshot."
    private static let expenseToIncomeDefaultPeriodKey = "widget.expenseToIncome.defaultPeriod"
    static let expenseToIncomeWidgetKind = "com.mb.offshore.expenseToIncome.widget"
    private static let savingsOutlookKeyPrefix = "widget.savingsOutlook.snapshot."
    private static let savingsOutlookDefaultPeriodKey = "widget.savingsOutlook.defaultPeriod"
    static let savingsOutlookWidgetKind = "com.mb.offshore.savingsOutlook.widget"
    private static let categorySpotlightKeyPrefix = "widget.categorySpotlight.snapshot."
    private static let categorySpotlightDefaultPeriodKey = "widget.categorySpotlight.defaultPeriod"
    static let categorySpotlightWidgetKind = "com.mb.offshore.categorySpotlight.widget"
    private static let dayOfWeekKeyPrefix = "widget.dayOfWeek.snapshot."
    private static let dayOfWeekDefaultPeriodKey = "widget.dayOfWeek.defaultPeriod"
    static let dayOfWeekWidgetKind = "com.mb.offshore.dayOfWeek.widget"

    struct IncomeSnapshot: Codable, Equatable {
        let actualIncome: Double
        let plannedIncome: Double
        let percentReceived: Double
        let rangeLabel: String
        let updatedAt: Date
    }

    struct ExpenseToIncomeSnapshot: Codable, Equatable {
        let expenses: Double
        let actualIncome: Double
        let rangeLabel: String
        let updatedAt: Date
    }

    struct SavingsOutlookSnapshot: Codable, Equatable {
        let actualSavings: Double
        let projectedSavings: Double
        let rangeLabel: String
        let updatedAt: Date
    }

    struct NextPlannedExpenseSnapshot: Codable, Equatable {
        let title: String
        let plannedAmount: Double
        let actualAmount: Double
        let date: Date
        let cardName: String?
        let cardThemeName: String?
        let cardPrimaryHex: String?
        let cardSecondaryHex: String?
        let cardPattern: String?
        let rangeLabel: String
        let updatedAt: Date
    }

    struct CategorySpotlightSnapshot: Codable, Equatable {
        struct CategoryItem: Codable, Equatable {
            let name: String
            let amount: Double
            let hexColor: String?
        }

        let categories: [CategoryItem]
        let rangeLabel: String
        let updatedAt: Date
    }

    struct DayOfWeekSnapshot: Codable, Equatable {
        struct Bucket: Codable, Equatable {
            let label: String
            let amount: Double
            let hexColors: [String]
        }

        let buckets: [Bucket]
        let rangeLabel: String
        let fallbackHexes: [String]
        let updatedAt: Date
    }

    static func writeIncomeSnapshot(_ snapshot: IncomeSnapshot, periodRaw: String) {
        guard let defaults = UserDefaults(suiteName: appGroupID) else { return }
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        guard let data = try? encoder.encode(snapshot) else { return }
        defaults.set(data, forKey: incomeKeyPrefix + periodRaw)
        #if canImport(WidgetKit)
        WidgetCenter.shared.reloadTimelines(ofKind: incomeWidgetKind)
        #endif
    }

    static func writeIncomeDefaultPeriod(_ periodRaw: String) {
        guard let defaults = UserDefaults(suiteName: appGroupID) else { return }
        defaults.set(periodRaw, forKey: incomeDefaultPeriodKey)
    }

    static func readIncomeSnapshot(periodRaw: String) -> IncomeSnapshot? {
        guard let defaults = UserDefaults(suiteName: appGroupID) else { return nil }
        guard let data = defaults.data(forKey: incomeKeyPrefix + periodRaw) else { return nil }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try? decoder.decode(IncomeSnapshot.self, from: data)
    }

    static func readIncomeDefaultPeriod() -> String? {
        guard let defaults = UserDefaults(suiteName: appGroupID) else { return nil }
        return defaults.string(forKey: incomeDefaultPeriodKey)
    }

    static func writeExpenseToIncomeSnapshot(_ snapshot: ExpenseToIncomeSnapshot, periodRaw: String) {
        guard let defaults = UserDefaults(suiteName: appGroupID) else { return }
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        guard let data = try? encoder.encode(snapshot) else { return }
        defaults.set(data, forKey: expenseToIncomeKeyPrefix + periodRaw)
        #if canImport(WidgetKit)
        WidgetCenter.shared.reloadTimelines(ofKind: expenseToIncomeWidgetKind)
        #endif
    }

    static func writeExpenseToIncomeDefaultPeriod(_ periodRaw: String) {
        guard let defaults = UserDefaults(suiteName: appGroupID) else { return }
        defaults.set(periodRaw, forKey: expenseToIncomeDefaultPeriodKey)
    }

    static func readExpenseToIncomeSnapshot(periodRaw: String) -> ExpenseToIncomeSnapshot? {
        guard let defaults = UserDefaults(suiteName: appGroupID) else { return nil }
        guard let data = defaults.data(forKey: expenseToIncomeKeyPrefix + periodRaw) else { return nil }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try? decoder.decode(ExpenseToIncomeSnapshot.self, from: data)
    }

    static func readExpenseToIncomeDefaultPeriod() -> String? {
        guard let defaults = UserDefaults(suiteName: appGroupID) else { return nil }
        return defaults.string(forKey: expenseToIncomeDefaultPeriodKey)
    }

    static func writeSavingsOutlookSnapshot(_ snapshot: SavingsOutlookSnapshot, periodRaw: String) {
        guard let defaults = UserDefaults(suiteName: appGroupID) else { return }
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        guard let data = try? encoder.encode(snapshot) else { return }
        defaults.set(data, forKey: savingsOutlookKeyPrefix + periodRaw)
        #if canImport(WidgetKit)
        WidgetCenter.shared.reloadTimelines(ofKind: savingsOutlookWidgetKind)
        #endif
    }

    static func writeSavingsOutlookDefaultPeriod(_ periodRaw: String) {
        guard let defaults = UserDefaults(suiteName: appGroupID) else { return }
        defaults.set(periodRaw, forKey: savingsOutlookDefaultPeriodKey)
    }

    static func readSavingsOutlookSnapshot(periodRaw: String) -> SavingsOutlookSnapshot? {
        guard let defaults = UserDefaults(suiteName: appGroupID) else { return nil }
        guard let data = defaults.data(forKey: savingsOutlookKeyPrefix + periodRaw) else { return nil }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try? decoder.decode(SavingsOutlookSnapshot.self, from: data)
    }

    static func readSavingsOutlookDefaultPeriod() -> String? {
        guard let defaults = UserDefaults(suiteName: appGroupID) else { return nil }
        return defaults.string(forKey: savingsOutlookDefaultPeriodKey)
    }

    static func writeCategorySpotlightSnapshot(_ snapshot: CategorySpotlightSnapshot, periodRaw: String) {
        guard let defaults = UserDefaults(suiteName: appGroupID) else { return }
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        guard let data = try? encoder.encode(snapshot) else { return }
        defaults.set(data, forKey: categorySpotlightKeyPrefix + periodRaw)
        #if canImport(WidgetKit)
        WidgetCenter.shared.reloadTimelines(ofKind: categorySpotlightWidgetKind)
        #endif
    }

    static func writeCategorySpotlightDefaultPeriod(_ periodRaw: String) {
        guard let defaults = UserDefaults(suiteName: appGroupID) else { return }
        defaults.set(periodRaw, forKey: categorySpotlightDefaultPeriodKey)
    }

    static func readCategorySpotlightSnapshot(periodRaw: String) -> CategorySpotlightSnapshot? {
        guard let defaults = UserDefaults(suiteName: appGroupID) else { return nil }
        guard let data = defaults.data(forKey: categorySpotlightKeyPrefix + periodRaw) else { return nil }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try? decoder.decode(CategorySpotlightSnapshot.self, from: data)
    }

    static func readCategorySpotlightDefaultPeriod() -> String? {
        guard let defaults = UserDefaults(suiteName: appGroupID) else { return nil }
        return defaults.string(forKey: categorySpotlightDefaultPeriodKey)
    }

    static func writeDayOfWeekSnapshot(_ snapshot: DayOfWeekSnapshot, periodRaw: String) {
        guard let defaults = UserDefaults(suiteName: appGroupID) else { return }
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        guard let data = try? encoder.encode(snapshot) else { return }
        defaults.set(data, forKey: dayOfWeekKeyPrefix + periodRaw)
        #if canImport(WidgetKit)
        WidgetCenter.shared.reloadTimelines(ofKind: dayOfWeekWidgetKind)
        #endif
    }

    static func writeDayOfWeekDefaultPeriod(_ periodRaw: String) {
        guard let defaults = UserDefaults(suiteName: appGroupID) else { return }
        defaults.set(periodRaw, forKey: dayOfWeekDefaultPeriodKey)
    }

    static func readDayOfWeekSnapshot(periodRaw: String) -> DayOfWeekSnapshot? {
        guard let defaults = UserDefaults(suiteName: appGroupID) else { return nil }
        guard let data = defaults.data(forKey: dayOfWeekKeyPrefix + periodRaw) else { return nil }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try? decoder.decode(DayOfWeekSnapshot.self, from: data)
    }

    static func readDayOfWeekDefaultPeriod() -> String? {
        guard let defaults = UserDefaults(suiteName: appGroupID) else { return nil }
        return defaults.string(forKey: dayOfWeekDefaultPeriodKey)
    }

    private static let nextPlannedKey = "widget.nextPlannedExpense.snapshot"
    static let nextPlannedWidgetKind = "com.mb.offshore.nextPlannedExpense.widget"

    static func writeNextPlannedExpenseSnapshot(_ snapshot: NextPlannedExpenseSnapshot) {
        guard let defaults = UserDefaults(suiteName: appGroupID) else { return }
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        guard let data = try? encoder.encode(snapshot) else { return }
        defaults.set(data, forKey: nextPlannedKey)
        #if canImport(WidgetKit)
        WidgetCenter.shared.reloadTimelines(ofKind: nextPlannedWidgetKind)
        #endif
    }

    static func readNextPlannedExpenseSnapshot() -> NextPlannedExpenseSnapshot? {
        guard let defaults = UserDefaults(suiteName: appGroupID) else { return nil }
        guard let data = defaults.data(forKey: nextPlannedKey) else { return nil }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try? decoder.decode(NextPlannedExpenseSnapshot.self, from: data)
    }

    static func clearNextPlannedExpenseSnapshot() {
        guard let defaults = UserDefaults(suiteName: appGroupID) else { return }
        defaults.removeObject(forKey: nextPlannedKey)
        #if canImport(WidgetKit)
        WidgetCenter.shared.reloadTimelines(ofKind: nextPlannedWidgetKind)
        #endif
    }
}

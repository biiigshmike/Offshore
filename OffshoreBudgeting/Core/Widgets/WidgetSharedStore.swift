import Foundation
#if canImport(WidgetKit)
import WidgetKit
#endif

// Lightweight shared storage for WidgetKit snapshots.
enum WidgetSharedStore {
    static let appGroupID = "group.com.mb.offshore-budgeting"
    private static let uiTestSuitePrefix = "uitest.widget.sharedstore."
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
    private static let categoryAvailabilityKeyPrefix = "widget.categoryAvailability.snapshot."
    private static let categoryAvailabilityDefaultPeriodKey = "widget.categoryAvailability.defaultPeriod"
    private static let categoryAvailabilityDefaultSegmentKey = "widget.categoryAvailability.defaultSegment"
    private static let categoryAvailabilityDefaultSortKey = "widget.categoryAvailability.defaultSort"
    private static let categoryAvailabilityCategoriesKey = "widget.categoryAvailability.categories"
    static let categoryAvailabilityWidgetKind = "com.mb.offshore.categoryAvailability.widget"
    private static let cardWidgetKeyPrefix = "widget.card.snapshot."
    private static let cardWidgetDefaultPeriodKey = "widget.card.defaultPeriod"
    private static let cardWidgetCardsKey = "widget.card.cards"
    static let cardWidgetKind = "com.mb.offshore.card.widget"

    private static var isUITesting: Bool {
        ProcessInfo.processInfo.arguments.contains("-ui-testing")
    }

    private static var uiTestRunID: String {
        let env = ProcessInfo.processInfo.environment
        if let runID = env["UITEST_RUN_ID"], !runID.isEmpty { return runID }
        return String(ProcessInfo.processInfo.processIdentifier)
    }

    private static var shouldReloadWidgetTimelines: Bool {
        !isUITesting
    }

    private static func defaults() -> UserDefaults? {
        if isUITesting {
            return UserDefaults(suiteName: uiTestSuitePrefix + uiTestRunID)
        }
        return UserDefaults(suiteName: appGroupID)
    }

#if canImport(WidgetKit)
    // MARK: - Timeline Reload Coalescing
    /// Coalesces multiple reload requests into a single per-runloop flush to avoid spamming
    /// WidgetCenter during bursty snapshot writes (e.g., Home widget refresh).
    @MainActor
    private static var pendingReloadKinds: Set<String> = []
    @MainActor
    private static var isReloadFlushScheduled: Bool = false

    private static func scheduleTimelineReload(kind: String) {
        guard shouldReloadWidgetTimelines else { return }
        Task { @MainActor in
            pendingReloadKinds.insert(kind)
            guard !isReloadFlushScheduled else { return }
            isReloadFlushScheduled = true
            await Task.yield()
            isReloadFlushScheduled = false
            let kinds = pendingReloadKinds
            pendingReloadKinds.removeAll()
            for kind in kinds {
                WidgetCenter.shared.reloadTimelines(ofKind: kind)
            }
        }
    }
#endif

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

    struct CategoryAvailabilitySnapshot: Codable, Equatable {
        struct Item: Codable, Equatable {
            let name: String
            let spent: Double
            let cap: Double?
            let available: Double
            let hexColor: String?
        }

        let items: [Item]
        let rangeLabel: String
        let updatedAt: Date
    }

    struct CardWidgetCard: Codable, Equatable {
        let id: String
        let name: String
        let themeName: String?
        let primaryHex: String?
        let secondaryHex: String?
        let patternName: String?
    }

    struct CardWidgetSnapshot: Codable, Equatable {
        struct Transaction: Codable, Equatable {
            let name: String
            let amount: Double
            let date: Date
            let hexColor: String?
        }

        let cardID: String
        let cardName: String
        let cardThemeName: String?
        let cardPrimaryHex: String?
        let cardSecondaryHex: String?
        let cardPattern: String?
        let totalSpent: Double
        let recentTransactions: [Transaction]
        let topTransactions: [Transaction]
        let rangeLabel: String
        let updatedAt: Date
    }

    static func writeIncomeSnapshot(_ snapshot: IncomeSnapshot, periodRaw: String) {
        guard let defaults = defaults() else { return }
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        guard let data = try? encoder.encode(snapshot) else { return }
        defaults.set(data, forKey: incomeKeyPrefix + periodRaw)
        #if canImport(WidgetKit)
        scheduleTimelineReload(kind: incomeWidgetKind)
        #endif
    }

    static func writeIncomeDefaultPeriod(_ periodRaw: String) {
        guard let defaults = defaults() else { return }
        defaults.set(periodRaw, forKey: incomeDefaultPeriodKey)
    }

    static func readIncomeSnapshot(periodRaw: String) -> IncomeSnapshot? {
        guard let defaults = defaults() else { return nil }
        guard let data = defaults.data(forKey: incomeKeyPrefix + periodRaw) else { return nil }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try? decoder.decode(IncomeSnapshot.self, from: data)
    }

    static func readIncomeDefaultPeriod() -> String? {
        guard let defaults = defaults() else { return nil }
        return defaults.string(forKey: incomeDefaultPeriodKey)
    }

    static func writeExpenseToIncomeSnapshot(_ snapshot: ExpenseToIncomeSnapshot, periodRaw: String) {
        guard let defaults = defaults() else { return }
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        guard let data = try? encoder.encode(snapshot) else { return }
        defaults.set(data, forKey: expenseToIncomeKeyPrefix + periodRaw)
        #if canImport(WidgetKit)
        scheduleTimelineReload(kind: expenseToIncomeWidgetKind)
        #endif
    }

    static func writeExpenseToIncomeDefaultPeriod(_ periodRaw: String) {
        guard let defaults = defaults() else { return }
        defaults.set(periodRaw, forKey: expenseToIncomeDefaultPeriodKey)
    }

    static func readExpenseToIncomeSnapshot(periodRaw: String) -> ExpenseToIncomeSnapshot? {
        guard let defaults = defaults() else { return nil }
        guard let data = defaults.data(forKey: expenseToIncomeKeyPrefix + periodRaw) else { return nil }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try? decoder.decode(ExpenseToIncomeSnapshot.self, from: data)
    }

    static func readExpenseToIncomeDefaultPeriod() -> String? {
        guard let defaults = defaults() else { return nil }
        return defaults.string(forKey: expenseToIncomeDefaultPeriodKey)
    }

    static func writeSavingsOutlookSnapshot(_ snapshot: SavingsOutlookSnapshot, periodRaw: String) {
        guard let defaults = defaults() else { return }
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        guard let data = try? encoder.encode(snapshot) else { return }
        defaults.set(data, forKey: savingsOutlookKeyPrefix + periodRaw)
        #if canImport(WidgetKit)
        scheduleTimelineReload(kind: savingsOutlookWidgetKind)
        #endif
    }

    static func writeSavingsOutlookDefaultPeriod(_ periodRaw: String) {
        guard let defaults = defaults() else { return }
        defaults.set(periodRaw, forKey: savingsOutlookDefaultPeriodKey)
    }

    static func readSavingsOutlookSnapshot(periodRaw: String) -> SavingsOutlookSnapshot? {
        guard let defaults = defaults() else { return nil }
        guard let data = defaults.data(forKey: savingsOutlookKeyPrefix + periodRaw) else { return nil }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try? decoder.decode(SavingsOutlookSnapshot.self, from: data)
    }

    static func readSavingsOutlookDefaultPeriod() -> String? {
        guard let defaults = defaults() else { return nil }
        return defaults.string(forKey: savingsOutlookDefaultPeriodKey)
    }

    static func writeCategorySpotlightSnapshot(_ snapshot: CategorySpotlightSnapshot, periodRaw: String) {
        guard let defaults = defaults() else { return }
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        guard let data = try? encoder.encode(snapshot) else { return }
        defaults.set(data, forKey: categorySpotlightKeyPrefix + periodRaw)
        #if canImport(WidgetKit)
        scheduleTimelineReload(kind: categorySpotlightWidgetKind)
        #endif
    }

    static func writeCategorySpotlightDefaultPeriod(_ periodRaw: String) {
        guard let defaults = defaults() else { return }
        defaults.set(periodRaw, forKey: categorySpotlightDefaultPeriodKey)
    }

    static func readCategorySpotlightSnapshot(periodRaw: String) -> CategorySpotlightSnapshot? {
        guard let defaults = defaults() else { return nil }
        guard let data = defaults.data(forKey: categorySpotlightKeyPrefix + periodRaw) else { return nil }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try? decoder.decode(CategorySpotlightSnapshot.self, from: data)
    }

    static func readCategorySpotlightDefaultPeriod() -> String? {
        guard let defaults = defaults() else { return nil }
        return defaults.string(forKey: categorySpotlightDefaultPeriodKey)
    }

    static func writeDayOfWeekSnapshot(_ snapshot: DayOfWeekSnapshot, periodRaw: String) {
        guard let defaults = defaults() else { return }
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        guard let data = try? encoder.encode(snapshot) else { return }
        defaults.set(data, forKey: dayOfWeekKeyPrefix + periodRaw)
        #if canImport(WidgetKit)
        scheduleTimelineReload(kind: dayOfWeekWidgetKind)
        #endif
    }

    static func writeDayOfWeekDefaultPeriod(_ periodRaw: String) {
        guard let defaults = defaults() else { return }
        defaults.set(periodRaw, forKey: dayOfWeekDefaultPeriodKey)
    }

    static func readDayOfWeekSnapshot(periodRaw: String) -> DayOfWeekSnapshot? {
        guard let defaults = defaults() else { return nil }
        guard let data = defaults.data(forKey: dayOfWeekKeyPrefix + periodRaw) else { return nil }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try? decoder.decode(DayOfWeekSnapshot.self, from: data)
    }

    static func readDayOfWeekDefaultPeriod() -> String? {
        guard let defaults = defaults() else { return nil }
        return defaults.string(forKey: dayOfWeekDefaultPeriodKey)
    }

    static func writeCategoryAvailabilitySnapshot(_ snapshot: CategoryAvailabilitySnapshot, periodRaw: String, segmentRaw: String) {
        guard let defaults = defaults() else { return }
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        guard let data = try? encoder.encode(snapshot) else { return }
        defaults.set(data, forKey: categoryAvailabilityKeyPrefix + periodRaw + "." + segmentRaw)
        #if canImport(WidgetKit)
        scheduleTimelineReload(kind: categoryAvailabilityWidgetKind)
        #endif
    }

    static func readCategoryAvailabilitySnapshot(periodRaw: String, segmentRaw: String) -> CategoryAvailabilitySnapshot? {
        guard let defaults = defaults() else { return nil }
        guard let data = defaults.data(forKey: categoryAvailabilityKeyPrefix + periodRaw + "." + segmentRaw) else { return nil }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try? decoder.decode(CategoryAvailabilitySnapshot.self, from: data)
    }

    static func writeCardWidgetSnapshot(_ snapshot: CardWidgetSnapshot, periodRaw: String, cardID: String) {
        guard let defaults = defaults() else { return }
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        guard let data = try? encoder.encode(snapshot) else { return }
        defaults.set(data, forKey: cardWidgetKeyPrefix + periodRaw + "." + cardID)
        #if canImport(WidgetKit)
        scheduleTimelineReload(kind: cardWidgetKind)
        #endif
    }

    static func writeCardWidgetDefaultPeriod(_ periodRaw: String) {
        guard let defaults = defaults() else { return }
        defaults.set(periodRaw, forKey: cardWidgetDefaultPeriodKey)
    }

    static func readCardWidgetSnapshot(periodRaw: String, cardID: String) -> CardWidgetSnapshot? {
        guard let defaults = defaults() else { return nil }
        guard let data = defaults.data(forKey: cardWidgetKeyPrefix + periodRaw + "." + cardID) else { return nil }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try? decoder.decode(CardWidgetSnapshot.self, from: data)
    }

    static func readCardWidgetDefaultPeriod() -> String? {
        guard let defaults = defaults() else { return nil }
        return defaults.string(forKey: cardWidgetDefaultPeriodKey)
    }

    static func writeCardWidgetCards(_ cards: [CardWidgetCard]) {
        guard let defaults = defaults() else { return }
        let encoder = JSONEncoder()
        guard let data = try? encoder.encode(cards) else { return }
        defaults.set(data, forKey: cardWidgetCardsKey)
        #if canImport(WidgetKit)
        scheduleTimelineReload(kind: cardWidgetKind)
        #endif
    }

    static func readCardWidgetCards() -> [CardWidgetCard] {
        guard let defaults = defaults() else { return [] }
        guard let data = defaults.data(forKey: cardWidgetCardsKey) else { return [] }
        let decoder = JSONDecoder()
        return (try? decoder.decode([CardWidgetCard].self, from: data)) ?? []
    }

    // MARK: - Migrations
    /// Best-effort migration for Card widget cached snapshots when a Card's UUID changes
    /// (e.g., deterministic IDs after an update or renaming when IDs are name-derived).
    static func migrateCardWidgetSnapshots(cardIDMap: [String: String]) {
        guard !cardIDMap.isEmpty else { return }
        guard let defaults = defaults() else { return }

        let all = defaults.dictionaryRepresentation()
        for (key, value) in all {
            guard key.hasPrefix(cardWidgetKeyPrefix) else { continue }
            guard let data = value as? Data else { continue }

            // Key format: "widget.card.snapshot.<periodRaw>.<cardID>"
            guard let lastDot = key.lastIndex(of: ".") else { continue }
            let oldCardID = String(key[key.index(after: lastDot)...])
            guard let newCardID = cardIDMap[oldCardID], newCardID != oldCardID else { continue }

            let newKey = String(key[..<key.index(after: lastDot)]) + newCardID
            defaults.set(data, forKey: newKey)
            defaults.removeObject(forKey: key)
        }

        // Also migrate the card list used by the picker.
        if let data = defaults.data(forKey: cardWidgetCardsKey) {
            let decoder = JSONDecoder()
            if let cards = try? decoder.decode([CardWidgetCard].self, from: data) {
                let updated = cards.map { card -> CardWidgetCard in
                    if let mapped = cardIDMap[card.id] {
                        return CardWidgetCard(
                            id: mapped,
                            name: card.name,
                            themeName: card.themeName,
                            primaryHex: card.primaryHex,
                            secondaryHex: card.secondaryHex,
                            patternName: card.patternName
                        )
                    }
                    return card
                }
                let encoder = JSONEncoder()
                if let updatedData = try? encoder.encode(updated) {
                    defaults.set(updatedData, forKey: cardWidgetCardsKey)
                }
            }
        }

        #if canImport(WidgetKit)
        scheduleTimelineReload(kind: cardWidgetKind)
        #endif
    }

    static func writeCategoryAvailabilityDefaultPeriod(_ periodRaw: String) {
        guard let defaults = defaults() else { return }
        defaults.set(periodRaw, forKey: categoryAvailabilityDefaultPeriodKey)
    }

    static func readCategoryAvailabilityDefaultPeriod() -> String? {
        guard let defaults = defaults() else { return nil }
        return defaults.string(forKey: categoryAvailabilityDefaultPeriodKey)
    }

    static func writeCategoryAvailabilityDefaultSegment(_ segmentRaw: String) {
        guard let defaults = defaults() else { return }
        defaults.set(segmentRaw, forKey: categoryAvailabilityDefaultSegmentKey)
    }

    static func readCategoryAvailabilityDefaultSegment() -> String? {
        guard let defaults = defaults() else { return nil }
        return defaults.string(forKey: categoryAvailabilityDefaultSegmentKey)
    }

    static func writeCategoryAvailabilityDefaultSort(_ sortRaw: String) {
        guard let defaults = defaults() else { return }
        defaults.set(sortRaw, forKey: categoryAvailabilityDefaultSortKey)
    }

    static func readCategoryAvailabilityDefaultSort() -> String? {
        guard let defaults = defaults() else { return nil }
        return defaults.string(forKey: categoryAvailabilityDefaultSortKey)
    }

    static func writeCategoryAvailabilityCategories(_ categories: [String]) {
        guard let defaults = defaults() else { return }
        defaults.set(categories, forKey: categoryAvailabilityCategoriesKey)
    }

    static func readCategoryAvailabilityCategories() -> [String] {
        guard let defaults = defaults() else { return [] }
        return defaults.stringArray(forKey: categoryAvailabilityCategoriesKey) ?? []
    }

    private static let nextPlannedKey = "widget.nextPlannedExpense.snapshot"
    static let nextPlannedWidgetKind = "com.mb.offshore.nextPlannedExpense.widget"

    static func writeNextPlannedExpenseSnapshot(_ snapshot: NextPlannedExpenseSnapshot) {
        guard let defaults = defaults() else { return }
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        guard let data = try? encoder.encode(snapshot) else { return }
        defaults.set(data, forKey: nextPlannedKey)
        #if canImport(WidgetKit)
        scheduleTimelineReload(kind: nextPlannedWidgetKind)
        #endif
    }

    static func readNextPlannedExpenseSnapshot() -> NextPlannedExpenseSnapshot? {
        guard let defaults = defaults() else { return nil }
        guard let data = defaults.data(forKey: nextPlannedKey) else { return nil }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try? decoder.decode(NextPlannedExpenseSnapshot.self, from: data)
    }

    static func clearNextPlannedExpenseSnapshot() {
        guard let defaults = defaults() else { return }
        defaults.removeObject(forKey: nextPlannedKey)
        #if canImport(WidgetKit)
        scheduleTimelineReload(kind: nextPlannedWidgetKind)
        #endif
    }
}

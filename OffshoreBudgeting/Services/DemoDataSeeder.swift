#if DEBUG
import Foundation
import CoreData
import SwiftUI

// MARK: - DemoDataSeeder
/// Seeds deterministic demo data for debug builds.
struct DemoDataSeeder {

    // MARK: Dependencies
    private let coreData: CoreDataService
    private let workspaceService: WorkspaceService
    private let cardService: CardService
    private let budgetService: BudgetService
    private let incomeService: IncomeService
    private let plannedExpenseService: PlannedExpenseService
    private let unplannedExpenseService: UnplannedExpenseService
    private let categoryService: ExpenseCategoryService
    private let cardAppearanceStore: CardAppearanceStore
    private let userDefaults: UserDefaults

    // MARK: Configuration
    private let seedVersion: Int
    private let seedMode: DemoSeedConfiguration.SeedMode
    private let shouldResetBeforeSeed: Bool

    // MARK: Init
    init(seedVersion: Int,
         seedMode: DemoSeedConfiguration.SeedMode,
         shouldResetBeforeSeed: Bool,
         coreData: CoreDataService = .shared,
         workspaceService: WorkspaceService = .shared,
         cardService: CardService = CardService(),
         budgetService: BudgetService = BudgetService(),
         incomeService: IncomeService = IncomeService(),
         plannedExpenseService: PlannedExpenseService = PlannedExpenseService(),
         unplannedExpenseService: UnplannedExpenseService = UnplannedExpenseService(),
         categoryService: ExpenseCategoryService = ExpenseCategoryService(),
         cardAppearanceStore: CardAppearanceStore = .shared,
         userDefaults: UserDefaults = .standard) {
        self.seedVersion = seedVersion
        self.seedMode = seedMode
        self.shouldResetBeforeSeed = shouldResetBeforeSeed
        self.coreData = coreData
        self.workspaceService = workspaceService
        self.cardService = cardService
        self.budgetService = budgetService
        self.incomeService = incomeService
        self.plannedExpenseService = plannedExpenseService
        self.unplannedExpenseService = unplannedExpenseService
        self.categoryService = categoryService
        self.cardAppearanceStore = cardAppearanceStore
        self.userDefaults = userDefaults
    }

    // MARK: Public API
    @MainActor
    func seedIfNeeded() async {
        guard seedMode != .off else { return }

        let storedVersion = userDefaults.integer(forKey: Self.seedVersionDefaultsKey)
        if !shouldResetBeforeSeed && storedVersion == seedVersion {
            if AppLog.isVerbose {
                AppLog.service.debug("Skipping demo seed – version \(seedVersion) already applied")
            }
            return
        }

        coreData.ensureLoaded()
        await coreData.waitUntilStoresLoaded(timeout: 5.0)

        if shouldResetBeforeSeed {
            do {
                try coreData.wipeAllData()
                userDefaults.removeObject(forKey: Self.seedVersionDefaultsKey)
            } catch {
                AppLog.service.error("Demo seed reset failed: \(String(describing: error))")
                return
            }
        }

        let workspaceID = workspaceService.ensureActiveWorkspaceID()

        do {
            try seedContent(workspaceID: workspaceID)
            try coreData.saveIfNeeded()
            userDefaults.set(seedVersion, forKey: Self.seedVersionDefaultsKey)
            userDefaults.synchronize()
            AppLog.service.info("Demo seed applied – mode=\(seedMode.rawValue) version=\(seedVersion)")
        } catch {
            AppLog.service.error("Demo seed failed: \(String(describing: error))")
        }
    }

    // MARK: Content
    private func seedContent(workspaceID: UUID) throws {
        let calendar = Calendar(identifier: .gregorian)
        let today = Date()
        let period = BudgetPeriod.monthly
        let range = period.range(containing: today)

        let budget = try budgetService.createBudget(name: "Household Essentials",
                                                    startDate: range.start,
                                                    endDate: range.end,
                                                    isRecurring: true,
                                                    recurrenceType: period.rawValue,
                                                    recurrenceEndDate: nil,
                                                    parentID: nil)
        assignWorkspace(workspaceID, to: budget)

        let cards = try createCards(workspaceID: workspaceID)
        if let budgetID = managedID(for: budget) {
            try cards.forEach { card in
                try cardService.attachCard(card, toBudgetsWithIDs: [budgetID])
            }
        }

        let categories = try createCategories(workspaceID: workspaceID)
        try createCategorySpendingCaps(for: categories,
                                       period: period,
                                       range: range,
                                       calendar: calendar)
        try createIncomes(workspaceID: workspaceID,
                          calendar: calendar,
                          budgetRange: range)
        try createPlannedExpenses(workspaceID: workspaceID,
                                  budgetID: managedID(for: budget),
                                  calendar: calendar,
                                  range: range,
                                  categories: categories)
        try createUnplannedExpenses(workspaceID: workspaceID,
                                    cards: cards,
                                    categories: categories,
                                    calendar: calendar,
                                    range: range)
    }

    private func createCards(workspaceID: UUID) throws -> [Card] {
        let definitions: [(name: String, theme: CardTheme)] = [
            ("Everyday Checking", .mint),
            ("Travel Rewards", .ocean),
            ("Online Wallet", .graphite)
        ]

        return try definitions.map { definition in
            let card = try cardService.createCard(name: definition.name,
                                                  ensureUniqueName: false,
                                                  attachToBudgetIDs: [])
            assignWorkspace(workspaceID, to: card)
            if let cardID = managedID(for: card) {
                cardAppearanceStore.setTheme(definition.theme, for: cardID)
            }
            return card
        }
    }

    private func createCategories(workspaceID: UUID) throws -> [ExpenseCategory] {
        let palette: [(name: String, color: String)] = [
            ("Housing", "#5D4037"),
            ("Groceries", "#2E7D32"),
            ("Utilities", "#1976D2"),
            ("Dining Out", "#EF6C00"),
            ("Transportation", "#1565C0"),
            ("Entertainment", "#8E24AA")
        ]

        return try palette.map { definition in
            let category = try categoryService.addCategory(name: definition.name,
                                                           color: definition.color,
                                                           ensureUniqueName: false)
            assignWorkspace(workspaceID, to: category)
            return category
        }
    }

    private func createIncomes(workspaceID: UUID,
                                calendar: Calendar,
                                budgetRange: (start: Date, end: Date)) throws {
        let firstPayDate = calendar.date(bySettingHour: 9, minute: 0, second: 0, of: budgetRange.start) ?? budgetRange.start
        let freelanceDate = calendar.date(byAdding: .day, value: 5, to: budgetRange.start) ?? budgetRange.start
        let dividendDate = calendar.date(byAdding: .day, value: 12, to: budgetRange.start) ?? budgetRange.start

        let salary = try incomeService.createIncome(source: "Primary Salary",
                                                    amount: 3200,
                                                    date: firstPayDate,
                                                    isPlanned: true,
                                                    recurrence: "semimonthly",
                                                    recurrenceEndDate: nil,
                                                    secondBiMonthlyDay: 28)
        assignWorkspace(workspaceID, to: salary)

        let freelance = try incomeService.createIncome(source: "Freelance Design",
                                                       amount: 600,
                                                       date: freelanceDate,
                                                       isPlanned: true,
                                                       recurrence: "monthly",
                                                       recurrenceEndDate: nil,
                                                       secondBiMonthlyDay: nil)
        assignWorkspace(workspaceID, to: freelance)

        let dividends = try incomeService.createIncome(source: "Quarterly Dividends",
                                                       amount: 180,
                                                       date: dividendDate,
                                                       isPlanned: false,
                                                       recurrence: nil,
                                                       recurrenceEndDate: nil,
                                                       secondBiMonthlyDay: nil)
        assignWorkspace(workspaceID, to: dividends)
    }

    private func createPlannedExpenses(workspaceID: UUID,
                                        budgetID: UUID?,
                                        calendar: Calendar,
                                        range: (start: Date, end: Date),
                                        categories: [ExpenseCategory]) throws {
        guard let budgetID else { return }

        let categoryLookup = Dictionary(uniqueKeysWithValues: categories.compactMap { category -> (String, ExpenseCategory)? in
            guard let name = category.name?.trimmingCharacters(in: .whitespacesAndNewlines), !name.isEmpty else { return nil }
            return (name, category)
        })

        let entries: [(title: String, planned: Double, actual: Double, offset: Int, categoryName: String?)] = [
            ("Rent", 1600, 1600, 1, "Housing"),
            ("Utilities", 220, 210, 4, "Utilities"),
            ("Groceries", 550, 320, 7, "Groceries"),
            ("Streaming Services", 80, 80, 10, "Entertainment"),
            ("Transit Pass", 110, 95, 14, "Transportation")
        ]

        try entries.forEach { entry in
            let date = calendar.date(byAdding: .day, value: entry.offset, to: range.start) ?? range.start
            let expense = try plannedExpenseService.create(inBudgetID: budgetID,
                                                            titleOrDescription: entry.title,
                                                            plannedAmount: entry.planned,
                                                            actualAmount: entry.actual,
                                                            transactionDate: date,
                                                            isGlobal: false,
                                                            globalTemplateID: nil)
            assignWorkspace(workspaceID, to: expense)
            if let categoryName = entry.categoryName,
               let category = categoryLookup[categoryName] {
                expense.setValue(category, forKey: "expenseCategory")
            }
        }
    }

    private func createUnplannedExpenses(workspaceID: UUID,
                                          cards: [Card],
                                          categories: [ExpenseCategory],
                                          calendar: Calendar,
                                          range: (start: Date, end: Date)) throws {
        guard let everydayCard = cards.first.flatMap(managedID),
              let travelCard = cards.dropFirst().first.flatMap(managedID) else { return }

        let categoryIDsByName: [String: UUID] = categories.reduce(into: [:]) { partialResult, category in
            guard let name = category.name?.trimmingCharacters(in: .whitespacesAndNewlines), !name.isEmpty,
                  let id = managedID(for: category) else { return }
            partialResult[name] = id
        }

        let events: [(description: String, amount: Double, daysFromStart: Int, cardID: UUID, categoryID: UUID?)] = [
            ("Supermarket Run", 124.73, 3, everydayCard, categoryIDsByName["Groceries"]),
            ("Coffee with Friends", 18.40, 6, travelCard, categoryIDsByName["Dining Out"]),
            ("Gas Refill", 46.21, 9, everydayCard, categoryIDsByName["Transportation"]),
            ("Movie Night", 42.00, 12, travelCard, categoryIDsByName["Entertainment"]),
            ("Yoga Class", 28.00, 18, everydayCard, nil)
        ]

        try events.forEach { event in
            let date = calendar.date(byAdding: .day, value: event.daysFromStart, to: range.start) ?? range.start
            let expense = try unplannedExpenseService.create(descriptionText: event.description,
                                                              amount: event.amount,
                                                              date: date,
                                                              cardID: event.cardID,
                                                              categoryID: event.categoryID,
                                                              recurrence: nil,
                                                              recurrenceEnd: nil,
                                                              secondBiMonthlyDay: nil,
                                                              secondBiMonthlyDate: nil,
                                                              parentID: nil)
            assignWorkspace(workspaceID, to: expense)
        }
    }

    private func createCategorySpendingCaps(for categories: [ExpenseCategory],
                                            period: BudgetPeriod,
                                            range: (start: Date, end: Date),
                                            calendar: Calendar) throws {
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyy-MM-dd"

        let startString = formatter.string(from: range.start)
        let endString = formatter.string(from: range.end)

        let segments: [(rawValue: String, minMultiplier: Double, maxMultiplier: Double)] = [
            ("planned", 0.75, 1.25),
            ("variable", 0.0, 0.60)
        ]

        try categories.enumerated().forEach { index, category in
            let context = category.managedObjectContext ?? coreData.viewContext
            let baseAmount = Double(120 + (index * 45))

            try segments.forEach { segment in
                let periodKey = "\(period.rawValue)|\(startString)|\(endString)|\(segment.rawValue)"

                let minAmount = segment.rawValue == "planned" ? baseAmount * segment.minMultiplier : 0
                let maxAmount = baseAmount * segment.maxMultiplier

                try upsertCategorySpendingCap(in: context,
                                              category: category,
                                              periodKey: periodKey,
                                              expenseType: "min",
                                              amount: minAmount)
                try upsertCategorySpendingCap(in: context,
                                              category: category,
                                              periodKey: periodKey,
                                              expenseType: "max",
                                              amount: maxAmount)
            }
        }
    }

    private func upsertCategorySpendingCap(in context: NSManagedObjectContext,
                                           category: ExpenseCategory,
                                           periodKey: String,
                                           expenseType: String,
                                           amount: Double) throws {
        let fetch = NSFetchRequest<CategorySpendingCap>(entityName: "CategorySpendingCap")
        fetch.fetchLimit = 1
        fetch.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
            NSPredicate(format: "category == %@", category),
            NSPredicate(format: "period == %@", periodKey),
            NSPredicate(format: "expenseType ==[c] %@", expenseType)
        ])

        let cap = try context.fetch(fetch).first ?? {
            let inserted = NSEntityDescription.insertNewObject(forEntityName: "CategorySpendingCap", into: context) as? CategorySpendingCap
            inserted?.setValue(UUID(), forKey: "id")
            inserted?.setValue(category, forKey: "category")
            inserted?.setValue(periodKey, forKey: "period")
            inserted?.setValue(expenseType.lowercased(), forKey: "expenseType")
            return inserted
        }()

        cap?.setValue(amount, forKey: "amount")
    }

    // MARK: Workspace Helpers
    private func assignWorkspace(_ workspaceID: UUID, to object: NSManagedObject) {
        guard object.entity.attributesByName.keys.contains("workspaceID") else { return }
        object.setValue(workspaceID, forKey: "workspaceID")
    }

    private func managedID(for object: NSManagedObject) -> UUID? {
        object.value(forKey: "id") as? UUID
    }

    // MARK: Constants
    private static let seedVersionDefaultsKey = "UBDemoSeedVersion"
}
#endif

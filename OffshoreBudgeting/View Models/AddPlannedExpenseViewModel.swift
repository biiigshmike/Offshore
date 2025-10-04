//
//  AddPlannedExpenseViewModel.swift
//  SoFar
//
//  Handles adding a PlannedExpense to a selected Budget.
//  Can optionally mark the expense as a global preset (isGlobal == true)
//  so it appears in “Presets” for quick-add later.
//

import Foundation
import CoreData
import Combine

// MARK: - AddPlannedExpenseViewModel
@MainActor
final class AddPlannedExpenseViewModel: ObservableObject {

    // MARK: Dependencies
    private let context: NSManagedObjectContext

    // MARK: Card Picker Store
    private var cardPickerStore: CardPickerStore?
    private var cardPickerCancellables: Set<AnyCancellable> = []
    private var hasStartedLoading = false

    // MARK: Identity
    private let plannedExpenseID: NSManagedObjectID?
    private let preselectedBudgetID: NSManagedObjectID?
    let isEditing: Bool
    /// When false, a budget is optional (used for preset-only creation).
    private let requiresBudgetSelection: Bool

    // MARK: Loaded Data
    @Published private(set) var allBudgets: [Budget] = []
    @Published private(set) var allCategories: [ExpenseCategory] = []
    @Published private(set) var allCards: [Card] = []
    @Published private(set) var cardsLoaded = false

    // MARK: Live Updates
    /// Listens for Core Data changes and reloads cards/categories/budgets on demand.
    private var changeMonitor: CoreDataEntityChangeMonitor?

    // MARK: Form State
    @Published var selectedBudgetID: NSManagedObjectID?
    @Published var selectedCategoryID: NSManagedObjectID?
    @Published var selectedCardID: NSManagedObjectID?
    @Published var descriptionText: String = ""
    @Published var plannedAmountString: String = ""
    @Published var actualAmountString: String = ""
    @Published var transactionDate: Date = Date()
    @Published var saveAsGlobalPreset: Bool = false

    /// Tracks whether the item being edited was originally a global template.
    private var editingOriginalIsGlobal: Bool = false

    // MARK: Init
    init(plannedExpenseID: NSManagedObjectID? = nil,
         preselectedBudgetID: NSManagedObjectID? = nil,
         requiresBudgetSelection: Bool = true,
         cardPickerStore: CardPickerStore? = nil,
         initialDate: Date? = nil,
         context: NSManagedObjectContext = CoreDataService.shared.viewContext) {
        self.context = context
        self.plannedExpenseID = plannedExpenseID
        self.preselectedBudgetID = preselectedBudgetID
        self.isEditing = plannedExpenseID != nil
        self.requiresBudgetSelection = requiresBudgetSelection
        self.selectedBudgetID = nil
        self.cardPickerStore = cardPickerStore
        if let store = cardPickerStore {
            bindToCardPickerStore(store, preserveSelection: false)
        }
        if let d = initialDate { self.transactionDate = d }
    }

    func attachCardPickerStoreIfNeeded(_ store: CardPickerStore) {
        guard cardPickerStore !== store else { return }
        cardPickerCancellables.removeAll()
        cardPickerStore = store
        bindToCardPickerStore(store, preserveSelection: true)
    }

    func startIfNeeded() {
        guard !hasStartedLoading else { return }
        hasStartedLoading = true
        Task { [weak self] in
            await self?.load()
        }
    }

    // MARK: load()
    func load() async {
        cardsLoaded = cardPickerStore?.isReady ?? false
        CoreDataService.shared.ensureLoaded()
        allBudgets = fetchBudgets()
        allCategories = fetchCategories()
        if cardPickerStore == nil {
            allCards = fetchCards()
        }

        if isEditing, let id = plannedExpenseID,
           let existing = try? context.existingObject(with: id) as? PlannedExpense {
            selectedBudgetID = existing.budget?.objectID
            selectedCategoryID = existing.expenseCategory?.objectID
            selectedCardID = existing.card?.objectID
            descriptionText = existing.descriptionText ?? ""
            plannedAmountString = formatAmount(existing.plannedAmount)
            actualAmountString = formatAmount(existing.actualAmount)
            transactionDate = existing.transactionDate ?? Date()
            saveAsGlobalPreset = existing.isGlobal
            editingOriginalIsGlobal = existing.isGlobal
        } else {
            // If preselected not provided, default to most-recent budget by start date.
            // For preset creation where a budget is optional, we intentionally
            // leave `selectedBudgetID` nil until the user opts to assign one.
            if let pre = preselectedBudgetID {
                selectedBudgetID = pre
            } else if requiresBudgetSelection {
                selectedBudgetID = allBudgets.first?.objectID
            }
            if selectedCategoryID == nil {
                selectedCategoryID = allCategories.first?.objectID
            }
            // If cards exist, do not auto-select; the user will pick one explicitly.
        }

        // Monitor for external inserts/updates/deletes of cards so the picker updates if a new card is added from a sheet.
        var entities: [String] = ["ExpenseCategory", "Budget"]
        if cardPickerStore == nil {
            entities.append("Card")
        }
        changeMonitor = CoreDataEntityChangeMonitor(
            entityNames: entities
        ) { [weak self] in
            guard let self else { return }
            Task { @MainActor in
                if self.cardPickerStore == nil {
                    self.allCards = self.fetchCards()
                }
                self.allCategories = self.fetchCategories()
                self.allBudgets = self.fetchBudgets()
                if self.cardPickerStore == nil {
                    self.cardsLoaded = true
                }
            }
        }

        if cardPickerStore == nil {
            cardsLoaded = true
        }
    }

    // MARK: Validation
    var canSave: Bool {
        let amountValid = Double(plannedAmountString.replacingOccurrences(of: ",", with: "")) != nil
        let textValid = !descriptionText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        let cardValid = (selectedCardID != nil)
        let categoryValid = (selectedCategoryID != nil)
        if isEditing && editingOriginalIsGlobal {
            // Editing a parent template: require a card and a category.
            return textValid && amountValid && cardValid && categoryValid
        }
        if !requiresBudgetSelection && saveAsGlobalPreset {
            // Adding a new global preset without attaching to a budget: require a card and a category.
            return textValid && amountValid && cardValid && categoryValid
        }
        // Standard: require budget, card, and category
        return (selectedBudgetID != nil) && textValid && amountValid && cardValid && categoryValid
    }

    // MARK: save()
    func save() throws {
        let plannedAmt = Double(plannedAmountString.replacingOccurrences(of: ",", with: "")) ?? 0
        let actualAmt  = Double(actualAmountString.replacingOccurrences(of: ",", with: "")) ?? 0

        // Resolve required card selection up-front.
        guard let cardID = selectedCardID,
              let selectedCard = try? context.existingObject(with: cardID) as? Card else {
            throw NSError(domain: "SoFar.AddPlannedExpense", code: 12, userInfo: [NSLocalizedDescriptionKey: "Please select a card."])
        }

        if isEditing,
           let id = plannedExpenseID,
           let existing = try? context.existingObject(with: id) as? PlannedExpense {
            existing.descriptionText = descriptionText.trimmingCharacters(in: .whitespacesAndNewlines)
            existing.plannedAmount = plannedAmt
            existing.actualAmount = actualAmt
            existing.transactionDate = transactionDate
            // Resolve required category selection.
            guard let catID = selectedCategoryID,
                  let category = try? context.existingObject(with: catID) as? ExpenseCategory else {
                throw NSError(domain: "SoFar.AddPlannedExpense", code: 11, userInfo: [NSLocalizedDescriptionKey: "Please select a category."])
            }
            existing.expenseCategory = category
            existing.card = selectedCard
            if editingOriginalIsGlobal {
                // Editing a parent template; keep it global and unattached.
                existing.isGlobal = true
                existing.budget = nil
            } else {
                guard let budgetID = selectedBudgetID,
                      let targetBudget = context.object(with: budgetID) as? Budget else {
                    throw NSError(domain: "SoFar.AddPlannedExpense", code: 10, userInfo: [NSLocalizedDescriptionKey: "Please select a budget."])
                }
                existing.isGlobal = false
                existing.budget = targetBudget
            }
        } else {
            let trimmed = descriptionText.trimmingCharacters(in: .whitespacesAndNewlines)

            if saveAsGlobalPreset {
                // Create a global parent template
                let parent = PlannedExpense(context: context)
                parent.id = parent.id ?? UUID()
                parent.descriptionText = trimmed
                parent.plannedAmount = plannedAmt
                // Preserve any actual amount entered when creating the preset so it
                // can be edited later and displayed in PresetsView
                parent.actualAmount = actualAmt
                parent.transactionDate = transactionDate
                parent.isGlobal = true
                parent.budget = nil
                // Category is required for templates as well
                guard let catID = selectedCategoryID,
                      let category = try? context.existingObject(with: catID) as? ExpenseCategory else {
                    throw NSError(domain: "SoFar.AddPlannedExpense", code: 11, userInfo: [NSLocalizedDescriptionKey: "Please select a category."])
                }
                parent.expenseCategory = category
                parent.card = selectedCard

                if let budgetID = selectedBudgetID,
                   let targetBudget = context.object(with: budgetID) as? Budget {
                    // Optionally create a child attached to a budget if one was selected
                    let child = PlannedExpense(context: context)
                    child.id = child.id ?? UUID()
                    child.descriptionText = trimmed
                    child.plannedAmount = plannedAmt
                    child.actualAmount = actualAmt
                    child.transactionDate = transactionDate
                    child.isGlobal = false
                    child.globalTemplateID = parent.id
                    child.budget = targetBudget
                    // Require category for child too
                    guard let catID = selectedCategoryID,
                          let category = try? context.existingObject(with: catID) as? ExpenseCategory else {
                        throw NSError(domain: "SoFar.AddPlannedExpense", code: 11, userInfo: [NSLocalizedDescriptionKey: "Please select a category."])
                    }
                    child.expenseCategory = category
                    child.card = selectedCard
                }
            } else {
                guard let budgetID = selectedBudgetID,
                      let targetBudget = context.object(with: budgetID) as? Budget else {
                    throw NSError(domain: "SoFar.AddPlannedExpense", code: 10, userInfo: [NSLocalizedDescriptionKey: "Please select a budget."])
                }

                // Standard single planned expense
                let item = PlannedExpense(context: context)
                item.id = item.id ?? UUID()
                item.descriptionText = trimmed
                item.plannedAmount = plannedAmt
                item.actualAmount = actualAmt
                item.transactionDate = transactionDate
                item.isGlobal = false
                item.budget = targetBudget
                // Category is required
                guard let catID = selectedCategoryID,
                      let category = try? context.existingObject(with: catID) as? ExpenseCategory else {
                    throw NSError(domain: "SoFar.AddPlannedExpense", code: 11, userInfo: [NSLocalizedDescriptionKey: "Please select a category."])
                }
                item.expenseCategory = category
                item.card = selectedCard
            }
        }

        try context.save()
    }

    // MARK: Private fetch
    private func fetchBudgets() -> [Budget] {
        let req = NSFetchRequest<Budget>(entityName: "Budget")
        req.sortDescriptors = [
            NSSortDescriptor(key: "startDate", ascending: false),
            NSSortDescriptor(key: "name", ascending: true, selector: #selector(NSString.localizedCaseInsensitiveCompare(_:)))
        ]
        return (try? context.fetch(req)) ?? []
    }

    private func fetchCards() -> [Card] {
        let req = NSFetchRequest<Card>(entityName: "Card")
        req.sortDescriptors = [
            NSSortDescriptor(key: "name", ascending: true, selector: #selector(NSString.localizedCaseInsensitiveCompare(_:)))
        ]
        return (try? context.fetch(req)) ?? []
    }

    private func bindToCardPickerStore(_ store: CardPickerStore, preserveSelection: Bool) {
        updateCardsFromStore(store.cards, preserveSelection: preserveSelection)
        cardsLoaded = store.isReady

        store.$cards
            .receive(on: DispatchQueue.main)
            .sink { [weak self] cards in
                guard let self else { return }
                self.updateCardsFromStore(cards, preserveSelection: true)
            }
            .store(in: &cardPickerCancellables)

        store.$isReady
            .receive(on: DispatchQueue.main)
            .sink { [weak self] ready in
                self?.cardsLoaded = ready
            }
            .store(in: &cardPickerCancellables)
    }

    private func updateCardsFromStore(_ cards: [Card], preserveSelection: Bool) {
        let previousSelection = selectedCardID
        allCards = cards

        guard preserveSelection else { return }

        if let previousSelection,
           !cards.contains(where: { $0.objectID == previousSelection }) {
            selectedCardID = cards.first?.objectID
        }
    }

    private func fetchCategories() -> [ExpenseCategory] {
        let req = NSFetchRequest<ExpenseCategory>(entityName: "ExpenseCategory")
        req.sortDescriptors = [
            NSSortDescriptor(key: "name", ascending: true, selector: #selector(NSString.localizedCaseInsensitiveCompare(_:)))
        ]
        return (try? context.fetch(req)) ?? []
    }

    private func formatAmount(_ value: Double) -> String {
        let nf = NumberFormatter()
        nf.locale = .current
        nf.numberStyle = .decimal
        nf.minimumFractionDigits = 0
        nf.maximumFractionDigits = 2
        return nf.string(from: NSNumber(value: value)) ?? ""
    }
}

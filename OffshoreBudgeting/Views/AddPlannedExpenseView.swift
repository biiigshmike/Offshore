//
//  AddPlannedExpenseView.swift
//  SoFar
//
//  Simple, polished form for adding a planned expense to a budget.
//

import SwiftUI
import UIKit
import CoreData

// MARK: - AddPlannedExpenseView
struct AddPlannedExpenseView: View {

    // MARK: Inputs
    /// Existing PlannedExpense to edit; nil when adding.
    let plannedExpenseID: NSManagedObjectID?
    /// Budget to preselect when adding; ignored if `plannedExpenseID` is provided.
    let preselectedBudgetID: NSManagedObjectID?
    /// If true, the "Use in future budgets?" toggle will start ON when the view first appears.
    let defaultSaveAsGlobalPreset: Bool
    /// When true, shows a toggle allowing the user to optionally assign a budget.
    let showAssignBudgetToggle: Bool
    /// Called after a successful save.
    let onSaved: () -> Void
    /// Optional card to preselect on first load.
    let initialCardID: NSManagedObjectID?

    // MARK: State
    /// We don't call `dismiss()` directly anymore (the scaffold handles it),
    /// but we keep this in case future platform-specific work needs it.
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var themeManager: ThemeManager
    @EnvironmentObject private var cardPickerStore: CardPickerStore
    @StateObject private var vm: AddPlannedExpenseViewModel
    @State private var isAssigningToBudget: Bool

    /// Guard to apply `defaultSaveAsGlobalPreset` only once on first load.
    @State private var didApplyDefaultGlobal = false
    @State private var didApplyInitialCardSelection = false

    @State private var budgetSearchText = ""

    private var filteredBudgets: [Budget] {
        vm.allBudgets.filter { budgetSearchText.isEmpty || ($0.name ?? "").localizedCaseInsensitiveContains(budgetSearchText) }
    }

    // MARK: Layout
    /// Shared card picker height to align with `CardPickerRow`.
    private let cardRowHeight: CGFloat = 160
    @State private var isPresentingAddCard = false

    // MARK: Init
    /// Designated initializer.
    /// - Parameters:
    ///   - plannedExpenseID: ID of expense.
    ///  - preselectedBudgetID: Optional budget objectID to preselect.
    ///   - defaultSaveAsGlobalPreset: When true, defaults the "Use in future budgets?" toggle to ON on first load.
    ///   - showAssignBudgetToggle: Toggle whether or not adding to budget now or later.
    ///  - onSaved: Closure invoked after `vm.save()` succeeds.
    init(
        plannedExpenseID: NSManagedObjectID? = nil,
        preselectedBudgetID: NSManagedObjectID? = nil,
        defaultSaveAsGlobalPreset: Bool = false,
        showAssignBudgetToggle: Bool = false,
        onSaved: @escaping () -> Void,
        initialCardID: NSManagedObjectID? = nil
    ) {
        self.plannedExpenseID = plannedExpenseID
        self.preselectedBudgetID = preselectedBudgetID
        self.defaultSaveAsGlobalPreset = defaultSaveAsGlobalPreset
        self.showAssignBudgetToggle = showAssignBudgetToggle
        self.onSaved = onSaved
        self.initialCardID = initialCardID
        _isAssigningToBudget = State(initialValue: !showAssignBudgetToggle)
        _vm = StateObject(
            wrappedValue: AddPlannedExpenseViewModel(
                plannedExpenseID: plannedExpenseID,
                preselectedBudgetID: preselectedBudgetID,
                requiresBudgetSelection: !showAssignBudgetToggle
            )
        )
    }

    // MARK: Body
    var body: some View {
        EditSheetScaffold(
            title: vm.isEditing ? "Edit Planned Expense" : "Add Planned Expense",
            saveButtonTitle: vm.isEditing ? "Save Changes" : "Save",
            isSaveEnabled: vm.canSave,
            onSave: { trySave() }
        ) {
            // MARK: Card Selection
            UBFormSection("Card", isUppercased: true) {
                if !vm.cardsLoaded {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                        .frame(height: cardRowHeight)
                } else if vm.allCards.isEmpty {
                    VStack(spacing: DS.Spacing.m) {
                        Text("No cards yet. Add one to assign this expense.")
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        GlassCTAButton(
                            maxWidth: .infinity,
                            fillHorizontally: true,
                            fallbackAppearance: .neutral,
                            action: { isPresentingAddCard = true }
                        ) {
                            Label("Add Card", systemImage: "plus")
                        }
                        .accessibilityLabel("Add Card")
                    }
                } else {
                    CardPickerRow(
                        allCards: vm.allCards,
                        selectedCardID: $vm.selectedCardID
                    )
                    .frame(maxWidth: .infinity, alignment: .center)
                    .frame(height: cardRowHeight)
                    .ub_hideScrollIndicators()
                }
            }

            // MARK: Budget Assignment
            if showAssignBudgetToggle && !vm.allBudgets.isEmpty {
                UBFormSection("Add to a budget now?", isUppercased: true) {
                    Toggle("Select a Budget", isOn: $isAssigningToBudget)
                }
                if isAssigningToBudget {
                    budgetPickerSection
                }
            } else if !showAssignBudgetToggle {
                budgetPickerSection
            }

            // MARK: Category Selection
            UBFormSection("Category", isUppercased: true) {
                CategoryChipsRow(selectedCategoryID: $vm.selectedCategoryID)
            }
            .ub_formSectionClearBackground()
            .accessibilityElement(children: .contain)

            // MARK: Individual Fields
            // Instead of grouping all fields into a single section, mirror the
            // Add Card form by giving each input its own section with a
            // descriptive header.  This pushes the label outside of the cell
            // (e.g. “Name” in Add Card) and allows the actual `TextField`
            // to be empty, so the placeholder remains visible and left‑aligned.

            // Expense Description
            UBFormSection("Expense Description", isUppercased: true) {
                // Use an empty label and a prompt for true placeholder styling on modern OSes.
                UBFormRow {
                    if #available(iOS 15.0, macCatalyst 15.0, *) {
                        TextField("", text: $vm.descriptionText, prompt: Text("Electric"))
                            .autocorrectionDisabled(true)
                            .textInputAutocapitalization(.never)
                            .multilineTextAlignment(.leading)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .accessibilityLabel("Expense Description")
                    } else {
                        TextField("Rent", text: $vm.descriptionText)
                            .autocorrectionDisabled(true)
                            .textInputAutocapitalization(.never)
                            .multilineTextAlignment(.leading)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .accessibilityLabel("Expense Description")
                    }
                }
            }

            // Planned Amount
            UBFormSection("Planned Amount", isUppercased: true) {
                UBFormRow {
                    if #available(iOS 15.0, macCatalyst 15.0, *) {
                        TextField("", text: $vm.plannedAmountString, prompt: Text("100"))
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.leading)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .accessibilityLabel("Planned Amount")
                    } else {
                        TextField("2000", text: $vm.plannedAmountString)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.leading)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .accessibilityLabel("Planned Amount")
                    }
                }
            }

            // Actual Amount
            UBFormSection("Actual Amount", isUppercased: true) {
                UBFormRow {
                    if #available(iOS 15.0, macCatalyst 15.0, *) {
                        TextField("", text: $vm.actualAmountString, prompt: Text("102.50"))
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.leading)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .accessibilityLabel("Actual Amount")
                    } else {
                        TextField("102.50", text: $vm.actualAmountString)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.leading)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .accessibilityLabel("Actual Amount")
                    }
                }
            }

            // Transaction Date
            UBFormSection("Transaction Date", isUppercased: true) {
                // Hide the label of the DatePicker itself; the section header supplies the label.
                DatePicker("", selection: $vm.transactionDate, displayedComponents: [.date])
                    .labelsHidden()
                    .ub_compactDatePickerStyle()
                    .accessibilityLabel("Transaction Date")
            }

            // MARK: Use in future budgets?
            UBFormSection("Use in future budgets?", isUppercased: true) {
                Toggle("Use in future budgets?", isOn: $vm.saveAsGlobalPreset)
            }
        }
        .onAppear {
            vm.attachCardPickerStoreIfNeeded(cardPickerStore)
            vm.startIfNeeded()
        }
        .onChange(of: vm.cardsLoaded) { _ in
            guard vm.cardsLoaded else { return }
            applyDefaultSaveAsGlobalPresetIfNeeded()
            applyInitialCardSelectionIfNeeded()
        }
        .onChange(of: vm.allCards) { _ in
            applyInitialCardSelectionIfNeeded()
        }
        .ub_onChange(of: isAssigningToBudget) { newValue in
            guard showAssignBudgetToggle else { return }
            if newValue {
                vm.selectedBudgetID = vm.allBudgets.first?.objectID
            } else {
                vm.selectedBudgetID = nil
            }
        }
        .environment(\.managedObjectContext, CoreDataService.shared.viewContext)
        // Add Card sheet for empty state
        .sheet(isPresented: $isPresentingAddCard) {
            AddCardFormView { newName, selectedTheme in
                do {
                    let service = CardService()
                    let card = try service.createCard(name: newName)
                    if let uuid = card.value(forKey: "id") as? UUID {
                        CardAppearanceStore.shared.setTheme(selectedTheme, for: uuid)
                    }
                    // Select the new card immediately
                    vm.selectedCardID = card.objectID
                } catch {
                    // Best-effort simple alert; the sheet handles its own dismissal
                    let alert = UIAlertController(title: "Couldn’t Create Card", message: error.localizedDescription, preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "OK", style: .default))
                    UIApplication.shared.connectedScenes
                        .compactMap { ($0 as? UIWindowScene)?.keyWindow }
                        .first?
                        .rootViewController?
                        .present(alert, animated: true)
                }
            }
        }
    }

    // MARK: Actions
    /// Attempts to save; on success calls `onSaved`.
    /// - Returns: `true` if the sheet should dismiss, `false` to stay open.
    private func trySave() -> Bool {
        guard vm.canSave else { return false }
        do {
            try vm.save()
            onSaved()
            // Resign keyboard on iOS for a neat dismissal.
            ub_dismissKeyboard()
            return true
        } catch {
            // Present error via UIKit alert on iOS; macOS simply returns false.
            let alert = UIAlertController(
                title: "Couldn’t Save",
                message: error.localizedDescription,
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            UIApplication.shared.connectedScenes
                .compactMap { ($0 as? UIWindowScene)?.keyWindow }
                .first?
                .rootViewController?
                .present(alert, animated: true)
            return false
        }
    }

    @ViewBuilder
    private var budgetPickerSection: some View {
        UBFormSection("Choose Budget", isUppercased: true) {
            UBFormRow {
                // Use a custom binding so the selection is cleared immediately
                // when the search text changes to a string that doesn't include
                // the currently selected budget.  This avoids transient invalid
                // picker selections that trigger console warnings.
                TextField(
                    "Search Budgets",
                    text: Binding(
                        get: { budgetSearchText },
                        set: { newValue in
                            budgetSearchText = newValue
                            let matching = vm.allBudgets.filter { budget in
                                newValue.isEmpty || (budget.name ?? "").localizedCaseInsensitiveContains(newValue)
                            }
                            if newValue.isEmpty {
                                vm.selectedBudgetID = nil
                            } else if let current = vm.selectedBudgetID,
                                      matching.contains(where: { $0.objectID == current }) {
                                // Keep existing selection if it still matches
                            } else {
                                // Auto-select the first matching budget so the
                                // menu label updates dynamically without the
                                // user opening the dropdown.
                                vm.selectedBudgetID = matching.first?.objectID
                            }
                        }
                    )
                )
                .autocorrectionDisabled(true)
                .textInputAutocapitalization(.never)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            UBFormRow {
                // Use a Menu instead of a Picker to prevent warnings about
                // invalid selections when the available budgets change.
                Menu {
                    ForEach(filteredBudgets, id: \.objectID) { budget in
                        Button(budget.name ?? "Untitled") {
                            vm.selectedBudgetID = budget.objectID
                        }
                    }
                } label: {
                    Text(
                        vm.allBudgets.first(where: { $0.objectID == vm.selectedBudgetID })?.name ?? "Select Budget"
                    )
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .menuStyle(.borderlessButton)
                .id(budgetSearchText)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    private func applyDefaultSaveAsGlobalPresetIfNeeded() {
        guard !vm.isEditing, !didApplyDefaultGlobal else { return }
        vm.saveAsGlobalPreset = defaultSaveAsGlobalPreset
        didApplyDefaultGlobal = true
    }

    private func applyInitialCardSelectionIfNeeded() {
        guard !didApplyInitialCardSelection,
              let initialCardID,
              vm.selectedCardID == nil,
              vm.cardsLoaded,
              vm.allCards.contains(where: { $0.objectID == initialCardID }) else { return }
        vm.selectedCardID = initialCardID
        didApplyInitialCardSelection = true
    }
}

// MARK: - CategoryChipsRow
/// Shared layout metrics for the category pill controls.
/// Reusable horizontally scrolling row of category chips with an Add button.
private struct CategoryChipsRow: View {

    @Binding var selectedCategoryID: NSManagedObjectID?
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.platformCapabilities) private var capabilities
    @EnvironmentObject private var themeManager: ThemeManager
    @Namespace private var glassNamespace

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(key: "name", ascending: true,
                                           selector: #selector(NSString.localizedCaseInsensitiveCompare(_:)))]
    )
    private var categories: FetchedResults<ExpenseCategory>

    @State private var isPresentingNewCategory = false
    @State private var addButtonWidth: CGFloat = .zero

    private let verticalInset: CGFloat = DS.Spacing.s + DS.Spacing.xs
    private let addButtonSpacing: CGFloat = DS.Spacing.m
    private let chipRowClipShape = Capsule(style: .continuous)

    var body: some View {
        ZStack(alignment: .leading) {
            chipsScrollContainer()
                .padding(.leading, chipsLeadingPadding)

            addCategoryButton
        }
        .listRowBackground(Color.clear)
        .listRowInsets(
            EdgeInsets(
                top: verticalInset,
                leading: DS.Spacing.l,
                bottom: verticalInset,
                trailing: DS.Spacing.l
            )
        )
        .sheet(isPresented: $isPresentingNewCategory) {
            ExpenseCategoryEditorSheet(
                initialName: "",
                initialHex: "#4E9CFF"
            ) { name, hex in
                let category = ExpenseCategory(context: viewContext)
                category.id = UUID()
                category.name = name
                category.color = hex
                do {
                    try viewContext.obtainPermanentIDs(for: [category])
                    try viewContext.save()
                    selectedCategoryID = category.objectID
                } catch {
                    AppLog.ui.error("Failed to create category: \(error.localizedDescription)")
                }
            }
            // Guard presentationDetents for iOS 16+ only.
            .modifier(PresentationDetentsCompat())
            .environment(\.managedObjectContext, viewContext)
        }
        .ub_onChange(of: categories.count) {
            if selectedCategoryID == nil, let first = categories.first {
                selectedCategoryID = first.objectID
            }
        }
    }
}

private extension CategoryChipsRow {
    private var chipsLeadingPadding: CGFloat { addButtonWidth + addButtonSpacing }

    private var addCategoryButton: some View {
        AddCategoryPill { isPresentingNewCategory = true }
            .zIndex(1)
            .background(addButtonWidthReader)
    }

    private var addButtonWidthReader: some View {
        GeometryReader { proxy in
            Color.clear
                .onAppear { updateAddButtonWidth(proxy.size.width) }
                .ub_onChange(of: proxy.size.width) { newWidth in
                    updateAddButtonWidth(newWidth)
                }
        }
    }

    @ViewBuilder
    private func chipsScrollContainer() -> some View {
        if capabilities.supportsOS26Translucency, #available(iOS 26.0, macOS 26.0, macCatalyst 26.0, *) {
            GlassEffectContainer(spacing: DS.Spacing.s) {
                chipsScrollView(namespace: glassNamespace)
            }
            .clipShape(chipRowClipShape)
        } else {
            chipsScrollView(namespace: nil)
        }
    }

    @ViewBuilder
    private func chipsScrollView(namespace: Namespace.ID?) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            LazyHStack(spacing: DS.Spacing.s) {
                if categories.isEmpty {
                    Text("No categories yet")
                        .foregroundStyle(.secondary)
                        .padding(.vertical, 10)
                } else {
                    ForEach(categories, id: \.objectID) { cat in
                        let isSelected = selectedCategoryID == cat.objectID
                        CategoryChip(
                            id: cat.objectID.uriRepresentation().absoluteString,
                            name: cat.name ?? "Untitled",
                            colorHex: cat.color ?? "#999999",
                            isSelected: isSelected,
                            namespace: namespace
                        )
                        .onTapGesture { selectedCategoryID = cat.objectID }
                        .glassEffectTransitionIfNeeded(using: namespace)
                    }
                }
            }
            .padding(.horizontal, DS.Spacing.s)
        }
        .ub_hideScrollIndicators()
        .ub_disableHorizontalBounce()
        .clipped()
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func updateAddButtonWidth(_ width: CGFloat) {
        let quantized = (width * 2).rounded() / 2
        let tolerance: CGFloat = 0.5
        DispatchQueue.main.async {
            if abs(addButtonWidth - quantized) > tolerance {
                addButtonWidth = max(0, quantized)
            }
        }
    }
}

private extension View {
    @ViewBuilder
    func glassEffectTransitionIfNeeded(using namespace: Namespace.ID?) -> some View {
        if #available(iOS 26.0, macOS 26.0, macCatalyst 26.0, *) {
            self.glassEffectTransition(.matchedGeometry)
        } else {
            self
        }
    }
}

// A tiny compatibility wrapper to avoid directly calling presentationDetents on older OSes.
private struct PresentationDetentsCompat: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 16.0, *) {
            content.presentationDetents([.medium])
        } else {
            content
        }
    }
}

// MARK: - AddCategoryPill
private struct AddCategoryPill: View {
    var onTap: () -> Void
    @EnvironmentObject private var themeManager: ThemeManager

    var body: some View {
        Button(action: onTap) {
            Label("Add", systemImage: "plus")
                .font(.subheadline.weight(.semibold))
        }
        .buttonStyle(
            AddCategoryPillStyle(
                tint: themeManager.selectedTheme.resolvedTint
            )
        )
        .controlSize(.regular)
        .accessibilityLabel("Add Category")
    }
}

// MARK: - CategoryChip
private struct CategoryChip: View {
    let id: String
    let name: String
    let colorHex: String
    let isSelected: Bool
    let namespace: Namespace.ID?
    @Environment(\.platformCapabilities) private var capabilities
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        let categoryColor = Color(hex: colorHex) ?? .secondary
        let style = CategoryChipStyle.make(
            isSelected: isSelected,
            categoryColor: categoryColor,
            colorScheme: colorScheme
        )

        let pill = CategoryChipPill(
            isSelected: isSelected,
            glassTint: style.glassTint,
            glassTextColor: style.glassTextColor,
            fallbackTextColor: style.fallbackTextColor,
            fallbackFill: style.fallbackFill,
            fallbackStrokeColor: style.fallbackStroke.color,
            fallbackStrokeLineWidth: style.fallbackStroke.lineWidth
        ) {
            HStack(spacing: DS.Spacing.s) {
                Circle()
                    .fill(categoryColor)
                    .frame(width: 10, height: 10)
                Text(name)
                    .font(.subheadline.weight(.semibold))
            }
        }
        let resolvedChip = Group {
            if capabilities.supportsOS26Translucency, #available(iOS 26.0, macCatalyst 26.0, *) {
                if let ns = namespace {
                    pill
                        .glassEffectID(id, in: ns)
                } else {
                    pill
                }
            } else {
                pill
            }
        }

        let base = resolvedChip
            .scaleEffect(style.scale)
            .animation(.easeOut(duration: 0.15), value: isSelected)
            .accessibilityAddTraits(isSelected ? .isSelected : [])

        let shouldApplyShadow = style.shadowRadius > 0 || style.shadowY != 0

        if shouldApplyShadow {
            base
                .shadow(
                    color: style.shadowColor,
                    radius: style.shadowRadius,
                    x: 0,
                    y: style.shadowY
                )
        } else {
            base
        }
    }

}

// MARK: - Styles
private struct AddCategoryPillStyle: ButtonStyle {
    let tint: Color

    func makeBody(configuration: Configuration) -> some View {
        let isActive = configuration.isPressed

        let capsule = Capsule(style: .continuous)

        return CategoryChipPill(
            isSelected: false,
            glassTextColor: .primary,
            fallbackTextColor: .primary,
            fallbackFill: DS.Colors.chipFill,
            fallbackStrokeColor: DS.Colors.chipFill,
            fallbackStrokeLineWidth: 1
        ) {
            configuration.label
                .font(.subheadline.weight(.semibold))
        }
        .overlay {
            if isActive {
                capsule.strokeBorder(tint.opacity(0.35), lineWidth: 2)
            }
        }
        .animation(.easeOut(duration: 0.15), value: isActive)
    }
}

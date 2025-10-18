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
    @EnvironmentObject private var cardPickerStore: CardPickerStore
    @StateObject private var vm: AddPlannedExpenseViewModel
    @State private var isAssigningToBudget: Bool
    @State private var didSyncAssignBudgetToggle = false

    /// Guard to apply `defaultSaveAsGlobalPreset` only once on first load.
    @State private var didApplyDefaultGlobal = false
    @State private var didApplyInitialCardSelection = false

    @State private var budgetSearchText = ""
    @State private var isShowingScopeDialog = false

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
        let shouldStartAssigning: Bool
        if !showAssignBudgetToggle {
            shouldStartAssigning = true
        } else if plannedExpenseID != nil || preselectedBudgetID != nil {
            shouldStartAssigning = true
        } else {
            shouldStartAssigning = false
        }
        _isAssigningToBudget = State(initialValue: shouldStartAssigning)
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
        navigationContainer {
            Form {
            // MARK: Card Selection
            Section {
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
                            height: 33,
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
                    .scrollIndicators(.hidden)
                }
            } header: {
                Text("Card")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)
            }

            // MARK: Budget Assignment
            if showAssignBudgetToggle && !vm.allBudgets.isEmpty {
                Section {
                    Toggle("Select a Budget", isOn: $isAssigningToBudget)
                } header: {
                    Text("Add to a budget now?")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .textCase(.uppercase)
                }
                if isAssigningToBudget {
                    budgetPickerSection
                }
            } else if !showAssignBudgetToggle {
                budgetPickerSection
            }

            // MARK: Category Selection
            Section {
                CategoryChipsRow(selectedCategoryID: $vm.selectedCategoryID)
            }
//            .ub_formSectionClearBackground()
            .accessibilityElement(children: .contain)

            // MARK: Individual Fields
            // Instead of grouping all fields into a single section, mirror the
            // Add Card form by giving each input its own section with a
            // descriptive header.  This pushes the label outside of the cell
            // (e.g. “Name” in Add Card) and allows the actual `TextField`
            // to be empty, so the placeholder remains visible and left‑aligned.

            // Expense Description
            Section {
                // Use an empty label and a prompt for true placeholder styling on modern OSes.
                HStack(alignment: .center) {
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
                    Spacer(minLength: 0)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            } header: {
                Text("Expense Description")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)
            }

            // Planned Amount
            Section {
                HStack(alignment: .center) {
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
                    Spacer(minLength: 0)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            } header: {
                Text("Planned Amount")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)
            }

            // Actual Amount
            Section {
                HStack(alignment: .center) {
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
                    Spacer(minLength: 0)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            } header: {
                Text("Actual Amount")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)
            }

            // Transaction Date
            Section {
                // Hide the label of the DatePicker itself; the section header supplies the label.
                DatePicker("", selection: $vm.transactionDate, displayedComponents: [.date])
                    .labelsHidden()
                    .datePickerStyle(.compact)
                    .accessibilityLabel("Transaction Date")
            } header: {
                Text("Transaction Date")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)
            }
            // MARK: Use in future budgets?
            Section {
                Toggle("Use in future budgets?", isOn: $vm.saveAsGlobalPreset)
            } header: {
                Text("Use in future budgets?")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)
            }
            }
            .listStyle(.insetGrouped)
            .scrollIndicators(.hidden)
            .navigationTitle(vm.isEditing ? "Edit Planned Expense" : "Add Planned Expense")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(vm.isEditing ? "Save Changes" : "Save") {
                        if trySave() { dismiss() }
                    }
                    .disabled(!vm.canSave)
                }
            }
        }
        .applyDetentsIfAvailable(detents: [.medium, .large], selection: nil)
        .onAppear {
            vm.attachCardPickerStoreIfNeeded(cardPickerStore)
            vm.startIfNeeded()
            applyInitialAssignBudgetToggleIfNeeded()
        }
        .onChange(of: vm.cardsLoaded) { _ in
            guard vm.cardsLoaded else { return }
            applyDefaultSaveAsGlobalPresetIfNeeded()
            applyInitialCardSelectionIfNeeded()
            applyInitialAssignBudgetToggleIfNeeded()
        }
        .onChange(of: vm.allBudgets.count) { _ in
            applyInitialAssignBudgetToggleIfNeeded()
        }
        .onChange(of: vm.selectedBudgetIDs) { _ in
            applyInitialAssignBudgetToggleIfNeeded()
        }
        .onChange(of: vm.allCards) { _ in
            applyInitialCardSelectionIfNeeded()
        }
        .onChange(of: isAssigningToBudget) { newValue in
            guard showAssignBudgetToggle else { return }
            if newValue {
                if vm.selectedBudgetIDs.isEmpty, let first = vm.allBudgets.first?.objectID {
                    vm.selectedBudgetIDs = [first]
                }
            } else {
                vm.selectedBudgetIDs = []
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
        .confirmationDialog(
            "Apply changes to related expenses?",
            isPresented: $isShowingScopeDialog
        ) {
            Button("Only this expense") {
                if performSave(scope: .onlyThis) {
                    dismiss()
                }
            }
            Button("Past instances") {
                if performSave(scope: .past(referenceDate: vm.transactionDate)) {
                    dismiss()
                }
            }
            Button("Future instances") {
                if performSave(scope: .future(referenceDate: vm.transactionDate)) {
                    dismiss()
                }
            }
            Button("All instances") {
                if performSave(scope: .all(referenceDate: vm.transactionDate)) {
                    dismiss()
                }
            }
            Button("Cancel", role: .cancel) { }
        }
    }

    // MARK: Actions
    /// Attempts to save; on success calls `onSaved`.
    /// - Returns: `true` if the sheet should dismiss, `false` to stay open.
    private func trySave() -> Bool {
        guard vm.canSave else { return false }
        if vm.shouldPromptForScopeSelection {
            isShowingScopeDialog = true
            return false
        }
        return performSave(scope: .onlyThis)
    }

    @discardableResult
    private func performSave(scope: PlannedExpenseUpdateScope) -> Bool {
        do {
            try vm.save(scope: scope)
            onSaved()
            ub_dismissKeyboard()
            return true
        } catch {
            presentSaveError(error)
            return false
        }
    }

    private func presentSaveError(_ error: Error) {
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
    }

    @ViewBuilder
    private var budgetPickerSection: some View {
        Section {
            HStack(alignment: .center) {
                TextField("Search Budgets", text: $budgetSearchText)
                .autocorrectionDisabled(true)
                .textInputAutocapitalization(.never)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            HStack(alignment: .center) {
                // Use a Menu instead of a Picker to prevent warnings about
                // invalid selections when the available budgets change.
                Menu {
                    ForEach(filteredBudgets, id: \.objectID) { budget in
                        Button {
                            vm.toggleBudgetSelection(for: budget.objectID)
                        } label: {
                            HStack {
                                Text(budget.name ?? "Untitled")
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                if vm.isBudgetSelected(budget.objectID) {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                } label: {
                    Text(budgetSelectionSummary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .menuStyle(.borderlessButton)
                .menuActionDismissBehavior(.disabled)
                .id(budgetSearchText)
                .frame(maxWidth: .infinity, alignment: .leading)
                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        } header: {
            Text("Choose Budget")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
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

    private func applyInitialAssignBudgetToggleIfNeeded() {
        guard showAssignBudgetToggle, !didSyncAssignBudgetToggle else { return }
        let hasSelection = !vm.selectedBudgetIDs.isEmpty
        if hasSelection != isAssigningToBudget {
            isAssigningToBudget = hasSelection
        }
        if hasSelection || !vm.allBudgets.isEmpty {
            didSyncAssignBudgetToggle = true
        }
    }

    private var budgetSelectionSummary: String {
        let names = vm.selectedBudgetNames
        guard !names.isEmpty else { return "Select Budgets" }
        if names.count == 1 { return names[0] }
        if names.count == 2 { return names.joined(separator: ", ") }
        let prefix = names.prefix(2).joined(separator: ", ")
        let remaining = names.count - 2
        return "\(prefix) +\(remaining) more"
    }
}

// MARK: - Navigation container
private extension AddPlannedExpenseView {
    @ViewBuilder
    func navigationContainer<Inner: View>(@ViewBuilder content: () -> Inner) -> some View {
        if #available(iOS 16.0, macCatalyst 16.0, *) {
            NavigationStack { content() }
        } else {
            NavigationView { content() }
        }
    }
}

// MARK: - CategoryChipsRow
/// Shared layout metrics for the category pill controls.
/// Reusable horizontally scrolling row of category chips with an Add button.
private struct CategoryChipsRow: View {

    @Binding var selectedCategoryID: NSManagedObjectID?
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.platformCapabilities) private var capabilities

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(key: "name", ascending: true,
                                           selector: #selector(NSString.localizedCaseInsensitiveCompare(_:)))]
    )
    private var categories: FetchedResults<ExpenseCategory>

    @State private var isPresentingNewCategory = false

    private let verticalInset: CGFloat = DS.Spacing.s + DS.Spacing.xs
    private let chipRowClipShape = Rectangle()

    var body: some View {
        HStack(alignment: .center, spacing: DS.Spacing.s) {
            addCategoryButton
            chipsScrollContainer()
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .listRowInsets(rowInsets)
        .listRowSeparator(.hidden)
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
        .onChange(of: categories.count) { _ in
            if selectedCategoryID == nil, let first = categories.first {
                selectedCategoryID = first.objectID
            }
        }
    }

    private var rowInsets: EdgeInsets {
        EdgeInsets(
            top: verticalInset,
            leading: DS.Spacing.l,
            bottom: verticalInset,
            trailing: DS.Spacing.l
        )
    }
}

private extension CategoryChipsRow {
    @ViewBuilder
    private func chipsScrollContainer() -> some View {
        if capabilities.supportsOS26Translucency, #available(iOS 26.0, macOS 26.0, macCatalyst 26.0, *) {
            GlassEffectContainer(spacing: DS.Spacing.s) {
                chipRowLayout()
            }
            .clipShape(chipRowClipShape)
        } else {
            chipRowLayout()
                .clipShape(chipRowClipShape)
        }
    }

    private func chipRowLayout() -> some View {
        chipsScrollView()
            .padding(.horizontal, DS.Spacing.s)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func chipsScrollView() -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            categoryChips
                .padding(.trailing, DS.Spacing.s)
        }
        .scrollIndicators(.hidden)
        .ub_disableHorizontalBounce()
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private var categoryChips: some View {
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
                        action: { selectedCategoryID = cat.objectID }
                    )
                }
            }
        }
    }

    private var addCategoryButton: some View {
        AddCategoryPill { isPresentingNewCategory = true }
            .padding(.leading, DS.Spacing.s)
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
    var fillsWidth: Bool = false
    var onTap: () -> Void
    @EnvironmentObject private var themeManager: ThemeManager

    var body: some View {
        if #available(iOS 26.0, macOS 26.0, macCatalyst 26.0, *) {
            let label = Label("Add", systemImage: "plus")
                .font(.subheadline.weight(.semibold))
                .padding(.horizontal, 12)
                .frame(maxWidth: fillsWidth ? .infinity : nil, maxHeight: 44, alignment: .center)
                .glassEffect(.regular.tint(.none).interactive(true))
                .clipShape(Capsule())
                .compositingGroup()
            Button(action: onTap) {
                label
            }
            .buttonStyle(.plain)
            .frame(maxWidth: fillsWidth ? .infinity : nil, maxHeight: 44, alignment: .center)
            .accessibilityLabel("Add Category")
        } else {
            Button(action: onTap) {
                Label("Add", systemImage: "plus")
                    .font(.subheadline.weight(.semibold))
                    .padding(.horizontal, 12)
                    .frame(maxWidth: fillsWidth ? .infinity : nil, maxHeight: 33, alignment: .center)
                    .background(
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .fill(Color(UIColor { traits in
                                traits.userInterfaceStyle == .dark ? UIColor(white: 0.22, alpha: 1) : UIColor(white: 0.9, alpha: 1)
                            }))
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                    .contentShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
            }
            .buttonStyle(.plain)
            .controlSize(.regular)
            .frame(maxWidth: fillsWidth ? .infinity : nil, maxHeight: 33, alignment: .center)
            .accessibilityLabel("Add Category")
        }
    }
}

// MARK: - CategoryChip
private struct CategoryChip: View {
    let id: String
    let name: String
    let colorHex: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        let accentColor = UBColorFromHex(colorHex) ?? .secondary
        let glassTintColor = accentColor.opacity(0.25)
        let legacyShape = RoundedRectangle(cornerRadius: 6, style: .continuous)

        let label = HStack(spacing: DS.Spacing.s) {
            Circle()
                .fill(accentColor)
                .frame(width: 10, height: 10)
            Text(name)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.primary)
        }
        .padding(.horizontal, 12)
        .frame(minHeight: 33, maxHeight: 44)
        .background(.clear)

        if #available(iOS 26.0, macOS 26.0, macCatalyst 26.0, *) {
            Button(action: action) {
                label
                    .glassEffect(
                        .regular
                            .tint(isSelected ? glassTintColor : .none)
                            .interactive(true)
                    )
                    .frame(maxHeight: 33)
                    .clipShape(Capsule())
                    .compositingGroup()
            }
            .accessibilityAddTraits(isSelected ? .isSelected : [])
            .animation(.easeOut(duration: 0.15), value: isSelected)
            .frame(maxHeight: 44)
            .buttonStyle(.plain)
            .buttonBorderShape(.capsule)
        } else {
            let neutralFill = DS.Colors.chipFill
            Button(action: action) {
                label
            }
            .accessibilityAddTraits(isSelected ? .isSelected : [])
            .animation(.easeOut(duration: 0.15), value: isSelected)
            .frame(maxHeight: 33)
            .buttonStyle(.plain)
            .background(
                legacyShape.fill(isSelected ? glassTintColor : neutralFill)
            )
                .overlay(
                    legacyShape
                        .stroke(neutralFill, lineWidth: 1)
                )
                .contentShape(legacyShape)
        }
    }

}

// MARK: - Hex Color Helper (local)
fileprivate func UBColorFromHex(_ hex: String?) -> Color? {
    guard var value = hex?.trimmingCharacters(in: .whitespacesAndNewlines), !value.isEmpty else { return nil }
    if value.hasPrefix("#") { value.removeFirst() }
    guard value.count == 6, let intVal = Int(value, radix: 16) else { return nil }
    let r = Double((intVal >> 16) & 0xFF) / 255.0
    let g = Double((intVal >> 8) & 0xFF) / 255.0
    let b = Double(intVal & 0xFF) / 255.0
    return Color(red: r, green: g, blue: b)
}

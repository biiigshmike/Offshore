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
    /// Called when the view should be dismissed by a parent container.
    let onDismiss: () -> Void
    /// Optional card to preselect on first load.
    let initialCardID: NSManagedObjectID?
    /// Wraps the content in a navigation container when presented standalone.
    let wrapsInNavigation: Bool

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
    @State private var showAllBudgets = false
    @State private var isShowingScopeDialog = false

    private var filteredBudgets: [Budget] {
        vm.allBudgets.filter { budgetSearchText.isEmpty || ($0.name ?? "").localizedCaseInsensitiveContains(budgetSearchText) }
    }

    // MARK: Layout
    /// Shared card picker height to align with `CardPickerRow`.
    @ScaledMetric(relativeTo: .body) private var cardRowHeight: CGFloat = 160
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
        onDismiss: @escaping () -> Void = {},
        initialCardID: NSManagedObjectID? = nil,
        wrapsInNavigation: Bool = true
    ) {
        self.plannedExpenseID = plannedExpenseID
        self.preselectedBudgetID = preselectedBudgetID
        self.defaultSaveAsGlobalPreset = defaultSaveAsGlobalPreset
        self.showAssignBudgetToggle = showAssignBudgetToggle
        self.onSaved = onSaved
        self.onDismiss = onDismiss
        self.initialCardID = initialCardID
        self.wrapsInNavigation = wrapsInNavigation
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
                        .frame(minHeight: cardRowHeight)
                } else if vm.allCards.isEmpty {
                    VStack(spacing: DS.Spacing.m) {
                        Text("No cards yet. Add one to assign this expense.")
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        GlassCTAButton(
                            maxWidth: .infinity,
                            height: 44,
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
                    .frame(minHeight: cardRowHeight)
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
                    Button("Cancel") {
                        onDismiss()
                        dismiss()
                    }
                }
                // Editing: single trailing action
                ToolbarItem(placement: .confirmationAction) {
                    if vm.isEditing {
                        Button("Save Changes") {
                            if trySave() {
                                onDismiss()
                                dismiss()
                            }
                        }
                        .disabled(!vm.canSave)
                    }
                }
                // Adding: separate trailing actions (no container)
                if !vm.isEditing {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Save") {
                            if trySave() { dismiss() }
                        }
                        .disabled(!vm.canSave)
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Save and Add") {
                            if saveAndStayOpen() { resetFormForNewEntry() }
                        }
                        .disabled(!vm.canSave)
                    }
                }
            }
        }
        .applyDetentsIfAvailable(detents: [.medium, .large], selection: nil)
        .onAppear {
            vm.attachCardPickerStoreIfNeeded(cardPickerStore)
            vm.startIfNeeded()
            applyInitialCardSelectionIfNeeded()
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
                    try service.updateCard(card, name: nil, theme: selectedTheme)
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
                    onDismiss()
                    dismiss()
                }
            }
            Button("Past instances") {
                if performSave(scope: .past(referenceDate: vm.transactionDate)) {
                    onDismiss()
                    dismiss()
                }
            }
            Button("Future instances") {
                if performSave(scope: .future(referenceDate: vm.transactionDate)) {
                    onDismiss()
                    dismiss()
                }
            }
            Button("All instances") {
                if performSave(scope: .all(referenceDate: vm.transactionDate)) {
                    onDismiss()
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

    /// Saves without invoking `onSaved` so the sheet remains open.
    /// Returns true on success, false on failure or if validation fails.
    private func saveAndStayOpen() -> Bool {
        guard vm.canSave else { return false }
        do {
            try vm.save(scope: .onlyThis)
            // Do NOT call onSaved() here — parent may dismiss sheet.
            return true
        } catch {
            presentSaveError(error)
            return false
        }
    }

    /// Clears key entry fields so the user can add another item without closing the form.
    private func resetFormForNewEntry() {
        // Keep selections (card, category, budgets, global preset toggle) as-is for faster entry.
        vm.descriptionText = ""
        vm.plannedAmountString = ""
        vm.actualAmountString = ""
        // Keep date unchanged to facilitate adding multiple for a given day.
    }

    @ViewBuilder
    private var budgetPickerSection: some View {
        Section {
            // Search field
            HStack(alignment: .center) {
                TextField("Search Budgets", text: $budgetSearchText)
                    .autocorrectionDisabled(true)
                    .textInputAutocapitalization(.never)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            // Inline, multi-select list with trailing checkmarks
            let all = filteredBudgets
            let isSearching = !budgetSearchText.isEmpty
            let limit = 10
            let collapsed = !showAllBudgets && !isSearching && all.count > limit
            let visible = collapsed ? Array(all.prefix(limit)) : all

            if all.isEmpty {
                Text("No matching budgets")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                ForEach(visible, id: \.objectID) { budget in
                    Button {
                        withAnimation(.easeInOut) {
                            vm.toggleBudgetSelection(for: budget.objectID)
                        }
                    } label: {
                        HStack {
                            Text(budget.name ?? "Untitled")
                                .frame(maxWidth: .infinity, alignment: .leading)
                            if vm.isBudgetSelected(budget.objectID) {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .contentShape(Rectangle())
                    .accessibilityLabel("Select budget \(budget.name ?? "Untitled")")
                    .accessibilityValue(vm.isBudgetSelected(budget.objectID) ? "Selected" : "Not Selected")
                }

                // Show All / Show Less control (only when not searching)
                if !isSearching && all.count > limit {
                    if showAllBudgets {
                        Button("Show Less") { withAnimation(.easeInOut) { showAllBudgets = false } }
                            .frame(maxWidth: .infinity, alignment: .leading)
                    } else {
                        let remaining = all.count - limit
                        Button("Show All (\(remaining) more)") { withAnimation(.easeInOut) { showAllBudgets = true } }
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            }
        } header: {
            Text("Choose Budget")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
        }
        .animation(.easeInOut, value: showAllBudgets)
    }

    private func applyDefaultSaveAsGlobalPresetIfNeeded() {
        guard !vm.isEditing, !didApplyDefaultGlobal else { return }
        vm.saveAsGlobalPreset = defaultSaveAsGlobalPreset
        didApplyDefaultGlobal = true
    }

    private func applyInitialCardSelectionIfNeeded() {
        guard !didApplyInitialCardSelection, let initialCardID else { return }
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

}

// MARK: - Navigation container
private extension AddPlannedExpenseView {
    @ViewBuilder
    func navigationContainer<Inner: View>(@ViewBuilder content: () -> Inner) -> some View {
        if !wrapsInNavigation {
            content()
        } else if #available(iOS 16.0, macCatalyst 16.0, *) {
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
    @AppStorage(AppSettingsKeys.activeWorkspaceID.rawValue) private var activeWorkspaceIDRaw: String = ""
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(key: "name", ascending: true,
                                           selector: #selector(NSString.localizedCaseInsensitiveCompare(_:)))]
    )
    private var categories: FetchedResults<ExpenseCategory>

    @State private var isPresentingNewCategory = false
    // Force fresh instance so the editor sheet doesn't retain prior @State on Mac Catalyst
    @State private var addCategorySheetInstanceID = UUID()

    private let verticalInset: CGFloat = DS.Spacing.s + DS.Spacing.xs
    private var isAccessibilitySize: Bool { dynamicTypeSize.isAccessibilitySize }

    private var filteredCategories: [ExpenseCategory] {
        guard let workspaceID = UUID(uuidString: activeWorkspaceIDRaw) else { return Array(categories) }
        return categories.filter { category in
            (category.value(forKey: "workspaceID") as? UUID) == workspaceID
        }
    }

    var body: some View {
        Group {
            if isAccessibilitySize {
                VStack(alignment: .leading, spacing: DS.Spacing.s) {
                    addCategoryButton
                        .frame(maxWidth: .infinity, alignment: .leading)
                    chipsScrollContainer()
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            } else {
                HStack(alignment: .center, spacing: DS.Spacing.s) {
                    addCategoryButton
                    chipsScrollContainer()
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .listRowInsets(rowInsets)
        .listRowSeparator(.hidden)
        .ub_preOS26ListRowBackground(.clear)
        .sheet(isPresented: $isPresentingNewCategory) {
            ExpenseCategoryEditorSheet(
                initialName: "",
                initialHex: "#4E9CFF"
            ) { name, hex in
                let category = ExpenseCategory(context: viewContext)
                category.id = UUID()
                category.name = name
                category.color = hex
                WorkspaceService.shared.applyWorkspaceID(on: category)
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
            // Ensure a fresh view identity each presentation
            .id(addCategorySheetInstanceID)
            .environment(\.managedObjectContext, viewContext)
        }
        .onChange(of: categories.count) { _ in
            if selectedCategoryID == nil, let first = filteredCategories.first {
                selectedCategoryID = first.objectID
            }
        }
        .onChange(of: activeWorkspaceIDRaw) { _ in
            if let first = filteredCategories.first {
                selectedCategoryID = first.objectID
            } else {
                selectedCategoryID = nil
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
        // Removed GlassEffectContainer to prevent a row-sized glass background
        // from appearing behind the chips inside Form rows. We retain the
        // horizontal ScrollView and per-chip glass for appearance parity with HomeView.
        chipRowLayout()
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
            if filteredCategories.isEmpty {
                Text("No categories yet")
                    .foregroundStyle(.secondary)
                    .padding(.vertical, 10)
            } else {
                ForEach(filteredCategories, id: \.objectID) { cat in
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
        AddCategoryPill(
            fillsWidth: isAccessibilitySize,
            onTap: {
                // Refresh identity and present
                addCategorySheetInstanceID = UUID()
                isPresentingNewCategory = true
            }
        )
        .padding(.leading, isAccessibilitySize ? 0 : DS.Spacing.s)
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
    @ScaledMetric(relativeTo: .body) private var minHeight: CGFloat = 44

    var body: some View {
        if #available(iOS 26.0, macOS 26.0, macCatalyst 26.0, *) {
            let label = Label("Add", systemImage: "plus")
                .font(.subheadline.weight(.semibold))
                .padding(.horizontal, 12)
                .frame(maxWidth: fillsWidth ? .infinity : nil, minHeight: minHeight, alignment: .center)
                .glassEffect(.regular.tint(.clear).interactive(true))
            Button(action: onTap) {
                label
            }
            .buttonStyle(.plain)
            .frame(maxWidth: fillsWidth ? .infinity : nil, minHeight: minHeight, alignment: .center)
            .clipShape(Capsule())
            .compositingGroup()
            .accessibilityLabel("Add Category")
        } else {
            Button(action: onTap) {
                Label("Add", systemImage: "plus")
                    .font(.subheadline.weight(.semibold))
                    .padding(.horizontal, 12)
                    .frame(maxWidth: fillsWidth ? .infinity : nil, minHeight: minHeight, alignment: .center)
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
            .frame(maxWidth: fillsWidth ? .infinity : nil, minHeight: minHeight, alignment: .center)
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
    @ScaledMetric(relativeTo: .subheadline) private var dotSize: CGFloat = 10
    @ScaledMetric(relativeTo: .body) private var minHeight: CGFloat = 44

    var body: some View {
        let accentColor = UBColorFromHex(colorHex) ?? .secondary
        let glassTintColor = accentColor.opacity(0.25)
        let legacyShape = RoundedRectangle(cornerRadius: 6, style: .continuous)

        let label = HStack(spacing: DS.Spacing.s) {
            Circle()
                .fill(accentColor)
                .frame(width: dotSize, height: dotSize)
            Text(name)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.primary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, 12)
        .frame(minHeight: minHeight, maxHeight: minHeight)

        if #available(iOS 26.0, macOS 26.0, macCatalyst 26.0, *) {
            Button(action: action) {
                label
                    .glassEffect(
                        .regular
                            .tint(isSelected ? glassTintColor : .none)
                            .interactive(true)
                    )
                    .frame(minHeight: minHeight, maxHeight: minHeight)
                    .clipShape(Capsule())
                    .compositingGroup()
            }
            .accessibilityAddTraits(isSelected ? .isSelected : [])
            .accessibilityLabel(name)
            .accessibilityHint("Select category")
            .animation(.easeOut(duration: 0.15), value: isSelected)
            .frame(minHeight: minHeight, maxHeight: minHeight)
            .buttonStyle(.plain)
        } else {
            let neutralFill = DS.Colors.chipFill
            Button(action: action) {
                label
            }
            .accessibilityAddTraits(isSelected ? .isSelected : [])
            .accessibilityLabel(name)
            .accessibilityHint("Select category")
            .animation(.easeOut(duration: 0.15), value: isSelected)
            .frame(minHeight: minHeight, maxHeight: minHeight)
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

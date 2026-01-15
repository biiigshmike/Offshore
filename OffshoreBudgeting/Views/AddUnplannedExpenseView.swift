//
//  AddUnplannedExpenseView.swift
//  SoFar
//
//  Add Variable (Unplanned) Expense
//  -------------------------------------------------------------
//  • Card chooser (horizontal)  ← uses shared CardPickerRow (no local duplicate)
//  • Category chips row (static Add button + live, scrolling chips)
//  • Description, Amount, Date
//  -------------------------------------------------------------?
//

import SwiftUI
import UIKit
import CoreData

// MARK: - AddUnplannedExpenseView
struct AddUnplannedExpenseView: View {

    // MARK: Inputs
    let unplannedExpenseID: NSManagedObjectID?
    let allowedCardIDs: Set<NSManagedObjectID>?
    let initialCardID: NSManagedObjectID?
    let initialDate: Date?
    let onSaved: () -> Void
    let onDismiss: () -> Void
    let wrapsInNavigation: Bool

    // MARK: State
    @StateObject private var vm: AddUnplannedExpenseViewModel
    @EnvironmentObject private var cardPickerStore: CardPickerStore
    @State private var isPresentingAddCard = false
    @State private var didApplyInitialCardSelection = false
    @AppStorage(AppSettingsKeys.activeWorkspaceID.rawValue) private var activeWorkspaceIDRaw: String = ""

    @FetchRequest(
        sortDescriptors: [
            NSSortDescriptor(
                key: "name",
                ascending: true,
                selector: #selector(NSString.localizedCaseInsensitiveCompare(_:))
            )
        ]
    )
    private var expenseCategories: FetchedResults<ExpenseCategory>

    @State private var isPresentingNewCategory = false
    @State private var addCategorySheetInstanceID = UUID()
    
    // MARK: - Layout
    /// Height of the card picker row.  This matches the tile height defined in
    /// `CardPickerRow` so adjustments remain centralized.
    @ScaledMetric(relativeTo: .body) private var cardRowHeight: CGFloat = 160


    // MARK: Init
    init(unplannedExpenseID: NSManagedObjectID? = nil,
         allowedCardIDs: Set<NSManagedObjectID>? = nil,
         initialCardID: NSManagedObjectID? = nil,
         initialDate: Date? = nil,
         onSaved: @escaping () -> Void,
         onDismiss: @escaping () -> Void = {},
         wrapsInNavigation: Bool = true) {
        self.unplannedExpenseID = unplannedExpenseID
        self.allowedCardIDs = allowedCardIDs
        self.initialCardID = initialCardID
        self.initialDate = initialDate
        self.onSaved = onSaved
        self.onDismiss = onDismiss
        self.wrapsInNavigation = wrapsInNavigation

        let model = AddUnplannedExpenseViewModel(
            unplannedExpenseID: unplannedExpenseID,
            allowedCardIDs: allowedCardIDs,
            initialCardID: initialCardID,
            initialDate: initialDate
        )
        _vm = StateObject<AddUnplannedExpenseViewModel>(wrappedValue: model)
    }

    // MARK: Body
    @Environment(\.dismiss) private var dismiss
    @Environment(\.managedObjectContext) private var viewContext

    var body: some View {
        navigationContainer {
            formContent
                .navigationTitle(vm.isEditing ? "Edit Variable Expense" : "Add Variable Expense")
                .ub_windowTitle(vm.isEditing ? "Edit Variable Expense" : "Add Variable Expense")
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
                                if trySave() {
                                    onDismiss()
                                    dismiss()
                                }
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
        }
        .onChange(of: vm.cardsLoaded) { _ in
            applyInitialCardSelectionIfNeeded()
        }
        .onChange(of: vm.allCards) { _ in
            applyInitialCardSelectionIfNeeded()
        }
        // Make sure our chips & sheet share the same context.
        .environment(\.managedObjectContext, CoreDataService.shared.viewContext)
        .sheet(isPresented: $isPresentingAddCard) {
            AddCardFormView { newName, selectedTheme, selectedEffect in
                do {
                    let service = CardService()
                    let card = try service.createCard(name: newName)
                    try service.updateCard(card, name: nil, theme: selectedTheme, effect: selectedEffect)
                    vm.selectedCardID = card.objectID
                } catch {
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

    // MARK: Navigation container
    @ViewBuilder
    private func navigationContainer<Inner: View>(@ViewBuilder content: () -> Inner) -> some View {
        if !wrapsInNavigation {
            content()
        } else if #available(iOS 16.0, macCatalyst 16.0, *) {
            NavigationStack { content() }
        } else {
            NavigationView { content() }
        }
    }

    // MARK: Form content
    @ViewBuilder
    private var formContent: some View {
        Form {
            // MARK: Card Picker (horizontal)
            Section {
                if !vm.cardsLoaded {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                        .frame(minHeight: cardRowHeight)
                } else if vm.allCards.isEmpty {
                    VStack(spacing: Spacing.m) {
                        Text("No cards yet. Add one to assign this expense.")
                            .foregroundStyle(Colors.styleSecondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .frame(minHeight: 44)
                            .fixedSize(horizontal: false, vertical: true)
                        GlassCTAButton(
                            maxWidth: .infinity,
                            height: 44,
                            fillHorizontally: true,
                            fallbackAppearance: .neutral,
                            action: { isPresentingAddCard = true }
                        ) {
                            Label("Add Card", systemImage: Icons.sfPlus)
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
                Text("Assign a Card to Expense")
                    .font(Typography.footnote)
                    .foregroundStyle(Colors.styleSecondary)
            }

            // MARK: Category Chips Row
            Section {
                DesignSystemV2.CategoryChipsRow(
                    items: expenseCategoryChipItems,
                    selectedID: expenseCategorySelectedID,
                    onAddTapped: {
                        addCategorySheetInstanceID = UUID()
                        isPresentingNewCategory = true
                    }
                )
                .listRowInsets(expenseCategoryRowInsets)
                .listRowSeparator(.hidden)
                .ub_preOS26ListRowBackground(.clear)
                .sheet(isPresented: $isPresentingNewCategory) {
                    let base = ExpenseCategoryEditorSheet(
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
                            vm.selectedCategoryID = category.objectID
                        } catch {
                            AppLog.ui.error("Failed to create category: \(error.localizedDescription)")
                        }
                    }
                    .environment(\.managedObjectContext, viewContext)

                    Group {
                        if #available(iOS 16.0, *) {
                            base.presentationDetents([.medium])
                        } else {
                            base
                        }
                    }
                    .id(addCategorySheetInstanceID)
                }
                .onChange(of: expenseCategories.count) { _ in
                    if vm.selectedCategoryID == nil, let first = filteredExpenseCategories.first {
                        vm.selectedCategoryID = first.objectID
                    }
                }
                .onChange(of: activeWorkspaceIDRaw) { _ in
                    if let first = filteredExpenseCategories.first {
                        vm.selectedCategoryID = first.objectID
                    } else {
                        vm.selectedCategoryID = nil
                    }
                }
                .accessibilityElement(children: .contain)
            } header: {
                Text("Category")
                    .font(Typography.footnote)
                    .foregroundStyle(Colors.styleSecondary)
            }
//            .ub_formSectionClearBackground()


            // MARK: Individual Fields
            // Give each field its own section with a header so that the
            // descriptive label appears outside the cell, mirroring the
            // appearance of the Add Card form.  Also left‑align text for
            // improved readability on macOS and avoid right‑aligned text.

            // Expense Description
            Section {
                HStack(alignment: .center) {
                    if #available(iOS 15.0, macCatalyst 15.0, *) {
                        TextField("", text: $vm.descriptionText, prompt: Text("Apple Store"))
                            .autocorrectionDisabled(true)
                            .textInputAutocapitalization(.never)
                            .multilineTextAlignment(.leading)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .accessibilityLabel("Expense Description")
                    } else {
                        TextField("Apple Store", text: $vm.descriptionText)
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
                    .font(Typography.footnote)
                    .foregroundStyle(Colors.styleSecondary)
            }

            // Amount
            Section {
                HStack(alignment: .center) {
                    if #available(iOS 15.0, macCatalyst 15.0, *) {
                        TextField("", text: $vm.amountString, prompt: Text("299.99"))
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.leading)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .accessibilityLabel("Amount")
                    } else {
                        TextField("299.99", text: $vm.amountString)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.leading)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .accessibilityLabel("Amount")
                    }
                    Spacer(minLength: 0)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            } header: {
                Text("Amount")
                    .font(Typography.footnote)
                    .foregroundStyle(Colors.styleSecondary)
            }

            // Transaction Date
            Section {
                DatePicker("", selection: $vm.transactionDate, displayedComponents: [.date])
                    .labelsHidden()
                    .datePickerStyle(.compact)
                    .accessibilityLabel("Transaction Date")
            } header: {
                Text("Transaction Date")
                    .font(Typography.footnote)
                    .foregroundStyle(Colors.styleSecondary)
            }
        }
        .listStyle(.insetGrouped)
        .scrollIndicators(.hidden)
    }

    // MARK: - trySave()
    /// Validates and persists the expense via the view model.
    /// - Returns: `true` if the sheet should dismiss; `false` to stay open.
    private func trySave() -> Bool {
        guard vm.canSave else { return false }
        do {
            try vm.save()
            onSaved()
            // Resign keyboard on iOS via unified helper
            ub_dismissKeyboard()
            return true
        } catch {
            // Present error via UIKit alert on iOS; macOS simply returns false.
            let alert = UIAlertController(title: "Couldn’t Save", message: error.localizedDescription, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            UIApplication.shared.connectedScenes
                .compactMap { ($0 as? UIWindowScene)?.keyWindow }
                .first?
                .rootViewController?
                .present(alert, animated: true)
            return false
        }
    }

    /// Clears key entry fields while keeping selections to quickly add another expense.
    private func resetFormForNewEntry() {
        vm.descriptionText = ""
        vm.amountString = ""
        // Keep selected card, category, and date.
    }

    // MARK: - Category Chips (DSv2)
    private var filteredExpenseCategories: [ExpenseCategory] {
        guard let workspaceID = UUID(uuidString: activeWorkspaceIDRaw) else { return Array(expenseCategories) }
        return expenseCategories.filter { category in
            (category.value(forKey: "workspaceID") as? UUID) == workspaceID
        }
    }

    private var expenseCategoryIDToObjectID: [String: NSManagedObjectID] {
        Dictionary(
            uniqueKeysWithValues: filteredExpenseCategories.map { category in
                (category.objectID.uriRepresentation().absoluteString, category.objectID)
            }
        )
    }

    private var expenseCategorySelectedID: Binding<String?> {
        Binding<String?>(
            get: { vm.selectedCategoryID?.uriRepresentation().absoluteString },
            set: { newValue in
                guard let newValue else {
                    vm.selectedCategoryID = nil
                    return
                }
                if let mapped = expenseCategoryIDToObjectID[newValue] {
                    vm.selectedCategoryID = mapped
                } else {
                    vm.selectedCategoryID = nil
                }
            }
        )
    }

    private var expenseCategoryChipItems: [DesignSystemV2.CategoryChipItem] {
        filteredExpenseCategories.map { category in
            let id = category.objectID.uriRepresentation().absoluteString
            let title = category.name ?? "Untitled"
            let colorHex = category.color ?? "#999999"
            let color = UBColorFromHex(colorHex) ?? .secondary
            return DesignSystemV2.CategoryChipItem(id: id, title: title, color: color)
        }
    }

    private var expenseCategoryRowInsets: EdgeInsets {
        let verticalInset: CGFloat = Spacing.s + Spacing.xs
        return EdgeInsets(
            top: verticalInset,
            leading: Spacing.l,
            bottom: verticalInset,
            trailing: Spacing.l
        )
    }
}

private extension AddUnplannedExpenseView {
    func applyInitialCardSelectionIfNeeded() {
        guard !didApplyInitialCardSelection, let initialCardID else { return }
        vm.selectedCardID = initialCardID
        didApplyInitialCardSelection = true
    }
    /// Saves without notifying the parent via `onSaved` so the sheet stays open.
    /// Returns true on success, false on failure or if validation fails.
    func saveAndStayOpen() -> Bool {
        guard vm.canSave else { return false }
        do {
            try vm.save()
            // Intentionally do not call onSaved() to avoid dismissing the sheet.
            return true
        } catch {
            let alert = UIAlertController(title: "Couldn’t Save", message: error.localizedDescription, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            UIApplication.shared.connectedScenes
                .compactMap { ($0 as? UIWindowScene)?.keyWindow }
                .first?
                .rootViewController?
                .present(alert, animated: true)
            return false
        }
    }
}

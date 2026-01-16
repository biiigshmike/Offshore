//
//  ExpenseImportView.swift
//  SoFar
//
//  Review and import CSV expenses into a card.
//

import SwiftUI
import CoreData

// MARK: - ExpenseImportView
struct ExpenseImportView: View {

    // MARK: Inputs
    private let onComplete: () -> Void

    // MARK: State
    @StateObject private var viewModel: ExpenseImportViewModel
    @State private var editMode: EditMode = .inactive
    @State private var selectedIDs: Set<UUID> = []
    @State private var didApplyDefaultSelection = false
    @State private var isPresentingAddCategory = false
    @State private var isPresentingAssignCategory = false
    @State private var isShowingMissingCategoryAlert = false
    @State private var importError: ImportError?
    @State private var lastKnownSelection: Set<UUID> = []
    @State private var isReadyExpanded = true
    @State private var isPossibleExpanded = true
    @State private var isDuplicatesExpanded = true
    @State private var isNeedsExpanded = true
    @State private var isPaymentsExpanded = true
    @State private var isCreditsExpanded = true
    @ScaledMetric private var categoryDotSize: CGFloat = 10

    @Environment(\.dismiss) private var dismiss

    // MARK: Init
    init(card: CardItem, fileURL: URL, onComplete: @escaping () -> Void) {
        self.onComplete = onComplete
        _viewModel = StateObject(wrappedValue: ExpenseImportViewModel(card: card, fileURL: fileURL))
    }

    // MARK: Body
    var body: some View {
        navigationContainer {
            content
                .navigationTitle("Import Expenses")
                .ub_windowTitle("Import Expenses")
                .toolbar { toolbarContent }
        }
        .environment(\.editMode, $editMode)
        .applyDetentsIfAvailable(detents: [.large], selection: nil)
        .task { await viewModel.load() }
        .onChange(of: viewModel.rows) { _ in
            pruneSelections()
            applyDefaultSelectionIfNeeded()
        }
        .onChange(of: editMode) { mode in
            if mode == .active, selectedIDs.isEmpty, !lastKnownSelection.isEmpty {
                selectedIDs = lastKnownSelection
            }
        }
        .onChange(of: viewModel.state) { _ in
            applyDefaultSelectionIfNeeded()
        }
        .sheet(isPresented: $isPresentingAddCategory) {
            ExpenseCategoryEditorSheet(
                initialName: "",
                initialHex: "#4E9CFF",
                onCancel: { isPresentingAddCategory = false },
                onSave: { name, hex in
                    viewModel.addCategory(name: name, hex: hex)
                    isPresentingAddCategory = false
                }
            )
        }
        .sheet(isPresented: $isPresentingAssignCategory) {
            CategoryPickerSheet(
                categories: viewModel.categories,
                onPick: { category in
                    viewModel.assignCategoryToAllSelected(ids: selectedIDs, categoryID: category.objectID)
                    isPresentingAssignCategory = false
                }
            )
        }
        .alert("Missing Categories", isPresented: $isShowingMissingCategoryAlert) {
            Button("Go Back", role: .cancel) {}
            Button("Assign to All") { isPresentingAssignCategory = true }
        } message: {
            Text("Some selected expenses are missing a category. Assign one category to all selected expenses or go back to review.")
        }
        .alert(item: $importError) { error in
            Alert(
                title: Text("Import Failed"),
                message: Text(error.message),
                dismissButton: .cancel(Text("OK"))
            )
        }
        .accessibilityIdentifier(AccessibilityID.ExpenseImport.screen)
    }

    // MARK: Content
    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
	        case .idle, .loading:
	            ProgressView()
	                .frame(maxWidth: .infinity, maxHeight: .infinity)
	        case .failed(let message):
	            VStack(spacing: Spacing.m) {
	                Image(systemName: "exclamationmark.triangle")
	                    .font(.system(size: 40, weight: .bold))
	                Text("Couldn’t load CSV")
	                    .font(.headline)
	                Text(message)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding()
        case .loaded:
            listContent
        }
    }

    private var listContent: some View {
        List {
	            if !viewModel.readyRowIDs.isEmpty {
	                Section(header: sectionHeader(title: "Ready for Import", isExpanded: $isReadyExpanded, accessibilityID: AccessibilityID.ExpenseImport.Section.readyForImportHeader)) {
	                    if isReadyExpanded {
	                        ForEach(viewModel.readyRowIDs, id: \.self) { id in
	                            if let binding = binding(for: id) {
	                                importRowView(binding, isSelectable: viewModel.selectableRowIDs.contains(id))
	                            }
                        }
                    }
                }
            }

	            if !viewModel.possibleMatchRowIDs.isEmpty {
	                Section(header: sectionHeader(title: "Possible Matches", isExpanded: $isPossibleExpanded, accessibilityID: AccessibilityID.ExpenseImport.Section.possibleMatchesHeader)) {
	                    if isPossibleExpanded {
	                        ForEach(viewModel.possibleMatchRowIDs, id: \.self) { id in
	                            if let binding = binding(for: id) {
	                                importRowView(binding, isSelectable: viewModel.selectableRowIDs.contains(id))
	                            }
                        }
                    }
                }
            }

	            if !viewModel.possibleDuplicateRowIDs.isEmpty {
	                Section(header: sectionHeader(title: "Possible Duplicates", isExpanded: $isDuplicatesExpanded, accessibilityID: AccessibilityID.ExpenseImport.Section.possibleDuplicatesHeader)) {
	                    if isDuplicatesExpanded {
	                        ForEach(viewModel.possibleDuplicateRowIDs, id: \.self) { id in
	                            if let binding = binding(for: id) {
	                                importRowView(binding, isSelectable: viewModel.selectableRowIDs.contains(id))
	                            }
                        }
                    }
                }
            }

	            if !viewModel.missingDataRowIDs.isEmpty {
	                Section(header: sectionHeader(title: "Needs More Data", isExpanded: $isNeedsExpanded, accessibilityID: AccessibilityID.ExpenseImport.Section.needsMoreDataHeader)) {
	                    if isNeedsExpanded {
	                        ForEach(viewModel.missingDataRowIDs, id: \.self) { id in
	                            if let binding = binding(for: id) {
	                                importRowView(binding, isSelectable: viewModel.selectableRowIDs.contains(id))
	                            }
                        }
                    }
                }
            }

	            if !viewModel.paymentRowIDs.isEmpty {
	                Section(header: sectionHeader(title: "Payments", isExpanded: $isPaymentsExpanded, accessibilityID: AccessibilityID.ExpenseImport.Section.paymentsHeader)) {
	                    if isPaymentsExpanded {
	                        ForEach(viewModel.paymentRowIDs, id: \.self) { id in
	                            if let binding = binding(for: id) {
	                                importRowView(binding, isSelectable: viewModel.selectableRowIDs.contains(id))
	                            }
                        }
                    }
                }
            }

	            if !viewModel.creditRowIDs.isEmpty {
	                Section(header: sectionHeader(title: "Credits", isExpanded: $isCreditsExpanded, accessibilityID: AccessibilityID.ExpenseImport.Section.creditsHeader)) {
	                    if isCreditsExpanded {
	                        ForEach(viewModel.creditRowIDs, id: \.self) { id in
	                            if let binding = binding(for: id) {
	                                importRowView(binding, isSelectable: viewModel.selectableRowIDs.contains(id))
	                            }
                        }
                    }
                }
            }
	        }
	        .listStyle(.insetGrouped)
	        .accessibilityIdentifier(AccessibilityID.ExpenseImport.list)
	    }

    @ViewBuilder
    private func importRowView(_ row: Binding<ExpenseImportViewModel.ImportRow>, isSelectable: Bool) -> some View {
        let selectedCategoryName = viewModel.categoryName(for: row.wrappedValue.selectedCategoryID)
	        let selectedCategoryHex = viewModel.categoryHex(for: row.wrappedValue.selectedCategoryID)
	        let isSelected = selectedIDs.contains(row.wrappedValue.id)
	
	        HStack(alignment: .top, spacing: Spacing.m) {
	            if editMode == .active {
	                Button(action: { toggleSelection(for: row.wrappedValue.id, isSelectable: isSelectable) }) {
		                    Image(systemName: isSelected ? Icons.sfCheckmarkCircleFill : "circle")
	                        .font(.system(size: 18, weight: .semibold))
	                        .foregroundStyle(isSelected ? Color.accentColor : (isSelectable ? Color.secondary : Color.secondary.opacity(0.4)))
	                }
	                .buttonStyle(.plain)
	                .accessibilityLabel(isSelected ? "Selected" : (isSelectable ? "Not selected" : "Selection unavailable"))
	                .padding(.top, Spacing.xxs)
	                .disabled(!isSelectable)
	            } else if isSelected, isSelectable {
		                Image(systemName: Icons.sfCheckmarkCircleFill)
	                    .font(.system(size: 18, weight: .semibold))
	                    .foregroundStyle(Color.accentColor)
	                    .accessibilityLabel("Selected")
	                    .padding(.top, Spacing.xxs)
	            }
	
	            VStack(alignment: .leading, spacing: Spacing.s) {
	                badgeRow(for: row)
	                TextField("Expense Description", text: row.descriptionText)
	                    .autocorrectionDisabled(true)
	                    .textInputAutocapitalization(.never)
                    .accessibilityLabel("Expense Description")

                    if !row.wrappedValue.originalDescriptionText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        Text("Original: \(row.wrappedValue.originalDescriptionText)")
                            .font(Typography.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                            .accessibilityLabel("Original description")
                    }

                TextField("Amount", text: row.amountText)
                    .keyboardType(.decimalPad)
                    .accessibilityLabel("Amount")

                DatePicker("Transaction Date", selection: bindingDate(for: row), displayedComponents: [.date])
                    .datePickerStyle(.compact)
                    .accessibilityLabel("Transaction Date")

                Menu {
                    ForEach(viewModel.categories, id: \.objectID) { category in
                        Button(category.name ?? "Untitled") {
                            row.selectedCategoryID.wrappedValue = category.objectID
                            row.matchQuality.wrappedValue = .none
                        }
                    }
                    Button("Clear Category", role: .destructive) {
                        row.selectedCategoryID.wrappedValue = nil
                        row.matchQuality.wrappedValue = .none
                    }
	            } label: {
	                menuLabel(
	                    content: HStack(spacing: Spacing.s) {
	                        Circle()
	                            .fill(UBColorFromHex(selectedCategoryHex) ?? .secondary)
	                            .frame(width: categoryDotSize, height: categoryDotSize)
	                        Text(selectedCategoryName)
	                            .font(.subheadline)
		                        Image(systemName: Icons.sfChevronDown)
	                            .font(Typography.captionSemibold)
	                            .foregroundStyle(.secondary)
	                    }
	                )
            }
            .accessibilityLabel("Category")
            .accessibilityIdentifier(AccessibilityID.ExpenseImport.rowCategoryMenu(id: row.wrappedValue.id))
            .ub_menuButtonStyle()

                if !row.wrappedValue.categoryNameFromCSV.isEmpty {
                    Text("CSV Category: \(row.wrappedValue.categoryNameFromCSV)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Toggle("Use this name next time", isOn: row.useNameNextTime)
                    .accessibilityLabel("Use this name next time")

                Toggle("Save as Preset Planned Expense?", isOn: row.isPreset)
                    .accessibilityLabel("Save as Preset Planned Expense")

            }
        }
        .padding(.vertical, 4)
        .listRowBackground(isSelected ? Colors.secondaryOpacity008 : Color.clear)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier(AccessibilityID.ExpenseImport.row(id: row.wrappedValue.id))
    }

    // MARK: Toolbar
    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .cancellationAction) {
            Button("Cancel") {
                if editMode == .active {
                    cancelSelection()
                } else {
                    dismiss()
                }
            }
            .accessibilityLabel(editMode == .active ? "Cancel Selection" : "Cancel Import")
            .accessibilityIdentifier(AccessibilityID.ExpenseImport.cancelButton)
        }

        ToolbarItem(placement: .primaryAction) {
            Button(action: { isPresentingAddCategory = true }) {
                Image(systemName: "plus")
            }
            .accessibilityLabel("Add Category")
            .accessibilityIdentifier(AccessibilityID.ExpenseImport.addCategoryButton)
        }

        ToolbarItemGroup(placement: .bottomBar) {
            if editMode == .inactive {
                Button("Select") {
                    lastKnownSelection = selectedIDs
                    editMode = .active
                }
                    .accessibilityLabel("Select Expenses")
                    .accessibilityIdentifier(AccessibilityID.ExpenseImport.selectButton)
            } else {
                Button("Select All") { selectAllEligible() }
                    .accessibilityLabel("Select All Expenses")
                    .accessibilityIdentifier(AccessibilityID.ExpenseImport.selectAllButton)
                Button("Deselect All") { selectedIDs.removeAll() }
                    .accessibilityLabel("Deselect All Expenses")
                    .accessibilityIdentifier(AccessibilityID.ExpenseImport.deselectAllButton)
            }
            Button("Import") { importSelected() }
                .disabled(selectedIDs.isEmpty)
                .accessibilityLabel("Import Selected Expenses")
                .accessibilityIdentifier(AccessibilityID.ExpenseImport.importButton)
        }
    }

    // MARK: Helpers
    private func importSelected() {
        let validSelection = selectedIDs.intersection(viewModel.selectableRowIDs)
        guard !validSelection.isEmpty else { return }

        if viewModel.hasMissingCategory(in: validSelection) {
            isShowingMissingCategoryAlert = true
            return
        }

        do {
            try viewModel.importRows(with: validSelection)
            onComplete()
            dismiss()
        } catch {
            importError = ImportError(message: error.localizedDescription)
        }
    }

    private func selectAllEligible() {
        selectedIDs = viewModel.selectableRowIDs
    }

    private func pruneSelections() {
        let pruned = selectedIDs.intersection(viewModel.selectableRowIDs)
        guard pruned != selectedIDs else { return }
        selectedIDs = pruned
    }

    private func applyDefaultSelectionIfNeeded() {
        guard !didApplyDefaultSelection else { return }
        guard case .loaded = viewModel.state else { return }
        selectedIDs = viewModel.defaultSelectedIDs
        didApplyDefaultSelection = true
    }

    private func cancelSelection() {
        selectedIDs.removeAll()
        editMode = .inactive
    }

	    private func sectionHeader(title: String, isExpanded: Binding<Bool>, accessibilityID: String) -> some View {
	        Button(action: { isExpanded.wrappedValue.toggle() }) {
	            HStack {
	                Text(title)
                Spacer()
	                Image(systemName: "chevron.right")
	                    .rotationEffect(.degrees(isExpanded.wrappedValue ? 90 : 0))
	                    .font(Typography.captionSemibold)
	                    .foregroundStyle(.secondary)
	            }
	        }
	        .buttonStyle(.plain)
        .accessibilityLabel(isExpanded.wrappedValue ? "Collapse \(title)" : "Expand \(title)")
        .accessibilityIdentifier(accessibilityID)
    }

	    private func badgeRow(for row: Binding<ExpenseImportViewModel.ImportRow>) -> some View {
	        HStack(spacing: Spacing.s) {
	            Menu {
	                Button("Variable") { row.isPreset.wrappedValue = false }
	                Button("Preset") { row.isPreset.wrappedValue = true }
	            } label: {
                menuBadge(text: row.wrappedValue.isPreset ? "Preset" : "Variable")
            }
            .accessibilityLabel("Expense Type")
            .ub_menuButtonStyle()

            Menu {
                Button("Debit") { row.importKind.wrappedValue = .debit }
                Button("Credit") { row.importKind.wrappedValue = .credit }
                Button("Payment") { row.importKind.wrappedValue = .payment }
            } label: {
                menuBadge(text: kindLabel(for: row.wrappedValue.importKind))
            }
            .accessibilityLabel("Transaction Type")
            .ub_menuButtonStyle()

            if row.wrappedValue.isPossibleDuplicate {
                staticBadge(text: "Duplicate", accessibilityLabel: "Possible duplicate")
            }
        }
        .accessibilityElement(children: .contain)
    }

	    private func menuBadge(text: String) -> some View {
	        menuLabel(
	            content: HStack(spacing: Spacing.xs) {
	                Text(text)
	                    .font(Typography.captionSemibold)
		                Image(systemName: Icons.sfChevronDown)
	                    .font(Typography.captionSemibold)
	                    .foregroundStyle(.secondary)
	            }
	        )
	        .accessibilityLabel(text)
    }

	    private func staticBadge(text: String, accessibilityLabel: String) -> some View {
	        menuLabel(
	            content: Text(text)
	                .font(Typography.captionSemibold)
	        )
	        .accessibilityLabel(accessibilityLabel)
	    }

    private func kindLabel(for kind: ExpenseImportViewModel.ImportKind) -> String {
        switch kind {
        case .debit: return "Debit"
        case .credit: return "Credit"
        case .payment: return "Payment"
        }
    }

    @ViewBuilder
	    private func menuLabel<Content: View>(content: Content) -> some View {
	        if #available(iOS 26.0, macCatalyst 26.0, macOS 26.0, *) {
	            content
	                .padding(.horizontal, Spacing.sPlus)
	                .padding(.vertical, Spacing.xs)
	                .glassEffect(.regular.tint(.clear).interactive(true))
	                .clipShape(Capsule())
	                .contentShape(Capsule())
	        } else {
	            content
	                .padding(.horizontal, Spacing.sPlus)
	                .padding(.vertical, Spacing.xs)
	                .background(
	                    RoundedRectangle(cornerRadius: 8, style: .continuous)
		                        .fill(Colors.secondaryOpacity008)
	                )
                .overlay(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
                )
                .contentShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
    }

    private func toggleSelection(for id: UUID, isSelectable: Bool) {
        guard editMode == .active, isSelectable else { return }
        if selectedIDs.contains(id) {
            selectedIDs.remove(id)
        } else {
            selectedIDs.insert(id)
        }
    }

    private func binding(for id: UUID) -> Binding<ExpenseImportViewModel.ImportRow>? {
        guard let index = viewModel.rows.firstIndex(where: { $0.id == id }) else { return nil }
        return $viewModel.rows[index]
    }

    private func bindingDate(for row: Binding<ExpenseImportViewModel.ImportRow>) -> Binding<Date> {
        Binding<Date>(
            get: { row.wrappedValue.transactionDate ?? Date() },
            set: { row.transactionDate.wrappedValue = $0 }
        )
    }

    @ViewBuilder
    private func navigationContainer<Inner: View>(@ViewBuilder content: () -> Inner) -> some View {
        if #available(iOS 16.0, macCatalyst 16.0, *) {
            NavigationStack { content() }
        } else {
            NavigationView { content() }
        }
    }
}

// MARK: - CategoryPickerSheet
private struct CategoryPickerSheet: View {
    let categories: [ExpenseCategory]
    let onPick: (ExpenseCategory) -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Group {
                if categories.isEmpty {
                    Text("No categories yet. Add one to continue.")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                        .padding()
                } else {
                    List(categories, id: \.objectID) { category in
                        Button(category.name ?? "Untitled") {
                            onPick(category)
                            dismiss()
                        }
                        .accessibilityLabel("Select \(category.name ?? "category")")
                    }
                }
            }
            .navigationTitle("Assign Category")
            .ub_windowTitle("Assign Category")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
        .applyDetentsIfAvailable(detents: [.medium, .large], selection: nil)
    }
}

// MARK: - Selection Disabled Compat
private extension View {
    @ViewBuilder
    func applySelectionDisabledIfAvailable(_ disabled: Bool) -> some View {
        if #available(iOS 17.0, macCatalyst 17.0, *) {
            selectionDisabled(disabled)
        } else {
            self
        }
    }
}

// MARK: - ImportError
private struct ImportError: Identifiable {
    let id = UUID()
    let message: String
}

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
        .onChange(of: selectedIDs) { _ in
            pruneSelections()
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
    }

    // MARK: Content
    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .idle, .loading:
            ProgressView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        case .failed(let message):
            VStack(spacing: 12) {
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
                Section(header: sectionHeader(title: "Ready for Import", isExpanded: $isReadyExpanded)) {
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
                Section(header: sectionHeader(title: "Possible Matches", isExpanded: $isPossibleExpanded)) {
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
                Section(header: sectionHeader(title: "Possible Duplicates", isExpanded: $isDuplicatesExpanded)) {
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
                Section(header: sectionHeader(title: "Needs More Data", isExpanded: $isNeedsExpanded)) {
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
                Section(header: sectionHeader(title: "Payments", isExpanded: $isPaymentsExpanded)) {
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
                Section(header: sectionHeader(title: "Credits", isExpanded: $isCreditsExpanded)) {
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
    }

    @ViewBuilder
    private func importRowView(_ row: Binding<ExpenseImportViewModel.ImportRow>, isSelectable: Bool) -> some View {
        let selectedCategoryName = viewModel.categoryName(for: row.wrappedValue.selectedCategoryID)
        let selectedCategoryHex = viewModel.categoryHex(for: row.wrappedValue.selectedCategoryID)
        let isSelected = selectedIDs.contains(row.wrappedValue.id)

        HStack(alignment: .top, spacing: 12) {
            if editMode == .active {
                Button(action: { toggleSelection(for: row.wrappedValue.id, isSelectable: isSelectable) }) {
                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(isSelected ? Color.accentColor : (isSelectable ? Color.secondary : Color.secondary.opacity(0.4)))
                }
                .buttonStyle(.plain)
                .accessibilityLabel(isSelected ? "Selected" : (isSelectable ? "Not selected" : "Selection unavailable"))
                .padding(.top, 4)
                .disabled(!isSelectable)
            } else if isSelected, isSelectable {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(Color.accentColor)
                    .accessibilityLabel("Selected")
                    .padding(.top, 4)
            }

            VStack(alignment: .leading, spacing: 8) {
                badgeRow(for: row)
                TextField("Expense Description", text: row.descriptionText)
                    .autocorrectionDisabled(true)
                    .textInputAutocapitalization(.never)
                    .accessibilityLabel("Expense Description")

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
                    content: HStack(spacing: 8) {
                        Circle()
                            .fill(UBColorFromHex(selectedCategoryHex) ?? .secondary)
                            .frame(width: categoryDotSize, height: categoryDotSize)
                        Text(selectedCategoryName)
                            .font(.subheadline)
                        Image(systemName: "chevron.down")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                    }
                )
            }
            .accessibilityLabel("Category")
            .ub_menuButtonStyle()

                if !row.wrappedValue.categoryNameFromCSV.isEmpty {
                    Text("CSV Category: \(row.wrappedValue.categoryNameFromCSV)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Toggle("Save as Preset Planned Expense?", isOn: row.isPreset)
                    .accessibilityLabel("Save as Preset Planned Expense")

            }
        }
        .padding(.vertical, 4)
        .listRowBackground(isSelected ? Color.secondary.opacity(0.08) : Color.clear)
        .accessibilityElement(children: .contain)
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
        }

        ToolbarItem(placement: .primaryAction) {
            Button(action: { isPresentingAddCategory = true }) {
                Image(systemName: "plus")
            }
            .accessibilityLabel("Add Category")
        }

        ToolbarItemGroup(placement: .bottomBar) {
            if editMode == .inactive {
                Button("Select") {
                    lastKnownSelection = selectedIDs
                    editMode = .active
                }
                    .accessibilityLabel("Select Expenses")
            } else {
                Button("Select All") { selectAllEligible() }
                    .accessibilityLabel("Select All Expenses")
                Button("Deselect All") { selectedIDs.removeAll() }
                    .accessibilityLabel("Deselect All Expenses")
            }
            Button("Import") { importSelected() }
                .disabled(selectedIDs.isEmpty)
                .accessibilityLabel("Import Selected Expenses")
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
        selectedIDs = selectedIDs.intersection(viewModel.selectableRowIDs)
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

    private func sectionHeader(title: String, isExpanded: Binding<Bool>) -> some View {
        Button(action: { isExpanded.wrappedValue.toggle() }) {
            HStack {
                Text(title)
                Spacer()
                Image(systemName: "chevron.right")
                    .rotationEffect(.degrees(isExpanded.wrappedValue ? 90 : 0))
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(isExpanded.wrappedValue ? "Collapse \(title)" : "Expand \(title)")
    }

    private func badgeRow(for row: Binding<ExpenseImportViewModel.ImportRow>) -> some View {
        HStack(spacing: 8) {
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
            content: HStack(spacing: 6) {
                Text(text)
                    .font(.caption.weight(.semibold))
                Image(systemName: "chevron.down")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
        )
        .accessibilityLabel(text)
    }

    private func staticBadge(text: String, accessibilityLabel: String) -> some View {
        menuLabel(
            content: Text(text)
                .font(.caption.weight(.semibold))
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
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .glassEffect(.regular.tint(.clear).interactive(true))
                .clipShape(Capsule())
                .contentShape(Capsule())
        } else {
            content
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(Color.secondary.opacity(0.08))
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

// MARK: - Menu Button Style
private extension View {
    @ViewBuilder
    func ub_menuButtonStyle() -> some View {
        if #available(iOS 16.0, macCatalyst 16.0, *) {
            self
                .buttonStyle(.plain)
                .buttonBorderShape(.capsule)
        } else {
            self
                .buttonStyle(.plain)
        }
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

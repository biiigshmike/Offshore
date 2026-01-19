//
//  ExpenseImportView.swift
//  SoFar
//
//  Review and import CSV expenses into a card.
//

import SwiftUI
import CoreData
#if os(iOS) || targetEnvironment(macCatalyst)
import UIKit
#endif

// MARK: - ExpenseImportView
struct ExpenseImportView: View {

    // MARK: Inputs
    private let onComplete: () -> Void

    // MARK: State
    @StateObject private var viewModel: ExpenseImportViewModel
    @State private var isSelectingOverride = false
    @State private var selectedIDs: Set<UUID> = []
    @State private var didApplyDefaultSelection = false
    @State private var isPresentingAddCategory = false
    @State private var isPresentingAssignCategory = false
    @State private var isShowingMissingCategoryAlert = false
    @State private var importError: ImportError?
    @State private var isReadyExpanded = true
    @State private var isPossibleExpanded = false
    @State private var isDuplicatesExpanded = false
    @State private var isNeedsExpanded = false
    @State private var isPaymentsExpanded = false
    @State private var isCreditsExpanded = false
    @State private var cachedSelectableRowIDs: Set<UUID> = []
    @State private var rowIndexByID: [UUID: Int] = [:]
    @State private var pendingPruneTask: Task<Void, Never>?
    @State private var lastLoggedSelectedIDs: Set<UUID> = []
    @FocusState private var isKeyboardFocused: Bool
    @ScaledMetric private var categoryDotSize: CGFloat = 10
    @ScaledMetric(relativeTo: .body) private var selectionIndicatorSize: CGFloat = 20
    @ScaledMetric(relativeTo: .body) private var selectionIndicatorStroke: CGFloat = 2

    @Environment(\.dismiss) private var dismiss

    private var isSelecting: Bool {
        isSelectingOverride
    }

    // MARK: Init
    init(card: CardItem, fileURL: URL, onComplete: @escaping () -> Void) {
        self.onComplete = onComplete
        _viewModel = StateObject(wrappedValue: ExpenseImportViewModel(card: card, fileURL: fileURL))
    }

    // MARK: Body
    var body: some View {
        navigationContainer {
            content
                .ub_perfRenderScope("ExpenseImportView.body")
                .ub_perfRenderCounter("ExpenseImportView", every: 10)
                .navigationTitle("Import Expenses")
                .ub_windowTitle("Import Expenses")
                .toolbar { toolbarContent }
                .safeAreaInset(edge: .bottom) {
                    if case .loaded = viewModel.state {
                        bottomActionBar
                    }
                }
        }
        .task { await UBPerf.measureAsync("ExpenseImportViewModel.load") { await viewModel.load() } }
        .onAppear { UBPerf.mark("ExpenseImportView.onAppear") }
        .onDisappear {
            pendingPruneTask?.cancel()
            pendingPruneTask = nil
            UBPerf.mark("ExpenseImportView.onDisappear")
        }
        .onChange(of: viewModel.rows) { _ in
            applyDefaultSelectionIfNeeded()
            if UBPerfExperiments.importStabilizeList {
                rowIndexByID = Dictionary(uniqueKeysWithValues: viewModel.rows.indices.map { idx in
                    (viewModel.rows[idx].id, idx)
                })
                cachedSelectableRowIDs = viewModel.selectableRowIDs
            }
            schedulePruneSelectionsIfNeeded()
        }
        .onChange(of: selectedIDs) { newValue in
            guard UBPerf.isEnabled else { return }
            let added = newValue.subtracting(lastLoggedSelectedIDs)
            let removed = lastLoggedSelectedIDs.subtracting(newValue)
            let addedPrefix = added.prefix(3).map { String($0.uuidString.prefix(8)) }.joined(separator: ",")
            let removedPrefix = removed.prefix(3).map { String($0.uuidString.prefix(8)) }.joined(separator: ",")
            let line = "ExpenseImportView.selectedIDs count=\(newValue.count) isSelecting=\(self.isSelecting) added=\(added.count) removed=\(removed.count) addedPrefix=[\(addedPrefix)] removedPrefix=[\(removedPrefix)]"
            UBPerf.logger.info("\(line, privacy: .public)")
            UBPerf.emit(line)
            lastLoggedSelectedIDs = newValue
        }
        .onChange(of: viewModel.state) { _ in
            applyDefaultSelectionIfNeeded()
        }
        .onChange(of: isSelectingOverride) { newValue in
            guard UBPerf.isEnabled else { return }
            let line = "ExpenseImportView.isSelectingOverride \(newValue ? "ON" : "OFF") selected=\(selectedIDs.count)"
            UBPerf.logger.info("\(line, privacy: .public)")
            UBPerf.emit(line)
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

    private func performSelectionSetUpdate(_ update: () -> Void) {
        var transaction = Transaction()
        transaction.animation = nil
        transaction.disablesAnimations = true

#if os(iOS) || targetEnvironment(macCatalyst)
        UIView.performWithoutAnimation {
            withTransaction(transaction) { update() }
        }
#else
        withTransaction(transaction) { update() }
#endif
    }

    @ViewBuilder
    private var listContent: some View {
        let selectableIDs = UBPerfExperiments.importStabilizeList ? cachedSelectableRowIDs : viewModel.selectableRowIDs
        ScrollView(.vertical) {
            LazyVStack(alignment: .leading, spacing: Spacing.m) {
                importSections(selectableIDs: selectableIDs)
            }
            .padding(.horizontal, Spacing.l)
            .padding(.vertical, Spacing.s)
        }
#if os(iOS) || targetEnvironment(macCatalyst)
        .scrollDismissesKeyboard(.interactively)
#endif
        .transaction { t in
            guard UBPerfExperiments.importDisableAnimations else { return }
            t.animation = nil
            t.disablesAnimations = true
        }
        .accessibilityIdentifier(AccessibilityID.ExpenseImport.list)
    }

    @ViewBuilder
    private func importSections(selectableIDs: Set<UUID>) -> some View {
        if !viewModel.possibleDuplicateRowIDs.isEmpty {
            Section(header: sectionHeader(title: "Possible Duplicates", isExpanded: $isDuplicatesExpanded, accessibilityID: AccessibilityID.ExpenseImport.Section.possibleDuplicatesHeader)) {
                if isDuplicatesExpanded {
                    VStack(spacing: Spacing.s) {
                        ForEach(viewModel.possibleDuplicateRowIDs, id: \.self) { id in
                            if let binding = binding(for: id) {
                                importRowView(binding, isSelectable: selectableIDs.contains(id))
                            }
                        }
                    }
                    .padding(.top, Spacing.xs)
                }
            }
        }

        if !viewModel.missingDataRowIDs.isEmpty {
            Section(header: sectionHeader(title: "Needs More Data", isExpanded: $isNeedsExpanded, accessibilityID: AccessibilityID.ExpenseImport.Section.needsMoreDataHeader)) {
                if isNeedsExpanded {
                    VStack(spacing: Spacing.s) {
                        ForEach(viewModel.missingDataRowIDs, id: \.self) { id in
                            if let binding = binding(for: id) {
                                importRowView(binding, isSelectable: selectableIDs.contains(id))
                            }
                        }
                    }
                    .padding(.top, Spacing.xs)
                }
            }
        }

        if !viewModel.paymentRowIDs.isEmpty {
            Section(header: sectionHeader(title: "Payments", isExpanded: $isPaymentsExpanded, accessibilityID: AccessibilityID.ExpenseImport.Section.paymentsHeader)) {
                if isPaymentsExpanded {
                    VStack(spacing: Spacing.s) {
                        ForEach(viewModel.paymentRowIDs, id: \.self) { id in
                            if let binding = binding(for: id) {
                                importRowView(binding, isSelectable: selectableIDs.contains(id))
                            }
                        }
                    }
                    .padding(.top, Spacing.xs)
                }
            }
        }

        if !viewModel.creditRowIDs.isEmpty {
            Section(header: sectionHeader(title: "Credits", isExpanded: $isCreditsExpanded, accessibilityID: AccessibilityID.ExpenseImport.Section.creditsHeader)) {
                if isCreditsExpanded {
                    VStack(spacing: Spacing.s) {
                        ForEach(viewModel.creditRowIDs, id: \.self) { id in
                            if let binding = binding(for: id) {
                                importRowView(binding, isSelectable: selectableIDs.contains(id))
                            }
                        }
                    }
                    .padding(.top, Spacing.xs)
                }
            }
        }

        if !viewModel.possibleMatchRowIDs.isEmpty {
            Section(header: sectionHeader(title: "Possible Matches", isExpanded: $isPossibleExpanded, accessibilityID: AccessibilityID.ExpenseImport.Section.possibleMatchesHeader)) {
                if isPossibleExpanded {
                    VStack(spacing: Spacing.s) {
                        ForEach(viewModel.possibleMatchRowIDs, id: \.self) { id in
                            if let binding = binding(for: id) {
                                importRowView(binding, isSelectable: selectableIDs.contains(id))
                            }
                        }
                    }
                    .padding(.top, Spacing.xs)
                }
            }
        }

        if !viewModel.readyRowIDs.isEmpty {
            Section(header: sectionHeader(title: "Ready for Import", isExpanded: $isReadyExpanded, accessibilityID: AccessibilityID.ExpenseImport.Section.readyForImportHeader)) {
                if isReadyExpanded {
                    VStack(spacing: Spacing.s) {
                        ForEach(viewModel.readyRowIDs, id: \.self) { id in
                            if let binding = binding(for: id) {
                                importRowView(binding, isSelectable: selectableIDs.contains(id))
                            }
                        }
                    }
                    .padding(.top, Spacing.xs)
                }
            }
        }
    }

    @ViewBuilder
    private func importRowView(_ row: Binding<ExpenseImportViewModel.ImportRow>, isSelectable: Bool) -> some View {
        let selectedCategoryName = viewModel.categoryName(for: row.wrappedValue.selectedCategoryID)
		        let selectedCategoryHex = viewModel.categoryHex(for: row.wrappedValue.selectedCategoryID)
		        let isSelected = selectedIDs.contains(row.wrappedValue.id)
	
        let canToggleSelection: Bool = {
            guard isSelecting else { return false }
            if isSelected { return true }
            return isSelectable
        }()

        let inner = rowCard(isSelected: isSelected) {
            HStack(alignment: .top, spacing: Spacing.m) {
                selectionIndicator(isSelected: isSelected, isSelectable: isSelectable)
                    .padding(.top, Spacing.xxs)

                Group {
                    if isSelecting {
                        selectModeRowContent(
                            row: row.wrappedValue,
                            isSelectable: isSelectable,
                            selectedCategoryName: selectedCategoryName,
                            selectedCategoryHex: selectedCategoryHex
                        )
                    } else {
                        editableRowContent(
                            row: row,
                            selectedCategoryName: selectedCategoryName,
                            selectedCategoryHex: selectedCategoryHex
                        )
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .accessibilityIdentifier(AccessibilityID.ExpenseImport.row(id: row.wrappedValue.id))

        if isSelecting {
            Button(action: { toggleSelection(for: row.wrappedValue.id, isSelectable: isSelectable) }) {
                inner
            }
            .buttonStyle(UBNoHighlightButtonStyle())
            .disabled(!canToggleSelection)
            .accessibilityLabel(isSelected ? "Selected" : (isSelectable ? "Not selected" : "Selection unavailable"))
        } else {
            inner
        }
    }

    private func editableRowContent(
        row: Binding<ExpenseImportViewModel.ImportRow>,
        selectedCategoryName: String,
        selectedCategoryHex: String?
    ) -> some View {
        VStack(alignment: .leading, spacing: Spacing.s) {
            badgeRow(for: row)

            Picker("Import As", selection: row.importAs) {
                Text("Expense").tag(ExpenseImportViewModel.ImportAs.expense)
                Text("Income").tag(ExpenseImportViewModel.ImportAs.income)
            }
            .pickerStyle(.segmented)
            .tint(Colors.actualIncome)
            .accessibilityLabel("Import As")

            TextField("Expense Description", text: row.descriptionText)
                .autocorrectionDisabled(true)
                .textInputAutocapitalization(.never)
                .focused($isKeyboardFocused)
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
                .focused($isKeyboardFocused)
                .accessibilityLabel("Amount")

            DatePicker("Transaction Date", selection: bindingDate(for: row), displayedComponents: [.date])
                .datePickerStyle(.compact)
                .accessibilityLabel("Transaction Date")

            if row.wrappedValue.importAs == .expense {
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
            }

            if !row.wrappedValue.categoryNameFromCSV.isEmpty {
                Text("CSV Category: \(row.wrappedValue.categoryNameFromCSV)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Toggle("Use this name next time", isOn: row.useNameNextTime)
                .accessibilityLabel("Use this name next time")

            if row.wrappedValue.importAs == .expense {
                Toggle("Save as Preset Planned Expense?", isOn: row.isPreset)
                    .accessibilityLabel("Save as Preset Planned Expense")
            }
        }
    }

    private func selectModeRowContent(
        row: ExpenseImportViewModel.ImportRow,
        isSelectable: Bool,
        selectedCategoryName: String,
        selectedCategoryHex: String?
    ) -> some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            selectionModeMetaLine(row: row, isSelectable: isSelectable)

            Text(row.descriptionText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Untitled" : row.descriptionText)
                .font(.body.weight(.semibold))
                .lineLimit(2)
                .accessibilityLabel("Description")

            HStack(spacing: Spacing.m) {
                if let date = row.transactionDate {
                    Text(date, style: .date)
                } else {
                    Text("No date")
                }

                Spacer(minLength: 0)

                Text(row.amountText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "—" : row.amountText)
                    .monospacedDigit()
            }
            .font(.caption)
            .foregroundStyle(.secondary)
            .accessibilityLabel("Date and amount")

            if row.importAs == .expense {
                HStack(spacing: Spacing.s) {
                    Circle()
                        .fill(UBColorFromHex(selectedCategoryHex) ?? .secondary)
                        .frame(width: categoryDotSize, height: categoryDotSize)
                    Text(selectedCategoryName)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                .accessibilityLabel("Category")
            }
        }
    }

    private func selectionModeMetaLine(row: ExpenseImportViewModel.ImportRow, isSelectable: Bool) -> some View {
        let pieces: [String] = [
            row.isPreset ? "Preset" : "Variable",
            kindLabel(for: row.importKind),
            row.importAs == .expense ? "Expense" : "Income",
            row.isPossibleDuplicate ? "Duplicate" : nil,
            isSelectable ? nil : "Needs Info",
        ].compactMap { $0 }

        return Text(pieces.joined(separator: " • "))
            .font(Typography.captionSemibold)
            .foregroundStyle(.secondary)
            .lineLimit(1)
            .accessibilityLabel("Row details")
    }

    private func toggleSelection(for id: UUID, isSelectable: Bool) {
        let isSelected = selectedIDs.contains(id)
        if !isSelected, !isSelectable { return }

        performSelectionSetUpdate {
            if isSelected {
                selectedIDs.remove(id)
            } else {
                selectedIDs.insert(id)
            }
        }
    }

    private func selectionIndicator(isSelected: Bool, isSelectable: Bool) -> some View {
        // Force a stable, explicit tint for the selection affordance.
        // Using `.accentColor`/environment tint can appear to “flip” between the app tint and
        // the system default during heavy UI churn, which reads as flicker.
        let tint = Colors.actualIncome
        let strokeOpacity = isSelectable ? 0.35 : 0.18

        return ZStack {
            if isSelected {
                Circle()
                    .fill(tint)
                Image(systemName: Icons.sfCheckmark)
                    .font(.system(size: selectionIndicatorSize * 0.55, weight: .bold))
                    .symbolRenderingMode(.monochrome)
                    .foregroundStyle(.white)
            } else {
                Circle()
                    .strokeBorder(tint.opacity(strokeOpacity), lineWidth: selectionIndicatorStroke)
            }
        }
        .frame(width: selectionIndicatorSize, height: selectionIndicatorSize)
        .frame(width: 22, alignment: .leading)
        .opacity(isSelecting ? 1 : 0)
        .transaction { t in
            t.animation = nil
            t.disablesAnimations = true
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    private func rowCard<Content: View>(isSelected: Bool, @ViewBuilder content: () -> Content) -> some View {
        content()
            .padding(.horizontal, Spacing.l)
            .padding(.vertical, Spacing.m)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: Radius.card, style: .continuous)
                    .fill(isSelected ? Colors.secondaryOpacity012 : Colors.containerBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: Radius.card, style: .continuous)
                    .strokeBorder(Color.secondary.opacity(0.18), lineWidth: 1)
            )
    }

    // MARK: Toolbar
    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .cancellationAction) {
            Button("Cancel") {
                if isSelecting {
                    cancelSelection()
                } else {
                    dismiss()
                }
            }
            .accessibilityLabel(isSelecting ? "Cancel Selection" : "Cancel Import")
            .accessibilityIdentifier(AccessibilityID.ExpenseImport.cancelButton)
        }

        ToolbarItem(placement: .primaryAction) {
            Button(action: { isPresentingAddCategory = true }) {
                Image(systemName: "plus")
            }
            .accessibilityLabel("Add Category")
            .accessibilityIdentifier(AccessibilityID.ExpenseImport.addCategoryButton)
        }

#if os(iOS) || targetEnvironment(macCatalyst)
        if isKeyboardFocused {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") { isKeyboardFocused = false }
                    .accessibilityLabel("Dismiss keyboard")
            }
        }
#endif
    }

    private var bottomActionBar: some View {
        HStack(spacing: Spacing.m) {
            if !isSelecting {
                Button("Select") { enterSelectionMode() }
                    .accessibilityLabel("Select Expenses")
                    .accessibilityIdentifier(AccessibilityID.ExpenseImport.selectButton)
            } else {
                Button("Select All") { selectAllEligible() }
                    .accessibilityLabel("Select All Expenses")
                    .accessibilityIdentifier(AccessibilityID.ExpenseImport.selectAllButton)
                Button("Deselect All") {
                    performSelectionSetUpdate { selectedIDs.removeAll() }
                }
                .accessibilityLabel("Deselect All Expenses")
                .accessibilityIdentifier(AccessibilityID.ExpenseImport.deselectAllButton)
            }

            Spacer(minLength: 0)

            Button("Import") { importSelected() }
                .buttonStyle(.borderedProminent)
                .disabled(selectedIDs.isEmpty)
                .accessibilityLabel("Import Selected Expenses")
                .accessibilityIdentifier(AccessibilityID.ExpenseImport.importButton)
        }
        .padding(.horizontal, Spacing.l)
        .padding(.top, Spacing.s)
        .padding(.bottom, Spacing.sPlus)
        .background(.ultraThinMaterial)
        .overlay(alignment: .top) {
            Divider()
        }
    }

    // MARK: Helpers
    private func importSelected() {
        let validSelection = selectedIDs.intersection(currentSelectableRowIDs())
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
        performSelectionSetUpdate {
            selectedIDs = currentSelectableRowIDs()
        }
    }

    private func schedulePruneSelectionsIfNeeded() {
        // Avoid mutating selection during active list selection mode.
        // The system manages selection visuals and frequent selection set changes can look like flicker.
        if isSelecting {
            UBPerf.tick("ExpenseImportView.pruneSelections.skippedSelecting", every: 10)
            return
        }
        let selectable = currentSelectableRowIDs()
        if UBPerfExperiments.importDebounceSelectionPrune {
            pendingPruneTask?.cancel()
            let delayMs = UBPerfExperiments.importDebounceSelectionPruneDelayMs
            pendingPruneTask = Task { @MainActor in
                if delayMs > 0 {
                    try? await Task.sleep(nanoseconds: UInt64(delayMs) * 1_000_000)
                }
                pruneSelections(selectableRowIDs: currentSelectableRowIDs())
            }
        } else {
            pruneSelections(selectableRowIDs: selectable)
        }
    }

    private func pruneSelections(selectableRowIDs: Set<UUID>) {
        guard !isSelecting else { return }
        UBPerf.tick("ExpenseImportView.pruneSelections", every: 10)
        let pruned = selectedIDs.intersection(selectableRowIDs)
        guard pruned != selectedIDs else { return }
        if UBPerf.isEnabled {
            let removed = selectedIDs.subtracting(pruned).count
            let line = "ExpenseImportView.pruneSelections removed=\(removed) selected=\(selectedIDs.count)->\(pruned.count)"
            UBPerf.logger.info("\(line, privacy: .public)")
            UBPerf.emit(line)
        }
        performSelectionSetUpdate {
            selectedIDs = pruned
        }
    }

    private func currentSelectableRowIDs() -> Set<UUID> {
        if UBPerfExperiments.importStabilizeList {
            return cachedSelectableRowIDs
        }
        return viewModel.selectableRowIDs
    }

    private func applyDefaultSelectionIfNeeded() {
        guard !didApplyDefaultSelection else { return }
        guard case .loaded = viewModel.state else { return }
        let selectable = currentSelectableRowIDs()
        if UBPerf.isEnabled {
            let line = "ExpenseImportView.applyDefaultSelection ids=\(viewModel.defaultSelectedIDs.count)"
            UBPerf.logger.info("\(line, privacy: .public)")
            UBPerf.emit(line)
        }
        performSelectionSetUpdate {
            selectedIDs = viewModel.defaultSelectedIDs.intersection(selectable)
        }
        didApplyDefaultSelection = true
    }

    private func cancelSelection() {
        if UBPerf.isEnabled {
            UBPerf.mark("ExpenseImportView.cancelSelection", "selected=\(selectedIDs.count)")
        }
        performSelectionSetUpdate { selectedIDs.removeAll() }
        setSelecting(false)
    }

    private func enterSelectionMode() {
        if UBPerf.isEnabled {
            UBPerf.mark("ExpenseImportView.enterSelectionMode", "selected=\(selectedIDs.count)")
        }
        setSelecting(true)
    }

    private func setSelecting(_ newValue: Bool) {
        if newValue {
            pendingPruneTask?.cancel()
            pendingPruneTask = nil
        }
        var transaction = Transaction()
        transaction.animation = nil
        transaction.disablesAnimations = true
#if os(iOS) || targetEnvironment(macCatalyst)
        UIView.performWithoutAnimation {
            withTransaction(transaction) { isSelectingOverride = newValue }
        }
#else
        withTransaction(transaction) { isSelectingOverride = newValue }
#endif
    }

	    private func sectionHeader(title: String, isExpanded: Binding<Bool>, accessibilityID: String) -> some View {
	        Button(action: { isExpanded.wrappedValue.toggle() }) {
                rowCard(isSelected: false) {
                    HStack {
                        Text(title)
                            .font(Typography.subheadlineSemibold)
                        Spacer()
                        Image(systemName: Icons.sfChevronRight)
                            .rotationEffect(.degrees(isExpanded.wrappedValue ? 90 : 0))
                            .font(Typography.captionSemibold)
                            .foregroundStyle(.secondary)
                    }
                }
	        }
	        .buttonStyle(UBNoHighlightButtonStyle())
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

    private func binding(for id: UUID) -> Binding<ExpenseImportViewModel.ImportRow>? {
        if UBPerfExperiments.importStabilizeList,
           let index = rowIndexByID[id],
           viewModel.rows.indices.contains(index),
           viewModel.rows[index].id == id {
            return $viewModel.rows[index]
        }

        guard let fallback = viewModel.rows.firstIndex(where: { $0.id == id }) else { return nil }
        return $viewModel.rows[fallback]
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

// MARK: - Button Styles
private struct UBNoHighlightButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
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

// MARK: - ImportError
private struct ImportError: Identifiable {
    let id = UUID()
    let message: String
}

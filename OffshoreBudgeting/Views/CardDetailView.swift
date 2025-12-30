//  CardDetailView.swift
//  SoFar
//
//  Wallet-style detail for a selected Card.
//  - Top bar: Done + Search, Edit
//  - iOS/macOS safe toolbar & searchable usage
//

import SwiftUI
import CoreData

// MARK: - CardDetailView
struct CardDetailView: View {
    // MARK: Inputs
    let card: CardItem
    @Binding var isPresentingAddExpense: Bool
    var onDone: () -> Void

    // MARK: State
    @State private var cardSnapshot: CardItem
    @State private var isPresentingEditCard: Bool = false
    @StateObject private var viewModel: CardDetailViewModel
    @Environment(\.responsiveLayoutContext) private var layoutContext
    @EnvironmentObject private var themeManager: ThemeManager
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @AppStorage(AppSettingsKeys.confirmBeforeDelete.rawValue)
    private var confirmBeforeDelete: Bool = true
    @State private var isSearchActive: Bool = false
    @FocusState private var isSearchFieldFocused: Bool
    // Add flows
    @State private var isPresentingAddPlanned: Bool = false
    @State private var expensePendingDeletion: CardExpense?
    @State private var isConfirmingDelete: Bool = false
    @State private var deletionError: DeletionError?
    @State private var editingExpense: CardExpense?
    @State private var isMenuActive = false
    @State private var budgetDetailCommands: BudgetDetailCommands?
    // Date range pickers
    @State private var startDate: Date = Date()
    @State private var endDate: Date = Date()

    // Guided walkthrough state removed
    // No longer tracking header offset via state; the header is rendered
    // outside of the scroll view and does not need to drive layout of the
    // underlying content.
    // @State private var headerOffset: CGFloat = 0

    private let initialHeaderTopPadding: CGFloat = 16
    
    // MARK: Init
    init(card: CardItem,
         isPresentingAddExpense: Binding<Bool>,
         onDone: @escaping () -> Void) {
        self.card = card
        self._isPresentingAddExpense = isPresentingAddExpense
        self.onDone = onDone
        _cardSnapshot = State(initialValue: card)
        _viewModel = StateObject(wrappedValue: CardDetailViewModel(card: card))
    }
    
    // MARK: Body
    var body: some View {
        navigationContent
        .ub_navigationBackground(
            theme: themeManager.selectedTheme,
            configuration: themeManager.glassConfiguration
        )
        .task { await viewModel.load() }
        //.accentColor(themeManager.selectedTheme.tint)
        //.tint(themeManager.selectedTheme.tint)
        .sheet(isPresented: $isPresentingEditCard) {
            AddCardFormView(
                mode: .edit,
                editingCard: cardSnapshot
            ) { name, theme in
                handleCardEdit(name: name, theme: theme)
            }
        }
        // Add Variable (Unplanned) Expense sheet for this card
        .sheet(isPresented: $isPresentingAddExpense) {
            AddUnplannedExpenseView(
                initialCardID: cardSnapshot.objectID ?? card.objectID,
                initialDate: Date(),
                onSaved: {
                    isPresentingAddExpense = false
                    refreshCardDetails()
                }
            )
        }
        // Add Planned Expense sheet for this card
        .sheet(isPresented: $isPresentingAddPlanned) {
            AddPlannedExpenseView(
                preselectedBudgetID: nil,
                defaultSaveAsGlobalPreset: false,
                showAssignBudgetToggle: true,
                onSaved: {
                    isPresentingAddPlanned = false
                    refreshCardDetails()
                },
                initialCardID: cardSnapshot.objectID ?? card.objectID
            )
            .environment(\.managedObjectContext, CoreDataService.shared.viewContext)
        }
        .sheet(item: $editingExpense) { expense in
            if expense.isPlanned {
                AddPlannedExpenseView(
                    plannedExpenseID: expense.objectID,
                    preselectedBudgetID: nil,
                    defaultSaveAsGlobalPreset: false,
                    showAssignBudgetToggle: true,
                    onSaved: {
                        refreshCardDetails()
                    },
                    initialCardID: cardSnapshot.objectID ?? card.objectID
                )
                .environment(\.managedObjectContext, CoreDataService.shared.viewContext)
            } else {
                AddUnplannedExpenseView(
                    unplannedExpenseID: expense.objectID,
                    initialCardID: cardSnapshot.objectID ?? card.objectID,
                    initialDate: expense.date,
                    onSaved: {
                        refreshCardDetails()
                    }
                )
                .environment(\.managedObjectContext, CoreDataService.shared.viewContext)
            }
        }
        .alert("Delete Expense?", isPresented: $isConfirmingDelete) {
            Button("Delete", role: .destructive) {
                if let expense = expensePendingDeletion {
                    performDelete(expense)
                }
            }
            Button("Cancel", role: .cancel) { expensePendingDeletion = nil }
        } message: {
            Text("This will remove the expense from the card.")
        }
        .alert(item: $deletionError) { error in
            Alert(
                title: Text("Couldn't Delete Expense"),
                message: Text(error.message),
                dismissButton: .cancel(Text("OK"))
            )
        }
        .ub_surfaceBackground(
            themeManager.selectedTheme,
            configuration: themeManager.glassConfiguration,
            ignoringSafeArea: .all
        )
        .tipsAndHintsOverlay(for: .cardDetail)
        .focusedSceneValue(
            \.budgetDetailCommands,
            isMenuActive ? budgetDetailCommands : nil
        )
        

    }

    // MARK: content
    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .initial, .loading:
            ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity)
        case .error(let message):
            VStack(spacing: 12) {
                Image(systemName: "exclamationmark.triangle")
                    .font(.system(size: 40, weight: .bold))
                Text("Couldn’t load details")
                    .font(.headline)
                Text(message).font(.subheadline).foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding()
        case .empty:
            let cardMaxWidth = resolvedCardMaxWidth(in: layoutContext)
            detailsList(cardMaxWidth: cardMaxWidth)
        case .loaded:
            let cardMaxWidth = resolvedCardMaxWidth(in: layoutContext)
            detailsList(cardMaxWidth: cardMaxWidth)
    }
    }

    @ViewBuilder
    private func detailsList(cardMaxWidth: CGFloat?) -> some View {
        List {
            Section {
                CardTileView(card: cardSnapshot, enableMotionShine: true)
                    .frame(maxWidth: cardMaxWidth)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.top, initialHeaderTopPadding)
                    .padding(.bottom, 12)
            }

            // Date Range + Presets
            Section {
                let rowMaxWidth = cardMaxWidth ?? resolvedDateRowMaxWidth(in: layoutContext)
                HStack(spacing: 10) {
                    HStack(spacing: 8) {
                        DatePicker("Start", selection: $startDate, displayedComponents: .date)
                            .labelsHidden()
                        DatePicker("End", selection: $endDate, displayedComponents: .date)
                            .labelsHidden()
                    }
                    Spacer(minLength: 0)
                    HStack(spacing: 8) {
                        // Go button: liquid glass circular on OS 26, rounded rect legacy
                        goButton
                        // Calendar menu: liquid glass circular on OS 26, plain legacy
                        calendarMenu
                    }
                }
                .frame(maxWidth: rowMaxWidth)
                .frame(maxWidth: .infinity, alignment: .center)
            }

            Section {
                let row = VStack(alignment: .leading, spacing: 8) {
                    Text(viewModel.filteredTotal, format: .currency(code: currencyCode))
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, 8)

                if let colors = totalSpentHeatmapColors {
                    row.listRowBackground(totalSpentHeatmapBackground(colors: colors))
                } else {
                    row
                }
            } header: {
                Text("TOTAL SPENT")
                    .font(.subheadline.weight(.semibold))
                    .textCase(nil)
            }

            // Category Chips (horizontal)
            Section {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(viewModel.filteredCategories) { cat in
                            categoryChip(cat)
                        }
                        if viewModel.filteredCategories.isEmpty {
                            Text("No categories yet")
                                .foregroundStyle(.secondary)
                                .padding(.vertical, 8)
                        }
                    }
                    .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
                }
                .frame(height: 44)
            }

            // Segment Picker
            Section {
                Picker("", selection: $viewModel.segment) {
                    Text("Planned").tag(CardDetailViewModel.Segment.planned)
                    Text("Variable").tag(CardDetailViewModel.Segment.variable)
                    Text("Unified").tag(CardDetailViewModel.Segment.all)
                }
                .pickerStyle(.segmented)
            }

            // Sort Bar
            Section {
                Picker("Sort", selection: $viewModel.sort) {
                    Text("A–Z").tag(CardDetailViewModel.Sort.titleAZ)
                    Text("$↓").tag(CardDetailViewModel.Sort.amountLowHigh)
                    Text("$↑").tag(CardDetailViewModel.Sort.amountHighLow)
                    Text("Date ↑").tag(CardDetailViewModel.Sort.dateOldNew)
                    Text("Date ↓").tag(CardDetailViewModel.Sort.dateNewOld)
                }
                .pickerStyle(.segmented)
            }

            Section {
                let expenses = viewModel.filteredExpenses
                let trimmedSearch = viewModel.searchText.trimmingCharacters(in: .whitespacesAndNewlines)
                let swipeConfig = UnifiedSwipeConfig(allowsFullSwipeToDelete: !confirmBeforeDelete)
                if expenses.isEmpty {
                    let emptyMessage = trimmedSearch.isEmpty
                        ? "No expenses yet for this date range."
                        : "No results for “\(trimmedSearch)”"
                    Text(emptyMessage)
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical, DesignSystem.Spacing.l)
                } else {
                    ForEach(expenses) { expense in
                        ExpenseRow(expense: expense, currencyCode: currencyCode)
//                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
//                                Button(role: .destructive) {
//                                    requestDelete(expense)
//                                } label: {
//                                    Label("Delete", systemImage: "trash")
//                                }
//                                .tint(.red)
//                                Button {
//                                    editingExpense = expense
//                                } label: {
//                                    Label("Edit", systemImage: "pencil")
//                                }
//                                .tint(.gray)
//                            }
                            .unifiedSwipeActions(
                                swipeConfig,
                                onEdit: { editingExpense = expense },
                                onDelete: { requestDelete(expense) }
                            )
                    }
                    .onDelete(perform: handleDelete)
                }
            } header: {
                Text("EXPENSES")
                    .font(.subheadline.weight(.semibold))
                    .textCase(nil)
            }

            // UPCOMING section removed per request
        }
        .listStyle(.insetGrouped)
    }

    private func refreshCardDetails() {
        Task { await viewModel.load() }
    }

    private func handleCardEdit(name: String, theme: CardTheme) {
        let service = CardService()

        do {
            var managedCard: Card?

            if let objectID = cardSnapshot.objectID,
               let existingCard = try? viewContext.existingObject(with: objectID) as? Card {
                managedCard = existingCard
            } else if let uuid = cardSnapshot.uuid {
                managedCard = try service.findCard(byID: uuid)
            }

            if let managedCard {
                // Persist name and theme to Core Data
                try service.updateCard(managedCard, name: name, theme: theme)
                cardSnapshot.name = name
                cardSnapshot.theme = theme
                refreshCardDetails()
            }
        } catch {
            if viewContext.hasChanges { viewContext.rollback() }
        }
    }

    private func requestDelete(_ expense: CardExpense) {
        if confirmBeforeDelete {
            expensePendingDeletion = expense
            isConfirmingDelete = true
        } else {
            performDelete(expense)
        }
    }

    private func handleDelete(_ offsets: IndexSet) {
        let expenses = viewModel.filteredExpenses
        let targets = offsets.compactMap { index in
            expenses.indices.contains(index) ? expenses[index] : nil
        }
        guard !targets.isEmpty else { return }

        if confirmBeforeDelete, let first = targets.first {
            expensePendingDeletion = first
            isConfirmingDelete = true
        } else {
            targets.forEach { performDelete($0) }
        }
    }

    private func performDelete(_ expense: CardExpense) {
        Task { @MainActor in
            expensePendingDeletion = nil
            isConfirmingDelete = false

            do {
                try await viewModel.delete(expense: expense)
                await viewModel.load()
            } catch {
                if viewContext.hasChanges { viewContext.rollback() }
                deletionError = DeletionError(message: error.localizedDescription)
            }
        }
    }

    private var currencyCode: String {
        if #available(iOS 16.0, macCatalyst 16.0, *) {
            return Locale.current.currency?.identifier ?? "USD"
        } else {
            return Locale.current.currencyCode ?? "USD"
        }
    }

    // Apply a preset and refresh
    private func setPreset(_ period: BudgetPeriod) {
        let r = period.range(containing: Date())
        startDate = r.start
        endDate = r.end
        viewModel.setDateRange(r.start, r.end)
        Task { await viewModel.load() }
    }

    private var navigationContent: some View {
        content
            .navigationTitle(cardSnapshot.name)
        #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
        #endif
            .toolbar { toolbarContent }
            .task {
                // Initialize local start/end from the model's allowed interval
                if let interval = viewModel.allowedInterval {
                    startDate = interval.start
                    endDate = interval.end
                } else {
                    let p = WorkspaceService.shared.currentBudgetPeriod(in: viewContext)
                    let r = p.range(containing: Date())
                    startDate = r.start
                    endDate = r.end
                }
            }
            .onAppear {
                isMenuActive = true
                if budgetDetailCommands == nil {
                    budgetDetailCommands = BudgetDetailCommands(
                        addPlannedExpense: { isPresentingAddPlanned = true },
                        addVariableExpense: { isPresentingAddExpense = true }
                    )
                }
            }
            .onDisappear { isMenuActive = false }
    }

    // MARK: Toolbar
    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .navigationBarTrailing) {
            searchToolbarControl
        }
        ToolbarItemGroup(placement: .navigationBarTrailing) {
            IconOnlyButton(systemName: "pencil") {
                isPresentingEditCard = true
            }
            // Add Expense menu (Planned or Variable) — rightmost control
            Menu {
                Button("Add Planned Expense") {
                    isPresentingAddPlanned = true
                }
                Button("Add Variable Expense") {
                    isPresentingAddExpense = true
                }
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: 18, weight: .semibold))
                    .symbolRenderingMode(.monochrome)
            }
            .accessibilityLabel("Add Expense")
        }
    }

    // MARK: Toolbar Search
    @ViewBuilder
    private var searchToolbarControl: some View {
        if #available(iOS 26.0, macCatalyst 26.0, macOS 26.0, *) {
            searchToolbarControlGlass
        } else {
            searchToolbarControlLegacy
        }
    }

    @available(iOS 26.0, macCatalyst 26.0, macOS 26.0, *)
    private var searchToolbarControlGlass: some View {
        GlassEffectContainer(spacing: 8) {
            HStack(spacing: 6) {
                if isSearchActive {
                    Buttons.toolbarIcon("xmark") { closeSearch() }
                    glassSearchField
                } else {
                    Buttons.toolbarIcon("magnifyingglass") { openSearch() }
                }
            }
        }
    }

    private var searchToolbarControlLegacy: some View {
        HStack(spacing: 6) {
            if isSearchActive {
                Buttons.toolbarIcon("xmark") { closeSearch() }
                legacySearchField
            } else {
                Buttons.toolbarIcon("magnifyingglass") { openSearch() }
            }
        }
    }

    @available(iOS 26.0, macCatalyst 26.0, macOS 26.0, *)
    private var glassSearchField: some View {
        searchField
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color.secondary.opacity(0.12))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(Color.secondary.opacity(0.18), lineWidth: 0.5)
            )
    }

    private var legacySearchField: some View {
        searchField
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(Color.secondary.opacity(0.12))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(Color.secondary.opacity(0.18), lineWidth: 0.5)
            )
    }

    private var searchField: some View {
        HStack(spacing: 6) {
            TextField("Search expenses", text: $viewModel.searchText)
                .textFieldStyle(.plain)
                .focused($isSearchFieldFocused)
                .frame(minWidth: 140, maxWidth: 220)
            if !viewModel.searchText.isEmpty {
                Button(action: { viewModel.searchText = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Clear Search")
            }
        }
        .accessibilityElement(children: .contain)
    }

    private func openSearch() {
        withAnimation(.spring(response: 0.28, dampingFraction: 0.85)) {
            isSearchActive = true
        }
        isSearchFieldFocused = true
    }

    private func closeSearch() {
        withAnimation(.spring(response: 0.28, dampingFraction: 0.85)) {
            isSearchActive = false
        }
        viewModel.searchText = ""
        isSearchFieldFocused = false
    }

    // MARK: Date Row Controls
    @ViewBuilder
    private var goButton: some View {
        if #available(iOS 26.0, macCatalyst 26.0, macOS 26.0, *) {
            Button(action: applyDateRange) {
                Image(systemName: "arrow.right")
                    .font(.system(size: 16, weight: .semibold))
                    .frame(width: 44, height: 44)
                    .glassEffect(.regular.tint(.clear).interactive(true))
            }
            .buttonStyle(.plain)
            .buttonBorderShape(.circle)
            .tint(.accentColor)
            .accessibilityLabel("Apply date range")
        } else {
            let shape = RoundedRectangle(cornerRadius: 6, style: .continuous)
            Button(action: applyDateRange) {
                Text("Go").font(.subheadline.weight(.semibold))
                    .frame(minWidth: 44)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 8)
                    .background(shape.fill(Color.secondary.opacity(0.12)))
                    .contentShape(shape)
            }
            .buttonStyle(.plain)
            .overlay(shape.stroke(Color.secondary.opacity(0.18), lineWidth: 0.5))
            .accessibilityLabel("Apply date range")
        }
    }

    @ViewBuilder
    private var calendarMenu: some View {
        if #available(iOS 26.0, macCatalyst 26.0, macOS 26.0, *) {
            Menu {
                Button("Daily") { setPreset(.daily) }
                Button("Weekly") { setPreset(.weekly) }
                Button("Monthly") { setPreset(.monthly) }
                Button("Quarterly") { setPreset(.quarterly) }
                Button("Yearly") { setPreset(.yearly) }
            } label: {
                Image(systemName: "calendar")
                    .font(.system(size: 16, weight: .semibold))
                    .frame(width: 44, height: 44)
                    .glassEffect(.regular.tint(.clear).interactive(true))
            }
            .buttonStyle(.plain)
            .buttonBorderShape(.circle)
            .tint(.accentColor)
            .accessibilityLabel("Select date preset")
        } else {
            Menu {
                Button("Daily") { setPreset(.daily) }
                Button("Weekly") { setPreset(.weekly) }
                Button("Monthly") { setPreset(.monthly) }
                Button("Quarterly") { setPreset(.quarterly) }
                Button("Yearly") { setPreset(.yearly) }
            } label: {
                Image(systemName: "calendar")
                    .font(.system(size: 16, weight: .semibold))
                    .frame(width: 33, height: 33)
            }
            .accessibilityLabel("Select date preset")
        }
    }

    private func applyDateRange() {
        if endDate < startDate { endDate = startDate }
        viewModel.setDateRange(startDate, endDate)
        Task { await viewModel.load() }
    }

    
    // MARK: Layout Helpers
    private func resolvedCardMaxWidth(in context: ResponsiveLayoutContext) -> CGFloat? {
        let availableWidth = max(context.containerSize.width - context.safeArea.leading - context.safeArea.trailing, 0)

        switch context.idiom {
        case .phone:
            return nil
        case .pad, .mac, .vision, .car:
            return boundedCardWidth(for: availableWidth, upperBound: 520)
        case .unspecified:
            if context.horizontalSizeClass == .regular {
                return boundedCardWidth(for: availableWidth, upperBound: 480)
            } else {
                return nil
            }
        }
    }

    private func resolvedDateRowMaxWidth(in context: ResponsiveLayoutContext) -> CGFloat? {
        let availableWidth = max(context.containerSize.width - context.safeArea.leading - context.safeArea.trailing, 0)

        switch context.idiom {
        case .phone:
            return nil
        case .pad, .mac, .vision, .car:
            return boundedCardWidth(for: availableWidth, upperBound: 560)
        case .unspecified:
            if context.horizontalSizeClass == .regular {
                return boundedCardWidth(for: availableWidth, upperBound: 520)
            } else {
                return nil
            }
        }
    }

    private func boundedCardWidth(for availableWidth: CGFloat, upperBound: CGFloat) -> CGFloat? {
        guard availableWidth > 0 else { return upperBound }
        return min(availableWidth, upperBound)
    }

    // MARK: Heatmap Helpers (Total Spent)
    private var totalSpentHeatmapColors: [Color]? {
        let rawColors = viewModel.filteredCategories.compactMap { UBColorFromHex($0.colorHex) }
        let limited = Array(rawColors.prefix(12))
        guard !limited.isEmpty else { return nil }
        return softenedHeatmapColors(from: limited)
    }

    @ViewBuilder
    private func totalSpentHeatmapBackground(colors: [Color]) -> some View {
        let blobs = heatmapBlobs(from: colors)
        ZStack {
            Color.primary.opacity(colorScheme == .dark ? 0.06 : 0.02)
            ForEach(blobs) { blob in
                RadialGradient(
                    gradient: Gradient(colors: [blob.color, .clear]),
                    center: blob.center,
                    startRadius: 0,
                    endRadius: blob.radius
                )
                .opacity(blob.opacity)
                .blur(radius: 18)
            }
        }
    }

    private struct HeatmapBlob: Identifiable {
        let id = UUID()
        let color: Color
        let center: UnitPoint
        let radius: CGFloat
        let opacity: Double
    }

    private func heatmapBlobs(from colors: [Color]) -> [HeatmapBlob] {
        let baseColors = colors.prefix(6)
        let centers: [UnitPoint] = [
            .topLeading, .topTrailing, .bottomLeading, .bottomTrailing, .center, .init(x: 0.2, y: 0.7)
        ]
        let radii: [CGFloat] = [180, 200, 160, 190, 220, 170]
        let opacityBase: Double = colorScheme == .dark ? 0.28 : 0.22

        return zip(baseColors, centers).enumerated().map { index, pair in
            let (color, center) = pair
            return HeatmapBlob(
                color: color,
                center: center,
                radius: radii[index % radii.count],
                opacity: opacityBase * (index % 2 == 0 ? 1.0 : 0.85)
            )
        }
    }

    private func softenedHeatmapColors(from colors: [Color]) -> [Color] {
        colors.map(softenHeatmapColor)
    }

    private func softenHeatmapColor(_ color: Color) -> Color {
        #if canImport(UIKit)
        let ui = UIColor(color)
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        if ui.getRed(&r, green: &g, blue: &b, alpha: &a) {
            let mix: CGFloat = 0.30 // blend toward a light neutral to reduce harshness
            let nr = r * (1 - mix) + mix
            let ng = g * (1 - mix) + mix
            let nb = b * (1 - mix) + mix
            let na = a * 0.9
            return Color(red: Double(nr), green: Double(ng), blue: Double(nb), opacity: Double(na))
        }
        #elseif os(macOS)
        if let ns = NSColor(color).usingColorSpace(.sRGB) {
            let r = ns.redComponent, g = ns.greenComponent, b = ns.blueComponent, a = ns.alphaComponent
            let mix: CGFloat = 0.30
            let nr = r * (1 - mix) + mix
            let ng = g * (1 - mix) + mix
            let nb = b * (1 - mix) + mix
            let na = a * 0.9
            return Color(red: Double(nr), green: Double(ng), blue: Double(nb), opacity: Double(na))
        }
        #endif
        return color.opacity(0.85)
    }

    // MARK: Guided Walkthrough Helpers
    // Guided walkthrough removed

    // The sectionOffset helper and associated preference key were removed
    // because the card header is no longer rendered in this view, eliminating
    // the need to adjust the content based on a stored scroll offset.
}

// MARK: - ExpenseRow
private struct ExpenseRow: View {
    let expense: CardExpense
    let currencyCode: String
    private let df: DateFormatter = {
        let d = DateFormatter()
        d.dateStyle = .medium
        return d
    }()
    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 2) {
                Text(expense.description)
                    .font(.body.weight(.medium))
                HStack(spacing: 6) {
                    let catColor = UBColorFromHex(expense.category?.color) ?? .secondary
                    let catName: String = {
                        let raw = expense.category?.name?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
                        return raw.isEmpty ? "Uncategorized" : raw
                    }()
                    Circle()
                        .fill(catColor)
                        .frame(width: 8, height: 8)
                    Text(catName)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    if let date = expense.date {
                        Text("·")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(df.string(from: date))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            Spacer()
            Text(expense.amount, format: .currency(code: currencyCode))
                .font(.body.weight(.semibold)).monospacedDigit()
        }
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Shared Toolbar Icon
private struct IconOnlyButton: View {
    let systemName: String
    var action: () -> Void
    @EnvironmentObject private var themeManager: ThemeManager
    var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 18, weight: .semibold))
                .symbolRenderingMode(.monochrome)
                .foregroundStyle(themeManager.selectedTheme.accent)
                .imageScale(.medium)
                .padding(.horizontal, 2)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text(label))
    }
    private var label: String {
        switch systemName {
        case "magnifyingglass": return "Search"
        case "pencil": return "Edit"
        default: return "Action"
        }
    }
}

private struct DeletionError: Identifiable {
    let id = UUID()
    let message: String
}

// MARK: - Helpers
// Back-deploy listSectionSpacing(…) only on iOS 17+/macCatalyst 17+.
//

// MARK: - Category Chip (CardDetail)
private extension CardDetailView {
    @ViewBuilder
    func categoryChip(_ cat: CardCategoryTotal) -> some View {
        let accentColor = cat.color
        let isSelected = viewModel.selectedCategoryID == cat.categoryObjectID
        let glassTintColor = accentColor.opacity(0.25)
        let legacyShape = RoundedRectangle(cornerRadius: 6, style: .continuous)

        let label = HStack(spacing: DS.Spacing.s) {
            Circle().fill(accentColor).frame(width: 10, height: 10)
            Text(cat.name).font(.subheadline.weight(.medium))
            Text(cat.amount, format: .currency(code: currencyCode)).font(.subheadline.weight(.semibold))
        }
        .padding(.horizontal, 12)
        .frame(minHeight: 44, maxHeight: 44)

        if #available(iOS 26.0, macCatalyst 26.0, macOS 26.0, *) {
            Button(action: {
                if viewModel.selectedCategoryID == cat.categoryObjectID { viewModel.selectedCategoryID = nil }
                else { viewModel.selectedCategoryID = cat.categoryObjectID }
            }) {
                label
                    .glassEffect(
                        .regular
                            .tint(isSelected ? glassTintColor : .none)
                            .interactive(true)
                    )
                    .frame(minHeight: 44, maxHeight: 44)
                    .clipShape(Capsule())
                    .compositingGroup()
            }
            .buttonStyle(.plain)
            .accessibilityAddTraits(isSelected ? .isSelected : [])
            .animation(.easeOut(duration: 0.15), value: isSelected)
            .frame(maxHeight: 44)
        } else {
            Button(action: {
                if viewModel.selectedCategoryID == cat.categoryObjectID { viewModel.selectedCategoryID = nil }
                else { viewModel.selectedCategoryID = cat.categoryObjectID }
            }) {
                label
            }
            .accessibilityAddTraits(isSelected ? .isSelected : [])
            .animation(.easeOut(duration: 0.15), value: isSelected)
            .frame(maxHeight: 33)
            .buttonStyle(.plain)
            .background(
                legacyShape.fill(isSelected ? glassTintColor : DS.Colors.chipFill)
            )
            .overlay(
                legacyShape.stroke(isSelected ? DS.Colors.chipSelectedStroke : DS.Colors.chipFill, lineWidth: 1)
            )
            .contentShape(legacyShape)
        }
    }
}

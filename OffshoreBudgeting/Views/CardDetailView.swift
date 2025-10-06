//
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
    var onEdit: () -> Void

    // MARK: State
    @StateObject private var viewModel: CardDetailViewModel
    @Environment(\.responsiveLayoutContext) private var layoutContext
    @EnvironmentObject private var themeManager: ThemeManager
    @Environment(\.managedObjectContext) private var viewContext
    @AppStorage(AppSettingsKeys.confirmBeforeDelete.rawValue) private var confirmBeforeDelete: Bool = true
    @State private var isSearchActive: Bool = false
    @FocusState private var isSearchFieldFocused: Bool
    // Add flows
    @State private var isPresentingAddPlanned: Bool = false
    @State private var expensePendingDeletion: CardExpense?
    @State private var isConfirmingDelete: Bool = false
    @State private var deletionError: DeletionError?

    // No longer tracking header offset via state; the header is rendered
    // outside of the scroll view and does not need to drive layout of the
    // underlying content.
    // @State private var headerOffset: CGFloat = 0

    private let initialHeaderTopPadding: CGFloat = 16
    private let listRowHorizontalPadding: CGFloat = DesignSystem.Spacing.l
    
    // MARK: Init
    init(card: CardItem,
         isPresentingAddExpense: Binding<Bool>,
         onDone: @escaping () -> Void,
         onEdit: @escaping () -> Void) {
        self.card = card
        self._isPresentingAddExpense = isPresentingAddExpense
        self.onDone = onDone
        self.onEdit = onEdit
        _viewModel = StateObject(wrappedValue: CardDetailViewModel(card: card))
    }
    
    // MARK: Body
    var body: some View {
        navigationContainer
        .ub_navigationBackground(
            theme: themeManager.selectedTheme,
            configuration: themeManager.glassConfiguration
        )
        .task { await viewModel.load() }
        //.accentColor(themeManager.selectedTheme.tint)
        //.tint(themeManager.selectedTheme.tint)
        // Add Variable (Unplanned) Expense sheet for this card
        .sheet(isPresented: $isPresentingAddExpense) {
            AddUnplannedExpenseView(
                initialCardID: card.objectID,
                initialDate: Date(),
                onSaved: {
                    isPresentingAddExpense = false
                    Task { await viewModel.load() }
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
                    Task { await viewModel.load() }
                },
                initialCardID: card.objectID
            )
            .environment(\.managedObjectContext, CoreDataService.shared.viewContext)
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
            VStack(spacing: 12) {
                Image(systemName: "creditcard")
                    .font(.system(size: 44, weight: .regular))
                    .foregroundStyle(.secondary)
                Text("No expenses yet")
                    .font(.title3.weight(.semibold))
                Text("Add an expense to see totals and categories here.")
                    .font(.subheadline).foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            .padding()
        case .loaded(let total, _, _):
            let cardMaxWidth = resolvedCardMaxWidth(in: layoutContext)
            listContent(cardMaxWidth: cardMaxWidth, total: total)
    }
    }

    @ViewBuilder
    private func listContent(cardMaxWidth: CGFloat?, total: Double) -> some View {
        if #available(iOS 16.0, macCatalyst 16.0, *) {
            if #available(iOS 17.0, macCatalyst 17.0, *) {
                baseList(cardMaxWidth: cardMaxWidth, total: total)
                    .scrollContentBackground(.hidden)
                    .listSectionSpacing(20)
            } else {
                baseList(cardMaxWidth: cardMaxWidth, total: total)
                    .scrollContentBackground(.hidden)
            }
        } else {
            baseList(cardMaxWidth: cardMaxWidth, total: total)
        }
    }

    private func baseList(cardMaxWidth: CGFloat?, total: Double) -> some View {
        List {
            // Card header as its own section to ensure consistent rendering
            // with modern List defaults across iOS 16/17.
            Section {
                cardRow(maxWidth: cardMaxWidth)
            }

            // Totals + categories grouped together so they remain visible
            // above the expenses list, regardless of List section spacing.
            Section {
                totalsListRow(total: total)
                categoryListRow(categories: viewModel.filteredCategories)
            }

            // Expenses list (already returns a Section)
            expensesSection
        }
        .ub_listStyleLiquidAware()
        .ub_hideScrollIndicators()
        .cardDetailHideTopListSeparatorIfAvailable()
#if os(iOS)
        // Neutralize UIKit's automatic bottom padding and provide our own
        // spacer so the list always scrolls and doesn't get constrained by
        // the tab bar.
        .background(UBScrollViewInsetAdjustmentDisabler())
#endif
        .cardDetailListBottomInset(layoutContext: layoutContext)
    }

    // MARK: Bottom inset for comfortable/infinite scrolling
    // Mirrors the strategy used in BudgetDetailsView so lists remain scrollable
    // even when content is short, and to keep spacing consistent above the tab bar.
    @ViewBuilder
    private func cardDetailBottomSpacer() -> some View {
        Color.clear.frame(height: CardDetailListBottomInsetMetrics.bottomInset(for: layoutContext))
            .allowsHitTesting(false)
            .accessibilityHidden(true)
    }

    @ViewBuilder
    private func cardRow(maxWidth: CGFloat?) -> some View {
        CardTileView(card: card, enableMotionShine: true)
            .frame(maxWidth: maxWidth)
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.horizontal, listRowHorizontalPadding)
            .padding(.top, initialHeaderTopPadding)
            .padding(.bottom, 12)
            .listRowInsets(.init())
            .listRowBackground(Color.clear)
    }

    @ViewBuilder
    private func totalsListRow(total: Double) -> some View {
        totalsSection(total: total)
            .padding(.horizontal, listRowHorizontalPadding)
            .listRowInsets(.init(top: 0, leading: 0, bottom: 12, trailing: 0))
            .listRowBackground(Color.clear)
    }

    @ViewBuilder
    private func categoryListRow(categories: [CardCategoryTotal]) -> some View {
        categoryBreakdown(categories: categories)
            .padding(.horizontal, listRowHorizontalPadding)
            .listRowInsets(.init(top: 0, leading: 0, bottom: 12, trailing: 0))
            .listRowBackground(Color.clear)
    }

    private var expensesSection: some View {
        Section {
            let expenses = viewModel.filteredExpenses
            if expenses.isEmpty {
                expenseRowContainer(topInset: 0, bottomInset: 24) {
                    Text(viewModel.searchText.isEmpty ? "No expenses found." : "No results for “\(viewModel.searchText)”")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }
            } else {
                ForEach(Array(expenses.enumerated()), id: \.element.id) { pair in
                    let isFirst = pair.offset == 0
                    let isLast = pair.offset == expenses.count - 1
                    expenseRowContainer(
                        topInset: isFirst ? 0 : 4,
                        bottomInset: isLast ? 24 : 12
                    ) {
                        ExpenseRow(expense: pair.element, currencyCode: currencyCode)
                    }
                        .unifiedSwipeActions(
                            UnifiedSwipeConfig(allowsFullSwipeToDelete: false),
                            onEdit: nil,
                            onDelete: { requestDelete(pair.element) }
                        )
                }
                .onDelete { handleDelete($0) }
            }
        } header: {
            Text("EXPENSES")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.leading, 16)
                .padding(.trailing, 16)
                .padding(.top, 12)
                .padding(.bottom, 4)
                .textCase(nil)
        }
    }

    private func expenseRowContainer<Content: View>(
        topInset: CGFloat,
        bottomInset: CGFloat,
        @ViewBuilder content: () -> Content
    ) -> some View {
        content()
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, DesignSystem.Spacing.l)
            .background(rowBackground(color: themeManager.selectedTheme.secondaryBackground))
            .padding(.horizontal, listRowHorizontalPadding)
            .contentShape(Rectangle())
            .listRowInsets(.init(top: topInset, leading: 0, bottom: bottomInset, trailing: 0))
            .listRowBackground(Color.clear)
            .ub_preOS26ListRowBackground(themeManager.selectedTheme.secondaryBackground)
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

    private func rowBackground(color: Color) -> some View {
        RoundedRectangle(cornerRadius: 16, style: .continuous)
            .fill(color)
    }

    private var currencyCode: String {
        if #available(iOS 16.0, macCatalyst 16.0, *) {
            return Locale.current.currency?.identifier ?? "USD"
        } else {
            return Locale.current.currencyCode ?? "USD"
        }
    }

    // MARK: navigationContainer
    @ViewBuilder
    private var navigationContainer: some View {
        if #available(iOS 16.0, macCatalyst 16.0, *) {
            NavigationStack {
                navigationContent
            }
        } else {
            NavigationView {
                navigationContent
            }
        }
    }

    private var navigationContent: some View {
        content
            .navigationTitle(card.name)
        #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
        #endif
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") { onDone() }
                        .keyboardShortcut(.escape, modifiers: [])
                }
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    if isSearchActive {
                        TextField("Search expenses", text: $viewModel.searchText)
                            .textFieldStyle(.roundedBorder)
                            .frame(maxWidth: 200)
                            .focused($isSearchFieldFocused)
                        Button("Cancel") {
                            withAnimation {
                                isSearchActive = false
                                viewModel.searchText = ""
                                isSearchFieldFocused = false
                            }
                        }
                    } else {
                        IconOnlyButton(systemName: "magnifyingglass") {
                            withAnimation { isSearchActive = true }
                            isSearchFieldFocused = true
                        }
                        IconOnlyButton(systemName: "pencil") {
                            onEdit()
                        }
                        // Add Expense menu (Planned or Variable) — keep as the rightmost control
                        Menu {
                            Button("Add Planned Expense") { isPresentingAddPlanned = true }
                            Button("Add Variable Expense") { isPresentingAddExpense = true }
                        } label: {
                            RootHeaderControlIcon(systemImage: "plus")
                        }
                        .modifier(HideMenuIndicatorIfPossible())
                        .accessibilityLabel("Add Expense")
                    }
                }
            }
    }

    // MARK: totalsSection
    private func totalsSection(total: Double) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("TOTAL SPENT")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)
            Text(total, format: .currency(code: currencyCode))
                .font(.system(size: 32, weight: .bold, design: .rounded))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(themeManager.selectedTheme.secondaryBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
    
    // MARK: categoryBreakdown
    private func categoryBreakdown(categories: [CardCategoryTotal]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("BY CATEGORY")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)
            ForEach(categories) { cat in
                HStack {
                    Circle()
                        .fill(cat.color)
                        .frame(width: 10, height: 10)
                    Text(cat.name)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Text(cat.amount, format: .currency(code: currencyCode))
                        .monospacedDigit()
                        .font(.callout.weight(.semibold))
                }
                .padding(.vertical, 2)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(themeManager.selectedTheme.secondaryBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
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

    private func boundedCardWidth(for availableWidth: CGFloat, upperBound: CGFloat) -> CGFloat? {
        guard availableWidth > 0 else { return upperBound }
        return min(availableWidth, upperBound)
    }

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
                if let date = expense.date {
                    Text(df.string(from: date)).font(.caption).foregroundStyle(.secondary)
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

// MARK: - List Bottom Inset Helpers
private extension View {
    @ViewBuilder
    func cardDetailListBottomInset(layoutContext: ResponsiveLayoutContext) -> some View {
        #if os(iOS)
        #if targetEnvironment(macCatalyst)
        self
        #else
        self.safeAreaInset(edge: .bottom) {
            Color.clear
                .frame(height: CardDetailListBottomInsetMetrics.bottomInset(for: layoutContext))
                .allowsHitTesting(false)
                .accessibilityHidden(true)
        }
        #endif
        #else
        self
        #endif
    }

    @ViewBuilder
    func cardDetailHideTopListSeparatorIfAvailable() -> some View {
        if #available(iOS 16.0, macCatalyst 16.0, macOS 13.0, *) {
            self.listSectionSeparator(.hidden, edges: .top)
        } else {
            self
        }
    }
}

private enum CardDetailListBottomInsetMetrics {
    #if os(iOS)
    #if targetEnvironment(macCatalyst)
    static func bottomInset(for layoutContext: ResponsiveLayoutContext) -> CGFloat { 0 }
    #else
    // Match BudgetDetailsView behavior: ensure at least the tab bar height is
    // represented so the list always scrolls comfortably.
    private static let compactTabBarHeight: CGFloat = 49
    private static let regularTabBarHeight: CGFloat = 49

    static func bottomInset(for layoutContext: ResponsiveLayoutContext) -> CGFloat {
        let safeAreaBottom = layoutContext.safeArea.bottom
        let sizeClass = layoutContext.horizontalSizeClass ?? .compact
        let tabBarHeight = sizeClass == .regular ? regularTabBarHeight : compactTabBarHeight
        if safeAreaBottom >= tabBarHeight - 1 {
            return safeAreaBottom
        } else {
            return safeAreaBottom + tabBarHeight
        }
    }
    #endif
    #else
    static func bottomInset(for layoutContext: ResponsiveLayoutContext) -> CGFloat { 0 }
    #endif
}

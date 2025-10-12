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
    @AppStorage(AppSettingsKeys.confirmBeforeDelete.rawValue) private var confirmBeforeDelete: Bool = true
    @State private var isSearchActive: Bool = false
    @FocusState private var isSearchFieldFocused: Bool
    // Add flows
    @State private var isPresentingAddPlanned: Bool = false
    @State private var expensePendingDeletion: CardExpense?
    @State private var isConfirmingDelete: Bool = false
    @State private var deletionError: DeletionError?
    @State private var editingExpense: CardExpense?

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
            detailsList(cardMaxWidth: cardMaxWidth, total: total)
    }
    }

    @ViewBuilder
    private func detailsList(cardMaxWidth: CGFloat?, total: Double) -> some View {
        List {
            Section {
                CardTileView(card: cardSnapshot, enableMotionShine: true)
                    .frame(maxWidth: cardMaxWidth)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.top, initialHeaderTopPadding)
                    .padding(.bottom, 12)
            }

            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Text(total, format: .currency(code: currencyCode))
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, 8)
            } header: {
                Text("TOTAL SPENT")
                    .font(.subheadline.weight(.semibold))
                    .textCase(nil)
            }

            Section {
                if viewModel.filteredCategories.isEmpty {
                    Text("No category totals available.")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical, DesignSystem.Spacing.l)
                } else {
                    ForEach(viewModel.filteredCategories) { cat in
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
            } header: {
                Text("BY CATEGORY")
                    .font(.subheadline.weight(.semibold))
                    .textCase(nil)
            }

            Section {
                let expenses = viewModel.filteredExpenses
                if expenses.isEmpty {
                    Text(viewModel.searchText.isEmpty ? "No expenses found." : "No results for “\(viewModel.searchText)”")
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
                                UnifiedSwipeConfig(allowsFullSwipeToDelete: false),
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
                try service.updateCard(managedCard, name: name)

                let resolvedUUID = cardSnapshot.uuid
                    ?? (managedCard.value(forKey: "id") as? UUID)
                if let resolvedUUID {
                    CardAppearanceStore.shared.setTheme(theme, for: resolvedUUID)
                }

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

    private var navigationContent: some View {
        content
            .navigationTitle(cardSnapshot.name)
        #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
        #endif
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") { dismiss(); onDone() }
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
                            isPresentingEditCard = true
                        }
                        // Add Expense menu (Planned or Variable) — rightmost control
                        Menu {
                            Button("Add Planned Expense") { isPresentingAddPlanned = true }
                            Button("Add Variable Expense") { isPresentingAddExpense = true }
                        } label: {
                            Image(systemName: "plus")
                                .font(.system(size: 18, weight: .semibold))
                                .symbolRenderingMode(.monochrome)
                        }
                        .accessibilityLabel("Add Expense")
                    }
                }
            }
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

// MARK: - Helpers
// Back-deploy listSectionSpacing(…) only on iOS 17+/macCatalyst 17+.
//

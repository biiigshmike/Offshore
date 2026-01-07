import SwiftUI
import CoreData

// MARK: - CardsView2
/// Simple grid of cards with modal CardDetailView.
/// - Uses ScrollView + LazyVGrid
/// - '+' button is glass on iOS 26+, plain on older OSes
/// - Tapping a card pushes CardDetailView in a navigation stack
struct CardsView: View {

    // MARK: State & ViewModel
    @StateObject private var vm = CardsViewModel()
    @State private var isPresentingAddCard = false
    @State private var isPresentingCardVariableExpense = false
    @State private var detailCard: CardItem? = nil
    @State private var editingCard: CardItem? = nil

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.responsiveLayoutContext) private var layoutContext

    // MARK: Grid
    @ScaledMetric(relativeTo: .body) private var cardWidth: CGFloat = 260
    @ScaledMetric(relativeTo: .body) private var cardHeight: CGFloat = 160
    @ScaledMetric(relativeTo: .body) private var gridSpacing: CGFloat = 16
    @ScaledMetric(relativeTo: .body) private var gridPadding: CGFloat = 16

    private var usesSingleColumn: Bool {
        dynamicTypeSize.isAccessibilitySize
    }

    private var gridSpacingValue: CGFloat {
        usesSingleColumn ? gridSpacing * 0.75 : gridSpacing
    }

    private var availableGridWidth: CGFloat {
        let safeArea = layoutContext.safeArea
        let insets = safeArea.leading + safeArea.trailing
        let width = layoutContext.containerSize.width - insets - (gridPadding * 2)
        return max(width, 0)
    }

    private var cappedCardWidth: CGFloat {
        guard availableGridWidth > 0 else { return cardWidth }
        return min(cardWidth, availableGridWidth)
    }

    private var columns: [GridItem] {
        if usesSingleColumn {
            return [GridItem(.flexible(minimum: cappedCardWidth, maximum: max(availableGridWidth, cappedCardWidth)), spacing: gridSpacingValue)]
        }
        return [GridItem(.adaptive(minimum: cappedCardWidth, maximum: cappedCardWidth), spacing: gridSpacingValue)]
    }
    

    var body: some View {
        cardsContent
            .tipsAndHintsOverlay(for: .cards)
    }

    @ViewBuilder
    private var cardsContent: some View {
        Group {
            if case .empty = vm.state {
                UBEmptyState(message: "No cards found. Tap + to create a card.")
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            } else {
                ScrollView {
                    Group {
                        switch vm.state {
                        case .initial:
                            Color.clear.frame(height: 1)
                        case .loading:
                            LazyVGrid(columns: columns, spacing: gridSpacingValue) {
                                ForEach(0..<2, id: \.self) { _ in
                                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                                        .fill(Color.primary.opacity(0.06))
                                        .frame(height: cardHeight)
                                        .redacted(reason: .placeholder)
                                }
                            }
                            .padding(.horizontal, gridPadding)
                            .padding(.top, gridPadding)
                        case .empty:
                            EmptyView()
                        case .loaded(let cards):
                            LazyVGrid(columns: columns, spacing: gridSpacingValue) {
                                ForEach(cards) { card in
                                    NavigationLink(value: card) {
                                        CardTileView(
                                            card: card,
                                            isSelected: false,
                                            onTap: { /* handled by NavigationLink */ },
                                            isInteractive: false,
                                            enableMotionShine: true,
                                            showsBaseShadow: false,
                                            showsEffectOverlay: true
                                        )
                                        .frame(maxWidth: usesSingleColumn ? .infinity : nil)
                                        .frame(minHeight: cardHeight)
                                    }
                                    .buttonStyle(.plain)
                                    .contextMenu {
                                        Button("Edit", systemImage: "pencil") { editingCard = card }
                                        Button("Delete", systemImage: "trash", role: .destructive) {
                                            vm.requestDelete(card: card)
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal, gridPadding)
                            .padding(.top, gridPadding)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .top)
                }
                .refreshable {
                    // Pull-to-refresh: nudge CloudKit and reload cards
                    CloudSyncAccelerator.shared.nudgeOnForeground()
                    await vm.refresh()
                }
            }
        }
        .navigationTitle("Cards")
        .toolbar { toolbarContent }
        .onAppear { vm.startIfNeeded() }
        .sheet(isPresented: $isPresentingAddCard) {
            AddCardFormView { newName, theme, effect in
                Task { await vm.addCard(name: newName, theme: theme, effect: effect) }
            }
        }
        .onChange(of: detailCard) { newValue in
            if newValue == nil {
                isPresentingCardVariableExpense = false
            }
        }
        .alert(item: $vm.alert) { alert in
            switch alert.kind {
            case .error(let message):
                return Alert(title: Text("Error"), message: Text(message), dismissButton: .default(Text("OK")))
            case .confirmDelete(let card):
                return Alert(
                    title: Text("Delete “\(card.name)”?"),
                    message: Text("This will delete the card and all of its expenses."),
                    primaryButton: .destructive(Text("Delete"), action: { Task { await vm.confirmDelete(card: card) } }),
                    secondaryButton: .cancel()
                )
            case .rename:
                return Alert(title: Text("Rename Card"), message: Text("Use Edit instead."), dismissButton: .default(Text("OK")))
            }
        }
        .navigationDestination(for: CardItem.self) { card in
            CardDetailView(
                card: card,
                isPresentingAddExpense: $isPresentingCardVariableExpense,
                onDone: { detailCard = nil }
            )
        }
        .sheet(item: $editingCard) { card in
            AddCardFormView(mode: .edit, editingCard: card) { name, theme, effect in
                Task { await vm.edit(card: card, name: name, theme: theme, effect: effect) }
            }
        }
    }

    // MARK: Toolbar
    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .primaryAction) {
            addButton
        }
    }

    @ViewBuilder
    private var addButton: some View {
        Buttons.toolbarIcon("plus") { isPresentingAddCard = true }
        .accessibilityLabel("Add Card")
        
    }

    // Guided walkthrough removed
}

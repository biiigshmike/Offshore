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

    @EnvironmentObject private var guidedWalkthrough: GuidedWalkthroughManager

    // MARK: Guided Walkthrough State
    @State private var showGuidedOverlay: Bool = false
    @State private var requestedGuidedWalkthrough: Bool = false
    @State private var visibleGuidedHints: Set<GuidedWalkthroughManager.Hint> = []
    @State private var guidedHintWorkItems: [GuidedWalkthroughManager.Hint: DispatchWorkItem] = [:]

    // MARK: Grid
    private let columns = [GridItem(.adaptive(minimum: 260, maximum: 260), spacing: 16)]
    private let cardHeight: CGFloat = 160

    var body: some View {
        ZStack {
            cardsContent
            if showGuidedOverlay, let overlay = guidedWalkthrough.overlay(for: .cards) {
                GuidedOverlayView(
                    overlay: overlay,
                    onDismiss: {
                        showGuidedOverlay = false
                        guidedWalkthrough.markOverlaySeen(for: .cards)
                    },
                    nextAction: presentCardsHints
                )
                .transition(.opacity)
            }
        }
        .onAppear { requestCardsGuidedIfNeeded() }
        .onDisappear { cancelCardsHintWork() }
    }

    @ViewBuilder
    private var cardsContent: some View {
        navigationContainer {
            ScrollView {
                Group {
                    switch vm.state {
                    case .initial:
                        Color.clear.frame(height: 1)
                    case .loading:
                        LazyVGrid(columns: columns, spacing: 16) {
                            ForEach(0..<2, id: \.self) { _ in
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .fill(Color.primary.opacity(0.06))
                                    .frame(height: cardHeight)
                                    .redacted(reason: .placeholder)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 16)
                    case .empty:
                        VStack(spacing: 12) {
                            Image(systemName: "creditcard")
                                .font(.system(size: 42, weight: .regular))
                                .foregroundStyle(.secondary)
                            Text("No Cards Found")
                                .font(.title3.weight(.semibold))
                            Text("Press + to add your first card.")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity, minHeight: 260, alignment: .center)
                        .padding(.horizontal, 16)
                    case .loaded(let cards):
                        LazyVGrid(columns: columns, spacing: 16) {
                            ForEach(cards) { card in
                                NavigationLink(value: card) {
                                    CardTileView(
                                        card: card,
                                        isSelected: false,
                                        onTap: { /* handled by NavigationLink */ },
                                        isInteractive: false,
                                        enableMotionShine: true,
                                        showsBaseShadow: false
                                    )
                                    .frame(height: cardHeight)
                                    .overlay(alignment: .topLeading) {
                                        if visibleGuidedHints.contains(.cardsTile),
                                           let bubble = cardsHintLookup[.cardsTile],
                                           card == cards.first {
                                            HintBubbleView(hint: bubble)
                                                .padding(.top, 8)
                                                .padding(.leading, 8)
                                        }
                                    }
                                }
                                .simultaneousGesture(TapGesture().onEnded { hideCardsHint(.cardsTile) })
                                .contextMenu {
                                    Button("Edit", systemImage: "pencil") { editingCard = card }
                                    Button("Delete", systemImage: "trash", role: .destructive) {
                                        vm.requestDelete(card: card)
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 16)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .top)
            }
            .navigationTitle("Cards")
            .toolbar { toolbarContent }
            .onAppear { vm.startIfNeeded() }
            .sheet(isPresented: $isPresentingAddCard) {
                AddCardFormView { newName, theme in
                    Task { await vm.addCard(name: newName, theme: theme) }
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
                AddCardFormView(mode: .edit, editingCard: card) { name, theme in
                    Task { await vm.edit(card: card, name: name, theme: theme) }
                }
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
        Buttons.toolbarIcon("plus") {
            hideCardsHint(.cardsAdd)
            isPresentingAddCard = true
        }
        .accessibilityLabel("Add Card")
        .overlay(alignment: .topTrailing) {
            if visibleGuidedHints.contains(.cardsAdd),
               let bubble = cardsHintLookup[.cardsAdd] {
                HintBubbleView(hint: bubble)
                    .offset(x: 16, y: -50)
            }
        }
        .simultaneousGesture(TapGesture().onEnded { hideCardsHint(.cardsAdd) })
    }

    // MARK: Navigation container
    @ViewBuilder
    private func navigationContainer<Inner: View>(@ViewBuilder content: () -> Inner) -> some View {
        if #available(iOS 16.0, macCatalyst 16.0, *) {
            NavigationStack {
                content()
            }
        } else {
            NavigationView {
                content()
            }
        }
    }

    // MARK: Guided Walkthrough Helpers
    private var cardsHintLookup: [GuidedWalkthroughManager.Hint: HintBubble] {
        Dictionary(uniqueKeysWithValues: guidedWalkthrough.hints(for: .cards).map { ($0.id, $0) })
    }

    private func requestCardsGuidedIfNeeded() {
        guard !requestedGuidedWalkthrough else { return }
        requestedGuidedWalkthrough = true
        if guidedWalkthrough.shouldShowOverlay(for: .cards) {
            withAnimation(.easeInOut(duration: 0.3)) {
                showGuidedOverlay = true
            }
        } else {
            presentCardsHints()
        }
    }

    private func presentCardsHints() {
        for bubble in guidedWalkthrough.hints(for: .cards) where guidedWalkthrough.shouldShowHint(bubble.id) {
            displayCardsHint(bubble.id)
        }
    }

    private func displayCardsHint(_ hint: GuidedWalkthroughManager.Hint) {
        guard guidedWalkthrough.shouldShowHint(hint) else { return }
        guard !visibleGuidedHints.contains(hint) else { return }
        withAnimation(.easeInOut(duration: 0.25)) {
            _ = visibleGuidedHints.insert(hint)
        }
        scheduleCardsHintAutoHide(for: hint)
    }

    private func scheduleCardsHintAutoHide(for hint: GuidedWalkthroughManager.Hint) {
        guidedHintWorkItems[hint]?.cancel()
        let work = DispatchWorkItem {
            if visibleGuidedHints.contains(hint) {
                withAnimation(.easeInOut(duration: 0.3)) {
                    _ = visibleGuidedHints.remove(hint)
                }
            }
            guidedWalkthrough.markHintSeen(hint)
            guidedHintWorkItems[hint] = nil
        }
        guidedHintWorkItems[hint] = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 6.0, execute: work)
    }

    private func hideCardsHint(_ hint: GuidedWalkthroughManager.Hint) {
        if let work = guidedHintWorkItems.removeValue(forKey: hint) {
            work.cancel()
        }
        if visibleGuidedHints.contains(hint) {
            withAnimation(.easeInOut(duration: 0.2)) {
                _ = visibleGuidedHints.remove(hint)
            }
        }
        guidedWalkthrough.markHintSeen(hint)
    }

    private func cancelCardsHintWork() {
        for (_, work) in guidedHintWorkItems { work.cancel() }
        guidedHintWorkItems.removeAll()
        visibleGuidedHints.removeAll()
        showGuidedOverlay = false
    }
}

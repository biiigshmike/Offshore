import SwiftUI
import CoreData
#if canImport(UIKit)
import UIKit
#endif

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

    // MARK: Grid
    private let columns = [GridItem(.adaptive(minimum: 260, maximum: 260), spacing: 16)]
    private let cardHeight: CGFloat = 160

    // MARK: Environment
    @EnvironmentObject private var tour: GuidedTourState
    @Environment(\.guidedTourScreen) private var guidedTourScreen

    // MARK: Guided Tour State
    @State private var showTourOverlay = false
    @State private var activeHints: Set<CardsHint> = []

    private enum CardsHint: String, CaseIterable, Hashable {
        case grid
        case add

        var anchorID: String { "cards.hint.\(rawValue)" }

        var icon: String {
            switch self {
            case .grid: return "rectangle.grid.2x2"
            case .add: return "plus"
            }
        }

        var text: String {
            switch self {
            case .grid:
                return "Tap a card to view details and track expenses for that wallet."
            case .add:
                return "Add a new card to start tracking purchases from a different wallet."
            }
        }

        var arrowDirection: GuidedHintBubble.ArrowDirection {
            switch self {
            case .grid: return .down
            case .add: return .down
            }
        }
    }

    var body: some View {
        ZStack {
            cardsContent
                .guidedHintOverlay { geometry, anchors in
                    cardsHintsOverlay(geometry: geometry, anchors: anchors)
                }

            if showTourOverlay {
                GuidedTourOverlay(
                    title: "Organize your cards",
                    message: cardsOverlayMessage,
                    bullets: cardsOverlayBullets,
                    onClose: handleCardsOverlayDismiss
                )
                .transition(.opacity)
                .zIndex(1)
            }
        }
    }

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
                                // Modern value-based navigation link
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
                                }
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
            .guidedHintAnchor(CardsHint.grid.anchorID)
            .navigationTitle("Cards")
            .toolbar { toolbarContent }
            .onAppear {
                vm.startIfNeeded()
                evaluateCardsTourState()
            }
            // Add Card
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
            // Destination for value-based navigation
            .navigationDestination(for: CardItem.self) { card in
                CardDetailView(
                    card: card,
                    isPresentingAddExpense: $isPresentingCardVariableExpense,
                    onDone: { detailCard = nil }
                )
            }
            // Edit sheet
            .sheet(item: $editingCard) { card in
                AddCardFormView(mode: .edit, editingCard: card) { name, theme in
                    Task { await vm.edit(card: card, name: name, theme: theme) }
                }
            }
            .onChange(of: vm.state) { _ in
                evaluateCardsTourState()
            }
            .onReceive(NotificationCenter.default.publisher(for: .guidedTourDidReset)) { _ in
                handleCardsTourReset()
            }
        }
    }

    // MARK: Guided Tour
    private func evaluateCardsTourState() {
        guard isCardsViewActive else { return }

        switch vm.state {
        case .loaded, .empty:
            break
        default:
            return
        }

        if tour.needsOverlay(.cards) {
            if !showTourOverlay {
                withAnimation(.easeInOut(duration: 0.25)) {
                    showTourOverlay = true
                }
                AppLog.ui.info("GuidedTour overlayShown screen=cards")
            }
            activeHints.removeAll()
            return
        }

        if showTourOverlay {
            showTourOverlay = false
        }

        presentCardsHintsIfNeeded()
    }

    private func presentCardsHintsIfNeeded() {
        guard isCardsViewActive, !showTourOverlay else { return }

        guard tour.needsHints(.cards) else {
            activeHints.removeAll()
            return
        }

        let hints = CardsHint.allCases
        let desired = Set(hints)
        if desired != activeHints {
            activeHints = desired
            AppLog.ui.info("GuidedTour hintsShown screen=cards count=\(desired.count)")
        }
    }

    private func handleCardsOverlayDismiss() {
        tour.markOverlaySeen(.cards)
        withAnimation(.easeInOut(duration: 0.25)) {
            showTourOverlay = false
        }
        AppLog.ui.info("GuidedTour overlayDismissed screen=cards")
        presentCardsHintsIfNeeded()
    }

    private func dismissCardsHint(_ hint: CardsHint) {
        activeHints.remove(hint)
        if activeHints.isEmpty {
            tour.markHintsDismissed(.cards)
            AppLog.ui.info("GuidedTour hintsCompleted screen=cards")
        }
    }

    private func handleCardsTourReset() {
        showTourOverlay = false
        activeHints.removeAll()
        evaluateCardsTourState()
    }

    private var isCardsViewActive: Bool {
        guidedTourScreen == nil || guidedTourScreen == .cards
    }

    private var cardsOverlayMessage: String {
        "Store debit, credit, and cash cards so every wallet has a clear running total."
    }

    private var cardsOverlayBullets: [String] {
        [
            "Tap a card tile to open its detail view and review expenses.",
            "Use the plus button to add new cards in seconds.",
            "Long-press a card for quick edit and delete actions."
        ]
    }

    @ViewBuilder
    private func cardsHintsOverlay(geometry: GeometryProxy, anchors: [String: Anchor<CGRect>]) -> some View {
        let ordered = CardsHint.allCases.filter { activeHints.contains($0) }
        ForEach(ordered, id: \.self) { hint in
            if let frame = geometry.frame(forHint: hint.anchorID, anchors: anchors) {
                cardsHintBubble(for: hint, frame: frame, geometry: geometry)
            }
        }
    }

    @ViewBuilder
    private func cardsHintBubble(for hint: CardsHint, frame: CGRect, geometry: GeometryProxy) -> some View {
        let bubble = GuidedHintBubble(
            icon: hint.icon,
            text: hint.text,
            arrowDirection: hint.arrowDirection
        ) { dismissCardsHint(hint) }

        let position = cardsHintPosition(for: hint, frame: frame, geometry: geometry)

        bubble
            .position(x: position.x, y: position.y)
            .transition(.opacity.combined(with: .scale))
            .zIndex(1)
    }

    private func cardsHintPosition(for hint: CardsHint, frame: CGRect, geometry: GeometryProxy) -> CGPoint {
        let width = geometry.size.width.isFinite ? geometry.size.width : UIScreen.main.bounds.width
        let minX: CGFloat = 140
        let maxX: CGFloat = max(minX, width - 140)
        let x = clamp(frame.midX, min: minX, max: maxX)

        switch hint {
        case .grid:
            let y = max(frame.minY - 70, 80)
            return CGPoint(x: x, y: y)
        case .add:
            let y = max(frame.minY - 70, 80)
            return CGPoint(x: x, y: y)
        }
    }

    private func clamp(_ value: CGFloat, min: CGFloat, max: CGFloat) -> CGFloat {
        guard min < max else { return value }
        if value < min { return min }
        if value > max { return max }
        return value
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
        // Clear, no-background toolbar icon (matches IncomeView2)
        Buttons.toolbarIcon("plus") { isPresentingAddCard = true }
            .accessibilityLabel("Add Card")
            .guidedHintAnchor(CardsHint.add.anchorID)
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
}

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

    // MARK: Grid
    private let columns = [GridItem(.adaptive(minimum: 260, maximum: 260), spacing: 16)]
    private let cardHeight: CGFloat = 160

    var body: some View {
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
                            Text("No cards yet")
                                .font(.title3.weight(.semibold))
                            Text("Tap + to add your first card.")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity, minHeight: 240)
                        .padding(.top, 24)
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
            .navigationTitle("Cards")
            .toolbar { toolbarContent }
            .onAppear { vm.startIfNeeded() }
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
        // Clear, no-background toolbar icon (matches IncomeView2)
        Buttons.toolbarIcon("plus") { isPresentingAddCard = true }
            .accessibilityLabel("Add Card")
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

//
//  CardPickerRow.swift
//  SoFar
//
//  Horizontal, scrollable row of saved cards rendered with CardTileView styling.
//  Designed for AddUnplannedExpenseView (or anywhere you pick a card).
//
//  Parameters:
//  - allCards: Core Data cards `[Card]` (we bridge each to `CardItem` internally).
//  - selectedCardID: Two-way binding to the picked card's `NSManagedObjectID?`.
//
//  Behavior:
//  - Shows the actual themed card tiles with a strong color-matched selection ring + glow.
//  - On first appear, auto-selects the first card if nothing is chosen yet.
//  - Keeps selection stable via Core Data `objectID`.
//
//  How to use:
//    CardPickerRow(allCards: vm.allCards, selectedCardID: $vm.selectedCardID)
//

import SwiftUI
import CoreData

// MARK: - CardPickerRow
struct CardPickerRow: View {

    // MARK: Inputs
    /// Core Data Card entities to render as selectable tiles.
    let allCards: [Card]

    /// Selected Core Data objectID; keeps selection stable even through renames.
    @Binding var selectedCardID: NSManagedObjectID?

    // MARK: Layout
    // Card tile height. Adjust here rather than inside individual views so
    // tweaks remain consistent across the app.
    private let tileHeight: CGFloat = 160

    // MARK: Body
    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: DS.Spacing.l) {
                    ForEach(allCards, id: \.objectID) { managedCard in
                        // MARK: Bridge Core Data → UI model
                        // Uses your existing CoreDataBridge to pull name/theme.
                        let item = CardItem(from: managedCard)
                        let isSelected = selectedCardID == managedCard.objectID
                        let idString = managedCard.objectID.uriRepresentation().absoluteString

                        CardTileView(
                            card: item,
                            isSelected: isSelected,
                            onTap: {
                                // MARK: On Tap → Select for Expense
                                withAnimation(.easeInOut) {
                                    selectedCardID = managedCard.objectID
                                }
                            },
                            enableMotionShine: true,
                            showsBaseShadow: false
                        )
                        .frame(height: tileHeight)
                        .id(idString)
                    }
                }
                .padding(.horizontal, DS.Spacing.l)
                .padding(.vertical, DS.Spacing.s)
            }
            .scrollIndicators(.hidden)
            .onAppear {
                // If no selection yet, default to first available card.
                if selectedCardID == nil, let firstID = allCards.first?.objectID {
                    selectedCardID = firstID
                }
                // Attempt to center the selected card on first appear.
                scrollToSelected(proxy, animated: false)
            }
            .onChange(of: selectedCardID) { _ in
                scrollToSelected(proxy, animated: true)
            }
            .onChange(of: allCards.count) { _ in
                // When the data set changes (e.g., card added), keep selected centered.
                scrollToSelected(proxy, animated: true)
            }
        }
    }

    // MARK: Helpers
    private func scrollToSelected(_ proxy: ScrollViewProxy, animated: Bool) {
        guard let sel = selectedCardID else { return }
        let idString = sel.uriRepresentation().absoluteString
        if animated {
            withAnimation(.easeInOut) {
                proxy.scrollTo(idString, anchor: .center)
            }
        } else {
            proxy.scrollTo(idString, anchor: .center)
        }
    }
}

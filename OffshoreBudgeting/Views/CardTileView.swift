//
//  CardTileView.swift
//  SoFar
//
//  Reusable, selectable card tile used in CardsView and AddUnplannedExpenseView.
//
//  Updates in this version:
//  - Stronger, always-visible selection RING (2–3pt) inside the card bounds.
//  - Soft outer GLOW remains for extra flair when not clipped.
//  - Background gradient is STATIC (no device motion).
//  - Metallic title text still shimmers (uses your existing holographic helper).
//

import SwiftUI

// NOTE: CardItem is defined in Models/CardItem.swift.

// MARK: - CardTileView
struct CardTileView: View {

    // MARK: Inputs
    /// The UI card to display.
    let card: CardItem
    /// Pass true to show the selection ring + glow.
    var isSelected: Bool = false
    /// Optional tap callback.
    var onTap: (() -> Void)? = nil
    /// When true, enables motion‑driven metallic/shine overlays in the title.
    /// Keep this OFF for grids to avoid heavy per‑frame updates; turn ON for
    /// single, prominent tiles (e.g., detail header).
    var enableMotionShine: Bool = false

    /// When true, applies the base neutral drop shadow beneath the card tile.
    /// Set to false for flat presentations (e.g., pickers and grids) while
    /// retaining the selection glow.
    var showsBaseShadow: Bool = true

    @EnvironmentObject private var themeManager: ThemeManager

    // MARK: Layout
    private let cornerRadius: CGFloat = DS.Radius.card
    private let aspectRatio: CGFloat = 1.586 // credit card proportion

    // MARK: Body
    var body: some View {
        cardTile
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(Text("\(card.name)\(isSelected ? ", selected" : "")"))
            .accessibilityIdentifier("card_tile_\(card.id)")
    }
}

// MARK: - Computed Views
private extension CardTileView {

    @ViewBuilder
    var cardTile: some View {
        if let onTap {
            baseTile
                .onTapGesture { onTap() }
                .accessibilityAddTraits(.isButton)
                .accessibilityHint(Text("Tap to select card"))
        } else {
            baseTile
        }
    }

    var baseTile: some View {
        ZStack(alignment: .bottomLeading) {

            // MARK: Card Background (STATIC gradient + pattern)
            ZStack {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(backgroundStyle)
                card.theme
                    .patternOverlay(cornerRadius: cornerRadius)
                    .blendMode(.overlay)
            }

            // MARK: Title (Metallic shimmer stays)
            cardTitle
                .lineLimit(1)
                .minimumScaleFactor(0.5)
                .padding(.all, DS.Spacing.l)
        }
        .aspectRatio(aspectRatio, contentMode: .fit)
        .contentShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        .overlay(selectionRingOverlay) // <- inner visible ring
        .overlay(selectionGlowOverlay) // <- outer glow (pretty when not clipped)
        .overlay(thinEdgeOverlay)
        //.shadow(color: .black.opacity(showsBaseShadow ? 0.20 : 0), radius: showsBaseShadow ? 6 : 0, x: 0, y: showsBaseShadow ? 4 : 0)
    }

    // MARK: Background Gradient (STATIC)
    var backgroundStyle: AnyShapeStyle {
        card.theme.backgroundStyle(for: themeManager.selectedTheme)
    }

    // MARK: Selection Ring (always visible, not clipped)
    /// A high-contrast ring drawn INSIDE the card bounds so it can’t be clipped.
    var selectionRingOverlay: some View {
        RoundedRectangle(cornerRadius: cornerRadius - 0.5, style: .continuous)
            .inset(by: 0.5) // keep the ring inside the edge
            .stroke(
                isSelected
                ? card.theme.glowColor.opacity(0.95)
                : .clear,
                lineWidth: isSelected ? 2.5 : 0
            )
            .overlay(
                // Subtle inner assist ring to help on very bright cards
                RoundedRectangle(cornerRadius: cornerRadius - 1.5, style: .continuous)
                    .inset(by: 1.5)
                    .stroke(isSelected ? Color.white.opacity(0.45) : .clear, lineWidth: isSelected ? 0.8 : 0)
            )
            .allowsHitTesting(false)
    }

    // MARK: Selection Glow (soft, outside)
    /// Pretty neon-ish glow. This may be clipped by parent containers,
    /// which is why the ring above is the reliable indicator.
    var selectionGlowOverlay: some View {
        // Draw a clear stroke to host shadows without clipping.
        RoundedRectangle(cornerRadius: cornerRadius + 1, style: .continuous)
            .stroke(Color.clear, lineWidth: 0)
            .shadow(color: card.theme.glowColor.opacity(isSelected ? 0.60 : 0), radius: isSelected ? 10 : 0)
            .shadow(color: card.theme.glowColor.opacity(isSelected ? 0.36 : 0), radius: isSelected ? 20 : 0)
            .shadow(color: card.theme.glowColor.opacity(isSelected ? 0.18 : 0), radius: isSelected ? 34 : 0)
            .padding(isSelected ? -1 : 0)
            .allowsHitTesting(false)
    }

    // MARK: Thin Edge
    /// Subtle inner edge to sharpen the card silhouette.
    var thinEdgeOverlay: some View {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .strokeBorder(Color.primary.opacity(0.18), lineWidth: 1)
            .allowsHitTesting(false)
    }

    // MARK: Title builder
    var cardTitle: some View {
        Group {
            if enableMotionShine {
                HolographicMetallicText(
                    text: card.name,
                    titleFont: Font.system(.title, design: .rounded).weight(.semibold),
                    shimmerResponsiveness: 1.5,
                    maxMetallicOpacity: 0.6,
                    maxShineOpacity: 0.7
                )
            } else {
                Text(card.name)
                    .font(.system(.title, design: .rounded).weight(.semibold))
                    .foregroundStyle(UBTypography.cardTitleStatic)
                    .ub_cardTitleShadow()
            }
        }
    }
}

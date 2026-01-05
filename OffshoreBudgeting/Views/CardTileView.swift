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
    /// When false, renders as a plain, non-interactive view (useful as a
    /// NavigationLink label so the link receives taps instead of an inner button).
    var isInteractive: Bool = true
    /// When true, enables motion‑driven metallic/shine overlays in the title.
    /// Keep this OFF for grids to avoid heavy per‑frame updates; turn ON for
    /// single, prominent tiles (e.g., detail header).
    var enableMotionShine: Bool = false

    /// When true, applies the base neutral drop shadow beneath the card tile.
    /// Set to false for flat presentations (e.g., pickers and grids) while
    /// retaining the selection glow.
    var showsBaseShadow: Bool = true

    @EnvironmentObject private var themeManager: ThemeManager
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.colorSchemeContrast) private var colorSchemeContrast
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    // MARK: Layout
    private let cornerRadius: CGFloat = DS.Radius.card
    private let aspectRatio: CGFloat = 1.586 // credit card proportion
    @ScaledMetric(relativeTo: .body) private var titlePadding: CGFloat = DS.Spacing.l
    @ScaledMetric(relativeTo: .body) private var minimumTileHeight: CGFloat = 160

    // MARK: Body
    var body: some View {
        Group {
            if isInteractive {
                Button(action: { onTap?() }) { tileVisual }
                    .buttonStyle(.plain)
            } else {
                tileVisual
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text("\(card.name)\(isSelected ? ", selected" : "")"))
        .accessibilityHint(Text("Tap to select card"))
        .accessibilityIdentifier("card_tile_\(card.id)")
    }
}

// MARK: - Computed Views
private extension CardTileView {
    var isHighContrast: Bool {
        colorSchemeContrast == .increased
    }

    var isAccessibilitySize: Bool {
        dynamicTypeSize.isAccessibilitySize
    }

    // MARK: Tile Visual
    @ViewBuilder
    var tileVisual: some View {
        let tileBase =
            ZStack(alignment: .bottomLeading) {

                // MARK: Card Background (STATIC gradient + pattern)
                ZStack {
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(backgroundStyle)
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(card.theme.adaptiveOverlay(for: colorScheme, isHighContrast: isHighContrast))
                    card.theme
                        .patternOverlay(cornerRadius: cornerRadius)
                        .blendMode(.overlay)
                }

                // MARK: Title (Metallic shimmer stays)
                cardTitle
                    .lineLimit(isAccessibilitySize ? 3 : 2)
                    .minimumScaleFactor(isAccessibilitySize ? 1 : 0.82)
                    .fixedSize(horizontal: false, vertical: true)
                    .multilineTextAlignment(.leading)
                    .padding(.all, titlePadding)
            }
            .contentShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay(selectionFillOverlay)
            .overlay(selectionRingOverlay) // <- inner visible ring
            .overlay(selectionGlowOverlay) // <- outer glow (pretty when not clipped)
            .overlay(thinEdgeOverlay)
            //.shadow(color: .black.opacity(showsBaseShadow ? 0.20 : 0), radius: showsBaseShadow ? 6 : 0, x: 0, y: showsBaseShadow ? 4 : 0)

        if isAccessibilitySize {
            tileBase.frame(minHeight: minimumTileHeight)
        } else {
            tileBase.aspectRatio(aspectRatio, contentMode: .fit)
        }
    }

    // MARK: Background Gradient (STATIC)
    var backgroundStyle: AnyShapeStyle {
        card.theme.backgroundStyle(for: themeManager.selectedTheme)
    }

    // MARK: Selection Fill & Badge
    /// Additional selected-state feedback using the accent color and blend modes.
    var selectionFillOverlay: some View {
        Group {
            if isSelected {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(card.theme.selectionAccentColor.opacity(0.22))
                    .blendMode(card.theme.selectionAccentBlendMode)
                    .overlay(alignment: .topTrailing) {
                        selectionBadge
                            .padding(DS.Spacing.m)
                    }
                    .allowsHitTesting(false)
            }
        }
    }

    // MARK: Selection Ring (always visible, not clipped)
    /// A high-contrast ring drawn INSIDE the card bounds so it can’t be clipped.
    var selectionRingOverlay: some View {
        RoundedRectangle(cornerRadius: cornerRadius - 0.5, style: .continuous)
            .inset(by: 0.5) // keep the ring inside the edge
            .stroke(
                isSelected
                ? card.theme.selectionAccentColor
                : .clear,
                lineWidth: isSelected ? 3.2 : 0
            )
            .overlay(
                // Subtle inner assist ring to help on very bright cards
                RoundedRectangle(cornerRadius: cornerRadius - 2.0, style: .continuous)
                    .inset(by: 2.0)
                    .stroke(
                        isSelected ? card.theme.selectionAssistStrokeColor : .clear,
                        lineWidth: isSelected ? 1.1 : 0
                    )
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
        let titleFont = Font.system(.title, design: .rounded).weight(.semibold)
        let titleColor: Color = isHighContrast ? .primary : UBTypography.cardTitleStatic
        let allowMotionShine = enableMotionShine && !reduceMotion && !isHighContrast
        let titleView = Group {
            if allowMotionShine {
                HolographicMetallicText(
                    text: card.name,
                    titleFont: titleFont,
                    shimmerResponsiveness: 1.5,
                    maxMetallicOpacity: 0.6,
                    maxShineOpacity: 0.7
                )
            } else {
                Text(card.name)
                    .font(titleFont)
                    .foregroundStyle(titleColor)
                    .ub_cardTitleShadow()
            }
        }
        return titleView
    }

    // MARK: Selection Badge
    var selectionBadge: some View {
        ZStack {
            Circle()
                .fill(card.theme.selectionAccentColor.opacity(0.92))
            Image(systemName: "checkmark")
                .font(.caption.weight(.bold))
                .foregroundStyle(card.theme.selectionGlyphColor)
        }
        .frame(width: 28, height: 28)
        .shadow(color: Color.black.opacity(0.25), radius: 6, x: 0, y: 3)
        .accessibilityHidden(true)
    }
}

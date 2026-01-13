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
import UIKit

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
    /// When true, allows the material background to respond to device motion.
    var enableMaterialMotion: Bool = true

    /// When true, applies the base neutral drop shadow beneath the card tile.
    /// Set to false for flat presentations (e.g., pickers and grids) while
    /// retaining the selection glow.
    var showsBaseShadow: Bool = true
    /// When true, overlays the selected card effect (e.g., subtle plastic sheen).
    var showsEffectOverlay: Bool = false
    /// Title line limit when not in accessibility sizes.
    var nonAccessibilityTitleLineLimit: Int = 2
    /// Optional min scale for the title when not in accessibility sizes.
    var nonAccessibilityTitleMinimumScaleFactor: CGFloat? = nil
    /// Optional tightening for the title when not in accessibility sizes.
    var nonAccessibilityTitleAllowsTightening: Bool = false

    @EnvironmentObject private var themeManager: ThemeManager
    @EnvironmentObject private var cardPickerStore: CardPickerStore
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.colorSchemeContrast) private var colorSchemeContrast
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    // MARK: Layout
    private let cornerRadius: CGFloat = DS.Radius.card
    private let aspectRatio: CGFloat = 1.586 // credit card proportion
    @ScaledMetric(relativeTo: .body) private var titlePadding: CGFloat = Spacing.l
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
        .accessibilityLabel(Text("\(resolvedCard.name)\(isSelected ? ", selected" : "")"))
        .accessibilityHint(Text("Tap to select card"))
        .accessibilityIdentifier(AccessibilityID.Cards.Tile.cardTile(id: resolvedCard.id))
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

    var resolvedCard: CardItem {
        guard cardPickerStore.isReady else { return card }
        if let objectID = card.objectID,
           let managedCard = cardPickerStore.cards.first(where: { $0.objectID == objectID }) {
            var item = CardItem(from: managedCard)
            item.balance = card.balance
            return item
        }
        if let uuid = card.uuid,
           let managedCard = cardPickerStore.cards.first(where: { ($0.value(forKey: "id") as? UUID) == uuid }) {
            var item = CardItem(from: managedCard)
            item.balance = card.balance
            return item
        }
        return card
    }

    // MARK: Tile Visual
    @ViewBuilder
    var tileVisual: some View {
        let tileBase =
            ZStack(alignment: .bottomLeading) {

                // MARK: Card Background (material-aware)
                ZStack {
                    if showsEffectOverlay {
                        CardMaterialBackground(
                            theme: resolvedCard.theme,
                            effect: resolvedCard.effect,
                            cornerRadius: cornerRadius,
                            enableMotion: enableMaterialMotion
                        )
                    } else {
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .fill(backgroundStyle)
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .fill(resolvedCard.theme.adaptiveOverlay(for: colorScheme, isHighContrast: isHighContrast))
                        resolvedCard.theme
                            .patternOverlay(cornerRadius: cornerRadius)
                            .blendMode(.overlay)
                    }
                }

                // MARK: Title (Metallic shimmer stays)
                cardTitle
                    .lineLimit(isAccessibilitySize ? 3 : nonAccessibilityTitleLineLimit)
                    .if(!isAccessibilitySize && nonAccessibilityTitleAllowsTightening) { view in
                        view.allowsTightening(true)
                    }
                    .minimumScaleFactor(
                        isAccessibilitySize ? 1 : (nonAccessibilityTitleMinimumScaleFactor ?? 0.82)
                    )
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
        resolvedCard.theme.backgroundStyle(for: themeManager.selectedTheme)
    }


    // MARK: Selection Fill & Badge
    /// Additional selected-state feedback using the accent color and blend modes.
    var selectionFillOverlay: some View {
        Group {
            if isSelected {
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .fill(resolvedCard.theme.selectionAccentColor.opacity(0.22))
                            .blendMode(resolvedCard.theme.selectionAccentBlendMode)
                            .overlay(alignment: .topTrailing) {
                                selectionBadge
                                    .padding(Spacing.m)
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
                ? resolvedCard.theme.selectionAccentColor
                : .clear,
                lineWidth: isSelected ? 3.2 : 0
            )
            .overlay(
                // Subtle inner assist ring to help on very bright cards
                RoundedRectangle(cornerRadius: cornerRadius - 2.0, style: .continuous)
                    .inset(by: 2.0)
                    .stroke(
                        isSelected ? resolvedCard.theme.selectionAssistStrokeColor : .clear,
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
            .shadow(color: resolvedCard.theme.glowColor.opacity(isSelected ? 0.60 : 0), radius: isSelected ? 10 : 0)
            .shadow(color: resolvedCard.theme.glowColor.opacity(isSelected ? 0.36 : 0), radius: isSelected ? 20 : 0)
            .shadow(color: resolvedCard.theme.glowColor.opacity(isSelected ? 0.18 : 0), radius: isSelected ? 34 : 0)
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
                    text: resolvedCard.name,
                    titleFont: titleFont,
                    shimmerResponsiveness: 1.5,
                    maxMetallicOpacity: 0.6,
                    maxShineOpacity: 0.7
                )
            } else {
                Text(resolvedCard.name)
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
                .fill(resolvedCard.theme.selectionAccentColor.opacity(0.92))
            Image(systemName: "checkmark")
                .font(.caption.weight(.bold))
                .foregroundStyle(resolvedCard.theme.selectionGlyphColor)
        }
        .frame(width: 28, height: 28)
        .shadow(color: Color.black.opacity(0.25), radius: 6, x: 0, y: 3)
        .accessibilityHidden(true)
    }
}

// MARK: - CardMaterialBackground
struct CardMaterialBackground: View {
    let theme: CardTheme
    let effect: CardEffect
    let cornerRadius: CGFloat
    let enableMotion: Bool
    @ObservedObject private var motion: MotionMonitor = MotionMonitor.shared
    @EnvironmentObject private var themeManager: ThemeManager
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.colorSchemeContrast) private var colorSchemeContrast
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        GeometryReader { proxy in
            let size = proxy.size
            ZStack {
                if effect == .glass {
                    glassSurface(for: size)
                } else {
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(materialFill(for: size))
                        .saturation(materialSaturation)
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(materialOverlayColor(for: size))
                    if effect == .holographic && shouldUseMaterial {
                        let ring = holographicRingMetrics(for: size)
                        let ringShape = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .inset(by: ring.inset)
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .fill(holographicFoilOverlay(for: size))
                            .blendMode(.plusLighter)
                            .opacity(holographicFoilOverlayOpacity(for: size))
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .fill(holographicRainbowOverlay(for: size))
                            .blendMode(.softLight)
                            .opacity(holographicRainbowOverlayOpacity(for: size))
                        ringShape
                            .strokeBorder(holographicFoilOverlay(for: size), lineWidth: ring.thickness)
                            .blendMode(.plusLighter)
                            .opacity(holographicRingRimOpacity(for: size))
                        ringShape
                            .strokeBorder(holographicRainbowOverlay(for: size), lineWidth: ring.thickness * 2.2)
                            .blendMode(.softLight)
                            .opacity(holographicRingFillOpacity(for: size))
                            .blur(radius: ring.thickness * 0.35)
                    }
                    if effect == .metal && shouldUseMaterial {
                        MetalAnisotropicBandingOverlay(
                            cornerRadius: cornerRadius,
                            bandHeight: 1.6,
                            gap: 14.0,
                            highlight: metalBandHighlight,
                            shadow: metalBandShadow
                        )
                        .blendMode(.softLight)
                        .opacity(0.05)
                        MetalBrushedLinesOverlay(
                            cornerRadius: cornerRadius,
                            spacing: 2.8,
                            thickness: 0.7,
                            color: metalBrushColor
                        )
                        .blendMode(.softLight)
                        .opacity(0.15)
                    }
                }
            }
            .allowsHitTesting(false)
        }
    }
}

private extension CardMaterialBackground {
    var shouldUseMaterial: Bool {
        themeManager.selectedTheme.usesGlassMaterials && colorSchemeContrast != .increased
    }

    func materialFill(for size: CGSize) -> AnyShapeStyle {
        guard shouldUseMaterial else {
            return theme.backgroundStyle(for: themeManager.selectedTheme)
        }
        switch effect {
        case .plastic:
            return AnyShapeStyle(plasticGradient(for: size))
        case .metal:
            return AnyShapeStyle(metalGradient)
        case .holographic:
            return AnyShapeStyle(theme.backgroundStyle(for: themeManager.selectedTheme))
        case .glass:
            return AnyShapeStyle(theme.backgroundStyle(for: themeManager.selectedTheme))
        }
    }

    var materialSaturation: Double {
        guard shouldUseMaterial else { return 1.0 }
        switch effect {
        case .metal:
            return 0.48
        case .holographic:
            return 1.22
        case .plastic:
            return 1.0
        case .glass:
            return 1.0
        }
    }

    func materialOverlayColor(for size: CGSize) -> Color {
        if !shouldUseMaterial {
            return theme.adaptiveOverlay(for: colorScheme, isHighContrast: colorSchemeContrast == .increased)
        }
        if effect == .plastic {
            return plasticOverlayColor(for: size)
        }
        if effect == .holographic {
            return holographicOverlayColor(for: size)
        }
        return theme.adaptiveOverlay(for: colorScheme, isHighContrast: colorSchemeContrast == .increased)
    }

    @ViewBuilder
    func glassSurface(for size: CGSize) -> some View {
        let shape = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
        let tint = glassTint
        let rim = glassRim
        let effectTint = tint.opacity(glassTintOverlayOpacity(for: size))
        let specular = glassSpecularOverlay(for: size)
        let specularSecondary = glassSpecularSecondaryOverlay(for: size)
        let base = shape
            .fill(theme.backgroundStyle(for: themeManager.selectedTheme))
            .saturation(glassBaseSaturation)
            .brightness(glassBaseBrightness)
        if #available(iOS 26.0, macCatalyst 26.0, macOS 26.0, *), shouldUseMaterial {
            ZStack {
                base
                Color.clear
                    .glassEffect(.regular.tint(effectTint), in: shape)
                    .opacity(0.96)
                shape.fill(specular)
                    .blendMode(.screen)
                shape.fill(specularSecondary)
                    .blendMode(.screen)
                    .opacity(0.65)
            }
            .overlay(shape.stroke(rim, lineWidth: 1))
        } else {
            ZStack {
                base
                shape.fill(glassFallbackStyle)
                shape.fill(effectTint)
                shape.fill(specular)
                    .blendMode(.screen)
                shape.fill(specularSecondary)
                    .blendMode(.screen)
                    .opacity(0.65)
            }
            .overlay(shape.stroke(rim, lineWidth: 1))
        }
    }

    var glassThemeTint: Color {
        let (top, bottom) = theme.colors
        let mid = mix(top, with: bottom, amount: 0.5)
        let saturationBoost = colorScheme == .dark ? 0.06 : 0.12
        let brightnessBoost = colorScheme == .dark ? 0.08 : 0.04
        return adjustedColor(mid, brightnessDelta: brightnessBoost, saturationDelta: saturationBoost)
    }

    var glassTint: Color {
        let accent = themeManager.selectedTheme.glassPalette.accent
        let blend = colorScheme == .dark ? 0.60 : 0.68
        return mix(accent, with: glassThemeTint, amount: blend)
    }

    var glassRim: Color {
        let rimBase = themeManager.selectedTheme.glassPalette.rim
        let rimTint = adjustedColor(glassThemeTint, brightnessDelta: 0.04, saturationDelta: -0.04)
        let mixed = mix(rimBase, with: rimTint, amount: 0.28)
        let opacity = colorScheme == .dark ? 0.32 : 0.26
        return mixed.opacity(opacity)
    }

    var glassTintOpacityScale: Double {
        0.42
    }

    func glassTintOverlayOpacity(for size: CGSize) -> Double {
        let sizeFactor = materialSizeFactor(for: size)
        let baseOpacity = colorScheme == .dark ? 0.28 : 0.24
        let sizeBoost = 0.08 * sizeFactor
        return min(0.46, (baseOpacity + sizeBoost) * glassTintOpacityScale)
    }

    var glassBaseSaturation: Double {
        colorScheme == .dark ? 0.92 : 0.94
    }

    var glassBaseBrightness: Double {
        colorScheme == .dark ? 0.01 : 0.03
    }

    func glassSpecularOverlay(for size: CGSize) -> LinearGradient {
        let specular = themeManager.selectedTheme.glassPalette.specular
        let sizeFactor = materialSizeFactor(for: size)
        let baseOpacity = colorScheme == .dark ? 0.36 : 0.30
        let strength = baseOpacity * (0.92 + 0.08 * sizeFactor)
        let stops: [Gradient.Stop] = [
            .init(color: specular.opacity(strength), location: 0.0),
            .init(color: specular.opacity(strength * 0.7), location: 0.34),
            .init(color: specular.opacity(strength * 0.30), location: 0.68),
            .init(color: specular.opacity(0.0), location: 0.96)
        ]
        let shift = glassSpecularShift(for: size)
        return glassSpecularGradient(
            angle: glassSpecularAnglePrimary,
            shift: shift,
            stops: stops,
            length: 0.92
        )
    }

    func glassSpecularSecondaryOverlay(for size: CGSize) -> LinearGradient {
        let specular = themeManager.selectedTheme.glassPalette.specular
        let sizeFactor = materialSizeFactor(for: size)
        let baseOpacity = colorScheme == .dark ? 0.20 : 0.16
        let strength = baseOpacity * (0.90 + 0.10 * sizeFactor)
        let stops: [Gradient.Stop] = [
            .init(color: specular.opacity(strength * 0.7), location: 0.0),
            .init(color: specular.opacity(strength * 0.45), location: 0.42),
            .init(color: specular.opacity(0.0), location: 0.88)
        ]
        let baseShift = glassSpecularShift(for: size)
        let secondaryShift = CGSize(width: baseShift.width * 0.6, height: baseShift.height * 0.6)
        return glassSpecularGradient(
            angle: glassSpecularAngleSecondary,
            shift: secondaryShift,
            stops: stops,
            length: 0.80
        )
    }

    var glassSpecularAnglePrimary: Angle {
        plasticAngle
    }

    var glassSpecularAngleSecondary: Angle {
        .degrees(glassSpecularAnglePrimary.degrees + 16.0)
    }

    func glassSpecularShift(for size: CGSize) -> CGSize {
        let base = plasticShift(for: size)
        return CGSize(width: base.width * 0.9, height: base.height * 0.9)
    }

    func glassSpecularGradient(
        angle: Angle,
        shift: CGSize,
        stops: [Gradient.Stop],
        length: Double
    ) -> LinearGradient {
        materialGradient(angle: angle, shift: shift, stops: stops, length: length)
    }
    var glassFallbackStyle: AnyShapeStyle {
        #if os(iOS) || targetEnvironment(macCatalyst) || os(macOS)
        if #available(iOS 15.0, macCatalyst 15.0, macOS 12.0, *) {
            return themeManager.glassConfiguration.glass.material.shapeStyle
        }
        #endif
        return AnyShapeStyle(Color.white.opacity(0.12))
    }

    func plasticOverlayColor(for size: CGSize) -> Color {
        let baseColor = colorScheme == .dark
            ? Color(white: 0.18)
            : Color(white: 0.98)
        let sizeFactor = materialSizeFactor(for: size)
        let baseOpacity = (colorScheme == .dark ? 0.06 : 0.015) * (1.0 - 0.90 * sizeFactor)
        return baseColor.opacity(baseOpacity)
    }

    func holographicOverlayColor(for size: CGSize) -> Color {
        let baseColor = colorScheme == .dark
            ? Color(white: 0.14)
            : Color(white: 0.99)
        let sizeFactor = materialSizeFactor(for: size)
        let baseOpacity = (colorScheme == .dark ? 0.025 : 0.006) * (1.0 - 0.65 * sizeFactor)
        return baseColor.opacity(baseOpacity)
    }

    func plasticGradient(for size: CGSize) -> LinearGradient {
        let (top, bottom) = theme.colors
        let sizeFactor = materialSizeFactor(for: size)
        let soften = 1.0 - 0.55 * sizeFactor
        let baseLift = colorScheme == .dark ? 0.06 : 0.08
        let baseDrop = colorScheme == .dark ? -0.05 : -0.06
        let motionBoost = motionMagnitude * 0.10
        let lift = (baseLift + motionBoost) * soften
        let drop = (baseDrop - motionBoost * 0.4) * soften
        let topSheen = adjustedColor(top, brightnessDelta: lift, saturationDelta: -0.02)
        let bottomSheen = adjustedColor(bottom, brightnessDelta: drop, saturationDelta: -0.02)
        let mid = mix(top, with: bottom, amount: 0.5)
        let stops: [Gradient.Stop] = [
            .init(color: topSheen, location: 0.0),
            .init(color: mid, location: 0.50),
            .init(color: bottomSheen, location: 1.0)
        ]
        return materialGradient(angle: plasticAngle, shift: plasticShift(for: size), stops: stops)
    }

    func holographicGradient(for size: CGSize) -> LinearGradient {
        let (top, bottom) = theme.colors
        let sizeFactor = holographicSizeFactor(for: size)
        let soften = 1.0 - 0.18 * sizeFactor
        let baseBoost = colorScheme == .dark ? 0.08 : 0.10
        let motionBoost = holographicMotionMagnitude * (colorScheme == .dark ? 0.60 : 0.68)
        let highlightBoost = min(0.54, (baseBoost + motionBoost) * soften)
        let extremeBoost = min(0.72, (baseBoost + motionBoost + 0.08) * soften)
        let midBrightBoost = highlightBoost + (extremeBoost - highlightBoost) * holographicBandAttenuation
        let stopShift = holographicStopShift(for: size)

        let mid = mix(top, with: bottom, amount: 0.5)
        let topEdge = adjustedColor(top, brightnessDelta: highlightBoost * 0.50, saturationDelta: -0.08)
        let bottomEdge = adjustedColor(bottom, brightnessDelta: highlightBoost * 0.50, saturationDelta: -0.08)
        let topSoft = adjustedColor(top, brightnessDelta: highlightBoost * 0.70, saturationDelta: -0.06)
        let bottomSoft = adjustedColor(bottom, brightnessDelta: highlightBoost * 0.70, saturationDelta: -0.06)
        let midSoft = adjustedColor(mid, brightnessDelta: highlightBoost, saturationDelta: -0.08)
        let midBright = adjustedColor(mid, brightnessDelta: midBrightBoost, saturationDelta: -0.10)

        func shifted(_ value: Double) -> Double {
            min(0.90, max(0.12, value + stopShift))
        }

        let stops: [Gradient.Stop] = [
            .init(color: top, location: 0.0),
            .init(color: top, location: 0.02),
            .init(color: topEdge, location: 0.10),
            .init(color: topSoft, location: shifted(0.30)),
            .init(color: midSoft, location: shifted(0.46)),
            .init(color: midBright, location: shifted(0.56)),
            .init(color: midSoft, location: shifted(0.70)),
            .init(color: bottomSoft, location: shifted(0.86)),
            .init(color: bottomEdge, location: 0.97),
            .init(color: bottom, location: 1.0)
        ]
        return materialGradient(
            angle: holographicAngle,
            shift: holographicShift(for: size),
            stops: stops,
            length: 1.0
        )
    }

    func holographicFoilOverlay(for size: CGSize) -> LinearGradient {
        let (top, bottom) = theme.colors
        let sizeFactor = holographicSizeFactor(for: size)
        let soften = 1.0 - 0.20 * sizeFactor
        let baseBoost = colorScheme == .dark ? 0.10 : 0.12
        let motionBoost = holographicMotionMagnitude * (colorScheme == .dark ? 0.55 : 0.62)
        let highlightBoost = min(0.62, (baseBoost + motionBoost) * soften)
        let stopShift = holographicStopShift(for: size)

        let mid = mix(top, with: bottom, amount: 0.5)
        let shadow = adjustedColor(mid, brightnessDelta: -0.08, saturationDelta: -0.10).opacity(0.0)
        let soft = adjustedColor(mid, brightnessDelta: highlightBoost * 0.42, saturationDelta: -0.06).opacity(0.26)
        let bright = adjustedColor(mid, brightnessDelta: highlightBoost * 0.80, saturationDelta: -0.03).opacity(0.52)

        func shifted(_ value: Double) -> Double {
            min(0.88, max(0.12, value + stopShift))
        }

        let stops: [Gradient.Stop] = [
            .init(color: shadow, location: 0.0),
            .init(color: soft, location: shifted(0.24)),
            .init(color: bright, location: shifted(0.40)),
            .init(color: bright, location: shifted(0.62)),
            .init(color: soft, location: shifted(0.78)),
            .init(color: shadow, location: 1.0)
        ]

        return LinearGradient(gradient: Gradient(stops: stops), startPoint: .top, endPoint: .bottom)
    }

    func holographicFoilOverlayOpacity(for size: CGSize) -> Double {
        let sizeFactor = holographicSizeFactor(for: size)
        let baseOpacity = (colorScheme == .dark ? 0.40 : 0.34) * (1.0 - 0.15 * sizeFactor)
        let motionBoost = holographicMotionMagnitude * (colorScheme == .dark ? 0.32 : 0.36)
        return min(0.86, baseOpacity + motionBoost)
    }

    func holographicRainbowOverlay(for size: CGSize) -> RadialGradient {
        let (top, bottom) = theme.colors
        let mid = mix(top, with: bottom, amount: 0.5)
        let center = holographicRainbowCenter
        let minDimension = min(size.width, size.height)
        let endRadius = max(140, minDimension * 1.9)
        let stops = holographicRainbowStops(base: mid)
        return RadialGradient(
            gradient: Gradient(stops: stops),
            center: center,
            startRadius: 0,
            endRadius: endRadius
        )
    }

    func holographicRainbowOverlayOpacity(for size: CGSize) -> Double {
        let sizeFactor = holographicSizeFactor(for: size)
        let baseOpacity = (colorScheme == .dark ? 0.34 : 0.28) * (1.0 - 0.12 * sizeFactor)
        let motionBoost = holographicMotionMagnitude * (colorScheme == .dark ? 0.30 : 0.34)
        return min(0.75, baseOpacity + motionBoost)
    }

    func holographicRainbowStops(base: Color) -> [Gradient.Stop] {
        let colors: [Color] = [
            Color(red: 1.00, green: 0.55, blue: 0.75),
            Color(red: 1.00, green: 0.75, blue: 0.35),
            Color(red: 0.98, green: 0.95, blue: 0.48),
            Color(red: 0.45, green: 0.95, blue: 0.70),
            Color(red: 0.35, green: 0.85, blue: 1.00),
            Color(red: 0.55, green: 0.60, blue: 1.00),
            Color(red: 0.85, green: 0.55, blue: 1.00)
        ]
        let stops: [Gradient.Stop] = colors.enumerated().map { index, color in
            let t = (Double(index) / Double(max(colors.count - 1, 1))) * 0.92
            let mixed = mix(color, with: base, amount: 0.40).opacity(0.45)
            return Gradient.Stop(color: mixed, location: t)
        }
        return stops + [
            Gradient.Stop(color: base.opacity(0.15), location: 0.96),
            Gradient.Stop(color: base.opacity(0.0), location: 1.0)
        ]
    }

    func holographicRingMetrics(for size: CGSize) -> (inset: CGFloat, thickness: CGFloat) {
        let sizeFactor = holographicSizeFactor(for: size)
        let thickness = min(6.0, max(4.0, 4.0 + (2.0 * sizeFactor)))
        let inset = min(6.0, max(3.0, 3.0 + (2.0 * sizeFactor)))
        return (inset, thickness)
    }

    func holographicRingRimOpacity(for size: CGSize) -> Double {
        let sizeFactor = holographicSizeFactor(for: size)
        let baseOpacity = (colorScheme == .dark ? 0.36 : 0.30) * (1.0 - 0.15 * sizeFactor)
        let motionBoost = holographicMotionMagnitude * (colorScheme == .dark ? 0.20 : 0.24)
        return min(0.70, baseOpacity + motionBoost)
    }

    func holographicRingFillOpacity(for size: CGSize) -> Double {
        let sizeFactor = holographicSizeFactor(for: size)
        let baseOpacity = (colorScheme == .dark ? 0.20 : 0.16) * (1.0 - 0.12 * sizeFactor)
        let motionBoost = holographicMotionMagnitude * (colorScheme == .dark ? 0.18 : 0.20)
        return min(0.45, baseOpacity + motionBoost)
    }

    var metalGradient: LinearGradient {
        let base = metalBaseColor
        let highlight = metalHighlightColor
        let shadow = metalShadowColor
        let stops: [Gradient.Stop] = [
            .init(color: base, location: 0.0),
            .init(color: highlight, location: 0.40),
            .init(color: base, location: 0.62),
            .init(color: shadow, location: 1.0)
        ]
        return materialGradient(angle: metalAngle, shift: metalShift, stops: stops)
    }

    var metalBrushColor: Color {
        adjustedColor(metalBaseColor, brightnessDelta: colorScheme == .dark ? 0.05 : -0.04, saturationDelta: -0.05)
    }

    var metalBaseColor: Color {
        let (top, bottom) = theme.colors
        let mid = mix(top, with: bottom, amount: 0.5)
        let neutral = colorScheme == .dark ? Color(white: 0.22) : Color(white: 0.90)
        return mix(mid, with: neutral, amount: 0.24)
    }

    var metalHighlightColor: Color {
        adjustedColor(metalBaseColor, brightnessDelta: colorScheme == .dark ? 0.06 : 0.04, saturationDelta: -0.03)
    }

    var metalShadowColor: Color {
        adjustedColor(metalBaseColor, brightnessDelta: colorScheme == .dark ? -0.05 : -0.04, saturationDelta: -0.04)
    }

    var metalBandHighlight: Color {
        adjustedColor(metalBaseColor, brightnessDelta: colorScheme == .dark ? 0.04 : 0.03, saturationDelta: -0.05)
    }

    var metalBandShadow: Color {
        adjustedColor(metalBaseColor, brightnessDelta: colorScheme == .dark ? -0.03 : -0.02, saturationDelta: -0.05)
    }

    func materialGradient(angle: Angle, shift: CGSize, stops: [Gradient.Stop], length: Double = 0.7) -> LinearGradient {
        let theta = angle.radians
        let dx = cos(theta)
        let dy = sin(theta)
        let span = max(0.4, min(1.0, length))
        let startX = clampedUnit(0.5 - dx * span + Double(shift.width))
        let startY = clampedUnit(0.5 - dy * span + Double(shift.height))
        let endX = clampedUnit(0.5 + dx * span + Double(shift.width))
        let endY = clampedUnit(0.5 + dy * span + Double(shift.height))
        return LinearGradient(
            gradient: Gradient(stops: stops),
            startPoint: UnitPoint(x: startX, y: startY),
            endPoint: UnitPoint(x: endX, y: endY)
        )
    }

    func clampedUnit(_ value: Double) -> Double {
        min(1.0, max(0.0, value))
    }

    func materialSizeFactor(for size: CGSize) -> Double {
        let minDimension = max(1.0, min(Double(size.width), Double(size.height)))
        let t = (minDimension - 80.0) / 140.0
        return min(1.0, max(0.0, t))
    }

    func holographicSizeFactor(for size: CGSize) -> Double {
        let minDimension = max(1.0, min(Double(size.width), Double(size.height)))
        let t = (minDimension - 80.0) / 260.0
        return min(1.0, max(0.0, t))
    }

    func rgbaComponents(from color: Color) -> (Double, Double, Double, Double)? {
        let platformColor = UIColor(color)
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        guard platformColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha) else { return nil }
        return (Double(red), Double(green), Double(blue), Double(alpha))
    }

    func hsbaComponents(from color: Color) -> (Double, Double, Double, Double)? {
        let platformColor = UIColor(color)
        var hue: CGFloat = 0
        var saturation: CGFloat = 0
        var brightness: CGFloat = 0
        var alpha: CGFloat = 0
        guard platformColor.getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha) else {
            return nil
        }
        return (Double(hue), Double(saturation), Double(brightness), Double(alpha))
    }

    func mix(_ color: Color, with other: Color, amount: Double) -> Color {
        guard let a = rgbaComponents(from: color), let b = rgbaComponents(from: other) else { return color }
        let t = max(0, min(1, amount))
        let red = a.0 + (b.0 - a.0) * t
        let green = a.1 + (b.1 - a.1) * t
        let blue = a.2 + (b.2 - a.2) * t
        let alpha = a.3 + (b.3 - a.3) * t
        return Color(red: red, green: green, blue: blue, opacity: alpha)
    }

    func adjustedColor(_ color: Color, brightnessDelta: Double, saturationDelta: Double) -> Color {
        guard let hsba = hsbaComponents(from: color) else { return color }
        let hue = hsba.0
        let saturation = min(1.0, max(0.0, hsba.1 + saturationDelta))
        let brightness = min(1.0, max(0.0, hsba.2 + brightnessDelta))
        return Color(hue: hue, saturation: saturation, brightness: brightness, opacity: hsba.3)
    }
}

// MARK: - Motion → Parameters
private extension CardMaterialBackground {
    struct GravitySample {
        let x: Double
        let y: Double
        let z: Double
    }

    var gravitySample: GravitySample {
        GravitySample(
            x: motion.displayGravityX,
            y: motion.displayGravityY,
            z: motion.displayGravityZ
        )
    }

    var horizontalMagnitude: Double {
        let g = gravitySample
        let magnitude = sqrt(g.x * g.x + g.y * g.y)
        return min(1.0, max(0.0, magnitude))
    }

    var faceUpAttenuation: Double {
        let absZ = min(1.0, max(0.0, abs(gravitySample.z)))
        let faceUpStart: Double = 0.9
        let faceUpEnd: Double = 0.98
        if absZ <= faceUpStart { return 1.0 }
        if absZ >= faceUpEnd { return 0.0 }
        let progress = (absZ - faceUpStart) / (faceUpEnd - faceUpStart)
        return max(0.0, min(1.0, 1.0 - progress))
    }

    var gravityDrivenMagnitude: Double {
        let base = horizontalMagnitude
        guard base >= 0.02 else { return 0 }
        return base * faceUpAttenuation
    }

    var horizontalAngleDegrees: Double? {
        guard gravityDrivenMagnitude > 0 else { return nil }
        let g = gravitySample
        return atan2(g.y, g.x) * 180.0 / .pi
    }

    var usesMotion: Bool {
        #if os(iOS) || targetEnvironment(macCatalyst)
        return enableMotion && !reduceMotion && gravityDrivenMagnitude > 0
        #else
        return false
        #endif
    }

    var motionMagnitude: Double {
        #if os(iOS) || targetEnvironment(macCatalyst)
        guard enableMotion && !reduceMotion else { return 0 }
        return gravityDrivenMagnitude
        #else
        return 0
        #endif
    }

    var plasticAngle: Angle {
        guard let baseAngle = horizontalAngleDegrees, usesMotion else { return .degrees(-45) }
        return .degrees(baseAngle - 45.0)
    }

    func plasticShift(for size: CGSize) -> CGSize {
        guard usesMotion else { return .zero }
        let g = gravitySample
        let scale: Double = 0.08 * (1.0 - 0.75 * materialSizeFactor(for: size))
        return CGSize(
            width: max(-0.10, min(0.10, g.x * scale)),
            height: max(-0.10, min(0.10, -g.y * scale))
        )
    }

    var holographicAngle: Angle {
        .degrees(90)
    }

    var holographicSecondaryAngle: Angle {
        .degrees(0)
    }

    func holographicShift(for size: CGSize) -> CGSize {
        let base = plasticShift(for: size)
        return CGSize(width: base.width * 0.10, height: base.height * 0.10)
    }

    var holographicMotionMagnitude: Double {
        let damped = pow(motionMagnitude, 1.8)
        return damped * 0.60
    }

    var holographicBandAttenuation: Double {
        let magnitude = holographicMotionMagnitude
        let start: Double = 0.05
        let end: Double = 0.20
        if magnitude <= start { return 1.0 }
        if magnitude >= end { return 0.15 }
        let progress = (magnitude - start) / (end - start)
        return max(0.15, 1.0 - progress)
    }

    func holographicStopShift(for size: CGSize) -> Double {
        guard usesMotion else { return 0 }
        let g = gravitySample
        let direction = (g.y * 0.85) + (g.x * 0.35)
        let sizeFactor = holographicSizeFactor(for: size)
        let scale = (1.0 - 0.25 * sizeFactor)
        let raw = direction * (0.30 * holographicMotionMagnitude) * scale
        return min(0.08, max(-0.08, raw))
    }

    var holographicRainbowCenter: UnitPoint {
        let shift = holographicRainbowShift
        return UnitPoint(
            x: clampedUnit(0.5 + Double(shift.width)),
            y: clampedUnit(0.45 + Double(shift.height))
        )
    }

    var holographicRainbowShift: CGSize {
        guard usesMotion else { return .zero }
        let g = gravitySample
        let scale = 0.26 * holographicMotionMagnitude
        return CGSize(width: g.x * scale, height: -g.y * scale)
    }

    var metalAngle: Angle {
        guard let baseAngle = horizontalAngleDegrees, usesMotion else { return .degrees(0) }
        return .degrees(baseAngle * 0.08)
    }

    var metalShift: CGSize {
        guard usesMotion else { return .zero }
        let g = gravitySample
        let scale: Double = 0.03
        return CGSize(
            width: max(-0.05, min(0.05, g.x * scale)),
            height: max(-0.05, min(0.05, -g.y * scale))
        )
    }
}

// MARK: - MetalBrushedLinesOverlay
private struct MetalBrushedLinesOverlay: View {
    let cornerRadius: CGFloat
    let spacing: CGFloat
    let thickness: CGFloat
    let color: Color

    var body: some View {
        GeometryReader { proxy in
            let size = proxy.size
            Canvas { context, _ in
                var y: CGFloat = 0
                while y < size.height {
                    let rect = CGRect(x: 0, y: y, width: size.width, height: thickness)
                    context.fill(Path(rect), with: .color(color))
                    y += spacing
                }
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        .allowsHitTesting(false)
    }
}

// MARK: - MetalAnisotropicBandingOverlay
private struct MetalAnisotropicBandingOverlay: View {
    let cornerRadius: CGFloat
    let bandHeight: CGFloat
    let gap: CGFloat
    let highlight: Color
    let shadow: Color

    var body: some View {
        GeometryReader { proxy in
            let size = proxy.size
            Canvas { context, _ in
                var y: CGFloat = 0
                var index: Int = 0
                while y < size.height {
                    let rect = CGRect(x: 0, y: y, width: size.width, height: bandHeight)
                    let color = index.isMultiple(of: 2) ? highlight : shadow
                    context.fill(Path(rect), with: .color(color))
                    y += bandHeight + gap
                    index += 1
                }
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        .allowsHitTesting(false)
    }
}

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

    /// When true, applies the base neutral drop shadow beneath the card tile.
    /// Set to false for flat presentations (e.g., pickers and grids) while
    /// retaining the selection glow.
    var showsBaseShadow: Bool = true
    /// When true, overlays the selected card effect (e.g., subtle plastic sheen).
    var showsEffectOverlay: Bool = false

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

                // MARK: Card Background (material-aware)
                ZStack {
                    if showsEffectOverlay {
                        CardMaterialBackground(theme: card.theme, effect: card.effect, cornerRadius: cornerRadius)
                    } else {
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .fill(backgroundStyle)
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .fill(card.theme.adaptiveOverlay(for: colorScheme, isHighContrast: isHighContrast))
                        card.theme
                            .patternOverlay(cornerRadius: cornerRadius)
                            .blendMode(.overlay)
                    }
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

// MARK: - CardMaterialBackground
struct CardMaterialBackground: View {
    let theme: CardTheme
    let effect: CardEffect
    let cornerRadius: CGFloat
    @ObservedObject private var motion: MotionMonitor = MotionMonitor.shared
    @EnvironmentObject private var themeManager: ThemeManager
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.colorSchemeContrast) private var colorSchemeContrast
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        GeometryReader { proxy in
            let size = proxy.size
            ZStack {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(materialFill(for: size))
                    .saturation(materialSaturation)
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(materialOverlayColor(for: size))
                if effect == .metal && shouldUseMaterial {
                    MetalBrushedLinesOverlay(
                        cornerRadius: cornerRadius,
                        spacing: 2.8,
                        thickness: 0.7,
                        color: metalBrushColor
                    )
                    .blendMode(.softLight)
                    .opacity(0.35)
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
            return AnyShapeStyle(plasticGradient(for: size))
        }
    }

    var materialSaturation: Double {
        guard shouldUseMaterial else { return 1.0 }
        switch effect {
        case .metal:
            return 0.22
        case .plastic, .holographic:
            return 1.0
        }
    }

    func materialOverlayColor(for size: CGSize) -> Color {
        if !shouldUseMaterial {
            return theme.adaptiveOverlay(for: colorScheme, isHighContrast: colorSchemeContrast == .increased)
        }
        if effect == .plastic || effect == .holographic {
            return plasticOverlayColor(for: size)
        }
        return theme.adaptiveOverlay(for: colorScheme, isHighContrast: colorSchemeContrast == .increased)
    }

    func plasticOverlayColor(for size: CGSize) -> Color {
        let baseColor = colorScheme == .dark
            ? Color(white: 0.18)
            : Color(white: 0.98)
        let sizeFactor = materialSizeFactor(for: size)
        let baseOpacity = (colorScheme == .dark ? 0.06 : 0.015) * (1.0 - 0.90 * sizeFactor)
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

    var metalGradient: LinearGradient {
        let (top, bottom) = theme.colors
        let neutral = colorScheme == .dark ? Color(white: 0.14) : Color(white: 0.88)
        let flatTop = mix(top, with: neutral, amount: 0.55)
        let flatBottom = mix(bottom, with: neutral, amount: 0.55)
        let highlight = mix(neutral, with: .white, amount: colorScheme == .dark ? 0.20 : 0.12)
        let stops: [Gradient.Stop] = [
            .init(color: flatTop, location: 0.0),
            .init(color: highlight.opacity(0.30), location: 0.45),
            .init(color: flatBottom, location: 1.0)
        ]
        return materialGradient(angle: metalAngle, shift: metalShift, stops: stops)
    }

    var metalBrushColor: Color {
        colorScheme == .dark ? Color.white.opacity(0.10) : Color.black.opacity(0.08)
    }

    func materialGradient(angle: Angle, shift: CGSize, stops: [Gradient.Stop]) -> LinearGradient {
        let theta = angle.radians
        let dx = cos(theta)
        let dy = sin(theta)
        let startX = clampedUnit(0.5 - dx * 0.7 + Double(shift.width))
        let startY = clampedUnit(0.5 - dy * 0.7 + Double(shift.height))
        let endX = clampedUnit(0.5 + dx * 0.7 + Double(shift.width))
        let endY = clampedUnit(0.5 + dy * 0.7 + Double(shift.height))
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
        return !reduceMotion && gravityDrivenMagnitude > 0
        #else
        return false
        #endif
    }

    var motionMagnitude: Double {
        #if os(iOS) || targetEnvironment(macCatalyst)
        guard !reduceMotion else { return 0 }
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

    var metalAngle: Angle {
        guard let baseAngle = horizontalAngleDegrees, usesMotion else { return .degrees(90) }
        return .degrees(90.0 + baseAngle * 0.15)
    }

    var metalShift: CGSize {
        guard usesMotion else { return .zero }
        let g = gravitySample
        let scale: Double = 0.06
        return CGSize(
            width: max(-0.08, min(0.08, g.x * scale)),
            height: max(-0.08, min(0.08, -g.y * scale))
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

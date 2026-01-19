//
//  HolographicMetallicText.swift
//  SoFar
//
//  Metallic text effect (static; no Core Motion).
//  Matches the previous project's design: dark readable base text,
//  plus a masked metallic sweep + a narrower shine band.
//  On macOS, overlays are disabled and the base text stays legible.
//
//  Usage:
//  HolographicMetallicText(text: "Apple Card")
//      .lineLimit(1)
//      .minimumScaleFactor(0.8)
//

import SwiftUI

// MARK: - HolographicMetallicText
/// Draws a shiny, metallic label using a static “foil” overlay (no time loop, no device motion).
/// - Parameters:
///   - text: String displayed.
///   - titleFont: Text font. Defaults to rounded, semibold title.
///   - shimmerResponsiveness: Reserved for future use (kept for API compatibility).
///   - maxMetallicOpacity: Cap for the broad metallic sweep (0.0–1.0).
///   - maxShineOpacity: Cap for the narrow shine band (0.0–1.0).
@MainActor
struct HolographicMetallicText: View {
    // MARK: Inputs
    let text: String
    var titleFont: Font = Font.system(.title, design: .rounded).weight(.semibold)
    var shimmerResponsiveness: Double = 1.5
    var maxMetallicOpacity: Double = 0.6
    var maxShineOpacity: Double = 0.7

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    // MARK: Body
    var body: some View {
        let titleView =
            Text(text)
                .font(titleFont)
                .multilineTextAlignment(.center)
                .foregroundStyle(UBTypography.cardTitleStatic)
                .ub_cardTitleShadow()

        #if os(iOS) || targetEnvironment(macCatalyst)
        // Static “foil” overlay. No motion observation, no animation loop.
        titleView
            .overlay(
                Rectangle()
                    .fill(UBDecor.metallicSilverLinear(angle: .degrees(115)))
                    .mask(titleView)
                    .opacity(max(0.0, min(1.0, maxMetallicOpacity))),
                alignment: .center
            )
            .overlay(
                Rectangle()
                    .fill(UBDecor.metallicShine(angle: .degrees(65), intensity: reduceMotion ? 0.65 : 0.85))
                    .mask(titleView)
                    .opacity(max(0.0, min(1.0, maxShineOpacity * 0.75))),
                alignment: .center
            )
        #else
        titleView
        #endif
    }
}

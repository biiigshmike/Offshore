//
//  DesignSystem.swift
//  SoFar
//  Created by Michael Brown on 8/8/25.
//

import SwiftUI
// MARK: Platform Color Imports
import UIKit

// MARK: - Overview
/// Central, minimal design token collection for spacing, radius, and colors.
///
/// Intent:
/// - Keep view code declarative by referencing tokens instead of hard values.
/// - Provide dynamic, system-aware colors without leaking UIKit into views.
/// - Maintain cross-platform friendliness (iOS, iPadOS, macCatalyst).

// MARK: - DesignSystem (Tokens)
/// Centralized design tokens and tiny helpers for spacing, radius, shadows, and colors.
/// SwiftUI-only types for cross-platform friendliness (iOS, iPadOS, macOS).
enum DesignSystem {

    // MARK: Spacing (pts)
    /// Spacing scale used throughout the UI. Values are in points and chosen to
    /// align with common iOS rhythm. Prefer these over magic numbers.
    enum Spacing {
        static let xs: CGFloat = Offshore.Spacing.xs
        static let s: CGFloat = Offshore.Spacing.s
        static let m: CGFloat = Offshore.Spacing.m
        static let l: CGFloat = Offshore.Spacing.l
        static let xl: CGFloat = Offshore.Spacing.xl
        static let xxl: CGFloat = Offshore.Spacing.xxl
    }

    // MARK: Corner Radii
    /// Corner radius tokens for common components.
    enum Radius {
        /// Rounded card/container corners.
        static let card: CGFloat = Offshore.Radius.card
    }

    // MARK: Colors
    /// Color tokens including accents and neutrals. Prefer these over hardcoded
    /// `Color` literals so global adjustments remain centralized.
    enum Colors {
        // Accent hues
        /// Planned income series/accent.
        static let plannedIncome: Color = Offshore.Colors.plannedIncome
        /// Actual income series/accent.
        static let actualIncome: Color = Offshore.Colors.actualIncome
        /// Positive savings/accent.
        static let savingsGood: Color = Offshore.Colors.savingsGood
        /// Negative savings/accent.
        static let savingsBad: Color = Offshore.Colors.savingsBad

        // Neutrals
        /// Subtle card/container fill over grouped/system backgrounds.
        static let cardFill: Color = Offshore.Colors.cardFill

        // MARK: System‑Aware Container Background
        /// A dynamic background color that adapts to light/dark mode across UIKit platforms.
        /// Use behind pickers, lists, or lightweight surfaces to ensure contrast with content.
        static var containerBackground: Color {
            Offshore.Colors.containerBackground
        }

        // MARK: Chip and Pill Fills
        /// Default fill color for unselected category chips and pills.  This neutral
        /// tone ensures that chips sit comfortably on top of the form’s grouped
        /// background on all platforms.  Increase or decrease the opacity to tune
        /// the visual weight of chips globally.
        static var chipFill: Color {
            Offshore.Colors.chipFill
        }

        /// Fill color for selected category chips and pills.  This uses a slightly
        /// higher opacity of the primary color to indicate selection without
        /// overpowering the interface.  If you wish to refine the selection
        /// contrast across themes, update this constant instead of hardcoding
        /// values in your views.
        static var chipSelectedFill: Color {
            Offshore.Colors.chipSelectedFill
        }

        /// Stroke color for the selection outline around a chip or pill.  Using
        /// a separate constant allows you to globally adjust the stroke strength
        /// independent of the fill opacity.  When unselected, you may choose to
        /// return `.clear` or a low‑opacity stroke for subtle definition.
        static var chipSelectedStroke: Color {
            Offshore.Colors.chipSelectedStroke
        }

        /// Generates a dynamic neutral color that keeps light mode behavior intact
        /// while resolving to a richer, darker fill in dark mode. The `opacity`
        /// value mirrors the historical hierarchy so existing design intent is
        /// preserved.
        /// Produces a chip neutral that tracks `UIColor.label` in light mode and blends
        /// label into background in dark mode to avoid overly bright pills.
        /// - Parameter opacity: Relative opacity used to mix label/background.
        private static func dynamicChipNeutral(opacity: CGFloat) -> Color {
            if #available(iOS 13.0, macCatalyst 13.0, *) {
                let dynamicColor = UIColor { traitCollection in
                    let resolvedLabel = UIColor.label.resolvedColor(with: traitCollection)
                    guard traitCollection.userInterfaceStyle == .dark else {
                        return resolvedLabel.withAlphaComponent(opacity)
                    }

                    let resolvedBackground = UIColor.systemBackground.resolvedColor(with: traitCollection)
                    if let blended = UIColor.ds_blend(resolvedBackground, with: resolvedLabel, fraction: opacity) {
                        return blended
                    } else {
                        return resolvedLabel.withAlphaComponent(opacity)
                    }
                }
                return Color(dynamicColor)
            } else {
                return Color.black.opacity(Double(opacity))
            }
        }
    }
}

// Maintain compatibility with existing views using `DS`
/// Alias for `DesignSystem` to keep call sites terse and readable.
typealias DS = DesignSystem

// MARK: - Private Helpers

fileprivate extension UIColor {
    /// Linearly interpolates between two UIColors in sRGB space.
    /// - Parameters:
    ///   - base: Starting color (fraction = 0).
    ///   - with: Target color (fraction = 1).
    ///   - fraction: Mix amount in 0...1.
    /// - Returns: A blended color or `nil` if components couldn’t be extracted.
    static func ds_blend(_ base: UIColor, with other: UIColor, fraction: CGFloat) -> UIColor? {
        let t = max(0, min(1, fraction))
        var br: CGFloat = 0, bg: CGFloat = 0, bb: CGFloat = 0, ba: CGFloat = 0
        var or: CGFloat = 0, og: CGFloat = 0, ob: CGFloat = 0, oa: CGFloat = 0

        guard base.getRed(&br, green: &bg, blue: &bb, alpha: &ba),
              other.getRed(&or, green: &og, blue: &ob, alpha: &oa) else {
            return nil
        }

        let r = br + (or - br) * t
        let g = bg + (og - bg) * t
        let b = bb + (ob - bb) * t
        let a = ba + (oa - ba) * t

        return UIColor(red: r, green: g, blue: b, alpha: a)
    }
}

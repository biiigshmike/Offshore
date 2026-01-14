import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

// MARK: - Colors
/// DesignSystemV2 color/style tokens (Settings scope).
///
/// This file is intentionally small and only includes expressions that repeat
/// across Settings and Settings destinations.
enum Colors {
    static let clear: Color = .clear
    static let grayOpacity02: Color = Color.gray.opacity(0.2)
    static let primaryOpacity008: Color = Color.primary.opacity(0.08)
    static let secondaryOpacity008: Color = Color.secondary.opacity(0.08)
    static let secondaryOpacity012: Color = Color.secondary.opacity(0.12)
    static let secondaryOpacity018: Color = Color.secondary.opacity(0.18)
    static let plannedIncome: Color = .orange
    static let actualIncome: Color = .blue
    static let white: Color = .white

    static let stylePrimary: HierarchicalShapeStyle = .primary
    static let styleSecondary: HierarchicalShapeStyle = .secondary

    // MARK: Chip and Pill Fills
    static var chipFill: Color {
        dynamicChipNeutral(opacity: 0.06)
    }

    static var chipSelectedFill: Color {
        dynamicChipNeutral(opacity: 0.12)
    }

    static var chipSelectedStroke: Color {
        dynamicChipNeutral(opacity: 0.35)
    }

    private static func dynamicChipNeutral(opacity: CGFloat) -> Color {
        #if canImport(UIKit)
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
        #else
        return Color.black.opacity(Double(opacity))
        #endif
    }
}

#if canImport(UIKit)
// MARK: - Private Helpers

fileprivate extension UIColor {
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
#endif

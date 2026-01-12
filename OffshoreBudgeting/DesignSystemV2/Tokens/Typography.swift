import SwiftUI

// MARK: - Typography
/// DesignSystemV2 typography tokens (Settings scope).
///
/// This file is intentionally small and only includes font patterns that repeat
/// across Settings and Settings destinations.
enum Typography {
    static let body: Font = .body
    static let headline: Font = .headline
    static let subheadline: Font = .subheadline
    static let subheadlineSemibold: Font = .subheadline.weight(.semibold)
    static let footnote: Font = .footnote
    static let title3Semibold: Font = .title3.weight(.semibold)
    static let caption2Semibold: Font = .caption2.weight(.semibold)
}


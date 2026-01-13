import SwiftUI

// MARK: - Colors
/// DesignSystemV2 color/style tokens (Settings scope).
///
/// This file is intentionally small and only includes expressions that repeat
/// across Settings and Settings destinations.
enum Colors {
    static let clear: Color = .clear
    static let grayOpacity02: Color = Color.gray.opacity(0.2)
    static let primaryOpacity008: Color = Color.primary.opacity(0.08)
    static let secondaryOpacity012: Color = Color.secondary.opacity(0.12)
    static let secondaryOpacity018: Color = Color.secondary.opacity(0.18)
    static let plannedIncome: Color = .orange
    static let actualIncome: Color = .blue
    static let white: Color = .white

    static let stylePrimary: HierarchicalShapeStyle = .primary
    static let styleSecondary: HierarchicalShapeStyle = .secondary
}

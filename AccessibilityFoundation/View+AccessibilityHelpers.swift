import SwiftUI

public extension View {
    /// Applies a consistent accessibility label and hint for icon-only buttons.
    func iconButtonA11y(label: String, hint: String? = nil) -> some View {
        accessibilityLabel(Text(label))
            .accessibilityHint(Text(hint ?? AccessibilityFoundation.Constants.defaultButtonHint))
    }

    /// Hides decorative elements from accessibility.
    func hideDecorative() -> some View {
        accessibilityHidden(true)
    }

    /// Combines child elements into a single accessibility element.
    func combineChildrenForA11y() -> some View {
        accessibilityElement(children: .combine)
    }

    /// Provides a standard row label/value pairing for accessibility.
    func accessibilityRow(label: String, value: String, hint: String? = nil) -> some View {
        accessibilityElement(children: .ignore)
            .accessibilityLabel(Text(label))
            .accessibilityValue(Text(value))
            .accessibilityHint(Text(hint ?? AccessibilityFoundation.Constants.defaultRowHint))
    }
}

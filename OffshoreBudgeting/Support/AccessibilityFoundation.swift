import Foundation

/// App-wide accessibility goals
/// - Provide clear, consistent labels and hints for interactive elements.
/// - Ensure meaningful content is discoverable and decorative content is hidden.
/// - Keep accessibility changes additive and opt-in, preserving UI and behavior.
///
/// Helpers available
/// - See `View+AccessibilityHelpers.swift` for opt-in view modifiers.
/// - See `AccessibilityAnnouncements.swift` (if present) for manual announcements.
///
/// Do
/// - Use helpers to standardize labels, hints, and grouping.
/// - Prefer semantic descriptions over visual-only cues.
/// - Keep changes local to the view being updated.
///
/// Do not
/// - Change navigation, layout, or view hierarchy to apply accessibility.
/// - Add automatic announcements or side effects.
/// - Introduce new state, services, or view models for accessibility.
public enum AccessibilityFoundation {
    /// Namespace for shared constants.
    public enum Constants {
        public static let defaultButtonHint = "Activates the button."
        public static let defaultRowHint = "Shows more details."
    }
}

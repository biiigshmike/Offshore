//
//  AccessibilityFoundation.swift
//  OffshoreBudgeting
//
//  Shared accessibility helpers and conventions.
//

import SwiftUI

// MARK: - Accessibility Foundation
// DO: Prefer semantic SwiftUI controls and system colors.
// DO: Provide explicit labels for icon-only buttons and ambiguous actions.
// DO: Hide decorative images and combine complex rows intentionally.
// DO: Adapt motion, transparency, and contrast when accessibility settings change.
// DON'T: Rely on color alone to convey meaning.
// DON'T: Stack multiple labels that produce duplicate VoiceOver announcements.
// DON'T: Use fixed heights that clip text at Accessibility sizes.

enum AccessibilityFoundation {
    static let auditChecklist: [String] = [
        "All interactive controls reachable with VoiceOver.",
        "Icon-only controls have accessibilityLabel and hint as needed.",
        "Decorative images hidden.",
        "Rows/cards have a sensible combined announcement OR child elements are individually navigable.",
        "Focus order is logical.",
        "Dynamic Type: works at Accessibility sizes, no clipped essential content.",
        "Tap targets remain usable.",
        "Color is not the only differentiator.",
        "Contrast is acceptable in light/dark and increased contrast settings.",
        "Reduce Motion: avoids problematic motion triggers.",
        "Voice Control: labels are unique and speakable.",
        "Keyboard operability (especially on iPad + Catalyst).",
        "Charts have an accessible summary and a non-color-only explanation."
    ]
}

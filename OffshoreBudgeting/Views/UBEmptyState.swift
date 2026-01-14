//
//  UBEmptyState.swift
//  SoFar
//
//  A reusable, app-standard empty state view.
//  Matches the Cards screen styling: centered content,
//  supportive message, and a pill-shaped primary action.
//
//  Usage:
//  UBEmptyState(
//      title: "Cards",
//      message: "No cards found. Tap + to create a card.",
//      primaryButtonTitle: "Add your first card",
//      onPrimaryTap: { /* present add flow */ }
//  )
//

import SwiftUI

// MARK: - UBEmptyState
/// Standardized empty-state presentation with optional action buttons.
struct UBEmptyState: View {

    // MARK: Content
    /// SF Symbol name to display above the title.
    let iconSystemName: String?
    /// Main headline text.
    let title: String?
    /// Supporting copy below the title.
    let message: String

    // MARK: Actions
    /// Optional primary action button label; when nil, no button is shown.
    let primaryButtonTitle: String?
    /// Callback when the primary button is tapped.
    let onPrimaryTap: (() -> Void)?

    // MARK: Layout
    /// Optional width limit for message text; defaults to a comfortably readable width.
    let maxMessageWidth: CGFloat
    /// How the empty state content should align within its available container.
    /// Defaults to centered to preserve existing call sites.
    let containerAlignment: Alignment

    // MARK: init(...)
    /// Designated initializer.
    /// - Parameters:
    ///   - iconSystemName: SF Symbol name (e.g., "creditcard")
    ///   - title: Headline (e.g., "Cards")
    ///   - message: Supportive copy, 1–2 lines if possible
    ///   - primaryButtonTitle: Text for CTA; pass `nil` to omit
    ///   - onPrimaryTap: Closure invoked when CTA is tapped
    ///   - maxMessageWidth: Optional width limit for the message line-wrapping
    init(
        iconSystemName: String? = nil,
        title: String? = nil,
        message: String,
        primaryButtonTitle: String? = nil,
        onPrimaryTap: (() -> Void)? = nil,
        maxMessageWidth: CGFloat = 520,
        containerAlignment: Alignment = .center
    ) {
        self.iconSystemName = iconSystemName
        self.title = title
        self.message = message
        self.primaryButtonTitle = primaryButtonTitle
        self.onPrimaryTap = onPrimaryTap
        self.maxMessageWidth = maxMessageWidth
        self.containerAlignment = containerAlignment
    }

    // MARK: Body
    var body: some View {
        DesignSystemV2.EmptyState(
            iconSystemName: iconSystemName,
            title: title,
            message: message,
            primaryButtonTitle: primaryButtonTitle,
            onPrimaryTap: onPrimaryTap,
            maxMessageWidth: maxMessageWidth,
            containerAlignment: containerAlignment
        )
    }
}

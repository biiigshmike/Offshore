//
//  View+AccessibilityHelpers.swift
//  OffshoreBudgeting
//
//  Shared view modifiers for consistent accessibility behavior.
//

import SwiftUI

extension View {
    func iconButtonA11y(label: String, hint: String? = nil) -> some View {
        self
            .accessibilityLabel(Text(label))
            .ifLet(hint) { view, hint in
                view.accessibilityHint(Text(hint))
            }
            .accessibilityAddTraits(.isButton)
    }

    func hideDecorative() -> some View {
        accessibilityHidden(true)
    }

    func combine(children behavior: AccessibilityChildBehavior = .combine) -> some View {
        accessibilityElement(children: behavior)
    }

    func chartA11ySummary(
        title: String,
        range: String? = nil,
        breakdown: String? = nil,
        hint: String? = nil
    ) -> some View {
        let value = [range, breakdown]
            .compactMap { value in
                guard let value, !value.isEmpty else { return nil }
                return value
            }
            .joined(separator: ". ")
        return self
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(Text(title))
            .if(!value.isEmpty) { view in
                view.accessibilityValue(Text(value))
            }
            .ifLet(hint) { view, hint in
                view.accessibilityHint(Text(hint))
            }
    }

    func a11yMoveUpDownActions(
        canMoveUp: Bool,
        canMoveDown: Bool,
        moveUp: @escaping () -> Void,
        moveDown: @escaping () -> Void
    ) -> some View {
        self
            .if(canMoveUp) { view in
                view.accessibilityAction(named: Text("Move Up"), moveUp)
            }
            .if(canMoveDown) { view in
                view.accessibilityAction(named: Text("Move Down"), moveDown)
            }
    }
}

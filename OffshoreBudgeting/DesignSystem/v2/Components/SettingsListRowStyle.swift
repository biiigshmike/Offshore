import SwiftUI

// MARK: - DesignSystemV2.SettingsListRowStyle
extension DesignSystemV2 {
    /// Settings-only list row chrome helpers.
    ///
    /// Intentional scope: `SettingsView.swift` and the destination views defined in that same file.
    /// Do not use this outside Settings without an explicit scope decision.
    enum SettingsListRowBackground {
        case colorsClear
        case colorClear
        case none
    }

    struct SettingsListRowStyle: ViewModifier {
        let insets: Bool
        let background: SettingsListRowBackground
        // Included for future parity with Settings row chrome; keep unused unless SettingsView already uses it.
        let hideSeparator: Bool

        func body(content: Content) -> some View {
            applySeparator(
                applyBackground(
                    applyInsets(content)
                )
            )
        }

        @ViewBuilder
        private func applyInsets<V: View>(_ view: V) -> some View {
            if insets {
                view.listRowInsets(EdgeInsets())
            } else {
                view
            }
        }

        @ViewBuilder
        private func applyBackground<V: View>(_ view: V) -> some View {
            switch background {
            case .colorsClear:
                view.listRowBackground(Colors.clear)
            case .colorClear:
                view.listRowBackground(Color.clear)
            case .none:
                view
            }
        }

        @ViewBuilder
        private func applySeparator<V: View>(_ view: V) -> some View {
            if hideSeparator {
                view.listRowSeparator(.hidden)
            } else {
                view
            }
        }
    }
}

extension View {
    func settingsListRowStyle(
        insets: Bool = true,
        background: DesignSystemV2.SettingsListRowBackground = .none,
        hideSeparator: Bool = false
    ) -> some View {
        modifier(
            DesignSystemV2.SettingsListRowStyle(
                insets: insets,
                background: background,
                hideSeparator: hideSeparator
            )
        )
    }
}

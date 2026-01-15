import SwiftUI

// MARK: - DesignSystemV2.Toolbar (Settings scope)
extension DesignSystemV2 {
    /// Settings-only toolbar/button helpers.
    ///
    /// Intentional scope: `SettingsView.swift` and Settings destinations (e.g., Categories, Presets).
    enum Toolbar {
        static func plusButton(
            accessibilityLabel: String,
            accessibilityIdentifier: String? = nil,
            action: @escaping () -> Void
        ) -> some View {
            Group {
                if let accessibilityIdentifier = accessibilityIdentifier {
                    Button(action: action) {
                        Image(systemName: Icons.sfPlus)
                            .symbolRenderingMode(.monochrome)
                            .foregroundStyle(Colors.stylePrimary)
                            .font(.system(size: 17, weight: .semibold))
                            .frame(width: 33, height: 33)
                            .contentShape(Circle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(accessibilityLabel)
                    .accessibilityIdentifier(accessibilityIdentifier)
                } else {
                    Button(action: action) {
                        Image(systemName: Icons.sfPlus)
                            .symbolRenderingMode(.monochrome)
                            .foregroundStyle(Colors.stylePrimary)
                            .font(.system(size: 17, weight: .semibold))
                            .frame(width: 33, height: 33)
                            .contentShape(Circle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(accessibilityLabel)
                }
            }
        }

        static func prominentButton<Label: View>(
            tint: Color,
            accessibilityIdentifier: String? = nil,
            @ViewBuilder label: () -> Label,
            action: @escaping () -> Void
        ) -> some View {
            Group {
                if #available(iOS 26.0, macCatalyst 26.0, macOS 26.0, *) {
                    if let accessibilityIdentifier = accessibilityIdentifier {
                        Button(action: action, label: label)
                            .buttonStyle(.glassProminent)
                            .tint(tint)
                            .listRowInsets(EdgeInsets())
                            .accessibilityIdentifier(accessibilityIdentifier)
                    } else {
                        Button(action: action, label: label)
                            .buttonStyle(.glassProminent)
                            .tint(tint)
                            .listRowInsets(EdgeInsets())
                    }
                } else {
                    if let accessibilityIdentifier = accessibilityIdentifier {
                        Button(action: action, label: label)
                            .buttonStyle(.plain)
                            .listRowInsets(EdgeInsets())
                            .accessibilityIdentifier(accessibilityIdentifier)
                    } else {
                        Button(action: action, label: label)
                            .buttonStyle(.plain)
                            .listRowInsets(EdgeInsets())
                    }
                }
            }
        }
    }
}

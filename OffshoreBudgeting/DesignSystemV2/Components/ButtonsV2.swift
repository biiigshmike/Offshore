import SwiftUI

// MARK: - DesignSystemV2.Buttons
extension DesignSystemV2 {
    /// Reusable, semantic button components for use across screens.
    ///
    /// Notes:
    /// - OS 26+ uses `.buttonStyle(.glassProminent)` with a provided tint.
    /// - Legacy behavior is preserved by passing a `legacyStyle` closure where needed.
    /// - Accessibility identifiers should remain at call sites.
    enum Buttons {

        // MARK: - PrimaryCTA
        struct PrimaryCTA<Label: View, LegacyStyled: View>: View {
            let tint: Color
            let useGlassIfAvailable: Bool
            let accessibilityLabel: Text?
            let action: () -> Void
            @ViewBuilder let label: () -> Label
            @ViewBuilder let legacyStyle: (_ button: Button<Label>) -> LegacyStyled

            init(
                tint: Color,
                useGlassIfAvailable: Bool = true,
                accessibilityLabel: Text? = nil,
                action: @escaping () -> Void,
                @ViewBuilder label: @escaping () -> Label,
                @ViewBuilder legacyStyle: @escaping (_ button: Button<Label>) -> LegacyStyled
            ) {
                self.tint = tint
                self.useGlassIfAvailable = useGlassIfAvailable
                self.accessibilityLabel = accessibilityLabel
                self.action = action
                self.label = label
                self.legacyStyle = legacyStyle
            }

            init(
                tint: Color,
                useGlassIfAvailable: Bool = true,
                accessibilityLabel: Text? = nil,
                action: @escaping () -> Void,
                @ViewBuilder label: @escaping () -> Label
            ) where LegacyStyled == PlainLegacyCTA<Label> {
                self.init(
                    tint: tint,
                    useGlassIfAvailable: useGlassIfAvailable,
                    accessibilityLabel: accessibilityLabel,
                    action: action,
                    label: label,
                    legacyStyle: { PlainLegacyCTA(button: $0) }
                )
            }

            var body: some View {
                Group {
                    if useGlassIfAvailable,
                       #available(iOS 26.0, macCatalyst 26.0, macOS 26.0, *) {
                        styledForGlass
                    } else {
                        styledForLegacy
                    }
                }
            }

            @available(iOS 26.0, macCatalyst 26.0, macOS 26.0, *)
            private var styledForGlass: some View {
                let button = Button(action: action, label: label)
                return Group {
                    if let accessibilityLabel {
                        button
                            .buttonStyle(.glassProminent)
                            .tint(tint)
                            .accessibilityLabel(accessibilityLabel)
                    } else {
                        button
                            .buttonStyle(.glassProminent)
                            .tint(tint)
                    }
                }
            }

            private var styledForLegacy: some View {
                let button = Button(action: action, label: label)
                return Group {
                    if let accessibilityLabel {
                        legacyStyle(button).accessibilityLabel(accessibilityLabel)
                    } else {
                        legacyStyle(button)
                    }
                }
            }
        }

        // MARK: - SecondaryCTA
        struct SecondaryCTA<Label: View, LegacyStyled: View>: View {
            let tint: Color
            let useGlassIfAvailable: Bool
            let accessibilityLabel: Text?
            let action: () -> Void
            @ViewBuilder let label: () -> Label
            @ViewBuilder let legacyStyle: (_ button: Button<Label>) -> LegacyStyled

            init(
                tint: Color,
                useGlassIfAvailable: Bool = true,
                accessibilityLabel: Text? = nil,
                action: @escaping () -> Void,
                @ViewBuilder label: @escaping () -> Label,
                @ViewBuilder legacyStyle: @escaping (_ button: Button<Label>) -> LegacyStyled
            ) {
                self.tint = tint
                self.useGlassIfAvailable = useGlassIfAvailable
                self.accessibilityLabel = accessibilityLabel
                self.action = action
                self.label = label
                self.legacyStyle = legacyStyle
            }

            init(
                tint: Color,
                useGlassIfAvailable: Bool = true,
                accessibilityLabel: Text? = nil,
                action: @escaping () -> Void,
                @ViewBuilder label: @escaping () -> Label
            ) where LegacyStyled == PlainLegacyCTA<Label> {
                self.init(
                    tint: tint,
                    useGlassIfAvailable: useGlassIfAvailable,
                    accessibilityLabel: accessibilityLabel,
                    action: action,
                    label: label,
                    legacyStyle: { PlainLegacyCTA(button: $0) }
                )
            }

            var body: some View {
                Group {
                    if useGlassIfAvailable,
                       #available(iOS 26.0, macCatalyst 26.0, macOS 26.0, *) {
                        styledForGlass
                    } else {
                        styledForLegacy
                    }
                }
            }

            @available(iOS 26.0, macCatalyst 26.0, macOS 26.0, *)
            private var styledForGlass: some View {
                let button = Button(action: action, label: label)
                return Group {
                    if let accessibilityLabel {
                        button
                            .buttonStyle(.glassProminent)
                            .tint(tint)
                            .accessibilityLabel(accessibilityLabel)
                    } else {
                        button
                            .buttonStyle(.glassProminent)
                            .tint(tint)
                    }
                }
            }

            private var styledForLegacy: some View {
                let button = Button(action: action, label: label)
                return Group {
                    if let accessibilityLabel {
                        legacyStyle(button).accessibilityLabel(accessibilityLabel)
                    } else {
                        legacyStyle(button)
                    }
                }
            }
        }

        // MARK: - DestructiveCTA
        struct DestructiveCTA<Label: View, LegacyStyled: View>: View {
            let tint: Color
            let useGlassIfAvailable: Bool
            let accessibilityLabel: Text?
            let action: () -> Void
            @ViewBuilder let label: () -> Label
            @ViewBuilder let legacyStyle: (_ button: Button<Label>) -> LegacyStyled

            init(
                tint: Color = .red,
                useGlassIfAvailable: Bool = true,
                accessibilityLabel: Text? = nil,
                action: @escaping () -> Void,
                @ViewBuilder label: @escaping () -> Label,
                @ViewBuilder legacyStyle: @escaping (_ button: Button<Label>) -> LegacyStyled
            ) {
                self.tint = tint
                self.useGlassIfAvailable = useGlassIfAvailable
                self.accessibilityLabel = accessibilityLabel
                self.action = action
                self.label = label
                self.legacyStyle = legacyStyle
            }

            init(
                tint: Color = .red,
                useGlassIfAvailable: Bool = true,
                accessibilityLabel: Text? = nil,
                action: @escaping () -> Void,
                @ViewBuilder label: @escaping () -> Label
            ) where LegacyStyled == PlainLegacyCTA<Label> {
                self.init(
                    tint: tint,
                    useGlassIfAvailable: useGlassIfAvailable,
                    accessibilityLabel: accessibilityLabel,
                    action: action,
                    label: label,
                    legacyStyle: { PlainLegacyCTA(button: $0) }
                )
            }

            var body: some View {
                Group {
                    if useGlassIfAvailable,
                       #available(iOS 26.0, macCatalyst 26.0, macOS 26.0, *) {
                        styledForGlass
                    } else {
                        styledForLegacy
                    }
                }
            }

            @available(iOS 26.0, macCatalyst 26.0, macOS 26.0, *)
            private var styledForGlass: some View {
                let button = Button(role: .destructive, action: action, label: label)
                return Group {
                    if let accessibilityLabel {
                        button
                            .buttonStyle(.glassProminent)
                            .tint(tint)
                            .accessibilityLabel(accessibilityLabel)
                    } else {
                        button
                            .buttonStyle(.glassProminent)
                            .tint(tint)
                    }
                }
            }

            private var styledForLegacy: some View {
                let button = Button(role: .destructive, action: action, label: label)
                return Group {
                    if let accessibilityLabel {
                        legacyStyle(button).accessibilityLabel(accessibilityLabel)
                    } else {
                        legacyStyle(button)
                    }
                }
            }
        }

        // MARK: - ToolbarIcon
        struct ToolbarIcon: View {
            let systemImage: String
            let action: () -> Void

            init(_ systemImage: String, action: @escaping () -> Void) {
                self.systemImage = systemImage
                self.action = action
            }

            var body: some View {
                Button(action: action) {
                    Image(systemName: systemImage)
                        .symbolRenderingMode(.monochrome)
                        .foregroundStyle(Colors.stylePrimary)
                        .font(.system(size: 17, weight: .semibold))
                        .frame(width: 33, height: 33)
                        .contentShape(Circle())
                }
                .buttonStyle(.plain)
            }
        }

        // MARK: - IconMenuLabel
        struct IconMenuLabel: View {
            let systemImage: String
            let size: CGFloat

            init(_ systemImage: String, size: CGFloat) {
                self.systemImage = systemImage
                self.size = size
            }

            var body: some View {
                Image(systemName: systemImage)
                    .symbolRenderingMode(.monochrome)
                    .font(.body.weight(.semibold))
                    .frame(width: size, height: size)
                    .tint(.primary)
                    .foregroundStyle(.primary)
            }
        }

        // MARK: - Private
        struct PlainLegacyCTA<Label: View>: View {
            let button: Button<Label>

            var body: some View {
                button.buttonStyle(.plain)
            }
        }
    }
}

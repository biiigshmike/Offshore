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
            let iconSize: CGFloat
            let legacyTint: Color
            let legacyPadding: CGFloat
            let hitSize: CGFloat

            init(
                _ systemImage: String,
                iconSize: CGFloat,
                legacyTint: Color,
                legacyPadding: CGFloat,
                hitSize: CGFloat = 44
            ) {
                self.systemImage = systemImage
                self.iconSize = iconSize
                self.legacyTint = legacyTint
                self.legacyPadding = legacyPadding
                self.hitSize = hitSize
            }

            var body: some View {
                Group {
                    if #available(iOS 26.0, macCatalyst 26.0, macOS 26.0, *) {
                        ZStack {
                            Image(systemName: systemImage)
                                .symbolRenderingMode(.monochrome)
                                .font(.body.weight(.semibold))
                                .frame(width: iconSize, height: iconSize)
                                .foregroundStyle(.primary)
                        }
                        .frame(width: hitSize, height: hitSize)
                        .contentShape(Circle())
                    } else {
                        Image(systemName: systemImage)
                            .font(.body.weight(.semibold))
                            .padding(legacyPadding)
                            .frame(minWidth: iconSize, minHeight: iconSize)
                            .foregroundStyle(legacyTint)
                    }
                }
            }
        }

        // MARK: - GlassProminentIconMenu
        struct GlassProminentIconMenu<MenuItems: View>: View {
            let systemImage: String
            let accessibilityLabel: String
            let accessibilityHint: String
            let tint: Color
            let iconSize: CGFloat
            let hitSize: CGFloat
            let legacyTint: Color
            let legacyPadding: CGFloat
            @ViewBuilder let items: () -> MenuItems

            init(
                systemImage: String,
                accessibilityLabel: String,
                accessibilityHint: String,
                tint: Color,
                iconSize: CGFloat,
                hitSize: CGFloat = 44,
                legacyTint: Color,
                legacyPadding: CGFloat,
                @ViewBuilder items: @escaping () -> MenuItems
            ) {
                self.systemImage = systemImage
                self.accessibilityLabel = accessibilityLabel
                self.accessibilityHint = accessibilityHint
                self.tint = tint
                self.iconSize = iconSize
                self.hitSize = hitSize
                self.legacyTint = legacyTint
                self.legacyPadding = legacyPadding
                self.items = items
            }

            var body: some View {
                Group {
                    if #available(iOS 26.0, macCatalyst 26.0, macOS 26.0, *) {
                        Menu {
                            items()
                        } label: {
                            Image(systemName: systemImage)
                                .symbolRenderingMode(.monochrome)
                                .font(.system(size: 17, weight: .semibold))
                                .frame(width: iconSize, height: iconSize)
                                .foregroundStyle(.primary)
                                .frame(width: hitSize, height: hitSize)
                                .contentShape(Circle())
                        }
                        .buttonStyle(.glassProminent)
                        .tint(tint)
                    } else {
                        Menu {
                            items()
                        } label: {
                            Image(systemName: systemImage)
                                .font(.body.weight(.semibold))
                                .padding(legacyPadding)
                                .frame(minWidth: iconSize, minHeight: iconSize)
                                .foregroundStyle(legacyTint)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .accessibilityLabel(accessibilityLabel)
                .accessibilityHint(accessibilityHint)
                .frame(minWidth: 44, minHeight: 44)
            }
        }

        // MARK: - Menu Styling
        struct GlassProminentTinted: ViewModifier {
            let tint: Color

            func body(content: Content) -> some View {
                Group {
                    if #available(iOS 26.0, macCatalyst 26.0, macOS 26.0, *) {
                        content
                            .buttonStyle(.glassProminent)
                            .tint(tint)
                    } else {
                        content
                            .buttonStyle(.plain)
                    }
                }
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

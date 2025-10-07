import SwiftUI

// MARK: - GlassTextButton
struct GlassTextButton<Label: View>: View {
    enum LabelContentStyle {
        case text
        case glyph(weight: Font.Weight = .thin)
    }

    @Environment(\.platformCapabilities) private var capabilities
    @EnvironmentObject private var themeManager: ThemeManager
    @Environment(\.colorScheme) private var colorScheme

    private let width: CGFloat?
    private let maxWidth: CGFloat?
    private let alignment: Alignment
    private let contentStyle: LabelContentStyle
    private let action: () -> Void
    private let labelBuilder: () -> Label

    init(
        width: CGFloat? = nil,
        maxWidth: CGFloat? = nil,
        alignment: Alignment = .center,
        contentStyle: LabelContentStyle = .text,
        action: @escaping () -> Void,
        @ViewBuilder label: @escaping () -> Label
    ) {
        self.width = width
        self.maxWidth = maxWidth
        self.alignment = alignment
        self.contentStyle = contentStyle
        self.action = action
        self.labelBuilder = label
    }

    var body: some View {
        Group {
            if capabilities.supportsOS26Translucency, #available(iOS 26.0, macOS 26.0, macCatalyst 26.0, *) {
                Button(action: action) {
                    buttonLabel()
                }
                .buttonStyle(.glass)
                .buttonBorderShape(.roundedRectangle(radius: resolvedCornerRadius))
                .tint(glassTint)
                .onAppear {
                    capabilities.qaLogLiquidGlassDecision(component: "GlassTextButton", path: "glass")
                }
            } else {
                Button(action: action) {
                    buttonLabel()
                }
                .buttonStyle(.plain)
                .tint(legacyTint)
                .onAppear {
                    capabilities.qaLogLiquidGlassDecision(component: "GlassTextButton", path: "legacy")
                }
            }
        }
        .frame(maxWidth: maxWidth, alignment: alignment)
        .frame(width: width, alignment: alignment)
    }

    // MARK: - Label Styling
    @ViewBuilder
    private func buttonLabel() -> some View {
        labelBuilder()
            .font(resolvedFont)
            .foregroundStyle(resolvedForeground)
            .padding(.horizontal, resolvedHorizontalPadding)
            .padding(.vertical, DS.Spacing.s)
            .frame(maxWidth: maxWidth, alignment: alignment)
            .frame(width: width, alignment: alignment)
            .frame(height: resolvedHeight, alignment: alignment)
            .contentShape(RoundedRectangle(cornerRadius: resolvedCornerRadius, style: .continuous))
    }

    private var resolvedFont: Font {
        switch contentStyle {
        case .text:
            return .system(size: 17, weight: .semibold, design: .rounded)
        case .glyph(let weight):
            return .system(size: 17, weight: weight, design: .rounded)
        }
    }

    private var resolvedHorizontalPadding: CGFloat {
        switch contentStyle {
        case .text:
            return DS.Spacing.l
        case .glyph:
            return DS.Spacing.m
        }
    }

    private var resolvedForeground: Color {
        themeManager.selectedTheme.primaryTextColor(for: colorScheme)
    }

    private var glassTint: Color {
        themeManager.selectedTheme.glassPalette.accent
    }

    private var legacyTint: Color {
        themeManager.selectedTheme.resolvedTint
    }

    private var resolvedHeight: CGFloat {
        max(44, DS.Spacing.l + (DS.Spacing.s * 2))
    }

    private var resolvedCornerRadius: CGFloat {
        resolvedHeight / 2
    }
}

// MARK: - Convenience Initializers
extension GlassTextButton where Label == Text {
    init(
        _ titleKey: LocalizedStringKey,
        width: CGFloat? = nil,
        maxWidth: CGFloat? = nil,
        alignment: Alignment = .center,
        contentStyle: LabelContentStyle = .text,
        action: @escaping () -> Void
    ) {
        self.init(
            width: width,
            maxWidth: maxWidth,
            alignment: alignment,
            contentStyle: contentStyle,
            action: action
        ) {
            Text(titleKey)
        }
    }

    init(
        _ title: String,
        width: CGFloat? = nil,
        maxWidth: CGFloat? = nil,
        alignment: Alignment = .center,
        contentStyle: LabelContentStyle = .text,
        action: @escaping () -> Void
    ) {
        self.init(
            width: width,
            maxWidth: maxWidth,
            alignment: alignment,
            contentStyle: contentStyle,
            action: action
        ) {
            Text(title)
        }
    }
}

#if DEBUG
struct GlassTextButton_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            preview(for: PlatformCapabilities(supportsOS26Translucency: true, supportsAdaptiveKeypad: true))
                .previewDisplayName("OS 26 Glass")
            preview(for: PlatformCapabilities(supportsOS26Translucency: false, supportsAdaptiveKeypad: false))
                .previewDisplayName("Legacy")
        }
        .environmentObject(ThemeManager())
    }

    private static func preview(for capabilities: PlatformCapabilities) -> some View {
        VStack(spacing: DS.Spacing.m) {
            GlassTextButton("Primary Action", maxWidth: 200) {}
            GlassTextButton(width: 60, contentStyle: .glyph(weight: .thin), action: {}) {
                Text("<<")
            }
        }
        .padding(DS.Spacing.l)
        .environment(\.platformCapabilities, capabilities)
    }
}
#endif

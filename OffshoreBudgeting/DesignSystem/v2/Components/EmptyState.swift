import SwiftUI

// MARK: - DesignSystemV2.EmptyState
extension DesignSystemV2 {
    /// Standardized empty-state presentation with optional action button.
    ///
    /// This is a DSv2 port of `UBEmptyState` intended to keep behavior stable while
    /// centralizing spacing/typography/icons under DSv2.
    struct EmptyState: View {

        @Environment(\.isOnboardingPresentation) private var isOnboardingPresentation
        @Environment(\.colorScheme) private var colorScheme
        @Environment(\.platformCapabilities) private var capabilities
        @Environment(\.verticalSizeClass) private var verticalSizeClass
        @EnvironmentObject private var themeManager: ThemeManager

        // MARK: Content
        let iconSystemName: String?
        let title: String?
        let message: String

        // MARK: Actions
        let primaryButtonTitle: String?
        let onPrimaryTap: (() -> Void)?

        // MARK: Layout
        let maxMessageWidth: CGFloat
        let containerAlignment: Alignment

        // MARK: init(...)
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
            VStack(spacing: Spacing.m) {
                if let iconSystemName, !iconSystemName.isEmpty {
                    Image(systemName: iconSystemName)
                        .font(.system(size: 52, weight: .medium))
                        .foregroundStyle(.primary)
                        .accessibilityHidden(true)
                }

                if let title = resolvedTitle {
                    Text(title)
                        .font(Typography.largeTitleBold)
                        .foregroundStyle(.primary)
                }

                Text(message)
                    .font(messageFont)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(messageForeground)
                    .frame(maxWidth: maxMessageWidth)

                if let primaryButtonTitle, let onPrimaryTap {
                    primaryButton(title: primaryButtonTitle, action: onPrimaryTap)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: containerAlignment)
            .padding(.horizontal, Spacing.l)
            .padding(.vertical, resolvedVerticalPadding)
        }

        private var resolvedTitle: String? {
            guard let title else { return nil }
            let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
            return trimmed.isEmpty ? nil : trimmed
        }

        private var messageFont: Font {
            resolvedTitle == nil ? Typography.title3Semibold : Typography.subheadline
        }

        private var messageForeground: some ShapeStyle {
            resolvedTitle == nil ? Colors.stylePrimary : Colors.styleSecondary
        }

        private var resolvedVerticalPadding: CGFloat {
            verticalSizeClass == .compact ? Spacing.s : Spacing.m
        }

        private var onboardingTint: Color {
            themeManager.selectedTheme.resolvedTint
        }

        // MARK: Primary CTA Helpers
        @ViewBuilder
        private func primaryButton(title: String, action: @escaping () -> Void) -> some View {
            let fallbackTint = isOnboardingPresentation ? onboardingTint : primaryButtonTint
            let glassTint = isOnboardingPresentation ? onboardingTint : primaryButtonGlassTint

            if capabilities.supportsOS26Translucency, #available(iOS 26.0, macOS 26.0, macCatalyst 26.0, *) {
                glassStyledPrimaryButton(title: title, glassTint: glassTint, action: action)
            } else {
                legacyPrimaryButton(title: title, tint: fallbackTint, action: action)
            }
        }

        private func legacyPrimaryButton(title: String, tint: Color, action: @escaping () -> Void) -> some View {
            Button(action: action) {
                Label(title, systemImage: Icons.sfPlus)
                    .labelStyle(.titleAndIcon)
                    .foregroundStyle(primaryButtonForegroundColor())
            }
            .buttonStyle(.plain)
            .tint(tint)
        }

        @available(iOS 26.0, macOS 26.0, macCatalyst 26.0, *)
        private func glassStyledPrimaryButton(title: String, glassTint: Color, action: @escaping () -> Void) -> some View {
            Button(action: action) {
                Label(title, systemImage: Icons.sfPlus)
                    .labelStyle(.titleAndIcon)
                    .font(.system(size: 17, weight: .semibold, design: .rounded))
                    .foregroundStyle(primaryButtonForegroundColor())
                    .padding(.horizontal, Spacing.xl)
                    .padding(.vertical, Spacing.m)
            }
            .tint(glassTint)
            .buttonStyle(.glass)
            .frame(maxWidth: 320)
        }

        private func primaryButtonForegroundColor(isTintedBackground: Bool = false) -> Color {
            switch colorScheme {
            case .light:
                return .black
            default:
                return isTintedBackground ? .white : .primary
            }
        }

        private var primaryButtonTint: Color {
            themeManager.selectedTheme.resolvedTint
        }

        private var primaryButtonGlassTint: Color {
            themeManager.selectedTheme.glassPalette.accent
        }
    }
}


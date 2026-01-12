import SwiftUI

// MARK: - DesignSystemV2.SettingsRow
enum DesignSystemV2 {
    /// A reusable Settings row container layout.
    ///
    /// This centralizes the repeated row structure (HStack, optional chevron, accessibility),
    /// while callers provide the leading icon tile view to preserve visuals.
    struct SettingsRow<Leading: View>: View {
        let title: String
        var detail: String? = nil
        var showsChevron: Bool = true
        var action: (() -> Void)? = nil
        var accessibilityLabel: Text? = nil
        @ViewBuilder var leading: Leading

        @ScaledMetric(relativeTo: .body) private var iconTextSpacing: CGFloat = Spacing.l

        init(
            title: String,
            detail: String? = nil,
            showsChevron: Bool = true,
            action: (() -> Void)? = nil,
            accessibilityLabel: Text? = nil,
            @ViewBuilder leading: () -> Leading
        ) {
            self.title = title
            self.detail = detail
            self.showsChevron = showsChevron
            self.action = action
            self.accessibilityLabel = accessibilityLabel
            self.leading = leading()
        }

        var body: some View {
            if let action {
                Button(action: action) { rowBody }
                    .buttonStyle(.plain)
                    .contentShape(Rectangle())
            } else {
                rowBody
            }
        }

        private var rowBody: some View {
            HStack(spacing: iconTextSpacing) {
                leading

                Text(title)
                    .lineLimit(nil)
                    .fixedSize(horizontal: false, vertical: true)

                Spacer()

                if let detail {
                    Text(detail)
                        .lineLimit(nil)
                        .fixedSize(horizontal: false, vertical: true)
                }

                if showsChevron {
                    Image(systemName: Icons.sfChevronRight)
                        .font(Typography.footnote)
                        .foregroundStyle(Colors.styleSecondary)
                        .accessibilityHidden(true)
                }
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel(accessibilityLabel ?? Text(title))
        }
    }
}

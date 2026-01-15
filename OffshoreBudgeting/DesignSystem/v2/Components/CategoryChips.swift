import SwiftUI

// MARK: - DesignSystemV2.Category Chips
extension DesignSystemV2 {
    struct CategoryChipItem: Identifiable, Hashable {
        let id: String
        let title: String
        let color: Color

        init(id: String, title: String, color: Color) {
            self.id = id
            self.title = title
            self.color = color
        }
    }

    struct CategoryChip: View {
        let title: String
        let trailingText: String?
        let color: Color
        let isSelected: Bool
        let showsButtonBorderShapeOnOS26: Bool
        let titleFont: Font
        let trailingFont: Font
        let trailingForeground: Color?
        let action: () -> Void

        @ScaledMetric(relativeTo: .subheadline) private var dotSize: CGFloat = 10
        @ScaledMetric(relativeTo: .body) private var minHeight: CGFloat = 44

        init(
            title: String,
            color: Color,
            isSelected: Bool,
            showsButtonBorderShapeOnOS26: Bool = true,
            dotSize: CGFloat = 10,
            minHeight: CGFloat = 44,
            action: @escaping () -> Void
        ) {
            self.title = title
            self.trailingText = nil
            self.color = color
            self.isSelected = isSelected
            self.showsButtonBorderShapeOnOS26 = showsButtonBorderShapeOnOS26
            self.titleFont = Typography.subheadlineSemibold
            self.trailingFont = Typography.subheadlineSemibold
            self.trailingForeground = nil
            self.action = action
            _dotSize = ScaledMetric(wrappedValue: dotSize, relativeTo: .subheadline)
            _minHeight = ScaledMetric(wrappedValue: minHeight, relativeTo: .body)
        }

        init(
            title: String,
            trailingText: String,
            trailingForeground: Color? = nil,
            color: Color,
            isSelected: Bool,
            showsButtonBorderShapeOnOS26: Bool = true,
            titleFont: Font = Typography.subheadlineSemibold,
            trailingFont: Font = Typography.subheadlineSemibold,
            dotSize: CGFloat = 10,
            minHeight: CGFloat = 44,
            action: @escaping () -> Void
        ) {
            self.title = title
            self.trailingText = trailingText
            self.trailingForeground = trailingForeground
            self.color = color
            self.isSelected = isSelected
            self.showsButtonBorderShapeOnOS26 = showsButtonBorderShapeOnOS26
            self.titleFont = titleFont
            self.trailingFont = trailingFont
            self.action = action
            _dotSize = ScaledMetric(wrappedValue: dotSize, relativeTo: .subheadline)
            _minHeight = ScaledMetric(wrappedValue: minHeight, relativeTo: .body)
        }

        var body: some View {
            let accentColor = color
            let glassTintColor = accentColor.opacity(0.25)
            let legacyShape = RoundedRectangle(cornerRadius: 6, style: .continuous)

            let label = HStack(spacing: Spacing.s) {
                Circle()
                    .fill(accentColor)
                    .frame(width: dotSize, height: dotSize)
                Text(title)
                    .font(titleFont)
                    .foregroundStyle(.primary)
                    .fixedSize(horizontal: false, vertical: true)
                if let trailingText {
                    Text(trailingText)
                        .font(trailingFont)
                        .foregroundStyle(trailingForeground ?? .primary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(.horizontal, 12)
            .frame(minHeight: minHeight, maxHeight: minHeight)

            if #available(iOS 26.0, macOS 26.0, macCatalyst 26.0, *) {
                Button(action: action) {
                    label
                        .glassEffect(
                            .regular
                                .tint(isSelected ? glassTintColor : .none)
                                .interactive(true)
                        )
                        .frame(minHeight: minHeight, maxHeight: minHeight)
                        .clipShape(Capsule())
                        .compositingGroup()
                }
                .accessibilityAddTraits(isSelected ? .isSelected : [])
                .accessibilityLabel(title)
                .accessibilityHint("Select category")
                .animation(.easeOut(duration: 0.15), value: isSelected)
                .frame(minHeight: minHeight, maxHeight: minHeight)
                .buttonStyle(.plain)
                .modifier(ApplyButtonBorderShapeIfEnabled(isEnabled: showsButtonBorderShapeOnOS26))
            } else {
                let neutralFill = Colors.chipFill
                Button(action: action) {
                    label
                }
                .accessibilityAddTraits(isSelected ? .isSelected : [])
                .accessibilityLabel(title)
                .accessibilityHint("Select category")
                .animation(.easeOut(duration: 0.15), value: isSelected)
                .frame(minHeight: minHeight, maxHeight: minHeight)
                .buttonStyle(.plain)
                .modifier(
                    DesignSystemV2.ChipLegacySurface(
                        shape: legacyShape,
                        fill: isSelected ? glassTintColor : neutralFill,
                        stroke: neutralFill,
                        lineWidth: 1
                    )
                )
            }
        }
    }

    struct AddCategoryPill: View {
        let fillsWidth: Bool
        let action: () -> Void

        @ScaledMetric(relativeTo: .body) private var minHeight: CGFloat = 44

        init(fillsWidth: Bool, minHeight: CGFloat = 44, action: @escaping () -> Void) {
            self.fillsWidth = fillsWidth
            self.action = action
            _minHeight = ScaledMetric(wrappedValue: minHeight, relativeTo: .body)
        }

        var body: some View {
            if #available(iOS 26.0, macOS 26.0, macCatalyst 26.0, *) {
                let label = Label("Add", systemImage: Icons.sfPlus)
                    .font(Typography.subheadlineSemibold)
                    .padding(.horizontal, 12)
                    .frame(maxWidth: fillsWidth ? .infinity : nil, minHeight: minHeight, alignment: .center)
                    .glassEffect(.regular.tint(.clear).interactive(true))

                Button(action: action) {
                    label
                }
                .buttonStyle(.plain)
                .frame(maxWidth: fillsWidth ? .infinity : nil, minHeight: minHeight, alignment: .center)
                .clipShape(Capsule())
                .compositingGroup()
                .accessibilityLabel("Add Category")
            } else {
                Button(action: action) {
                    Label("Add", systemImage: Icons.sfPlus)
                        .font(Typography.subheadlineSemibold)
                        .padding(.horizontal, 12)
                        .frame(maxWidth: fillsWidth ? .infinity : nil, minHeight: minHeight, alignment: .center)
                        .background(
                            RoundedRectangle(cornerRadius: 6, style: .continuous)
                                .fill(legacyFill)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                        .contentShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                }
                .buttonStyle(.plain)
                .controlSize(.regular)
                .frame(maxWidth: fillsWidth ? .infinity : nil, minHeight: minHeight, alignment: .center)
                .accessibilityLabel("Add Category")
            }
        }

        private var legacyFill: Color {
            #if canImport(UIKit)
            return Color(UIColor { traits in
                traits.userInterfaceStyle == .dark
                ? UIColor(white: 0.22, alpha: 1)
                : UIColor(white: 0.9, alpha: 1)
            })
            #else
            return Color(white: 0.9)
            #endif
        }
    }

    // MARK: - CategoryChipsRow
    /// Public entrypoint for the standard “category chips row” UI.
    /// Delegates to the internal layout implementation to keep call sites stable.
    public struct CategoryChipsRow: View {
        let items: [CategoryChipItem]
        @Binding var selectedID: String?
        let emptyTitle: String
        let onAddTapped: () -> Void

        public init(
            items: [CategoryChipItem],
            selectedID: Binding<String?>,
            emptyTitle: String = "No categories yet",
            onAddTapped: @escaping () -> Void
        ) {
            self.items = items
            self._selectedID = selectedID
            self.emptyTitle = emptyTitle
            self.onAddTapped = onAddTapped
        }

        public var body: some View {
            CategoryChipsRowLayout(
                items: items,
                selectedID: $selectedID,
                emptyTitle: emptyTitle,
                onAddTapped: onAddTapped
            )
        }
    }

    internal struct CategoryChipsRowLayout: View {
        let items: [CategoryChipItem]
        @Binding var selectedID: String?
        let emptyTitle: String
        let onAddTapped: () -> Void

        @Environment(\.dynamicTypeSize) private var dynamicTypeSize

        init(
            items: [CategoryChipItem],
            selectedID: Binding<String?>,
            emptyTitle: String = "No categories yet",
            onAddTapped: @escaping () -> Void
        ) {
            self.items = items
            self._selectedID = selectedID
            self.emptyTitle = emptyTitle
            self.onAddTapped = onAddTapped
        }

        var body: some View {
            Group {
                if isAccessibilitySize {
                    VStack(alignment: .leading, spacing: Spacing.s) {
                        addButton
                            .frame(maxWidth: .infinity, alignment: .leading)
                        chipsScrollContainer()
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                } else {
                    HStack(alignment: .center, spacing: Spacing.s) {
                        addButton
                        chipsScrollContainer()
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }

        private var isAccessibilitySize: Bool {
            dynamicTypeSize.isAccessibilitySize
        }

        private var addButton: some View {
            DesignSystemV2.AddCategoryPill(fillsWidth: isAccessibilitySize, action: onAddTapped)
                .padding(.leading, isAccessibilitySize ? 0 : Spacing.s)
        }

        @ViewBuilder
        private func chipsScrollContainer() -> some View {
            chipsScrollView()
                .padding(.horizontal, Spacing.s)
                .frame(maxWidth: .infinity, alignment: .leading)
        }

        private func chipsScrollView() -> some View {
            ScrollView(.horizontal, showsIndicators: false) {
                chipsContent
                    .padding(.trailing, Spacing.s)
            }
            .scrollIndicators(.hidden)
            .ub_disableHorizontalBounce()
            .frame(maxWidth: .infinity, alignment: .leading)
        }

        @ViewBuilder
        private var chipsContent: some View {
            LazyHStack(spacing: Spacing.s) {
                if items.isEmpty {
                    Text(emptyTitle)
                        .foregroundStyle(.secondary)
                        .padding(.vertical, Spacing.sPlus)
                } else {
                    ForEach(items) { item in
                        let isSelected = selectedID == item.id
                        DesignSystemV2.CategoryChip(
                            title: item.title,
                            color: item.color,
                            isSelected: isSelected,
                            showsButtonBorderShapeOnOS26: true,
                            action: { selectedID = item.id }
                        )
                    }
                }
            }
        }
    }

}

// MARK: - Private
private struct ApplyButtonBorderShapeIfEnabled: ViewModifier {
    let isEnabled: Bool

    func body(content: Content) -> some View {
        if isEnabled {
            content.buttonBorderShape(.capsule)
        } else {
            content
        }
    }
}

import SwiftUI
import CoreData

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

    struct CategoryChipsRowLayout: View {
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

    // MARK: - ExpenseCategoryChipsRow (Legacy wrapper-first migration)
    struct ExpenseCategoryChipsRow: View {
        @Binding var selectedCategoryID: NSManagedObjectID?

        @Environment(\.managedObjectContext) private var viewContext
        @AppStorage(AppSettingsKeys.activeWorkspaceID.rawValue) private var activeWorkspaceIDRaw: String = ""

        @FetchRequest(
            sortDescriptors: [
                NSSortDescriptor(
                    key: "name",
                    ascending: true,
                    selector: #selector(NSString.localizedCaseInsensitiveCompare(_:))
                )
            ]
        )
        private var categories: FetchedResults<ExpenseCategory>

        @State private var isPresentingNewCategory = false
        @State private var addCategorySheetInstanceID = UUID()

        private let verticalInset: CGFloat = Spacing.s + Spacing.xs

        private var filteredCategories: [ExpenseCategory] {
            guard let workspaceID = UUID(uuidString: activeWorkspaceIDRaw) else { return Array(categories) }
            return categories.filter { category in
                (category.value(forKey: "workspaceID") as? UUID) == workspaceID
            }
        }

        private var idToObjectID: [String: NSManagedObjectID] {
            Dictionary(
                uniqueKeysWithValues: filteredCategories.map { category in
                    (category.objectID.uriRepresentation().absoluteString, category.objectID)
                }
            )
        }

        private var selectedID: Binding<String?> {
            Binding<String?>(
                get: { selectedCategoryID?.uriRepresentation().absoluteString },
                set: { newValue in
                    guard let newValue else {
                        selectedCategoryID = nil
                        return
                    }
                    if let mapped = idToObjectID[newValue] {
                        selectedCategoryID = mapped
                    } else {
                        selectedCategoryID = nil
                    }
                }
            )
        }

        var body: some View {
            DesignSystemV2.CategoryChipsRowLayout(
                items: chipItems,
                selectedID: selectedID,
                onAddTapped: {
                    addCategorySheetInstanceID = UUID()
                    isPresentingNewCategory = true
                }
            )
            .listRowInsets(rowInsets)
            .listRowSeparator(.hidden)
            .ub_preOS26ListRowBackground(.clear)
            .sheet(isPresented: $isPresentingNewCategory) {
                let base = ExpenseCategoryEditorSheet(
                    initialName: "",
                    initialHex: "#4E9CFF"
                ) { name, hex in
                    let category = ExpenseCategory(context: viewContext)
                    category.id = UUID()
                    category.name = name
                    category.color = hex
                    WorkspaceService.shared.applyWorkspaceID(on: category)
                    do {
                        try viewContext.obtainPermanentIDs(for: [category])
                        try viewContext.save()
                        selectedCategoryID = category.objectID
                    } catch {
                        AppLog.ui.error("Failed to create category: \(error.localizedDescription)")
                    }
                }
                .environment(\.managedObjectContext, viewContext)

                Group {
                    if #available(iOS 16.0, *) {
                        base.presentationDetents([.medium])
                    } else {
                        base
                    }
                }
                .id(addCategorySheetInstanceID)
            }
            .onChange(of: categories.count) { _ in
                if selectedCategoryID == nil, let first = filteredCategories.first {
                    selectedCategoryID = first.objectID
                }
            }
            .onChange(of: activeWorkspaceIDRaw) { _ in
                if let first = filteredCategories.first {
                    selectedCategoryID = first.objectID
                } else {
                    selectedCategoryID = nil
                }
            }
        }

        private var chipItems: [DesignSystemV2.CategoryChipItem] {
            filteredCategories.map { category in
                let id = category.objectID.uriRepresentation().absoluteString
                let title = category.name ?? "Untitled"
                let colorHex = category.color ?? "#999999"
                let color = UBColorFromHex(colorHex) ?? .secondary
                return DesignSystemV2.CategoryChipItem(id: id, title: title, color: color)
            }
        }

        private var rowInsets: EdgeInsets {
            EdgeInsets(
                top: verticalInset,
                leading: Spacing.l,
                bottom: verticalInset,
                trailing: Spacing.l
            )
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

import SwiftUI
import CoreData

// MARK: - ExpenseCategoryChipsRow
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


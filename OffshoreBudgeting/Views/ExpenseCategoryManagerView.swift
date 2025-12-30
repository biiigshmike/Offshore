//
//  ExpenseCategoryManagerView.swift
//  SoFar
//
//  Created by Michael Brown on 8/14/25.
//

import SwiftUI
import CoreData
import UIKit

// MARK: - ExpenseCategoryManagerView
struct ExpenseCategoryManagerView: View {
    
    // MARK: Dependencies
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject private var themeManager: ThemeManager
    @Environment(\.platformCapabilities) private var capabilities
    @Environment(\.ub_safeAreaInsets) private var legacySafeAreaInsets
    @Environment(\.dismiss) private var dismiss
    
    // MARK: Sorting
    private static let sortByName: [NSSortDescriptor] = [
        NSSortDescriptor(key: "name", ascending: true)
    ]
    
    // MARK: Fetch Request
    @FetchRequest(
        sortDescriptors: ExpenseCategoryManagerView.sortByName,
        animation: .default
    )
    private var categories: FetchedResults<ExpenseCategory>
    
    // MARK: UI State
    @State private var isPresentingAddSheet: Bool = false
    // Force a fresh sheet instance each presentation (fixes Mac Catalyst state reuse)
    @State private var addSheetInstanceID = UUID()
    @State private var categoryToEdit: ExpenseCategory?
    @State private var categoryToDelete: ExpenseCategory?
    @State private var isMenuActive = false
    @Environment(\.currentSidebarSelection) private var currentSidebarSelection
    @AppStorage(AppSettingsKeys.confirmBeforeDelete.rawValue) private var confirmBeforeDelete: Bool = true
    @AppStorage(AppSettingsKeys.activeWorkspaceID.rawValue) private var activeWorkspaceIDRaw: String = ""
    
    // MARK: Body
    var body: some View {
        navigationContainer {
            groupedListContent
                .navigationTitle("Categories")
                .toolbar {
                    // Left: Done (clear/plain, larger tap target)
//                    ToolbarItem(placement: .cancellationAction) {
//                        Button(action: { dismiss() }) {
//                            Text("Done")
//                                .font(.system(size: 17, weight: .semibold, design: .rounded))
//                                .foregroundStyle(.primary)
//                                .frame(minWidth: 44, minHeight: 34)
//                                .padding(.horizontal, 14)
//                        }
//                        .buttonStyle(.plain)
//                        .accessibilityLabel("Done")
//                    }
                    
                    // Right: Add Category (clear/plain, 33x33 hit box)
                    ToolbarItem(placement: .primaryAction) {
                        Button(action: {
                            // Refresh the sheet identity so @State in the sheet resets on each open
                            addSheetInstanceID = UUID()
                            isPresentingAddSheet = true
                        }) {
                            Image(systemName: "plus")
                                .symbolRenderingMode(.monochrome)
                                .foregroundStyle(.primary)
                                .font(.system(size: 17, weight: .semibold))
                                .frame(width: 33, height: 33)
                                .contentShape(Circle())
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Add Category")
                    }
                }
        }
        .accentColor(themeManager.selectedTheme.resolvedTint)
        .tint(themeManager.selectedTheme.resolvedTint)
        .sheet(isPresented: $isPresentingAddSheet, onDismiss: {
            // Ensure the presenting flag is cleared and next open is fresh
            isPresentingAddSheet = false
        }) {
            ExpenseCategoryEditorSheet(
                initialName: "",
                initialHex: "#4E9CFF",
                onCancel: { isPresentingAddSheet = false },
                onSave: { name, hex in
                    addCategory(name: name, hex: hex)
                    // Explicitly flip binding off to avoid any Catalyst re-present glitch
                    #if targetEnvironment(macCatalyst)
                    DispatchQueue.main.async { isPresentingAddSheet = false }
                    #else
                    isPresentingAddSheet = false
                    #endif
                }
            )
            .id(addSheetInstanceID)
        }
        .sheet(item: $categoryToEdit) { category in
            ExpenseCategoryEditorSheet(
                initialName: category.name ?? "",
                initialHex: category.color ?? "#999999",
                onSave: { name, hex in
                    category.name = name
                    category.color = hex
                    saveContext()
                }
            )
        }
        .alert(item: $categoryToDelete) { cat in
            let counts = usageCounts(for: cat)
            let title = Text(#"Delete \#(cat.name ?? "Category")?"#)
            let message: Text = {
                if counts.total > 0 {
                    return Text(#"This category is used by \#(counts.planned) planned and \#(counts.unplanned) variable expenses. Deleting it will also delete those expenses."#)
                } else {
                    return Text("This will remove the category.")
                }
            }()
            return Alert(
                title: title,
                message: message,
                primaryButton: .destructive(Text(counts.total > 0 ? "Delete Category & Expenses" : "Delete")) { deleteCategory(cat) },
                secondaryButton: .cancel()
            )
        }
        .tipsAndHintsOverlay(for: .categories)
        .onAppear { isMenuActive = true }
        .onDisappear { isMenuActive = false }
        .focusedSceneValue(
            \.newItemCommand,
            (isMenuActive || currentSidebarSelection == .manageCategories) ? NewItemCommand(
                title: "New Category",
                action: {
                    addSheetInstanceID = UUID()
                    isPresentingAddSheet = true
                }
            ) : nil
        )
    }

    private var filteredCategories: [ExpenseCategory] {
        guard let workspaceID = UUID(uuidString: activeWorkspaceIDRaw) else { return Array(categories) }
        return categories.filter { category in
            (category.value(forKey: "workspaceID") as? UUID) == workspaceID
        }
    }
    
    private var groupedListContent: some View {
        Group {
            if filteredCategories.isEmpty {
                emptyState
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            } else {
                List {
//                    Text("These categories appear when adding expenses. Colors help visually group spending.")
//                        .font(.footnote)
//                        .foregroundStyle(.secondary)
                    
                    Section() {
                        let swipeConfig = UnifiedSwipeConfig(allowsFullSwipeToDelete: !confirmBeforeDelete)

                        ForEach(filteredCategories, id: \.objectID) { category in
                            categoryRow(for: category, swipeConfig: swipeConfig)
                        }
                        .onDelete { offsets in
                            let targets = offsets.map { filteredCategories[$0] }
                            if confirmBeforeDelete {
                                if let used = targets.first(where: { usageCounts(for: $0).total > 0 }) {
                                    categoryToDelete = used
                                } else if let first = targets.first {
                                    categoryToDelete = first
                                }
                            } else {
                                // Strictly delete with no alerts when confirmations are disabled
                                targets.forEach(deleteCategory(_:))
                            }
                        }
                    }
                }
                .listStyle(.insetGrouped)
            }
        }
    }
    
    // MARK: Navigation container
    @ViewBuilder
    private func navigationContainer<Inner: View>(@ViewBuilder content: () -> Inner) -> some View {
        if #available(iOS 16.0, macCatalyst 16.0, *) {
            NavigationStack { content() }
        } else {
            NavigationView { content() }
        }
    }
    
    // MARK: - Row Builders
    @ViewBuilder
    private func categoryRow(for category: ExpenseCategory, swipeConfig: UnifiedSwipeConfig) -> some View {
        CategoryRowView(
            config: swipeConfig,
            label: { rowLabel(for: category) },
            onTap: { categoryToEdit = category },
            onEdit: { categoryToEdit = category },
            onDelete: {
                if confirmBeforeDelete {
                    // Show confirmation (with cascade details if in use)
                    categoryToDelete = category
                } else {
                    // Strictly delete without any alert
                    deleteCategory(category)
                }
            }
        )
    }
    
    @ViewBuilder
    private func rowLabel(for category: ExpenseCategory) -> some View {
        HStack(spacing: 12) {
            ColorCircle(hex: category.color ?? "#999999")
            VStack(alignment: .leading) {
                Text(category.name ?? "Untitled")
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
        }
    }
    
    // MARK: - Empty State
    private var emptyState: some View {
        UBEmptyState(message: "No categories found. Tap + to create a category.")
    }
    
    // MARK: - CRUD
    private func addCategory(name: String, hex: String) {
        let new = ExpenseCategory(context: viewContext)
        new.id = UUID()
        new.name = name
        new.color = hex
        WorkspaceService.shared.applyWorkspaceID(on: new)
        saveContext()
    }
    
    private func deleteCategory(_ cat: ExpenseCategory) {
        // Fetch and delete all expenses referencing this category (planned and variable).
        let reqP = NSFetchRequest<PlannedExpense>(entityName: "PlannedExpense")
        reqP.predicate = NSPredicate(format: "expenseCategory == %@", cat)
        let planned = (try? viewContext.fetch(reqP)) ?? []
        
        let reqU = NSFetchRequest<UnplannedExpense>(entityName: "UnplannedExpense")
        reqU.predicate = NSPredicate(format: "expenseCategory == %@", cat)
        let unplanned = (try? viewContext.fetch(reqU)) ?? []
        
        planned.forEach { viewContext.delete($0) }
        unplanned.forEach { viewContext.delete($0) }
        viewContext.delete(cat)
        saveContext()
    }
    
    // MARK: Usage counting (excludes global templates to match user-visible "in use")
    private func usageCounts(for category: ExpenseCategory) -> (planned: Int, unplanned: Int, total: Int) {
        // Planned: exclude isGlobal == true (templates)
        let reqP = NSFetchRequest<NSNumber>(entityName: "PlannedExpense")
        reqP.resultType = .countResultType
        reqP.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
            NSPredicate(format: "expenseCategory == %@", category),
            NSPredicate(format: "isGlobal == NO")
        ])
        let plannedCount = (try? viewContext.count(for: reqP)) ?? 0
        
        // Unplanned: count all
        let reqU = NSFetchRequest<NSNumber>(entityName: "UnplannedExpense")
        reqU.resultType = .countResultType
        reqU.predicate = NSPredicate(format: "expenseCategory == %@", category)
        let unplannedCount = (try? viewContext.count(for: reqU)) ?? 0
        
        return (plannedCount, unplannedCount, plannedCount + unplannedCount)
    }
    
    private func saveContext() {
        do { try viewContext.save() }
        catch { AppLog.ui.error("Failed to save categories: \(error.localizedDescription)") }
    }
}

// MARK: - CategoryRowView
private struct CategoryRowView<Label: View>: View {
    
    // MARK: Properties
    var config: UnifiedSwipeConfig
    @ViewBuilder var label: () -> Label
    var onTap: () -> Void
    var onEdit: () -> Void
    var onDelete: () -> Void
    
    // MARK: Body
    var body: some View {
        label()
            .contentShape(Rectangle())
            .onTapGesture(perform: onTap)
            .unifiedSwipeActions(
                config,
                onEdit: onEdit,
                onDelete: onDelete
            )
            .accessibilityAddTraits(.isButton)
    }
}

// MARK: - Availability Helpers
private extension View {
    @ViewBuilder
    func applyIfAvailableScrollContentBackgroundHidden() -> some View {
        if #available(iOS 16.0, macCatalyst 16.0, *) {
            scrollContentBackground(.hidden)
        } else {
            self
        }
    }
}

// MARK: - ExpenseCategoryEditorSheet
struct ExpenseCategoryEditorSheet: View {
    @Environment(\.dismiss) private var dismiss
    
    @State private var name: String
    @State private var color: Color
    
    // Optional cancel hook so presenters can flip their isPresented binding on macOS/Catalyst
    let onCancel: (() -> Void)?
    let onSave: (_ name: String, _ hex: String) -> Void
    
    init(initialName: String,
         initialHex: String,
         onCancel: (() -> Void)? = nil,
         onSave: @escaping (_ name: String, _ hex: String) -> Void) {
        self._name = State(initialValue: initialName)
        self._color = State(initialValue: UBColorFromHex(initialHex) ?? .blue)
        self.onCancel = onCancel
        self.onSave = onSave
    }
    
    var body: some View {
        navigationContainer {
            Form {
                Section {
                    HStack(alignment: .center) {
                        TextField("", text: $name, prompt: Text("Shopping"))
                            .multilineTextAlignment(.leading)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .autocorrectionDisabled(true)
                            .textInputAutocapitalization(.never)
                        Spacer(minLength: 0)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                } header: {
                    Text("Name")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .textCase(.uppercase)
                }
                
                Section {
                    ColorPicker("Color", selection: $color, supportsOpacity: false)
                        .labelsHidden()
                        .frame(maxWidth: .infinity, alignment: .leading)
                } header: {
                    Text("Color")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .textCase(.uppercase)
                }
            }
            .listStyle(.insetGrouped)
            .scrollIndicators(.hidden)
            .navigationTitle("New Category")
            .interactiveDismissDisabled(false)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        // Notify presenter (if provided) and dismiss.
                        onCancel?()
                        // Defer to next runloop to avoid Catalyst sheet bugs.
                        DispatchQueue.main.async {
                            dismiss()
                            forceDismissAnyPresentedControllerIfNeeded()
                        }
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
                        guard !trimmed.isEmpty, let hex = colorToHex(color) else { return }
                        onSave(trimmed, hex)
                        // Defer to next runloop to avoid Catalyst sheet bugs.
                        DispatchQueue.main.async {
                            dismiss()
                            forceDismissAnyPresentedControllerIfNeeded()
                        }
                    }
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
        .modifier(DetentsForCategoryEditorCompat())
    }
    
    // Minimal nav container for older OS support
    @ViewBuilder
    private func navigationContainer<Inner: View>(@ViewBuilder content: () -> Inner) -> some View {
        if #available(iOS 16.0, macCatalyst 16.0, *) {
            NavigationStack { content() }
        } else {
            NavigationView { content() }
        }
    }
    
    private func colorToHex(_ color: Color) -> String? {
        let ui = UIColor(color)
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        guard ui.getRed(&r, green: &g, blue: &b, alpha: &a) else { return nil }
        let ri = Int(round(r * 255)), gi = Int(round(g * 255)), bi = Int(round(b * 255))
        return String(format: "#%02X%02X%02X", ri, gi, bi)
    }

    // Fallback for Mac Catalyst where SwiftUI sheet dismissal can sometimes
    // visually linger even after state changes. This ensures any presented
    // controller is dismissed.
    private func forceDismissAnyPresentedControllerIfNeeded() {
        #if targetEnvironment(macCatalyst)
        DispatchQueue.main.async {
            UIApplication.shared.connectedScenes
                .compactMap { ($0 as? UIWindowScene)?.keyWindow }
                .first?
                .rootViewController?
                .dismiss(animated: true)
        }
        #endif
    }
}

// MARK: - ColorCircle
struct ColorCircle: View {
    var hex: String
    
    var body: some View {
        Circle()
            .fill(UBColorFromHex(hex) ?? .gray.opacity(0.4))
            .frame(width: 24, height: 24)
            .overlay(
                Circle().strokeBorder(Color.primary.opacity(0.1))
            )
            .accessibilityHidden(true)
    }
}

// MARK: - Local Detents modifier for Category Editor (avoids Catalyst bug)
private struct DetentsForCategoryEditorCompat: ViewModifier {
    func body(content: Content) -> some View {
        #if targetEnvironment(macCatalyst)
        // Avoid presentationDetents on Mac Catalyst due to dismissal glitches.
        content
        #else
        content.applyDetentsIfAvailable(detents: [.medium, .large], selection: nil)
        #endif
    }
}

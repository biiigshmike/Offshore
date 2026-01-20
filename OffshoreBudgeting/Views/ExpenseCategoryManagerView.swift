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
    @EnvironmentObject private var settings: AppSettingsState
    @Environment(\.platformCapabilities) private var capabilities
    @Environment(\.ub_safeAreaInsets) private var legacySafeAreaInsets
    @Environment(\.dismiss) private var dismiss
    @Environment(\.uiTestingFlags) private var uiTestingFlags
    
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
    @State private var isConfirmingDeleteCategory = false
    @State private var pendingDeleteCategoryObjectID: NSManagedObjectID?
    @State private var pendingDeleteCategoryName: String = ""
    @State private var isDeletingCategory = false
    let wrapsInNavigation: Bool

    init(wrapsInNavigation: Bool = true) {
        self.wrapsInNavigation = wrapsInNavigation
    }
    
    // MARK: Body
    var body: some View {
        navigationContainer {
            groupedListContent
                .navigationTitle("Categories")
                .ub_windowTitle("Categories")
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
                        DesignSystemV2.Buttons.ToolbarIcon(Icons.sfPlus) {
                            // Refresh the sheet identity so @State in the sheet resets on each open
                            addSheetInstanceID = UUID()
                            isPresentingAddSheet = true
                        }
                        .accessibilityLabel("Add Category")
                        .accessibilityIdentifier(AccessibilityID.Settings.Categories.addButton)
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
        .tipsAndHintsOverlay(for: .categories)
        .alert(deleteCategoryAlertTitle, isPresented: $isConfirmingDeleteCategory) {
            Button("Delete", role: .destructive) {
                let objectID = pendingDeleteCategoryObjectID
                clearPendingCategoryDelete()
                guard let objectID else { return }
                Task { @MainActor in
                    await Task.yield()
                    await deleteCategory(objectID: objectID)
                }
            }
            Button("Cancel", role: .cancel) {
                clearPendingCategoryDelete()
            }
        } message: {
            Text("This will delete the category and any expenses assigned to it. This action cannot be undone.")
        }
    }

    private var filteredCategories: [ExpenseCategory] {
        guard let workspaceID = UUID(uuidString: settings.activeWorkspaceID) else { return Array(categories) }
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
                        let swipeConfig = UnifiedSwipeConfig(allowsFullSwipeToDelete: !settings.confirmBeforeDelete)

                        ForEach(filteredCategories, id: \.objectID) { category in
                            categoryRow(for: category, swipeConfig: swipeConfig)
                        }
                        .onDelete { offsets in
                            let targets = offsets.map { filteredCategories[$0] }
                            if settings.confirmBeforeDelete {
                                if let first = targets.first { requestDelete(first) }
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
        if !wrapsInNavigation {
            content()
        } else if #available(iOS 16.0, macCatalyst 16.0, *) {
            NavigationStack { content() }
        } else {
            NavigationView { content() }
        }
    }
    
    // MARK: - Row Builders
    @ViewBuilder
    private func categoryRow(for category: ExpenseCategory, swipeConfig: UnifiedSwipeConfig) -> some View {
        let name = category.name ?? "Untitled"
        CategoryRowView(
            config: swipeConfig,
            label: { rowLabel(for: category) },
            onTap: { categoryToEdit = category },
            onEdit: { categoryToEdit = category },
            onDelete: {
                if settings.confirmBeforeDelete {
                    // Show confirmation (with cascade details if in use)
                    requestDelete(category)
                } else {
                    // Strictly delete without any alert
                    deleteCategory(category)
                }
            }
        )
        .accessibilityElement(children: uiTestingFlags.isUITesting ? .contain : .ignore)
        .accessibilityLabel(Text(name))
        .accessibilityIdentifier(AccessibilityID.Settings.Categories.categoryRow(id: categoryUUID(for: category)))
    }
    
    @ViewBuilder
    private func rowLabel(for category: ExpenseCategory) -> some View {
        let name = category.name ?? "Untitled"
        HStack(spacing: Spacing.m) {
            ColorCircle(hex: category.color ?? "#999999")
            VStack(alignment: .leading) {
                Text(name)
            }
            Spacer()
            Image(systemName: Icons.sfChevronRight)
                .font(Typography.captionSemibold)
                .foregroundStyle(Colors.styleSecondary)
        }
    }

    private func categoryUUID(for category: ExpenseCategory) -> UUID? {
        if let id = category.id { return id }
        return category.value(forKey: "id") as? UUID
    }
    
    // MARK: - Empty State
    private var emptyState: some View {
        DesignSystemV2.EmptyState(message: "No categories found. Tap + to create a category.")
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
        let objectID = cat.objectID
        Task { @MainActor in
            guard !isDeletingCategory else { return }
            isDeletingCategory = true
            defer { isDeletingCategory = false }
            await deleteCategory(objectID: objectID)
        }
    }

    private var deleteCategoryAlertTitle: String {
        let name = pendingDeleteCategoryName.trimmingCharacters(in: .whitespacesAndNewlines)
        return "Delete \(name.isEmpty ? "Category" : name)?"
    }

    private func requestDelete(_ category: ExpenseCategory) {
        pendingDeleteCategoryObjectID = category.objectID
        pendingDeleteCategoryName = category.name ?? "Category"
        isConfirmingDeleteCategory = true
    }

    private func clearPendingCategoryDelete() {
        pendingDeleteCategoryObjectID = nil
        pendingDeleteCategoryName = ""
        isConfirmingDeleteCategory = false
    }

    @MainActor
    private func deleteCategory(objectID: NSManagedObjectID) async {
        let bg = CoreDataService.shared.newBackgroundContext()
        var deletedObjectIDs: [NSManagedObjectID] = []
        do {
            deletedObjectIDs = try await bg.perform {
                guard let category = try? bg.existingObject(with: objectID) as? ExpenseCategory else { return [] }

                func executeBatchDelete(entityName: String, predicate: NSPredicate) throws -> [NSManagedObjectID] {
                    let fetch = NSFetchRequest<NSFetchRequestResult>(entityName: entityName)
                    fetch.predicate = predicate
                    let delete = NSBatchDeleteRequest(fetchRequest: fetch)
                    delete.resultType = .resultTypeObjectIDs
                    let result = try bg.execute(delete) as? NSBatchDeleteResult
                    return (result?.result as? [NSManagedObjectID]) ?? []
                }

                var ids: [NSManagedObjectID] = []
                // Delete dependent expenses first to avoid constraint issues.
                ids.append(contentsOf: try executeBatchDelete(entityName: "PlannedExpense", predicate: NSPredicate(format: "expenseCategory == %@", category)))
                ids.append(contentsOf: try executeBatchDelete(entityName: "UnplannedExpense", predicate: NSPredicate(format: "expenseCategory == %@", category)))
                ids.append(contentsOf: try executeBatchDelete(entityName: "ExpenseCategory", predicate: NSPredicate(format: "self == %@", category)))

                if !bg.registeredObjects.isEmpty {
                    bg.reset()
                }
                return ids
            }
        } catch {
            AppLog.ui.error("Failed to delete category: \(error.localizedDescription)")
        }

        guard !deletedObjectIDs.isEmpty else { return }
        let changes: [AnyHashable: Any] = [NSDeletedObjectsKey: deletedObjectIDs]
        NSManagedObjectContext.mergeChanges(fromRemoteContextSave: changes, into: [viewContext])
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
                            .accessibilityIdentifier(AccessibilityID.Settings.Categories.nameField)
                        Spacer(minLength: 0)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                } header: {
                    Text("Name")
                        .font(Typography.footnote)
                        .foregroundStyle(Colors.styleSecondary)
                        .textCase(.uppercase)
                }
                
                Section {
                    ColorPicker("Color", selection: $color, supportsOpacity: false)
                        .labelsHidden()
                        .frame(maxWidth: .infinity, alignment: .leading)
                } header: {
                    Text("Color")
                        .font(Typography.footnote)
                        .foregroundStyle(Colors.styleSecondary)
                        .textCase(.uppercase)
                }
            }
            .listStyle(.insetGrouped)
            .scrollIndicators(.hidden)
            .navigationTitle("New Category")
            .ub_windowTitle("New Category")
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
                    .accessibilityIdentifier(AccessibilityID.Settings.Categories.cancelButton)
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
                    .accessibilityIdentifier(AccessibilityID.Settings.Categories.saveButton)
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

import SwiftUI
import CoreData

// MARK: - PresetsView
/// Simplified presets list with swipe to edit/delete and glass add button on iOS 26.
struct PresetsView: View {
    // MARK: Env
    @Environment(\.managedObjectContext) private var viewContext

    // MARK: State
    @StateObject private var vm = PresetsViewModel()
    @State private var isPresentingAdd = false
    @State private var sheetTemplateToAssign: PlannedExpense? = nil
    @State private var editingTemplate: PlannedExpense? = nil
    @State private var templateToDelete: PlannedExpense? = nil
    @AppStorage(AppSettingsKeys.confirmBeforeDelete.rawValue) private var confirmBeforeDelete: Bool = true

    var body: some View {
        Group {
            if vm.items.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "list.bullet.rectangle")
                        .font(.system(size: 42))
                        .foregroundStyle(.secondary)
                    Text("Presets").font(.title2.weight(.semibold))
                    Text("Add recurring expenses so budgets are faster to create.")
                        .font(.subheadline).foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, minHeight: 260)
                .padding(.horizontal, 16)
            } else {
                List {
                    ForEach(vm.items) { item in
                        PresetRowView(item: item) { template in
                            sheetTemplateToAssign = template
                        }
                        .listRowInsets(EdgeInsets(top: 12, leading: 16, bottom: 12, trailing: 16))
                        .unifiedSwipeActions(
                            UnifiedSwipeConfig(allowsFullSwipeToDelete: false),
                            onEdit: { editingTemplate = item.template },
                            onDelete: {
                                if confirmBeforeDelete {
                                    templateToDelete = item.template
                                } else {
                                    delete(template: item.template)
                                }
                            }
                        )
                    }
                    .onDelete { indexSet in
                        let targets = indexSet.compactMap { vm.items[safe: $0]?.template }
                        if confirmBeforeDelete, let first = targets.first {
                            templateToDelete = first
                        } else {
                            targets.forEach(delete(template:))
                        }
                    }
                }
                .listStyle(.plain)
            }
        }
        .navigationTitle("Presets")
        .toolbar { toolbarContent }
        .onAppear { vm.loadTemplates(using: viewContext) }
        .onReceive(NotificationCenter.default.publisher(for: .dataStoreDidChange).receive(on: RunLoop.main)) { _ in
            vm.loadTemplates(using: viewContext)
        }
        .refreshable { vm.loadTemplates(using: viewContext) }
        // Add preset
        .sheet(isPresented: $isPresentingAdd) {
            AddGlobalPresetSheet(onSaved: { vm.loadTemplates(using: viewContext) })
                .environment(\.managedObjectContext, viewContext)
        }
        // Assign budgets
        .sheet(item: $sheetTemplateToAssign) { template in
            PresetBudgetAssignmentSheet(template: template) { vm.loadTemplates(using: viewContext) }
                .environment(\.managedObjectContext, viewContext)
        }
        // Edit preset
        .sheet(item: $editingTemplate) { template in
            AddPlannedExpenseView(
                plannedExpenseID: template.objectID,
                preselectedBudgetID: nil,
                defaultSaveAsGlobalPreset: true,
                onSaved: { vm.loadTemplates(using: viewContext) }
            )
            .environment(\.managedObjectContext, viewContext)
        }
        .alert(item: $templateToDelete) { template in
            Alert(
                title: Text("Delete \(template.descriptionText ?? "Preset")?"),
                message: Text("This will remove the preset and its assignments."),
                primaryButton: .destructive(Text("Delete")) { delete(template: template) },
                secondaryButton: .cancel()
            )
        }
    }

    // MARK: Toolbar
    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .primaryAction) {
            // Clear, no-background toolbar icon; consistent with other screens
            Buttons.toolbarIcon("plus") { isPresentingAdd = true }
                .accessibilityLabel("Add Preset Planned Expense")
        }
    }

    // MARK: Actions
    private func delete(template: PlannedExpense) {
        do {
            try PlannedExpenseService.shared.deleteTemplateAndChildren(template: template, in: viewContext)
            vm.loadTemplates(using: viewContext)
        } catch {
            viewContext.rollback()
        }
    }
}

//

// MARK: - AddGlobalPresetSheet (local)
private struct AddGlobalPresetSheet: View {
    let onSaved: () -> Void
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        AddPlannedExpenseView(
            preselectedBudgetID: nil,
            defaultSaveAsGlobalPreset: true,
            showAssignBudgetToggle: true,
            onSaved: {
                onSaved()
                dismiss()
            }
        )
    }
}

// MARK: - Array Safe Indexing helper (local)
private extension Array {
    subscript(safe index: Index) -> Element? { indices.contains(index) ? self[index] : nil }
}

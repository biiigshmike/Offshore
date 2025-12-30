import SwiftUI
import CoreData

// MARK: - PresetsView
/// Simplified presets list with swipe to edit/delete and glass add button on iOS 26.
struct PresetsView: View {
    private let header: AnyView?

    init(header: AnyView? = nil) {
        self.header = header
    }

    // MARK: Env
    @Environment(\.managedObjectContext) private var viewContext
    
    // MARK: State
    @StateObject private var vm = PresetsViewModel()
    private enum ActiveSheet: Identifiable {
        case add
        case assign(NSManagedObjectID)
        case edit(NSManagedObjectID)

        var id: String {
            switch self {
            case .add: return "add"
            case .assign(let id): return "assign:\(id.uriRepresentation().absoluteString)"
            case .edit(let id): return "edit:\(id.uriRepresentation().absoluteString)"
            }
        }
    }

    @State private var activeSheet: ActiveSheet?
    @State private var templateToDelete: PlannedExpense? = nil
    @State private var isMenuActive = false
    @Environment(\.currentSidebarSelection) private var currentSidebarSelection
    @AppStorage(AppSettingsKeys.confirmBeforeDelete.rawValue) private var confirmBeforeDelete: Bool = true

    // Guided walkthrough removed

    var body: some View {
        presetsContent
            .tipsAndHintsOverlay(for: .presets)
            .focusedSceneValue(
                \.newItemCommand,
                isMenuActive || currentSidebarSelection == .managePresets
                ? NewItemCommand(title: "New Preset", action: { activeSheet = .add })
                : nil
            )
    }

    @ViewBuilder
    private var presetsContent: some View {
        Group {
            if vm.items.isEmpty {
                VStack(spacing: DS.Spacing.l) {
                    if let header {
                        header
                            .padding(.horizontal, DS.Spacing.l)
                    }
                    UBEmptyState(message: "No presets found. Tap + to create a preset.")
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            } else {
                let swipeConfig = UnifiedSwipeConfig(allowsFullSwipeToDelete: !confirmBeforeDelete)
                List {
                    if let header {
                        header
                            .listRowInsets(EdgeInsets(top: 12, leading: 16, bottom: 12, trailing: 16))
                            .listRowSeparator(.hidden)
                    }

                    Section {
                        ForEach(vm.items) { item in
                            PresetRowView(item: item) { template in
                                activeSheet = .assign(template.objectID)
                            }
                                .listRowInsets(EdgeInsets(top: 12, leading: 16, bottom: 12, trailing: 16))
                                .unifiedSwipeActions(
                                    swipeConfig,
                                    onEdit: { activeSheet = .edit(item.template.objectID) },
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
                }
                .listStyle(.insetGrouped)
            }
        }
        .navigationTitle("Presets")
        .toolbar { toolbarContent }
        .onAppear {
            isMenuActive = true
            vm.startIfNeeded(using: viewContext)
        }
        .onDisappear { isMenuActive = false }
        .refreshable {
            // Pull-to-refresh: nudge CloudKit and reload list
            CloudSyncAccelerator.shared.nudgeOnForeground()
            vm.loadTemplates(using: viewContext)
        }
        .ub_platformSheet(item: $activeSheet) { sheet in
            switch sheet {
            case .add:
                AddGlobalPresetSheet(onSaved: {
                    vm.loadTemplates(using: viewContext)
                    activeSheet = nil
                })
                .environment(\.managedObjectContext, viewContext)
            case .assign(let objectID):
                if let template = try? viewContext.existingObject(with: objectID) as? PlannedExpense {
                    PresetBudgetAssignmentSheet(template: template) {
                        vm.loadTemplates(using: viewContext)
                        activeSheet = nil
                    }
                    .environment(\.managedObjectContext, viewContext)
                } else {
                    EmptyView()
                }
            case .edit(let objectID):
                if let template = try? viewContext.existingObject(with: objectID) as? PlannedExpense {
                    AddPlannedExpenseView(
                        plannedExpenseID: template.objectID,
                        preselectedBudgetID: nil,
                        defaultSaveAsGlobalPreset: true,
                        onSaved: {
                            vm.loadTemplates(using: viewContext)
                            activeSheet = nil
                        }
                    )
                    .environment(\.managedObjectContext, viewContext)
                } else {
                    EmptyView()
                }
            }
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
            Buttons.toolbarIcon("plus", label: "Add Preset Planned Expense") { activeSheet = .add }
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

    // Guided walkthrough removed
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

import SwiftUI
import CoreData

/// Sheet that allows toggling global planned expense presets for a specific budget.
struct ManageBudgetPresetsSheet: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss

    let budget: Budget
    let onDone: () -> Void

    @FetchRequest private var templates: FetchedResults<PlannedExpense>

    @State private var assignedTemplateObjectIDs: Set<NSManagedObjectID> = []

    init(budget: Budget, onDone: @escaping () -> Void) {
        self.budget = budget
        self.onDone = onDone

        let request: NSFetchRequest<PlannedExpense> = NSFetchRequest(entityName: "PlannedExpense")
        let workspaceID = WorkspaceService.shared.activeWorkspaceID
        request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
            NSPredicate(format: "isGlobal == YES"),
            WorkspaceService.predicate(for: workspaceID)
        ])
        request.sortDescriptors = [
            NSSortDescriptor(
                key: "descriptionText",
                ascending: true,
                selector: #selector(NSString.localizedCaseInsensitiveCompare(_:))
            )
        ]
        _templates = FetchRequest(fetchRequest: request)
    }

    var body: some View {
        navigationContainer {
            Group {
                if templates.isEmpty {
                    emptyState
                } else {
                    List {
                        ForEach(templates, id: \.objectID) { template in
                            presetRow(for: template)
                        }
                    }
                }
            }
            .navigationTitle("Budget Presets")
            .ub_windowTitle("Budget Presets")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done", action: dismissAndComplete)
                }
            }
            .onAppear(perform: loadAssignments)
            .onReceive(
                NotificationCenter.default
                    .publisher(for: .dataStoreDidChange)
                    .debounce(for: .milliseconds(DataChangeDebounce.milliseconds()), scheduler: RunLoop.main)
            ) { _ in
                loadAssignments()
            }
        }
    }

    // MARK: - Rows
    private func presetRow(for template: PlannedExpense) -> some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(template.descriptionText ?? "Untitled Preset")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(2)

                HStack(spacing: 12) {
                    Text("Planned: \(CurrencyFormatter.shared.string(template.plannedAmount))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("Actual: \(CurrencyFormatter.shared.string(template.actualAmount))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .accessibilityElement(children: .combine)
            }

            Spacer(minLength: 12)

            Toggle("", isOn: binding(for: template))
                .labelsHidden()
        }
        .padding(.vertical, 6)
        .contentShape(Rectangle())
    }

    // MARK: - Bindings
    private func binding(for template: PlannedExpense) -> Binding<Bool> {
        Binding<Bool>(
            get: { assignedTemplateObjectIDs.contains(template.objectID) },
            set: { newValue in updateAssignment(for: template, shouldAssign: newValue) }
        )
    }

    private func updateAssignment(for template: PlannedExpense, shouldAssign: Bool) {
        guard let budgetInContext = try? viewContext.existingObject(with: budget.objectID) as? Budget else {
            return
        }

        let workspaceID = (budgetInContext.value(forKey: "workspaceID") as? UUID)
            ?? WorkspaceService.shared.activeWorkspaceID
        if shouldAssign {
            PlannedExpenseService.shared.ensureChild(from: template, attachedTo: budgetInContext, in: viewContext, workspaceID: workspaceID)
            assignedTemplateObjectIDs.insert(template.objectID)
        } else {
            PlannedExpenseService.shared.removeChild(from: template, for: budgetInContext, in: viewContext, workspaceID: workspaceID)
            assignedTemplateObjectIDs.remove(template.objectID)
        }

        do {
            if viewContext.hasChanges {
                try viewContext.save()
            }
        } catch {
            AppLog.ui.error("ManageBudgetPresetsSheet toggle error: \(String(describing: error))")
            viewContext.rollback()
            loadAssignments()
        }
    }

    // MARK: - Data
    private func loadAssignments() {
        guard let budgetInContext = try? viewContext.existingObject(with: budget.objectID) as? Budget else {
            assignedTemplateObjectIDs = []
            return
        }

        let request: NSFetchRequest<PlannedExpense> = NSFetchRequest(entityName: "PlannedExpense")
        let workspaceID = (budgetInContext.value(forKey: "workspaceID") as? UUID)
            ?? WorkspaceService.shared.activeWorkspaceID
        request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
            NSPredicate(format: "budget == %@", budgetInContext),
            NSPredicate(format: "isGlobal == NO"),
            NSPredicate(format: "globalTemplateID != nil"),
            WorkspaceService.predicate(for: workspaceID)
        ])

        let existingInstances = (try? viewContext.fetch(request)) ?? []
        let assignedIDs = Set(existingInstances.compactMap { $0.globalTemplateID })

        var resolved: Set<NSManagedObjectID> = []
        for template in templates {
            if let templateID = template.id, assignedIDs.contains(templateID) {
                resolved.insert(template.objectID)
            }
        }
        assignedTemplateObjectIDs = resolved
    }

    private func dismissAndComplete() {
        dismiss()
        onDone()
    }

    // MARK: - Empty State
    private var emptyState: some View {
        VStack(spacing: DS.Spacing.m) {
            Image(systemName: "list.bullet.rectangle")
                .font(.system(size: 44, weight: .regular))
                .foregroundStyle(.secondary)
            Text("No Presets Available")
                .font(.headline)
            Text("Create presets from the Presets tab to assign them to this budget.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, DS.Spacing.xl)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        .padding()
    }

    // MARK: - Navigation container helper
    @ViewBuilder
    private func navigationContainer<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        if #available(iOS 16.0, macCatalyst 16.0, *) {
            NavigationStack { content() }
        } else {
            NavigationView { content() }
        }
    }
}

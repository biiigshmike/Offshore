import SwiftUI
import CoreData

/// Sheet that allows toggling global planned expense presets for a specific budget.
struct ManageBudgetPresetsSheet: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.platformCapabilities) private var capabilities
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var themeManager: ThemeManager

    let budget: Budget
    let onDone: () -> Void

    @FetchRequest private var templates: FetchedResults<PlannedExpense>

    @State private var assignedTemplateObjectIDs: Set<NSManagedObjectID> = []
    @State private var isCloseButtonPressed: Bool = false

    init(budget: Budget, onDone: @escaping () -> Void) {
        self.budget = budget
        self.onDone = onDone

        let request: NSFetchRequest<PlannedExpense> = NSFetchRequest(entityName: "PlannedExpense")
        request.predicate = NSPredicate(format: "isGlobal == YES")
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
                        Section {
                            ForEach(templates, id: \.objectID) { template in
                                presetRow(for: template)
                            }
                        }
                    }
                    .ub_listStyleLiquidAware()
                }
            }
            .navigationTitle("Budget Presets")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) { closeButton }
            }
            .onAppear(perform: loadAssignments)
            .onReceive(
                NotificationCenter.default.publisher(for: .dataStoreDidChange)
                    .receive(on: RunLoop.main)
            ) { _ in
                loadAssignments()
            }
        }
        .ub_navigationBackground(
            theme: themeManager.selectedTheme,
            configuration: themeManager.glassConfiguration
        )
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

        if shouldAssign {
            PlannedExpenseService.shared.ensureChild(from: template, attachedTo: budgetInContext, in: viewContext)
            assignedTemplateObjectIDs.insert(template.objectID)
        } else {
            PlannedExpenseService.shared.removeChild(from: template, for: budgetInContext, in: viewContext)
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
        request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
            NSPredicate(format: "budget == %@", budgetInContext),
            NSPredicate(format: "isGlobal == NO"),
            NSPredicate(format: "globalTemplateID != nil")
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

    // MARK: - Close
    private var closeButton: some View {
        Group {
            if capabilities.supportsOS26Translucency,
               #available(iOS 26.0, macOS 26.0, macCatalyst 26.0, *) {
                Button(action: closeSheet) {
                    Image(systemName: "xmark")
                        .font(.system(size: 16, weight: .semibold))
                        .frame(width: 34, height: 34)
                }
                .buttonStyle(.glass)
                .tint(themeManager.selectedTheme.glassPalette.accent)
                .pressFeedback(isPressed: $isCloseButtonPressed)
                .scaleEffect(isCloseButtonPressed ? 0.88 : 1.0)
                .animation(.spring(response: 0.32, dampingFraction: 0.68), value: isCloseButtonPressed)
                .accessibilityLabel("Close")
            } else {
                Button(action: closeSheet) {
                    Image(systemName: "xmark")
                        .font(.system(size: 16, weight: .semibold))
                }
                .buttonStyle(
                    TranslucentButtonStyle(
                        tint: themeManager.selectedTheme.resolvedTint,
                        metrics: .calendarNavigationIcon,
                        appearance: .neutral
                    )
                )
                .accessibilityLabel("Close")
            }
        }
    }

    private func closeSheet() {
        isCloseButtonPressed = false
        withAnimation(.spring(response: 0.32, dampingFraction: 0.78)) {
            dismiss()
        }
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

// MARK: - Press Feedback Modifier
private struct PressFeedbackModifier: ViewModifier {
    @Binding var isPressed: Bool

    func body(content: Content) -> some View {
        content
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in
                        if !isPressed { isPressed = true }
                    }
                    .onEnded { _ in
                        isPressed = false
                    }
            )
    }
}

private extension View {
    func pressFeedback(isPressed: Binding<Bool>) -> some View {
        modifier(PressFeedbackModifier(isPressed: isPressed))
    }
}

//
//  PresetBudgetAssignmentSheet.swift
//  SoFar
//
//  Created by Michael Brown on 8/14/25.
//

import SwiftUI
import CoreData

// MARK: - PresetBudgetAssignmentSheet
/// Sheet that lists all budgets with a toggle to assign/unassign the given
/// global template. Assigning creates a child PlannedExpense linked to the
/// selected budget; unassigning deletes that child.
struct PresetBudgetAssignmentSheet: View {

    // MARK: Environment
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var themeManager: ThemeManager
    @AppStorage(AppSettingsKeys.confirmBeforeDelete.rawValue)
    private var confirmBeforeDelete: Bool = true

    // MARK: Inputs
    let template: PlannedExpense
    var onChangesCommitted: (() -> Void)?

    // MARK: State
    @State private var budgets: [Budget] = []
    @State private var membership: [UUID: Bool] = [:] // Budget.id : isAssigned
    @State private var isConfirmingDelete: Bool = false
    @State private var budgetPendingDeletion: NSManagedObjectID?
    @State private var editingBudgetBox: ObjectIDBox?

    // MARK: Body
    var body: some View {
        navigationContainer {
            List {
                ForEach(budgets, id: \.self) { budget in
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(budget.name ?? "Untitled Budget")
                                .font(.body)
                            if let s = budget.startDate, let e = budget.endDate {
                                Text(dateSpanLabel(start: s, end: e))
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        Spacer()
                        Toggle("", isOn: Binding<Bool>(
                            get: { isAssigned(to: budget) },
                            set: { newValue in toggleAssignment(for: budget, to: newValue) }
                        ))
                        .labelsHidden()
                    }
                    .unifiedSwipeActions(
                        UnifiedSwipeConfig(allowsFullSwipeToDelete: !confirmBeforeDelete),
                        onEdit: { editingBudgetBox = ObjectIDBox(id: budget.objectID) },
                        onDelete: { requestDeleteBudget(budget) }
                    )
                    .padding(.vertical, 6)
                }
            }
            .navigationTitle("Assign to Budgets")
            .toolbar {
                // MARK: Toolbar Buttons
                // Cross-platform placements:
                #if os(iOS)
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        saveContext()
                        onChangesCommitted?()
                        dismiss()
                    }
                    .font(.headline)
                }
                #else
                // macOS fallback
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        saveContext()
                        onChangesCommitted?()
                        dismiss()
                    }
                    .font(.headline)
                }
                #endif
            }
            .onAppear { reload() }
        }
        .ub_navigationBackground(
            theme: themeManager.selectedTheme,
            configuration: themeManager.glassConfiguration
        )
        .alert("Delete Budget?", isPresented: $isConfirmingDelete) {
            Button("Delete", role: .destructive) { performDeleteBudget() }
            Button("Cancel", role: .cancel) { budgetPendingDeletion = nil }
        } message: {
            Text("This action cannot be undone.")
        }
        .sheet(item: $editingBudgetBox) { box in
            if let budget = try? CoreDataService.shared.viewContext.existingObject(with: box.id) as? Budget {
                let start = budget.startDate ?? Date()
                let end = budget.endDate ?? Date()
                AddBudgetView(
                    editingBudgetObjectID: budget.objectID,
                    fallbackStartDate: start,
                    fallbackEndDate: end,
                    onSaved: {
                        reload()
                        onChangesCommitted?()
                    }
                )
                .environment(\.managedObjectContext, CoreDataService.shared.viewContext)
            } else {
                Text("Budget not found")
            }
        }
    }

    // MARK: - Navigation container (iOS 16+/macOS 13+ NavigationStack; older NavigationView)
    @ViewBuilder
    private func navigationContainer<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        if #available(iOS 16.0, macCatalyst 16.0, *) {
            NavigationStack { content() }
        } else {
            NavigationView { content() }
        }
    }

    // MARK: - Load
    /// Loads budgets and current assignment membership.
    private func reload() {
        budgets = PlannedExpenseService.shared.fetchAllBudgets(in: viewContext)
        let children = PlannedExpenseService.shared.fetchChildren(of: template, in: viewContext)
        let assignedBudgetIDs = Set(children.compactMap { $0.budget?.id })
        membership = [:]
        for b in budgets {
            guard let id = b.id else { continue }
            membership[id] = assignedBudgetIDs.contains(id)
        }
    }

    // MARK: - Membership Utilities
    private func isAssigned(to budget: Budget) -> Bool {
        guard let id = budget.id else { return false }
        return membership[id] ?? false
    }

    private func toggleAssignment(for budget: Budget, to newValue: Bool) {
        guard let budgetID = budget.id else { return }
        if newValue {
            PlannedExpenseService.shared.ensureChild(from: template, attachedTo: budget, in: viewContext)
        } else {
            PlannedExpenseService.shared.removeChild(from: template, for: budget, in: viewContext)
        }
        membership[budgetID] = newValue
    }

    // MARK: - Delete Budget (Swipe)
    private func requestDeleteBudget(_ budget: Budget) {
        if confirmBeforeDelete {
            budgetPendingDeletion = budget.objectID
            isConfirmingDelete = true
        } else {
            budgetPendingDeletion = budget.objectID
            performDeleteBudget()
        }
    }

    private func performDeleteBudget() {
        guard let id = budgetPendingDeletion else { return }
        budgetPendingDeletion = nil
        do {
            if let budget = try viewContext.existingObject(with: id) as? Budget {
                try BudgetService().deleteBudget(budget)
                // Refresh local list and membership map
                reload()
                onChangesCommitted?()
            }
        } catch {
            AppLog.ui.error("PresetBudgetAssignmentSheet delete budget error: \(String(describing: error))")
        }
    }

    // MARK: - Save
    private func saveContext() {
        guard viewContext.hasChanges else { return }
        do { try viewContext.save() } catch {
            AppLog.ui.error("PresetBudgetAssignmentSheet save error: \(String(describing: error))")
        }
    }

    // MARK: - Formatting
    private func dateSpanLabel(start: Date, end: Date) -> String {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .none
        return "\(f.string(from: start)) – \(f.string(from: end))"
    }
}

// MARK: - ObjectIDBox (for sheet identity)
private struct ObjectIDBox: Identifiable {
    let id: NSManagedObjectID
}

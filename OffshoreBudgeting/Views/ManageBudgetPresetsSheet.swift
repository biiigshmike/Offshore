import SwiftUI
import CoreData
import Combine

/// Sheet that lets a user attach or detach global presets for a specific budget.
struct ManageBudgetPresetsSheet: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var themeManager: ThemeManager
    @Environment(\.platformCapabilities) private var capabilities

    let budget: Budget
    let onDone: () -> Void

    @State private var templates: [PlannedExpense] = []
    @State private var assignments: [UUID: Bool] = [:]
    @State private var hasNotifiedCompletion = false

    var body: some View {
        navigationContainer {
            content
                .navigationTitle("Budget Presets")
                .toolbar { closeToolbar }
                .onAppear(perform: reload)
                .onReceive(
                    NotificationCenter.default
                        .publisher(for: .dataStoreDidChange)
                        .receive(on: RunLoop.main)
                ) { _ in
                    reload()
                }
        }
        .ub_navigationBackground(
            theme: themeManager.selectedTheme,
            configuration: themeManager.glassConfiguration
        )
        .onDisappear(perform: notifyCompletionIfNeeded)
    }

    @ViewBuilder
    private var content: some View {
        if templates.isEmpty {
            List {
                Section {
                    UBEmptyState(
                        iconSystemName: "list.bullet.rectangle",
                        title: "No Presets Available",
                        message: "Create presets from the Presets tab to assign them to this budget."
                    )
                    .padding(.vertical, DS.Spacing.xl)
                    .frame(maxWidth: .infinity)
                    .listRowInsets(
                        EdgeInsets(top: 32, leading: DS.Spacing.l, bottom: 32, trailing: DS.Spacing.l)
                    )
                    .listRowBackground(Color.clear)
                }
            }
            .ub_listStyleLiquidAware()
        } else {
            List {
                ForEach(templates, id: \.objectID) { template in
                    BudgetPresetToggleRow(
                        title: template.descriptionText ?? "Untitled Preset",
                        plannedAmountText: plannedAmountText(for: template),
                        nextDueText: nextDueText(for: template),
                        isAssigned: binding(for: template)
                    )
                    .listRowInsets(
                        EdgeInsets(top: 12, leading: DS.Spacing.m, bottom: 12, trailing: DS.Spacing.m)
                    )
                    .ub_preOS26ListRowBackground(themeManager.selectedTheme.background)
                }
            }
            .ub_listStyleLiquidAware()
        }
    }

    private func binding(for template: PlannedExpense) -> Binding<Bool> {
        Binding(
            get: {
                guard let id = template.id else { return false }
                return assignments[id] ?? false
            },
            set: { newValue in
                guard let id = template.id else { return }
                assignments[id] = newValue
                if newValue {
                    PlannedExpenseService.shared.ensureChild(
                        from: template,
                        attachedTo: budget,
                        in: viewContext
                    )
                } else {
                    PlannedExpenseService.shared.removeChild(
                        from: template,
                        for: budget,
                        in: viewContext
                    )
                }
                saveContext()
            }
        )
    }

    private func reload() {
        templates = PlannedExpenseService.shared.fetchGlobalTemplates(in: viewContext)
        var snapshot: [UUID: Bool] = [:]
        for template in templates {
            guard let id = template.id else { continue }
            let isAssigned = PlannedExpenseService.shared.child(
                of: template,
                for: budget,
                in: viewContext
            ) != nil
            snapshot[id] = isAssigned
        }
        assignments = snapshot
    }

    private func saveContext() {
        guard viewContext.hasChanges else { return }
        do {
            try viewContext.save()
        } catch {
            AppLog.ui.error("ManageBudgetPresetsSheet save error: \(String(describing: error))")
            viewContext.rollback()
        }
    }

    private func closeSheet() {
        saveContext()
        notifyCompletionIfNeeded()
        withAnimation(.spring(response: 0.34, dampingFraction: 0.78)) {
            dismiss()
        }
    }

    private func notifyCompletionIfNeeded() {
        guard !hasNotifiedCompletion else { return }
        hasNotifiedCompletion = true
        onDone()
    }

    private func plannedAmountText(for template: PlannedExpense) -> String {
        CurrencyFormatter.shared.string(template.plannedAmount)
    }

    private func nextDueText(for template: PlannedExpense) -> String? {
        guard let date = template.transactionDate else { return nil }
        return Self.dueDateFormatter.string(from: date)
    }

    @ToolbarContentBuilder
    private var closeToolbar: some ToolbarContent {
        ToolbarItem(placement: .navigationBarTrailing) {
            closeButton
        }
    }

    @ViewBuilder
    private var closeButton: some View {
        if capabilities.supportsOS26Translucency,
           #available(iOS 26.0, macOS 26.0, macCatalyst 26.0, *) {
            Button(action: closeSheet) {
                RootHeaderControlIcon(systemImage: "xmark")
                    .frame(width: RootHeaderActionMetrics.dimension(for: capabilities),
                           height: RootHeaderActionMetrics.dimension(for: capabilities))
            }
            .buttonStyle(.glass)
            .buttonBorderShape(.circle)
            .tint(themeManager.selectedTheme.resolvedTint)
            .accessibilityLabel("Close Budget Presets")
        } else {
            RootHeaderGlassControl(sizing: .icon) {
                Button(action: closeSheet) {
                    RootHeaderControlIcon(systemImage: "xmark")
                }
                .buttonStyle(RootHeaderActionButtonStyle())
                .accessibilityLabel("Close Budget Presets")
            }
        }
    }

    @ViewBuilder
    private func navigationContainer<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        if #available(iOS 16.0, macCatalyst 16.0, *) {
            NavigationStack { content() }
        } else {
            NavigationView { content() }
                .navigationViewStyle(StackNavigationViewStyle())
        }
    }

    private static let dueDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }()
}

private struct BudgetPresetToggleRow: View {
    let title: String
    let plannedAmountText: String
    let nextDueText: String?
    @Binding var isAssigned: Bool

    var body: some View {
        HStack(spacing: DS.Spacing.m) {
            VStack(alignment: .leading, spacing: DS.Spacing.xs) {
                Text(title)
                    .font(.body)
                    .foregroundStyle(.primary)
                HStack(spacing: DS.Spacing.xs) {
                    Text(plannedAmountText)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    if let nextDueText {
                        Text("•")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(nextDueText)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            Spacer()
            Toggle("", isOn: $isAssigned)
                .labelsHidden()
        }
        .padding(.vertical, DS.Spacing.xs)
    }
}

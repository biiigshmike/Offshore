import SwiftUI
import CoreData

// MARK: - PresetsView
/// Simplified presets list with swipe to edit/delete and glass add button on iOS 26.
struct PresetsView: View {
    // MARK: Env
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject private var guidedWalkthrough: GuidedWalkthroughManager

    // MARK: State
    @StateObject private var vm = PresetsViewModel()
    @State private var isPresentingAdd = false
    @State private var sheetTemplateToAssign: PlannedExpense? = nil
    @State private var editingTemplate: PlannedExpense? = nil
    @State private var templateToDelete: PlannedExpense? = nil
    @AppStorage(AppSettingsKeys.confirmBeforeDelete.rawValue) private var confirmBeforeDelete: Bool = true

    // MARK: Guided Walkthrough State
    @State private var showGuidedOverlay: Bool = false
    @State private var requestedGuidedWalkthrough: Bool = false
    @State private var visibleGuidedHints: Set<GuidedWalkthroughManager.Hint> = []
    @State private var guidedHintWorkItems: [GuidedWalkthroughManager.Hint: DispatchWorkItem] = [:]

    var body: some View {
        ZStack {
            presetsContent
            if showGuidedOverlay, let overlay = guidedWalkthrough.overlay(for: .presets) {
                GuidedOverlayView(
                    overlay: overlay,
                    onDismiss: {
                        showGuidedOverlay = false
                        guidedWalkthrough.markOverlaySeen(for: .presets)
                    },
                    nextAction: presentPresetsHints
                )
                .transition(.opacity)
            }
        }
        .onAppear { requestPresetsGuidedIfNeeded() }
        .onDisappear { cancelPresetsHintWork() }
    }

    @ViewBuilder
    private var presetsContent: some View {
        Group {
            if vm.items.isEmpty {
                ScrollView {
                    VStack(spacing: 12) {
                        Image(systemName: "list.bullet.rectangle")
                            .font(.system(size: 42))
                            .foregroundStyle(.secondary)
                        Text("No Presets Found").font(.title2.weight(.semibold))
                        Text("Press + to add a Preset Expense.\nPresets make creating budgets faster\nand can be reused again and again.")
                            .font(.subheadline).foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, minHeight: 260, alignment: .center)
                    .padding(.horizontal, 16)
                }
                .frame(maxWidth: .infinity, alignment: .top)
            } else {
                List {
                    let swipeConfig = UnifiedSwipeConfig(allowsFullSwipeToDelete: !confirmBeforeDelete)
                    let firstID = vm.items.first?.id

                    ForEach(vm.items) { item in
                        PresetRowView(item: item) { template in
                            hidePresetsHint(.presetsAssignments)
                            sheetTemplateToAssign = template
                        }
                        .listRowInsets(EdgeInsets(top: 12, leading: 16, bottom: 12, trailing: 16))
                        .unifiedSwipeActions(
                            swipeConfig,
                            onEdit: { editingTemplate = item.template },
                            onDelete: {
                                if confirmBeforeDelete {
                                    templateToDelete = item.template
                                } else {
                                    delete(template: item.template)
                                }
                            }
                        )
                        .overlay(alignment: .topTrailing) {
                            if visibleGuidedHints.contains(.presetsAssignments),
                               let bubble = presetsHintLookup[.presetsAssignments],
                               item.id == firstID {
                                HintBubbleView(hint: bubble)
                                    .offset(x: -4, y: -10)
                            }
                        }
                        .overlay(alignment: .bottomTrailing) {
                            if visibleGuidedHints.contains(.presetsNextDate),
                               let bubble = presetsHintLookup[.presetsNextDate],
                               item.id == firstID {
                                HintBubbleView(hint: bubble)
                                    .offset(x: -20, y: 24)
                            }
                        }
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
        .onAppear { vm.startIfNeeded(using: viewContext) }
        .refreshable { vm.loadTemplates(using: viewContext) }
        .sheet(isPresented: $isPresentingAdd) {
            AddGlobalPresetSheet(onSaved: { vm.loadTemplates(using: viewContext) })
                .environment(\.managedObjectContext, viewContext)
        }
        .sheet(item: $sheetTemplateToAssign) { template in
            PresetBudgetAssignmentSheet(template: template) { vm.loadTemplates(using: viewContext) }
                .environment(\.managedObjectContext, viewContext)
        }
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
            Buttons.toolbarIcon("plus") {
                hidePresetsHint(.presetsAssignments)
                hidePresetsHint(.presetsNextDate)
                isPresentingAdd = true
            }
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

    // MARK: Guided Walkthrough Helpers
    private var presetsHintLookup: [GuidedWalkthroughManager.Hint: HintBubble] {
        Dictionary(uniqueKeysWithValues: guidedWalkthrough.hints(for: .presets).map { ($0.id, $0) })
    }

    private func requestPresetsGuidedIfNeeded() {
        guard !requestedGuidedWalkthrough else { return }
        requestedGuidedWalkthrough = true
        if guidedWalkthrough.shouldShowOverlay(for: .presets) {
            withAnimation(.easeInOut(duration: 0.3)) {
                showGuidedOverlay = true
            }
        } else {
            presentPresetsHints()
        }
    }

    private func presentPresetsHints() {
        for bubble in guidedWalkthrough.hints(for: .presets) where guidedWalkthrough.shouldShowHint(bubble.id) {
            displayPresetsHint(bubble.id)
        }
    }

    private func displayPresetsHint(_ hint: GuidedWalkthroughManager.Hint) {
        guard guidedWalkthrough.shouldShowHint(hint) else { return }
        guard !visibleGuidedHints.contains(hint) else { return }
        withAnimation(.easeInOut(duration: 0.25)) {
            visibleGuidedHints.insert(hint)
        }
        schedulePresetsHintAutoHide(for: hint)
    }

    private func schedulePresetsHintAutoHide(for hint: GuidedWalkthroughManager.Hint) {
        guidedHintWorkItems[hint]?.cancel()
        let work = DispatchWorkItem {
            if visibleGuidedHints.contains(hint) {
                withAnimation(.easeInOut(duration: 0.3)) {
                    visibleGuidedHints.remove(hint)
                }
            }
            guidedWalkthrough.markHintSeen(hint)
            guidedHintWorkItems[hint] = nil
        }
        guidedHintWorkItems[hint] = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 6.0, execute: work)
    }

    private func hidePresetsHint(_ hint: GuidedWalkthroughManager.Hint) {
        if let work = guidedHintWorkItems.removeValue(forKey: hint) {
            work.cancel()
        }
        if visibleGuidedHints.contains(hint) {
            withAnimation(.easeInOut(duration: 0.2)) {
                visibleGuidedHints.remove(hint)
            }
        }
        guidedWalkthrough.markHintSeen(hint)
    }

    private func cancelPresetsHintWork() {
        for (_, work) in guidedHintWorkItems { work.cancel() }
        guidedHintWorkItems.removeAll()
        visibleGuidedHints.removeAll()
        showGuidedOverlay = false
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

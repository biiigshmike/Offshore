import SwiftUI
import CoreData
#if canImport(UIKit)
import UIKit
#endif

// MARK: - PresetsView
/// Simplified presets list with swipe to edit/delete and glass add button on iOS 26.
struct PresetsView: View {
    // MARK: Env
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject private var tour: GuidedTourState
    @Environment(\.guidedTourScreen) private var guidedTourScreen

    // MARK: State
    @StateObject private var vm = PresetsViewModel()
    @State private var isPresentingAdd = false
    @State private var sheetTemplateToAssign: PlannedExpense? = nil
    @State private var editingTemplate: PlannedExpense? = nil
    @State private var templateToDelete: PlannedExpense? = nil
    @AppStorage(AppSettingsKeys.confirmBeforeDelete.rawValue) private var confirmBeforeDelete: Bool = true

    // MARK: Guided Tour State
    @State private var showTourOverlay = false
    @State private var activeHints: Set<PresetsHint> = []

    private enum PresetsHint: String, CaseIterable, Hashable {
        case add
        case row

        var anchorID: String { "presets.hint.\(rawValue)" }

        var icon: String {
            switch self {
            case .add: return "plus"
            case .row: return "line.3.horizontal.decrease"
            }
        }

        var text: String {
            switch self {
            case .add:
                return "Save frequently used expenses as presets so budgets start faster."
            case .row:
                return "Swipe a preset to edit details or delete it when you no longer need it."
            }
        }

        var arrowDirection: GuidedHintBubble.ArrowDirection { .down }
    }

    var body: some View {
        ZStack {
            presetsContent
                .guidedHintOverlay { geometry, anchors in
                    presetsHintsOverlay(geometry: geometry, anchors: anchors)
                }

            if showTourOverlay {
                GuidedTourOverlay(
                    title: "Reuse your best expenses",
                    message: presetsOverlayMessage,
                    bullets: presetsOverlayBullets,
                    onClose: handlePresetsOverlayDismiss
                )
                .transition(.opacity)
                .zIndex(1)
            }
        }
    }

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
                .guidedHintAnchor(PresetsHint.row.anchorID)
            }
        }
        .navigationTitle("Presets")
        .toolbar { toolbarContent }
        .onAppear { vm.loadTemplates(using: viewContext) }
        .onReceive(
            NotificationCenter.default
                .publisher(for: .dataStoreDidChange)
                .debounce(for: .milliseconds(DataChangeDebounce.milliseconds()), scheduler: RunLoop.main)
        ) { _ in
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
        .onReceive(NotificationCenter.default.publisher(for: .guidedTourDidReset)) { _ in
            handlePresetsTourReset()
        }
    }

    // MARK: Guided Tour
    private func evaluatePresetsTourState() {
        guard isPresetsViewActive else { return }
        if tour.needsOverlay(.presets) {
            if !showTourOverlay {
                withAnimation(.easeInOut(duration: 0.25)) {
                    showTourOverlay = true
                }
                AppLog.ui.info("GuidedTour overlayShown screen=presets")
            }
            activeHints.removeAll()
            return
        }

        if showTourOverlay {
            showTourOverlay = false
        }

        presentPresetsHintsIfNeeded()
    }

    private func presentPresetsHintsIfNeeded() {
        guard isPresetsViewActive, !showTourOverlay else { return }

        guard tour.needsHints(.presets) else {
            activeHints.removeAll()
            return
        }

        let hints = resolvedPresetsHints()
        let desired = Set(hints)
        if desired != activeHints {
            activeHints = desired
            AppLog.ui.info("GuidedTour hintsShown screen=presets count=\(desired.count)")
        }
    }

    private func resolvedPresetsHints() -> [PresetsHint] {
        var hints: [PresetsHint] = [.add]
        if !vm.items.isEmpty { hints.append(.row) }
        return hints
    }

    private func handlePresetsOverlayDismiss() {
        tour.markOverlaySeen(.presets)
        withAnimation(.easeInOut(duration: 0.25)) {
            showTourOverlay = false
        }
        AppLog.ui.info("GuidedTour overlayDismissed screen=presets")
        presentPresetsHintsIfNeeded()
    }

    private func dismissPresetsHint(_ hint: PresetsHint) {
        activeHints.remove(hint)
        if activeHints.isEmpty {
            tour.markHintsDismissed(.presets)
            AppLog.ui.info("GuidedTour hintsCompleted screen=presets")
        }
    }

    private func handlePresetsTourReset() {
        showTourOverlay = false
        activeHints.removeAll()
        evaluatePresetsTourState()
    }

    private var isPresetsViewActive: Bool {
        guidedTourScreen == nil || guidedTourScreen == .presets
    }

    private var presetsOverlayMessage: String {
        if vm.items.isEmpty {
            return "Create presets for recurring expenses so you can add them to budgets with a tap."
        }
        return "Manage reusable expenses from here and assign them to any budget when needed."
    }

    private var presetsOverlayBullets: [String] {
        if vm.items.isEmpty {
            return [
                "Tap the plus button to save your first preset.",
                "Presets bundle common fields so future budgets start faster."
            ]
        }
        return [
            "Swipe a preset row to assign it, edit details, or delete it.",
            "Use presets to keep your budget templates consistent."
        ]
    }

    @ViewBuilder
    private func presetsHintsOverlay(geometry: GeometryProxy, anchors: [String: Anchor<CGRect>]) -> some View {
        let ordered = PresetsHint.allCases.filter { activeHints.contains($0) }
        ForEach(ordered, id: \.self) { hint in
            if let frame = geometry.frame(forHint: hint.anchorID, anchors: anchors) {
                presetsHintBubble(for: hint, frame: frame, geometry: geometry)
            }
        }
    }

    @ViewBuilder
    private func presetsHintBubble(for hint: PresetsHint, frame: CGRect, geometry: GeometryProxy) -> some View {
        let bubble = GuidedHintBubble(
            icon: hint.icon,
            text: hint.text,
            arrowDirection: hint.arrowDirection
        ) { dismissPresetsHint(hint) }

        let position = presetsHintPosition(for: hint, frame: frame, geometry: geometry)

        bubble
            .position(x: position.x, y: position.y)
            .transition(.opacity.combined(with: .scale))
            .zIndex(1)
    }

    private func presetsHintPosition(for hint: PresetsHint, frame: CGRect, geometry: GeometryProxy) -> CGPoint {
        let width = geometry.size.width.isFinite ? geometry.size.width : UIScreen.main.bounds.width
        let minX: CGFloat = 120
        let maxX: CGFloat = max(minX, width - 120)
        let x = clamp(frame.midX, min: minX, max: maxX)

        switch hint {
        case .add:
            let y = max(frame.minY - 60, 60)
            return CGPoint(x: x, y: y)
        case .row:
            let y = max(frame.minY - 60, 120)
            return CGPoint(x: x, y: y)
        }
    }

    private func clamp(_ value: CGFloat, min: CGFloat, max: CGFloat) -> CGFloat {
        guard min < max else { return value }
        if value < min { return min }
        if value > max { return max }
        return value
    }
    // MARK: Toolbar
    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .primaryAction) {
            // Clear, no-background toolbar icon; consistent with other screens
            Buttons.toolbarIcon("plus") { isPresentingAdd = true }
                .accessibilityLabel("Add Preset Planned Expense")
                .guidedHintAnchor(PresetsHint.add.anchorID)
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

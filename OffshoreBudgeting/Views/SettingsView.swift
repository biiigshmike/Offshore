import SwiftUI
import CoreData
#if canImport(UIKit)
import UIKit
#endif

// MARK: - SettingsView
/// Simplified Settings screen using plain SwiftUI containers.
/// Layout mirrors the original: grouped cards with rows and toggles.
struct SettingsView: View {
    // MARK: Env
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject private var tour: GuidedTourState
    @Environment(\.guidedTourScreen) private var guidedTourScreen

    // MARK: State
    @StateObject private var vm = SettingsViewModel()
    @AppStorage("didCompleteOnboarding") private var didCompleteOnboarding: Bool = false
    @State private var showResetAlert = false
    @State private var showMergeConfirm = false
    @State private var isMerging = false
    @State private var showMergeDone = false
    @State private var showDisableCloudOptions = false
    @State private var isReconfiguringStores = false

    // MARK: Guided Tour State
    @State private var showTourOverlay = false
    @State private var showSettingsHint = false

    private enum SettingsHint: String {
        case repeatOnboarding

        var anchorID: String { "settings.hint.\(rawValue)" }

        var text: String {
            "Replay onboarding to revisit the guided walkthrough."
        }
    }

    var body: some View {
        ZStack {
            settingsContent
                .guidedHintOverlay { geometry, anchors in
                    settingsHintOverlay(geometry: geometry, anchors: anchors)
                }

            if showTourOverlay {
                GuidedTourOverlay(
                    title: "Fine-tune Offshore",
                    message: settingsOverlayMessage,
                    bullets: settingsOverlayBullets,
                    onClose: handleSettingsOverlayDismiss
                )
                .transition(.opacity)
                .zIndex(1)
            }
        }
    }

    private var settingsContent: some View {
        ScrollView {
            VStack(spacing: 16) {
                // General
                SettingsCard(
                    iconSystemName: "gearshape",
                    title: "General",
                    subtitle: "Manage default behaviors."
                ) {
                    VStack(spacing: 0) {
                        SettingsRow(title: "Confirm Before Deleting", showsTopDivider: false) {
                            Toggle("", isOn: $vm.confirmBeforeDelete).labelsHidden()
                        }
                        SettingsRow(title: "Default Budget Period") {
                            Picker("", selection: $vm.budgetPeriod) {
                                ForEach(BudgetPeriod.selectableCases) { Text($0.displayName).tag($0) }
                            }
                            .labelsHidden()
                        }
                    }
                }

                // Expense Categories
                SettingsCard(
                    iconSystemName: "tag",
                    title: "Expense Categories",
                    subtitle: "Manage expense categories for Variable Expenses."
                ) {
                    VStack(spacing: 0) {
                        NavigationLink {
                            ExpenseCategoryManagerView()
                                .environment(\.managedObjectContext, viewContext)
                        } label: {
                            SettingsRow(title: "Manage Categories", detail: "Open", showsTopDivider: false) {
                                Image(systemName: "chevron.right").foregroundStyle(.secondary)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }

                // iCloud Sync
                SettingsCard(
                    iconSystemName: "icloud",
                    title: "iCloud",
                    subtitle: "Manage CloudKit sync and status."
                ) {
                    VStack(spacing: 0) {
                        SettingsRow(title: "Enable iCloud Sync", showsTopDivider: false) {
                            Toggle("", isOn: Binding(
                                get: { vm.enableCloudSync },
                                set: { newValue in
                                    // Intercept disabling to ask user what to do with data.
                                    if vm.enableCloudSync && newValue == false {
                                        // Do not flip the toggle yet; present options.
                                        showDisableCloudOptions = true
                                        return
                                    }
                                    // Enabling: apply immediately with progress overlay.
                                    if !vm.enableCloudSync && newValue == true {
                                        isReconfiguringStores = true
                                        vm.enableCloudSync = true
                                        if vm.syncCardThemes == false { vm.syncCardThemes = true }
                                        Task { @MainActor in
                                            // Give the UI a moment to render the overlay before heavy work.
                                            try? await Task.sleep(nanoseconds: 80_000_000)
                                            await CoreDataService.shared.applyCloudSyncPreferenceChange(enableSync: true)
                                            _ = WorkspaceService.shared.ensureActiveWorkspaceID()
                                            await WorkspaceService.shared.assignWorkspaceIDIfMissing()
                                            CardAppearanceStore.shared.applySettingsChanged()
                                            BudgetPreferenceSync.shared.applySettingsChanged()
                                            isReconfiguringStores = false
                                        }
                                    }
                                }
                            ))
                            .labelsHidden()
                        }
                        CloudStatusControls()
                        SettingsRow(title: "Sync Card Themes") {
                            Toggle("", isOn: $vm.syncCardThemes)
                                .labelsHidden()
                                .disabled(!vm.enableCloudSync)
                                .onChange(of: vm.syncCardThemes) { _ in
                                    Task { @MainActor in
                                        CardAppearanceStore.shared.applySettingsChanged()
                                    }
                                }
                        }
                        SettingsRow(title: "Sync Budget Period") {
                            Toggle("", isOn: $vm.syncBudgetPeriod)
                                .labelsHidden()
                                .disabled(!vm.enableCloudSync)
                                .onChange(of: vm.syncBudgetPeriod) { _ in
                                    Task { @MainActor in
                                        BudgetPreferenceSync.shared.applySettingsChanged()
                                    }
                                }
                        }
                        Button(action: { showMergeConfirm = true }) {
                            SettingsRow(title: "Merge Local Data into iCloud", detail: "Run") {
                                Image(systemName: "arrow.triangle.2.circlepath").foregroundStyle(.secondary)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }

                // Help
                SettingsCard(
                    iconSystemName: "book",
                    title: "Help",
                    subtitle: "Open the in-app guide."
                ) {
                    VStack(spacing: 0) {
                        NavigationLink(destination: HelpView()) {
                            SettingsRow(title: "View Help", detail: "Open", showsTopDivider: false) {
                                Image(systemName: "chevron.right").foregroundStyle(.secondary)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }

                // Onboarding
                SettingsCard(
                    iconSystemName: "questionmark.circle",
                    title: "Onboarding",
                    subtitle: "Replay the initial setup flow."
                ) {
                    VStack(spacing: 0) {
                        Button {
                            GuidedTourState.shared.resetAll()
                            didCompleteOnboarding = false
                        } label: {
                            SettingsRow(title: "Repeat Onboarding Process", showsTopDivider: false) { EmptyView() }
                        }
                        .buttonStyle(.plain)
                        .guidedHintAnchor(SettingsHint.repeatOnboarding.anchorID)

                        Button {
                            GuidedTourState.shared.resetAll()
                            evaluateSettingsTourState()
                        } label: {
                            SettingsRow(title: "Reset Guided Walkthrough", detail: "Reset") { EmptyView() }
                        }
                        .buttonStyle(.plain)
#if DEBUG
                        Button {
                            QAOverrides.scheduleGuidedTourRefresh()
                            GuidedTourState.shared.forceAllOverlaysOnce()
                            evaluateSettingsTourState()
                        } label: {
                            SettingsRow(title: "Force Guided Tour Overlays", detail: "Debug") { EmptyView() }
                        }
                        .buttonStyle(.plain)
#endif
                    }
                }

                // Reset
                SettingsCard(
                    iconSystemName: "trash",
                    title: "Reset",
                    subtitle: "Clear all stored data."
                ) {
                    VStack(spacing: 0) {
                        Button(role: .destructive, action: { showResetAlert = true }) {
                            SettingsRow(title: "Erase All Data", showsTopDivider: false) { EmptyView() }
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 24) // comfortable tail space below Reset card
        }
        .navigationTitle("Settings")
        // Turn off iCloud options
        .confirmationDialog("Turn Off iCloud Sync?", isPresented: $showDisableCloudOptions, titleVisibility: .visible) {
            Button("Switch to Local (Keep Data)", role: .destructive) { disableCloud(eraseLocal: false) }
            Button("Remove from This Device", role: .destructive) { disableCloud(eraseLocal: true) }
            Button("Cancel", role: .cancel) { /* leave toggle ON */ }
        } message: {
            Text("Choose what to do with your data on this device.")
        }
        
        // Erase confirmation
        .alert("Erase All Data?", isPresented: $showResetAlert) {
            Button("Erase", role: .destructive) { performDataWipe() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will remove all budgets, cards, incomes, and expenses. This action cannot be undone.")
        }
        // Merge confirmation
        .alert("Merge Local Data into iCloud?", isPresented: $showMergeConfirm) {
            Button("Merge", role: .none) { runMerge() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will look for duplicate items across devices and collapse them to avoid duplicates. Your data remains in iCloud; this action cannot be undone.")
        }
        // Merge result
        .alert("Merge Complete", isPresented: $showMergeDone) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Your data has been merged. If you still see duplicates, you can run the merge again or contact support.")
        }
        .overlay(alignment: .center) {
            if isMerging || isReconfiguringStores {
                ZStack {
                    Color.black.opacity(0.3).ignoresSafeArea()
                    VStack(spacing: 12) {
                        ProgressView()
                        Text(isMerging ? "Merging data…" : "Reconfiguring storage…").foregroundStyle(.secondary)
                    }
                    .padding(16)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
            }
        }
        .onAppear { evaluateSettingsTourState() }
        .onReceive(NotificationCenter.default.publisher(for: .guidedTourDidReset)) { _ in
            handleSettingsTourReset()
        }
    }

    // MARK: Guided Tour
    private func evaluateSettingsTourState() {
        guard isSettingsViewActive, !isMerging else { return }

        if tour.needsOverlay(.settings) {
            if !showTourOverlay {
                withAnimation(.easeInOut(duration: 0.25)) {
                    showTourOverlay = true
                }
                AppLog.ui.info("GuidedTour overlayShown screen=settings")
            }
            showSettingsHint = false
            return
        }

        if showTourOverlay {
            showTourOverlay = false
        }

        presentSettingsHintIfNeeded()
    }

    private func presentSettingsHintIfNeeded() {
        guard isSettingsViewActive, !showTourOverlay else { return }
        let needsHint = tour.needsHints(.settings)
        if needsHint != showSettingsHint {
            showSettingsHint = needsHint
            if needsHint {
                AppLog.ui.info("GuidedTour hintShown screen=settings")
            }
        }
        if !needsHint {
            showSettingsHint = false
        }
    }

    private func handleSettingsOverlayDismiss() {
        tour.markOverlaySeen(.settings)
        withAnimation(.easeInOut(duration: 0.25)) {
            showTourOverlay = false
        }
        AppLog.ui.info("GuidedTour overlayDismissed screen=settings")
        presentSettingsHintIfNeeded()
    }

    private func dismissSettingsHint() {
        showSettingsHint = false
        tour.markHintsDismissed(.settings)
        AppLog.ui.info("GuidedTour hintsCompleted screen=settings")
    }

    private func handleSettingsTourReset() {
        showTourOverlay = false
        showSettingsHint = false
        evaluateSettingsTourState()
    }

    private var isSettingsViewActive: Bool {
        guidedTourScreen == nil || guidedTourScreen == .settings
    }

    private var settingsOverlayMessage: String {
        "Adjust defaults, sync options, and access support from one place."
    }

    private var settingsOverlayBullets: [String] {
        [
            "Customize confirmations, periods, and other defaults.",
            "Manage iCloud sync or merge data across devices.",
            "Replay onboarding whenever you want a guided tour."
        ]
    }

    @ViewBuilder
    private func settingsHintOverlay(geometry: GeometryProxy, anchors: [String: Anchor<CGRect>]) -> some View {
        if showSettingsHint,
           let frame = geometry.frame(forHint: SettingsHint.repeatOnboarding.anchorID, anchors: anchors) {
            let position = settingsHintPosition(frame: frame, geometry: geometry)
            GuidedHintBubble(
                icon: "questionmark.circle",
                text: SettingsHint.repeatOnboarding.text,
                arrowDirection: .down
            ) { dismissSettingsHint() }
            .position(x: position.x, y: position.y)
            .transition(.opacity.combined(with: .scale))
            .zIndex(1)
        }
    }

    private func settingsHintPosition(frame: CGRect, geometry: GeometryProxy) -> CGPoint {
        let width = geometry.size.width.isFinite ? geometry.size.width : UIScreen.main.bounds.width
        let minX: CGFloat = 140
        let maxX: CGFloat = max(minX, width - 140)
        let x = clamp(frame.midX, min: minX, max: maxX)
        let y = max(frame.minY - 60, 120)
        return CGPoint(x: x, y: y)
    }

    private func clamp(_ value: CGFloat, min: CGFloat, max: CGFloat) -> CGFloat {
        guard min < max else { return value }
        if value < min { return min }
        if value > max { return max }
        return value
    }

    // MARK: Data wipe
    private func performDataWipe() {
        do {
            try CoreDataService.shared.wipeAllData()
            UbiquitousFlags.clearHasCloudData()
        } catch {
            // No-op simple path
        }
    }

    private func runMerge() {
        isMerging = true
        Task { @MainActor in
            do {
                try MergeService.shared.mergeLocalDataIntoCloud()
                isMerging = false
                showMergeDone = true
            } catch {
                isMerging = false
                // Surface a simple message via the existing alert.
                showMergeDone = true
            }
        }
    }

    private func disableCloud(eraseLocal: Bool) {
        isReconfiguringStores = true
        // Keep the toggle ON visually until we complete switching to avoid UI flicker.
        Task { @MainActor in
            // Allow overlay to render first
            try? await Task.sleep(nanoseconds: 80_000_000)
            await CoreDataService.shared.applyCloudSyncPreferenceChange(enableSync: false)
            // Switch the toggle value only after stores have reconfigured
            vm.enableCloudSync = false
            _ = WorkspaceService.shared.ensureActiveWorkspaceID()
            await WorkspaceService.shared.assignWorkspaceIDIfMissing()
            if eraseLocal {
                do { try CoreDataService.shared.wipeAllData() } catch { /* ignore */ }
                UbiquitousFlags.clearHasCloudData()
            }
            isReconfiguringStores = false
        }
    }
}

// MARK: - Cloud Status Row
private struct CloudStatusControls: View {
    @StateObject private var cloud = CloudAccountStatusProvider()

    var body: some View {
        VStack(spacing: 0) {
            SettingsRow(title: "Cloud Status", detail: statusText) { statusDot }
            Button(action: { cloud.requestAccountStatusCheck(force: true) }) {
                SettingsRow(title: "Sync Now", detail: "Check") {
                    Image(systemName: "arrow.clockwise").foregroundStyle(.secondary)
                }
            }
            .buttonStyle(.plain)
        }
        .onAppear { cloud.requestAccountStatusCheck(force: false) }
    }

    private var statusText: String {
        switch cloud.isCloudAccountAvailable {
        case nil: return "Checking…"
        case .some(true): return "Available"
        case .some(false): return "Unavailable"
        }
    }

    @ViewBuilder private var statusDot: some View {
        let color: Color = {
            switch cloud.isCloudAccountAvailable {
            case nil: return .orange
            case .some(true): return .green
            case .some(false): return .red
            }
        }()
        Circle().fill(color).frame(width: 10, height: 10)
    }
}

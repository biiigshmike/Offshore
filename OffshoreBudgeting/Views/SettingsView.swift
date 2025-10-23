import SwiftUI
import CoreData

// MARK: - SettingsView
/// Simplified Settings screen using plain SwiftUI containers.
/// Layout mirrors the original: grouped cards with rows and toggles.
struct SettingsView: View {
    // MARK: Env
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject private var guidedWalkthrough: GuidedWalkthroughManager

    // MARK: State
    @StateObject private var vm = SettingsViewModel()
    @AppStorage("didCompleteOnboarding") private var didCompleteOnboarding: Bool = false
    @State private var showResetAlert = false
    @State private var showMergeConfirm = false
    @State private var isMerging = false
    @State private var showMergeDone = false
    @State private var showDisableCloudOptions = false
    @State private var isReconfiguringStores = false

    // MARK: Guided Walkthrough State
    @State private var showGuidedOverlay: Bool = false
    @State private var requestedGuidedWalkthrough: Bool = false
    @State private var visibleGuidedHints: Set<GuidedWalkthroughManager.Hint> = []
    @State private var guidedHintWorkItems: [GuidedWalkthroughManager.Hint: DispatchWorkItem] = [:]

    var body: some View {
        ZStack {
            settingsContent
            if showGuidedOverlay, let overlay = guidedWalkthrough.overlay(for: .settings) {
                GuidedOverlayView(
                    overlay: overlay,
                    onDismiss: {
                        showGuidedOverlay = false
                        guidedWalkthrough.markOverlaySeen(for: .settings)
                    },
                    nextAction: presentSettingsHints
                )
                .transition(.opacity)
            }
        }
        .onAppear { requestSettingsGuidedIfNeeded() }
        .onDisappear { cancelSettingsHintWork() }
    }

    @ViewBuilder
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
                .overlay(alignment: .topLeading) {
                    if visibleGuidedHints.contains(.settingsGeneral),
                       let bubble = settingsHintLookup[.settingsGeneral] {
                        HintBubbleView(hint: bubble)
                            .offset(x: 16, y: -20)
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
                .overlay(alignment: .topLeading) {
                    if visibleGuidedHints.contains(.settingsCategories),
                       let bubble = settingsHintLookup[.settingsCategories] {
                        HintBubbleView(hint: bubble)
                            .offset(x: 16, y: -20)
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
                                    if vm.enableCloudSync && newValue == false {
                                        showDisableCloudOptions = true
                                        return
                                    }
                                    if !vm.enableCloudSync && newValue == true {
                                        isReconfiguringStores = true
                                        vm.enableCloudSync = true
                                        if vm.syncCardThemes == false { vm.syncCardThemes = true }
                                        Task { @MainActor in
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
                .overlay(alignment: .topLeading) {
                    if visibleGuidedHints.contains(.settingsData),
                       let bubble = settingsHintLookup[.settingsData] {
                        HintBubbleView(hint: bubble)
                            .offset(x: 16, y: -20)
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
                        Button(action: {
                            guidedWalkthrough.resetAll()
                            didCompleteOnboarding = false
                        }) {
                            SettingsRow(title: "Repeat Onboarding Process", showsTopDivider: false) { EmptyView() }
                        }
                        .buttonStyle(.plain)
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
            .padding(.bottom, 24)
        }
        .navigationTitle("Settings")
        .confirmationDialog("Turn Off iCloud Sync?", isPresented: $showDisableCloudOptions, titleVisibility: .visible) {
            Button("Switch to Local (Keep Data)", role: .destructive) { disableCloud(eraseLocal: false) }
            Button("Remove from This Device", role: .destructive) { disableCloud(eraseLocal: true) }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Choose what to do with your data on this device.")
        }
        .alert("Erase All Data?", isPresented: $showResetAlert) {
            Button("Erase", role: .destructive) { performDataWipe() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will remove all budgets, cards, incomes, and expenses. This action cannot be undone.")
        }
        .alert("Merge Local Data into iCloud?", isPresented: $showMergeConfirm) {
            Button("Merge", role: .none) { runMerge() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will look for duplicate items across devices and collapse them to avoid duplicates. Your data remains in iCloud; this action cannot be undone.")
        }
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
                showMergeDone = true
            }
        }
    }

    private func disableCloud(eraseLocal: Bool) {
        isReconfiguringStores = true
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 80_000_000)
            await CoreDataService.shared.applyCloudSyncPreferenceChange(enableSync: false)
            vm.enableCloudSync = false
            _ = WorkspaceService.shared.ensureActiveWorkspaceID()
            await WorkspaceService.shared.assignWorkspaceIDIfMissing()
            if eraseLocal {
                do { try CoreDataService.shared.wipeAllData() } catch { }
                UbiquitousFlags.clearHasCloudData()
            }
            isReconfiguringStores = false
        }
    }

    // MARK: Guided Walkthrough Helpers
    private var settingsHintLookup: [GuidedWalkthroughManager.Hint: HintBubble] {
        Dictionary(uniqueKeysWithValues: guidedWalkthrough.hints(for: .settings).map { ($0.id, $0) })
    }

    private func requestSettingsGuidedIfNeeded() {
        guard !requestedGuidedWalkthrough else { return }
        requestedGuidedWalkthrough = true
        if guidedWalkthrough.shouldShowOverlay(for: .settings) {
            withAnimation(.easeInOut(duration: 0.3)) {
                showGuidedOverlay = true
            }
        } else {
            presentSettingsHints()
        }
    }

    private func presentSettingsHints() {
        for bubble in guidedWalkthrough.hints(for: .settings) where guidedWalkthrough.shouldShowHint(bubble.id) {
            displaySettingsHint(bubble.id)
        }
    }

    private func displaySettingsHint(_ hint: GuidedWalkthroughManager.Hint) {
        guard guidedWalkthrough.shouldShowHint(hint) else { return }
        guard !visibleGuidedHints.contains(hint) else { return }
        withAnimation(.easeInOut(duration: 0.25)) {
            visibleGuidedHints.insert(hint)
        }
        scheduleSettingsHintAutoHide(for: hint)
    }

    private func scheduleSettingsHintAutoHide(for hint: GuidedWalkthroughManager.Hint) {
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

    private func cancelSettingsHintWork() {
        for (_, work) in guidedHintWorkItems { work.cancel() }
        guidedHintWorkItems.removeAll()
        visibleGuidedHints.removeAll()
        showGuidedOverlay = false
    }
}

// MARK: - Cloud Status Row
private struct CloudStatusControls: View {
    @StateObject private var cloud = CloudAccountStatusProvider()

    var body: some View {
        VStack(spacing: 10) {
            SettingsRow(title: "Account Status", showsTopDivider: false) {
                HStack(spacing: 8) {
                    Circle()
                        .fill(statusColor)
                        .frame(width: 10, height: 10)
                    Text(statusDescription)
                        .foregroundStyle(.secondary)
                }
            }

            SettingsRow(title: "Last Synced") {
                Text("—")
                    .foregroundStyle(.secondary)
            }
        }
        .onAppear { cloud.requestAccountStatusCheck(force: true) }
    }
}

private extension CloudStatusControls {
    var statusColor: Color {
        switch cloud.availability {
        case .available: return .green
        case .unavailable: return .red
        case .unknown: return .yellow
        }
    }

    var statusDescription: String {
        switch cloud.availability {
        case .available: return "Available"
        case .unavailable: return "Unavailable"
        case .unknown: return "Checking…"
        }
    }
}

// Intentionally empty: SettingsRow is defined in SettingsViewModel.swift

import SwiftUI
import CoreData

// MARK: - SettingsView
/// Simplified Settings screen using plain SwiftUI containers.
/// Layout mirrors the original: grouped cards with rows and toggles.
struct SettingsView: View {
    // MARK: Env
    @Environment(\.managedObjectContext) private var viewContext
    
    // MARK: State
    @StateObject private var vm = SettingsViewModel()
    @AppStorage("didCompleteOnboarding") private var didCompleteOnboarding: Bool = false
    @State private var showResetAlert = false
    @State private var showMergeConfirm = false
    @State private var isMerging = false
    @State private var showMergeDone = false
    @State private var showDisableCloudOptions = false
    @State private var isReconfiguringStores = false
    @StateObject private var cloudDiag = CloudDiagnostics.shared

    // Guided walkthrough removed

    var body: some View { settingsContent }

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
                            Picker("",
                                   selection: Binding<BudgetPeriod>(
                                       get: { WorkspaceService.shared.currentBudgetPeriod(in: viewContext) },
                                       set: { WorkspaceService.shared.setBudgetPeriod($0, in: viewContext) }
                                   )
                            ) {
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
                iCloudCard
                

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
                        Button(action: { didCompleteOnboarding = false }) {
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
        .task { await cloudDiag.refresh() }
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
            await cloudDiag.refresh()
            isReconfiguringStores = false
        }
    }

    // Guided walkthrough removed
}

private extension SettingsView {
    @ViewBuilder
    var iCloudCard: some View {
        SettingsCard(
            iconSystemName: "icloud",
            title: "iCloud",
            subtitle: "Manage CloudKit sync and status."
        ) {
            VStack(spacing: 0) {
                SettingsRow(title: "Enable iCloud Sync", showsTopDivider: false) {
                    Toggle("", isOn: cloudToggleBinding).labelsHidden()
                }
                // Budget Period sync is handled via Core Data (Workspace) when Cloud is enabled.

            }
        }
    }

    var cloudToggleBinding: Binding<Bool> {
        Binding<Bool>(
            get: { vm.enableCloudSync },
            set: { newValue in
                if vm.enableCloudSync && newValue == false {
                    showDisableCloudOptions = true
                    return
                }
                if !vm.enableCloudSync && newValue == true {
                    isReconfiguringStores = true
                    vm.enableCloudSync = true
                    Task { @MainActor in
                        try? await Task.sleep(nanoseconds: 80_000_000)
                        await CoreDataService.shared.applyCloudSyncPreferenceChange(enableSync: true)
                        _ = WorkspaceService.shared.ensureActiveWorkspaceID()
                        await WorkspaceService.shared.assignWorkspaceIDIfMissing()
                        // Workspace-backed period will mirror via Core Data
                        await cloudDiag.refresh()
                        isReconfiguringStores = false
                    }
                }
            }
        )
    }

    // Removed: Store Mode and Container Reachable rows for a cleaner UI
}

// Intentionally empty: SettingsRow is defined in SettingsViewModel.swift

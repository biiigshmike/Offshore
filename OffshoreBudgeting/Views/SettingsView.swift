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

    var body: some View {
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

                // Presets
                SettingsCard(
                    iconSystemName: "list.bullet.rectangle",
                    title: "Presets",
                    subtitle: "Planned Expenses default to being created as a Preset Planned Expense."
                ) {
                    VStack(spacing: 0) {
                        SettingsRow(title: "Use in Future Budgets by Default", showsTopDivider: false) {
                            Toggle("", isOn: $vm.presetsDefaultUseInFutureBudgets).labelsHidden()
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
            .padding(.bottom, 24) // comfortable tail space below Reset card
        }
        .navigationTitle("Settings")
        // Erase confirmation
        .alert("Erase All Data?", isPresented: $showResetAlert) {
            Button("Erase", role: .destructive) { performDataWipe() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will remove all budgets, cards, incomes, and expenses. This action cannot be undone.")
        }
    }

    // MARK: Data wipe
    private func performDataWipe() {
        do {
            try CoreDataService.shared.wipeAllData()
        } catch {
            // No-op simple path
        }
    }
}

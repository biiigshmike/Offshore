import SwiftUI
import UIKit

/// Comprehensive in-app guide that mirrors the app's documented structure.
/// Each section pulls from `// MARK:` comments across the codebase so users can
/// explore the same hierarchy developers see.
struct HelpView: View {
    @EnvironmentObject private var themeManager: ThemeManager

    var body: some View {
        Group {
            if #available(iOS 16.0, macCatalyst 16.0, *) {
                NavigationStack {
                    helpMenu
                        .navigationTitle("Help")
                }
            } else {
                NavigationView {
                    helpMenu
                        .navigationBarTitle("Help")
                }
                .navigationViewStyle(StackNavigationViewStyle())
            }
        }
        .ub_navigationBackground(
            theme: themeManager.selectedTheme,
            configuration: themeManager.glassConfiguration
        )
#if targetEnvironment(macCatalyst)
        .frame(minWidth: 400, minHeight: 500)
#endif
    }

    // MARK: - Menu
    @ViewBuilder
    private var helpMenu: some View {
        List {
            // MARK: Getting Started
            Section("Getting Started") {
                NavigationLink("Introduction") { intro }
                NavigationLink("Onboarding") { onboarding }
            }

            // MARK: Core Screens
            Section("Core Screens") {
                NavigationLink("Home") { home }
                NavigationLink("Income") { income }
                NavigationLink("Cards") { cards }
                NavigationLink("Presets") { presets }
                NavigationLink("Settings") { settings }
            }

            // MARK: Tips & Tricks
//            Section("Tips & Tricks") {
//                NavigationLink("Shortcuts & Gestures") { tips }
//            }
        }
    }

    // MARK: - Pages

    private var intro: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                Text("Welcome to Offshore Budgeting — a privacy‑first budgeting app. All data is processed on your device, and you’ll never be asked to connect a bank account. This guide introduces key concepts so you can quickly build budgets, track income, and log expenses across platforms.\n")

                Text("Planned Expenses")
                    .font(.title3).bold()
                Divider()
                Text("Recurring or expected costs for a budget period (e.g., rent, subscriptions). You can create them once and optionally save as a Preset to reuse in future budgets. A planned expense does not have to be a preset, but saving it makes setup faster.\n")

                Text("Variable Expenses")
                    .font(.title3).bold()
                Divider()
                Text("Unpredictable or one‑off costs during a budget period (e.g., fuel, dining). Log them as they happen and categorize them for later review.\n")

                Text("Planned Income")
                    .font(.title3).bold()
                Divider()
                Text("Income you expect to receive (e.g., salary). The app allocates planned income to each budget period and estimates your planned savings.\n")

                Text("Actual Income")
                    .font(.title3).bold()
                Divider()
                Text("Income you actually receive. The app totals actual income per budget period and shows your actual savings.\n")

                Text("Budgets & Periods")
                    .font(.title3).bold()
                Divider()
                Text("Budgets are organized by a period you choose in Settings (e.g., weekly, bi‑weekly, semi‑monthly, or monthly). Navigate periods on Home using the chevrons or the calendar button. If no budget exists for a period, create one from the ellipsis menu.\n")

                Text("Potential vs. Actual Savings")
                    .font(.title3).bold()
                Divider()
                Text("Potential savings = planned income − planned expenses for the period. Actual savings = actual income − actual expenses. Differences help you see whether you’re ahead or behind plan.\n")
            }
            .padding()
            .navigationTitle("Introduction")
        }
    }

    private var onboarding: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                Text("Quick setup on first launch:")
                    .font(.title3).bold()
                Text("• Welcome")
                Text("• Create initial expense categories")
                Text("• Add cards you’ll use for spending")
                Text("• Add preset planned expenses (optional)")
                Text("• Finish setup and open the app")
                Text("You can replay this flow anytime from Settings → Onboarding.")
            }
            .padding()
            .navigationTitle("Onboarding")
        }
    }

    private var home: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                Text("Overview and navigation:")
                    .font(.title3).bold()
                Text("• Use the left and right chevrons to move between budget periods. The current period is selected by default.")
                Text("• If no budget exists for the selected period, the top‑right shows only the ellipsis and calendar buttons. Tap the ellipsis to Create Budget.")
                Text("• After a budget exists, the ellipsis menu includes Manage Cards, Manage Presets, Edit Budget, and Delete Budget.")
                Text("• Use the calendar button to jump to a specific period and create budgets for it.")
                Text("• Tap + to add expenses: Planned Expenses for recurring items, or Variable Expenses for one‑off purchases.")


            }
            .padding()
            .navigationTitle("Home")
        }
    }

    private var income: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                Text("Calendar‑based income tracking:")
                    .font(.title3).bold()
                Text("• Weeks start on Sunday; today’s date is selected first.")
                Text("• Tap a day to view its income entries below the calendar.")
                Text("• Tap + to add income and optionally set it to repeat.")
                Text("• Swipe an entry to edit or delete it.")
                Text("• A weekly summary bar totals income for the visible week.")
            }
            .padding()
            .navigationTitle("Income")
        }
    }

    private var cards: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                Text("Cards and spending:")
                    .font(.title3).bold()
                Text("• Tap a card to open details; tap Done to close.")
                Text("• Tap + to add a new card. When a card’s details are open, + adds an expense to that card.")
                Text("• Long‑press a card to edit or delete it.")
            }
            .padding()
            .navigationTitle("Cards")
        }
    }

    private var presets: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                Text("Reusable planned expense templates:")
                    .font(.title3).bold()
                Text("• Each row shows planned/actual amounts, how many budgets use it, and the next upcoming date.")
                Text("• Tap + to create a template with \"Save as Global Preset\" enabled by default.")
                Text("• Swipe a preset to edit or delete it.")
                Text("• The list updates automatically when templates change.")
            }
            .padding()
            .navigationTitle("Presets")
        }
    }

    private var settings: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                Text("Customize and manage your data:")
                    .font(.title3).bold()
                Text("• General: confirm before deleting items and choose the default budget period.")
                Text("• iCloud Services: sync your data, card themes, app theme, and budget period across devices.")
                Text("• Expense Categories: create or edit categories for variable expenses.")
                Text("• Onboarding: replay the initial setup flow at any time.")
                Text("• Reset: permanently erase all budgets, cards, incomes, and expenses. If iCloud Sync is enabled, this removal applies to all devices. This action cannot be undone.")
            }
            .padding()
            .navigationTitle("Settings")
        }
    }

//    private var tips: some View {
//        ScrollView {
//            VStack(alignment: .leading, spacing: 12) {
//                Text("Power-user hints:")
//                Text("• Press ⌘? on macOS to open this help window.")
//                Text("• Double‑click a date in the Income calendar on macOS to create an entry instantly.")
//                Text("• Most lists support swipe actions for editing or deleting items and pull to refresh for reloading.")
//                Text("• Look for tooltips on buttons and menus for additional keyboard shortcuts.")
//            }
//            .padding()
//            .navigationTitle("Shortcuts & Gestures")
//        }
//    }
}

struct HelpView_Previews: PreviewProvider {
    static var previews: some View {
        HelpView()
            .environmentObject(ThemeManager())
    }
}

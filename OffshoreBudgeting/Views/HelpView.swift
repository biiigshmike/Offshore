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
                Text("Welcome to Offshore Budgeting! This guide highlights the app's major areas so you can quickly build budgets, track income, and log expenses across platforms.")
            }
            .padding()
            .navigationTitle("Introduction")
        }
    }

    private var onboarding: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                Text("When launching the app for the first time, a five-step onboarding flow sets up your workspace:")
                Text("• Welcome screen")
                Text("• Create initial expense categories")
                Text("• Add cards used for spending")
                Text("• Add preset planned expenses")
                Text("• Final loading step that unlocks the main interface")
                Text("You can replay this flow from Settings → Onboarding.")
            }
            .padding()
            .navigationTitle("Onboarding")
        }
    }

    private var home: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                Text("The Home tab shows your budgets, expenses, categories, income, potential & actual savings, as well as potential and actual income:")
                Text("• Use the left and right chevron buttons to navigate between budgets, whether active or inactive, based upon your default or selected budget period.")
                Text("• If no budget exists for the selected period, then there will be not plus button in the top right, only an ellipsis and a calendar button. To create and activate a budget, press the ellipsis and a menu will display an option to Create a Budget.")
                Text("• Once a budget has been created, the ellipsis button will display more options to Manage Cards, Manage Presets, Edit Budget, or Delete Budget.")
                Text("• The calendar button allows you to change the period and create budgets for the selected period.")
                Text("• Use the plus button to add either Planned Expenses or Variable Expenses.")


            }
            .padding()
            .navigationTitle("Home")
        }
    }

    private var income: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                Text("Track paychecks and other revenue on a calendar:")
                Text("• Weeks start on Sunday and today's date is always highlighted/selected first.")
                Text("• Tap a day to show its Selected Day's Income beneath the calendar.")
                Text("• Use the plus button to add income with optional recurrence rules.")
                Text("• Swipe an entry in the Selected Day's Income to edit or delete an Income entry.")
                Text("• A weekly summary bar totals income for the visible week.")
            }
            .padding()
            .navigationTitle("Income")
        }
    }

    private var cards: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                Text("Manage cards and expenses:")
                Text("• Tap a card to select it and reveal detailed spending; tap Done to close the detailed view.")
                Text("• The toolbar's plus icon adds a new card, or an expense if a card is selected from the detailed view of your card.")
                Text("• Long press a card from the Cards screen to edit or delete it.")
            }
            .padding()
            .navigationTitle("Cards")
        }
    }

    private var presets: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                Text("Presets are reusable planned expense templates that can be used in future budgets:")
                Text("• Each row shows planned/actual amounts, how many budgets use it, and the next upcoming date.")
                Text("• The plus button creates a template with \"Save as Global Preset\" enabled by default.")
                Text("• Swipe to edit or delete on the expense to edit or delete it.")
                Text("• The list updates automatically when templates change.")
            }
            .padding()
            .navigationTitle("Presets")
        }
    }

    private var settings: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                Text("Customize app behavior and manage data:")
                Text("• General: confirm before deleting items and choose the default budget period.")
                Text("• iCloud Services: sync your data, card themes, app theme, and budget period across devices.")
                Text("• Presets: control whether new planned expenses default to future budgets.")
                Text("• Expense Categories: open a manager to create or edit categories for variable expenses.")
                Text("• Onboarding: replay the initial setup flow at any time.")
                Text("• Reset: erase all stored budgets, cards, incomes, and expenses. This action cannot be undone and will erase all data across all devices if iCloud Sync is enabled.")
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

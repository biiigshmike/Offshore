import SwiftUI
import UIKit

/// Comprehensive in-app guide that mirrors the app's documented structure.
/// Each section pulls from `// MARK:` comments across the codebase so users can
/// explore the same hierarchy developers see.
struct HelpView: View {
    @EnvironmentObject private var themeManager: ThemeManager
    @AppStorage("didCompleteOnboarding") private var didCompleteOnboarding: Bool = false
    @State private var showOnboardingAlert = false

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
                NavigationLink {
                    intro
                } label: {
                    HelpRowLabel(
                        iconSystemName: "exclamationmark.bubble",
                        title: "Introduction",
                        iconStyle: .blue
                    )
                }
            }

            Section {
                repeatOnboardingButton
            }

            // MARK: Core Screens
            Section("Core Screens") {
                NavigationLink {
                    home
                } label: {
                    HelpRowLabel(
                        iconSystemName: "house.fill",
                        title: "Home",
                        iconStyle: .purple
                    )
                }
                NavigationLink {
                    budgets
                } label: {
                    HelpRowLabel(
                        iconSystemName: "chart.pie.fill",
                        title: "Budgets",
                        iconStyle: .blue
                    )
                }
                NavigationLink {
                    income
                } label: {
                    HelpRowLabel(
                        iconSystemName: "calendar",
                        title: "Income",
                        iconStyle: .red
                    )
                }
                NavigationLink {
                    cards
                } label: {
                    HelpRowLabel(
                        iconSystemName: "creditcard.fill",
                        title: "Cards",
                        iconStyle: .green
                    )
                }
                NavigationLink {
                    presets
                } label: {
                    HelpRowLabel(
                        iconSystemName: "list.number.badge.ellipsis",
                        title: "Presets",
                        iconStyle: .orange
                    )
                }
                NavigationLink {
                    settings
                } label: {
                    HelpRowLabel(
                        iconSystemName: "gear",
                        title: "Settings",
                        iconStyle: .gray
                    )
                }
            }

            // MARK: Tips & Tricks
//            Section("Tips & Tricks") {
//                NavigationLink("Shortcuts & Gestures") { tips }
//            }
        }
        .alert("Repeat Onboarding?", isPresented: $showOnboardingAlert) {
            Button("Go", role: .destructive) { didCompleteOnboarding = false }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("You can restart onboarding at any time.")
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
                Text("Potential Savings = planned income − planned expenses for the period. Actual savings = actual income − actual expenses. Differences help you see whether you’re ahead or behind plan.\n")
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

    private var budgets: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                Text("Budget overview and management:")
                    .font(.title3).bold()
                Text("• Review planned and actual amounts for each period.")
                Text("• Tap a budget to view details, planned expenses, and variable expenses.")
                Text("• Use the ellipsis menu to edit, manage cards, or delete a budget.")
            }
            .padding()
            .navigationTitle("Budgets")
        }
    }

    private var home: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                Text("Overview and navigation:")
                    .font(.title3).bold()
                Text("• Use the left and right chevrons to move between budget periods. The current period is controlled by pressing the calendar icon, or by changing your default budget period in Settings.")
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

    @ViewBuilder
    private var repeatOnboardingButton: some View {
        let label = Text("Repeat Onboarding")
            .font(.subheadline.weight(.semibold))
            .frame(maxWidth: .infinity)
            .frame(minHeight: 44, maxHeight: 44)

        if #available(iOS 26.0, macCatalyst 26.0, macOS 26.0, *) {
            Button {
                showOnboardingAlert = true
            } label: {
                label
            }
            .buttonStyle(.glassProminent)
            .tint(.blue)
            .listRowInsets(EdgeInsets())
        } else {
            Button {
                showOnboardingAlert = true
            } label: {
                label
            }
            .buttonStyle(.plain)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(
                        {
                            #if canImport(UIKit)
                            return Color(UIColor.systemBlue)
                            #elseif canImport(AppKit)
                            return Color(nsColor: NSColor.systemBlue)
                            #else
                            return Color.blue
                            #endif
                        }()
                    )
            )
            .foregroundStyle(.white)
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            .contentShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            .listRowInsets(EdgeInsets())
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

private enum HelpIconStyle {
    case gray
    case blue
    case blueOnWhite
    case purple
    case red
    case green
    case orange

    var tint: Color {
        switch self {
        case .gray:
            return Color(.systemGray)
        case .blue, .blueOnWhite:
            return Color(.systemBlue)
        case .purple:
            return Color(.systemPurple)
        case .red:
            return Color(.systemRed)
        case .green:
            return Color(.systemGreen)
        case .orange:
            return Color(.systemOrange)
        }
    }

    var background: Color {
        switch self {
        case .gray:
            return Color(.systemGray5)
        case .blue:
            return Color(.systemBlue).opacity(0.2)
        case .blueOnWhite:
            return Color(.systemBackground)
        case .purple:
            return Color(.systemPurple).opacity(0.22)
        case .red:
            return Color(.systemRed).opacity(0.2)
        case .green:
            return Color(.systemGreen).opacity(0.2)
        case .orange:
            return Color(.systemOrange).opacity(0.2)
        }
    }

    var usesStroke: Bool {
        switch self {
        case .blueOnWhite:
            return true
        default:
            return false
        }
    }
}

private struct HelpRowLabel: View {
    let iconSystemName: String
    let title: String
    let iconStyle: HelpIconStyle

    var body: some View {
        HStack(spacing: 12) {
            HelpIconTile(
                systemName: iconSystemName,
                style: iconStyle
            )
            Text(title)
            Spacer()
            Image(systemName: "chevron.right")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
    }
}

private struct HelpIconTile: View {
    let systemName: String
    let style: HelpIconStyle

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 7, style: .continuous)
                .fill(style.background)
            Image(systemName: systemName)
                .symbolRenderingMode(.monochrome)
                .foregroundStyle(style.tint)
        }
        .frame(width: 28, height: 28)
        .overlay(
            RoundedRectangle(cornerRadius: 7, style: .continuous)
                .stroke(style.tint.opacity(style.usesStroke ? 0.25 : 0), lineWidth: 0.5)
        )
    }
}

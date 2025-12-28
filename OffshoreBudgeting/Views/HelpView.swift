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
                Text("Welcome to Offshore Budgeting: a privacy-first budgeting app. All data is processed on your device, and you’ll never be asked to connect a bank account. This guide introduces the core building blocks and explains exactly how totals are calculated across the app.")

                Text("The Building Blocks")
                    .font(.title3).bold()
                Divider()
                Text("Cards, Income, Expense Categories, Presets, and Budgets are the foundation:")
                Text("• Cards hold your expenses and let you analyze spending by card.")
                Text("• Income is tracked via planned or actual income. Use planned income to help gauge savings and actual income for income you actually received to get your actual savings.")
                Text("• Expense Categories describe what the expense was for (groceries, rent, fuel).")
                Text("• Presets are reusable planned expenses for recurring bills.")
                Text("• Budgets group a date range so the app can summarize income, expenses, and savings for that period, such as Daily, Monthly, Quarterly, or Yearly. Budget in a way that makese sense to you!")

                Text("Planned Expenses")
                    .font(.title3).bold()
                Divider()
                Text("Expected or recurring costs for a budget period (rent, subscriptions). Planned expenses have two amounts:")
                Text("• Planned amount: what you thought it would be.")
                Text("• Actual amount: what actually posted.")
                Text("Planned amounts build your plan. Actual amounts drive your real totals.")

                Text("Variable Expenses")
                    .font(.title3).bold()
                Divider()
                Text("Unpredictable, one-off costs during a budget period (fuel, dining). These are always treated as actual spending and are tracked by card and category.")

                Text("Planned Income")
                    .font(.title3).bold()
                Divider()
                Text("Income you expect to receive (salary, deposits). Planned income is used for forecasts and potential savings.")

                Text("Actual Income")
                    .font(.title3).bold()
                Divider()
                Text("Income you actually receive. Actual income drives real totals, real savings, and the amount you can still spend safely.")

                Text("Budgets & Periods")
                    .font(.title3).bold()
                Divider()
                Text("Budgets are organized by a period you choose in Settings (weekly, bi-weekly, semi-monthly, or monthly). Navigate periods on Home with the date row controls. If no budget exists for a period, create one from the Home menu or the Budgets screen.")

                Text("How Totals Are Calculated")
                    .font(.title3).bold()
                Divider()
                Text("Everything in Offshore is basic math, and here's how it all breaks down:")
                Text("• Planned expenses total = sum of the planned amounts for planned expenses in the budget period.")
                Text("• Actual planned expenses total = sum of the actual amounts for those planned expenses.")
                Text("• Variable expenses total = sum of unplanned/variable expenses in the budget period.")
                Text("• Planned income total = sum of income entries marked Planned in the period.")
                Text("• Actual income total = sum of income entries marked Actual in the period.")
                Text("• Potential savings = planned income total - planned expenses planned total.")
                Text("• Actual savings = actual income total - (planned expenses actual total + variable expenses total).")
            }
            .padding()
            .navigationTitle("Introduction")
        }
    }

    private var budgets: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                DeviceScreenshotPlaceholders(sectionTitle: "Budgets")

                Text("Budgets: the place where the actual budgeting magic happens.")
                    .font(.title3).bold()
                Divider()
                Text("This screen lists Past, Active, and Upcoming budgets. Tap any budget to open its details and do the real work: add expenses, assign cards, and monitor totals.")

                Text("Budget Details: Build the Budget")
                    .font(.title3).bold()
                Divider()
                Text("Inside a budget, you plan and track expenses in two lanes:")
                Text("• Planned: recurring or expected costs.")
                Text("• Variable: one-off spending from your cards.")
                Text("You can add Planned or Variable expenses from the toolbar. Use Manage Cards and Manage Presets to keep the budget clean and accurate.")
                Text("Tip: having Cards and Categories defined first makes budgeting faster and keeps totals accurate.")

                DeviceScreenshotPlaceholders(sectionTitle: "Budgets")

                Text("Filters, Sorting, and Category Chips")
                    .font(.title3).bold()
                Divider()
                Text("Category chips sit above the list. Tap a category to filter the list to that category; tap again to clear the filter.")
                Text("Sorting controls apply within the active filter and let you order by title, amount, or date.")
                Text("Long-press a category chip to set spending minimums and maximums for that category and also to see how close you are to that category limit.")

                Text("How Budget Totals Are Calculated")
                    .font(.title3).bold()
                Divider()
                Text("These totals are shown in the budget header and summary cards:")
                Text("• Income (Expected) = planned income total in this period.")
                Text("• Income (Received) = actual income total in this period.")
                Text("• Planned expenses (Planned) = sum of planned amounts.")
                Text("• Planned expenses (Actual) = sum of actual amounts entered on planned expenses.")
                Text("• Variable expenses = sum of unplanned expenses on cards for this budget.")
                Text("• Projected savings = planned income - planned expenses (planned) - variable expenses.")
                Text("• Max savings = planned income - planned expenses (planned).")
                Text("• Actual savings = actual income - (planned expenses actual + variable expenses).")

                DeviceScreenshotPlaceholders(sectionTitle: "Budgets")
            }
            .padding()
            .navigationTitle("Budgets")
        }
    }

    private var home: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                DeviceScreenshotPlaceholders(sectionTitle: "Home")

                Text("Home is your dashboard for the selected date range.")
                    .font(.title3).bold()
                Divider()
                Text("By default, Home loads using your default budgeting preference from Settings. You can pick your own custom start and end date, or use the pre-defined ranges in the period menu by pressing on the calendar icon. The selected range controls every widget on the screen.")

                Text("Widgets Overview")
                    .font(.title3).bold()
                Divider()
                Text("Home is made of widgets. Tap any widget to open its detail page.")
                Text("• Income: shows Actual vs Planned income, and the percent received (actual versus planned).")
                Text("• Expense to Income: expenses = planned expenses actual amount + variable expenses amount. Shows % of planned and % of received income.")
                Text("• Savings Outlook: projected savings = actual savings + remaining income - remaining planned expenses.")
                Text("• Next Planned Expense: next upcoming planned expense with planned and actual values.")
                Text("• Category Spotlight: top categories by total spend (planned actual + variable).")
                Text("• Day of Week Spend: spend totals grouped by day in the current range.")
                Text("• Category Availability: caps and remaining amounts by category, segmented into All, Planned, or Variable.")
                Text("• What If?: a scenario planner that uses actual savings as the remaining pool.")
                Text("• Card widgets: every card can appear as a widget with its balance preview.")

                DeviceScreenshotPlaceholders(sectionTitle: "Home")

                Text("Editing Widgets")
                    .font(.title3).bold()
                Divider()
                Text("Tap Edit to pin or unpin widgets, then drag to reorder. New cards automatically appear as widgets so you can keep them visible.")

                Text("Home Calculations")
                    .font(.title3).bold()
                Divider()
                Text("Home calculations mirror your budget math:")
                Text("• Actual savings = actual income - (planned expenses actual amount + variable expenses total amount).")
                Text("• Remaining income = actual income - expenses.")
                Text("• Category availability uses caps when set; otherwise it uses remaining income.")
                Text("• Expense to Income uses planned totals and actual totals to show pacing.")

                DeviceScreenshotPlaceholders(sectionTitle: "Home")
            }
            .padding()
            .navigationTitle("Home")
        }
    }

    private var income: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                DeviceScreenshotPlaceholders(sectionTitle: "Income")

                Text("Income is your calendar-based income tracker.")
                    .font(.title3).bold()
                Divider()
                Text("The calendar shows planned and actual income totals per day. Tap a day to see its income entries and weekly totals.")
                Text("Use the navigation controls to move between days and months. Tap + to add income, then edit or delete with swipe actions in the Seleted Day Income section.")

                Text("Planned vs Actual Income")
                    .font(.title3).bold()
                Divider()
                Text("If your paycheck is consistent, create a recurring Actual Income entry. If it varies, use Planned Income to estimate, then log Actual Income when it arrives.")
                Text("Planned income keeps forecasts realistic. Actual income powers your real totals and savings.")

                DeviceScreenshotPlaceholders(sectionTitle: "Income")

                Text("How Income Feeds the App")
                    .font(.title3).bold()
                Divider()
                Text("Income totals are calculated from entries in the selected period:")
                Text("• Planned income total = sum of Planned entries.")
                Text("• Actual income total = sum of Actual entries.")
                Text("These totals feed Home and Budgets:")
                Text("• Income widgets use planned vs actual to show percent received.")
                Text("• Expense to Income uses actual income to show how much you have left.")
                Text("• Savings Outlook and Actual Savings use actual income.")

                DeviceScreenshotPlaceholders(sectionTitle: "Income")
            }
            .padding()
            .navigationTitle("Income")
        }
    }

    private var cards: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                DeviceScreenshotPlaceholders(sectionTitle: "Cards")

                Text("Cards is your full gallery of saved cards.")
                    .font(.title3).bold()
                Divider()
                Text("Tap + to add a card, or long-press a card to edit or delete it. Tap a card to open its detail view.")

                Text("Card Detail: Deep Dive")
                    .font(.title3).bold()
                Divider()
                Text("The detail view is a focused spending console:")
                Text("• Date range controls scope which expenses are included.")
                Text("• Category chips filter the list. Tap again to clear.")
                Text("• Segment control switches expenses between Planned, Variable, or Unified views.")
                Text("• Sorting orders results by title, amount, or date.")
                Text("• Search to find expenses by title, date, or category.")

                DeviceScreenshotPlaceholders(sectionTitle: "Cards")

                Text("Card Calculations")
                    .font(.title3).bold()
                Divider()
                Text("Total Spent equals the sum of filtered expenses.")
                Text("Planned expenses only count once they have an actual amount. Variable expenses always count as actual.")
                Text("Category totals and chips are derived from the filtered list, so filters always change the totals.")

                DeviceScreenshotPlaceholders(sectionTitle: "Cards")
            }
            .padding()
            .navigationTitle("Cards")
        }
    }

    private var presets: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                DeviceScreenshotPlaceholders(sectionTitle: "Presets")

                Text("Presets are reusable planned expense templates.")
                    .font(.title3).bold()
                Divider()
                Text("Use presets for fixed bills (rent, subscriptions, insurance). Each preset includes Planned and Actual amounts so you can track changes over time.")
                Text("Tap + to create a new preset. Swipe to edit or delete. Assign presets to budgets to speed up setup.")

                DeviceScreenshotPlaceholders(sectionTitle: "Presets")

                Text("How Presets Affect Totals")
                    .font(.title3).bold()
                Divider()
                Text("When you assign a preset to a budget, the preset becomes a planned expense in that budget:")
                Text("• Planned amount contributes to planned expenses totals.")
                Text("• Actual amount contributes to actual planned expenses totals once entered.")
                Text("Differences between planned and actual act as a signal when a vendor changes pricing.")

                DeviceScreenshotPlaceholders(sectionTitle: "Presets")
            }
            .padding()
            .navigationTitle("Presets")
        }
    }

    private var settings: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                DeviceScreenshotPlaceholders(sectionTitle: "Settings")

                Text("Settings is where you configure the app.")
                    .font(.title3).bold()
                Divider()
                Text("Every row here is a separate area to manage the app:")
                Text("• About: app info, version, and external links.")
                Text("• Help: this guide.")
                Text("• General: confirm before deleting and set your default budget period.")
                Text("• Privacy: enable Face ID or Touch ID app lock.")
                Text("• iCloud: enable sync and force a sync refresh if needed.")
                Text("• Manage Categories: add or edit expense categories used across budgets and cards.")
                Text("• Manage Presets: maintain planned expense templates.")

                DeviceScreenshotPlaceholders(sectionTitle: "Settings")

                Text("How Settings Affect Calculations")
                    .font(.title3).bold()
                Divider()
                Text("Your default budget period drives which dates are used for Home, Budgets, and Card views.")
                Text("Categories you create appear as chips and determine how totals are grouped and filtered.")
                Text("Presets you manage are pulled into budgets as planned expenses.")

                DeviceScreenshotPlaceholders(sectionTitle: "Settings")
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

private enum HelpDeviceFrame: String, CaseIterable, Identifiable {
    case iPhone = "iPhone"
    case iPad = "iPad"
    case mac = "Mac"

    var id: String { rawValue }

    func aspectRatio(isLandscape: Bool) -> CGFloat {
        switch self {
        case .iPhone:
            return isLandscape ? (19.5 / 9.0) : (9.0 / 19.5)
        case .iPad:
            return isLandscape ? (4.0 / 3.0) : (3.0 / 4.0)
        case .mac:
            return 16.0 / 10.0
        }
    }

    var maxWidth: CGFloat {
        switch self {
        case .iPhone:
            return 320
        case .iPad:
            return 520
        case .mac:
            return 640
        }
    }
}

private struct DeviceScreenshotPlaceholders: View {
    let sectionTitle: String
    @Environment(\.responsiveLayoutContext) private var layoutContext

    private var resolvedDevice: HelpDeviceFrame {
        #if targetEnvironment(macCatalyst)
        return .mac
        #elseif os(iOS)
        return UIDevice.current.userInterfaceIdiom == .pad ? .iPad : .iPhone
        #elseif os(macOS)
        return .mac
        #else
        return .iPhone
        #endif
    }

    private var shouldUseLandscape: Bool {
        #if os(iOS)
        if resolvedDevice == .iPhone || resolvedDevice == .iPad {
            return layoutContext.isLandscape
        }
        #endif
        return false
    }

    var body: some View {
        HelpScreenshotPlaceholder(
            title: "\(sectionTitle) - \(resolvedDevice.rawValue)",
            device: resolvedDevice,
            isLandscape: shouldUseLandscape
        )
        .padding(.vertical, 6)
    }
}

private struct HelpScreenshotPlaceholder: View {
    let title: String
    let device: HelpDeviceFrame
    let isLandscape: Bool

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .fill(Color.primary.opacity(0.04))
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .stroke(Color.primary.opacity(0.18), lineWidth: 1)
            VStack(spacing: 6) {
                Image(systemName: "iphone")
                    .font(.system(size: 24, weight: .regular))
                Text(title)
                    .font(.subheadline.weight(.semibold))
                Text("Screenshot placeholder")
                    .font(.caption)
            }
            .foregroundStyle(.secondary)
        }
        .aspectRatio(device.aspectRatio(isLandscape: isLandscape), contentMode: .fit)
        .frame(maxWidth: device.maxWidth)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 6)
    }
}

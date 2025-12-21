//
//  RootTabView.swift
//  so-far
//
//  Created by Michael Brown on 8/8/25.
//

import SwiftUI
import CoreData

// MARK: - Overview
/// Root tab container for the application. Hosts all primary sections and
/// applies theme-aware navigation chrome using compatibility helpers.
///
/// Behavior notes:
/// - Preserves existing view hierarchy and default selected tab.
/// - Navigation container adapts between `NavigationStack` (iOS/Catalyst 16+)
///   and `NavigationView` for earlier targets without changing routes.
/// - Background/chrome appearance is delegated to `ub_navigationBackground`
///   and `ub_rootNavigationChrome()` to centralize OS 26 vs. classic styling.
struct RootTabView: View {
    @EnvironmentObject private var themeManager: ThemeManager
    @Environment(\.dataRevision) private var dataRevision
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    let isWorkspaceReady: Bool

    // MARK: Tabs
    enum Tab: Hashable, CaseIterable {
        case home
        case budgets
        case income
        case cards
        case settings
    }

    // MARK: Destinations
    enum Destination: Hashable {
        case tab(Tab)
        case sidebarAddActions
        case sidebarQuickLinksActions
        case activeBudget(NSManagedObjectID)
    }

    // MARK: State
    @Environment(\.startTabIdentifier) private var startTabIdentifier
    @State private var selectedDestination: Destination = .tab(.home)
    @State private var lastPrimaryTab: Tab = .home
    @State private var appliedStartTab: Bool = false

    @State private var isPresentingAddPlannedExpense = false
    @State private var isPresentingAddVariableExpense = false
    @State private var isPresentingManageCategories = false
    @State private var isPresentingManagePresets = false

    @State private var isSidebarSectionsVisible: Bool = true

    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Budget.startDate, ascending: false)],
        animation: .default
    )
    private var budgets: FetchedResults<Budget>

    var body: some View {
        tabViewBody
    }

    // MARK: Body builders
    @ViewBuilder
    private var tabViewBody: some View {
        if #available(iOS 18.0, macCatalyst 18.0, macOS 15.0, *) {
            TabView(selection: $selectedDestination) {
                SwiftUI.Tab(Tab.home.title, systemImage: Tab.home.systemImage, value: Destination.tab(.home)) {
                    tabNavigationContainer {
                        decoratedTabContent(for: .home)
                    }
                }
                .accessibilityIdentifier(Tab.home.accessibilityID)

                SwiftUI.Tab(Tab.budgets.title, systemImage: Tab.budgets.systemImage, value: Destination.tab(.budgets)) {
                    tabNavigationContainer {
                        decoratedTabContent(for: .budgets)
                    }
                }
                .accessibilityIdentifier(Tab.budgets.accessibilityID)

                SwiftUI.Tab(Tab.income.title, systemImage: Tab.income.systemImage, value: Destination.tab(.income)) {
                    tabNavigationContainer {
                        decoratedTabContent(for: .income)
                    }
                }
                .accessibilityIdentifier(Tab.income.accessibilityID)

                SwiftUI.Tab(Tab.cards.title, systemImage: Tab.cards.systemImage, value: Destination.tab(.cards)) {
                    tabNavigationContainer {
                        decoratedTabContent(for: .cards)
                    }
                }
                .accessibilityIdentifier(Tab.cards.accessibilityID)

                SwiftUI.Tab(Tab.settings.title, systemImage: Tab.settings.systemImage, value: Destination.tab(.settings)) {
                    tabNavigationContainer {
                        decoratedTabContent(for: .settings)
                    }
                }
                .accessibilityIdentifier(Tab.settings.accessibilityID)

                TabSection {
                    SwiftUI.Tab(value: Destination.sidebarAddActions) {
                        EmptyView()
                    }
                    .tabPlacement(.sidebarOnly)
                    .defaultVisibility(.hidden, for: .tabBar)
                } header: {
                    Label("Add Expenses", systemImage: "plus")
                }
                .sectionActions {
                    Button("+ Add Planned Expense") { isPresentingAddPlannedExpense = true }
                    Button("+ Add Variable Expense") { isPresentingAddVariableExpense = true }
                }

                TabSection {
                    ForEach(activeBudgets, id: \.objectID) { budget in
                        SwiftUI.Tab(activeBudgetTitle(for: budget), systemImage: "chart.pie", value: Destination.activeBudget(budget.objectID)) {
                            tabNavigationContainer {
                                BudgetDetailsView(budgetID: budget.objectID)
                            }
                        }
                        .tabPlacement(.sidebarOnly)
                        .defaultVisibility(.hidden, for: .tabBar)
                    }
                } header: {
                    Label("Active Budgets", systemImage: "calendar")
                }

                TabSection {
                    SwiftUI.Tab(value: Destination.sidebarQuickLinksActions) {
                        EmptyView()
                    }
                    .tabPlacement(.sidebarOnly)
                    .defaultVisibility(.hidden, for: .tabBar)
                } header: {
                    Label("Quick Links", systemImage: "link")
                }
                .sectionActions {
                    Button("Manage Categories") { isPresentingManageCategories = true }
                    Button("Manage Presets") { isPresentingManagePresets = true }
                }
            }
            .onAppear { applyStartTabIfNeeded() }
            .onChange(of: selectedDestination) { updateLastPrimaryTab(for: $0) }
            .onChange(of: horizontalSizeClass) { _ in enforcePrimarySelectionIfCompact() }
            .onChange(of: isSidebarSectionsVisible) { _ in enforcePrimarySelectionIfSidebarHidden() }
            .tabViewStyle(.sidebarAdaptable)

            // Sheets for your actions
            .sheet(isPresented: $isPresentingAddPlannedExpense) {
                AddPlannedExpenseView(onSaved: { isPresentingAddPlannedExpense = false })
                    .environment(\.managedObjectContext, viewContext)
            }
            .sheet(isPresented: $isPresentingAddVariableExpense) {
                AddUnplannedExpenseView(onSaved: { isPresentingAddVariableExpense = false })
                    .environment(\.managedObjectContext, viewContext)
            }
            .sheet(isPresented: $isPresentingManageCategories) {
                navigationContainer {
                    ExpenseCategoryManagerView()
                        .environment(\.managedObjectContext, viewContext)
                }
            }
            .sheet(isPresented: $isPresentingManagePresets) {
                navigationContainer {
                    PresetsView()
                        .environment(\.managedObjectContext, viewContext)
                }
            }
        } else {
            baseTabView
        }
    }

    private var baseTabView: some View {
        TabView(selection: $selectedDestination) {
            legacyTabViewItem(for: .home)
            legacyTabViewItem(for: .budgets)
            legacyTabViewItem(for: .income)
            legacyTabViewItem(for: .cards)
            legacyTabViewItem(for: .settings)
        }
        .onAppear { applyStartTabIfNeeded() }
        .onChange(of: selectedDestination) { updateLastPrimaryTab(for: $0) }
        .onChange(of: horizontalSizeClass) { _ in enforcePrimarySelectionIfCompact() }
    }

    // MARK: - Legacy Tab Items

    @ViewBuilder
    private func legacyTabViewItem(for tab: Tab) -> some View {
        navigationContainer {
            decoratedTabContent(for: tab)
        }
        .tabItem {
            Label(tab.title, systemImage: tab.systemImage)
                .accessibilityIdentifier(tab.accessibilityID)
        }
        .tag(Destination.tab(tab))
    }

    // MARK: - Decoration & Navigation Containers

    @ViewBuilder
    private func decoratedTabContent(for tab: Tab) -> some View {
        let base = tabContent(for: tab)
            .ub_navigationBackground(
                theme: themeManager.selectedTheme,
                configuration: themeManager.glassConfiguration
            )
            .ub_rootNavigationChrome()

        if #available(iOS 26.0, macCatalyst 26.0, macOS 26.0, *) {
            base
        } else if #available(iOS 16.0, macCatalyst 16.0, macOS 13.0, *) {
            base
                .toolbarBackground(.visible, for: .tabBar)
                .toolbarBackground(themeManager.selectedTheme.legacyChromeBackground, for: .tabBar)
        } else {
            base
        }
    }

    @ViewBuilder
    private func tabContent(for tab: Tab) -> some View {
        if isWorkspaceReady {
            readyTabContent(for: tab)
        } else {
            loadingPlaceholder()
        }
    }

    @ViewBuilder
    private func readyTabContent(for tab: Tab) -> some View {
        switch tab {
        case .home:
            HomeView()
        case .budgets:
            BudgetsView()
                .id(dataRevision)
        case .income:
            IncomeView()
                .id(dataRevision)
        case .cards:
            CardsView()
                .id(dataRevision)
        case .settings:
            SettingsView()
        }
    }

    @ViewBuilder
    private func navigationContainer<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        if #available(iOS 16.0, macCatalyst 16.0, *) {
            NavigationStack { content() }
        } else {
            NavigationView { content() }
                .navigationViewStyle(StackNavigationViewStyle())
        }
    }

    @ViewBuilder
    private func tabNavigationContainer<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        navigationContainer { content() }
            .background(tabBarSectionsObserved())
    }

    private func loadingPlaceholder() -> some View {
        Color.clear
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .accessibilityHidden(true)
    }

    @ViewBuilder
    private func tabBarSectionsObserved() -> some View {
        if #available(iOS 18.0, macCatalyst 18.0, macOS 15.0, *) {
            TabBarSectionsObserver(isSidebarSectionsVisible: $isSidebarSectionsVisible)
        } else {
            EmptyView()
        }
    }
}

// MARK: - Tab Metadata
extension RootTabView.Tab {
    var title: String {
        switch self {
        case .home: return "Home"
        case .budgets: return "Budgets"
        case .income: return "Income"
        case .cards: return "Cards"
        case .settings: return "Settings"
        }
    }

    var systemImage: String {
        switch self {
        case .home: return "house"
        case .budgets: return "chart.pie"
        case .income: return "calendar"
        case .cards: return "creditcard"
        case .settings: return "gear"
        }
    }

    var accessibilityID: String {
        switch self {
        case .home: return "tab_home"
        case .budgets: return "tab_budgets"
        case .income: return "tab_income"
        case .cards: return "tab_cards"
        case .settings: return "tab_settings"
        }
    }
}

// MARK: - Start Tab Application
private extension RootTabView {
    func applyStartTabIfNeeded() {
        guard !appliedStartTab, let key = startTabIdentifier else { return }
        if let target = mapStartTab(key: key) {
            selectedDestination = .tab(target)
            lastPrimaryTab = target
            appliedStartTab = true
        }
    }

    func mapStartTab(key: String) -> Tab? {
        switch key.lowercased() {
        case "home": return .home
        case "budgets": return .budgets
        case "income": return .income
        case "cards": return .cards
        case "settings": return .settings
        default: return nil
        }
    }
}

// MARK: - Sidebar Data
private extension RootTabView {
    var activeBudgets: [Budget] {
        let now = Date()
        return budgets.filter { isActive($0, on: now) }
    }

    func isActive(_ budget: Budget, on date: Date) -> Bool {
        guard let start = budget.startDate, let end = budget.endDate else { return false }
        return start <= date && end >= date
    }

    func activeBudgetTitle(for budget: Budget) -> String {
        let raw = budget.name?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return raw.isEmpty ? "Untitled Budget" : raw
    }
}

// MARK: - Selection Tracking
private extension RootTabView {
    func updateLastPrimaryTab(for destination: Destination) {
        if case let .tab(tab) = destination {
            lastPrimaryTab = tab
        }
    }

    func enforcePrimarySelectionIfCompact() {
        guard horizontalSizeClass == .compact else { return }
        if case .tab = selectedDestination { return }
        selectedDestination = .tab(lastPrimaryTab)
    }
}

private extension RootTabView {
    func enforcePrimarySelectionIfSidebarHidden() {
        guard !isSidebarSectionsVisible else { return }
        if case .tab = selectedDestination { return }
        selectedDestination = .tab(lastPrimaryTab)
    }
}

// MARK: - NSManagedObjectID as Identifiable for sheet(item:)
private extension NSManagedObjectID {
    var id: URL { uriRepresentation() }
}
@available(iOS 18.0, macCatalyst 18.0, macOS 15.0, *)
private struct TabBarSectionsObserver: View {
    @Environment(\.isTabBarShowingSections) private var isTabBarShowingSections
    @Binding var isSidebarSectionsVisible: Bool

    var body: some View {
        Color.clear
            .onAppear { updateVisibility() }
            .onChange(of: isTabBarShowingSections) { _ in updateVisibility() }
    }

    private func updateVisibility() {
        isSidebarSectionsVisible = isTabBarShowingSections
    }
}


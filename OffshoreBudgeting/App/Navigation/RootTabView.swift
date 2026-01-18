//
//  RootTabView.swift
//  so-far
//
//  Created by Michael Brown on 8/8/25.
//

import SwiftUI
import CoreData
#if canImport(UIKit)
import UIKit
#endif

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
    @EnvironmentObject private var settings: AppSettingsState
    @Environment(\.dataRevision) private var dataRevision
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.responsiveLayoutContext) private var layoutContext
    let isWorkspaceReady: Bool
    
    // MARK: Tabs
    enum Tab: Hashable, CaseIterable {
        case home
        case budgets
        case income
        case cards
        case settings
    }
    
    enum SidebarItem: Hashable {
        case root(Tab)
        case addPlannedExpense
        case addVariableExpense
        case recentBudget(NSManagedObjectID)
        case managePresets
        case manageCategories
    }
    
    // MARK: State
    @Environment(\.startTabIdentifier) private var startTabIdentifier
    @Environment(\.startRouteIdentifier) private var startRouteIdentifier
    @Environment(\.uiTestingFlags) private var uiTestingFlags
    @EnvironmentObject private var uiTesting: UITestingState
    @State private var selectedTab: Tab = .home
    @State private var appliedStartTab: Bool = false
    @State private var appliedStartRoute: Bool = false
    @State private var uiTestStartRoute: String? = nil
    @State private var sidebarSelection: SidebarItem? = .root(.home)
    @State private var recentBudgets: [Budget] = []
    @State private var sidebarPath = NavigationPath()
    private let budgetService = BudgetService()
    
    var body: some View {
        rootBody
            .ub_perfRenderScope("RootTabView.body")
            .ub_perfRenderCounter("RootTabView", every: 10)
            .overlay(alignment: .topLeading) {
                if uiTestingFlags.isUITesting, uiTesting.seedDone {
                    Text("Seed Done")
                        .font(.caption2)
                        .opacity(0.01)
                        .accessibilityIdentifier(AccessibilityID.UITest.seedDone)
                }
            }
            .animation(.easeInOut(duration: 0.25), value: shouldUseCompactTabs)
            .onChange(of: dataRevision) { newValue in
                UBPerf.mark("RootTabView.dataRevision.changed", "value=\(newValue)")
            }
    }
    
    // MARK: Body builders
    private var prefersCompactTabs: Bool {
#if os(iOS)
        return UIDevice.current.userInterfaceIdiom == .phone
#else
        return false
#endif
    }
    
    private var shouldUseCompactTabs: Bool {
        prefersCompactTabs || settings.rootNavigationUsesCompactTabs || isNarrowLayout
    }
    
    private var showsSidebarRestoreControl: Bool {
        settings.rootNavigationUsesCompactTabs && !prefersCompactTabs && !isNarrowLayout
    }
    
    private var isNarrowLayout: Bool {
        if horizontalSizeClass == .compact {
            return true
        }
        let width = layoutContext.containerSize.width
        if width > 0 && width < 720 {
            return true
        }
        return false
    }

    private var shouldAllowPersistentNavigationMode: Bool {
        !prefersCompactTabs && !isNarrowLayout
    }

    private func splitViewVisibilityFromStored(_ value: String) -> NavigationSplitViewVisibility {
        switch value.lowercased() {
        case "detailonly", "detail_only", "detail":
            return .detailOnly
        case "doublecolumn", "double_column", "double":
            return .doubleColumn
        case "all":
            return .all
        default:
            return .all
        }
    }

    private func storeValue(from visibility: NavigationSplitViewVisibility) -> String {
        switch visibility {
        case .all:
            return "all"
        case .doubleColumn:
            return "doubleColumn"
        case .detailOnly:
            return "detailOnly"
        default:
            return "all"
        }
    }

    private var splitViewVisibilityBinding: Binding<NavigationSplitViewVisibility> {
        Binding(
            get: {
                splitViewVisibilityFromStored(settings.rootNavigationSplitViewVisibility)
            },
            set: { newValue in
                guard shouldAllowPersistentNavigationMode else { return }
                settings.rootNavigationSplitViewVisibility = storeValue(from: newValue)
            }
        )
    }
    
    @ViewBuilder
    private var rootBody: some View {
        if shouldUseCompactTabs {
            tabViewBody
                .transition(.opacity)
        } else {
            splitViewBody
                .transition(.opacity)
        }
    }
    
    @ViewBuilder
    private var tabViewBody: some View {
        if #available(iOS 18.0, macCatalyst 18.0, macOS 15.0, *) {
            adaptiveTabView
        } else {
            baseTabView
        }
    }
    
    @available(iOS 18.0, macCatalyst 18.0, macOS 15.0, *)
    @ViewBuilder
    private var adaptiveTabView: some View {
        TabView(selection: $selectedTab) {
            SwiftUI.Tab(value: Tab.home) {
                navigationContainer {
                    decoratedTabContent(for: .home)
                }
            }
            label: {
                Label(Tab.home.title, systemImage: Tab.home.systemImage)
                    .accessibilityIdentifier(Tab.home.accessibilityID)
            }
            
            SwiftUI.Tab(value: Tab.budgets) {
                navigationContainer {
                    decoratedTabContent(for: .budgets)
                }
            }
            label: {
                Label(Tab.budgets.title, systemImage: Tab.budgets.systemImage)
                    .accessibilityIdentifier(Tab.budgets.accessibilityID)
            }
            
            SwiftUI.Tab(value: Tab.income) {
                navigationContainer {
                    decoratedTabContent(for: .income)
                }
            }
            label: {
                Label(Tab.income.title, systemImage: Tab.income.systemImage)
                    .accessibilityIdentifier(Tab.income.accessibilityID)
            }
            
            SwiftUI.Tab(value: Tab.cards) {
                navigationContainer {
                    decoratedTabContent(for: .cards)
                }
            }
            label: {
                Label(Tab.cards.title, systemImage: Tab.cards.systemImage)
                    .accessibilityIdentifier(Tab.cards.accessibilityID)
            }
            
            SwiftUI.Tab(value: Tab.settings) {
                navigationContainer {
                    decoratedTabContent(for: .settings)
                }
            }
            label: {
                Label(Tab.settings.title, systemImage: Tab.settings.systemImage)
                    .accessibilityIdentifier(Tab.settings.accessibilityID)
            }
        }
        .onAppear {
            applyStartTabIfNeeded()
            applyStartRouteIfNeeded()
        }
    }
    
    private var baseTabView: some View {
        TabView(selection: $selectedTab) {
            legacyTabViewItem(for: .home)
            legacyTabViewItem(for: .budgets)
            legacyTabViewItem(for: .income)
            legacyTabViewItem(for: .cards)
            legacyTabViewItem(for: .settings)
        }
        .onAppear {
            applyStartTabIfNeeded()
            applyStartRouteIfNeeded()
        }
    }
    
    @ViewBuilder
    private var splitViewBody: some View {
        if #available(iOS 16.0, macCatalyst 16.0, macOS 13.0, *) {
            NavigationSplitView(columnVisibility: splitViewVisibilityBinding) {
                sidebarList
            } detail: {
                NavigationStack(path: $sidebarPath) {
                    sidebarDetail
                }
            }
            .onAppear {
                applyStartTabIfNeeded()
                applyStartRouteIfNeeded()
                refreshRecentBudgets()
            }
            .onChange(of: dataRevision) { _ in
                refreshRecentBudgets()
            }
            .onChange(of: sidebarSelection) { selection in
                sidebarPath = NavigationPath()
                guard case .root(let tab) = selection else { return }
                selectedTab = tab
            }
        } else {
            tabViewBody
        }
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
        .tag(tab)
    }
    
    @ViewBuilder
    private var sidebarList: some View {
        List {
            Section {
                ForEach(Tab.allCases, id: \.self) { tab in
                    let item = SidebarItem.root(tab)
                    sidebarRow(item: item, accessibilityID: tab.accessibilityID) {
                        Label(tab.title, systemImage: tab.systemImage)
                    }
                }
            }
            
            Section("Add Expenses") {
                let plannedItem = SidebarItem.addPlannedExpense
                sidebarRow(item: plannedItem) {
                    Label("Add Planned Expense", systemImage: Icons.sfPlusRectangle)
                }
                let variableItem = SidebarItem.addVariableExpense
                sidebarRow(item: variableItem) {
                    Label("Add Variable Expense", systemImage: Icons.sfPlusRectangle)
                }
            }
            
            Section("Quick Links") {
                let presetsItem = SidebarItem.managePresets
                sidebarRow(item: presetsItem) {
                    Label("Manage Presets", systemImage: Icons.sfListBulletRectangle)
                }
                let categoriesItem = SidebarItem.manageCategories
                sidebarRow(item: categoriesItem) {
                    Label("Manage Categories", systemImage: Icons.sfTag)
                }
            }
        }
        .ub_listStyleLiquidAware()
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("Offshore")
                    .font(.headline)
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    withAnimation(.easeInOut(duration: 0.25)) {
                        if shouldAllowPersistentNavigationMode {
                            settings.rootNavigationUsesCompactTabs = true
                        }
                    }
                } label: {
                    Image(systemName: Icons.sfInsetFilledTopthirdRectangle)
                }
                .accessibilityLabel("Show Compact Tabs")
            }
        }
    }
    
    @ViewBuilder
    private var sidebarDetail: some View {
        switch sidebarSelection {
        case .root(let tab):
            decoratedRootContent(tabContent(for: tab))
        case .addPlannedExpense:
            decoratedRootContent(
                AddPlannedExpenseView(
                    onSaved: {},
                    onDismiss: { sidebarSelection = .root(selectedTab) },
                    wrapsInNavigation: false
                )
            )
        case .addVariableExpense:
            decoratedRootContent(
                AddUnplannedExpenseView(
                    onSaved: {},
                    onDismiss: { sidebarSelection = .root(selectedTab) },
                    wrapsInNavigation: false
                )
            )
        case .recentBudget(let objectID):
            decoratedRootContent(BudgetDetailsView(budgetID: objectID))
        case .managePresets:
            decoratedRootContent(PresetsView())
        case .manageCategories:
            decoratedRootContent(ExpenseCategoryManagerView(wrapsInNavigation: false))
        case .none:
            decoratedRootContent(tabContent(for: selectedTab))
        }
    }
    
    // MARK: - Decoration & Navigation Containers
    
    @ViewBuilder
    private func decoratedTabContent(for tab: Tab) -> some View {
        decoratedRootContent(tabContent(for: tab))
    }
    
    @ViewBuilder
    private func decoratedRootContent<Content: View>(_ content: Content) -> some View {
        let base = content
            .ub_navigationBackground(
                theme: themeManager.selectedTheme,
                configuration: themeManager.glassConfiguration
            )
            .ub_rootNavigationChrome()
            .toolbar {
                if showsSidebarRestoreControl {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button {
                            withAnimation(.easeInOut(duration: 0.25)) {
                                if shouldAllowPersistentNavigationMode {
                                    settings.rootNavigationUsesCompactTabs = false
                                }
                            }
                        } label: {
                            Label("Show Sidebar", systemImage: Icons.sfSidebarLeading)
                        }
                    }
                }
            }
        
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
                .ub_windowTitle(Tab.home.title)
        case .budgets:
            remountOnDataRevisionIfNeeded(BudgetsView())
                .ub_windowTitle(Tab.budgets.title)
        case .income:
            remountOnDataRevisionIfNeeded(IncomeView())
                .ub_windowTitle(Tab.income.title)
        case .cards:
            remountOnDataRevisionIfNeeded(CardsView())
                .ub_windowTitle(Tab.cards.title)
        case .settings:
            if uiTestingFlags.isUITesting, uiTestStartRoute == "categories", shouldUseCompactTabs {
                ExpenseCategoryManagerView(wrapsInNavigation: false)
                    .ub_windowTitle("Categories")
            } else {
                SettingsView()
                    .ub_windowTitle(Tab.settings.title)
            }
        }
    }

    @ViewBuilder
    private func remountOnDataRevisionIfNeeded<V: View>(_ view: V) -> some View {
        if UBPerfExperiments.disableTabRemountsOnDataRevision {
            view
        } else {
            view.id(dataRevision)
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
    
    private func loadingPlaceholder() -> some View {
        Color.clear
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .accessibilityHidden(true)
    }
    
    private func refreshRecentBudgets() {
        guard isWorkspaceReady else {
            recentBudgets = []
            return
        }
        do {
            let budgets = try budgetService.fetchAllBudgets(sortByStartDateDescending: true)
            recentBudgets = Array(budgets.prefix(3))
        } catch {
            recentBudgets = []
        }
    }
    
    private func sidebarRowBackground(isSelected: Bool) -> some View {
        Group {
            if isSelected {
                RoundedRectangle(cornerRadius: Radius.card, style: .continuous)
                    .fill(selectedSidebarTint)
                    .padding(.horizontal, DesignSystem.Spacing.s)
            } else {
                Color.clear
            }
        }
    }
    
    @ViewBuilder
    private func sidebarRow<Label: View>(
        item: SidebarItem,
        accessibilityID: String? = nil,
        @ViewBuilder label: () -> Label
    ) -> some View {
        let isSelected = sidebarSelection == item
        let base = Button {
            sidebarSelection = item
        } label: {
            label()
                .foregroundStyle(.primary)
                .padding(.horizontal, DesignSystem.Spacing.s)
        }
            .buttonStyle(.plain)
            .listRowBackground(sidebarRowBackground(isSelected: isSelected))
        if let accessibilityID {
            base.accessibilityIdentifier(accessibilityID)
        } else {
            base
        }
    }
    
    private var selectedSidebarTint: Color {
        let tint = themeManager.selectedTheme.resolvedTint
        return tint.opacity(colorScheme == .dark ? 0.32 : 0.18)
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
        case .home: return Icons.sfHouse
        case .budgets: return Icons.sfChartPie
        case .income: return Icons.sfCalendar
        case .cards: return Icons.sfCreditcard
        case .settings: return Icons.sfGear
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
            selectedTab = target
            sidebarSelection = .root(target)
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

// MARK: - Start Route Application (UI Tests)
private extension RootTabView {
    func applyStartRouteIfNeeded() {
        guard uiTestingFlags.isUITesting, !appliedStartRoute, let route = startRouteIdentifier else { return }
        switch route.lowercased() {
        case "categories":
            selectedTab = .settings
            sidebarSelection = .manageCategories
            uiTestStartRoute = "categories"
            appliedStartRoute = true
        default:
            return
        }
    }
}

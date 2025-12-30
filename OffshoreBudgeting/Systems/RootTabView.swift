//
//  RootTabView.swift
//  so-far
//
//  Created by Michael Brown on 8/8/25.
//

import SwiftUI
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
    @Environment(\.dataRevision) private var dataRevision
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.responsiveLayoutContext) private var layoutContext
#if targetEnvironment(macCatalyst)
    @Environment(\.openWindow) private var openWindow
#endif
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
        case managePresets
        case manageCategories
    }

    private enum SidebarVisibility: String {
        case all
        case detailOnly
        case automatic
    }

    private static let sidebarVisibilityStorageKey: String = {
#if targetEnvironment(macCatalyst)
        return "\(AppSettingsKeys.sidebarVisibility.rawValue).macCatalyst"
#elseif os(iOS)
        let idiom: String = UIDevice.current.userInterfaceIdiom == .pad ? "ipad" : "iphone"
        return "\(AppSettingsKeys.sidebarVisibility.rawValue).\(idiom)"
#else
        return "\(AppSettingsKeys.sidebarVisibility.rawValue).macOS"
#endif
    }()

    private static let compactTabsStorageKey: String = {
#if targetEnvironment(macCatalyst)
        return "\(AppSettingsKeys.sidebarCompactTabsOverride.rawValue).macCatalyst"
#elseif os(iOS)
        let idiom: String = UIDevice.current.userInterfaceIdiom == .pad ? "ipad" : "iphone"
        return "\(AppSettingsKeys.sidebarCompactTabsOverride.rawValue).\(idiom)"
#else
        return "\(AppSettingsKeys.sidebarCompactTabsOverride.rawValue).macOS"
#endif
    }()

    // MARK: State
    @Environment(\.startTabIdentifier) private var startTabIdentifier
    @State private var selectedTab: Tab = .home
    @State private var appliedStartTab: Bool = false
    @State private var sidebarSelection: SidebarItem? = .root(.home)
    @AppStorage(Self.compactTabsStorageKey) private var usesCompactTabsOverride: Bool = false
    @AppStorage(Self.sidebarVisibilityStorageKey) private var sidebarVisibilityRaw: String = SidebarVisibility.automatic.rawValue
    @State private var columnVisibility: NavigationSplitViewVisibility = .all
    @State private var isPresentingHelp = false

    var body: some View {
        rootBody
            .animation(.easeInOut(duration: 0.25), value: shouldUseCompactTabs)
            .environment(\.currentRootTab, selectedTab)
            .environment(\.currentSidebarSelection, sidebarSelection)
#if targetEnvironment(macCatalyst)
            .onAppear { updateWindowTitle() }
            .onChange(of: selectedTab) { _ in updateWindowTitle() }
            .onChange(of: sidebarSelection) { _ in updateWindowTitle() }
            .focusedSceneValue(
                \.helpCommands,
                HelpCommands(openHelp: { openWindow(id: "help") })
            )
#else
            .sheet(isPresented: $isPresentingHelp) { HelpView() }
            .focusedSceneValue(
                \.helpCommands,
                HelpCommands(openHelp: { isPresentingHelp = true })
            )
#endif
    }

#if targetEnvironment(macCatalyst)
    @MainActor
    private func updateWindowTitle() {
        let title = windowTitle
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first { $0.activationState == .foregroundActive }?
            .title = title
    }

    private var windowTitle: String {
        switch sidebarSelection {
        case .root(let tab):
            return tab.title
        case .addPlannedExpense:
            return "Add Planned Expense"
        case .addVariableExpense:
            return "Add Variable Expense"
        case .managePresets:
            return "Presets"
        case .manageCategories:
            return "Categories"
        case .none:
            return selectedTab.title
        }
    }
#endif

    // MARK: Body builders
    private var prefersCompactTabs: Bool {
#if os(iOS)
        return UIDevice.current.userInterfaceIdiom == .phone
#else
        return false
#endif
    }

    private var shouldUseCompactTabs: Bool {
        prefersCompactTabs || usesCompactTabsOverride || isNarrowLayout
    }

    private var showsSidebarRestoreControl: Bool {
        usesCompactTabsOverride && !prefersCompactTabs && !isNarrowLayout
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
            SwiftUI.Tab(Tab.home.title, systemImage: Tab.home.systemImage, value: Tab.home) {
                navigationContainer {
                    decoratedTabContent(for: .home)
                }
            }
            .accessibilityIdentifier(Tab.home.accessibilityID)

            SwiftUI.Tab(Tab.budgets.title, systemImage: Tab.budgets.systemImage, value: Tab.budgets) {
                navigationContainer {
                    decoratedTabContent(for: .budgets)
                }
            }
            .accessibilityIdentifier(Tab.budgets.accessibilityID)

            SwiftUI.Tab(Tab.income.title, systemImage: Tab.income.systemImage, value: Tab.income) {
                navigationContainer {
                    decoratedTabContent(for: .income)
                }
            }
            .accessibilityIdentifier(Tab.income.accessibilityID)

            SwiftUI.Tab(Tab.cards.title, systemImage: Tab.cards.systemImage, value: Tab.cards) {
                navigationContainer {
                    decoratedTabContent(for: .cards)
                }
            }
            .accessibilityIdentifier(Tab.cards.accessibilityID)

            SwiftUI.Tab(Tab.settings.title, systemImage: Tab.settings.systemImage, value: Tab.settings) {
                navigationContainer {
                    decoratedTabContent(for: .settings)
                }
            }
            .accessibilityIdentifier(Tab.settings.accessibilityID)
        }
        .onAppear { applyStartTabIfNeeded() }
    }

    private var baseTabView: some View {
        TabView(selection: $selectedTab) {
            legacyTabViewItem(for: .home)
            legacyTabViewItem(for: .budgets)
            legacyTabViewItem(for: .income)
            legacyTabViewItem(for: .cards)
            legacyTabViewItem(for: .settings)
        }
        .onAppear { applyStartTabIfNeeded() }
    }

    @ViewBuilder
    private var splitViewBody: some View {
        if #available(iOS 16.0, macCatalyst 16.0, macOS 13.0, *) {
            NavigationSplitView(columnVisibility: $columnVisibility) {
                sidebarList
            } detail: {
                sidebarDetail
            }
            .onAppear {
                applyStartTabIfNeeded()
                columnVisibility = sidebarVisibilityValue(from: sidebarVisibilityRaw)
            }
            .onChange(of: sidebarSelection) { selection in
                switch selection {
                case .root(let tab):
                    selectedTab = tab
                default:
                    break
                }
            }
            .onChange(of: columnVisibility) { visibility in
                sidebarVisibilityRaw = sidebarVisibilityRawValue(from: visibility)
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
                    Label("Add Planned Expense", systemImage: "calendar.badge.plus")
                }
                let variableItem = SidebarItem.addVariableExpense
                sidebarRow(item: variableItem) {
                    Label("Add Variable Expense", systemImage: "plus.circle")
                }
            }

            Section("Quick Links") {
                let presetsItem = SidebarItem.managePresets
                sidebarRow(item: presetsItem) {
                    Label("Manage Presets", systemImage: "slider.horizontal.3")
                }
                let categoriesItem = SidebarItem.manageCategories
                sidebarRow(item: categoriesItem) {
                    Label("Manage Categories", systemImage: "tag")
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
                        usesCompactTabsOverride = true
                    }
                } label: {
                    Image(systemName: "inset.filled.topthird.rectangle")
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
            decoratedRootContent(AddPlannedExpenseView(onSaved: {}))
        case .addVariableExpense:
            decoratedRootContent(AddUnplannedExpenseView(onSaved: {}))
        case .managePresets:
            decoratedRootContent(PresetsView())
        case .manageCategories:
            decoratedRootContent(ExpenseCategoryManagerView())
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
                                usesCompactTabsOverride = false
                            }
                        } label: {
                            Label("Show Sidebar", systemImage: "sidebar.leading")
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

    private func loadingPlaceholder() -> some View {
        Color.clear
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .accessibilityHidden(true)
    }

    private func sidebarRowBackground(isSelected: Bool) -> some View {
        Group {
            if isSelected {
                RoundedRectangle(cornerRadius: DesignSystem.Radius.card, style: .continuous)
                    .fill(selectedSidebarTint)
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
        let base = Button {
            sidebarSelection = item
        } label: {
            label()
                .foregroundStyle(.primary)
                .padding(.vertical, 6)
                .padding(.horizontal, 4)
        }
        .buttonStyle(.plain)
        .listRowInsets(EdgeInsets(top: 6, leading: DesignSystem.Spacing.s, bottom: 6, trailing: DesignSystem.Spacing.s))
        .listRowBackground(
            sidebarRowBackground(isSelected: sidebarSelection == item)
                .padding(.horizontal, DesignSystem.Spacing.s / 2)
        )
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

    private func sidebarVisibilityValue(from rawValue: String) -> NavigationSplitViewVisibility {
        switch SidebarVisibility(rawValue: rawValue) {
        case .all:
            return .all
        case .detailOnly:
            return .detailOnly
        case .automatic, .none:
            return .automatic
        }
    }

    private func sidebarVisibilityRawValue(from visibility: NavigationSplitViewVisibility) -> String {
        if visibility == .all {
            return SidebarVisibility.all.rawValue
        }
        if visibility == .detailOnly {
            return SidebarVisibility.detailOnly.rawValue
        }
        return SidebarVisibility.automatic.rawValue
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

//
//  RootTabView.swift
//  so-far
//
//  Created by Michael Brown on 8/8/25.
//

import SwiftUI

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
    // Active theme and glass configuration provided by the app. This controls
    // background/chrome appearance via compatibility modifiers.
    @EnvironmentObject private var themeManager: ThemeManager
    @Environment(\.dataRevision) private var dataRevision

    // MARK: Tabs
    /// Logical destinations in the root tab bar. The order here matches the
    /// presentation order in the `TabView`.
    enum Tab: Hashable, CaseIterable {
        case home
        case income
        case cards
        case presets
        case settings
    }

    // MARK: State
    /// Currently selected tab. Defaults to `.home` to match existing behavior.
    @Environment(\.startTabIdentifier) private var startTabIdentifier
    @State private var selectedTab: Tab = .home
    @State private var appliedStartTab: Bool = false

    var body: some View {
        tabViewBody
    }

    // MARK: Body builders
    /// The underlying `TabView` that binds to `selectedTab` and hosts each tab.
    @ViewBuilder
    private var tabViewBody: some View {
        if #available(iOS 18.0, macCatalyst 18.0, macOS 15.0, *) {
            baseTabView
                .tabViewStyle(.sidebarAdaptable)
                .sidebar { sidebarList }
        } else {
            baseTabView
        }
    }

    private var baseTabView: some View {
        TabView(selection: $selectedTab) {
            tabViewItem(for: .home)
            tabViewItem(for: .income)
            tabViewItem(for: .cards)
            tabViewItem(for: .presets)
            tabViewItem(for: .settings)
        }
        .onAppear { applyStartTabIfNeeded() }
    }

    @available(iOS 18.0, macCatalyst 18.0, macOS 15.0, *)
    private var sidebarList: some View {
        List(selection: $selectedTab) {
            SidebarSections(selection: $selectedTab)
        }
        .listStyle(.sidebar)
    }

    @ViewBuilder
    /// Wraps a tab's content in a navigation container and assigns label/icon/tag.
    /// - Parameter tab: Logical tab identifier.
    private func tabViewItem(for tab: Tab) -> some View {
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
    /// Applies theme-aware navigation background and chrome to the tab content.
    /// - Parameter tab: Logical tab identifier.
    private func decoratedTabContent(for tab: Tab) -> some View {
        let base = tabContent(for: tab)
            .ub_navigationBackground(
                theme: themeManager.selectedTheme,
                configuration: themeManager.glassConfiguration
            )
            .ub_rootNavigationChrome()

        // On legacy OS versions (pre‑OS26), explicitly style the tab bar background
        // so it matches the app theme instead of an opaque system white. This
        // avoids the bottom “white bar” appearance and makes more content visible.
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
    /// Returns the root view for the given tab without additional decoration.
    /// - Parameter tab: Logical tab identifier.
    private func tabContent(for tab: Tab) -> some View {
        switch tab {
        case .home:
            HomeView()
                .id(dataRevision)
        case .income:
            IncomeView()
                .id(dataRevision)
        case .cards:
            CardsView()
                .id(dataRevision)
        case .presets:
            PresetsView()
                .id(dataRevision)
        case .settings:
            SettingsView()
        }
    }

    @ViewBuilder
    /// Host container that provides navigation for each tab, selecting
    /// `NavigationStack` on iOS/Catalyst 16+ and falling back to
    /// `NavigationView` elsewhere to preserve navigation behavior.
    private func navigationContainer<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        if #available(iOS 16.0, macCatalyst 16.0, *) {
            NavigationStack { content() }
        } else {
            NavigationView { content() }
                .navigationViewStyle(StackNavigationViewStyle())
        }
    }
}

// MARK: - Tab Metadata
private extension RootTabView.Tab {
    /// Localized title used in the tab bar label for each case.
    var title: String {
        switch self {
        case .home:
            return "Home"
        case .income:
            return "Income"
        case .cards:
            return "Cards"
        case .presets:
            return "Presets"
        case .settings:
            return "Settings"
        }
    }

    /// SF Symbols name for the system image used in the tab bar.
    var systemImage: String {
        switch self {
        case .home:
            return "house"
        case .income:
            return "calendar"
        case .cards:
            return "creditcard"
        case .presets:
            return "list.bullet.rectangle"
        case .settings:
            return "gear"
        }
    }

    /// Stable accessibility identifier for UI testing.
    var accessibilityID: String {
        switch self {
        case .home: return "tab_home"
        case .income: return "tab_income"
        case .cards: return "tab_cards"
        case .presets: return "tab_presets"
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
            appliedStartTab = true
        }
    }

    func mapStartTab(key: String) -> Tab? {
        switch key.lowercased() {
        case "home": return .home
        case "income": return .income
        case "cards": return .cards
        case "presets": return .presets
        case "settings": return .settings
        default: return nil
        }
    }
}

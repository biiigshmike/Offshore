import SwiftUI

private struct CurrentRootTabKey: EnvironmentKey {
    static let defaultValue: RootTabView.Tab = .home
}

private struct CurrentSidebarSelectionKey: EnvironmentKey {
    static let defaultValue: RootTabView.SidebarItem? = nil
}

extension EnvironmentValues {
    var currentRootTab: RootTabView.Tab {
        get { self[CurrentRootTabKey.self] }
        set { self[CurrentRootTabKey.self] = newValue }
    }

    var currentSidebarSelection: RootTabView.SidebarItem? {
        get { self[CurrentSidebarSelectionKey.self] }
        set { self[CurrentSidebarSelectionKey.self] = newValue }
    }
}

//
//  SidebarSections.swift
//  OffshoreBudgeting
//
//  Created by AI on 2024.
//

import SwiftUI

struct SidebarSections: View {
    @Binding var selection: RootTabView.Tab
    @EnvironmentObject private var navigationRouter: HomeNavigationRouter

    var body: some View {
        Section("Overview") {
            ForEach(RootTabView.Tab.primarySidebarTabs, id: \.self) { tab in
                sidebarRow(for: tab)
            }
        }

        Section("Management") {
            ForEach(RootTabView.Tab.secondarySidebarTabs, id: \.self) { tab in
                sidebarRow(for: tab)
            }
        }

        Section("Quick Actions") {
            Button {
                selection = .home
                navigationRouter.present(.addPlanned)
            } label: {
                Label("Add Planned Expense", systemImage: "calendar.badge.plus")
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .buttonStyle(.plain)

            Button {
                selection = .home
                navigationRouter.present(.addVariable)
            } label: {
                Label("Add Variable Expense", systemImage: "dollarsign.square")
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .buttonStyle(.plain)
        }
    }

    private func sidebarRow(for tab: RootTabView.Tab) -> some View {
        Button {
            selection = tab
        } label: {
            Label(tab.title, systemImage: tab.systemImage)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .buttonStyle(.plain)
        .tag(tab)
        .contentShape(Rectangle())
        .listRowBackground(listRowBackground(for: tab))
    }

    private func listRowBackground(for tab: RootTabView.Tab) -> some View {
        Group {
            if selection == tab {
                RoundedRectangle(cornerRadius: DesignSystem.Radius.card)
                    .fill(Color.accentColor.opacity(0.15))
            } else {
                Color.clear
            }
        }
    }
}

private extension RootTabView.Tab {
    static var primarySidebarTabs: [RootTabView.Tab] { [.home, .income, .cards] }
    static var secondarySidebarTabs: [RootTabView.Tab] { [.presets, .settings] }
}

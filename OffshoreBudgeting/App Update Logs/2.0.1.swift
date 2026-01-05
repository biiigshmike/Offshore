import SwiftUI

enum AppUpdateLog_2_0_1 {
    static func content(for screen: TipsScreen) -> TipsContent? {
        switch screen {
        case .home:
            let info = Bundle.main.infoDictionary
            let version = info?["CFBundleShortVersionString"] as? String ?? "0"
            let build = info?["CFBundleVersion"] as? String ?? "0"
            return TipsContent(
                title: "What's New • \(version) (Build \(build))",
                items: [
                    TipsItem(
                        symbolName: "sidebar.left",
                        title: "Sidebar Navigation",
                        detail: "Sidebar navigation support for iPad and Mac."
                    ),
                    TipsItem(
                        symbolName: "sparkles",
                        title: "UI Enhancements",
                        detail: "UI enhancements and cohesion across the app."
                    ),
                    TipsItem(
                        symbolName: "widget.small",
                        title: "Widgets",
                        detail: "iOS and macOS widgets for the Home Screen and Desktop."
                    ),
                    TipsItem(
                        symbolName: "calendar",
                        title: "Income Calendar",
                        detail: "Improved landscape calendar sizing so a full month fits on larger displays."
                    ),
                    TipsItem(
                        symbolName: "questionmark.circle",
                        title: "Help Guide",
                        detail: "More in-depth help guide."
                    ),
                    TipsItem(
                        symbolName: "paintpalette",
                        title: "Category Heat Map",
                        detail: "Card Detail now shows a category heat map on the Total Spent row to help visualize spending."
                    ),
                    TipsItem(
                        symbolName: "lightbulb.fill",
                        title: "Post-Onboarding Tips",
                        detail: "Post-onboarding overlays detailing each screen."
                    ),
                    TipsItem(
                        symbolName: "person.3.fill",
                        title: "Workspaces",
                        detail: "Profiles/Workspaces support for keeping budgets separated, for example, Personal and Work."
                    ),
                    TipsItem(
                        symbolName: "bell.badge",
                        title: "Notifications",
                        detail: "Local device notifications to remind you to log expenses and income."
                    )
                ],
                actionTitle: "Got It"
            )
        default:
            return nil
        }
    }
}

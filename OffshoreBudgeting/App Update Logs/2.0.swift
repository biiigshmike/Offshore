import SwiftUI

enum AppUpdateLog_2_0 {
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
                        symbolName: "dollarsign.bank.building",
                        title: "Offshore Released to the Public",
                        detail: "Offshore Budgeting released! A privacy-first app that provides a clean way to track income and expenses."
                    )
                ],
                actionTitle: "Got It"
            )
        default:
            return nil
        }
    }
}

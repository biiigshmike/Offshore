import SwiftUI

enum AppUpdateLog_2_0 {
    static func content(for screen: TipsScreen) -> TipsContent? {
        switch screen {
        case .home:
            return TipsContent(
                title: AppVersion.shared.displayTitle,
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

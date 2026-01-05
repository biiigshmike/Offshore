//
//  2.0.2.swift
//  Offshore
//
//  Created by Michael Brown on 1/5/26.
//

import SwiftUI

enum AppUpdateLog_2_1 {
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
                        symbolName: "creditcard.fill",
                        title: "Import Transactions",
                        detail: "Go to your Card's detailed overview, press the + symbol, then Import Transactions. Choose which transactions to import and attach them to the selected card effortlessly.\nNote: .csv is the only format currently accepted."
                    ),
                    TipsItem(
                        symbolName: "accessibility.fill",
                        title: "Accessibility",
                        detail: "Offshore now is truly Accessibile for all users. Made app-wide changes to ensure all elements are Accessibility compliant, such as Dynamic Type, Increase contrast, etc."
                    ),
                    TipsItem(
                        symbolName: "hand.raised.circle.fill",
                        title: "Privacy",
                        detail: "Fixed a bug that resulted in Biometrics being asked on devices that were not enrolled. App can now be locked with your device's passcode, if enabled."
                    ),
                    TipsItem(
                        symbolName: "lightbulb.fill",
                        title: "Tips & Hints",
                        detail: "Fixed an error where Tips & Hints for each screen would appear after updating the app to a new version. Hints should now only show for the first time per screen and or if you press the Reset Tips & Hints button in Settings > General.\nNote: What's New alerts will show if significant updates were made on the latest update."
                    ),
                    TipsItem(
                        symbolName: "sidebar.left",
                        title: "Sidebar",
                        detail: "Fixed a bug where if the sidebar was visible, the back < button would not display in nested navigation views."
                    ),
                    TipsItem(
                        symbolName: "sparkles",
                        title: "Polish and Sparkle",
                        detail: "Sprinkled glitter here and there to help the app shine bright and run smoother."
                    )
                ],
                actionTitle: "Got It"
            )
        default:
            return nil
        }
    }
}

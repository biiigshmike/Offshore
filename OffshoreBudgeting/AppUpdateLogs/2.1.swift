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
            return TipsContent(
                title: AppVersion.shared.displayTitle,
                items: [
                    TipsItem(
                        symbolName: "creditcard",
                        title: "Import Transactions & Card Themes",
                        detail: "Import .csv transactions directly into a card from its detail view. Select what you want and attach them instantly. Updated Card creation form with new Effects feature! Find the perfect effect to pair with your Card's theme."
                    ),
                    TipsItem(
                        symbolName: "accessibility",
                        title: "Accessibility Improvements",
                        detail: "App-wide accessibility updates, including Dynamic Type and improved contrast. The Home grid was simplified to ensure full compliance."
                    ),
                    TipsItem(
                        symbolName: "hand.raised.circle",
                        title: "Privacy & Security",
                        detail: "Biometric prompts now appear only on enrolled devices. You can also lock the app using your device passcode, if enabled."
                    ),
                    TipsItem(
                        symbolName: "lightbulb.fill",
                        title: "Tips & Hints",
                        detail: "Tips now appear only once per screen, or when manually reset in Settings. What’s New alerts appear only for significant updates."
                    ),
                    TipsItem(
                        symbolName: "sidebar.left",
                        title: "Sidebar Navigation",
                        detail: "Fixed an issue where the back button was missing in nested views when the sidebar was visible."
                    ),
                    TipsItem(
                        symbolName: "sparkles",
                        title: "General Improvements",
                        detail: "Small bug fixes and performance improvements throughout the app."
                    )
                ],
                actionTitle: "Got It"
            )
        default:
            return nil
        }
    }
}

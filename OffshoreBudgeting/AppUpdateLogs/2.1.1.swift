//
//  2.1.1.swift
//  Offshore
//
//  Created by Michael Brown on 1/14/26.
//
import SwiftUI

enum AppUpdateLog_2_1_1 {
    static func content(for screen: TipsScreen) -> TipsContent? {
        switch screen {
        case .home:
            return TipsContent(
                title: AppVersion.shared.displayTitle,
                items: [
                    TipsItem(
                        symbolName: "dollarsign.bank.building",
                        title: "Behind the Vault Improvements",
                        detail: "Worked on restructuring the app, improving loading speeds, and helping Offshore prepare for the future of budgeting."
                    )
                ],
                actionTitle: "Got It"
            )
        default:
            return nil
        }
    }
}

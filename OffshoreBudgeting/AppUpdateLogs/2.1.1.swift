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
                        detail: "Reinforced the vault for Offshore’s future. Cleared out a few barnacles to help everything run faster."
                    ),
                    TipsItem(
                        symbolName: "creditcard.fill",
                        title: "Improvements to Importing Expenses",
                        detail: "Incoming transactions now come pre-loaded with cleaner names instead of long strings of bank text. You can store preferred names locally so future imports recognize the preferred name automatically."
                    )
                ],
                actionTitle: "Got It"
            )
        default:
            return nil
        }
    }
}

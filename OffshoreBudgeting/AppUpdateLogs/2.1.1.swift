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
                        detail: "Worked on restructuring the app to prepare Offshore for the future of budgeting. Swept a few dead bugs off the vault floor to help make the app run faster."
                    ),
                    TipsItem(
                        symbolName: "creditcard.fill",
                        title: "Improvements to Importing Expenses",
                        detail: "Import process now automatically parses long bank Transaction Description text into a cleaner expense name. If you enable the toggle to use the expense name next time, the app can also remember your preference, locally on your device. This will make future imports suggest the saved name next time it's encountered."
                    )
                ],
                actionTitle: "Got It"
            )
        default:
            return nil
        }
    }
}

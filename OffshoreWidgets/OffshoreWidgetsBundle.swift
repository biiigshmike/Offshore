//
//  OffshoreWidgetsBundle.swift
//  OffshoreWidgets
//
//  Created by Michael Brown on 12/25/25.
//

import WidgetKit
import SwiftUI

@main
@available(iOS 17.0, *)
struct OffshoreWidgetsBundle: WidgetBundle {
    var body: some Widget {
        IncomeWidget()
        ExpenseToIncomeWidget()
        SavingsOutlookWidget()
        NextPlannedExpenseWidget()
    }
}

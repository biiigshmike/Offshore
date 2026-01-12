//
//  PresetRowView.swift
//  SoFar
//
//  Created by Michael Brown on 8/14/25.
//

import SwiftUI

#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

// MARK: - PresetRowView
/// Row layout matching the screenshot style:
/// Left column: Name, PLANNED/ACTUAL amounts.
/// Right column: "Assigned Budgets" pill and "NEXT DATE" label + value.
/// Tapping the pill opens the assignment sheet via callback.
struct PresetRowView: View {

    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    // MARK: Inputs
    let item: PresetListItem
    let onAssignTapped: (PlannedExpense) -> Void

    // MARK: Body
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.m) {
            titleRow
            amountsRow
        }
        .padding(.vertical, Spacing.xxs)
        .accessibilityIdentifier(AccessibilityID.Settings.Presets.presetRow(id: item.id))
    }

    private var isAccessibilitySize: Bool {
        dynamicTypeSize.isAccessibilitySize
    }

    // MARK: Title + Assigned Budgets Badge
    private var titleRow: some View {
        Group {
            if isAccessibilitySize {
                VStack(alignment: .leading, spacing: Spacing.s) {
                    Text(item.name)
                        .font(Typography.title3Semibold)
                        .foregroundStyle(Colors.stylePrimary)
                        .lineLimit(nil)
                        .fixedSize(horizontal: false, vertical: true)
                    assignButton
                }
            } else {
                HStack(alignment: .center, spacing: Spacing.m) {
                    Text(item.name)
                        .font(Typography.title3Semibold)
                        .foregroundStyle(Colors.stylePrimary)
                        .lineLimit(2)
                        .minimumScaleFactor(0.85)
                        .allowsTightening(true)

                    Spacer(minLength: Spacing.m)
                    assignButton
                }
            }
        }
    }

    private var assignButton: some View {
        Button {
            onAssignTapped(item.template)
        } label: {
            AssignedBudgetsBadge(
                title: "Assigned Budgets",
                count: item.assignedCount,
                colorScheme: colorScheme
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Assigned Budgets: \(item.assignedCount)")
    }

    // MARK: Amounts + Next Date
    private var amountsRow: some View {
        Group {
            if isAccessibilitySize {
                VStack(alignment: .leading, spacing: Spacing.sPlus) {
                    HStack(spacing: 24) {
                        LabeledAmountBlock(title: "PLANNED", value: item.plannedCurrency)
                        LabeledAmountBlock(title: "ACTUAL", value: item.actualCurrency)
                    }
                    nextDateBlock(alignment: .leading)
                }
            } else {
                HStack(alignment: .top, spacing: Spacing.m) {
                    HStack(spacing: 32) {
                        LabeledAmountBlock(title: "PLANNED", value: item.plannedCurrency)
                        LabeledAmountBlock(title: "ACTUAL", value: item.actualCurrency)
                    }

                    Spacer(minLength: Spacing.m)

                    nextDateBlock(alignment: .trailing)
                }
            }
        }
    }

    private func nextDateBlock(alignment: HorizontalAlignment) -> some View {
        VStack(alignment: alignment, spacing: Spacing.xxs) {
            Text("NEXT DATE")
                .font(Typography.caption2Semibold)
                .foregroundStyle(Colors.styleSecondary)
                .textCase(.uppercase)

            Text(item.nextDateLabel)
                .font(Typography.body)
                .foregroundStyle(Colors.stylePrimary)
                .lineLimit(isAccessibilitySize ? nil : 1)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

}

// MARK: - LabeledAmountBlock
/// Small helper for the "PLANNED" / "ACTUAL" blocks.
private struct LabeledAmountBlock: View {
    let title: String
    let value: String
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    private var isAccessibilitySize: Bool {
        dynamicTypeSize.isAccessibilitySize
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(Typography.caption2Semibold)
                .foregroundStyle(Colors.styleSecondary)
                .textCase(.uppercase)
            Text(value)
                .font(Typography.body)
                .foregroundStyle(Colors.stylePrimary)
                .lineLimit(isAccessibilitySize ? nil : 1)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

// MARK: - AssignedBudgetsBadge
private struct AssignedBudgetsBadge: View {
    let title: String
    let count: Int
    let colorScheme: ColorScheme
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @ScaledMetric(relativeTo: .body) private var countCircleSize: CGFloat = 28

    private var isAccessibilitySize: Bool {
        dynamicTypeSize.isAccessibilitySize
    }

    var body: some View {
        HStack(spacing: Spacing.sPlus) {
            Text(title)
                .font(Typography.subheadlineSemibold)
                .foregroundStyle(titleColor)
                .lineLimit(isAccessibilitySize ? nil : 1)
                .minimumScaleFactor(0.85)
                .allowsTightening(true)

            ZStack {
                Circle()
                    .fill(circleBackgroundColor)

                Text("\(count)")
                    .font(.footnote.weight(.bold))
                    .foregroundStyle(circleForegroundColor)
            }
            .frame(width: countCircleSize, height: countCircleSize)
        }
        .padding(.horizontal, Spacing.m)
        .padding(.vertical, Spacing.s)
        .fixedSize(horizontal: !isAccessibilitySize, vertical: false)
    }

    private var titleColor: Color {
        .primary
    }

    private var circleBackgroundColor: Color {
        if colorScheme == .dark {
            return circleBackgroundColorDark
        }

        return circleBackgroundColorLight
    }

    private var circleForegroundColor: Color {
        .primary
    }

    private var circleBackgroundColorLight: Color {
#if canImport(UIKit)
        Color(uiColor: .systemGray5)
#elseif canImport(AppKit)
        Color(nsColor: .systemGray5)
#else
        Colors.grayOpacity02
#endif
    }

    private var circleBackgroundColorDark: Color {
#if canImport(UIKit)
        Color(uiColor: .systemGray3)
#elseif canImport(AppKit)
        Color(nsColor: .systemGray3)
#else
        Color.gray.opacity(0.4)
#endif
    }
}

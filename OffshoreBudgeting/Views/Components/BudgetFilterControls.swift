import SwiftUI

struct BudgetExpenseSegmentedControl<Segment: Hashable>: View {
    let plannedSegment: Segment
    let variableSegment: Segment
    @Binding var selection: Segment

    var body: some View {
        UBSegmentedControl(
            selection: $selection,
            segments: [
                .init(id: "planned", title: "Planned Expenses", value: plannedSegment),
                .init(id: "variable", title: "Variable Expenses", value: variableSegment)
            ],
            selectedTint: AppTheme.system.resolvedTint.opacity(0.06),
            containerTint: .clear
        )
    }
}

struct BudgetSortBar<Sort: Hashable>: View {
    @Binding var selection: Sort
    let options: [(Sort, String)]

    var body: some View {
        UBSegmentedControl(
            selection: $selection,
            segments: options.enumerated().map { idx, option in
                UBSegmentedControl<Sort>.Segment(
                    id: "sort-\(idx)",
                    title: option.1,
                    value: option.0
                )
            },
            selectedTint: AppTheme.system.resolvedTint.opacity(0.06),
            containerTint: .clear
        )
    }
}

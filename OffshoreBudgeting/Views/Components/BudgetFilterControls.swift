import SwiftUI

struct BudgetExpenseSegmentedControl<Segment: Hashable>: View {
    let plannedSegment: Segment
    let variableSegment: Segment
    @Binding var selection: Segment

    var body: some View {
        Picker("", selection: $selection) {
            Text("Planned Expenses").tag(plannedSegment)
            Text("Variable Expenses").tag(variableSegment)
        }
        .pickerStyle(.segmented)
    }
}

struct BudgetSortBar<Sort: Hashable>: View {
    @Binding var selection: Sort
    let options: [(Sort, String)]

    var body: some View {
        Picker("Sort", selection: $selection) {
            ForEach(Array(options.enumerated()), id: \.offset) { item in
                let option = item.element
                Text(option.1).tag(option.0)
            }
        }
        .pickerStyle(.segmented)
    }
}

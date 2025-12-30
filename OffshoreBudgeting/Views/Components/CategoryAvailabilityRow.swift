import SwiftUI

struct CategoryAvailabilityRow: View {
    let item: CategoryAvailability
    let currencyFormatter: (Double) -> String

    var body: some View {
        let availableDisplay: Double = {
            if let cap = item.cap {
                return cap - item.spent
            }
            return item.available
        }()

        HStack(alignment: .center, spacing: 12) {
            Circle().fill(item.color.opacity(0.75)).frame(width: 12, height: 12)
            VStack(alignment: .leading, spacing: 4) {
                Text(item.name)
                    .font(.ubDetailLabel.weight(.semibold))
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Max: \(item.cap.map { currencyFormatter($0) } ?? "∞")")
                        .font(.ubCaption)
                        .foregroundStyle(.secondary)
                    HStack(spacing: 2) {
                        Text("Available:")
                            .font(.ubCaption)
                            .foregroundStyle(.primary)
                        Text(currencyFormatter(availableDisplay))
                            .font(.ubCaption)
                            .foregroundStyle(availableDisplay < 0 ? Color.red : .primary)
                    }
                }
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 4) {
                Text("Spent \(currencyFormatter(item.spent))")
                    .font(.ubCaption)
                    .foregroundStyle(item.over ? Color.red : (item.near ? Color.orange : .secondary))
                if let cap = item.cap {
                    ProgressView(value: min(item.spent / max(cap, 1), 1))
                        .tint(item.color)
                        .frame(width: 120)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

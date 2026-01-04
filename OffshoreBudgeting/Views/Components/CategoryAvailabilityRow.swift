import SwiftUI

struct CategoryAvailabilityRow: View {
    let item: CategoryAvailability
    let currencyFormatter: (Double) -> String
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @ScaledMetric(relativeTo: .body) private var progressWidth: CGFloat = 120

    private var useStackedLayout: Bool {
        dynamicTypeSize.isAccessibilitySize || horizontalSizeClass == .compact
    }

    var body: some View {
        let availableDisplay: Double = {
            if let cap = item.cap {
                return cap - item.spent
            }
            return item.available
        }()
        let progressTotal: Double = {
            if let cap = item.cap {
                return max(cap, 1)
            }
            let total = item.spent + max(availableDisplay, 0)
            return max(total, 1)
        }()
        let progressValue = min(max(item.spent, 0) / progressTotal, 1)

        Group {
            if useStackedLayout {
                VStack(alignment: .leading, spacing: 6) {
                    HStack(alignment: .center, spacing: 12) {
                        Circle().fill(item.color.opacity(0.75)).frame(width: 12, height: 12)
                        Text(item.name)
                            .font(.ubDetailLabel.weight(.semibold))
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                    }
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
                    HStack(spacing: 8) {
                        Text("Spent \(currencyFormatter(item.spent))")
                            .font(.ubCaption)
                            .foregroundStyle(item.over ? Color.red : (item.near ? Color.orange : .secondary))
                        ProgressView(value: progressValue)
                            .tint(item.color)
                            .frame(maxWidth: .infinity)
                    }
                }
            } else {
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
                        ProgressView(value: progressValue)
                            .tint(item.color)
                            .frame(width: progressWidth)
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }
}

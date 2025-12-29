import WidgetKit
import SwiftUI

enum NextPlannedExpenseWidgetStore {
    static let appGroupID = "group.com.mb.offshore-budgeting"
    static let snapshotKey = "widget.nextPlannedExpense.snapshot"

    struct Snapshot: Codable {
        let title: String
        let plannedAmount: Double
        let actualAmount: Double
        let date: Date
        let cardName: String?
        let cardThemeName: String?
        let cardPrimaryHex: String?
        let cardSecondaryHex: String?
        let cardPattern: String?
        let rangeLabel: String
        let updatedAt: Date
    }

    static func readSnapshot() -> Snapshot? {
        guard let defaults = UserDefaults(suiteName: appGroupID) else { return nil }
        guard let data = defaults.data(forKey: snapshotKey) else { return nil }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try? decoder.decode(Snapshot.self, from: data)
    }

    static func sampleSnapshot() -> Snapshot {
        Snapshot(
            title: "Gas & Parking",
            plannedAmount: 90,
            actualAmount: 0,
            date: Calendar.current.date(byAdding: .day, value: 2, to: Date()) ?? Date(),
            cardName: "Everyday Card",
            cardThemeName: nil,
            cardPrimaryHex: "#1C1C1E",
            cardSecondaryHex: "#2C2C2E",
            cardPattern: nil,
            rangeLabel: "This Month",
            updatedAt: Date()
        )
    }
}

struct NextPlannedExpenseEntry: TimelineEntry {
    let date: Date
    let snapshot: NextPlannedExpenseWidgetStore.Snapshot?
}

struct NextPlannedExpenseProvider: TimelineProvider {
    func placeholder(in context: Context) -> NextPlannedExpenseEntry {
        NextPlannedExpenseEntry(date: Date(), snapshot: NextPlannedExpenseWidgetStore.sampleSnapshot())
    }

    func getSnapshot(in context: Context, completion: @escaping (NextPlannedExpenseEntry) -> Void) {
        let snapshot = NextPlannedExpenseWidgetStore.readSnapshot() ?? NextPlannedExpenseWidgetStore.sampleSnapshot()
        completion(NextPlannedExpenseEntry(date: Date(), snapshot: snapshot))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<NextPlannedExpenseEntry>) -> Void) {
        let entry = NextPlannedExpenseEntry(date: Date(), snapshot: NextPlannedExpenseWidgetStore.readSnapshot())
        completion(Timeline(entries: [entry], policy: .after(Date().addingTimeInterval(60 * 30))))
    }
}

struct NextPlannedExpenseWidgetView: View {
    let entry: NextPlannedExpenseEntry

    var body: some View {
        let snapshot = entry.snapshot

        let content = VStack(alignment: .leading, spacing: 8) {
            Text("Next Planned Expense")
                .font(.headline)
                .lineLimit(2)
                .minimumScaleFactor(0.85)
                .frame(maxWidth: .infinity, alignment: .leading)
            if let snapshot {
                HStack(alignment: .top, spacing: 12) {
                    CardPreview(
                        cardName: snapshot.cardName,
                        primaryHex: snapshot.cardPrimaryHex,
                        secondaryHex: snapshot.cardSecondaryHex
                    )
                    .frame(width: 112, height: 70)

                    Spacer(minLength: 0)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(snapshot.title)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.primary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.85)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        Text(shortDate(snapshot.date))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        Text("Planned: \(formatCurrency(snapshot.plannedAmount))")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.primary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.85)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        Text("Actual: \(formatCurrency(snapshot.actualAmount))")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.85)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .frame(maxWidth: .infinity, alignment: .trailing)
                }
            } else {
                Text("No planned expenses in this range.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()

        if #available(iOS 17.0, *) {
            content
                .containerBackground(.fill.tertiary, for: .widget)
        } else {
            content
        }
    }

    private func formatCurrency(_ value: Double) -> String {
        let code = Locale.current.currency?.identifier ?? "USD"
        return value.formatted(.currency(code: code))
    }

    private func shortDate(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateStyle = .medium
        return f.string(from: date)
    }
}

@available(iOS 17.0, *)
struct NextPlannedExpenseWidget: Widget {
    static let kind = "com.mb.offshore.nextPlannedExpense.widget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: Self.kind, provider: NextPlannedExpenseProvider()) { entry in
            NextPlannedExpenseWidgetView(entry: entry)
        }
        .configurationDisplayName("Next Planned Expense")
        .description("Shows the next planned expense for the period.")
        .supportedFamilies([.systemMedium])
    }
}

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
}

struct NextPlannedExpenseEntry: TimelineEntry {
    let date: Date
    let snapshot: NextPlannedExpenseWidgetStore.Snapshot?
}

struct NextPlannedExpenseProvider: TimelineProvider {
    func placeholder(in context: Context) -> NextPlannedExpenseEntry {
        NextPlannedExpenseEntry(date: Date(), snapshot: nil)
    }

    func getSnapshot(in context: Context, completion: @escaping (NextPlannedExpenseEntry) -> Void) {
        completion(NextPlannedExpenseEntry(date: Date(), snapshot: NextPlannedExpenseWidgetStore.readSnapshot()))
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
                        themeName: snapshot.cardThemeName,
                        primaryHex: snapshot.cardPrimaryHex,
                        secondaryHex: snapshot.cardSecondaryHex,
                        patternName: snapshot.cardPattern
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

private struct CardPreview: View {
    let cardName: String?
    let themeName: String?
    let primaryHex: String?
    let secondaryHex: String?
    let patternName: String?

    var body: some View {
        let primary = Color(hex: primaryHex) ?? Color.secondary.opacity(0.2)
        let secondary = Color(hex: secondaryHex) ?? primary.opacity(0.8)

        RoundedRectangle(cornerRadius: 10, style: .continuous)
            .fill(LinearGradient(colors: [primary, secondary], startPoint: .topLeading, endPoint: .bottomTrailing))
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(Color.white.opacity(0.15), lineWidth: 1)
            )
            .overlay(alignment: .bottomLeading) {
                if let cardName, !cardName.isEmpty {
                    Text(cardName)
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                        .padding(6)
                }
            }
    }
}

private extension Color {
    init?(hex: String?) {
        guard let hex else { return nil }
        let trimmed = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        guard trimmed.count == 6 || trimmed.count == 8 else { return nil }
        var int: UInt64 = 0
        guard Scanner(string: trimmed).scanHexInt64(&int) else { return nil }
        let a, r, g, b: UInt64
        if trimmed.count == 8 {
            a = (int >> 24) & 0xff
            r = (int >> 16) & 0xff
            g = (int >> 8) & 0xff
            b = int & 0xff
        } else {
            a = 255
            r = (int >> 16) & 0xff
            g = (int >> 8) & 0xff
            b = int & 0xff
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

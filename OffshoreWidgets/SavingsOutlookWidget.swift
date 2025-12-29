import WidgetKit
import SwiftUI
import AppIntents

enum SavingsOutlookWidgetStore {
    static let appGroupID = "group.com.mb.offshore-budgeting"
    static let snapshotKeyPrefix = "widget.savingsOutlook.snapshot."
    static let defaultPeriodKey = "widget.savingsOutlook.defaultPeriod"

    struct Snapshot: Codable {
        let actualSavings: Double
        let projectedSavings: Double
        let rangeLabel: String
        let updatedAt: Date
    }

    static func readSnapshot(periodRaw: String) -> Snapshot? {
        guard let defaults = UserDefaults(suiteName: appGroupID) else { return nil }
        guard let data = defaults.data(forKey: snapshotKeyPrefix + periodRaw) else { return nil }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try? decoder.decode(Snapshot.self, from: data)
    }

    static func defaultPeriodValue() -> WidgetPeriod {
        guard let defaults = UserDefaults(suiteName: appGroupID),
              let raw = defaults.string(forKey: defaultPeriodKey),
              let period = WidgetPeriod(rawValue: raw) else {
            return .monthly
        }
        return period
    }

    static func sampleSnapshot() -> Snapshot {
        Snapshot(
            actualSavings: 620.0,
            projectedSavings: 1400.0,
            rangeLabel: "This Month",
            updatedAt: Date()
        )
    }
}

struct SavingsOutlookWidgetEntry: TimelineEntry {
    let date: Date
    let snapshot: SavingsOutlookWidgetStore.Snapshot?
    let period: WidgetPeriod
}

@available(iOS 17.0, *)
struct SavingsOutlookWidgetIntentProvider: AppIntentTimelineProvider {
    typealias Intent = SavingsOutlookWidgetConfigurationIntent
    typealias Entry = SavingsOutlookWidgetEntry

    func placeholder(in context: Context) -> SavingsOutlookWidgetEntry {
        SavingsOutlookWidgetEntry(date: Date(), snapshot: SavingsOutlookWidgetStore.sampleSnapshot(), period: SavingsOutlookWidgetStore.defaultPeriodValue())
    }

    func snapshot(for configuration: SavingsOutlookWidgetConfigurationIntent, in context: Context) async -> SavingsOutlookWidgetEntry {
        let period = configuration.period ?? SavingsOutlookWidgetStore.defaultPeriodValue()
        let snapshot = resolveSnapshot(for: period) ?? SavingsOutlookWidgetStore.sampleSnapshot()
        return SavingsOutlookWidgetEntry(date: Date(), snapshot: snapshot, period: period)
    }

    func timeline(for configuration: SavingsOutlookWidgetConfigurationIntent, in context: Context) async -> Timeline<SavingsOutlookWidgetEntry> {
        let period = configuration.period ?? SavingsOutlookWidgetStore.defaultPeriodValue()
        let entry = SavingsOutlookWidgetEntry(date: Date(), snapshot: resolveSnapshot(for: period), period: period)
        return Timeline(entries: [entry], policy: .after(Date().addingTimeInterval(60 * 30)))
    }

    private func resolveSnapshot(for period: WidgetPeriod) -> SavingsOutlookWidgetStore.Snapshot? {
        return SavingsOutlookWidgetStore.readSnapshot(periodRaw: period.rawValue)
    }
}

@available(iOS 17.0, *)
struct SavingsOutlookWidgetConfigurationIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "Savings Outlook Settings"

    @Parameter(title: "Period")
    var period: WidgetPeriod?

    init() {
        self.period = SavingsOutlookWidgetStore.defaultPeriodValue()
    }
}

struct SavingsOutlookWidgetView: View {
    let entry: SavingsOutlookWidgetEntry

    @Environment(\.widgetFamily) private var family

    var body: some View {
        let resolvedSnapshot = entry.snapshot ?? SavingsOutlookWidgetStore.readSnapshot(periodRaw: entry.period.rawValue)
        let actual = resolvedSnapshot?.actualSavings ?? 0
        let projected = resolvedSnapshot?.projectedSavings ?? 0
        let range = resolvedSnapshot?.rangeLabel ?? ""

        let projectedPositive = projected > 0
        let percentOfProjected = projectedPositive ? (actual / projected) * 100 : nil
        let progressValue = projectedPositive ? min(max(actual / projected, 0), 1) : 0
        let percentLabel: String = {
            guard let percent = percentOfProjected else { return "—" }
            if percent > 999 { return ">999%" }
            return String(format: "%.0f%%", percent)
        }()
        let statusTint: Color = {
            if actual < 0 && projectedPositive { return .red }
            if let percent = percentOfProjected, percent >= 100 { return .green }
            return .orange
        }()

        let content = VStack(alignment: .leading, spacing: 8) {
            Text("Savings Outlook")
                .font(.headline)
                .lineLimit(2)
                .minimumScaleFactor(0.85)
            if family != .systemSmall, !range.isEmpty {
                Text(range)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            if family == .systemSmall {
                Text(percentLabel)
                    .font(.headline)
                ProgressView(value: progressValue)
                    .tint(statusTint)
                HStack {
                    Spacer()
                    Text("of projected")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.secondary)
                }
            } else {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Projected")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(projected, format: .currency(code: currencyCode))
                            .font(.headline)
                    }
                    Spacer()
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Actual")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(actual, format: .currency(code: currencyCode))
                            .font(.headline)
                    }
                }
                ProgressView(value: progressValue)
                    .tint(statusTint)
                Text(projectedPositive ? "\(percentLabel) of projected" : "—")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(actual < 0 ? .red : .secondary)
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

    private var currencyCode: String {
        if #available(iOS 16.0, *) {
            return Locale.current.currency?.identifier ?? "USD"
        }
        return "USD"
    }
}

@available(iOS 17.0, *)
struct SavingsOutlookWidget: Widget {
    static let kind = "com.mb.offshore.savingsOutlook.widget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: Self.kind, intent: SavingsOutlookWidgetConfigurationIntent.self, provider: SavingsOutlookWidgetIntentProvider()) { entry in
            SavingsOutlookWidgetView(entry: entry)
        }
        .configurationDisplayName("Savings Outlook")
        .description("Tracks actual savings against projected savings for the period.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

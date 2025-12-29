import WidgetKit
import SwiftUI
import AppIntents

enum IncomeWidgetStore {
    static let appGroupID = "group.com.mb.offshore-budgeting"
    static let incomeKeyPrefix = "widget.income.snapshot."
    static let incomeDefaultPeriodKey = "widget.income.defaultPeriod"

    struct IncomeSnapshot: Codable {
        let actualIncome: Double
        let plannedIncome: Double
        let percentReceived: Double
        let rangeLabel: String
        let updatedAt: Date
    }

    static func readSnapshot(periodRaw: String) -> IncomeSnapshot? {
        guard let defaults = UserDefaults(suiteName: appGroupID) else { return nil }
        guard let data = defaults.data(forKey: incomeKeyPrefix + periodRaw) else { return nil }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try? decoder.decode(IncomeSnapshot.self, from: data)
    }

    static func readDefaultPeriod() -> String? {
        guard let defaults = UserDefaults(suiteName: appGroupID) else { return nil }
        return defaults.string(forKey: incomeDefaultPeriodKey)
    }

    static func defaultPeriodValue() -> WidgetPeriod {
        guard let raw = readDefaultPeriod(),
              let period = WidgetPeriod(rawValue: raw) else {
            return .monthly
        }
        return period
    }

    static func sampleSnapshot() -> IncomeSnapshot {
        let planned = 2400.0
        let actual = 1500.0
        return IncomeSnapshot(
            actualIncome: actual,
            plannedIncome: planned,
            percentReceived: planned > 0 ? actual / planned : 0,
            rangeLabel: "This Month",
            updatedAt: Date()
        )
    }
}

struct IncomeWidgetEntry: TimelineEntry {
    let date: Date
    let snapshot: IncomeWidgetStore.IncomeSnapshot?
    let period: WidgetPeriod
}

@available(iOS 17.0, *)
struct IncomeWidgetIntentProvider: AppIntentTimelineProvider {
    typealias Intent = IncomeWidgetConfigurationIntent
    typealias Entry = IncomeWidgetEntry

    func placeholder(in context: Context) -> IncomeWidgetEntry {
        IncomeWidgetEntry(date: Date(), snapshot: IncomeWidgetStore.sampleSnapshot(), period: IncomeWidgetStore.defaultPeriodValue())
    }

    func snapshot(for configuration: IncomeWidgetConfigurationIntent, in context: Context) async -> IncomeWidgetEntry {
        let period = configuration.period ?? IncomeWidgetStore.defaultPeriodValue()
        let snapshot = resolveSnapshot(for: period) ?? IncomeWidgetStore.sampleSnapshot()
        return IncomeWidgetEntry(date: Date(), snapshot: snapshot, period: period)
    }

    func timeline(for configuration: IncomeWidgetConfigurationIntent, in context: Context) async -> Timeline<IncomeWidgetEntry> {
        let period = configuration.period ?? IncomeWidgetStore.defaultPeriodValue()
        let entry = IncomeWidgetEntry(date: Date(), snapshot: resolveSnapshot(for: period), period: period)
        return Timeline(entries: [entry], policy: .after(Date().addingTimeInterval(60 * 30)))
    }

    private func resolveSnapshot(for period: WidgetPeriod) -> IncomeWidgetStore.IncomeSnapshot? {
        return IncomeWidgetStore.readSnapshot(periodRaw: period.rawValue)
    }
}

@available(iOS 17.0, *)
struct IncomeWidgetConfigurationIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "Income Widget Settings"

    @Parameter(title: "Period")
    var period: WidgetPeriod?

    init() {
        self.period = IncomeWidgetStore.defaultPeriodValue()
    }
}

struct IncomeWidgetView: View {
    let entry: IncomeWidgetEntry

    @Environment(\.widgetFamily) private var family

    var body: some View {
        let resolvedSnapshot = entry.snapshot ?? IncomeWidgetStore.readSnapshot(periodRaw: entry.period.rawValue)
        let actual = resolvedSnapshot?.actualIncome ?? 0
        let planned = resolvedSnapshot?.plannedIncome ?? 0
        let percent = resolvedSnapshot?.percentReceived ?? 0
        let range = resolvedSnapshot?.rangeLabel ?? ""

        let content = VStack(alignment: .leading, spacing: 8) {
            Text("Income")
                .font(.headline)
            if family != .systemSmall, !range.isEmpty {
                Text(range)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            if family == .systemSmall {
                Text(String(format: "%.0f%%", percent * 100))
                    .font(.headline)
                ProgressView(value: percent)
                    .tint(Color(red: 0.23, green: 0.55, blue: 0.95))
                HStack {
                    Spacer()
                    Text("received")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.secondary)
                }
            } else {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Actual")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(actual, format: .currency(code: currencyCode))
                            .font(.headline)
                    }
                    Spacer()
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Planned")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(planned, format: .currency(code: currencyCode))
                            .font(.headline)
                    }
                }
                ProgressView(value: percent)
                    .tint(Color(red: 0.23, green: 0.55, blue: 0.95))
                Text(String(format: "%.0f%% received", percent * 100))
                    .font(.caption2.weight(.semibold))
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

    private var currencyCode: String {
        if #available(iOS 16.0, *) {
            return Locale.current.currency?.identifier ?? "USD"
        }
        return "USD"
    }
}

@available(iOS 17.0, *)
struct IncomeWidget: Widget {
    static let kind = "com.mb.offshore.income.widget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: Self.kind, intent: IncomeWidgetConfigurationIntent.self, provider: IncomeWidgetIntentProvider()) { entry in
            IncomeWidgetView(entry: entry)
        }
        .configurationDisplayName("Income")
        .description("Shows received vs planned income for the period.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

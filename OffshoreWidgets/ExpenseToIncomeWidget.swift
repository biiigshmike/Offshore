import WidgetKit
import SwiftUI
import AppIntents

enum ExpenseToIncomeWidgetStore {
    static let appGroupID = "group.com.mb.offshore-budgeting"
    static let snapshotKeyPrefix = "widget.expenseToIncome.snapshot."
    static let defaultPeriodKey = "widget.expenseToIncome.defaultPeriod"

    struct Snapshot: Codable {
        let expenses: Double
        let actualIncome: Double
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
            expenses: 980.0,
            actualIncome: 2500.0,
            rangeLabel: "This Month",
            updatedAt: Date()
        )
    }
}

struct ExpenseToIncomeWidgetEntry: TimelineEntry {
    let date: Date
    let snapshot: ExpenseToIncomeWidgetStore.Snapshot?
    let period: WidgetPeriod
}

@available(iOS 17.0, *)
struct ExpenseToIncomeWidgetIntentProvider: AppIntentTimelineProvider {
    typealias Intent = ExpenseToIncomeWidgetConfigurationIntent
    typealias Entry = ExpenseToIncomeWidgetEntry

    func placeholder(in context: Context) -> ExpenseToIncomeWidgetEntry {
        ExpenseToIncomeWidgetEntry(date: Date(), snapshot: ExpenseToIncomeWidgetStore.sampleSnapshot(), period: ExpenseToIncomeWidgetStore.defaultPeriodValue())
    }

    func snapshot(for configuration: ExpenseToIncomeWidgetConfigurationIntent, in context: Context) async -> ExpenseToIncomeWidgetEntry {
        let period = configuration.period ?? ExpenseToIncomeWidgetStore.defaultPeriodValue()
        let snapshot = resolveSnapshot(for: period) ?? ExpenseToIncomeWidgetStore.sampleSnapshot()
        return ExpenseToIncomeWidgetEntry(date: Date(), snapshot: snapshot, period: period)
    }

    func timeline(for configuration: ExpenseToIncomeWidgetConfigurationIntent, in context: Context) async -> Timeline<ExpenseToIncomeWidgetEntry> {
        let period = configuration.period ?? ExpenseToIncomeWidgetStore.defaultPeriodValue()
        let entry = ExpenseToIncomeWidgetEntry(date: Date(), snapshot: resolveSnapshot(for: period), period: period)
        return Timeline(entries: [entry], policy: .after(Date().addingTimeInterval(60 * 30)))
    }

    private func resolveSnapshot(for period: WidgetPeriod) -> ExpenseToIncomeWidgetStore.Snapshot? {
        return ExpenseToIncomeWidgetStore.readSnapshot(periodRaw: period.rawValue)
    }
}

@available(iOS 17.0, *)
struct ExpenseToIncomeWidgetConfigurationIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "Expense to Income Settings"

    @Parameter(title: "Period")
    var period: WidgetPeriod?

    init() {
        self.period = ExpenseToIncomeWidgetStore.defaultPeriodValue()
    }
}

struct ExpenseToIncomeWidgetView: View {
    let entry: ExpenseToIncomeWidgetEntry

    @Environment(\.widgetFamily) private var family

    var body: some View {
        let resolvedSnapshot = entry.snapshot ?? ExpenseToIncomeWidgetStore.readSnapshot(periodRaw: entry.period.rawValue)
        let expenses = resolvedSnapshot?.expenses ?? 0
        let actualIncome = resolvedSnapshot?.actualIncome ?? 0
        let range = resolvedSnapshot?.rangeLabel ?? ""

        let hasReceived = actualIncome > 0
        let receivedPercent = hasReceived ? (expenses / actualIncome) * 100 : nil
        let gaugeValue = hasReceived ? min(max((receivedPercent ?? 0) / 100, 0), 1) : (expenses > 0 ? 1 : 0)
        let overReceived = (receivedPercent ?? 0) > 100
        let tint: Color = overReceived ? .red : .green

        let content = VStack(alignment: .leading, spacing: 8) {
            Text("Expense to Income")
                .font(.headline)
                .lineLimit(2)
                .minimumScaleFactor(0.85)
            if family != .systemSmall, !range.isEmpty {
                Text(range)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            if family == .systemSmall {
                Text(hasReceived ? String(format: "%.0f%%", receivedPercent ?? 0) : "—")
                    .font(.headline)
                ProgressView(value: gaugeValue)
                    .tint(tint)
                HStack {
                    Spacer()
                    Text("spent")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.secondary)
                }
            } else {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Expenses")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(expenses, format: .currency(code: currencyCode))
                            .font(.headline)
                    }
                    Spacer()
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Actual Income")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(actualIncome, format: .currency(code: currencyCode))
                            .font(.headline)
                    }
                }
                ProgressView(value: gaugeValue)
                    .tint(tint)
                Text(hasReceived ? String(format: "%.0f%% spent", receivedPercent ?? 0) : "—")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(overReceived ? .red : .secondary)
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
struct ExpenseToIncomeWidget: Widget {
    static let kind = "com.mb.offshore.expenseToIncome.widget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: Self.kind, intent: ExpenseToIncomeWidgetConfigurationIntent.self, provider: ExpenseToIncomeWidgetIntentProvider()) { entry in
            ExpenseToIncomeWidgetView(entry: entry)
        }
        .configurationDisplayName("Expense to Income")
        .description("Shows expenses versus received income for the period.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

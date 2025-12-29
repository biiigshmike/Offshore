import WidgetKit
import SwiftUI
import AppIntents

enum CardWidgetStore {
    static let appGroupID = "group.com.mb.offshore-budgeting"
    static let snapshotKeyPrefix = "widget.card.snapshot."
    static let defaultPeriodKey = "widget.card.defaultPeriod"
    static let cardsKey = "widget.card.cards"

    struct CardSnapshot: Codable {
        struct Transaction: Codable {
            let name: String
            let amount: Double
            let date: Date
            let hexColor: String?
        }

        let cardID: String
        let cardName: String
        let cardThemeName: String?
        let cardPrimaryHex: String?
        let cardSecondaryHex: String?
        let cardPattern: String?
        let totalSpent: Double
        let recentTransactions: [Transaction]
        let topTransactions: [Transaction]
        let rangeLabel: String
        let updatedAt: Date
    }

    struct CardEntry: Codable, Hashable {
        let id: String
        let name: String
        let themeName: String?
        let primaryHex: String?
        let secondaryHex: String?
        let patternName: String?
    }

    static func readSnapshot(periodRaw: String, cardID: String) -> CardSnapshot? {
        guard let defaults = UserDefaults(suiteName: appGroupID) else { return nil }
        guard let data = defaults.data(forKey: snapshotKeyPrefix + periodRaw + "." + cardID) else { return nil }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try? decoder.decode(CardSnapshot.self, from: data)
    }

    static func readDefaultPeriod() -> WidgetPeriod {
        guard let defaults = UserDefaults(suiteName: appGroupID),
              let raw = defaults.string(forKey: defaultPeriodKey),
              let period = WidgetPeriod(rawValue: raw) else {
            return .monthly
        }
        return period
    }

    static func readCards() -> [CardEntry] {
        guard let defaults = UserDefaults(suiteName: appGroupID) else { return [] }
        guard let data = defaults.data(forKey: cardsKey) else { return [] }
        let decoder = JSONDecoder()
        return (try? decoder.decode([CardEntry].self, from: data)) ?? []
    }

    static func defaultCardID() -> String? {
        readCards().first?.id
    }

    static func sampleSnapshot() -> CardSnapshot {
        let sampleTransactions: [CardSnapshot.Transaction] = [
            .init(name: "Groceries", amount: 64.25, date: Date().addingTimeInterval(-3600 * 24 * 2), hexColor: "#6F9CFB"),
            .init(name: "Fuel", amount: 42.10, date: Date().addingTimeInterval(-3600 * 24 * 3), hexColor: "#56C8F5"),
            .init(name: "Dining", amount: 28.75, date: Date().addingTimeInterval(-3600 * 24 * 5), hexColor: "#F5A25D")
        ]
        return CardSnapshot(
            cardID: "sample-card",
            cardName: "Everyday Card",
            cardThemeName: nil,
            cardPrimaryHex: "#1C1C1E",
            cardSecondaryHex: "#2C2C2E",
            cardPattern: nil,
            totalSpent: 423.90,
            recentTransactions: sampleTransactions,
            topTransactions: sampleTransactions.sorted { $0.amount > $1.amount },
            rangeLabel: "This Month",
            updatedAt: Date()
        )
    }
}

@available(iOS 17.0, *)
struct CardWidgetEntry: TimelineEntry {
    let date: Date
    let snapshot: CardWidgetStore.CardSnapshot?
    let period: WidgetPeriod
    let cardID: String?
    let mode: CardWidgetListMode
}

@available(iOS 17.0, *)
enum CardWidgetListMode: String, CaseIterable, AppEnum {
    case recent
    case top

    static var typeDisplayRepresentation: TypeDisplayRepresentation = "View"

    static var caseDisplayRepresentations: [CardWidgetListMode: DisplayRepresentation] = [
        .recent: "Last 3 transactions",
        .top: "Top 3 expenses"
    ]
}

@available(iOS 17.0, *)
struct CardWidgetCard: AppEntity, Identifiable, Hashable {
    static var typeDisplayRepresentation: TypeDisplayRepresentation = "Card"
    static var defaultQuery = CardWidgetCardQuery()

    let id: String
    let name: String
    let primaryHex: String?
    let secondaryHex: String?

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(name)")
    }
}

@available(iOS 17.0, *)
struct CardWidgetCardQuery: EntityQuery {
    func entities(for identifiers: [String]) async throws -> [CardWidgetCard] {
        let cards = CardWidgetStore.readCards()
        let filtered = cards.filter { identifiers.contains($0.id) }
        return filtered.map {
            CardWidgetCard(
                id: $0.id,
                name: $0.name,
                primaryHex: $0.primaryHex,
                secondaryHex: $0.secondaryHex
            )
        }
    }

    func suggestedEntities() async throws -> [CardWidgetCard] {
        CardWidgetStore.readCards().map {
            CardWidgetCard(
                id: $0.id,
                name: $0.name,
                primaryHex: $0.primaryHex,
                secondaryHex: $0.secondaryHex
            )
        }
    }
}

@available(iOS 17.0, *)
struct CardWidgetIntentProvider: AppIntentTimelineProvider {
    typealias Intent = CardWidgetConfigurationIntent
    typealias Entry = CardWidgetEntry

    func placeholder(in context: Context) -> CardWidgetEntry {
        let sample = CardWidgetStore.sampleSnapshot()
        return CardWidgetEntry(
            date: Date(),
            snapshot: sample,
            period: CardWidgetStore.readDefaultPeriod(),
            cardID: sample.cardID,
            mode: .recent
        )
    }

    func snapshot(for configuration: CardWidgetConfigurationIntent, in context: Context) async -> CardWidgetEntry {
        let period = configuration.period ?? CardWidgetStore.readDefaultPeriod()
        let cardID = configuration.card?.id ?? CardWidgetStore.defaultCardID()
        let mode = configuration.mode ?? .recent
        let snapshot = cardID.flatMap { CardWidgetStore.readSnapshot(periodRaw: period.rawValue, cardID: $0) }
            ?? CardWidgetStore.sampleSnapshot()
        let resolvedCardID = cardID ?? snapshot.cardID
        return CardWidgetEntry(date: Date(), snapshot: snapshot, period: period, cardID: resolvedCardID, mode: mode)
    }

    func timeline(for configuration: CardWidgetConfigurationIntent, in context: Context) async -> Timeline<CardWidgetEntry> {
        let period = configuration.period ?? CardWidgetStore.readDefaultPeriod()
        let cardID = configuration.card?.id ?? CardWidgetStore.defaultCardID()
        let mode = configuration.mode ?? .recent
        let snapshot = cardID.flatMap { CardWidgetStore.readSnapshot(periodRaw: period.rawValue, cardID: $0) }
        let entry = CardWidgetEntry(date: Date(), snapshot: snapshot, period: period, cardID: cardID, mode: mode)
        return Timeline(entries: [entry], policy: .after(Date().addingTimeInterval(60 * 30)))
    }
}

@available(iOS 17.0, *)
struct CardWidgetConfigurationIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "Card Widget Settings"

    @Parameter(title: "Period")
    var period: WidgetPeriod?

    @Parameter(title: "Card")
    var card: CardWidgetCard?

    @Parameter(title: "View")
    var mode: CardWidgetListMode?

    init() {
        self.period = CardWidgetStore.readDefaultPeriod()
        self.card = nil
        self.mode = .recent
    }
}

@available(iOS 17.0, *)
struct CardWidgetView: View {
    let entry: CardWidgetEntry

    @Environment(\.widgetFamily) private var family

    var body: some View {
        let snapshot = entry.snapshot
        let cardID = entry.cardID
        let cardEntry = CardWidgetStore.readCards().first { $0.id == cardID }
        let cardName = snapshot?.cardName ?? cardEntry?.name ?? ""
        let primaryHex = snapshot?.cardPrimaryHex ?? cardEntry?.primaryHex
        let secondaryHex = snapshot?.cardSecondaryHex ?? cardEntry?.secondaryHex
        let totalSpent = snapshot?.totalSpent ?? 0
        let transactions: [CardWidgetStore.CardSnapshot.Transaction] = {
            guard let snapshot else { return [] }
            switch entry.mode {
            case .recent: return snapshot.recentTransactions
            case .top: return snapshot.topTransactions
            }
        }()

        let content = Group {
            if cardID == nil {
                Text("No cards yet.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
                    .padding()
            } else {
                switch family {
                case .systemSmall:
                    smallLayout(cardName: cardName, primaryHex: primaryHex, secondaryHex: secondaryHex, totalSpent: totalSpent)
                case .systemMedium:
                    mediumLayout(cardName: cardName, primaryHex: primaryHex, secondaryHex: secondaryHex, transactions: transactions)
                default:
                    largeLayout(cardName: cardName, primaryHex: primaryHex, secondaryHex: secondaryHex, transactions: transactions)
                }
            }
        }

        if #available(iOS 17.0, *) {
            content
                .containerBackground(.fill.tertiary, for: .widget)
        } else {
            content
        }
    }

    private func smallLayout(cardName: String, primaryHex: String?, secondaryHex: String?, totalSpent: Double) -> some View {
        VStack(spacing: 8) {
            CardPreview(cardName: cardName, primaryHex: primaryHex, secondaryHex: secondaryHex)
                .aspectRatio(1.6, contentMode: .fit)
                .scaleEffect(1.15)
                .padding(.bottom, 6)
            Text(formatCurrency(totalSpent))
                .font(.headline)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
    }

    private func mediumLayout(cardName: String, primaryHex: String?, secondaryHex: String?, transactions: [CardWidgetStore.CardSnapshot.Transaction]) -> some View {
        GeometryReader { proxy in
            let cardWidth = proxy.size.width * 0.46
            HStack(alignment: .top, spacing: 12) {
                CardPreview(cardName: cardName, primaryHex: primaryHex, secondaryHex: secondaryHex)
                    .frame(width: cardWidth, height: cardWidth / 1.6)
                transactionList(transactions)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .padding()
        }
    }

    private func largeLayout(cardName: String, primaryHex: String?, secondaryHex: String?, transactions: [CardWidgetStore.CardSnapshot.Transaction]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            CardPreview(cardName: cardName, primaryHex: primaryHex, secondaryHex: secondaryHex)
                .aspectRatio(1.6, contentMode: .fit)
                .frame(maxWidth: .infinity, alignment: .center)
            transactionList(transactions)
        }
        .padding()
    }

    private func transactionList(_ transactions: [CardWidgetStore.CardSnapshot.Transaction]) -> some View {
        if transactions.isEmpty {
            return AnyView(
                Text("No expenses to show for this selected period.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            )
        }
        return AnyView(
            VStack(alignment: .leading, spacing: 6) {
                ForEach(transactions.indices, id: \.self) { index in
                    transactionRow(transactions[index])
                }
            }
        )
    }

    private func transactionRow(_ transaction: CardWidgetStore.CardSnapshot.Transaction) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 6) {
            Circle()
                .fill(Color(hex: transaction.hexColor) ?? Color.secondary)
                .frame(width: 6, height: 6)
            VStack(alignment: .leading, spacing: 2) {
                Text(transaction.name)
                    .font(.caption)
                    .lineLimit(2)
                    .minimumScaleFactor(0.75)
                    .fixedSize(horizontal: false, vertical: true)
                Text(shortDate(transaction.date))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 6)
            Text(formatCurrency(transaction.amount))
                .font(.caption.weight(.semibold))
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
    }

    private func formatCurrency(_ value: Double) -> String {
        let code = Locale.current.currency?.identifier ?? "USD"
        return value.formatted(.currency(code: code))
    }

    private func shortDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: date)
    }
}

@available(iOS 17.0, *)
struct CardWidget: Widget {
    static let kind = "com.mb.offshore.card.widget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: Self.kind, intent: CardWidgetConfigurationIntent.self, provider: CardWidgetIntentProvider()) { entry in
            CardWidgetView(entry: entry)
        }
        .configurationDisplayName("Card")
        .description("Shows a card snapshot with recent or top transactions.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

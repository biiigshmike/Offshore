import WidgetKit
import SwiftUI
import AppIntents

enum CategoryAvailabilityWidgetStore {
    static let appGroupID = "group.com.mb.offshore-budgeting"
    private static let snapshotKeyPrefix = "widget.categoryAvailability.snapshot."
    private static let defaultPeriodKey = "widget.categoryAvailability.defaultPeriod"
    private static let defaultSegmentKey = "widget.categoryAvailability.defaultSegment"
    private static let defaultSortKey = "widget.categoryAvailability.defaultSort"
    private static let categoriesKey = "widget.categoryAvailability.categories"

    struct Snapshot: Codable {
        struct Item: Codable {
            let name: String
            let spent: Double
            let cap: Double?
            let available: Double
            let hexColor: String?
        }

        let items: [Item]
        let rangeLabel: String
        let updatedAt: Date
    }

    static func readSnapshot(periodRaw: String, segmentRaw: String) -> Snapshot? {
        guard let defaults = UserDefaults(suiteName: appGroupID) else { return nil }
        guard let data = defaults.data(forKey: snapshotKeyPrefix + periodRaw + "." + segmentRaw) else { return nil }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try? decoder.decode(Snapshot.self, from: data)
    }

    static func readDefaultPeriod() -> WidgetPeriod {
        guard let defaults = UserDefaults(suiteName: appGroupID),
              let raw = defaults.string(forKey: defaultPeriodKey),
              let period = WidgetPeriod(rawValue: raw) else {
            return .monthly
        }
        return period
    }

    static func readDefaultSegment() -> CategoryAvailabilityWidgetSegment {
        guard let defaults = UserDefaults(suiteName: appGroupID),
              let raw = defaults.string(forKey: defaultSegmentKey),
              let segment = CategoryAvailabilityWidgetSegment(rawValue: raw) else {
            return .combined
        }
        return segment
    }

    static func readDefaultSort() -> CategoryAvailabilityWidgetSort {
        guard let defaults = UserDefaults(suiteName: appGroupID),
              let raw = defaults.string(forKey: defaultSortKey),
              let sort = CategoryAvailabilityWidgetSort(rawValue: raw) else {
            return .alphabetical
        }
        return sort
    }

    static func readCategories() -> [String] {
        guard let defaults = UserDefaults(suiteName: appGroupID) else { return [] }
        return defaults.stringArray(forKey: categoriesKey) ?? []
    }

    static func sampleSnapshot() -> Snapshot {
        Snapshot(
            items: [
                .init(name: "Groceries", spent: 120, cap: 300, available: 180, hexColor: "#6F9CFB"),
                .init(name: "Dining", spent: 95, cap: 180, available: 85, hexColor: "#F5A25D"),
                .init(name: "Fuel", spent: 60, cap: 120, available: 60, hexColor: "#56C8F5")
            ],
            rangeLabel: "This Month",
            updatedAt: Date()
        )
    }
}

enum CategoryAvailabilityWidgetSegment: String, CaseIterable {
    case combined
    case planned
    case variable
}

@available(iOS 17.0, *)
extension CategoryAvailabilityWidgetSegment: AppEnum {
    static var typeDisplayRepresentation: TypeDisplayRepresentation = "Segment"
    static var caseDisplayRepresentations: [CategoryAvailabilityWidgetSegment: DisplayRepresentation] = [
        .combined: "All",
        .planned: "Planned",
        .variable: "Variable"
    ]
}

enum CategoryAvailabilityWidgetSort: String, CaseIterable {
    case alphabetical
    case highestSpent
    case lowestSpent
}

@available(iOS 17.0, *)
extension CategoryAvailabilityWidgetSort: AppEnum {
    static var typeDisplayRepresentation: TypeDisplayRepresentation = "Sort"
    static var caseDisplayRepresentations: [CategoryAvailabilityWidgetSort: DisplayRepresentation] = [
        .alphabetical: "Alphabetical",
        .highestSpent: "Highest Spending",
        .lowestSpent: "Lowest Spending"
    ]
}

@available(iOS 17.0, *)
struct CategoryAvailabilityWidgetCategory: AppEntity, Identifiable {
    var id: String { name }
    let name: String

    static var typeDisplayRepresentation: TypeDisplayRepresentation = "Category"
    static var defaultQuery = CategoryAvailabilityWidgetCategoryQuery()

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(name)")
    }
}

@available(iOS 17.0, *)
struct CategoryAvailabilityWidgetCategoryQuery: EntityQuery {
    func entities(for identifiers: [String]) async throws -> [CategoryAvailabilityWidgetCategory] {
        identifiers.map { CategoryAvailabilityWidgetCategory(name: $0) }
    }

    func suggestedEntities() async throws -> [CategoryAvailabilityWidgetCategory] {
        CategoryAvailabilityWidgetStore.readCategories().map { CategoryAvailabilityWidgetCategory(name: $0) }
    }
}

struct CategoryAvailabilityEntry: TimelineEntry {
    let date: Date
    let snapshot: CategoryAvailabilityWidgetStore.Snapshot?
    let period: WidgetPeriod
    let segment: CategoryAvailabilityWidgetSegment
    let sort: CategoryAvailabilityWidgetSort
    let selectedCategory: String?
}

@available(iOS 17.0, *)
struct CategoryAvailabilityWidgetIntentProvider: AppIntentTimelineProvider {
    typealias Intent = CategoryAvailabilityWidgetConfigurationIntent
    typealias Entry = CategoryAvailabilityEntry

    func placeholder(in context: Context) -> CategoryAvailabilityEntry {
        CategoryAvailabilityEntry(
            date: Date(),
            snapshot: CategoryAvailabilityWidgetStore.sampleSnapshot(),
            period: CategoryAvailabilityWidgetStore.readDefaultPeriod(),
            segment: CategoryAvailabilityWidgetStore.readDefaultSegment(),
            sort: CategoryAvailabilityWidgetStore.readDefaultSort(),
            selectedCategory: nil
        )
    }

    func snapshot(for configuration: CategoryAvailabilityWidgetConfigurationIntent, in context: Context) async -> CategoryAvailabilityEntry {
        let period = configuration.period ?? CategoryAvailabilityWidgetStore.readDefaultPeriod()
        let segment = configuration.segment ?? CategoryAvailabilityWidgetStore.readDefaultSegment()
        let sort = configuration.sort ?? CategoryAvailabilityWidgetStore.readDefaultSort()
        let snapshot = CategoryAvailabilityWidgetStore.readSnapshot(periodRaw: period.rawValue, segmentRaw: segment.rawValue)
            ?? CategoryAvailabilityWidgetStore.sampleSnapshot()
        return CategoryAvailabilityEntry(
            date: Date(),
            snapshot: snapshot,
            period: period,
            segment: segment,
            sort: sort,
            selectedCategory: nil
        )
    }

    func timeline(for configuration: CategoryAvailabilityWidgetConfigurationIntent, in context: Context) async -> Timeline<CategoryAvailabilityEntry> {
        let period = configuration.period ?? CategoryAvailabilityWidgetStore.readDefaultPeriod()
        let segment = configuration.segment ?? CategoryAvailabilityWidgetStore.readDefaultSegment()
        let sort = configuration.sort ?? CategoryAvailabilityWidgetStore.readDefaultSort()
        let snapshot = CategoryAvailabilityWidgetStore.readSnapshot(periodRaw: period.rawValue, segmentRaw: segment.rawValue)
        let entry = CategoryAvailabilityEntry(
            date: Date(),
            snapshot: snapshot,
            period: period,
            segment: segment,
            sort: sort,
            selectedCategory: nil
        )
        return Timeline(entries: [entry], policy: .after(Date().addingTimeInterval(60 * 30)))
    }
}

@available(iOS 17.0, *)
struct CategoryAvailabilityWidgetConfigurationIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "Category Availability Settings"

    @Parameter(title: "Period")
    var period: WidgetPeriod?

    @Parameter(title: "Segment")
    var segment: CategoryAvailabilityWidgetSegment?

    @Parameter(title: "Sort")
    var sort: CategoryAvailabilityWidgetSort?

    init() {
        self.period = CategoryAvailabilityWidgetStore.readDefaultPeriod()
        self.segment = CategoryAvailabilityWidgetStore.readDefaultSegment()
        self.sort = CategoryAvailabilityWidgetStore.readDefaultSort()
    }
}

@available(iOS 17.0, *)
struct CategoryAvailabilitySmallWidgetIntentProvider: AppIntentTimelineProvider {
    typealias Intent = CategoryAvailabilitySmallWidgetConfigurationIntent
    typealias Entry = CategoryAvailabilityEntry

    func placeholder(in context: Context) -> CategoryAvailabilityEntry {
        CategoryAvailabilityEntry(
            date: Date(),
            snapshot: nil,
            period: CategoryAvailabilityWidgetStore.readDefaultPeriod(),
            segment: CategoryAvailabilityWidgetStore.readDefaultSegment(),
            sort: CategoryAvailabilityWidgetStore.readDefaultSort(),
            selectedCategory: nil
        )
    }

    func snapshot(for configuration: CategoryAvailabilitySmallWidgetConfigurationIntent, in context: Context) async -> CategoryAvailabilityEntry {
        let period = configuration.period ?? CategoryAvailabilityWidgetStore.readDefaultPeriod()
        let segment = configuration.segment ?? CategoryAvailabilityWidgetStore.readDefaultSegment()
        let sort = configuration.sort ?? CategoryAvailabilityWidgetStore.readDefaultSort()
        let snapshot = CategoryAvailabilityWidgetStore.readSnapshot(periodRaw: period.rawValue, segmentRaw: segment.rawValue)
        return CategoryAvailabilityEntry(
            date: Date(),
            snapshot: snapshot,
            period: period,
            segment: segment,
            sort: sort,
            selectedCategory: configuration.category?.name
        )
    }

    func timeline(for configuration: CategoryAvailabilitySmallWidgetConfigurationIntent, in context: Context) async -> Timeline<CategoryAvailabilityEntry> {
        let period = configuration.period ?? CategoryAvailabilityWidgetStore.readDefaultPeriod()
        let segment = configuration.segment ?? CategoryAvailabilityWidgetStore.readDefaultSegment()
        let sort = configuration.sort ?? CategoryAvailabilityWidgetStore.readDefaultSort()
        let snapshot = CategoryAvailabilityWidgetStore.readSnapshot(periodRaw: period.rawValue, segmentRaw: segment.rawValue)
        let entry = CategoryAvailabilityEntry(
            date: Date(),
            snapshot: snapshot,
            period: period,
            segment: segment,
            sort: sort,
            selectedCategory: configuration.category?.name
        )
        return Timeline(entries: [entry], policy: .after(Date().addingTimeInterval(60 * 30)))
    }
}

@available(iOS 17.0, *)
struct CategoryAvailabilitySmallWidgetConfigurationIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "Category Availability (Small)"

    @Parameter(title: "Period")
    var period: WidgetPeriod?

    @Parameter(title: "Segment")
    var segment: CategoryAvailabilityWidgetSegment?

    @Parameter(title: "Sort")
    var sort: CategoryAvailabilityWidgetSort?

    @Parameter(title: "Category")
    var category: CategoryAvailabilityWidgetCategory?

    init() {
        self.period = CategoryAvailabilityWidgetStore.readDefaultPeriod()
        self.segment = CategoryAvailabilityWidgetStore.readDefaultSegment()
        self.sort = CategoryAvailabilityWidgetStore.readDefaultSort()
        self.category = nil
    }
}

struct CategoryAvailabilityWidgetView: View {
    let entry: CategoryAvailabilityEntry

    @Environment(\.widgetFamily) private var family

    var body: some View {
        let snapshot = entry.snapshot
        let range = snapshot?.rangeLabel ?? ""
        let items = sortedItems(snapshot?.items ?? [], sort: entry.sort)

        let content = VStack(alignment: .leading, spacing: 8) {
            Text("Category Availability")
                .font(.headline)
                .lineLimit(2)
                .minimumScaleFactor(0.85)

            if family == .systemLarge, !range.isEmpty {
                Text(range)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if items.isEmpty {
                Text("No categories yet.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                switch family {
                case .systemSmall:
                    smallCategoryView(items: items, selected: entry.selectedCategory)
                case .systemMedium:
                    mediumCategoryView(items: items)
                default:
                    largeCategoryView(items: items)
                }
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

    private func sortedItems(_ items: [CategoryAvailabilityWidgetStore.Snapshot.Item], sort: CategoryAvailabilityWidgetSort) -> [CategoryAvailabilityWidgetStore.Snapshot.Item] {
        switch sort {
        case .alphabetical:
            return items.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        case .highestSpent:
            return items.sorted {
                if $0.spent == $1.spent { return $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
                return $0.spent > $1.spent
            }
        case .lowestSpent:
            return items.sorted {
                if $0.spent == $1.spent { return $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
                return $0.spent < $1.spent
            }
        }
    }

    private func smallCategoryView(items: [CategoryAvailabilityWidgetStore.Snapshot.Item], selected: String?) -> some View {
        let item = items.first { $0.name == selected } ?? items.first
        return VStack(alignment: .leading, spacing: 8) {
            if let item {
                let availableValue = item.cap != nil ? max((item.cap ?? 0) - item.spent, 0) : item.available
                HStack(spacing: 6) {
                    Circle()
                        .fill(Color(hex: item.hexColor) ?? Color.accentColor)
                        .frame(width: 8, height: 8)
                    Text(item.name)
                        .font(.caption.weight(.semibold))
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
                if let cap = item.cap, cap > 0 {
                    ProgressView(value: min(item.spent / max(cap, 1), 1))
                        .tint(Color(hex: item.hexColor) ?? Color.accentColor)
                } else {
                    Rectangle()
                        .fill(Color(hex: item.hexColor)?.opacity(0.6) ?? Color.accentColor.opacity(0.6))
                        .frame(height: 4)
                        .clipShape(RoundedRectangle(cornerRadius: 2, style: .continuous))
                }
                Text("Spent \(formatCurrency(item.spent))")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Text("Available \(formatCurrency(availableValue))")
                    .font(.caption2)
                    .foregroundStyle(availableValue < 0 ? Color.red : .secondary)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private func mediumCategoryView(items: [CategoryAvailabilityWidgetStore.Snapshot.Item]) -> some View {
        let showMore = items.count > 4
        let topItems = Array(items.prefix(4))
        let left = Array(topItems.prefix(2))
        let right = Array(topItems.dropFirst(2))
        let remaining = max(items.count - 4, 0)
        return VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(left.indices, id: \.self) { index in
                        availabilityListItem(.item(left[index]), layout: .medium)
                    }
                }
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(right.indices, id: \.self) { index in
                        availabilityListItem(.item(right[index]), layout: .medium)
                    }
                }
            }
            if showMore {
                availabilityListItem(.more(remaining), layout: .medium)
                    .frame(maxWidth: .infinity, alignment: .center)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private func largeCategoryView(items: [CategoryAvailabilityWidgetStore.Snapshot.Item]) -> some View {
        let maxItems = 5
        let displayItems = limitedItems(items: items, maxItems: maxItems)
        return VStack(alignment: .leading, spacing: 6) {
            ForEach(displayItems.indices, id: \.self) { index in
                availabilityListItem(displayItems[index], layout: .large)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private func limitedItems(items: [CategoryAvailabilityWidgetStore.Snapshot.Item], maxItems: Int) -> [AvailabilityDisplayItem] {
        if items.count <= maxItems {
            return items.map { AvailabilityDisplayItem.item($0) }
        }
        let displayCount = maxItems - 1
        let remaining = items.count - displayCount
        let trimmed = items.prefix(displayCount).map { AvailabilityDisplayItem.item($0) }
        return trimmed + [AvailabilityDisplayItem.more(remaining)]
    }

    @ViewBuilder
    private func availabilityListItem(_ item: AvailabilityDisplayItem, layout: AvailabilityLayout) -> some View {
        switch item {
        case .more(let count):
            HStack(spacing: 8) {
                Circle()
                    .fill(Color.secondary.opacity(0.5))
                    .frame(width: 8, height: 8)
                Text("+\(count) more")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
            }
        case .item(let data):
            switch layout {
            case .medium:
                mediumCategoryRow(item: data)
            case .large:
                categoryRow(item: data, compact: false)
            }
        }
    }

    private func categoryRow(item: CategoryAvailabilityWidgetStore.Snapshot.Item, compact: Bool) -> some View {
        let availableValue = item.cap != nil ? max((item.cap ?? 0) - item.spent, 0) : item.available
        let nameFont: Font = compact ? .caption : .subheadline
        let detailFont: Font = compact ? .caption2 : .caption
        let gaugeWidth: CGFloat = compact ? 60 : 110
        return HStack(alignment: .center, spacing: 8) {
            Circle()
                .fill(Color(hex: item.hexColor) ?? Color.accentColor)
                .frame(width: 8, height: 8)
            VStack(alignment: .leading, spacing: 2) {
                Text(item.name)
                    .font(nameFont.weight(.semibold))
                    .lineLimit(1)
                Text("Max: \(formatCurrency(item.cap))")
                    .font(detailFont)
                    .foregroundStyle(.secondary)
                HStack(spacing: 2) {
                    Text("Available:")
                        .font(detailFont)
                        .foregroundStyle(.secondary)
                    Text(formatCurrency(availableValue))
                        .font(detailFont)
                        .foregroundStyle(availableValue < 0 ? Color.red : .primary)
                }
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 4) {
                Text("Spent \(formatCurrency(item.spent))")
                    .font(detailFont)
                    .foregroundStyle(.secondary)
                if let cap = item.cap, cap > 0 {
                    ProgressView(value: min(item.spent / max(cap, 1), 1))
                        .tint(Color(hex: item.hexColor) ?? Color.accentColor)
                        .frame(width: gaugeWidth)
                }
            }
        }
    }

    private func mediumCategoryRow(item: CategoryAvailabilityWidgetStore.Snapshot.Item) -> some View {
        let availableValue = item.cap != nil ? max((item.cap ?? 0) - item.spent, 0) : item.available
        return VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 6) {
                Circle()
                    .fill(Color(hex: item.hexColor) ?? Color.accentColor)
                    .frame(width: 8, height: 8)
                Text(item.name)
                    .font(.caption.weight(.semibold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            if let cap = item.cap, cap > 0 {
                ProgressView(value: min(item.spent / max(cap, 1), 1))
                    .tint(Color(hex: item.hexColor) ?? Color.accentColor)
            } else {
                Rectangle()
                    .fill(Color(hex: item.hexColor)?.opacity(0.6) ?? Color.accentColor.opacity(0.6))
                    .frame(height: 4)
                    .clipShape(RoundedRectangle(cornerRadius: 2, style: .continuous))
            }
            Text("Available: \(formatCurrency(availableValue))  Spent: \(formatCurrency(item.spent))")
                .font(.caption2)
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
    }

    private func formatCurrency(_ value: Double?) -> String {
        guard let value else { return "∞" }
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        if #available(iOS 16.0, *) {
            formatter.currencyCode = Locale.current.currency?.identifier ?? "USD"
        } else {
            formatter.currencyCode = Locale.current.currencyCode ?? "USD"
        }
        return formatter.string(from: value as NSNumber) ?? String(format: "%.2f", value)
    }
}

private enum AvailabilityLayout {
    case medium
    case large
}

private enum AvailabilityDisplayItem {
    case item(CategoryAvailabilityWidgetStore.Snapshot.Item)
    case more(Int)
}

@available(iOS 17.0, *)
struct CategoryAvailabilityWidget: Widget {
    static let kind = "com.mb.offshore.categoryAvailability.widget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: Self.kind, intent: CategoryAvailabilityWidgetConfigurationIntent.self, provider: CategoryAvailabilityWidgetIntentProvider()) { entry in
            CategoryAvailabilityWidgetView(entry: entry)
        }
        .configurationDisplayName("Category Availability")
        .description("Shows category caps and remaining availability.")
        .supportedFamilies([.systemMedium, .systemLarge])
    }
}

@available(iOS 17.0, *)
struct CategoryAvailabilitySmallWidget: Widget {
    static let kind = "com.mb.offshore.categoryAvailability.small.widget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: Self.kind, intent: CategoryAvailabilitySmallWidgetConfigurationIntent.self, provider: CategoryAvailabilitySmallWidgetIntentProvider()) { entry in
            CategoryAvailabilityWidgetView(entry: entry)
        }
        .configurationDisplayName("Category Availability")
        .description("Shows category caps and remaining availability.")
        .supportedFamilies([.systemSmall])
    }
}

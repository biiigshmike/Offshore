import WidgetKit
import SwiftUI
import AppIntents

enum CategorySpotlightWidgetStore {
    static let appGroupID = "group.com.mb.offshore-budgeting"
    static let categorySpotlightKeyPrefix = "widget.categorySpotlight.snapshot."
    static let categorySpotlightDefaultPeriodKey = "widget.categorySpotlight.defaultPeriod"

    struct CategorySpotlightSnapshot: Codable {
        struct CategoryItem: Codable {
            let name: String
            let amount: Double
            let hexColor: String?
        }

        let categories: [CategoryItem]
        let rangeLabel: String
        let updatedAt: Date
    }

    static func readSnapshot(periodRaw: String) -> CategorySpotlightSnapshot? {
        guard let defaults = UserDefaults(suiteName: appGroupID) else { return nil }
        guard let data = defaults.data(forKey: categorySpotlightKeyPrefix + periodRaw) else { return nil }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try? decoder.decode(CategorySpotlightSnapshot.self, from: data)
    }

    static func readDefaultPeriod() -> String? {
        guard let defaults = UserDefaults(suiteName: appGroupID) else { return nil }
        return defaults.string(forKey: categorySpotlightDefaultPeriodKey)
    }

    static func defaultPeriodValue() -> WidgetPeriod {
        guard let raw = readDefaultPeriod(),
              let period = WidgetPeriod(rawValue: raw) else {
            return .monthly
        }
        return period
    }
}

struct CategorySpotlightEntry: TimelineEntry {
    let date: Date
    let snapshot: CategorySpotlightWidgetStore.CategorySpotlightSnapshot?
    let period: WidgetPeriod
}

@available(iOS 17.0, *)
struct CategorySpotlightWidgetIntentProvider: AppIntentTimelineProvider {
    typealias Intent = CategorySpotlightWidgetConfigurationIntent
    typealias Entry = CategorySpotlightEntry

    func placeholder(in context: Context) -> CategorySpotlightEntry {
        CategorySpotlightEntry(date: Date(), snapshot: nil, period: CategorySpotlightWidgetStore.defaultPeriodValue())
    }

    func snapshot(for configuration: CategorySpotlightWidgetConfigurationIntent, in context: Context) async -> CategorySpotlightEntry {
        let period = configuration.period ?? CategorySpotlightWidgetStore.defaultPeriodValue()
        return CategorySpotlightEntry(date: Date(), snapshot: resolveSnapshot(for: period), period: period)
    }

    func timeline(for configuration: CategorySpotlightWidgetConfigurationIntent, in context: Context) async -> Timeline<CategorySpotlightEntry> {
        let period = configuration.period ?? CategorySpotlightWidgetStore.defaultPeriodValue()
        let entry = CategorySpotlightEntry(date: Date(), snapshot: resolveSnapshot(for: period), period: period)
        return Timeline(entries: [entry], policy: .after(Date().addingTimeInterval(60 * 30)))
    }

    private func resolveSnapshot(for period: WidgetPeriod) -> CategorySpotlightWidgetStore.CategorySpotlightSnapshot? {
        return CategorySpotlightWidgetStore.readSnapshot(periodRaw: period.rawValue)
    }
}

@available(iOS 17.0, *)
struct CategorySpotlightWidgetConfigurationIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "Category Spotlight Settings"

    @Parameter(title: "Period")
    var period: WidgetPeriod?

    init() {
        self.period = CategorySpotlightWidgetStore.defaultPeriodValue()
    }
}

struct CategorySpotlightWidgetView: View {
    let entry: CategorySpotlightEntry

    @Environment(\.widgetFamily) private var family

    var body: some View {
        let snapshot = entry.snapshot ?? CategorySpotlightWidgetStore.readSnapshot(periodRaw: entry.period.rawValue)
        let categories = (snapshot?.categories ?? [])
            .filter { $0.amount > 0 }
            .sorted { lhs, rhs in
                if lhs.amount == rhs.amount { return lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending }
                return lhs.amount > rhs.amount
            }
        let total = categories.map(\.amount).reduce(0, +)
        let range = snapshot?.rangeLabel ?? ""

        let content = VStack(alignment: .leading, spacing: 8) {
            Text("Category Spotlight")
                .font(family == .systemSmall ? .subheadline.weight(.semibold) : .headline)
                .lineLimit(family == .systemSmall ? 1 : 2)
                .minimumScaleFactor(family == .systemSmall ? 0.5 : 0.85)
                .frame(maxWidth: .infinity, alignment: .leading)
                .multilineTextAlignment(.leading)
            if family != .systemSmall, !range.isEmpty {
                Text(range)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if total <= 0 {
                Text("Add expenses to see category trends.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                switch family {
                case .systemSmall:
                    let topCategories = Array(categories.prefix(3))
                    let topTotal = topCategories.map(\.amount).reduce(0, +)
                    donutView(categories: topCategories, total: topTotal, size: 72, includeRemainder: false)
                        .padding(.top, 6)
                        .frame(maxWidth: .infinity, alignment: .center)
                case .systemMedium:
                    let topCategories = Array(categories.prefix(3))
                    let topTotal = topCategories.map(\.amount).reduce(0, +)
                    HStack(alignment: .center, spacing: 12) {
                        donutView(categories: topCategories, total: topTotal, size: 82, includeRemainder: false)
                        categoryList(categories: topCategories, total: total, font: .caption, maxCount: 3)
                    }
                    .padding(.top, 4)
                default:
                    VStack(alignment: .leading, spacing: 8) {
                        donutView(categories: categories, total: total, size: 132, includeRemainder: false)
                            .frame(maxWidth: .infinity, alignment: .center)
                        categoryList(categories: categories, total: total, font: .caption2, maxCount: 6)
                    }
                    .padding(.top, 10)
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)

        if #available(iOS 17.0, *) {
            content
                .containerBackground(.fill.tertiary, for: .widget)
        } else {
            content
        }
    }

    private func donutView(
        categories: [CategorySpotlightWidgetStore.CategorySpotlightSnapshot.CategoryItem],
        total: Double,
        size: CGFloat,
        includeRemainder: Bool
    ) -> some View {
        var slices = categories.compactMap { item -> DonutSlice? in
            guard let color = Color(hex: item.hexColor) else { return nil }
            return DonutSlice(amount: item.amount, color: color)
        }
        if includeRemainder {
            let topTotal = slices.map(\.amount).reduce(0, +)
            if total > topTotal {
                let remainder = total - topTotal
                slices.append(DonutSlice(amount: remainder, color: Color.primary.opacity(0.12)))
            }
        }
        return DonutChart(slices: slices, total: total, showBackground: false)
            .frame(width: size, height: size)
    }

    private func categoryList(
        categories: [CategorySpotlightWidgetStore.CategorySpotlightSnapshot.CategoryItem],
        total: Double,
        font: Font,
        maxCount: Int?
    ) -> some View {
        let displayCount = maxCount ?? categories.count
        let visible = Array(categories.prefix(displayCount))
        let remainingCount = max(categories.count - visible.count, 0)

        return VStack(alignment: .leading, spacing: 4) {
            ForEach(visible.indices, id: \.self) { index in
                let item = visible[index]
                let percent = total > 0 ? (item.amount / total) * 100 : 0
                HStack(spacing: 6) {
                    Circle()
                        .fill(Color(hex: item.hexColor) ?? .clear)
                        .frame(width: 6, height: 6)
                    Text(item.name)
                        .font(font)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                    Spacer(minLength: 0)
                    Text(String(format: "%.0f%%", percent))
                        .font(font.weight(.semibold))
                        .foregroundStyle(.secondary)
                }
            }
            if remainingCount > 0 {
                Text("+\(remainingCount) more")
                    .font(font.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

@available(iOS 17.0, *)
struct CategorySpotlightWidget: Widget {
    static let kind = "com.mb.offshore.categorySpotlight.widget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: Self.kind, intent: CategorySpotlightWidgetConfigurationIntent.self, provider: CategorySpotlightWidgetIntentProvider()) { entry in
            CategorySpotlightWidgetView(entry: entry)
        }
        .configurationDisplayName("Category Spotlight")
        .description("Highlights top spending categories for the period.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

private struct DonutSlice: Identifiable {
    let id = UUID()
    let amount: Double
    let color: Color
}

private struct DonutSegment: Identifiable {
    let id = UUID()
    let start: Double
    let end: Double
    let color: Color
}

private struct DonutChart: View {
    let slices: [DonutSlice]
    let total: Double
    let showBackground: Bool

    private var segments: [DonutSegment] {
        guard total > 0 else { return [] }
        var current = 0.0
        var result: [DonutSegment] = []
        for slice in slices {
            let start = current / total
            current += slice.amount
            let end = current / total
            result.append(DonutSegment(start: start, end: end, color: slice.color))
        }
        return result
    }

    var body: some View {
        GeometryReader { geo in
            let size = min(geo.size.width, geo.size.height)
            let lineWidth = max(size * 0.22, 10)
            ZStack {
                ForEach(segments) { segment in
                    Circle()
                        .trim(from: segment.start, to: segment.end)
                        .stroke(segment.color, style: StrokeStyle(lineWidth: lineWidth, lineCap: .butt))
                        .rotationEffect(.degrees(-90))
                }
            }
        }
    }
}

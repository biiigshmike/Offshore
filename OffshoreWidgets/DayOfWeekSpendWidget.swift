import WidgetKit
import SwiftUI
import AppIntents

enum DayOfWeekSpendWidgetStore {
    static let appGroupID = "group.com.mb.offshore-budgeting"
    static let dayOfWeekKeyPrefix = "widget.dayOfWeek.snapshot."
    static let dayOfWeekDefaultPeriodKey = "widget.dayOfWeek.defaultPeriod"

    struct DayOfWeekSnapshot: Codable {
        struct Bucket: Codable {
            let label: String
            let amount: Double
            let hexColors: [String]
        }

        let buckets: [Bucket]
        let rangeLabel: String
        let fallbackHexes: [String]
        let updatedAt: Date
    }

    static func readSnapshot(periodRaw: String) -> DayOfWeekSnapshot? {
        guard let defaults = UserDefaults(suiteName: appGroupID) else { return nil }
        guard let data = defaults.data(forKey: dayOfWeekKeyPrefix + periodRaw) else { return nil }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try? decoder.decode(DayOfWeekSnapshot.self, from: data)
    }

    static func readDefaultPeriod() -> String? {
        guard let defaults = UserDefaults(suiteName: appGroupID) else { return nil }
        return defaults.string(forKey: dayOfWeekDefaultPeriodKey)
    }

    static func defaultPeriodValue() -> WidgetPeriod {
        guard let raw = readDefaultPeriod(),
              let period = WidgetPeriod(rawValue: raw) else {
            return .monthly
        }
        return period
    }
}

struct DayOfWeekSpendEntry: TimelineEntry {
    let date: Date
    let snapshot: DayOfWeekSpendWidgetStore.DayOfWeekSnapshot?
    let period: WidgetPeriod
}

@available(iOS 17.0, *)
struct DayOfWeekSpendWidgetIntentProvider: AppIntentTimelineProvider {
    typealias Intent = DayOfWeekSpendWidgetConfigurationIntent
    typealias Entry = DayOfWeekSpendEntry

    func placeholder(in context: Context) -> DayOfWeekSpendEntry {
        DayOfWeekSpendEntry(date: Date(), snapshot: nil, period: DayOfWeekSpendWidgetStore.defaultPeriodValue())
    }

    func snapshot(for configuration: DayOfWeekSpendWidgetConfigurationIntent, in context: Context) async -> DayOfWeekSpendEntry {
        let period = configuration.period ?? DayOfWeekSpendWidgetStore.defaultPeriodValue()
        return DayOfWeekSpendEntry(date: Date(), snapshot: resolveSnapshot(for: period), period: period)
    }

    func timeline(for configuration: DayOfWeekSpendWidgetConfigurationIntent, in context: Context) async -> Timeline<DayOfWeekSpendEntry> {
        let period = configuration.period ?? DayOfWeekSpendWidgetStore.defaultPeriodValue()
        let entry = DayOfWeekSpendEntry(date: Date(), snapshot: resolveSnapshot(for: period), period: period)
        return Timeline(entries: [entry], policy: .after(Date().addingTimeInterval(60 * 30)))
    }

    private func resolveSnapshot(for period: WidgetPeriod) -> DayOfWeekSpendWidgetStore.DayOfWeekSnapshot? {
        DayOfWeekSpendWidgetStore.readSnapshot(periodRaw: period.rawValue)
    }
}

@available(iOS 17.0, *)
struct DayOfWeekSpendWidgetConfigurationIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "Day of Week Spend Settings"

    @Parameter(title: "Period")
    var period: WidgetPeriod?

    init() {
        self.period = DayOfWeekSpendWidgetStore.defaultPeriodValue()
    }
}

struct DayOfWeekSpendWidgetView: View {
    let entry: DayOfWeekSpendEntry

    @Environment(\.widgetFamily) private var family

    var body: some View {
        let effectivePeriod = resolvePeriod(entry.period, family: family)
        let snapshot = (entry.period == effectivePeriod ? entry.snapshot : nil)
            ?? DayOfWeekSpendWidgetStore.readSnapshot(periodRaw: effectivePeriod.rawValue)
        let buckets = adjustedBuckets(snapshot?.buckets ?? [])
        let range = snapshot?.rangeLabel ?? ""
        let fallbackHexes = snapshot?.fallbackHexes ?? []
        let maxAmount = max(buckets.map(\.amount).max() ?? 0, 1)
        let orientation = barOrientation(for: effectivePeriod, family: family, bucketCount: buckets.count)

        let content = VStack(alignment: .leading, spacing: 8) {
            Text("Day of Week Spend")
                .font(titleFont)
                .lineLimit(2)
                .minimumScaleFactor(0.9)

            if family != .systemSmall, !range.isEmpty {
                Text(range)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if buckets.isEmpty {
                Text("No spending yet.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                DayOfWeekBarChart(
                    buckets: buckets,
                    maxAmount: maxAmount,
                    fallbackHexes: fallbackHexes,
                    family: family,
                    orientation: orientation,
                    period: effectivePeriod
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
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

    private func barOrientation(for period: WidgetPeriod, family: WidgetFamily, bucketCount: Int) -> BarOrientation {
        if period == .daily && family == .systemSmall {
            return .vertical
        }
        if period == .quarterly && family != .systemLarge {
            return .horizontal
        }
        if period == .monthly && family != .systemLarge {
            return .horizontal
        }
        if period == .biWeekly && family != .systemSmall {
            return .horizontal
        }
        if family == .systemLarge && bucketCount <= 2 {
            return .horizontal
        }
        if family == .systemSmall && bucketCount <= 3 {
            return .horizontal
        }
        return .vertical
    }

    private func adjustedBuckets(_ buckets: [DayOfWeekSpendWidgetStore.DayOfWeekSnapshot.Bucket]) -> [DayOfWeekSpendWidgetStore.DayOfWeekSnapshot.Bucket] {
        return buckets
    }

    private var titleFont: Font {
        switch family {
        case .systemSmall:
            return .system(size: 13, weight: .semibold)
        case .systemMedium:
            return .system(size: 15, weight: .semibold)
        default:
            return .system(size: 16, weight: .semibold)
        }
    }

    private func resolvePeriod(_ period: WidgetPeriod, family: WidgetFamily) -> WidgetPeriod {
        if period == .daily && family != .systemSmall {
            return .weekly
        }
        return period
    }
}

@available(iOS 17.0, *)
struct DayOfWeekSpendWidget: Widget {
    static let kind = "com.mb.offshore.dayOfWeek.widget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: Self.kind, intent: DayOfWeekSpendWidgetConfigurationIntent.self, provider: DayOfWeekSpendWidgetIntentProvider()) { entry in
            DayOfWeekSpendWidgetView(entry: entry)
        }
        .configurationDisplayName("Day of Week Spend")
        .description("Shows spending by time period with category gradients.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

private struct DayOfWeekBarChart: View {
    let buckets: [DayOfWeekSpendWidgetStore.DayOfWeekSnapshot.Bucket]
    let maxAmount: Double
    let fallbackHexes: [String]
    let family: WidgetFamily
    let orientation: BarOrientation
    let period: WidgetPeriod

    var body: some View {
        GeometryReader { geo in
            let spacing: CGFloat = family == .systemSmall ? 4 : (family == .systemLarge ? 8 : 6)
            let count = max(buckets.count, 1)

            if period == .yearly {
                yearlyContent(geo: geo, spacing: spacing, count: count)
            } else if orientation == .horizontal {
                let rowHeight = max((geo.size.height - spacing * CGFloat(count - 1)) / CGFloat(count), 12)
                let labelWidth = labelWidthForHorizontal()
                let barMaxWidth = max(geo.size.width - labelWidth - 6, 20)
                VStack(alignment: .leading, spacing: spacing) {
                    ForEach(Array(buckets.enumerated()), id: \.offset) { index, bucket in
                        let norm = max(min(bucket.amount / maxAmount, 1), 0)
                        let colors = gradientColors(for: bucket, fallbackHexes: fallbackHexes)
                        let gradient = LinearGradient(
                            colors: colors.map { $0.opacity(0.4 + 0.5 * norm) },
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                        let showLabel = shouldShowLabel(index: index, count: count)
                        HStack(spacing: 6) {
                            if showLabel {
                                Text(labelText(for: bucket.label))
                                    .font(labelFont)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(1)
                                    .allowsTightening(false)
                                    .minimumScaleFactor(1)
                                    .frame(width: labelWidth, alignment: .leading)
                            } else {
                                Color.clear.frame(width: labelWidth, height: 1)
                            }
                            Rectangle()
                                .fill(gradient)
                                .frame(width: max(barMaxWidth * CGFloat(norm), 6), height: max(rowHeight - 6, 6))
                                .clipShape(RoundedRectangle(cornerRadius: 3, style: .continuous))
                        }
                        .frame(height: rowHeight)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            } else {
                let minBarWidth: CGFloat = family == .systemSmall ? 8 : (family == .systemLarge ? 14 : 10)
                let barWidth = max((geo.size.width - spacing * CGFloat(count - 1)) / CGFloat(count), minBarWidth)
                let labelHeight: CGFloat = family == .systemLarge ? 18 : 14
                let barAreaHeight = max(40, geo.size.height - labelHeight)

                HStack(alignment: .bottom, spacing: spacing) {
                    ForEach(Array(buckets.enumerated()), id: \.offset) { index, bucket in
                        let norm = max(min(bucket.amount / maxAmount, 1), 0)
                        let colors = gradientColors(for: bucket, fallbackHexes: fallbackHexes)
                        let gradient = LinearGradient(
                            colors: colors.map { $0.opacity(0.4 + 0.5 * norm) },
                            startPoint: .top,
                            endPoint: .bottom
                        )
                        let showLabel = shouldShowLabel(index: index, count: count)
                        VStack(spacing: 2) {
                            Rectangle()
                                .fill(gradient)
                                .frame(width: barWidth, height: max(CGFloat(norm) * (barAreaHeight - 8), 4))
                                .clipShape(RoundedRectangle(cornerRadius: 3, style: .continuous))
                            if showLabel {
                                Text(labelText(for: bucket.label))
                                    .font(labelFont)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(1)
                                    .allowsTightening(false)
                                    .minimumScaleFactor(1)
                                    .frame(width: barWidth, alignment: .center)
                            }
                        }
                        .frame(width: barWidth)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
            }
        }
    }

    private func gradientColors(for bucket: DayOfWeekSpendWidgetStore.DayOfWeekSnapshot.Bucket, fallbackHexes: [String]) -> [Color] {
        let maxColors: Int = {
            switch family {
            case .systemSmall: return 3
            case .systemMedium: return 4
            default: return 5
            }
        }()
        let colors = uniqueHexes(from: bucket.hexColors, maxCount: maxColors)
            .compactMap { Color(hex: $0) }
        if !colors.isEmpty {
            if colors.count == 1, let first = colors.first { return [first, first] }
            return blendTail(colors: colors, totalCount: bucket.hexColors.count, maxCount: maxColors)
        }
        let fallback = uniqueHexes(from: fallbackHexes, maxCount: maxColors)
            .compactMap { Color(hex: $0) }
        if !fallback.isEmpty {
            if fallback.count == 1, let first = fallback.first { return [first, first] }
            return blendTail(colors: fallback, totalCount: fallbackHexes.count, maxCount: maxColors)
        }
        return [Color.blue, Color.green]
    }

    private func shouldShowLabel(index: Int, count: Int) -> Bool {
        if family == .systemSmall && period == .weekly {
            return true
        }
        switch family {
        case .systemSmall:
            return count <= 6 || index % 2 == 0
        case .systemMedium:
            return count <= 8 || index % 2 == 0
        default:
            return true
        }
    }

    private func uniqueHexes(from hexes: [String], maxCount: Int) -> [String] {
        var seen = Set<String>()
        var result: [String] = []
        for hex in hexes where !hex.isEmpty {
            if seen.contains(hex) { continue }
            seen.insert(hex)
            result.append(hex)
            if result.count >= maxCount { break }
        }
        return result
    }

    private func blendTail(colors: [Color], totalCount: Int, maxCount: Int) -> [Color] {
        guard totalCount > maxCount, colors.count >= maxCount else { return colors }
        let head = Array(colors.prefix(maxCount - 1))
        let tail = colors.suffix(from: maxCount - 1)
        let blended = tail.reduce(Color.clear) { acc, next in
            if acc == .clear { return next }
            return acc.blend(with: next, fraction: 0.5)
        }
        return head + [blended]
    }

    private func labelText(for raw: String) -> String {
        if period == .yearly && family == .systemSmall {
            if let first = raw.first { return String(first) }
        }
        return raw
    }

    private var labelFont: Font {
        switch family {
        case .systemSmall:
            return .system(size: 10, weight: .regular)
        case .systemMedium:
            return .system(size: 11, weight: .regular)
        default:
            return .system(size: 12, weight: .regular)
        }
    }

    private func labelWidthForHorizontal() -> CGFloat {
        switch family {
        case .systemSmall:
            switch period {
            case .monthly:
                return 38
            case .quarterly:
                return 30
            case .yearly:
                return 18
            default:
                return 30
            }
        case .systemMedium:
            return period == .monthly ? 50 : 44
        default:
            return 52
        }
    }

    @ViewBuilder
    private func yearlyContent(geo: GeometryProxy, spacing: CGFloat, count: Int) -> some View {
        switch family {
        case .systemSmall:
            yearlyVerticalBars(geo: geo, spacing: spacing, buckets: yearlyBuckets(), showLabels: false, labelMode: .none)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
        case .systemMedium:
            yearlyMediumGrid(geo: geo, spacing: spacing, buckets: yearlyBuckets())
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        default:
            yearlyVerticalBars(geo: geo, spacing: spacing, buckets: yearlyBuckets(), showLabels: true, labelMode: .singleLetter)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
        }
    }

    private enum YearlyLabelMode {
        case none
        case singleLetter
    }

    @ViewBuilder
    private func yearlyVerticalBars(geo: GeometryProxy, spacing: CGFloat, buckets: [DayOfWeekSpendWidgetStore.DayOfWeekSnapshot.Bucket], showLabels: Bool, labelMode: YearlyLabelMode) -> some View {
        let count = max(buckets.count, 12)
        let minBarWidth: CGFloat = family == .systemSmall ? 7 : 10
        let barWidth = max((geo.size.width - spacing * CGFloat(count - 1)) / CGFloat(count), minBarWidth)
        let labelHeight: CGFloat = showLabels ? 14 : 0
        let barAreaHeight = max(40, geo.size.height - labelHeight)
        HStack(alignment: .bottom, spacing: spacing) {
            ForEach(Array(buckets.enumerated()), id: \.offset) { index, bucket in
                let norm = max(min(bucket.amount / maxAmount, 1), 0)
                let colors = gradientColors(for: bucket, fallbackHexes: fallbackHexes)
                let gradient = LinearGradient(
                    colors: colors.map { $0.opacity(0.4 + 0.5 * norm) },
                    startPoint: .top,
                    endPoint: .bottom
                )
                VStack(spacing: 2) {
                    Rectangle()
                        .fill(gradient)
                        .frame(width: barWidth, height: max(CGFloat(norm) * (barAreaHeight - 8), 4))
                        .clipShape(RoundedRectangle(cornerRadius: 3, style: .continuous))
                    if showLabels {
                        Text(yearlyLabel(for: index, mode: labelMode))
                            .font(labelFont)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                            .allowsTightening(false)
                            .minimumScaleFactor(1)
                            .frame(width: barWidth, alignment: .center)
                    }
                }
                .frame(width: barWidth)
            }
        }
    }

    private func yearlyMediumGrid(geo: GeometryProxy, spacing: CGFloat, buckets: [DayOfWeekSpendWidgetStore.DayOfWeekSnapshot.Bucket]) -> some View {
        let left = Array(buckets.prefix(6))
        let right = Array(buckets.dropFirst(6).prefix(6))
        let columnSpacing: CGFloat = 12
        let rowCount = 6
        let rowSpacing: CGFloat = family == .systemMedium ? 6 : spacing
        let columnWidth = max((geo.size.width - columnSpacing) / 2, 80)
        let rowHeight = max((geo.size.height - rowSpacing * CGFloat(rowCount - 1)) / CGFloat(rowCount) - 1, 10)
        return HStack(alignment: .top, spacing: columnSpacing) {
            yearlyMediumColumn(buckets: left, columnWidth: columnWidth, rowHeight: rowHeight, rowSpacing: rowSpacing)
                .frame(width: columnWidth, alignment: .leading)
            yearlyMediumColumn(buckets: right, columnWidth: columnWidth, rowHeight: rowHeight, rowSpacing: rowSpacing)
                .frame(width: columnWidth, alignment: .leading)
        }
    }

    private func yearlyMediumColumn(buckets: [DayOfWeekSpendWidgetStore.DayOfWeekSnapshot.Bucket], columnWidth: CGFloat, rowHeight: CGFloat, rowSpacing: CGFloat) -> some View {
        let labelWidth: CGFloat = 24
        let barMaxWidth = max(columnWidth - labelWidth - 6, 24)
        return VStack(alignment: .leading, spacing: rowSpacing) {
            ForEach(Array(buckets.enumerated()), id: \.offset) { _, bucket in
                let norm = max(min(bucket.amount / maxAmount, 1), 0)
                let colors = gradientColors(for: bucket, fallbackHexes: fallbackHexes)
                let gradient = LinearGradient(
                    colors: colors.map { $0.opacity(0.4 + 0.5 * norm) },
                    startPoint: .leading,
                    endPoint: .trailing
                )
                HStack(spacing: 6) {
                    Text(bucket.label)
                        .font(labelFont)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .allowsTightening(false)
                        .minimumScaleFactor(1)
                        .frame(width: labelWidth, alignment: .leading)
                    Rectangle()
                        .fill(gradient)
                        .frame(width: max(barMaxWidth * CGFloat(norm), 6), height: max(rowHeight - 4, 6))
                        .clipShape(RoundedRectangle(cornerRadius: 3, style: .continuous))
                }
                .frame(height: rowHeight)
            }
        }
    }

    private func yearlyLabel(for index: Int, mode: YearlyLabelMode) -> String {
        switch mode {
        case .none:
            return ""
        case .singleLetter:
            let letters = ["J", "F", "M", "A", "M", "J", "J", "A", "S", "O", "N", "D"]
            if index < letters.count { return letters[index] }
            return ""
        }
    }

    private func yearlyBuckets() -> [DayOfWeekSpendWidgetStore.DayOfWeekSnapshot.Bucket] {
        let monthLabels = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]
        let normalized = Dictionary(uniqueKeysWithValues: buckets.map { bucket in
            (bucket.label.lowercased(), bucket)
        })
        var padded: [DayOfWeekSpendWidgetStore.DayOfWeekSnapshot.Bucket] = []
        for index in 0..<12 {
            let label = monthLabels[index]
            if let match = normalized[label.lowercased()] {
                padded.append(match)
                continue
            }
            padded.append(.init(label: label, amount: 0, hexColors: []))
        }
        return padded
    }
}

private enum BarOrientation {
    case vertical
    case horizontal
}

private extension Color {
    func blend(with other: Color, fraction: Double) -> Color {
        let f = max(0, min(1, fraction))
        #if canImport(UIKit)
        let a = UIColor(self)
        let b = UIColor(other)
        var ar: CGFloat = 0
        var ag: CGFloat = 0
        var ab: CGFloat = 0
        var aa: CGFloat = 0
        var br: CGFloat = 0
        var bg: CGFloat = 0
        var bb: CGFloat = 0
        var ba: CGFloat = 0
        a.getRed(&ar, green: &ag, blue: &ab, alpha: &aa)
        b.getRed(&br, green: &bg, blue: &bb, alpha: &ba)
        return Color(
            .sRGB,
            red: Double(ar + (br - ar) * f),
            green: Double(ag + (bg - ag) * f),
            blue: Double(ab + (bb - ab) * f),
            opacity: Double(aa + (ba - aa) * f)
        )
        #else
        return self
        #endif
    }
}

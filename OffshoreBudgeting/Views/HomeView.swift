import SwiftUI
import Charts
import CoreData
import UniformTypeIdentifiers
#if canImport(UIKit)
import UIKit
#endif
#if os(macOS)
import AppKit
#endif

// MARK: - Shared Models
/// Generic spend bucket used across widget + detail charts.
private struct SpendBucket: Identifiable {
    let id = UUID()
    let label: String
    let start: Date
    let end: Date
    let amount: Double
    let categoryHexColors: [String]
    let categoryTotals: [CategorySpendKey: Double]
}

private enum SpendBarOrientation {
    case vertical
    case horizontal
}

/// Represents a chart section (e.g., a week or month) containing spend buckets.
private struct SpendChartSection: Identifiable {
    let id = UUID()
    let title: String
    let subtitle: String?
    let buckets: [SpendBucket]
}

private struct CategorySpendKey: Hashable {
    let name: String
    let hex: String
}

struct CapStatus: Identifiable {
    let id = UUID()
    let name: String
    let amount: Double
    let cap: Double
    let color: Color
    let near: Bool
    let over: Bool
    let segment: CategoryAvailabilitySegment
}

struct CategoryAvailability: Identifiable {
    let id = UUID()
    let name: String
    let spent: Double
    let cap: Double?
    let available: Double
    let color: Color
    let over: Bool
    let near: Bool
    var capDisplay: String { cap.map { CategoryAvailability.formatCurrencyStatic($0) } ?? "∞" }

    private static func formatCurrencyStatic(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        if #available(iOS 16.0, macCatalyst 16.0, *) {
            formatter.currencyCode = Locale.current.currency?.identifier ?? "USD"
        } else {
            formatter.currencyCode = Locale.current.currencyCode ?? "USD"
        }
        return formatter.string(from: value as NSNumber) ?? String(format: "%.2f", value)
    }
}

enum CategoryAvailabilitySegment: String, CaseIterable, Identifiable {
    case combined
    case planned
    case variable

    var id: String { rawValue }

    var title: String {
        switch self {
        case .combined: return "All"
        case .planned: return "Planned"
        case .variable: return "Variable"
        }
    }
}

// MARK: - Layout Helpers
private struct WidgetSpan: Equatable, Hashable {
    let width: Int
    let height: Int
}

private struct WidgetSpanKey: LayoutValueKey {
    static let defaultValue = WidgetSpan(width: 1, height: 1)
}

@available(iOS 16.0, macOS 13.0, macCatalyst 16.0, *)
private struct WidgetGridLayout: Layout {
    let columns: Int
    let spacing: CGFloat
    let rowHeight: CGFloat

    struct Cache {
        var frames: [CGRect] = []
        var size: CGSize = .zero
        var proposalWidth: CGFloat = 0
    }

    func makeCache(subviews: Subviews) -> Cache { Cache() }

    func updateCache(_ cache: inout Cache, for subviews: Subviews, proposal: ProposedViewSize) {
        cache = computeLayout(subviews: subviews, proposal: proposal)
    }

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout Cache) -> CGSize {
        if cache.frames.count != subviews.count || cache.proposalWidth != (proposal.width ?? 0) {
            cache = computeLayout(subviews: subviews, proposal: proposal)
        }
        return cache.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout Cache) {
        if cache.frames.count != subviews.count || cache.proposalWidth != (proposal.width ?? 0) {
            cache = computeLayout(subviews: subviews, proposal: proposal)
        }
        for (index, frame) in cache.frames.enumerated() where index < subviews.count {
            let origin = CGPoint(x: bounds.minX + frame.minX, y: bounds.minY + frame.minY)
            subviews[index].place(
                at: origin,
                proposal: ProposedViewSize(width: frame.width, height: frame.height)
            )
        }
    }

    private func computeLayout(subviews: Subviews, proposal: ProposedViewSize) -> Cache {
        let safeColumns = max(1, columns)
        let proposedWidth = proposal.width ?? 0
        #if canImport(UIKit)
        let fallbackWidth: CGFloat = UIScreen.main.bounds.width - 40
        #else
        let fallbackWidth: CGFloat = 1024
        #endif
        let containerWidth = max(320, proposedWidth > 0 ? proposedWidth : fallbackWidth)
        let totalSpacing = CGFloat(max(safeColumns - 1, 0)) * spacing
        let columnWidth = (containerWidth - totalSpacing) / CGFloat(safeColumns)

        var occupancy: [[Bool]] = []
        var frames: [CGRect] = []

        func firstFit(for spanWidth: Int) -> (row: Int, column: Int) {
            let width = min(max(spanWidth, 1), safeColumns)
            if occupancy.isEmpty {
                occupancy.append(Array(repeating: false, count: safeColumns))
            }
            var row = 0
            while true {
                if row >= occupancy.count {
                    occupancy.append(Array(repeating: false, count: safeColumns))
                }
                let rowSlots = occupancy[row]
                let limit = safeColumns - width
                if limit >= 0 {
                    for start in 0...limit {
                        let slice = rowSlots[start..<(start + width)]
                        if slice.allSatisfy({ !$0 }) {
                            return (row, start)
                        }
                    }
                }
                row += 1
            }
        }

        for subview in subviews {
            let span = subview[WidgetSpanKey.self]
            let spanWidth = min(max(span.width, 1), safeColumns)
            let spanHeight = max(span.height, 1)

            let position = firstFit(for: spanWidth)
            let row = position.row
            let column = position.column

            let neededRows = row + spanHeight
            if neededRows > occupancy.count {
                for _ in occupancy.count..<neededRows {
                    occupancy.append(Array(repeating: false, count: safeColumns))
                }
            }
            for r in row..<row + spanHeight {
                for c in column..<column + spanWidth {
                    occupancy[r][c] = true
                }
            }

            let x = CGFloat(column) * (columnWidth + spacing)
            let y = CGFloat(row) * (rowHeight + spacing)
            let width = columnWidth * CGFloat(spanWidth) + spacing * CGFloat(max(spanWidth - 1, 0))
            let height = rowHeight * CGFloat(spanHeight) + spacing * CGFloat(max(spanHeight - 1, 0))
            frames.append(CGRect(x: x, y: y, width: width, height: height))
        }

        let rows = occupancy.count
        let totalHeight = CGFloat(rows) * rowHeight + spacing * CGFloat(max(rows - 1, 0))
        let totalWidth = columnWidth * CGFloat(safeColumns) + spacing * CGFloat(max(safeColumns - 1, 0))
        return Cache(frames: frames, size: CGSize(width: totalWidth, height: totalHeight), proposalWidth: proposal.width ?? 0)
    }
}

// MARK: - HomeView – Widget Feed
struct HomeView: View {

    @StateObject private var vm = HomeViewModel()

    @State private var nextPlannedSnapshot: PlannedExpenseSnapshot?
    @State private var widgetBuckets: [SpendBucket] = []
    @State private var weekdayRangeOverride: ClosedRange<Date>? = nil
    @State private var capStatuses: [CapStatus] = []
    @State private var availabilityPage: Int = 0
    @State private var startDateSelection: Date = Date()
    @State private var endDateSelection: Date = Date()

    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.platformCapabilities) private var capabilities
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.colorSchemeContrast) private var colorSchemeContrast

    enum Sort: String, CaseIterable, Identifiable { case titleAZ, amountLowHigh, amountHighLow, dateOldNew, dateNewOld; var id: String { rawValue } }

    @AppStorage("homePinnedWidgetIDs") private var pinnedStorage: String = ""
    @AppStorage("homeWidgetOrderIDs") private var orderStorage: String = ""
    @AppStorage("homeAvailabilitySegment") private var availabilitySegmentRawValue: String = CategoryAvailabilitySegment.combined.rawValue
    @AppStorage("homeScenarioAllocations") private var scenarioAllocationsRaw: String = ""
    @AppStorage(AppSettingsKeys.enableCloudSync.rawValue) private var enableCloudSync: Bool = false
    @AppStorage(AppSettingsKeys.syncHomeWidgetsAcrossDevices.rawValue) private var syncHomeWidgetsAcrossDevices: Bool = false

    private static let defaultWidgets: [WidgetID] = [
        .income, .expenseToIncome, .savings, .nextPlanned, .categorySpotlight, .dayOfWeek, .availability, .scenario
    ]

    private enum WidgetStorageKey {
        static let pinnedLocal = "homePinnedWidgetIDs"
        static let pinnedCloud = "homePinnedWidgetIDs.cloud"
        static let orderLocal = "homeWidgetOrderIDs"
        static let orderCloud = "homeWidgetOrderIDs.cloud"
    }

    @State private var pinnedIDs: [WidgetID] = []
    @State private var widgetOrder: [WidgetID] = []
    @State private var isEditing: Bool = false
    @State private var draggingID: WidgetID?
    @State private var ubiquitousObserver: NSObjectProtocol?
    @State private var storageRefreshToken = UUID()

    @ScaledMetric(relativeTo: .body) private var gridSpacing: CGFloat = 18
    @ScaledMetric(relativeTo: .body) private var gridRowHeight: CGFloat = 170
    @ScaledMetric(relativeTo: .body) private var availabilityRowHeight: CGFloat = 64
    @ScaledMetric(relativeTo: .body) private var availabilityRowSpacing: CGFloat = 8
    @ScaledMetric(relativeTo: .body) private var availabilityTabPadding: CGFloat = 12
    @ScaledMetric(relativeTo: .body) private var availabilityStatusDotSize: CGFloat = 12
    @ScaledMetric(relativeTo: .body) private var categorySpotlightHeight: CGFloat = 200
    @ScaledMetric(relativeTo: .body) private var dayOfWeekChartHeight: CGFloat = 140
    @ScaledMetric(relativeTo: .body) private var dayOfWeekRowHeight: CGFloat = 24
    @ScaledMetric(relativeTo: .body) private var dayOfWeekRowSpacing: CGFloat = 8
    @ScaledMetric(relativeTo: .body) private var dateActionButtonSize: CGFloat = 44
    @ScaledMetric(relativeTo: .body) private var cardWidgetMaxWidth: CGFloat = 360
    @ScaledMetric(relativeTo: .body) private var cardPreviewWidth: CGFloat = 120
    @ScaledMetric(relativeTo: .body) private var cardPreviewHeight: CGFloat = 76

    private var isCompactDateRow: Bool {
        horizontalSizeClass == .compact
    }

    private var isHighContrast: Bool {
        colorSchemeContrast == .increased
    }

    private var isLargeText: Bool {
        dynamicTypeSize >= .xxxLarge
    }

    private var isAccessibilitySize: Bool {
        isLargeText || dynamicTypeSize.isAccessibilitySize
    }

    private var shouldSyncWidgets: Bool {
        enableCloudSync && syncHomeWidgetsAcrossDevices
    }

    private var columnCount: Int {
        #if os(macOS)
        return 4
        #else
        #if os(iOS)
        if UIDevice.current.userInterfaceIdiom == .phone {
            return 1
        }
        #endif
        if horizontalSizeClass == .compact {
            return 1
        } else {
            return 3
        }
        #endif
    }
    private var availabilitySegment: CategoryAvailabilitySegment {
        CategoryAvailabilitySegment(rawValue: availabilitySegmentRawValue) ?? .combined
    }
    private var availabilitySegmentBinding: Binding<CategoryAvailabilitySegment> {
        Binding(
            get: { availabilitySegment },
            set: { availabilitySegmentRawValue = $0.rawValue }
        )
    }
    private var scenarioAllocations: [String: Double] {
        decodeScenarioAllocations(from: scenarioAllocationsRaw)
    }
    private func decodeScenarioAllocations(from raw: String) -> [String: Double] {
        guard !raw.isEmpty else { return [:] }
        var result: [String: Double] = [:]
        for pair in raw.split(separator: "&") {
            let parts = pair.split(separator: "=", maxSplits: 1)
            guard parts.count == 2 else { continue }
            let key = String(parts[0]).removingPercentEncoding ?? String(parts[0])
            let value = Double(parts[1]) ?? 0
            result[key] = value
        }
        return result
    }
    @State private var cardWidgets: [CardItem] = []

    enum HomePalette {
        static let budgets = Color(red: 0.15, green: 0.68, blue: 0.45)
        static let income  = Color(red: 0.23, green: 0.55, blue: 0.95)
        static let presets = Color(red: 0.59, green: 0.45, blue: 0.96)
        static let cards   = Color(red: 0.97, green: 0.62, blue: 0.25)
    }

    enum HomeWidgetKind: Hashable {
        case budgets, income, presets, cards
        case dayOfWeek, caps, availability, scenario
        case expenseToIncome, savingsOutlook

        var baseTitleColor: Color {
            switch self {
            case .budgets: return HomePalette.budgets
            case .income:  return HomePalette.income
            case .presets: return HomePalette.presets
            case .cards:   return HomePalette.cards
            case .dayOfWeek: return HomePalette.presets
            case .caps: return HomePalette.presets
            case .availability: return HomePalette.presets
            case .scenario: return HomePalette.income
            case .expenseToIncome: return HomePalette.budgets
            case .savingsOutlook: return HomePalette.budgets
            }
        }

        var highContrastTitleColor: Color {
            return .primary
        }
    }

    private struct HomeMetricRoute: Hashable {
        let budgetID: NSManagedObjectID
        let title: String
        let kind: HomeWidgetKind
    }

    private struct NextPlannedRoute: Hashable {
        let budgetID: NSManagedObjectID
    }

    private enum WidgetID: Hashable {
        case income
        case expenseToIncome
        case savings
        case nextPlanned
        case categorySpotlight
        case dayOfWeek
        case caps
        case availability
        case scenario
        case card(String)

        var storageKey: String {
            switch self {
            case .income: return "income"
            case .expenseToIncome: return "expenseToIncome"
            case .savings: return "savings"
            case .nextPlanned: return "nextPlanned"
            case .categorySpotlight: return "categorySpotlight"
            case .dayOfWeek: return "dayOfWeek"
            case .caps: return "caps"
            case .availability: return "availability"
            case .scenario: return "scenario"
            case .card(let uri): return "card:\(uri)"
            }
        }

        static func fromStorage(_ raw: String) -> WidgetID? {
            switch raw {
            case "income": return .income
            case "expenseToIncome": return .expenseToIncome
            case "savings": return .savings
            case "nextPlanned": return .nextPlanned
            case "categorySpotlight": return .categorySpotlight
            case "dayOfWeek": return .dayOfWeek
            case "caps": return .caps
            case "availability": return .availability
            case "scenario": return .scenario
            default:
                if raw.hasPrefix("card:") {
                    let suffix = String(raw.dropFirst("card:".count))
                    return .card(suffix)
                }
                return nil
            }
        }
    }

    private struct WidgetItem: Identifiable, Hashable {
        let id: WidgetID
        let span: WidgetSpan
        let view: AnyView
        let title: String
        let kind: HomeWidgetKind

        static func == (lhs: WidgetItem, rhs: WidgetItem) -> Bool {
            lhs.id == rhs.id
        }

        func hash(into hasher: inout Hasher) {
            hasher.combine(id.storageKey)
        }
    }

    private var whatsNewVersionToken: String? {
        let info = Bundle.main.infoDictionary
        let version = info?["CFBundleShortVersionString"] as? String
        let build = info?["CFBundleVersion"] as? String
        guard let version, !version.isEmpty, let build, !build.isEmpty else { return nil }
        return "\(version).\(build)"
    }

    var body: some View {
        ZStack(alignment: .top) {
            heatmapBackground
                .ignoresSafeArea()

            listContent
        }
        .navigationTitle("Home")
        .refreshable { await vm.refresh() }
        .task { await onAppearTask() }
        .onChange(of: vm.period) { _ in syncPickers(with: vm.currentDateRange) }
        .onChange(of: vm.selectedDate) { _ in syncPickers(with: vm.currentDateRange) }
        .onReceive(vm.$customDateRange) { _ in syncPickers(with: vm.currentDateRange) }
        .onChange(of: vm.state) { _ in Task { await stateDidChange() } }
        .onChange(of: shouldSyncWidgets) { _ in handleWidgetSyncPreferenceChange() }
        .onReceive(NotificationCenter.default.publisher(for: .NSManagedObjectContextDidSave, object: CoreDataService.shared.viewContext)) { _ in
            switch vm.state {
            case .loaded, .empty:
                Task { await loadAllCards() }
            case .initial, .loading:
                break
            }
        }
        .onDisappear { stopObservingWidgetSync() }
        .alert(item: $vm.alert, content: alert(for:))
        .navigationDestination(for: HomeMetricRoute.self) { route in
            if let summary = summaries.first(where: { $0.id == route.budgetID }) {
                let topCategory = summary.categoryBreakdown.first ?? summary.plannedCategoryBreakdown.first ?? summary.categoryBreakdown.first
                MetricDetailView(
                    title: route.title,
                    kind: route.kind,
                    range: currentRange,
                    period: vm.period,
                    summary: summary,
                    nextExpense: nil,
                    topCategory: route.kind == .presets ? topCategory : nil,
                    capStatuses: nil
                )
            } else {
                Color.clear
                    .navigationTitle(route.title)
            }
        }
        .navigationDestination(for: NextPlannedRoute.self) { route in
            let snapshot = (nextPlannedSnapshot?.budgetID == route.budgetID) ? nextPlannedSnapshot : nil
            NextPlannedPresetsView(summaryID: route.budgetID, nextExpense: snapshot)
                .environment(\.managedObjectContext, CoreDataService.shared.viewContext)
        }
        .navigationDestination(for: CardItem.self) { card in
            CardDetailView(
                card: card,
                isPresentingAddExpense: .constant(false),
                onDone: {}
            )
        }
        .tipsAndHintsOverlay(for: .home)
        .tipsAndHintsOverlay(for: .home, kind: .whatsNew, versionToken: whatsNewVersionToken)
    }

    // MARK: Content
    @ViewBuilder
    private var contentSections: some View {
        switch vm.state {
        case .initial, .loading:
            Section {
                ProgressView("Loading…")
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .listRowInsets(listRowInsets)
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
                    .ub_preOS26ListRowBackground(.clear)
            }
        case .empty:
            Section {
                emptyState
                    .listRowInsets(listRowInsets)
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
                    .ub_preOS26ListRowBackground(.clear)
            }
        case .loaded:
            if let summary = primarySummary {
                widgetListSections(for: summary)
            } else {
                Section {
                    emptyState
                        .listRowInsets(listRowInsets)
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                        .ub_preOS26ListRowBackground(.clear)
                }
            }
        }
    }

    @ViewBuilder
    private var listContent: some View {
        if #available(iOS 16.0, macCatalyst 16.0, *) {
            listBody
                .scrollContentBackground(.hidden)
        } else {
            listBody
        }
    }

    private var listBody: some View {
        List {
            Section {
                dateRow
                    .listRowInsets(listRowInsets)
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
                    .ub_preOS26ListRowBackground(.clear)
            }

            contentSections
        }
        .ub_listStyleLiquidAware()
    }

    @ViewBuilder
    private var dateRow: some View {
        let applyDisabled = startDateSelection > endDateSelection
        let useCompactLayout = isCompactDateRow || isAccessibilitySize
        let rangeLabel = Text(rangeDescription(currentRange))
            .font(.headline.weight(.semibold))
            .lineLimit(isAccessibilitySize ? nil : (useCompactLayout ? 2 : 1))
            .multilineTextAlignment(.leading)

        let controls = dateRowControls(disabled: applyDisabled, compactLayout: useCompactLayout)

        Group {
            if useCompactLayout {
                VStack(alignment: .leading, spacing: 12) {
                    rangeLabel
                    controls
                }
            } else {
                HStack(spacing: 12) {
                    rangeLabel
                    Spacer()
                    controls
                }
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(glassRowBackground)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    @ViewBuilder
    private func dateRowControls(disabled: Bool, compactLayout: Bool) -> some View {
        Group {
            if compactLayout {
                if isAccessibilitySize {
                    VStack(alignment: .leading, spacing: 8) {
                        datePickerRow(title: "Start date", selection: $startDateSelection)
                        datePickerRow(title: "End date", selection: $endDateSelection)
                        HStack(spacing: 16) {
                            applyButton(disabled)
                            periodMenu
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                } else {
                    ViewThatFits(in: .horizontal) {
                        HStack(spacing: 12) {
                            datePickerRow(title: "Start date", selection: $startDateSelection)
                            datePickerRow(title: "End date", selection: $endDateSelection)
                            applyButton(disabled)
                            periodMenu
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        VStack(alignment: .leading, spacing: 8) {
                            HStack(spacing: 8) {
                                datePickerRow(title: "Start date", selection: $startDateSelection)
                                datePickerRow(title: "End date", selection: $endDateSelection)
                            }
                            HStack(spacing: 12) {
                                applyButton(disabled)
                                periodMenu
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        VStack(alignment: .leading, spacing: 8) {
                            datePickerRow(title: "Start date", selection: $startDateSelection)
                            datePickerRow(title: "End date", selection: $endDateSelection)
                            HStack(spacing: 12) {
                                applyButton(disabled)
                                periodMenu
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                }
            } else {
                HStack(spacing: 8) {
                    DatePicker("Start date", selection: $startDateSelection, displayedComponents: [.date])
                        .labelsHidden()
                        .datePickerStyle(.compact)
                        .accessibilityLabel("Start date")
                    DatePicker("End date", selection: $endDateSelection, displayedComponents: [.date])
                        .labelsHidden()
                        .datePickerStyle(.compact)
                        .accessibilityLabel("End date")
                    applyButton(disabled)
                    periodMenu
                }
            }
        }
    }

    @ViewBuilder
    private func datePickerRow(title: String, selection: Binding<Date>) -> some View {
        if isAccessibilitySize {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
                DatePicker("", selection: selection, displayedComponents: [.date])
                    .labelsHidden()
                    .datePickerStyle(.compact)
                    .accessibilityLabel(Text(title))
            }
        } else {
            DatePicker(title, selection: selection, displayedComponents: [.date])
                .labelsHidden()
                .datePickerStyle(.compact)
                .accessibilityLabel(Text(title))
        }
    }

    private var glassRowBackground: some View {
        Group {
            if #available(iOS 26.0, macOS 15.0, macCatalyst 26.0, *) {
                Color.clear
                    .glassEffect(.regular, in: .rect(cornerRadius: 14))
            } else {
                #if canImport(UIKit)
                Color(UIColor.secondarySystemBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(.ultraThinMaterial)
                    )
                #elseif os(macOS)
                Color(NSColor.windowBackgroundColor)
                #else
                Color.gray.opacity(0.12)
                #endif
            }
        }
    }

    @ViewBuilder
    private func widgetListSections(for summary: BudgetSummary) -> some View {
        let items = widgetItems(for: summary)
        let visibleItems = orderedVisibleItems(from: items)
        let libraryItems = items.filter { !pinnedIDs.contains($0.id) }

        Group {
            Section(header: widgetsHeader) {
                ForEach(visibleItems) { item in
                    widgetCell(for: item)
                        .listRowInsets(listRowInsets)
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                        .ub_preOS26ListRowBackground(.clear)
                }
            }

            if isEditing && !libraryItems.isEmpty {
                Section {
                    Text("Add widgets")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)
                        .listRowInsets(listRowInsets)
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                        .ub_preOS26ListRowBackground(.clear)
                    ForEach(libraryItems) { item in
                        Button {
                            pinWidget(item.id)
                        } label: {
                            HStack {
                                Text(item.title)
                                Spacer()
                                Image(systemName: "pin.fill")
                            }
                            .padding(.vertical, 10)
                            .padding(.horizontal, 12)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(cardBackground(kind: item.kind))
                        }
                        .buttonStyle(.plain)
                        .listRowInsets(listRowInsets)
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                        .ub_preOS26ListRowBackground(.clear)
                    }
                }
            }
        }
        .onAppear { initializeLayoutStateIfNeeded(with: items) }
        .onChange(of: items.map(\.id)) { _ in
            initializeLayoutStateIfNeeded(with: items)
        }
        .onChange(of: storageRefreshToken) { _ in
            initializeLayoutStateIfNeeded(with: items)
        }
    }

    private var widgetsHeader: some View {
        HStack {
            Text("Widgets")
                .font(.headline.weight(.semibold))
                .foregroundStyle(.primary)
                .padding(.horizontal, isHighContrast ? 8 : 0)
                .padding(.vertical, isHighContrast ? 4 : 0)
                .background(isHighContrast ? Color.primary.opacity(0.2) : Color.clear)
                .clipShape(Capsule())
            Spacer()
            editWidgetsButton
        }
        .listRowInsets(listRowInsets)
        .listRowSeparator(.hidden)
        .listRowBackground(Color.clear)
        .ub_preOS26ListRowBackground(.clear)
    }

    private var listRowInsets: EdgeInsets {
        EdgeInsets(top: 8, leading: 20, bottom: 8, trailing: 20)
    }

    @ViewBuilder
    private var editWidgetsButton: some View {
        if capabilities.supportsOS26Translucency,
           #available(iOS 26.0, macOS 26.0, macCatalyst 26.0, *) {
            Button(isEditing ? "Done" : "Edit") {
                withAnimation(.spring(response: 0.25, dampingFraction: 0.9)) {
                    isEditing.toggle()
                    draggingID = nil
                }
            }
            .buttonStyle(.glass)
            .buttonBorderShape(.capsule)
            .tint(.clear)
            .foregroundStyle(.primary)
            .padding(.horizontal, isHighContrast ? 10 : 0)
            .padding(.vertical, isHighContrast ? 6 : 0)
            .background(isHighContrast ? Color.primary.opacity(0.2) : Color.clear)
            .clipShape(Capsule())
            .accessibilityLabel(isEditing ? "Done editing widgets" : "Edit widgets")
            .accessibilityHint("Reorder or add widgets.")
        } else {
            Button(isEditing ? "Done" : "Edit") {
                withAnimation(.spring(response: 0.25, dampingFraction: 0.9)) {
                    isEditing.toggle()
                    draggingID = nil
                }
            }
            .buttonStyle(.plain)
            .buttonBorderShape(.capsule)
            .foregroundStyle(.primary)
            .padding(.horizontal, isHighContrast ? 10 : 0)
            .padding(.vertical, isHighContrast ? 6 : 0)
            .background(isHighContrast ? Color.primary.opacity(0.2) : Color.clear)
            .clipShape(Capsule())
            .accessibilityLabel(isEditing ? "Done editing widgets" : "Edit widgets")
            .accessibilityHint("Reorder or add widgets.")
        }
    }

    // MARK: Widgets
    // MARK: Clarify help guide: % = received / planned
    private func incomeWidget(for summary: BudgetSummary) -> some View {
        widgetLink(title: "Income", subtitle: widgetRangeLabel, subtitleColor: .primary, kind: .income, span: WidgetSpan(width: 1, height: 1), summary: summary) {
            VStack(alignment: .leading, spacing: 8) {
                let total = max(summary.potentialIncomeTotal, 1)
                let percent = min(max(summary.actualIncomeTotal / total, 0), 1)
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Actual Income")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.primary)
                        Text(formatCurrency(summary.actualIncomeTotal))
                            .font(.headline)
                    }
                    Spacer()
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Planned Income")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.primary)
                        Text(formatCurrency(summary.potentialIncomeTotal))
                            .font(.headline)
                    }
                }
                HStack(spacing: 8) {
                    Text("0%")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)
                    Gauge(value: percent, in: 0...1) {
                        EmptyView()
                    }
                    .gaugeStyle(.accessoryLinear)
                    .tint(Gradient(colors: [HomeView.HomePalette.income.opacity(0.25), HomeView.HomePalette.income]))
                    .frame(maxWidth: .infinity)
                    Text(String(format: "%.0f%%", percent * 100))
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)
                }
            }
        }
    }

    // MARK: Clarify help guide: % = expenses / actual income
    private func expenseRatioWidget(for summary: BudgetSummary) -> some View {
        let expenses = summary.plannedExpensesActualTotal + summary.variableExpensesTotal
        let metrics = BudgetMetrics.expenseToIncome(
            expenses: expenses,
            expectedIncome: summary.potentialIncomeTotal,
            receivedIncome: summary.actualIncomeTotal
        )
        let hasReceived = metrics.percentOfReceived != nil
        let receivedPercent = metrics.percentOfReceived ?? 0
        let gaugeValue = hasReceived ? min(receivedPercent / 100, 1) : (metrics.expenses > 0 ? 1 : 0)
        let overReceived = (metrics.percentOfReceived ?? 0) > 100
        let tint: Color = overReceived ? .red : .green
        return widgetLink(title: "Expense to Income", subtitle: widgetRangeLabel, subtitleColor: .primary, kind: .expenseToIncome, span: WidgetSpan(width: 1, height: 1), summary: summary) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Expenses")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.primary)
                        Text(formatCurrency(metrics.expenses))
                            .font(.headline)
                    }
                    Spacer()
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Actual Income")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.primary)
                        Text(formatCurrency(summary.actualIncomeTotal))
                            .font(.headline)
                    }
                }
                HStack(spacing: 8) {
                    Text("0%")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)
                    Gauge(value: gaugeValue, in: 0...1) {
                        EmptyView()
                    }
                    .gaugeStyle(.accessoryLinear)
                    .tint(Gradient(colors: [tint.opacity(0.25), tint]))
                    .frame(maxWidth: .infinity)
                    let percentColor: Color = isHighContrast
                        ? Color.primary
                        : (overReceived ? Color.red : Color.primary)
                    Text(hasReceived ? String(format: "%.0f%%", receivedPercent) : "—")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(percentColor)
                }
            }
        }
    }

    // MARK: Clarify help guide: % = actual savings / projected savings
    private func savingsWidget(for summary: BudgetSummary) -> some View {
        let outlook = BudgetMetrics.savingsOutlook(
            actualSavings: summary.actualSavingsTotal,
            expectedIncome: summary.potentialIncomeTotal,
            incomeReceived: summary.actualIncomeTotal,
            plannedExpensesPlanned: summary.plannedExpensesPlannedTotal,
            plannedExpensesActual: summary.plannedExpensesActualTotal
        )
        let projected = outlook.projected
        let actual = outlook.actual
        let projectedPositive = projected > 0
        let percentOfProjected = projectedPositive ? (actual / projected) * 100 : nil
        let progressValue = projectedPositive ? min(max(actual / projected, 0), 1) : 0
        let percentLabel: String = {
            guard let percent = percentOfProjected else { return "--" }
            if percent > 999 { return ">999%" }
            return String(format: "%.0f%%", percent)
        }()
        let statusTint: Color = {
            if actual < 0 && projectedPositive { return .red }
            if let percent = percentOfProjected, percent >= 100 { return .green }
            return .orange
        }()
        let deficitTarget = projectedPositive ? 0 : abs(projected)
        let deficitRecovery = projectedPositive ? 0 : min(max((deficitTarget - abs(actual)) / max(deficitTarget, 1), 0), 1)
        let deficitLabel = String(format: "%.0f%%", deficitRecovery * 100)
        let deficitTint: Color = {
            if deficitRecovery >= 1 { return .green }
            if deficitRecovery >= 0.5 { return .orange }
            return .red
        }()
        return widgetLink(title: "Savings Outlook", subtitle: widgetRangeLabel, subtitleColor: .primary, kind: .savingsOutlook, span: WidgetSpan(width: 1, height: 1), summary: summary) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Projected Savings")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.primary)
                        Text(formatCurrency(projected))
                            .font(.headline)
                    }
                    Spacer()
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Actual Savings")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.primary)
                        Text(formatCurrency(actual))
                            .font(.headline)
                            .foregroundStyle(isHighContrast ? .primary : statusTint)
                    }
                }
                if projectedPositive {
                    HStack(spacing: 8) {
                        Text("0%")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.primary)
                        Gauge(value: progressValue, in: 0...1) {
                            EmptyView()
                        }
                        .gaugeStyle(.accessoryLinear)
                        .tint(Gradient(colors: [statusTint.opacity(0.25), statusTint]))
                        .frame(maxWidth: .infinity)
                        Text(percentLabel)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(isHighContrast ? .primary : statusTint)
                    }
                } else {
                    HStack(spacing: 8) {
                        Text("-100%")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.primary)
                        Gauge(value: deficitRecovery, in: 0...1) {
                            EmptyView()
                        }
                        .gaugeStyle(.accessoryLinear)
                        .tint(Gradient(colors: [deficitTint.opacity(0.25), deficitTint]))
                        .frame(maxWidth: .infinity)
                        Text(deficitLabel)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(isHighContrast ? .primary : deficitTint)
                    }
                }
            }
        }
    }


    private func nextPlannedExpenseWidget(for summary: BudgetSummary) -> some View {
        let snapshot = (nextPlannedSnapshot?.budgetID == summary.id) ? nextPlannedSnapshot : nil
        return NavigationLink(value: NextPlannedRoute(budgetID: summary.id)) {
            widgetCard(title: "Next Planned Expense", subtitle: widgetRangeLabel, subtitleColor: .primary, kind: .cards, span: WidgetSpan(width: 1, height: 1)) {
                if let snapshot {
                    let expense = fetchPlannedExpense(from: snapshot.expenseURI)
                    let cardItem = detachedCardItem(from: expense?.card)
                    NextPlannedExpenseWidgetRow(
                        cardItem: cardItem,
                        title: snapshot.title,
                        dateText: shortDate(snapshot.date),
                        plannedText: "Planned: \(formatCurrency(snapshot.plannedAmount))",
                        actualText: "Actual: \(formatCurrency(snapshot.actualAmount))"
                    )
                } else {
                    Text("No planned expenses in this range.")
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: - Next Planned Expense Helpers
    private func fetchPlannedExpense(from uri: URL) -> PlannedExpense? {
        let coordinator = CoreDataService.shared.container.persistentStoreCoordinator
        guard let id = coordinator.managedObjectID(forURIRepresentation: uri) else { return nil }
        return try? CoreDataService.shared.viewContext.existingObject(with: id) as? PlannedExpense
    }

    private func detachedCardItem(from card: Card?) -> CardItem? {
        guard let card else { return nil }
        return CardItem(from: card)
    }

    private func categorySpotlightWidget(for summary: BudgetSummary) -> some View {
        let categories = summary.categoryBreakdown
        let totalExpenses = categories.map(\.amount).reduce(0, +)
        let slices = categorySlices(from: categories, limit: 3)
        let topCategory = categories.first ?? summary.plannedCategoryBreakdown.first ?? summary.categoryBreakdown.first
        return widgetLink(title: "Category Spotlight", subtitle: widgetRangeLabel, subtitleColor: .primary, kind: .presets, span: WidgetSpan(width: 1, height: 2), summary: summary, topCategory: topCategory) {
            if let top = slices.first, totalExpenses > 0 {
                let donutHeight = isAccessibilitySize ? max(categorySpotlightHeight * 0.7, 140) : categorySpotlightHeight
                VStack(alignment: .leading, spacing: 8) {
                    CategoryDonutView(
                        slices: slices,
                        total: totalExpenses,
                        centerTitle: top.name,
                        centerValue: formatCurrency(top.amount)
                    )
                    .frame(height: donutHeight)

                    Text("Top \(min(3, slices.count)) categories in this range.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .lineLimit(nil)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            } else {
                Text("Add expenses to see category trends.")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    private func cardWidget(card: CardItem, summary: BudgetSummary) -> some View {
        NavigationLink(value: card) {
            widgetCard(title: card.name, subtitle: "Tap to view", kind: .cards, span: WidgetSpan(width: 1, height: 2)) {
                VStack(alignment: .leading, spacing: 8) {
                    CardTileView(card: card, isInteractive: false, enableMotionShine: true, showsBaseShadow: false)
                        .frame(maxWidth: cardWidgetMaxWidth, alignment: .leading)
                    if let balance = card.balance {
                        Text("\(formatCurrency(balance))")
                            .font(.title.weight(.bold))
                            .fontDesign(.rounded)
                    }
                }
            }
        }
        .buttonStyle(.plain)
    }

    private func weekdayWidget(for summary: BudgetSummary) -> some View {
        return widgetLink(title: "Day of Week Spend", subtitle: weekdayRangeLabel, subtitleColor: .primary, kind: .dayOfWeek, span: WidgetSpan(width: 1, height: 2), summary: summary) {
            if self.widgetBuckets.isEmpty {
                Text("No spending yet.")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                let previewPeriod = resolvedPeriod(vm.period, range: currentRange)
                let orientation = previewBarOrientation(for: previewPeriod, bucketCount: widgetBuckets.count)
                let maxAmount = max(self.widgetBuckets.map(\.amount).max() ?? 1, 1)
                let rowCount = max(widgetBuckets.count, 1)
                let rowHeight = isAccessibilitySize ? dayOfWeekRowHeight * 1.35 : dayOfWeekRowHeight
                let stackedHeight = CGFloat(rowCount) * rowHeight + CGFloat(max(rowCount - 1, 0)) * dayOfWeekRowSpacing
                let chartHeight = max(dayOfWeekChartHeight, stackedHeight)
                VStack(alignment: .leading, spacing: 8) {
                    SpendBucketChart(
                        buckets: widgetBuckets,
                        maxAmount: maxAmount,
                        summary: summary,
                        period: previewPeriod,
                        orientation: orientation,
                        maxColors: 4
                    )
                    .frame(height: chartHeight)
                    .frame(maxWidth: .infinity, alignment: .topLeading)

                    if let maxItem = self.widgetBuckets.max(by: { $0.amount < $1.amount }) {
                        Text("Highest: \(maxItem.label) • \(formatCurrency(maxItem.amount))")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.primary)
                            .lineLimit(nil)
                            .fixedSize(horizontal: false, vertical: true)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            }
        }
    }

    private func previewBarOrientation(for period: BudgetPeriod, bucketCount: Int) -> SpendBarOrientation {
        if period == .yearly { return .vertical }
        if period == .quarterly || period == .monthly { return .horizontal }
        if period == .biWeekly { return .horizontal }
        if bucketCount <= 2 { return .horizontal }
        return .vertical
    }

    private struct SpendBucketChart: View {
        let buckets: [SpendBucket]
        let maxAmount: Double
        let summary: BudgetSummary
        let period: BudgetPeriod
        let orientation: SpendBarOrientation
        let maxColors: Int
        @ScaledMetric(relativeTo: .body) private var spacing: CGFloat = 8
        @ScaledMetric(relativeTo: .body) private var labelWidth: CGFloat = 60
        @ScaledMetric(relativeTo: .body) private var labelWidthAccessibility: CGFloat = 84
        @ScaledMetric(relativeTo: .body) private var minRowHeight: CGFloat = 14
        @ScaledMetric(relativeTo: .body) private var minBarWidth: CGFloat = 10
        @ScaledMetric(relativeTo: .body) private var labelHeight: CGFloat = 16
        @ScaledMetric(relativeTo: .body) private var minBarAreaHeight: CGFloat = 60
        @Environment(\.dynamicTypeSize) private var dynamicTypeSize

        var body: some View {
            GeometryReader { geo in
                let count = max(buckets.count, 1)
                let baseLabelWidth = dynamicTypeSize.isAccessibilitySize ? labelWidthAccessibility : labelWidth
                let resolvedLabelWidth = dynamicTypeSize.isAccessibilitySize
                    ? min(baseLabelWidth, max(48, geo.size.width * 0.25))
                    : baseLabelWidth
                if orientation == .horizontal {
                    let minLabelHeight = labelHeight * (dynamicTypeSize.isAccessibilitySize ? 2 : 1)
                    let rowHeight = max((geo.size.height - spacing * CGFloat(count - 1)) / CGFloat(count), max(minRowHeight, minLabelHeight))
                    let barMaxWidth = max(geo.size.width - resolvedLabelWidth - 8, 20)
                    VStack(alignment: .leading, spacing: spacing) {
                        ForEach(buckets) { item in
                            let norm = max(min(item.amount / maxAmount, 1), 0)
                            let gradientColors = spendGradientColors(for: item, summary: summary, maxColors: maxColors)
                            let gradient = LinearGradient(
                                colors: gradientColors.map { $0.opacity(0.4 + 0.5 * norm) },
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                            HStack(spacing: 6) {
                                Text(displayLabel(item.label, period: period))
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(dynamicTypeSize.isAccessibilitySize ? 2 : 1)
                                    .fixedSize(horizontal: false, vertical: true)
                                    .frame(width: resolvedLabelWidth, alignment: .leading)
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
                    let barWidth = max((geo.size.width - spacing * CGFloat(count - 1)) / CGFloat(count), minBarWidth)
                    let barAreaHeight = max(minBarAreaHeight, geo.size.height - labelHeight)
                    HStack(alignment: .bottom, spacing: spacing) {
                        ForEach(buckets) { item in
                            let norm = max(min(item.amount / maxAmount, 1), 0)
                            let gradientColors = spendGradientColors(for: item, summary: summary, maxColors: maxColors)
                            let gradient = LinearGradient(
                                colors: gradientColors.map { $0.opacity(0.4 + 0.5 * norm) },
                                startPoint: .top,
                                endPoint: .bottom
                            )
                            VStack(spacing: 4) {
                                Rectangle()
                                    .fill(gradient)
                                    .frame(width: barWidth, height: max(CGFloat(norm) * (barAreaHeight - 8), 6))
                                    .clipShape(RoundedRectangle(cornerRadius: 3, style: .continuous))
                                Text(displayLabel(item.label, period: period))
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(1)
                                    .frame(width: barWidth, alignment: .center)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
                }
            }
        }

        private func displayLabel(_ label: String, period: BudgetPeriod) -> String {
            if period == .yearly, let first = label.first {
                return String(first)
            }
            return label
        }
    }

    // MARK: Widget orchestration
    private func widgetItems(for summary: BudgetSummary) -> [WidgetItem] {
        var items: [WidgetItem] = [
            WidgetItem(id: .income, span: WidgetSpan(width: 1, height: 1), view: AnyView(incomeWidget(for: summary)), title: "Income", kind: .income),
            WidgetItem(id: .expenseToIncome, span: WidgetSpan(width: 1, height: 1), view: AnyView(expenseRatioWidget(for: summary)), title: "Expense to Income", kind: .expenseToIncome),
            WidgetItem(id: .savings, span: WidgetSpan(width: 1, height: 1), view: AnyView(savingsWidget(for: summary)), title: "Savings Outlook", kind: .savingsOutlook),
            WidgetItem(id: .nextPlanned, span: WidgetSpan(width: 1, height: 1), view: AnyView(nextPlannedExpenseWidget(for: summary)), title: "Next Planned Expense", kind: .cards),
            WidgetItem(id: .categorySpotlight, span: WidgetSpan(width: 1, height: 2), view: AnyView(categorySpotlightWidget(for: summary)), title: "Category Spotlight", kind: .presets),
            WidgetItem(id: .dayOfWeek, span: WidgetSpan(width: 1, height: 2), view: AnyView(weekdayWidget(for: summary)), title: "Day of Week Spend", kind: .dayOfWeek),
            WidgetItem(id: .availability, span: WidgetSpan(width: 1, height: 3), view: AnyView(categoryAvailabilityWidget(for: summary)), title: "Category Availability", kind: .availability),
            WidgetItem(id: .scenario, span: WidgetSpan(width: 1, height: 1), view: AnyView(scenarioWidget(for: summary)), title: "What If?", kind: .scenario)
        ]

        for card in cardWidgets {
            let cardID = WidgetID.card(card.id)
            items.append(
                WidgetItem(
                    id: cardID,
                    span: WidgetSpan(width: 1, height: 2),
                    view: AnyView(cardWidget(card: card, summary: summary)),
                    title: card.name,
                    kind: .cards
                )
            )
        }

        return items
    }

    private func orderedVisibleItems(from items: [WidgetItem]) -> [WidgetItem] {
        let lookup = Dictionary(uniqueKeysWithValues: items.map { ($0.id, $0) })
        let available = items.map(\.id)
        let order = normalize(order: widgetOrder, available: available)
        let pinnedSet = Set(pinnedIDs)
        return order.compactMap { id in
            guard pinnedSet.contains(id) else { return nil }
            return lookup[id]
        }
    }

    @ViewBuilder
    private func widgetCell(for item: WidgetItem) -> some View {
        let base = item.view
            .layoutValue(key: WidgetSpanKey.self, value: item.span)
            .overlay(alignment: .topTrailing) {
                if isEditing {
                    pinToggle(for: item.id, title: item.title, isPinned: pinnedIDs.contains(item.id))
                }
            }
            .opacity(draggingID == item.id ? 0.65 : 1)
            .scaleEffect(draggingID == item.id ? 0.98 : 1)

        if isEditing {
            base
                .onDrag {
                    draggingID = item.id
                    return NSItemProvider(object: item.id.storageKey as NSString)
                }
                .onDrop(of: [UTType.text], delegate: WidgetDropDelegate(target: item.id, order: $widgetOrder, dragging: $draggingID, persist: persistOrder))
        } else {
            base
        }
    }

    @ViewBuilder
    private func pinToggle(for id: WidgetID, title: String, isPinned: Bool) -> some View {
        Button {
            if isPinned {
                unpinWidget(id)
            } else {
                pinWidget(id)
            }
        } label: {
            Image(systemName: isPinned ? "pin.slash.fill" : "pin.fill")
                .font(.footnote.weight(.bold))
                .padding(8)
                .background(.ultraThinMaterial, in: Circle())
        }
        .buttonStyle(.plain)
        .padding(6)
        .accessibilityLabel(isPinned ? "Unpin \(title)" : "Pin \(title)")
        .accessibilityHint(isPinned ? "Removes this widget from the list." : "Keeps this widget in the list.")
    }

    private func pinWidget(_ id: WidgetID) {
        if !pinnedIDs.contains(id) {
            pinnedIDs.append(id)
        }
        if !widgetOrder.contains(id) {
            widgetOrder.append(id)
        }
        persistPinned()
        persistOrder()
    }

    private func unpinWidget(_ id: WidgetID) {
        pinnedIDs.removeAll { $0 == id }
        persistPinned()
    }

    private func initializeLayoutStateIfNeeded(with items: [WidgetItem]) {
        let available = items.map(\.id)
        refreshWidgetStorageFromCloudIfNeeded()
        let storedPinned = decodeIDs(from: pinnedStorage)
        let storedOrder = decodeIDs(from: orderStorage)
        let hasStoredPrefs = !storedPinned.isEmpty || !storedOrder.isEmpty

        if pinnedIDs.isEmpty {
            let decoded = storedPinned.filter { available.contains($0) }
            if decoded.isEmpty && !hasStoredPrefs {
                pinnedIDs = HomeView.defaultWidgets.filter { available.contains($0) }
            } else {
                pinnedIDs = decoded
            }
        } else {
            pinnedIDs = pinnedIDs.filter { available.contains($0) }
        }

        // Auto-add any newly discovered cards so they surface without manual pinning.
        let knownOrder = Set(storedOrder)
        let cardIDs = available.filter {
            if case .card = $0 { return true }
            return false
        }
        for cardID in cardIDs where !knownOrder.contains(cardID) && !pinnedIDs.contains(cardID) {
            pinnedIDs.append(cardID)
        }
        if available.contains(.scenario), !knownOrder.contains(.scenario), !pinnedIDs.contains(.scenario) {
            pinnedIDs.append(.scenario)
        }

        if widgetOrder.isEmpty {
            let decoded = storedOrder.filter { available.contains($0) }
            if decoded.isEmpty {
                let seed = hasStoredPrefs ? pinnedIDs : HomeView.defaultWidgets
                widgetOrder = normalize(order: seed, available: available)
            } else {
                widgetOrder = normalize(order: decoded, available: available)
            }
        } else {
            widgetOrder = normalize(order: widgetOrder, available: available)
        }
        if available.contains(.scenario), !widgetOrder.contains(.scenario) {
            if let availabilityIndex = widgetOrder.firstIndex(of: .availability) {
                widgetOrder.insert(.scenario, at: widgetOrder.index(after: availabilityIndex))
            } else {
                widgetOrder.append(.scenario)
            }
        }

        persistPinned()
        persistOrder()
    }

    private func normalize(order: [WidgetID], available: [WidgetID]) -> [WidgetID] {
        var normalized = order.filter { available.contains($0) }
        for id in available where !normalized.contains(id) {
            normalized.append(id)
        }
        return normalized
    }

    private func decodeIDs(from raw: String) -> [WidgetID] {
        raw
            .split(separator: "|")
            .compactMap { WidgetID.fromStorage(String($0)) }
    }

    private func encodeIDs(_ ids: [WidgetID]) -> String {
        ids.map { $0.storageKey }.joined(separator: "|")
    }

    private func persistPinned() {
        pinnedStorage = encodeIDs(pinnedIDs)
        syncWidgetStorageIfNeeded(pinnedStorage, cloudKey: WidgetStorageKey.pinnedCloud)
    }

    private func persistOrder() {
        var unique: [WidgetID] = []
        for id in widgetOrder where !unique.contains(id) {
            unique.append(id)
        }
        widgetOrder = unique
        orderStorage = encodeIDs(unique)
        syncWidgetStorageIfNeeded(orderStorage, cloudKey: WidgetStorageKey.orderCloud)
    }

    private func refreshWidgetStorageFromCloudIfNeeded() {
        guard shouldSyncWidgets else { return }
        let pinned = loadSyncedString(localKey: WidgetStorageKey.pinnedLocal, cloudKey: WidgetStorageKey.pinnedCloud)
        let order = loadSyncedString(localKey: WidgetStorageKey.orderLocal, cloudKey: WidgetStorageKey.orderCloud)
        if pinnedStorage != pinned {
            pinnedStorage = pinned
        }
        if orderStorage != order {
            orderStorage = order
        }
    }

    private func loadSyncedString(localKey: String, cloudKey: String) -> String {
        let defaults = UserDefaults.standard
        if shouldSyncWidgets {
            let kv = NSUbiquitousKeyValueStore.default
            if kv.object(forKey: cloudKey) != nil {
                let value = kv.string(forKey: cloudKey) ?? ""
                defaults.set(value, forKey: localKey)
                return value
            }
            if defaults.object(forKey: localKey) != nil {
                let value = defaults.string(forKey: localKey) ?? ""
                kv.set(value, forKey: cloudKey)
                kv.synchronize()
                return value
            }
        }
        return defaults.string(forKey: localKey) ?? ""
    }

    private func syncWidgetStorageIfNeeded(_ value: String, cloudKey: String) {
        guard shouldSyncWidgets else { return }
        let kv = NSUbiquitousKeyValueStore.default
        kv.set(value, forKey: cloudKey)
        kv.synchronize()
    }

    private func handleWidgetSyncPreferenceChange() {
        if shouldSyncWidgets {
            refreshWidgetStorageFromCloudIfNeeded()
            startObservingWidgetSyncIfNeeded()
            storageRefreshToken = UUID()
        } else {
            stopObservingWidgetSync()
        }
    }

    private func startObservingWidgetSyncIfNeeded() {
        guard shouldSyncWidgets, ubiquitousObserver == nil else { return }
        ubiquitousObserver = NotificationCenter.default.addObserver(
            forName: NSUbiquitousKeyValueStore.didChangeExternallyNotification,
            object: NSUbiquitousKeyValueStore.default,
            queue: .main
        ) { _ in
            refreshWidgetStorageFromCloudIfNeeded()
            storageRefreshToken = UUID()
        }
    }

    private func stopObservingWidgetSync() {
        if let observer = ubiquitousObserver {
            NotificationCenter.default.removeObserver(observer)
            ubiquitousObserver = nil
        }
    }

    private struct WidgetDropDelegate: DropDelegate {
        let target: WidgetID
        @Binding var order: [WidgetID]
        @Binding var dragging: WidgetID?
        let persist: () -> Void

        func validateDrop(info: DropInfo) -> Bool {
            dragging != nil
        }

        func dropEntered(info: DropInfo) {
            reorderIfNeeded()
        }

        func dropUpdated(info: DropInfo) -> DropProposal? {
            DropProposal(operation: .move)
        }

        func performDrop(info: DropInfo) -> Bool {
            dragging = nil
            persist()
            return true
        }

        private func reorderIfNeeded() {
            guard let dragging else { return }
            guard dragging != target else { return }
            guard let fromIndex = order.firstIndex(of: dragging),
                  let toIndex = order.firstIndex(of: target) else { return }
            var mutableOrder = order
            let item = mutableOrder.remove(at: fromIndex)
            let destination = toIndex > fromIndex ? toIndex - 1 : toIndex
            mutableOrder.insert(item, at: destination)
            withAnimation(.spring(response: 0.25, dampingFraction: 0.9)) {
                order = mutableOrder
            }
        }
    }

    private func categoryAvailabilityWidget(for summary: BudgetSummary) -> some View {
        let rowHeight = availabilityRowHeight
        let rowSpacing = availabilityRowSpacing + (isAccessibilitySize ? 20 : 10)
        let tabPadding = availabilityTabPadding
        let pageSize = 5

        return widgetLink(title: "Category Availability", subtitle: widgetRangeLabel, subtitleColor: .primary, kind: .availability, span: WidgetSpan(width: 1, height: 3), summary: summary) {
            let segment = availabilitySegment
            let items = categoryAvailability(for: summary, segment: segment)
            let statuses = capStatuses.filter { $0.segment == segment }
            let overCount = statuses.filter { $0.over }.count
            let nearCount = statuses.filter { $0.near && !$0.over }.count
            let pages = stride(from: 0, to: items.count, by: pageSize).map { idx in
                Array(items[idx..<min(idx + pageSize, items.count)])
            }
            let pageCount = pages.count
            let currentPageIndex = min(availabilityPage, max(pageCount - 1, 0))
            let pageItems = pages.isEmpty ? [] : pages[currentPageIndex]
            let listHeight = CGFloat(pageSize) * rowHeight + CGFloat(max(pageSize - 1, 0)) * rowSpacing + tabPadding * 2
            let rowMinHeight: CGFloat? = isAccessibilitySize ? nil : rowHeight

            if isAccessibilitySize {
                VStack(alignment: .leading, spacing: 0) {
                    VStack(alignment: .leading, spacing: 10) {
                        PillSegmentedControl(selection: availabilitySegmentBinding) {
                            ForEach(CategoryAvailabilitySegment.allCases) { segment in
                                Text(segment.title).tag(segment)
                            }
                        }
                        .ubSegmentedGlassStyle()

                        VStack(alignment: .leading, spacing: 6) {
                            HStack(spacing: 6) {
                                Circle().fill(Color.red.opacity(0.2)).frame(width: availabilityStatusDotSize, height: availabilityStatusDotSize)
                                Text("Over: \(overCount)")
                            }
                            HStack(spacing: 6) {
                                Circle().fill(Color.orange.opacity(0.25)).frame(width: availabilityStatusDotSize, height: availabilityStatusDotSize)
                                Text("Near: \(nearCount)")
                            }
                        }
                        .font(.ubCaption)
                        .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal, 14)
                    .padding(.top, 10)
                    .padding(.bottom, 10)

                    Divider()
                        .padding(.horizontal, 14)
                        .opacity(0.35)

                    if pageItems.isEmpty {
                        Text("No categories yet.")
                            .foregroundStyle(.secondary)
                            .font(.ubCaption)
                            .frame(maxWidth: .infinity, minHeight: rowHeight * 2, alignment: .center)
                            .padding(.vertical, tabPadding)
                    } else {
                        VStack(spacing: rowSpacing) {
                            ForEach(pageItems) { item in
                                CategoryAvailabilityRow(item: item, currencyFormatter: formatCurrency)
                                    .frame(minHeight: rowMinHeight, alignment: .center)
                            }
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, tabPadding)
                    }

                    if pageCount > 1 {
                        Divider()
                            .padding(.horizontal, 14)
                            .opacity(0.35)

                        HStack {
                            Spacer(minLength: 0)
                            HStack(spacing: 16) {
                                availabilityNavButton("chevron.left", isDisabled: currentPageIndex == 0) {
                                    availabilityPage = max(currentPageIndex - 1, 0)
                                }
                                availabilityNavButton("chevron.right", isDisabled: currentPageIndex >= pageCount - 1) {
                                    availabilityPage = min(currentPageIndex + 1, pageCount - 1)
                                }
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            Spacer(minLength: 0)
                        }
                    }
                }
                .padding(.top, 6)
                .onChange(of: availabilitySegmentRawValue) { _ in availabilityPage = 0 }
                .onChange(of: pageCount) { _ in
                    availabilityPage = min(availabilityPage, max(pageCount - 1, 0))
                }
            } else {
                VStack(alignment: .leading, spacing: 0) {
                    PillSegmentedControl(selection: availabilitySegmentBinding) {
                        ForEach(CategoryAvailabilitySegment.allCases) { segment in
                            Text(segment.title).tag(segment)
                        }
                    }
                    .ubSegmentedGlassStyle()
                    .padding(.horizontal, 14)
                    .padding(.top, 10)
                    .padding(.bottom, 10)

                    HStack(spacing: 14) {
                        HStack(spacing: 6) {
                            Circle().fill(Color.red.opacity(0.2)).frame(width: availabilityStatusDotSize, height: availabilityStatusDotSize)
                            Text("Over: \(overCount)")
                        }
                        HStack(spacing: 6) {
                            Circle().fill(Color.orange.opacity(0.25)).frame(width: availabilityStatusDotSize, height: availabilityStatusDotSize)
                            Text("Near: \(nearCount)")
                        }
                        Spacer()
                    }
                    .font(.ubCaption)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 14)
                    .padding(.bottom, 6)

                    Divider()
                        .padding(.horizontal, 14)
                        .opacity(0.35)

                    if pageItems.isEmpty {
                        Text("No categories yet.")
                            .foregroundStyle(.secondary)
                            .font(.ubCaption)
                            .frame(maxWidth: .infinity, minHeight: rowHeight * 2, alignment: .center)
                            .padding(.vertical, tabPadding)
                    } else {
                        VStack(spacing: rowSpacing) {
                            ForEach(pageItems) { item in
                                CategoryAvailabilityRow(item: item, currencyFormatter: formatCurrency)
                                    .frame(minHeight: rowMinHeight, alignment: .center)
                            }
                            let missingRows = max(0, pageSize - pageItems.count)
                            ForEach(0..<missingRows, id: \.self) { _ in
                                Color.clear
                                    .frame(minHeight: rowHeight)
                            }
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, tabPadding)
                        .frame(height: listHeight, alignment: .top)
                    }

                    if pageCount > 1 {
                        Divider()
                            .padding(.horizontal, 14)
                            .opacity(0.35)

                        HStack {
                            Spacer(minLength: 0)
                            HStack(spacing: 16) {
                                availabilityNavButton("chevron.left", isDisabled: currentPageIndex == 0) {
                                    availabilityPage = max(currentPageIndex - 1, 0)
                                }
                                availabilityNavButton("chevron.right", isDisabled: currentPageIndex >= pageCount - 1) {
                                    availabilityPage = min(currentPageIndex + 1, pageCount - 1)
                                }
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            Spacer(minLength: 0)
                        }
                    }
                }
                .padding(.top, 6)
                .onChange(of: availabilitySegmentRawValue) { _ in availabilityPage = 0 }
                .onChange(of: pageCount) { _ in
                    availabilityPage = min(availabilityPage, max(pageCount - 1, 0))
                }
            }
        }
    }

    private func scenarioWidget(for summary: BudgetSummary) -> some View {
        let actualSavings = summary.actualSavingsTotal
        let savingsColor: Color = actualSavings < 0 ? .red : .green
        return widgetLink(title: "What If?", subtitle: widgetRangeLabel, subtitleColor: .primary, kind: .scenario, span: WidgetSpan(width: 1, height: 1), summary: summary) {
            VStack(alignment: .center, spacing: 6) {
                Text(formatCurrency(actualSavings))
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(isHighContrast ? .primary : savingsColor)
                    .lineLimit(isAccessibilitySize ? nil : 1)
                Text("Actual Savings")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
                Text("Tap to plan scenarios and see how much you can still save.")
                    .font(.subheadline)
                    .foregroundStyle(.primary)
                    .lineLimit(isAccessibilitySize ? nil : 2)
            }
            .frame(maxWidth: .infinity, alignment: .center)
        }
    }

    @ViewBuilder
    private func availabilityNavButton(_ systemName: String, isDisabled: Bool, action: @escaping () -> Void) -> some View {
        if capabilities.supportsOS26Translucency,
           #available(iOS 26.0, macOS 26.0, macCatalyst 26.0, *) {
            Button(action: action) {
                let buttonSize: CGFloat = 44
                ZStack {
                    Circle()
                        .fill(.ultraThinMaterial)
                        .glassEffect(.regular, in: .rect(cornerRadius: buttonSize / 2))
                    Image(systemName: systemName)
                        .font(.body.weight(.semibold))
                        .foregroundStyle(.primary)
                }
                .frame(width: buttonSize, height: buttonSize)
            }
            .buttonBorderShape(.circle)
            .buttonStyle(.plain)
            .disabled(isDisabled)
            .opacity(isDisabled ? 0.4 : 1)
        } else {
            Button(action: action) {
                let buttonSize: CGFloat = 44
                ZStack {
                    Circle()
                        .fill(Color.primary.opacity(0.08))
                    Image(systemName: systemName)
                        .font(.body.weight(.semibold))
                        .foregroundStyle(.primary)
                }
                .frame(width: buttonSize, height: buttonSize)
            }
            .buttonStyle(.plain)
            .disabled(isDisabled)
            .opacity(isDisabled ? 0.4 : 1)
        }
    }


    // MARK: Widget Helpers
    private func widgetLink<Content: View>(
        title: String,
        subtitle: String? = nil,
        subtitleColor: Color = .secondary,
        kind: HomeWidgetKind,
        span: WidgetSpan,
        summary: BudgetSummary,
        snapshot: PlannedExpenseSnapshot? = nil,
        topCategory: BudgetSummary.CategorySpending? = nil,
        capStatuses: [CapStatus]? = nil,
        @ViewBuilder content: @escaping () -> Content
    ) -> some View {
        NavigationLink(value: HomeMetricRoute(budgetID: summary.id, title: title, kind: kind)) {
            widgetCard(title: title, subtitle: subtitle, subtitleColor: subtitleColor, kind: kind, span: span, content: content)
        }
        .buttonStyle(.plain)
    }

    private func widgetCard<Content: View>(title: String, subtitle: String? = nil, subtitleColor: Color = .secondary, kind: HomeWidgetKind, span: WidgetSpan, @ViewBuilder content: () -> Content) -> some View {
        let body = content()
        return VStack(alignment: .leading, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.ubWidgetTitle)
                        .foregroundStyle(isHighContrast ? kind.highContrastTitleColor : kind.baseTitleColor)
                        .lineLimit(isAccessibilitySize ? nil : 2)
                if let subtitle {
                    Text(subtitle)
                        .font(.ubWidgetSubtitle)
                        .foregroundStyle(subtitleColor)
                        .lineLimit(isAccessibilitySize ? nil : 2)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            body
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .background(cardBackground(kind: kind))
    }

    private func cardBackground(kind: HomeWidgetKind) -> some View {
        let corner: CGFloat = 18
        #if canImport(UIKit)
        let fallback = Color(UIColor.secondarySystemBackground).opacity(0.96)
        #elseif os(macOS)
        let fallback = Color(NSColor.windowBackgroundColor).opacity(0.97)
        #else
        let fallback = Color.gray.opacity(0.16)
        #endif

        let shape = RoundedRectangle(cornerRadius: corner, style: .continuous)

        return Group {
            if #available(iOS 26.0, macOS 15.0, macCatalyst 26.0, *) {
                shape
                    .fill(.regularMaterial)
                    .overlay(
                        shape.stroke(Color.primary.opacity(0.08), lineWidth: 1)
                    )
                    .glassEffect(.regular, in: .rect(cornerRadius: corner))
            } else {
                shape
                    .fill(fallback)
                    .overlay(
                        shape.stroke(Color.primary.opacity(0.08), lineWidth: 1)
                    )
            }
        }
    }

    // MARK: Derived Data
    private var summaries: [BudgetSummary] {
        if case .loaded(let items) = vm.state { return items }
        return []
    }

    private var currentRange: ClosedRange<Date> { vm.currentDateRange }

    private var primarySummary: BudgetSummary? {
        let range = currentRange
        let cal = Calendar.current
        if let exact = summaries.first(where: { cal.isDate($0.periodStart, inSameDayAs: range.lowerBound) && cal.isDate($0.periodEnd, inSameDayAs: range.upperBound) }) {
            return exact
        }
        return summaries.first
    }

    private var widgetRangeLabel: String {
        return rangeDescription(currentRange)
    }

    private var weekdayRangeLabel: String {
        if let override = weekdayRangeOverride {
            return rangeDescription(override)
        }
        return widgetRangeLabel
    }

    private var heatmapBackground: some View {
        LinearGradient(
            colors: [
                HomePalette.income.opacity(0.22),
                HomePalette.presets.opacity(0.20),
                HomePalette.budgets.opacity(0.22),
                HomePalette.cards.opacity(0.22)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .blur(radius: 60)
        .overlay(Color.black.opacity(0.03))
    }

    private var emptyState: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("No budget data yet.")
                .font(.headline)
            Text("Set a budget for the \(vm.period.displayName.lowercased()) window or pick a custom date range to see widgets.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(cardBackground(kind: .budgets))
    }

    // MARK: Lifecycle helpers
    private func onAppearTask() async {
        handleWidgetSyncPreferenceChange()
        syncPickers(with: currentRange)
        vm.startIfNeeded()
    }

    private func stateDidChange() async {
        switch vm.state {
        case .loaded, .empty:
            break
        case .initial, .loading:
            return
        }
        let summary = primarySummary
        await loadNextPlannedExpense(for: summary)
        await loadWidgetBuckets(for: summary)
        await loadAllCards()
        await loadCaps(for: summary)
    }

    private func rangeDescription(_ range: ClosedRange<Date>) -> String {
        let f = DateFormatter()
        f.locale = Locale.current
        f.dateFormat = "MMM d, yyyy"
        let start = f.string(from: range.lowerBound)
        let end = f.string(from: range.upperBound)
        return "\(start) - \(end)"
    }

    private var dateActionSymbolFont: Font {
        isAccessibilitySize ? .title2.weight(.semibold) : .title3.weight(.semibold)
    }

    @ViewBuilder
    private func applyButton(_ disabled: Bool) -> some View {
        if #available(iOS 26.0, macCatalyst 26.0, *) {
            Button(action: applyCustomRangeFromPickers) {
                let buttonSize = max(dateActionButtonSize, 44)
                ZStack {
                    Circle()
                        .fill(.ultraThinMaterial)
                        .glassEffect(.regular, in: .rect(cornerRadius: buttonSize / 2))
                    Image(systemName: "arrow.right")
                        .font(dateActionSymbolFont)
                        .foregroundStyle(.primary)
                }
                .frame(width: buttonSize, height: buttonSize)
            }
            .buttonStyle(.plain)
            .buttonBorderShape(.circle)
            .tint(.accentColor)
            .frame(minWidth: 44, minHeight: 44)
            .accessibilityLabel("Apply date range")
            .accessibilityHint("Updates widgets for the selected dates.")
            .disabled(disabled)
        } else {
            Button(action: applyCustomRangeFromPickers) {
                let buttonSize = max(dateActionButtonSize, 44)
                ZStack {
                    Circle()
                        .fill(Color.primary.opacity(0.08))
                    Image(systemName: "arrow.right")
                        .font(dateActionSymbolFont)
                        .foregroundStyle(.primary)
                }
                .frame(width: buttonSize, height: buttonSize)
            }
            .buttonStyle(.plain)
            .frame(minWidth: 44, minHeight: 44)
            .accessibilityLabel("Apply date range")
            .accessibilityHint("Updates widgets for the selected dates.")
            .disabled(disabled)
        }
    }

    @ViewBuilder
    private var periodMenu: some View {
        if #available(iOS 26.0, macCatalyst 26.0, *) {
            Menu {
                periodMenuItems
            } label: {
                let buttonSize = max(dateActionButtonSize, 44)
                ZStack {
                    Circle()
                        .fill(.ultraThinMaterial)
                        .glassEffect(.regular, in: .rect(cornerRadius: buttonSize / 2))
                    Image(systemName: "calendar")
                        .font(dateActionSymbolFont)
                        .foregroundStyle(.primary)
                }
                .frame(width: buttonSize, height: buttonSize)
            }
            .buttonStyle(.plain)
            .buttonBorderShape(.circle)
            .tint(.accentColor)
            .frame(minWidth: 44, minHeight: 44)
            .accessibilityLabel("Date presets")
            .accessibilityHint("Choose a preset date range.")
        } else {
            Menu {
                periodMenuItems
            } label: {
                let buttonSize = max(dateActionButtonSize, 44)
                ZStack {
                    Circle()
                        .fill(Color.primary.opacity(0.08))
                    Image(systemName: "calendar")
                        .font(dateActionSymbolFont)
                        .foregroundStyle(.primary)
                }
                .frame(width: buttonSize, height: buttonSize)
            }
            .frame(minWidth: 44, minHeight: 44)
            .accessibilityLabel("Date presets")
            .accessibilityHint("Choose a preset date range.")
        }
    }

    @ViewBuilder
    private var periodMenuItems: some View {
        ForEach(BudgetPeriod.selectableCases) { period in
            Button {
                applyPeriod(period)
            } label: {
                HStack {
                    Text(period.displayName)
                    if period == vm.period, !vm.isUsingCustomRange {
                        Image(systemName: "checkmark")
                    }
                }
            }
        }
    }

    private func syncPickers(with range: ClosedRange<Date>) {
        startDateSelection = range.lowerBound
        endDateSelection = range.upperBound
    }

    private func applyCustomRangeFromPickers() {
        vm.applyCustomRange(start: startDateSelection, end: endDateSelection)
    }

    private func applyPeriod(_ period: BudgetPeriod) {
        vm.updateBudgetPeriod(to: period)
        syncPickers(with: vm.currentDateRange)
    }

    private func formatCurrency(_ amount: Double) -> String {
        if #available(iOS 15.0, macCatalyst 15.0, *) {
            let currencyCode: String
            if #available(iOS 16.0, macCatalyst 16.0, *) {
                currencyCode = Locale.current.currency?.identifier ?? "USD"
            } else {
                currencyCode = Locale.current.currencyCode ?? "USD"
            }
            return amount.formatted(.currency(code: currencyCode))
        } else {
            let formatter = NumberFormatter()
            formatter.numberStyle = .currency
            formatter.currencyCode = Locale.current.currencyCode ?? "USD"
            return formatter.string(from: amount as NSNumber) ?? String(format: "%.2f", amount)
        }
    }

    private func loadNextPlannedExpense(for summary: BudgetSummary?) async {
        guard let summary else {
            await MainActor.run {
                nextPlannedSnapshot = nil
                updateNextPlannedExpenseWidget(snapshot: nil)
            }
            return
        }
        let range = currentRange
        let selectedDate = await MainActor.run { vm.selectedDate }
        let anchorDate = nextExpenseAnchorDate(for: range, selectedDate: selectedDate)
        let bgContext = CoreDataService.shared.newBackgroundContext()
        let snapshot: PlannedExpenseSnapshot? = await bgContext.perform {
            guard let budget = try? bgContext.existingObject(with: summary.id) as? Budget else { return nil }
            let fetch = NSFetchRequest<PlannedExpense>(entityName: "PlannedExpense")
            let workspaceID = (budget.value(forKey: "workspaceID") as? UUID)
                ?? WorkspaceService.activeWorkspaceIDFromDefaults()
            guard let workspaceID else { return nil }
            fetch.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
                NSPredicate(format: "budget == %@", budget),
                NSPredicate(format: "transactionDate >= %@ AND transactionDate <= %@", range.lowerBound as NSDate, range.upperBound as NSDate),
                WorkspaceService.predicate(for: workspaceID)
            ])
            fetch.sortDescriptors = [NSSortDescriptor(key: "transactionDate", ascending: true)]
            fetch.fetchLimit = 25
            guard let expenses = try? bgContext.fetch(fetch), !expenses.isEmpty else { return nil }
            let next = expenses.first(where: { expense in
                let date = expense.transactionDate ?? range.upperBound
                return date >= anchorDate
            }) ?? expenses.last
            guard let next else { return nil }
            let title = HomeView.readPlannedDescription(next) ?? "Expense"
            let date = next.transactionDate ?? range.upperBound
            return PlannedExpenseSnapshot(
                budgetID: summary.id,
                expenseURI: next.objectID.uriRepresentation(),
                title: title,
                plannedAmount: next.plannedAmount,
                actualAmount: next.actualAmount,
                date: date
            )
        }
        await MainActor.run {
            nextPlannedSnapshot = snapshot
            updateNextPlannedExpenseWidget(snapshot: snapshot)
        }
    }

    private func updateNextPlannedExpenseWidget(snapshot: PlannedExpenseSnapshot?) {
        guard let snapshot else {
            WidgetSharedStore.clearNextPlannedExpenseSnapshot()
            return
        }
        let expense = fetchPlannedExpense(from: snapshot.expenseURI)
        let cardItem = detachedCardItem(from: expense?.card)
        let themeColors = cardItem?.theme.colors
        let primaryHex = themeColors.flatMap { colorToHex($0.0) }
        let secondaryHex = themeColors.flatMap { colorToHex($0.1) }
        let widgetSnapshot = WidgetSharedStore.NextPlannedExpenseSnapshot(
            title: snapshot.title,
            plannedAmount: snapshot.plannedAmount,
            actualAmount: snapshot.actualAmount,
            date: snapshot.date,
            cardName: cardItem?.name,
            cardThemeName: cardItem?.theme.rawValue,
            cardPrimaryHex: primaryHex,
            cardSecondaryHex: secondaryHex,
            cardPattern: nil,
            rangeLabel: widgetRangeLabel,
            updatedAt: Date()
        )
        WidgetSharedStore.writeNextPlannedExpenseSnapshot(widgetSnapshot)
    }

    private func colorToHex(_ color: Color) -> String? {
        #if canImport(UIKit)
        let uiColor = UIColor(color)
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        guard uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha) else { return nil }
        return String(
            format: "#%02X%02X%02X",
            Int(red * 255),
            Int(green * 255),
            Int(blue * 255)
        )
        #else
        return nil
        #endif
    }

    private func nextExpenseAnchorDate(for range: ClosedRange<Date>, selectedDate: Date) -> Date {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        if range.contains(today) {
            return today
        }
        let normalizedSelection = calendar.startOfDay(for: selectedDate)
        if range.contains(normalizedSelection) {
            return normalizedSelection
        }
        return calendar.startOfDay(for: range.lowerBound)
    }

    private func preferredFocusDate(in range: ClosedRange<Date>, selectedDate: Date) -> Date {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        if range.contains(today) {
            return today
        }
        if range.contains(selectedDate) {
            return calendar.startOfDay(for: selectedDate)
        }
        return calendar.startOfDay(for: range.lowerBound)
    }

    private func loadWidgetBuckets(for summary: BudgetSummary?) async {
        guard let summary else {
            await MainActor.run {
                widgetBuckets = []
                weekdayRangeOverride = nil
            }
            return
        }
        let range = currentRange
        let period = resolvedPeriod(vm.period, range: range)

        let totalsRange = period == .yearly ? fullYearRange(for: range.lowerBound) : range
        let dayTotals = await daySpendTotals(for: summary, in: totalsRange)

        let buckets: [SpendBucket]
        switch period {
        case .daily:
            buckets = bucketsForDays(in: range, dayTotals: dayTotals, includeAllWeekdays: false)
        case .weekly:
            buckets = bucketsForDays(in: range, dayTotals: dayTotals, includeAllWeekdays: true)
        case .biWeekly:
            let ranges = splitRange(range, daysPerBucket: 7)
            buckets = bucketsForRanges(ranges, dayTotals: dayTotals)
        case .monthly:
            let ranges = weeksInRange(range)
            buckets = bucketsForRanges(ranges, dayTotals: dayTotals)
        case .quarterly:
            buckets = bucketsForMonths(in: range, dayTotals: dayTotals)
        case .yearly:
            buckets = bucketsForMonths(in: totalsRange, dayTotals: dayTotals)
        case .custom:
            buckets = bucketsForDays(in: range, dayTotals: dayTotals, includeAllWeekdays: false)
        }

        await MainActor.run {
            widgetBuckets = buckets
            weekdayRangeOverride = range
        }
    }

    private func loadCards(for summary: BudgetSummary?) async {
        guard
            let summary,
            let budget = try? CoreDataService.shared.viewContext.existingObject(with: summary.id) as? Budget,
            let cards = budget.cards as? Set<Card>
        else {
            await MainActor.run { cardWidgets = [] }
            return
        }
        let sorted = cards
            .map { CardItem(from: $0) }
            .sorted { $0.name < $1.name }
        await MainActor.run { cardWidgets = sorted }
    }

    @MainActor
    private func loadAllCards() async {
        let range = currentRange
        let ctx = CoreDataService.shared.viewContext
        let req = NSFetchRequest<Card>(entityName: "Card")
        req.predicate = WorkspaceService.shared.activeWorkspacePredicate()
        req.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]
        let fetched = (try? ctx.fetch(req)) ?? []
        let items: [CardItem] = fetched.map { card in
            var item = CardItem(from: card)
            // Aggregate unplanned + planned actual expenses in the current range as balance.
            let expenseReq = NSFetchRequest<UnplannedExpense>(entityName: "UnplannedExpense")
            expenseReq.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
                NSPredicate(format: "card == %@", card),
                NSPredicate(format: "transactionDate >= %@ AND transactionDate <= %@", range.lowerBound as NSDate, range.upperBound as NSDate),
                WorkspaceService.shared.activeWorkspacePredicate()
            ])
            if let expenses = try? ctx.fetch(expenseReq) {
                let variableTotal = expenses.reduce(0) { $0 + $1.amount }
                var plannedTotal: Double = 0
                if let cardUUID = card.value(forKey: "id") as? UUID {
                    let plannedReq = NSFetchRequest<PlannedExpense>(entityName: "PlannedExpense")
                    plannedReq.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
                        NSPredicate(format: "card.id == %@ AND isGlobal == NO AND transactionDate >= %@ AND transactionDate <= %@",
                                    cardUUID as CVarArg, range.lowerBound as NSDate, range.upperBound as NSDate),
                        WorkspaceService.shared.activeWorkspacePredicate()
                    ])
                    if let planned = try? ctx.fetch(plannedReq) {
                        plannedTotal = planned.reduce(0) { $0 + $1.actualAmount }
                    }
                }
                item.balance = variableTotal + plannedTotal
            }
            return item
        }
        cardWidgets = items
    }

    private func loadCaps(for summary: BudgetSummary?) async {
        guard let summary else {
            await MainActor.run { capStatuses = [] }
            return
        }
        let caps = await fetchCapStatuses(for: summary)
        await MainActor.run { capStatuses = caps }
    }

    private func categoryAvailability(for summary: BudgetSummary, segment: CategoryAvailabilitySegment) -> [CategoryAvailability] {
        computeCategoryAvailability(summary: summary, caps: categoryCaps(for: summary), segment: segment)
    }

    fileprivate static func readPlannedDescription(_ object: NSManagedObject) -> String? {
        let keys = object.entity.attributesByName.keys
        if keys.contains("descriptionText") {
            return object.value(forKey: "descriptionText") as? String
        } else if keys.contains("title") {
            return object.value(forKey: "title") as? String
        }
        return nil
    }

    fileprivate static func readUnplannedDescription(_ object: NSManagedObject) -> String? {
        let keys = object.entity.attributesByName.keys
        if keys.contains("descriptionText") {
            return object.value(forKey: "descriptionText") as? String
        } else if keys.contains("title") {
            return object.value(forKey: "title") as? String
        }
        return nil
    }

    // MARK: Alerts
    private func alert(for alert: HomeViewAlert) -> Alert {
        switch alert.kind {
        case .error(let message):
            return Alert(title: Text("Error"), message: Text(message), dismissButton: .default(Text("OK")))
        case .confirmDelete(let id):
            return Alert(
                title: Text("Delete Budget?"),
                message: Text("This action cannot be undone."),
                primaryButton: .destructive(Text("Delete"), action: { Task { await vm.confirmDelete(budgetID: id) } }),
                secondaryButton: .cancel()
            )
        }
    }

    // MARK: Snapshot
    struct PlannedExpenseSnapshot: Identifiable, Hashable {
        let id = UUID()
        let budgetID: NSManagedObjectID
        let expenseURI: URL
        let title: String
        let plannedAmount: Double
        let actualAmount: Double
        let date: Date
    }
}

// MARK: - Metric Detail (stubbed metrics view)
private struct MetricDetailView: View {
    let title: String
    let kind: HomeView.HomeWidgetKind
    let range: ClosedRange<Date>
    let period: BudgetPeriod
    let summary: BudgetSummary
    let nextExpense: HomeView.PlannedExpenseSnapshot?
    let topCategory: BudgetSummary.CategorySpending?
    let capStatuses: [CapStatus]?

    // MARK: Local UI State
    @State private var showAllCategories: Bool = false
    @State private var expenseSeries: [DatedValue] = []
    @State private var actualIncomeSeries: [DatedValue] = []
    @State private var plannedIncomeSeries: [DatedValue] = []
    @State private var savingsSeries: [SavingsPoint] = []
    @State private var ratioSelection: DatedValue?
    @State private var selectedSpendBucket: SpendBucket?
    @State private var selectedSpendSectionID: UUID?
    @State private var savingsSelection: SavingsPoint?
    @State private var editingExpenseBox: ManagedIDBox?
    @State private var hasDeletedNextExpense = false
    @State private var incomeTimeline: [DatedValue] = []
    @State private var expectedTimeline: [DatedValue] = []
    @State private var timelineSelection: DatedValue?
    @State private var incomeBuckets: [IncomeBucket] = []
    @State private var comparisonPeriod: IncomeComparisonPeriod = .monthly
    @State private var latestIncomeID: NSManagedObjectID?
    @State private var showAddIncomeSheet = false
    @State private var editingIncomeBox: ManagedIDBox?
    @State private var spendSections: [SpendChartSection] = []
    @State private var expandedCategoryName: String? = nil
    @State private var expandedCategoryExpenses: [CategoryExpenseItem] = []
    @State private var expandedCategoryLoading: Bool = false
    @AppStorage("homeScenarioAllocations") private var scenarioAllocationsRaw: String = ""
    @State private var scenarioWidth: CGFloat = 0
    @AppStorage("homeAvailabilitySegment") private var detailAvailabilitySegmentRawValue: String = CategoryAvailabilitySegment.combined.rawValue
    @EnvironmentObject private var themeManager: ThemeManager
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @ScaledMetric(relativeTo: .body) private var legendDotSize: CGFloat = 12
    @ScaledMetric(relativeTo: .body) private var legendLineWidth: CGFloat = 18
    @ScaledMetric(relativeTo: .body) private var legendLineHeight: CGFloat = 3
    @ScaledMetric(relativeTo: .body) private var detailChartHeight: CGFloat = 200
    @ScaledMetric(relativeTo: .body) private var detailDayRowHeight: CGFloat = 28
    @ScaledMetric(relativeTo: .body) private var detailDayRowSpacing: CGFloat = 10
    private var detailAvailabilitySegment: CategoryAvailabilitySegment {
        CategoryAvailabilitySegment(rawValue: detailAvailabilitySegmentRawValue) ?? .combined
    }
    private var detailAvailabilitySegmentBinding: Binding<CategoryAvailabilitySegment> {
        Binding(
            get: { detailAvailabilitySegment },
            set: { detailAvailabilitySegmentRawValue = $0.rawValue }
        )
    }

    private var isLargeText: Bool {
        dynamicTypeSize >= .xxxLarge
    }

    private var isAccessibilitySize: Bool {
        isLargeText || dynamicTypeSize.isAccessibilitySize
    }

    private var resolvedDetailChartHeight: CGFloat {
        isAccessibilitySize ? detailChartHeight * 1.25 : detailChartHeight
    }

    private func condensedReceivedSeries() -> [DatedValue] {
        guard !incomeTimeline.isEmpty else { return [] }
        var events: [DatedValue] = []
        let start = DatedValue(date: range.lowerBound, value: 0)
        events.append(start)
        var lastValue: Double = 0
        for point in incomeTimeline.sorted(by: { $0.date < $1.date }) {
            if point.value != lastValue {
                events.append(point)
                lastValue = point.value
            }
        }
        if let last = events.last, last.date < range.upperBound {
            events.append(DatedValue(date: range.upperBound, value: last.value))
        }
        return events
    }

    private struct DatedValue: Identifiable {
        let date: Date
        let value: Double
        var id: Date { date }
    }

    private struct SavingsPoint: Identifiable {
        let date: Date
        let actual: Double
        let projected: Double
        var id: Date { date }
    }

    private struct CategoryExpenseItem: Identifiable {
        let id: NSManagedObjectID
        let title: String
        let amount: Double
        let date: Date?
        let card: Card?
    }

    private enum ExpenseIncomeSeries: String {
        case expenses = "Expenses"
        case actualIncome = "Actual Income"
        case plannedIncome = "Planned Income"
    }

    private struct ExpenseIncomePoint: Identifiable {
        let id = UUID()
        let date: Date
        let value: Double
        let series: ExpenseIncomeSeries
    }

    private struct ManagedIDBox: Identifiable {
        let id: NSManagedObjectID
    }

    private struct IncomeBucket: Identifiable {
        let id = UUID()
        let label: String
        let start: Date
        let total: Double
    }

    private enum IncomeComparisonPeriod: String, CaseIterable, Identifiable {
        case daily, weekly, biWeekly, monthly, quarterly, yearly
        var id: String { rawValue }
        var title: String {
            switch self {
            case .daily: return "Daily"
            case .weekly: return "Weekly"
            case .biWeekly: return "Bi-Weekly"
            case .monthly: return "Monthly"
            case .quarterly: return "Quarterly"
            case .yearly: return "Yearly"
            }
        }
    }

    var body: some View {
        content
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                if isAccessibilitySize {
                    ToolbarItem(placement: .principal) {
                        Text(title)
                            .font(.headline)
                            .lineLimit(nil)
                            .multilineTextAlignment(.center)
                    }
                }
            }
            .task { await loadSeriesIfNeeded() }
    }

    @ViewBuilder
    private var content: some View {
        if kind == .cards {
            nextExpenseList
        } else {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    detailContent
                }
                .padding()
            }
        }
    }

    // MARK: Sections
    @ViewBuilder
    private var detailContent: some View {
        switch kind {
        case .income:
            incomeContent
        case .expenseToIncome:
            expenseToIncomeContent
        case .savingsOutlook:
            savingsOutlookContent
        case .cards:
            nextExpenseContent
        case .presets:
            categoryContent
        case .budgets:
            budgetContent
        case .caps:
            capsContent
        case .dayOfWeek:
            weekdayContent
        case .availability:
            availabilityContent
        case .scenario:
            scenarioContent
        }
    }

    private var incomeContent: some View {
        let total = max(max(summary.potentialIncomeTotal, summary.actualIncomeTotal), 1)
        return VStack(alignment: .leading, spacing: 12) {
            incomeTimelineSection(total: total)
            incomeMoMSection
            quickIncomeActions
        }
    }

    private var weekdayContent: some View {
        let resolved = resolvedPeriod(period, range: range)
        return VStack(alignment: .leading, spacing: 12) {
            if spendSections.isEmpty {
                Text("No spending in this range.")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(spendSections) { section in
                    let orientation = isAccessibilitySize ? .horizontal : detailBarOrientation(for: resolved, bucketCount: section.buckets.count)
                    let maxAmount = max(section.buckets.map(\.amount).max() ?? 1, 1)
                    let rowCount = max(section.buckets.count, 1)
                    let rowHeight = isAccessibilitySize ? detailDayRowHeight * 1.25 : detailDayRowHeight
                    let stackedHeight = CGFloat(rowCount) * rowHeight + CGFloat(max(rowCount - 1, 0)) * detailDayRowSpacing
                    let chartHeight = orientation == .horizontal ? max(resolvedDetailChartHeight, stackedHeight) : resolvedDetailChartHeight
                    VStack(alignment: .leading, spacing: 8) {
                        Text(section.title)
                            .font(.subheadline.weight(.semibold))
                        if let subtitle = section.subtitle {
                            Text(subtitle)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Group {
                            if isAccessibilitySize {
                                Chart(section.buckets) { item in
                                    let norm = max(min(item.amount / maxAmount, 1), 0)
                                    let gradientColors = spendGradientColors(for: item, summary: summary, maxColors: 4)
                                    let gradient = LinearGradient(
                                        colors: gradientColors.map { $0.opacity(0.4 + 0.5 * norm) },
                                        startPoint: orientation == .horizontal ? .leading : .top,
                                        endPoint: orientation == .horizontal ? .trailing : .bottom
                                    )
                                    if orientation == .horizontal {
                                        BarMark(
                                            x: .value("Amount", item.amount),
                                            y: .value("Period", item.label)
                                        )
                                        .foregroundStyle(gradient)
                                        .cornerRadius(3)
                                    } else {
                                        BarMark(
                                            x: .value("Period", item.label),
                                            y: .value("Amount", item.amount)
                                        )
                                        .foregroundStyle(gradient)
                                        .cornerRadius(3)
                                    }
                                }
                                .chartXAxis(.hidden)
                                .chartYAxis {
                                    if orientation == .horizontal {
                                        AxisMarks(position: .leading, values: section.buckets.map(\.label)) { value in
                                            if let label = value.as(String.self) {
                                                AxisValueLabel {
                                                    Text(label)
                                                        .font(.caption2)
                                                        .lineLimit(2)
                                                        .fixedSize(horizontal: false, vertical: true)
                                                }
                                            } else {
                                                AxisValueLabel()
                                            }
                                        }
                                    }
                                }
                            } else {
                                Chart(section.buckets) { item in
                                    let norm = max(min(item.amount / maxAmount, 1), 0)
                                    let gradientColors = spendGradientColors(for: item, summary: summary, maxColors: 4)
                                    let gradient = LinearGradient(
                                        colors: gradientColors.map { $0.opacity(0.4 + 0.5 * norm) },
                                        startPoint: orientation == .horizontal ? .leading : .top,
                                        endPoint: orientation == .horizontal ? .trailing : .bottom
                                    )
                                    if orientation == .horizontal {
                                        BarMark(
                                            x: .value("Amount", item.amount),
                                            y: .value("Period", item.label)
                                        )
                                        .foregroundStyle(gradient)
                                        .cornerRadius(3)
                                    } else {
                                        BarMark(
                                            x: .value("Period", item.label),
                                            y: .value("Amount", item.amount)
                                        )
                                        .foregroundStyle(gradient)
                                        .cornerRadius(3)
                                    }
                                }
                                .chartOverlay { proxy in
                                    GeometryReader { geo in
                                        Rectangle().fill(.clear).contentShape(Rectangle())
                                            .simultaneousGesture(
                                                SpatialTapGesture()
                                                    .onEnded { value in
                                                        let origin = geo[proxy.plotAreaFrame].origin
                                                        let location = CGPoint(
                                                            x: value.location.x - origin.x,
                                                            y: value.location.y - origin.y
                                                        )
                                                        if orientation == .horizontal {
                                                            if let label: String = proxy.value(atY: location.y) {
                                                                toggleSpendSelection(in: section, label: label)
                                                            }
                                                        } else {
                                                            if let label: String = proxy.value(atX: location.x) {
                                                                toggleSpendSelection(in: section, label: label)
                                                            }
                                                        }
                                                    }
                                            )
                                    }
                                }
                                .chartYAxis {
                                    if orientation == .horizontal {
                                        AxisMarks(position: .leading, values: section.buckets.map(\.label)) { value in
                                    if let label = value.as(String.self) {
                                        AxisValueLabel {
                                            Text(label)
                                                .font(.caption2)
                                                .lineLimit(isAccessibilitySize ? 2 : 1)
                                                .fixedSize(horizontal: false, vertical: true)
                                        }
                                    } else {
                                        AxisValueLabel()
                                            }
                                        }
                                    } else {
                                        AxisMarks(position: .leading) { value in
                                            if let val = value.as(Double.self) {
                                                AxisGridLine()
                                                AxisTick()
                                                AxisValueLabel { axisCurrencyLabel(val) }
                                            }
                                        }
                                    }
                                }
                                .chartXAxis {
                                    if orientation == .horizontal {
                                        AxisMarks(position: .bottom) { value in
                                            if let val = value.as(Double.self) {
                                                AxisGridLine()
                                                AxisTick()
                                                AxisValueLabel { axisCurrencyLabel(val) }
                                            }
                                        }
                                    } else {
                                        AxisMarks(position: .bottom, values: section.buckets.map(\.label)) { value in
                                            if let label = value.as(String.self) {
                                                AxisTick()
                                                AxisValueLabel {
                                                    Text(String(label.prefix(1)))
                                                        .font(.caption2)
                                                        .lineLimit(1)
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        .frame(height: chartHeight)
                        .accessibilityElement(children: .ignore)
                        .accessibilityLabel("\(section.title) spending chart")
                        .accessibilityValue("Shows spending totals by period.")
                        if isAccessibilitySize {
                            HStack(spacing: 12) {
                                HStack(spacing: 6) {
                                    Circle()
                                        .fill(Color.secondary.opacity(0.7))
                                        .frame(width: 8, height: 8)
                                    Text("Day range")
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                }
                                HStack(spacing: 6) {
                                    LinearGradient(
                                        colors: [Color.blue.opacity(0.35), Color.blue.opacity(0.85)],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                    .frame(width: 22, height: 6)
                                    .clipShape(Capsule())
                                    Text("Amount spent")
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                        if selectedSpendSectionID == section.id, let bucket = selectedSpendBucket {
                            spendCategoryChips(for: bucket)
                        }
                        if let maxItem = section.buckets.max(by: { $0.amount < $1.amount }) {
                        Text("Highest: \(maxItem.label) • \(formatCurrency(maxItem.amount))")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .lineLimit(nil)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
            }
        }
    }

    private var capsContent: some View {
        let segment = detailAvailabilitySegment
        let filtered = (capStatuses ?? []).filter { $0.segment == segment }
        return VStack(alignment: .leading, spacing: 12) {
            Text("Category Caps & Alerts")
                .font(.ubSectionTitle)
                .lineLimit(nil)
                .fixedSize(horizontal: false, vertical: true)
            PillSegmentedControl(selection: detailAvailabilitySegmentBinding) {
                ForEach(CategoryAvailabilitySegment.allCases) { segment in
                    Text(segment.title).tag(segment)
                }
            }
            .ubSegmentedGlassStyle()
            .padding(.trailing, 6)
            if filtered.isEmpty {
                Text("No caps found for this range.")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(filtered) { cap in
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Circle().fill(cap.color).frame(width: legendDotSize, height: legendDotSize)
                            Text(cap.name)
                                .font(.ubDetailLabel.weight(.semibold))
                                .lineLimit(isAccessibilitySize ? nil : 1)
                                .fixedSize(horizontal: false, vertical: true)
                            Spacer()
                            if cap.over {
                                Text("Over")
                                    .font(.ubChip)
                                    .padding(6)
                                    .background(Color.red.opacity(0.12))
                                    .clipShape(Capsule())
                            } else if cap.near {
                                Text("Near")
                                    .font(.ubChip)
                                    .padding(6)
                                    .background(Color.orange.opacity(0.12))
                                    .clipShape(Capsule())
                            }
                        }
                        ProgressView(value: min(cap.amount / max(cap.cap, 1), 1))
                            .tint(cap.color)
                        HStack {
                            Text("Spent: \(formatCurrency(cap.amount))")
                                .font(.ubCaption)
                                .foregroundStyle(.secondary)
                            Spacer()
                            Text("Cap: \(formatCurrency(cap.cap))")
                                .font(.ubCaption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
    }


    private var expenseToIncomeContent: some View {
        let expenses = summary.plannedExpensesActualTotal + summary.variableExpensesTotal
        let expensePoints = expenseSeries.isEmpty ? twoPointSeries(value: expenses) : expenseSeries
        let incomePoints = actualIncomeSeries.isEmpty ? twoPointSeries(value: summary.actualIncomeTotal) : actualIncomeSeries
        let plannedPoints = plannedIncomeSeries.isEmpty ? twoPointSeries(value: summary.potentialIncomeTotal) : plannedIncomeSeries
        let remainingIncome = summary.actualIncomeTotal - expenses
        let plannedIncomePercent = summary.potentialIncomeTotal > 0
            ? (expenses / summary.potentialIncomeTotal) * 100
            : 0
        let actualIncomeRemainingPercent = summary.actualIncomeTotal > 0
            ? (remainingIncome / summary.actualIncomeTotal) * 100
            : 0
        return VStack(alignment: .leading, spacing: 16) {
            expenseIncomeChart(expensePoints: expensePoints, incomePoints: incomePoints, plannedPoints: plannedPoints)
            VStack(alignment: .leading, spacing: 8) {
                metricRow(label: "Expenses", value: formatCurrency(expenses))
                metricRow(label: "Actual Income", value: formatCurrency(summary.actualIncomeTotal))
                metricRow(label: "Planned Income", value: formatCurrency(summary.potentialIncomeTotal))
                metricRow(label: "Remaining Income", value: formatCurrency(remainingIncome))
                metricRow(label: "% of Planned Income Spent", value: String(format: "%.0f%%", plannedIncomePercent))
                metricRow(label: "% of Actual Income Remaining", value: String(format: "%.0f%%", actualIncomeRemainingPercent))
            }
        }
    }

    private var savingsOutlookContent: some View {
        let outlook = BudgetMetrics.savingsOutlook(
            actualSavings: summary.actualSavingsTotal,
            expectedIncome: summary.potentialIncomeTotal,
            incomeReceived: summary.actualIncomeTotal,
            plannedExpensesPlanned: summary.plannedExpensesPlannedTotal,
            plannedExpensesActual: summary.plannedExpensesActualTotal
        )
        let projected = outlook.projected
        let savingsPoints = savingsSeries.isEmpty ? fallbackSavingsSeries(projected: projected, actual: summary.actualSavingsTotal) : savingsSeries
        let actualSavings = summary.actualSavingsTotal

        return VStack(alignment: .leading, spacing: 16) {
            savingsChart(points: savingsPoints)
            VStack(alignment: .leading, spacing: 8) {
                metricRow(label: "Projected Savings", value: formatCurrency(projected))
                metricRow(label: "Actual Savings", value: formatCurrency(actualSavings))
                metricRow(label: "Remaining Income", value: formatCurrency(outlook.remainingIncome))
            }
        }
    }

    private var budgetContent: some View {
        expenseToIncomeContent
    }

    private var nextExpenseContent: some View {
        Group {
            if let nextExpense, !hasDeletedNextExpense {
                let expense = fetchPlannedExpense(from: nextExpense.expenseURI)
                NextPlannedDetailRow(
                    snapshot: nextExpense,
                    expense: expense,
                    onEdit: {
                        if let id = expense?.objectID {
                            editingExpenseBox = ManagedIDBox(id: id)
                        }
                    },
                    onDelete: {
                        deletePlannedExpense(expense)
                        withAnimation { hasDeletedNextExpense = true }
                    }
                )
            } else {
                Text("No planned expenses in this range.")
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var categoryContent: some View {
        Group {
            let allCategories = summary.categoryBreakdown
            let totalExpenses = allCategories.map(\.amount).reduce(0, +)
            let slices = categorySlices(from: allCategories, limit: showAllCategories ? allCategories.count : 3)
            if let leadingCategory = slices.first, !slices.isEmpty, totalExpenses > 0 {
                let totalForList = max(totalExpenses, 1)
                let topSlices = Array(slices.prefix(3))
                VStack(alignment: .leading, spacing: 12) {
                    CategoryDonutView(
                        slices: slices,
                        total: max(totalExpenses, 1),
                        centerTitle: isAccessibilitySize ? "" : leadingCategory.name,
                        centerValue: isAccessibilitySize ? "" : formatCurrency(leadingCategory.amount)
                    )
                    .frame(height: 220)
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Top Categories")
                            .font(.headline)
                        ForEach(Array(topSlices.indices), id: \.self) { idx in
                            let slice = topSlices[idx]
                            CategoryTopRow(slice: slice, total: max(totalExpenses, 1))
                        }
                    }
                    heatmapCategoryButton(title: showAllCategories ? "Hide All Categories" : "Show All Categories") {
                        withAnimation(.spring()) { showAllCategories.toggle() }
                    }
                    if showAllCategories {
                        categoriesCompactList(allCategories, total: totalForList)
                    }
                }
            } else {
                Text("No category data in this range.")
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var availabilityContent: some View {
        let segment = detailAvailabilitySegment
        let items = computeCategoryAvailability(summary: summary, caps: categoryCaps(for: summary), segment: segment)
        let rowSpacing: CGFloat = isAccessibilitySize ? 10 : 6
        let rowPadding: CGFloat = isAccessibilitySize ? 8 : 4
        return VStack(alignment: .leading, spacing: 12) {
            PillSegmentedControl(selection: detailAvailabilitySegmentBinding) {
                ForEach(CategoryAvailabilitySegment.allCases) { segment in
                    Text(segment.title).tag(segment)
                }
            }
            .ubSegmentedGlassStyle()
            .padding(.trailing, 6)
            if items.isEmpty {
                Text("No categories or caps available.")
                    .font(.ubBody)
                    .foregroundStyle(.secondary)
            } else {
                VStack(spacing: rowSpacing) {
                    ForEach(items) { item in
                        let isExpanded = expandedCategoryName == item.name
                        VStack(alignment: .leading, spacing: 6) {
                            Button {
                                toggleExpandedCategory(item)
                            } label: {
                                CategoryAvailabilityRow(item: item, currencyFormatter: formatCurrency)
                                    .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)

                        if isExpanded {
                            expandedCategoryExpensesView
                        }
                    }
                    .padding(rowPadding)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(isExpanded ? Color.primary.opacity(0.06) : Color.clear)
                    )
                }
            }
            }
        }
        .onChange(of: detailAvailabilitySegmentRawValue) { _ in
            guard let name = expandedCategoryName else { return }
            loadExpandedCategoryExpenses(categoryName: name, segment: detailAvailabilitySegment)
        }
    }

    private var scenarioContent: some View {
        let segment = CategoryAvailabilitySegment.variable
        let items = computeCategoryAvailability(summary: summary, caps: categoryCaps(for: summary), segment: segment)
        let remainingIncome = summary.actualSavingsTotal
        return VStack(alignment: .leading, spacing: 12) {
            if items.isEmpty {
                Text("No categories or caps available.")
                    .font(.ubBody)
                    .foregroundStyle(.secondary)
            } else {
                scenarioPlanner(items: items, remainingIncome: remainingIncome, segment: segment)
            }
        }
    }

    private func toggleExpandedCategory(_ item: CategoryAvailability) {
        if expandedCategoryName == item.name {
            expandedCategoryName = nil
            expandedCategoryExpenses = []
            expandedCategoryLoading = false
            return
        }
        expandedCategoryName = item.name
        loadExpandedCategoryExpenses(categoryName: item.name, segment: detailAvailabilitySegment)
    }

    private var expandedCategoryExpensesView: some View {
        Group {
            if expandedCategoryLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.leading, 22)
            } else if expandedCategoryExpenses.isEmpty {
                Text("No expenses in this range.")
                    .font(.ubCaption)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.leading, 22)
            } else {
                VStack(spacing: 8) {
                    ForEach(expandedCategoryExpenses) { expense in
                        categoryExpenseRow(expense)
                    }
                }
                .padding(.leading, 22)
            }
        }
    }

    private func categoryExpenseRow(_ expense: CategoryExpenseItem) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(expense.title)
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(isAccessibilitySize ? nil : 2)
                HStack(spacing: 6) {
                    categoryExpenseCardPreview(expense.card)
                    Text(expenseDateString(expense.date))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer(minLength: 8)
            Text(formatCurrency(expense.amount))
                .font(.subheadline.weight(.semibold))
                .monospacedDigit()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private func categoryExpenseCardPreview(_ card: Card?) -> some View {
        let symbolWidth: CGFloat = 14
        if let card {
            let theme: CardTheme = {
                if card.entity.attributesByName["theme"] != nil,
                   let raw = card.value(forKey: "theme") as? String,
                   let t = CardTheme(rawValue: raw) { return t }
                return .graphite
            }()
            RoundedRectangle(cornerRadius: 2, style: .continuous)
                .fill(theme.backgroundStyle(for: themeManager.selectedTheme))
                .overlay(theme.patternOverlay(cornerRadius: 2))
                .overlay(
                    RoundedRectangle(cornerRadius: 2, style: .continuous)
                        .stroke(Color.primary.opacity(0.18), lineWidth: 1)
                )
                .frame(width: 12, height: 8)
                .frame(width: symbolWidth, alignment: .leading)
        } else {
            RoundedRectangle(cornerRadius: 2, style: .continuous)
                .stroke(Color.primary.opacity(0.12), lineWidth: 1)
                .frame(width: 12, height: 8)
                .frame(width: symbolWidth, alignment: .leading)
        }
    }

    private func expenseDateString(_ date: Date?) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        guard let date else { return "No date" }
        return formatter.string(from: date)
    }

    private func loadExpandedCategoryExpenses(categoryName: String, segment: CategoryAvailabilitySegment) {
        expandedCategoryLoading = true
        Task {
            let items = await fetchCategoryExpenses(categoryName: categoryName, segment: segment)
            await MainActor.run {
                guard expandedCategoryName == categoryName else { return }
                expandedCategoryExpenses = items
                expandedCategoryLoading = false
            }
        }
    }

    private func fetchCategoryExpenses(categoryName: String, segment: CategoryAvailabilitySegment) async -> [CategoryExpenseItem] {
        let ctx = CoreDataService.shared.viewContext
        return await ctx.perform {
            guard let budget = try? ctx.existingObject(with: summary.id) as? Budget else { return [] }
            let catReq = NSFetchRequest<ExpenseCategory>(entityName: "ExpenseCategory")
            catReq.fetchLimit = 1
            let workspaceID = (budget.value(forKey: "workspaceID") as? UUID)
                ?? WorkspaceService.activeWorkspaceIDFromDefaults()
            guard let workspaceID else { return [] }
            catReq.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
                NSPredicate(format: "name ==[cd] %@", categoryName),
                WorkspaceService.predicate(for: workspaceID)
            ])
            guard let category = try? ctx.fetch(catReq).first else { return [] }

            var results: [CategoryExpenseItem] = []
            let start = range.lowerBound as NSDate
            let end = range.upperBound as NSDate

            if segment != .variable {
                let plannedReq = NSFetchRequest<PlannedExpense>(entityName: "PlannedExpense")
                plannedReq.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
                    NSPredicate(format: "budget == %@", budget),
                    NSPredicate(format: "isGlobal == NO"),
                    NSPredicate(format: "transactionDate >= %@ AND transactionDate <= %@", start, end),
                    NSPredicate(format: "expenseCategory == %@", category),
                    WorkspaceService.predicate(for: workspaceID)
                ])
                plannedReq.sortDescriptors = [NSSortDescriptor(key: "transactionDate", ascending: false)]
                if let planned = try? ctx.fetch(plannedReq) {
                    for exp in planned {
                        let title = HomeView.readPlannedDescription(exp) ?? "Expense"
                        let amount = exp.actualAmount != 0 ? exp.actualAmount : exp.plannedAmount
                        results.append(
                            CategoryExpenseItem(
                                id: exp.objectID,
                                title: title,
                                amount: amount,
                                date: exp.transactionDate,
                                card: exp.card
                            )
                        )
                    }
                }
            }

            if segment != .planned, let cards = budget.cards as? Set<Card>, !cards.isEmpty {
                let varReq = NSFetchRequest<UnplannedExpense>(entityName: "UnplannedExpense")
                varReq.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
                    NSPredicate(format: "card IN %@", cards as NSSet),
                    NSPredicate(format: "transactionDate >= %@ AND transactionDate <= %@", start, end),
                    NSPredicate(format: "expenseCategory == %@", category),
                    WorkspaceService.predicate(for: workspaceID)
                ])
                varReq.sortDescriptors = [NSSortDescriptor(key: "transactionDate", ascending: false)]
                if let vars = try? ctx.fetch(varReq) {
                    for exp in vars {
                        let title = HomeView.readUnplannedDescription(exp) ?? "Expense"
                        results.append(
                            CategoryExpenseItem(
                                id: exp.objectID,
                                title: title,
                                amount: exp.amount,
                                date: exp.transactionDate,
                                card: exp.card
                            )
                        )
                    }
                }
            }

            return results.sorted { lhs, rhs in
                switch (lhs.date, rhs.date) {
                case let (l?, r?): return l > r
                case (nil, _?): return false
                case (_?, nil): return true
                default: return lhs.title.localizedCaseInsensitiveCompare(rhs.title) == .orderedAscending
                }
            }
        }
    }

    @ViewBuilder
    private func scenarioPlanner(items: [CategoryAvailability], remainingIncome: Double, segment: CategoryAvailabilitySegment) -> some View {
        let totalAllocated = items.reduce(0) { $0 + allocationValue(for: $1, segment: segment) }
        let potentialSavings = remainingIncome - totalAllocated
        let slices = scenarioSlices(items: items, savings: potentialSavings, segment: segment)
        let savingsBase = Color.green
        let savingsColor = potentialSavings >= 0 ? savingsBase : Color.red.opacity(0.85)
        let savingsTextStyle = savingsColor

        VStack(alignment: .leading, spacing: 12) {
            Divider().padding(.top, 4)
            Text("Adjust category allocations to see how much you could still save.")
                .font(.ubBody)
                .foregroundStyle(.secondary)

            Group {
                if isAccessibilitySize {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(potentialSavings >= 0 ? "Potential Savings" : "Over-allocated")
                            .font(.ubDetailLabel.weight(.semibold))
                            .lineLimit(nil)
                            .fixedSize(horizontal: false, vertical: true)
                        Text(formatCurrency(potentialSavings))
                            .font(.ubMetricValue)
                            .foregroundStyle(savingsTextStyle)
                            .shadow(color: Color.primary.opacity(0.08), radius: 1, x: 0, y: 1)
                    }
                } else {
                    HStack {
                        Text(potentialSavings >= 0 ? "Potential Savings" : "Over-allocated")
                            .font(.ubDetailLabel.weight(.semibold))
                        Spacer()
                        Text(formatCurrency(potentialSavings))
                            .font(.ubMetricValue)
                            .foregroundStyle(savingsTextStyle)
                            .shadow(color: Color.primary.opacity(0.08), radius: 1, x: 0, y: 1)
                    }
                }
            }
            Group {
                if #available(iOS 26.0, macOS 26.0, macCatalyst 26.0, *) {
                    Button("Clear") { scenarioAllocationsRaw = "" }
                        .font(.ubCaption.weight(.semibold))
                        .padding(.vertical, 6)
                        .padding(.horizontal, 12)
                        .glassEffect(.regular, in: .capsule)
                        .buttonStyle(.plain)
                } else {
                    Button("Clear") { scenarioAllocationsRaw = "" }
                        .font(.ubCaption.weight(.semibold))
                        .buttonStyle(.plain)
                }
            }
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .disabled(scenarioAllocations.isEmpty)
            .opacity(scenarioAllocations.isEmpty ? 0.5 : 1)

            let width = scenarioWidth > 0 ? scenarioWidth : scenarioPlannerDefaultWidth()
            let donutSize = isAccessibilitySize
                ? min(max(width * 0.5, 220), 360)
                : min(max(width * 0.38, 180), 320)
            let stackedDonutSize = isAccessibilitySize
                ? min(max(width * 0.7, 260), 360)
                : min(max(width * 0.55, 200), 320)
            let listWidth = max(width - donutSize - 16, width * 0.48)

            ViewThatFits(in: .horizontal) {
                HStack(alignment: .top, spacing: 16) {
                CategoryDonutView(
                    slices: slices,
                    total: max(slices.map(\.amount).reduce(0, +), 1),
                    centerTitle: isAccessibilitySize ? "" : (potentialSavings >= 0 ? "Potential Savings" : "Deficit"),
                    centerValue: isAccessibilitySize ? "" : formatCurrency(potentialSavings),
                    savingsColor: savingsColor,
                    centerValueColor: savingsTextStyle
                )
                    .frame(width: donutSize, height: donutSize)
                    .frame(minWidth: 0, alignment: .leading)

                    VStack(spacing: 10) {
                        ForEach(items) { item in
                            scenarioAllocationRow(item: item, segment: segment)
                        }
                    }
                    .frame(width: listWidth, alignment: .leading)
                }

                VStack(alignment: .leading, spacing: 16) {
                    CategoryDonutView(
                        slices: slices,
                        total: max(slices.map(\.amount).reduce(0, +), 1),
                        centerTitle: isAccessibilitySize ? "" : (potentialSavings >= 0 ? "Potential Savings" : "Deficit"),
                        centerValue: isAccessibilitySize ? "" : formatCurrency(potentialSavings),
                        savingsColor: savingsColor,
                        centerValueColor: savingsTextStyle
                    )
                    .frame(width: stackedDonutSize, height: stackedDonutSize)
                    .frame(maxWidth: .infinity, alignment: .center)

                    VStack(spacing: 10) {
                        ForEach(items) { item in
                            scenarioAllocationRow(item: item, segment: segment)
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .frame(minHeight: 300, alignment: .top)
            .background(
                GeometryReader { geo in
                    Color.clear
                        .preference(key: ScenarioPlannerWidthPreferenceKey.self, value: geo.size.width)
                }
            )
            .onPreferenceChange(ScenarioPlannerWidthPreferenceKey.self) { scenarioWidth = $0 }
        }
    }

    private func scenarioAllocationRow(item: CategoryAvailability, segment: CategoryAvailabilitySegment) -> some View {
        let binding = allocationBinding(for: item, segment: segment)

        return VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .firstTextBaseline) {
                HStack(spacing: 6) {
                    Circle().fill(item.color).frame(width: legendDotSize, height: legendDotSize)
                    Text(item.name)
            }
                .font(.ubDetailLabel.weight(.semibold))
                .lineLimit(isAccessibilitySize ? nil : 1)
            }
            ViewThatFits(in: .horizontal) {
                HStack(spacing: 12) {
                    TextField("0", value: binding, formatter: allocationFormatter)
                        .textFieldStyle(.roundedBorder)
                        .keyboardType(.decimalPad)
                        .frame(minWidth: 100, maxWidth: 160, alignment: .leading)
                    Spacer()
                    Stepper("", value: binding, in: 0...1_000_000, step: 25)
                        .labelsHidden()
                }

                VStack(alignment: .leading, spacing: 8) {
                    TextField("0", value: binding, formatter: allocationFormatter)
                        .textFieldStyle(.roundedBorder)
                        .keyboardType(.decimalPad)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Stepper("", value: binding, in: 0...1_000_000, step: 25)
                        .labelsHidden()
                }
            }
        }
    }

    private func scenarioKey(for item: CategoryAvailability, segment: CategoryAvailabilitySegment) -> String {
        scenarioKeyPrefix(for: segment) + normalizeCategoryName(item.name)
    }

    private func scenarioKeyPrefix(for segment: CategoryAvailabilitySegment) -> String {
        "\(segment.rawValue)|"
    }

    private func allocationValue(for item: CategoryAvailability, segment: CategoryAvailabilitySegment) -> Double {
        let key = scenarioKey(for: item, segment: segment)
        return scenarioAllocations[key] ?? 0
    }

    private func allocationBinding(for item: CategoryAvailability, segment: CategoryAvailabilitySegment) -> Binding<Double> {
        let key = scenarioKey(for: item, segment: segment)
        return Binding(
            get: { allocationValue(for: item, segment: segment) },
            set: { newValue in
                var next = scenarioAllocations
                next[key] = max(newValue, 0)
                scenarioAllocationsRaw = encodeScenarioAllocations(next)
            }
        )
    }

    private func scenarioPlannerDefaultWidth() -> CGFloat {
        #if canImport(UIKit)
        return UIScreen.main.bounds.width - 48
        #elseif os(macOS)
        return NSScreen.main?.frame.width ?? 900
        #else
        return 600
        #endif
    }

    private struct ScenarioPlannerWidthPreferenceKey: PreferenceKey {
        static var defaultValue: CGFloat = 0
        static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
            value = nextValue()
        }
    }

    private var scenarioAllocations: [String: Double] {
        decodeScenarioAllocations(from: scenarioAllocationsRaw)
    }

private func scenarioSlices(items: [CategoryAvailability], savings: Double, segment: CategoryAvailabilitySegment) -> [CategorySlice] {
    var slices: [CategorySlice] = items.compactMap { item in
        let allocation = allocationValue(for: item, segment: segment)
        let amount = item.spent + allocation
        guard amount > 0 else { return nil }
        return CategorySlice(
            name: item.name,
            amount: amount,
            color: item.color
        )
    }
    if savings > 0 {
        slices.append(CategorySlice(name: "Savings", amount: savings, color: scenarioAverageColor(for: items)))
    } else if savings < 0 {
        slices.append(CategorySlice(name: "Deficit", amount: abs(savings), color: Color.red.opacity(0.8)))
    }
    if slices.isEmpty {
        slices.append(CategorySlice(name: "No Allocations", amount: 1, color: Color.secondary.opacity(0.3)))
    }
    return slices
}

private func scenarioGradient(for items: [CategoryAvailability]) -> AngularGradient? {
    let colors = items.map { $0.color }
    let limited = Array(colors.prefix(6))
    guard limited.count >= 2 else { return nil }
    return AngularGradient(gradient: Gradient(colors: limited), center: .center)
}

private func scenarioAverageColor(for items: [CategoryAvailability]) -> Color {
    let colors = items.map { $0.color }
    guard !colors.isEmpty else { return HomeView.HomePalette.income }
    #if canImport(UIKit)
    let comps = colors.compactMap { UIColor($0).cgColor.components }.filter { !$0.isEmpty }
    #elseif os(macOS)
    let comps = colors.compactMap { NSColor($0).usingColorSpace(.sRGB)?.cgColor.components }.filter { !$0.isEmpty }
    #else
    let comps: [[CGFloat]] = []
    #endif
    guard !comps.isEmpty else { return HomeView.HomePalette.income }
    let avg = comps.reduce([0.0, 0.0, 0.0, 0.0]) { acc, c in
        var next = acc
        next[0] += Double(c[0])
        next[1] += Double(c.count > 1 ? c[1] : c[0])
        next[2] += Double(c.count > 2 ? c[2] : c[0])
        next[3] += Double(c.count > 3 ? c[3] : 1)
        return next
    }
    let count = Double(comps.count)
    return Color(
        red: avg[0] / count,
        green: avg[1] / count,
        blue: avg[2] / count,
        opacity: avg[3] / count
    )
}

fileprivate func decodeScenarioAllocations(from raw: String) -> [String: Double] {
    guard !raw.isEmpty else { return [:] }
    var result: [String: Double] = [:]
    for pair in raw.split(separator: "&") {
        let parts = pair.split(separator: "=", maxSplits: 1)
        guard parts.count == 2 else { continue }
        let key = String(parts[0]).removingPercentEncoding ?? String(parts[0])
        let value = Double(parts[1]) ?? 0
        result[key] = value
    }
    return result
}

fileprivate func encodeScenarioAllocations(_ values: [String: Double]) -> String {
    values
        .map {
            let key = $0.key.addingPercentEncoding(withAllowedCharacters: .alphanumerics) ?? $0.key
            return "\(key)=\($0.value)"
        }
        .sorted()
        .joined(separator: "&")
}

    private var allocationFormatter: NumberFormatter {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        if #available(iOS 16.0, macCatalyst 16.0, *) {
            formatter.currencyCode = Locale.current.currency?.identifier ?? "USD"
        } else {
            formatter.currencyCode = Locale.current.currencyCode ?? "USD"
        }
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 2
        return formatter
    }

    // MARK: Helpers
    private func metricRow(label: String, value: String) -> some View {
        Group {
            if isAccessibilitySize {
                VStack(alignment: .leading, spacing: 4) {
                    Text(label)
                        .font(.ubBody)
                        .foregroundStyle(.secondary)
                        .lineLimit(nil)
                        .fixedSize(horizontal: false, vertical: true)
                    Text(value)
                        .font(.ubMetricValue)
                        .lineLimit(nil)
                        .fixedSize(horizontal: false, vertical: true)
                }
            } else {
                HStack {
                    Text(label)
                        .font(.ubBody)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.9)
                    Spacer()
                    Text(value)
                        .font(.ubMetricValue)
                }
            }
        }
    }

    private enum LegendSymbol {
        case dot
        case line
    }

    private func legendRow(label: String, color: Color, symbol: LegendSymbol) -> some View {
        HStack(spacing: 6) {
            legendSymbolView(symbol: symbol, color: color)
            Text(label)
                .font(.caption)
                .foregroundStyle(color)
                .lineLimit(nil)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    @ViewBuilder
    private func legendSymbolView(symbol: LegendSymbol, color: Color) -> some View {
        switch symbol {
        case .dot:
            Circle()
                .fill(color)
                .frame(width: legendDotSize, height: legendDotSize)
        case .line:
            let lineHeight = max(2, legendLineHeight)
            RoundedRectangle(cornerRadius: lineHeight / 2, style: .continuous)
                .fill(color)
                .frame(width: legendLineWidth, height: lineHeight)
        }
    }

    private func axisCurrencyLabel(_ value: Double) -> some View {
        Text(formatCurrency(value))
            .font(.caption2)
            .lineLimit(1)
            .minimumScaleFactor(isAccessibilitySize ? 0.6 : 0.8)
    }

    private func axisCurrencyLabelCompact(_ value: Double) -> some View {
        Text(formatAxisCurrency(value, compact: true))
            .font(.caption2)
            .lineLimit(1)
            .minimumScaleFactor(isAccessibilitySize ? 0.5 : 0.8)
    }

    private func axisDateLabel(_ date: Date) -> some View {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return Text(formatter.string(from: date))
            .font(.caption2)
            .lineLimit(2)
            .fixedSize(horizontal: false, vertical: true)
    }

    private func formatAxisCurrency(_ value: Double, compact: Bool) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        if #available(iOS 16.0, macCatalyst 16.0, *) {
            formatter.currencyCode = Locale.current.currency?.identifier ?? "USD"
        } else {
            formatter.currencyCode = Locale.current.currencyCode ?? "USD"
        }
        formatter.maximumFractionDigits = 0
        formatter.minimumFractionDigits = 0
        formatter.usesGroupingSeparator = !compact
        return formatter.string(from: value as NSNumber) ?? formatCurrency(value)
    }

    // MARK: Income Sections
    private func incomeTimelineSection(total: Double) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Spacer()
                paceBadge(total: total)
            }
            timelineChart
            HStack(spacing: 12) {
                metricRow(label: "Received", value: formatCurrency(summary.actualIncomeTotal))
                metricRow(label: "Planned", value: formatCurrency(summary.potentialIncomeTotal))
            }
        }
    }

    private func paceBadge(total: Double) -> some View {
        let dates = allDates(in: range)
        let daysElapsed = dates.filter { $0 <= startOfDay(Date()) }.count
        let progress = Double(daysElapsed) / Double(max(dates.count, 1))
        let expectedSoFar = expectedIncomeSoFar(progressFallback: progress, on: Date())
        let status: String
        if summary.actualIncomeTotal >= expectedSoFar * 1.02 {
            status = "Ahead"
        } else if summary.actualIncomeTotal >= expectedSoFar * 0.98 {
            status = "On Pace"
        } else {
            status = "Behind"
        }
        return Text(status)
            .font(.ubChip)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                Capsule().fill(HomeView.HomePalette.income.opacity(0.15))
            )
    }

    // MARK: Category Heatmap Button
    private func heatmapCategoryButton(title: String, action: @escaping () -> Void) -> some View {
        let shape26 = Capsule()
        let shapeLegacy = RoundedRectangle(cornerRadius: 10, style: .continuous)
        let gradientColors = categoryHeatmapColors

        @ViewBuilder
        func heatmapBackground<S: Shape>(for shape: S) -> some View {
            ZStack {
                Color.primary.opacity(0.02)
                if let gradientColors {
                    LinearGradient(
                        gradient: Gradient(colors: gradientColors),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .opacity(0.24)
                    AngularGradient(
                        gradient: Gradient(colors: gradientColors.reversed()),
                        center: .center,
                        startAngle: .degrees(-80),
                        endAngle: .degrees(280)
                    )
                    .opacity(0.14)
                    .blur(radius: 14)
                    .scaleEffect(1.05)
                    RadialGradient(
                        gradient: Gradient(colors: gradientColors.map { $0.opacity(0.35) }),
                        center: .center,
                        startRadius: 4,
                        endRadius: 140
                    )
                    .opacity(0.12)
                } else {
                    Color.accentColor.opacity(0.18)
                }
            }
            .clipShape(shape)
        }

        let label = Text(title)
            .font(.headline.weight(.bold))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .foregroundStyle(Color.primary.opacity(0.9))

        return Group {
            if #available(iOS 26.0, macCatalyst 26.0, *) {
                Button(action: action) {
                    label
                }
                .buttonStyle(.glassProminent)
                .tint(.clear)
                .background(heatmapBackground(for: shape26))
            } else {
                Button(action: action) {
                    label
                }
                .buttonStyle(.plain)
                .background(heatmapBackground(for: shapeLegacy))
                .overlay(shapeLegacy.stroke(Color.primary.opacity(0.08), lineWidth: 1))
            }
        }
    }

    private var categoryHeatmapColors: [Color]? {
        let rawColors = summary.categoryBreakdown.compactMap { UBColorFromHex($0.hexColor) }
        let limited = Array(rawColors.prefix(12))
        guard !limited.isEmpty else { return nil }
        return softenedHeatmapColors(from: limited)
    }

    private func softenedHeatmapColors(from colors: [Color]) -> [Color] {
        colors.map(softenHeatmapColor)
    }

    private func softenHeatmapColor(_ color: Color) -> Color {
        #if canImport(UIKit)
        let ui = UIColor(color)
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        if ui.getRed(&r, green: &g, blue: &b, alpha: &a) {
            let mix: CGFloat = 0.30 // blend toward a light neutral to reduce harshness
            let nr = r * (1 - mix) + mix
            let ng = g * (1 - mix) + mix
            let nb = b * (1 - mix) + mix
            let na = a * 0.9
            return Color(red: Double(nr), green: Double(ng), blue: Double(nb), opacity: Double(na))
        }
        #elseif os(macOS)
        if let ns = NSColor(color).usingColorSpace(.sRGB) {
            let r = ns.redComponent, g = ns.greenComponent, b = ns.blueComponent, a = ns.alphaComponent
            let mix: CGFloat = 0.30
            let nr = r * (1 - mix) + mix
            let ng = g * (1 - mix) + mix
            let nb = b * (1 - mix) + mix
            let na = a * 0.9
            return Color(red: Double(nr), green: Double(ng), blue: Double(nb), opacity: Double(na))
        }
        #endif
        return color.opacity(0.85)
    }

    @ViewBuilder
    private var timelineChart: some View {
        if incomeTimeline.isEmpty {
            Text("No income in this range.")
                .foregroundStyle(.secondary)
        } else {
            let plannedLineColor = HomeView.HomePalette.income
            let actualLineColor = Color.gray
            let receiptColor = Color.green

            let plannedSeries = expectedTimeline.isEmpty ? fallbackExpectedSeries() : expectedTimeline
            let receiptPoints = receiptPoints(from: incomeTimeline)
            let actualLineSeries = actualIncomeLineSeries(from: receiptPoints)
            let latestPlanned = plannedSeries.last?.value
            let latestActual = actualLineSeries.last?.value

            let maxVal = max((actualLineSeries.map(\.value).max() ?? 0), (plannedSeries.map(\.value).max() ?? 0), 1)
            let domain: ClosedRange<Double> = 0...(maxVal * 1.1)
            VStack(alignment: .leading, spacing: 8) {
                Group {
                    if isAccessibilitySize {
                        Chart {
                            ForEach(plannedSeries) { point in
                                LineMark(
                                    x: .value("Date", point.date),
                                    y: .value("Planned Income", point.value)
                                )
                                .interpolationMethod(.linear)
                                .foregroundStyle(by: .value("Series", "Planned Income"))
                                .lineStyle(StrokeStyle(lineWidth: 3, lineCap: .round))
                            }
                            ForEach(actualLineSeries) { point in
                                LineMark(
                                    x: .value("Date", point.date),
                                    y: .value("Actual Income", point.value)
                                )
                                .interpolationMethod(.linear)
                                .foregroundStyle(by: .value("Series", "Actual Income"))
                                .lineStyle(StrokeStyle(lineWidth: 2, lineCap: .round, dash: [6, 4]))
                            }
                            ForEach(receiptPoints) { point in
                                PointMark(
                                    x: .value("Date", point.date),
                                    y: .value("Received", point.value)
                                )
                                .symbolSize(18)
                                .foregroundStyle(receiptColor)
                            }
                        }
                        .chartYScale(domain: domain)
                        .chartLegend(.hidden)
                        .chartForegroundStyleScale([
                            "Planned Income": plannedLineColor,
                            "Actual Income": actualLineColor.opacity(0.9)
                        ])
                        .chartXAxis(.hidden)
                        .chartYAxis(.hidden)
                        .frame(height: resolvedDetailChartHeight)
                    } else {
                        Chart {
                            ForEach(plannedSeries) { point in
                                LineMark(
                                    x: .value("Date", point.date),
                                    y: .value("Planned Income", point.value)
                                )
                                .interpolationMethod(.linear)
                                .foregroundStyle(by: .value("Series", "Planned Income"))
                                .lineStyle(StrokeStyle(lineWidth: 3, lineCap: .round))
                            }
                            ForEach(actualLineSeries) { point in
                                LineMark(
                                    x: .value("Date", point.date),
                                    y: .value("Actual Income", point.value)
                                )
                                .interpolationMethod(.linear)
                                .foregroundStyle(by: .value("Series", "Actual Income"))
                                .lineStyle(StrokeStyle(lineWidth: 2, lineCap: .round, dash: [6, 4]))
                            }
                            ForEach(receiptPoints) { point in
                                PointMark(
                                    x: .value("Date", point.date),
                                    y: .value("Received", point.value)
                                )
                                .symbolSize(18)
                                .foregroundStyle(receiptColor)
                            }
                            if let selected = timelineSelection {
                                RuleMark(x: .value("Selected", selected.date))
                                    .foregroundStyle(.gray.opacity(0.35))
                                    .annotation(position: .topLeading) {
                                        Text(formatCurrency(selected.value))
                                            .font(.caption2)
                                    }
                            }
                        }
                        .chartYScale(domain: domain)
                        .chartLegend(.hidden)
                        .chartForegroundStyleScale([
                            "Planned Income": plannedLineColor,
                            "Actual Income": actualLineColor.opacity(0.9)
                        ])
                        .chartXAxis {
                            AxisMarks(values: .automatic(desiredCount: 3)) { value in
                                if let date = value.as(Date.self) {
                                    AxisValueLabel { axisDateLabel(date) }
                                } else {
                                    AxisValueLabel()
                                }
                            }
                        }
                        .chartYAxis {
                            AxisMarks(position: .leading) { value in
                                if let val = value.as(Double.self) {
                                    AxisGridLine()
                                    AxisTick()
                                    AxisValueLabel { axisCurrencyLabelCompact(val) }
                                }
                            }
                        }
                        .frame(height: resolvedDetailChartHeight)
                        .chartOverlay { proxy in
                            GeometryReader { geo in
                                Rectangle().fill(.clear).contentShape(Rectangle())
                                    .gesture(
                                        DragGesture(minimumDistance: 0)
                                            .onChanged { gesture in
                                                let origin = geo[proxy.plotAreaFrame].origin
                                                let locationX = gesture.location.x - origin.x
                                                if let date: Date = proxy.value(atX: locationX) {
                                                    timelineSelection = nearestPoint(in: actualLineSeries, to: date)
                                                }
                                            }
                                            .onEnded { _ in timelineSelection = nil }
                                    )
                            }
                        }
                    }
                }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("Income timeline chart")
                .accessibilityValue("Shows planned income and actual income over time.")

                if isAccessibilitySize {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Range: \(dateString(range.lowerBound)) – \(dateString(range.upperBound))")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(nil)
                            .fixedSize(horizontal: false, vertical: true)
                        if let latestPlanned {
                            Text("Planned: \(formatCurrency(latestPlanned))")
                                .font(.caption)
                                .foregroundStyle(plannedLineColor)
                                .lineLimit(nil)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        if let latestActual {
                            Text("Actual: \(formatCurrency(latestActual))")
                                .font(.caption)
                                .foregroundStyle(actualLineColor.opacity(0.9))
                                .lineLimit(nil)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }

                if let selected = timelineSelection {
                    Text("\(dateString(selected.date)) • \(formatCurrency(selected.value))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(nil)
                        .fixedSize(horizontal: false, vertical: true)
                } else {
                    Group {
                        if isAccessibilitySize {
                            VStack(alignment: .leading, spacing: 6) {
                                legendRow(label: "Planned Income", color: plannedLineColor, symbol: .dot)
                                legendRow(label: "Actual Income", color: actualLineColor.opacity(0.9), symbol: .dot)
                            }
                        } else {
                            HStack(spacing: 16) {
                                legendRow(label: "Planned Income", color: plannedLineColor, symbol: .dot)
                                legendRow(label: "Actual Income", color: actualLineColor.opacity(0.9), symbol: .dot)
                            }
                        }
                    }
                }
            }
        }
    }

    private var incomeMoMSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            ViewThatFits(in: .horizontal) {
                HStack {
                    Text("Trends")
                        .font(.ubSectionTitle)
                        .lineLimit(nil)
                        .fixedSize(horizontal: false, vertical: true)
                    Spacer()
                    Picker("Period", selection: $comparisonPeriod) {
                        ForEach(IncomeComparisonPeriod.allCases) { period in
                            Text(period.title).tag(period)
                        }
                    }
                    .pickerStyle(.menu)
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Trends")
                        .font(.ubSectionTitle)
                        .lineLimit(nil)
                        .fixedSize(horizontal: false, vertical: true)
                    Picker("Period", selection: $comparisonPeriod) {
                        ForEach(IncomeComparisonPeriod.allCases) { period in
                            Text(period.title).tag(period)
                        }
                    }
                    .pickerStyle(.menu)
                }
            }
            if incomeBuckets.isEmpty {
                Text("No income history for this period size.")
                    .foregroundStyle(.secondary)
            } else {
                let latestBucket = incomeBuckets.last
                Group {
                    if isAccessibilitySize {
                        Chart(incomeBuckets) { bucket in
                            BarMark(
                                x: .value("Period", bucket.label),
                                y: .value("Total", bucket.total)
                            )
                            .foregroundStyle(HomeView.HomePalette.income.opacity(0.8))
                        }
                        .chartXAxis(.hidden)
                        .chartYAxis(.hidden)
                        .frame(height: resolvedDetailChartHeight * 0.9)
                        .accessibilityElement(children: .ignore)
                        .accessibilityLabel("Income trends chart")
                        .accessibilityValue("Shows income totals by period.")

                        VStack(alignment: .leading, spacing: 4) {
                            Text("Period: \(comparisonPeriod.title)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .lineLimit(nil)
                                .fixedSize(horizontal: false, vertical: true)
                            if let latestBucket {
                                Text("Latest: \(latestBucket.label) • \(formatCurrency(latestBucket.total))")
                                    .font(.caption)
                                    .foregroundStyle(HomeView.HomePalette.income)
                                    .lineLimit(nil)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                    } else {
                        Chart(incomeBuckets) { bucket in
                            BarMark(
                                x: .value("Period", bucket.label),
                                y: .value("Total", bucket.total)
                            )
                            .foregroundStyle(HomeView.HomePalette.income.opacity(0.8))
                        }
                        .chartXAxis {
                            AxisMarks(values: .automatic(desiredCount: 4)) { value in
                                if let label = value.as(String.self) {
                                    AxisValueLabel {
                                        Text(label)
                                            .font(.caption2)
                                            .lineLimit(2)
                                            .fixedSize(horizontal: false, vertical: true)
                                    }
                                } else {
                                    AxisValueLabel()
                                }
                            }
                        }
                        .chartYAxis {
                            AxisMarks(position: .leading) { value in
                                if let val = value.as(Double.self) {
                                    AxisGridLine()
                                    AxisTick()
                                    AxisValueLabel { axisCurrencyLabel(val) }
                                }
                            }
                        }
                        .frame(height: resolvedDetailChartHeight * 0.9)
                        .accessibilityElement(children: .ignore)
                        .accessibilityLabel("Income trends chart")
                        .accessibilityValue("Shows income totals by period.")
                    }
                }
            }
        }
    }

    private var quickIncomeActions: some View {
        Group {
            if isAccessibilitySize {
                VStack(alignment: .leading, spacing: 10) {
                    addIncomeButton
                    editLatestButton
                }
            } else {
                HStack(spacing: 12) {
                    addIncomeButton
                    editLatestButton
                }
            }
        }
        .sheet(isPresented: $showAddIncomeSheet) {
            AddIncomeFormView(incomeObjectID: nil, budgetObjectID: nil, initialDate: nil)
                .environment(\.managedObjectContext, CoreDataService.shared.viewContext)
        }
        .sheet(item: $editingIncomeBox) { box in
            AddIncomeFormView(incomeObjectID: box.id, budgetObjectID: nil, initialDate: nil)
                .environment(\.managedObjectContext, CoreDataService.shared.viewContext)
        }
    }

    private var addIncomeButton: some View {
        Button {
            showAddIncomeSheet = true
        } label: {
            Label("Add Income", systemImage: "plus.circle.fill")
                .font(.subheadline.weight(.semibold))
        }
        .buttonStyle(.borderedProminent)
        .tint(HomeView.HomePalette.income)
    }

    private var editLatestButton: some View {
        Button {
            if let id = latestIncomeID {
                editingIncomeBox = ManagedIDBox(id: id)
            }
        } label: {
            Label("Edit Latest", systemImage: "pencil")
                .font(.subheadline.weight(.semibold))
        }
        .buttonStyle(.bordered)
        .disabled(latestIncomeID == nil)
    }

    private func formatCurrency(_ amount: Double) -> String {
        if #available(iOS 15.0, macCatalyst 15.0, *) {
            let currencyCode: String
            if #available(iOS 16.0, macCatalyst 16.0, *) {
                currencyCode = Locale.current.currency?.identifier ?? "USD"
            } else {
                currencyCode = Locale.current.currencyCode ?? "USD"
            }
            return amount.formatted(.currency(code: currencyCode))
        } else {
            let formatter = NumberFormatter()
            formatter.numberStyle = .currency
            formatter.currencyCode = Locale.current.currencyCode ?? "USD"
            return formatter.string(from: amount as NSNumber) ?? String(format: "%.2f", amount)
        }
    }

    private func dateString(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateStyle = .medium
        return f.string(from: date)
    }

    private var nextExpenseList: some View {
        List {
            nextExpenseContent
                .listRowInsets(EdgeInsets(top: 12, leading: 16, bottom: 12, trailing: 16))
        }
        .listStyle(.plain)
        .sheet(item: $editingExpenseBox) { box in
            AddPlannedExpenseView(
                plannedExpenseID: box.id,
                preselectedBudgetID: summary.id,
                onSaved: {
                    editingExpenseBox = nil
                    Task { await loadSeriesIfNeeded() }
                }
            )
            .environment(\.managedObjectContext, CoreDataService.shared.viewContext)
        }
    }

    private func fetchPlannedExpense(from uri: URL) -> PlannedExpense? {
        let coordinator = CoreDataService.shared.container.persistentStoreCoordinator
        guard let id = coordinator.managedObjectID(forURIRepresentation: uri) else { return nil }
        return try? CoreDataService.shared.viewContext.existingObject(with: id) as? PlannedExpense
    }

    // MARK: - Card Preview Helpers
    private func detachedCardItem(from card: Card?) -> CardItem? {
        guard let card else { return nil }
        return CardItem(from: card)
    }

    private func deletePlannedExpense(_ expense: PlannedExpense?) {
        guard let expense else { return }
        let ctx = CoreDataService.shared.viewContext
        ctx.perform {
            ctx.delete(expense)
            try? ctx.save()
        }
    }

    // MARK: Sparklines & Charts
    private func fallbackRatioSeries(expenses: Double, income: Double) -> [DatedValue] {
        let safeIncome = income == 0 ? 1 : income
        return twoPointSeries(value: expenses / safeIncome)
    }

    private func fallbackSavingsSeries(projected: Double, actual: Double) -> [SavingsPoint] {
        twoPointDates().map { date in
            SavingsPoint(date: date, actual: actual, projected: projected)
        }
    }

    private func twoPointSeries(value: Double) -> [DatedValue] {
        twoPointDates().map { DatedValue(date: $0, value: value) }
    }

    private func twoPointDates() -> [Date] {
        let start = startOfDay(range.lowerBound)
        let end = startOfDay(range.upperBound)
        if start == end { return [start] }
        return [start, end]
    }

    // MARK: Timeline & Pace Helpers
    private func receiptPoints(from timeline: [DatedValue]) -> [DatedValue] {
        let sorted = timeline.sorted { $0.date < $1.date }
        var points: [DatedValue] = []
        var lastValue = 0.0
        for point in sorted {
            if point.value > lastValue {
                points.append(point)
            }
            lastValue = point.value
        }
        return points
    }

    private func actualIncomeLineSeries(from receiptPoints: [DatedValue]) -> [DatedValue] {
        guard let start = receiptPoints.first else {
            return [DatedValue(date: range.lowerBound, value: 0)]
        }
        var series: [DatedValue] = [DatedValue(date: range.lowerBound, value: 0)]
        series.append(contentsOf: receiptPoints)
        if start.date < range.lowerBound {
            series[0] = DatedValue(date: range.lowerBound, value: start.value)
        }
        return series
    }

    // MARK: Income Pace Helpers
    private func expectedIncomeSoFar(progressFallback: Double, on date: Date) -> Double {
        guard !expectedTimeline.isEmpty else {
            return summary.potentialIncomeTotal * progressFallback
        }
        let day = startOfDay(date)
        if let expected = expectedTimeline.last(where: { $0.date <= day }) {
            return expected.value
        }
        return expectedTimeline.first?.value ?? 0
    }

    private func fallbackExpectedSeries() -> [DatedValue] {
        [
            DatedValue(date: range.lowerBound, value: 0),
            DatedValue(date: range.upperBound, value: summary.potentialIncomeTotal)
        ]
    }

    private func nearestPoint(in points: [DatedValue], to date: Date) -> DatedValue? {
        points.min(by: { abs($0.date.timeIntervalSince(date)) < abs($1.date.timeIntervalSince(date)) })
    }

    private func nearestSavingsPoint(in points: [SavingsPoint], to date: Date) -> SavingsPoint? {
        points.min(by: { abs($0.date.timeIntervalSince(date)) < abs($1.date.timeIntervalSince(date)) })
    }

    private func smoothSavings(_ points: [SavingsPoint], maxCount: Int) -> [SavingsPoint] {
        guard maxCount > 1 else { return points }
        if points.count <= maxCount { return deduplicate(points) }

        // Aggregate to week buckets to reduce jaggedness.
        let calendar = Calendar.current
        var buckets: [Date: (actual: Double, projected: Double, count: Int)] = [:]
        for p in points {
            let week = calendar.dateInterval(of: .weekOfYear, for: p.date)?.start ?? startOfDay(p.date)
            let entry = buckets[week] ?? (0, 0, 0)
            buckets[week] = (entry.actual + p.actual, entry.projected + p.projected, entry.count + 1)
        }
        let aggregated = buckets.keys.sorted().map { weekStart -> SavingsPoint in
            let entry = buckets[weekStart]!
            return SavingsPoint(
                date: weekStart,
                actual: entry.actual / Double(entry.count),
                projected: entry.projected / Double(entry.count)
            )
        }
        return deduplicate(aggregated)
    }

    private func deduplicate(_ points: [SavingsPoint]) -> [SavingsPoint] {
        var seen: Set<Date> = []
        var result: [SavingsPoint] = []
        for p in points {
            if !seen.contains(p.date) {
                seen.insert(p.date)
                result.append(p)
            }
        }
        return result.sorted { $0.date < $1.date }
    }

    // MARK: Data Loading
    private func loadSeriesIfNeeded() async {
        let series = await computeDailySeries()
        let income = await computeIncomeTimeline()
        let sections = await computeSpendSections()
        await MainActor.run {
            self.expenseSeries = series.expensePoints
            self.actualIncomeSeries = series.actualIncomePoints
            self.plannedIncomeSeries = series.plannedIncomePoints
            self.savingsSeries = series.savingsPoints
            self.spendSections = sections
            self.selectedSpendSectionID = nil
            self.selectedSpendBucket = nil
            self.incomeTimeline = income.received
            self.expectedTimeline = income.expected
            self.incomeBuckets = income.buckets
            self.latestIncomeID = income.latestIncomeID
        }
    }

    private struct DailySeriesResult {
        let expensePoints: [DatedValue]
        let actualIncomePoints: [DatedValue]
        let plannedIncomePoints: [DatedValue]
        let savingsPoints: [SavingsPoint]
    }

    private struct IncomeTimelineResult {
        let received: [DatedValue]
        let expected: [DatedValue]
        let buckets: [IncomeBucket]
        let latestIncomeID: NSManagedObjectID?
    }

    private func computeDailySeries() async -> DailySeriesResult {
        let ctx = CoreDataService.shared.newBackgroundContext()
        return await ctx.perform {
            guard let budget = try? ctx.existingObject(with: summary.id) as? Budget else {
                let projected = summary.potentialIncomeTotal - summary.plannedExpensesPlannedTotal - summary.variableExpensesTotal
                return DailySeriesResult(
                    expensePoints: twoPointSeries(value: summary.plannedExpensesActualTotal + summary.variableExpensesTotal),
                    actualIncomePoints: twoPointSeries(value: summary.actualIncomeTotal),
                    plannedIncomePoints: twoPointSeries(value: summary.potentialIncomeTotal),
                    savingsPoints: fallbackSavingsSeries(projected: projected, actual: summary.actualSavingsTotal)
                )
            }

            let dates = allDates(in: range)
            if dates.isEmpty {
                let projected = summary.potentialIncomeTotal - summary.plannedExpensesPlannedTotal - summary.variableExpensesTotal
                return DailySeriesResult(
                    expensePoints: twoPointSeries(value: summary.plannedExpensesActualTotal + summary.variableExpensesTotal),
                    actualIncomePoints: twoPointSeries(value: summary.actualIncomeTotal),
                    plannedIncomePoints: twoPointSeries(value: summary.potentialIncomeTotal),
                    savingsPoints: fallbackSavingsSeries(projected: projected, actual: summary.actualSavingsTotal)
                )
            }

            var incomeDaily: [Date: Double] = [:]
            var expenseDaily: [Date: Double] = [:]
            let workspaceID = (budget.value(forKey: "workspaceID") as? UUID)
                ?? WorkspaceService.activeWorkspaceIDFromDefaults()
            guard let workspaceID else {
                let projected = summary.potentialIncomeTotal - summary.plannedExpensesPlannedTotal - summary.variableExpensesTotal
                return DailySeriesResult(
                    expensePoints: twoPointSeries(value: summary.plannedExpensesActualTotal + summary.variableExpensesTotal),
                    actualIncomePoints: twoPointSeries(value: summary.actualIncomeTotal),
                    plannedIncomePoints: twoPointSeries(value: summary.potentialIncomeTotal),
                    savingsPoints: fallbackSavingsSeries(projected: projected, actual: summary.actualSavingsTotal)
                )
            }
            // Incomes (actual)
            let incomeReq = NSFetchRequest<Income>(entityName: "Income")
            let incomeStart = startOfDay(range.lowerBound)
            let incomeEndDay = startOfDay(range.upperBound)
            let incomeEndExclusive = Calendar.current.date(byAdding: .day, value: 1, to: incomeEndDay) ?? range.upperBound
            incomeReq.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
                NSPredicate(format: "date >= %@ AND date < %@", incomeStart as NSDate, incomeEndExclusive as NSDate),
                WorkspaceService.predicate(for: workspaceID)
            ])
            if let incomes = try? ctx.fetch(incomeReq) {
                for inc in incomes where inc.isPlanned == false {
                    let day = startOfDay(inc.date ?? range.lowerBound)
                    incomeDaily[day, default: 0] += inc.amount
                }
            }

            // Planned expenses (actualAmount)
            let plannedReq = NSFetchRequest<PlannedExpense>(entityName: "PlannedExpense")
            plannedReq.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
                NSPredicate(format: "budget == %@", budget),
                NSPredicate(format: "transactionDate >= %@ AND transactionDate <= %@", range.lowerBound as NSDate, range.upperBound as NSDate),
                WorkspaceService.predicate(for: workspaceID)
            ])
            if let planned = try? ctx.fetch(plannedReq) {
                for exp in planned {
                    let day = startOfDay(exp.transactionDate ?? range.lowerBound)
                    expenseDaily[day, default: 0] += exp.actualAmount
                }
            }

            // Variable expenses (cards)
            if let cards = budget.cards as? Set<Card>, !cards.isEmpty {
                let varReq = NSFetchRequest<UnplannedExpense>(entityName: "UnplannedExpense")
                varReq.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
                    NSPredicate(format: "card IN %@", cards as NSSet),
                    NSPredicate(format: "transactionDate >= %@ AND transactionDate <= %@", range.lowerBound as NSDate, range.upperBound as NSDate),
                    WorkspaceService.predicate(for: workspaceID)
                ])
                if let vars = try? ctx.fetch(varReq) {
                    for exp in vars {
                        let day = startOfDay(exp.transactionDate ?? range.lowerBound)
                        expenseDaily[day, default: 0] += exp.amount
                    }
                }
            }

            var expensePoints: [DatedValue] = []
            var actualIncomePoints: [DatedValue] = []
            var plannedIncomePoints: [DatedValue] = []
            var savingsPoints: [SavingsPoint] = []

            var cumulativeIncome = 0.0
            var cumulativeExpense = 0.0

            let projectedTotalExpense = summary.plannedExpensesPlannedTotal + summary.variableExpensesTotal
            let daysCount = max(dates.count, 1)

            for (idx, day) in dates.enumerated() {
                cumulativeIncome += incomeDaily[day] ?? 0
                cumulativeExpense += expenseDaily[day] ?? 0
                expensePoints.append(DatedValue(date: day, value: cumulativeExpense))
                actualIncomePoints.append(DatedValue(date: day, value: cumulativeIncome))

                let fraction = Double(idx + 1) / Double(daysCount)
                let projectedIncomeLine = summary.potentialIncomeTotal * fraction
                let projectedExpenseLine = projectedTotalExpense * fraction
                let projectedNet = projectedIncomeLine - projectedExpenseLine
                let actualNet = cumulativeIncome - cumulativeExpense
                savingsPoints.append(SavingsPoint(date: day, actual: actualNet, projected: projectedNet))
                plannedIncomePoints.append(DatedValue(date: day, value: projectedIncomeLine))

            }

            if expensePoints.count == 1, let first = expensePoints.first {
                expensePoints.append(DatedValue(date: range.upperBound, value: first.value))
            }
            if actualIncomePoints.count == 1, let first = actualIncomePoints.first {
                actualIncomePoints.append(DatedValue(date: range.upperBound, value: first.value))
            }
            if plannedIncomePoints.count == 1, let first = plannedIncomePoints.first {
                plannedIncomePoints.append(DatedValue(date: range.upperBound, value: first.value))
            }
            if savingsPoints.count == 1, let first = savingsPoints.first {
                savingsPoints.append(SavingsPoint(date: range.upperBound, actual: first.actual, projected: first.projected))
            }

            return DailySeriesResult(
                expensePoints: expensePoints,
                actualIncomePoints: actualIncomePoints,
                plannedIncomePoints: plannedIncomePoints,
                savingsPoints: savingsPoints
            )
        }
    }

    private func computeSpendSections() async -> [SpendChartSection] {
        let resolved = resolvedPeriod(period, range: range)
        let yearRange = fullYearRange(for: range.lowerBound)
        let totalsRange = resolved == .yearly ? yearRange : range
        let dayTotals = await daySpendTotals(for: summary, in: totalsRange)

        let dayFormatter = DateFormatter()
        dayFormatter.dateFormat = "MMM d"
        let monthFormatter = DateFormatter()
        monthFormatter.dateFormat = "LLLL yyyy"
        let yearFormatter = DateFormatter()
        yearFormatter.dateFormat = "yyyy"

        func weekTitle(_ r: ClosedRange<Date>) -> String {
            let start = dayFormatter.string(from: r.lowerBound)
            let end = dayFormatter.string(from: r.upperBound)
            return "\(start) – \(end)"
        }

        switch resolved {
        case .daily:
            let buckets = bucketsForDays(in: range, dayTotals: dayTotals, includeAllWeekdays: false)
            return [SpendChartSection(title: dayFormatter.string(from: range.lowerBound), subtitle: nil, buckets: buckets)]
        case .weekly:
            let buckets = bucketsForDays(in: range, dayTotals: dayTotals, includeAllWeekdays: true)
            return [SpendChartSection(title: weekTitle(range), subtitle: nil, buckets: buckets)]
        case .biWeekly:
            let weeks = weeksInRange(range)
            return weeks.map { week in
                let buckets = bucketsForDays(in: week, dayTotals: dayTotals, includeAllWeekdays: true)
                return SpendChartSection(title: weekTitle(week), subtitle: dayFormatter.string(from: week.lowerBound) + " – " + dayFormatter.string(from: week.upperBound), buckets: buckets)
            }
        case .monthly:
            let weeks = weeksInRange(range)
            let monthTitle = monthFormatter.string(from: range.lowerBound)
            return weeks.enumerated().map { idx, week in
                let buckets = bucketsForDays(in: week, dayTotals: dayTotals, includeAllWeekdays: true)
                let title = "\(monthTitle) • Week \(idx + 1)"
                return SpendChartSection(title: title, subtitle: dayFormatter.string(from: week.lowerBound) + " – " + dayFormatter.string(from: week.upperBound), buckets: buckets)
            }
        case .quarterly:
            let months = monthsInRange(range)
            return months.map { monthRange in
                let weekBuckets = bucketsForWeeks(in: monthRange, dayTotals: dayTotals)
                let title = monthFormatter.string(from: monthRange.lowerBound)
                return SpendChartSection(title: title, subtitle: nil, buckets: weekBuckets)
            }
        case .yearly:
            let monthBuckets = bucketsForMonths(in: yearRange, dayTotals: dayTotals)
            let title = yearFormatter.string(from: yearRange.lowerBound)
            return [SpendChartSection(title: title, subtitle: nil, buckets: monthBuckets)]
        case .custom:
            let buckets = bucketsForDays(in: range, dayTotals: dayTotals, includeAllWeekdays: false)
            return [SpendChartSection(title: dayFormatter.string(from: range.lowerBound) + " – " + dayFormatter.string(from: range.upperBound), subtitle: nil, buckets: buckets)]
        }
    }

    private func toggleSpendSelection(in section: SpendChartSection, label: String) {
        guard let bucket = section.buckets.first(where: { $0.label == label }) else { return }
        if selectedSpendSectionID == section.id, selectedSpendBucket?.id == bucket.id {
            selectedSpendSectionID = nil
            selectedSpendBucket = nil
        } else {
            selectedSpendSectionID = section.id
            selectedSpendBucket = bucket
        }
    }

    private func spendCategoryChips(for bucket: SpendBucket) -> some View {
        let sorted = bucket.categoryTotals.sorted { $0.value > $1.value }
        return ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                if sorted.isEmpty {
                    CategoryChipPill(
                        glassTextColor: .secondary,
                        fallbackTextColor: .secondary,
                        fallbackFill: Color.primary.opacity(0.06),
                        fallbackStrokeColor: Color.primary.opacity(0.12),
                        fallbackStrokeLineWidth: 1
                    ) {
                        Text("No Categories")
                    }
                } else {
                    ForEach(sorted, id: \.key) { entry in
                        let name = entry.key.name
                        let color = UBColorFromHex(entry.key.hex) ?? Color.secondary
                        CategoryChipPill(
                            glassTint: color.opacity(0.18),
                            glassTextColor: .primary,
                            fallbackTextColor: .primary,
                            fallbackFill: color.opacity(0.15),
                            fallbackStrokeColor: color.opacity(0.35),
                            fallbackStrokeLineWidth: 1
                        ) {
                            HStack(spacing: 6) {
                                Circle()
                                    .fill(color)
                                    .frame(width: 6, height: 6)
                                Text(name)
                                Text(formatCurrency(entry.value))
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
            .padding(.vertical, 4)
        }
    }

    private func allDates(in range: ClosedRange<Date>) -> [Date] {
        var dates: [Date] = []
        var current = startOfDay(range.lowerBound)
        let end = startOfDay(range.upperBound)
        let calendar = Calendar.current
        while current <= end {
            dates.append(current)
            if let next = calendar.date(byAdding: .day, value: 1, to: current) {
                current = next
            } else { break }
        }
        return dates
    }

    private func startOfDay(_ date: Date) -> Date {
        Calendar.current.startOfDay(for: date)
    }

    private func shortDate(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateStyle = .medium
        return f.string(from: date)
    }

    // MARK: Income Helpers
    private func computeIncomeTimeline() async -> IncomeTimelineResult {
        let ctx = CoreDataService.shared.newBackgroundContext()
        let workspaceID = WorkspaceService.shared.activeWorkspaceID
        return await ctx.perform {
            let dates = allDates(in: range)
            var incomeDaily: [Date: Double] = [:]
            var expectedDaily: [Date: Double] = [:]
            let incomeReq = NSFetchRequest<Income>(entityName: "Income")
            let incomeStart = startOfDay(range.lowerBound)
            let incomeEndDay = startOfDay(range.upperBound)
            let incomeEndExclusive = Calendar.current.date(byAdding: .day, value: 1, to: incomeEndDay) ?? range.upperBound
            incomeReq.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
                NSPredicate(format: "date >= %@ AND date < %@", incomeStart as NSDate, incomeEndExclusive as NSDate),
                WorkspaceService.predicate(for: workspaceID)
            ])
            incomeReq.sortDescriptors = [NSSortDescriptor(key: "date", ascending: true)]
            let incomes = (try? ctx.fetch(incomeReq)) ?? []
            for inc in incomes where inc.isPlanned == false {
                let day = startOfDay(inc.date ?? range.lowerBound)
                incomeDaily[day, default: 0] += inc.amount
            }
            for inc in incomes where inc.isPlanned == true {
                let day = startOfDay(inc.date ?? range.lowerBound)
                expectedDaily[day, default: 0] += inc.amount
            }
            var received: [DatedValue] = []
            var cumulative = 0.0
            for day in dates {
                cumulative += incomeDaily[day] ?? 0
                received.append(DatedValue(date: day, value: cumulative))
            }
            if received.count == 1, let first = received.first {
                received.append(DatedValue(date: range.upperBound, value: first.value))
            }
            let expected: [DatedValue]
            if expectedDaily.isEmpty {
                expected = dates.enumerated().map { idx, day in
                    let fraction = Double(idx + 1) / Double(max(dates.count, 1))
                    return DatedValue(date: day, value: summary.potentialIncomeTotal * fraction)
                }
            } else {
                var expectedCumulative = 0.0
                expected = dates.map { day in
                    expectedCumulative += expectedDaily[day] ?? 0
                    return DatedValue(date: day, value: expectedCumulative)
                }
            }
            let buckets = computeIncomeBuckets(using: ctx, period: comparisonPeriod, workspaceID: workspaceID)
            let latestIncomeID = incomes.last?.objectID
            return IncomeTimelineResult(received: received, expected: expected, buckets: buckets, latestIncomeID: latestIncomeID)
        }
    }

    private func computeIncomeBuckets(using ctx: NSManagedObjectContext,
                                      period: IncomeComparisonPeriod,
                                      workspaceID: UUID) -> [IncomeBucket] {
        var buckets: [IncomeBucket] = []
        let calendar = Calendar.current
        let end = range.upperBound
        let count = 6
        for i in 0..<count {
            guard let bucketRange = bucketRange(endingAt: end, index: i, period: period, calendar: calendar) else { continue }
            let incomeReq = NSFetchRequest<Income>(entityName: "Income")
            incomeReq.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
                NSPredicate(format: "date >= %@ AND date <= %@", bucketRange.start as NSDate, bucketRange.end as NSDate),
                WorkspaceService.predicate(for: workspaceID)
            ])
            let total = ((try? ctx.fetch(incomeReq)) ?? []).filter { $0.isPlanned == false }.reduce(0) { $0 + $1.amount }
            let label = bucketLabel(for: bucketRange, period: period, calendar: calendar)
            buckets.append(IncomeBucket(label: label, start: bucketRange.start, total: total))
        }
        return buckets.sorted { $0.start < $1.start }
    }

    private func bucketRange(endingAt end: Date, index: Int, period: IncomeComparisonPeriod, calendar: Calendar) -> (start: Date, end: Date)? {
        switch period {
        case .daily:
            guard let day = calendar.date(byAdding: .day, value: -index, to: startOfDay(end)) else { return nil }
            return (startOfDay(day), calendar.date(byAdding: .day, value: 0, to: startOfDay(day)) ?? day)
        case .weekly:
            guard let start = calendar.date(byAdding: .day, value: -(index * 7), to: startOfDay(end)),
                  let range = calendar.dateInterval(of: .weekOfYear, for: start) else { return nil }
            return (range.start, calendar.date(byAdding: .day, value: 6, to: range.start) ?? range.end)
        case .biWeekly:
            guard let start = calendar.date(byAdding: .day, value: -(index * 14), to: startOfDay(end)) else { return nil }
            let endDate = calendar.date(byAdding: .day, value: 13, to: start) ?? start
            return (start, endDate)
        case .monthly:
            guard let date = calendar.date(byAdding: .month, value: -index, to: end) else { return nil }
            let interval = calendar.dateInterval(of: .month, for: date) ?? DateInterval(start: date, end: date)
            let endDate = calendar.date(byAdding: .day, value: -1, to: calendar.date(byAdding: .month, value: 1, to: interval.start) ?? interval.end) ?? interval.end
            return (interval.start, endDate)
        case .quarterly:
            guard let date = calendar.date(byAdding: .month, value: -(index * 3), to: end) else { return nil }
            guard let qRange = calendar.dateInterval(of: .quarter, for: date) else { return nil }
            let endDate = calendar.date(byAdding: .day, value: -1, to: calendar.date(byAdding: .month, value: 3, to: qRange.start) ?? qRange.end) ?? qRange.end
            return (qRange.start, endDate)
        case .yearly:
            guard let date = calendar.date(byAdding: .year, value: -index, to: end) else { return nil }
            guard let yRange = calendar.dateInterval(of: .year, for: date) else { return nil }
            let endDate = calendar.date(byAdding: .day, value: -1, to: calendar.date(byAdding: .year, value: 1, to: yRange.start) ?? yRange.end) ?? yRange.end
            return (yRange.start, endDate)
        }
    }

    private func bucketLabel(for range: (start: Date, end: Date), period: IncomeComparisonPeriod, calendar: Calendar) -> String {
        let fmt = DateFormatter()
        switch period {
        case .daily:
            fmt.dateFormat = "MMM d"
            return fmt.string(from: range.start)
        case .weekly, .biWeekly:
            fmt.dateFormat = "MMM d"
            let start = fmt.string(from: range.start)
            let end = fmt.string(from: range.end)
            return "\(start)–\(end)"
        case .monthly:
            fmt.dateFormat = "MMM"
            return fmt.string(from: range.start)
        case .quarterly:
            let q = (calendar.component(.month, from: range.start) - 1) / 3 + 1
            let year = calendar.component(.year, from: range.start) % 100
            return "Q\(q) ’\(year)"
        case .yearly:
            fmt.dateFormat = "yyyy"
            return fmt.string(from: range.start)
        }
    }

    @ViewBuilder
    private func expenseIncomeChart(expensePoints: [DatedValue], incomePoints: [DatedValue], plannedPoints: [DatedValue]) -> some View {
        if expensePoints.isEmpty && incomePoints.isEmpty && plannedPoints.isEmpty {
            Text("Not enough data for this range.")
                .foregroundStyle(.secondary)
        } else {
            let chartPoints =
                expensePoints.map { ExpenseIncomePoint(date: $0.date, value: $0.value, series: .expenses) } +
                incomePoints.map { ExpenseIncomePoint(date: $0.date, value: $0.value, series: .actualIncome) } +
                plannedPoints.map { ExpenseIncomePoint(date: $0.date, value: $0.value, series: .plannedIncome) }
            let values = (expensePoints + incomePoints + plannedPoints).map(\.value)
            let maxVal = values.max() ?? 1
            let lineColor = Color.orange
            let incomeColor = HomeView.HomePalette.income
            let plannedColor = HomeView.HomePalette.income.opacity(0.6)
            let upper = max(maxVal, 1)
            let pad = max(upper * 0.12, 1)
            let domain: ClosedRange<Double> = 0...(upper + pad)
            let latestExpense = expensePoints.last
            let latestIncome = incomePoints.last
            let latestPlanned = plannedPoints.last

            Group {
                if isAccessibilitySize {
                    Chart {
                        ForEach(chartPoints) { point in
                            LineMark(
                                x: .value("Date", point.date),
                                y: .value("Amount", point.value)
                            )
                            .interpolationMethod(.linear)
                            .foregroundStyle(by: .value("Series", point.series.rawValue))
                            .lineStyle(point.series == .plannedIncome ? StrokeStyle(lineWidth: 2, dash: [5, 4]) : StrokeStyle(lineWidth: 2))
                        }
                    }
                    .chartYScale(domain: domain)
                    .chartForegroundStyleScale([
                        ExpenseIncomeSeries.expenses.rawValue: lineColor,
                        ExpenseIncomeSeries.actualIncome.rawValue: incomeColor,
                        ExpenseIncomeSeries.plannedIncome.rawValue: plannedColor
                    ])
                    .chartLegend(.hidden)
                    .chartXAxis(.hidden)
                    .chartYAxis(.hidden)
                    .frame(height: resolvedDetailChartHeight)
                } else {
                    Chart {
                        ForEach(chartPoints) { point in
                            LineMark(
                                x: .value("Date", point.date),
                                y: .value("Amount", point.value)
                            )
                            .interpolationMethod(.linear)
                            .foregroundStyle(by: .value("Series", point.series.rawValue))
                            .lineStyle(point.series == .plannedIncome ? StrokeStyle(lineWidth: 2, dash: [5, 4]) : StrokeStyle(lineWidth: 2))
                        }
                        if let selected = ratioSelection {
                            RuleMark(x: .value("Selected", selected.date))
                                .foregroundStyle(lineColor.opacity(0.35))
                        }
                    }
                    .chartYScale(domain: domain)
                    .chartForegroundStyleScale([
                        ExpenseIncomeSeries.expenses.rawValue: lineColor,
                        ExpenseIncomeSeries.actualIncome.rawValue: incomeColor,
                        ExpenseIncomeSeries.plannedIncome.rawValue: plannedColor
                    ])
                    .chartLegend(.hidden)
                    .chartXAxisLabel("Date")
                    .chartYAxisLabel("Amount")
                    .chartYAxis {
                        AxisMarks(position: .leading) { value in
                            if let val = value.as(Double.self) {
                                AxisGridLine()
                                AxisTick()
                                AxisValueLabel { axisCurrencyLabel(val) }
                            }
                        }
                    }
                    .chartXAxis {
                        AxisMarks(values: .automatic(desiredCount: 3)) { value in
                            if let date = value.as(Date.self) {
                                AxisValueLabel { axisDateLabel(date) }
                            } else {
                                AxisValueLabel()
                            }
                        }
                    }
                    .frame(height: resolvedDetailChartHeight)
                    .chartOverlay { proxy in
                        GeometryReader { geo in
                            Rectangle().fill(.clear).contentShape(Rectangle())
                                .gesture(
                                    DragGesture(minimumDistance: 0)
                                        .onChanged { gesture in
                                            let origin = geo[proxy.plotAreaFrame].origin
                                            let locationX = gesture.location.x - origin.x
                                            if let date: Date = proxy.value(atX: locationX) {
                                                ratioSelection = nearestPoint(in: expensePoints, to: date)
                                            }
                                        }
                                        .onEnded { _ in ratioSelection = nil }
                                )
                        }
                    }
                }
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Expense to income chart")
            .accessibilityValue("Shows expenses, actual income, and planned income for the selected range.")

            if isAccessibilitySize {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Range: \(dateString(range.lowerBound)) – \(dateString(range.upperBound))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(nil)
                        .fixedSize(horizontal: false, vertical: true)
                    if let latestExpense {
                        Text("Expenses: \(formatCurrency(latestExpense.value))")
                            .font(.caption)
                            .foregroundStyle(lineColor)
                            .lineLimit(nil)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    if let latestIncome {
                        Text("Actual Income: \(formatCurrency(latestIncome.value))")
                            .font(.caption)
                            .foregroundStyle(incomeColor)
                            .lineLimit(nil)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    if let latestPlanned {
                        Text("Planned Income: \(formatCurrency(latestPlanned.value))")
                            .font(.caption)
                            .foregroundStyle(plannedColor)
                            .lineLimit(nil)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }

            Group {
                if isAccessibilitySize {
                    VStack(alignment: .leading, spacing: 6) {
                        legendRow(label: "Expenses", color: lineColor, symbol: .dot)
                        legendRow(label: "Actual Income", color: incomeColor, symbol: .dot)
                        legendRow(label: "Planned Income", color: plannedColor, symbol: .line)
                    }
                } else {
                    HStack(spacing: 12) {
                        legendRow(label: "Expenses", color: lineColor, symbol: .dot)
                        legendRow(label: "Actual Income", color: incomeColor, symbol: .dot)
                        legendRow(label: "Planned Income", color: plannedColor, symbol: .line)
                    }
                }
            }

            if let selected = ratioSelection {
                let expense = nearestPoint(in: expensePoints, to: selected.date)
                let income = nearestPoint(in: incomePoints, to: selected.date)
                let planned = nearestPoint(in: plannedPoints, to: selected.date)
                let expenseText = expense.map { formatCurrency($0.value) } ?? "—"
                let incomeText = income.map { formatCurrency($0.value) } ?? "—"
                let plannedText = planned.map { formatCurrency($0.value) } ?? "—"
                Text("\(dateString(selected.date)) • Exp \(expenseText) • Inc \(incomeText) • Plan \(plannedText)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(nil)
                    .fixedSize(horizontal: false, vertical: true)
            } else if let latestExpense, let latestIncome, let latestPlanned {
                Text("Latest: \(dateString(latestExpense.date)) • Exp \(formatCurrency(latestExpense.value)) • Inc \(formatCurrency(latestIncome.value)) • Plan \(formatCurrency(latestPlanned.value))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(nil)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    @ViewBuilder
    private func savingsChart(points: [SavingsPoint]) -> some View {
        if points.isEmpty {
            Text("Not enough data for this range.")
                .foregroundStyle(.secondary)
        } else {
            let sampled = smoothSavings(points, maxCount: 14)
            let minVal = sampled.map { min($0.actual, $0.projected) }.min() ?? 0
            let maxVal = sampled.map { max($0.actual, $0.projected) }.max() ?? 1
            let lower = min(minVal, 0)
            let upper = max(maxVal, 0)
            let pad = max((upper - lower) * 0.1, 1)
            let domain: ClosedRange<Double> = (lower - pad)...(upper + pad)

            let actualSeries = sampled.map { DatedValue(date: $0.date, value: $0.actual) }
            let projectedSeries = sampled.map { DatedValue(date: $0.date, value: $0.projected) }
            let actualColor = Color.green
            let projectedColor = Color.indigo
            let latestActual = actualSeries.last?.value
            let latestProjected = projectedSeries.last?.value

            VStack(alignment: .leading, spacing: 6) {
                Group {
                    if isAccessibilitySize {
                        Chart {
                            ForEach(actualSeries) { point in
                                BarMark(
                                    x: .value("Date", point.date),
                                    y: .value("Actual", point.value)
                                )
                                .cornerRadius(4)
                                .foregroundStyle(actualColor.opacity(0.8))
                            }

                            ForEach(projectedSeries) { point in
                                LineMark(
                                    x: .value("Date", point.date),
                                    y: .value("Projected", point.value)
                                )
                                .interpolationMethod(.monotone)
                                .lineStyle(StrokeStyle(lineWidth: 2, dash: [6, 4]))
                                PointMark(
                                    x: .value("Date", point.date),
                                    y: .value("Projected", point.value)
                                )
                                .symbolSize(10)
                            }
                            .foregroundStyle(projectedColor)

                            RuleMark(y: .value("Zero", 0))
                                .foregroundStyle(.gray.opacity(0.55))
                        }
                        .chartYScale(domain: domain)
                        .chartXAxis(.hidden)
                        .chartYAxis(.hidden)
                        .frame(height: resolvedDetailChartHeight)
                    } else {
                        Chart {
                            ForEach(actualSeries) { point in
                                BarMark(
                                    x: .value("Date", point.date),
                                    y: .value("Actual", point.value)
                                )
                                .cornerRadius(4)
                                .foregroundStyle(actualColor.opacity(0.8))
                            }

                            ForEach(projectedSeries) { point in
                                LineMark(
                                    x: .value("Date", point.date),
                                    y: .value("Projected", point.value)
                                )
                                .interpolationMethod(.monotone)
                                .lineStyle(StrokeStyle(lineWidth: 2, dash: [6, 4]))
                                PointMark(
                                    x: .value("Date", point.date),
                                    y: .value("Projected", point.value)
                                )
                                .symbolSize(10)
                            }
                            .foregroundStyle(projectedColor)

                            if let selected = savingsSelection {
                                RuleMark(x: .value("Selected", selected.date))
                                    .foregroundStyle(.gray.opacity(0.35))
                            }

                            RuleMark(y: .value("Zero", 0))
                                .foregroundStyle(.gray.opacity(0.55))
                        }
                        .chartYScale(domain: domain)
                        .chartXAxisLabel("Date")
                        .chartYAxisLabel("Savings")
                        .chartXAxis {
                            AxisMarks(values: .automatic(desiredCount: 3)) { value in
                                if let date = value.as(Date.self) {
                                    AxisValueLabel { axisDateLabel(date) }
                                } else {
                                    AxisValueLabel()
                                }
                            }
                        }
                        .chartYAxis {
                            AxisMarks(position: .leading) { value in
                                if let val = value.as(Double.self) {
                                    AxisGridLine()
                                    AxisTick()
                                    AxisValueLabel { axisCurrencyLabel(val) }
                                }
                            }
                        }
                        .frame(height: resolvedDetailChartHeight)
                        .chartOverlay { proxy in
                            GeometryReader { geo in
                                Rectangle().fill(.clear).contentShape(Rectangle())
                                    .gesture(
                                        DragGesture(minimumDistance: 0)
                                            .onChanged { gesture in
                                                let origin = geo[proxy.plotAreaFrame].origin
                                                let locationX = gesture.location.x - origin.x
                                                if let date: Date = proxy.value(atX: locationX) {
                                                    savingsSelection = nearestSavingsPoint(in: points, to: date)
                                                }
                                            }
                                            .onEnded { _ in savingsSelection = nil }
                                    )
                            }
                        }
                    }
                }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("Savings chart")
                .accessibilityValue("Shows actual and projected savings over time.")

                if isAccessibilitySize {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Range: \(dateString(range.lowerBound)) – \(dateString(range.upperBound))")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(nil)
                            .fixedSize(horizontal: false, vertical: true)
                        if let latestActual {
                            Text("Actual: \(formatCurrency(latestActual))")
                                .font(.caption)
                                .foregroundStyle(actualColor)
                                .lineLimit(nil)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        if let latestProjected {
                            Text("Projected: \(formatCurrency(latestProjected))")
                                .font(.caption)
                                .foregroundStyle(projectedColor)
                                .lineLimit(nil)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }

                Group {
                    if isAccessibilitySize {
                        VStack(alignment: .leading, spacing: 6) {
                            legendRow(label: "Actual", color: actualColor, symbol: .dot)
                            legendRow(label: "Projected", color: projectedColor, symbol: .dot)
                            if let selected = savingsSelection {
                                Text("\(dateString(selected.date)) • \(formatCurrency(selected.actual)) / \(formatCurrency(selected.projected))")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(nil)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                    } else {
                        HStack(spacing: 12) {
                            legendRow(label: "Actual", color: actualColor, symbol: .dot)
                            legendRow(label: "Projected", color: projectedColor, symbol: .dot)
                            if let selected = savingsSelection {
                                Text("\(dateString(selected.date)) • \(formatCurrency(selected.actual)) / \(formatCurrency(selected.projected))")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(nil)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                    }
                }
            }
        }
    }

    // MARK: Categories bar list
    private func categoryBars(totalOverride: Double? = nil) -> some View {
        let items = summary.variableCategoryBreakdown
        let topItems = showAllCategories ? items : Array(items.prefix(5))
        let total = totalOverride ?? max(items.map(\.amount).reduce(0, +), 1)
        return VStack(alignment: .leading, spacing: 10) {
            ForEach(topItems) { cat in
                categoryRow(cat, total: total)
            }
        }
    }

    private func categoriesCompactList(_ items: [BudgetSummary.CategorySpending], total: Double) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            ForEach(items) { cat in
                categoryRow(cat, total: total)
            }
        }
    }

    private func categoryRow(_ cat: BudgetSummary.CategorySpending, total: Double) -> some View {
        let color = UBColorFromHex(cat.hexColor) ?? HomeView.HomePalette.presets
        let share = max(min(cat.amount / max(total, 1), 1), 0)
        return Group {
            if isAccessibilitySize {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Circle().fill(color).frame(width: legendDotSize, height: legendDotSize)
                        Text(cat.categoryName)
                            .font(.subheadline.weight(.semibold))
                            .lineLimit(nil)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    HStack(spacing: 8) {
                        Text(formatCurrency(cat.amount))
                            .font(.subheadline)
                        Text(String(format: "%.0f%%", share * 100))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            } else {
                HStack {
                    Circle().fill(color).frame(width: legendDotSize, height: legendDotSize)
                    Text(cat.categoryName)
                        .font(.subheadline.weight(.semibold))
                        .lineLimit(1)
                        .fixedSize(horizontal: false, vertical: true)
                    Spacer()
                    Text(formatCurrency(cat.amount))
                        .font(.subheadline)
                    Text(String(format: "%.0f%%", share * 100))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

}

// MARK: - Shared compact preset-style row
private struct NextPlannedDetailRow: View {
    let snapshot: HomeView.PlannedExpenseSnapshot
    let expense: PlannedExpense?
    let onEdit: () -> Void
    let onDelete: () -> Void

    @EnvironmentObject private var themeManager: ThemeManager
    @AppStorage(AppSettingsKeys.confirmBeforeDelete.rawValue) private var confirmBeforeDelete: Bool = true
    @State private var showDeleteAlert = false
    @ScaledMetric(relativeTo: .body) private var symbolWidth: CGFloat = 14
    @ScaledMetric(relativeTo: .body) private var dotSize: CGFloat = 8
    @ScaledMetric(relativeTo: .body) private var cardIndicatorWidth: CGFloat = 12
    @ScaledMetric(relativeTo: .body) private var cardIndicatorHeight: CGFloat = 8

    var body: some View {
        let dotColor = UBColorFromHex(expense?.expenseCategory?.color) ?? .secondary
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 2) {
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Circle().fill(dotColor).frame(width: dotSize, height: dotSize)
                        .frame(width: symbolWidth, alignment: .leading)
                    Text(snapshot.title)
                        .font(.headline)
                        .lineLimit(nil)
                        .fixedSize(horizontal: false, vertical: true)
                }
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    cardIndicator
                        .frame(width: symbolWidth, alignment: .leading)
                    Text(shortDate(snapshot.date))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer(minLength: 8)
            VStack(alignment: .trailing, spacing: 4) {
                Text("Planned: \(formatCurrency(snapshot.plannedAmount))")
                    .font(.subheadline.weight(.semibold))
                Text("Actual: \(formatCurrency(snapshot.actualAmount))")
                    .font(.subheadline)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
        .unifiedSwipeActions(
            UnifiedSwipeConfig(allowsFullSwipeToDelete: !confirmBeforeDelete),
            onEdit: onEdit,
            onDelete: { confirmBeforeDelete ? (showDeleteAlert = true) : onDelete() }
        )
        .alert("Delete planned expense?", isPresented: $showDeleteAlert) {
            Button("Delete", role: .destructive) { onDelete() }
            Button("Cancel", role: .cancel) { }
        }
    }

    private var cardIndicator: some View {
        Group {
            if let card = expense?.card {
                let theme: CardTheme = {
                    if card.entity.attributesByName["theme"] != nil,
                       let raw = card.value(forKey: "theme") as? String,
                       let t = CardTheme(rawValue: raw) { return t }
                    return .graphite
                }()
                RoundedRectangle(cornerRadius: 2, style: .continuous)
                    .fill(theme.backgroundStyle(for: themeManager.selectedTheme))
                    .overlay(theme.patternOverlay(cornerRadius: 2))
                    .overlay(
                        RoundedRectangle(cornerRadius: 2, style: .continuous)
                            .stroke(Color.primary.opacity(0.18), lineWidth: 1)
                    )
                    .frame(width: cardIndicatorWidth, height: cardIndicatorHeight)
            } else {
                RoundedRectangle(cornerRadius: 2, style: .continuous)
                    .stroke(Color.primary.opacity(0.12), lineWidth: 1)
                    .frame(width: cardIndicatorWidth, height: cardIndicatorHeight)
            }
        }
    }

    private func formatCurrency(_ amount: Double) -> String {
        if #available(iOS 15.0, macCatalyst 15.0, *) {
            let currencyCode: String
            if #available(iOS 16.0, macCatalyst 16.0, *) {
                currencyCode = Locale.current.currency?.identifier ?? "USD"
            } else {
                currencyCode = Locale.current.currencyCode ?? "USD"
            }
            return amount.formatted(.currency(code: currencyCode))
        } else {
            let formatter = NumberFormatter()
            formatter.numberStyle = .currency
            formatter.currencyCode = Locale.current.currencyCode ?? "USD"
            return formatter.string(from: amount as NSNumber) ?? String(format: "%.2f", amount)
        }
    }
}

private struct PresetExpenseRowView: View {
    let title: String
    let amountText: String
    let dateText: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.body.weight(.semibold))
                .foregroundStyle(.primary)
                .lineLimit(2)
            HStack(spacing: 12) {
                Text(amountText)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(dateText)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Next Planned Expense Widget Row
private struct NextPlannedExpenseWidgetRow: View {
    let cardItem: CardItem?
    let title: String
    let dateText: String
    let plannedText: String
    let actualText: String
    @ScaledMetric(relativeTo: .body) private var cardPreviewWidth: CGFloat = 140
    private let cardAspectRatio: CGFloat = 1.586
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    private var isAccessibilitySize: Bool {
        dynamicTypeSize.isAccessibilitySize
    }

    private var isCompactWidth: Bool {
        horizontalSizeClass == .compact
    }

    private var previewWidth: CGFloat {
        isAccessibilitySize ? cardPreviewWidth * 0.8 : cardPreviewWidth
    }

    private var previewHeight: CGFloat {
        previewWidth / cardAspectRatio
    }

    var body: some View {
        Group {
            if isAccessibilitySize {
                VStack(alignment: .leading, spacing: 12) {
                    cardPreview
                    details
                }
            } else {
                HStack(alignment: .top, spacing: 12) {
                    cardPreview
                    details
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var details: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.body.weight(.semibold))
                .foregroundStyle(.primary)
                .lineLimit(isAccessibilitySize || isCompactWidth ? nil : 1)
            Text(dateText)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(plannedText)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.primary)
            Text(actualText)
                .font(.caption)
                .foregroundStyle(.primary)
        }
    }

    @ViewBuilder
    private var cardPreview: some View {
        if let cardItem {
            CardTileView(card: cardItem, isInteractive: false, enableMotionShine: true, showsBaseShadow: false)
                .frame(width: previewWidth)
        } else {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Color.secondary.opacity(0.12))
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .stroke(Color.primary.opacity(0.12), lineWidth: 1)
                )
                .frame(width: previewWidth, height: previewHeight)
        }
    }
}

private func shortDate(_ date: Date) -> String {
    let f = DateFormatter()
    f.dateStyle = .medium
    return f.string(from: date)
}

// MARK: - Next Planned + Presets Detail
private struct NextPlannedPresetsView: View {
    let summaryID: NSManagedObjectID
    let nextExpense: HomeView.PlannedExpenseSnapshot?

    @State private var hasDeletedNextExpense = false
    @State private var editingExpenseBox: ExpenseBox?
    @Environment(\.managedObjectContext) private var viewContext

    private struct ExpenseBox: Identifiable {
        let id: NSManagedObjectID
    }

    var body: some View {
        PresetsView(header: headerView)
            .sheet(item: $editingExpenseBox) { box in
                AddPlannedExpenseView(
                    plannedExpenseID: box.id,
                    preselectedBudgetID: summaryID,
                    onSaved: {
                        editingExpenseBox = nil
                    }
                )
                .environment(\.managedObjectContext, viewContext)
            }
    }

    private var headerView: AnyView? {
        guard let nextExpense, !hasDeletedNextExpense else { return nil }
        let expense = fetchPlannedExpense(from: nextExpense.expenseURI)
        let colors = nextExpenseGradientColors(for: expense)
        let gradient = LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing)
        let shadowColor = colors.last ?? HomeView.HomePalette.cards
        return AnyView(
            VStack(alignment: .leading, spacing: 12) {
                Text("Next Planned Expense")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(HomeView.HomePalette.cards)
                    .lineLimit(nil)
                    .fixedSize(horizontal: false, vertical: true)
                NextPlannedDetailRow(
                    snapshot: nextExpense,
                    expense: expense,
                    onEdit: { presentEditor(for: nextExpense) },
                    onDelete: {
                        deletePlannedExpense(for: nextExpense)
                        withAnimation { hasDeletedNextExpense = true }
                    }
                )
            }
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(.ultraThinMaterial)
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(gradient)
                        .opacity(0.35)
                }
                .shadow(color: shadowColor.opacity(0.18), radius: 18, x: 0, y: 12)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(gradient, lineWidth: 1)
                    .opacity(0.7)
            )
        )
    }

    private func presentEditor(for snapshot: HomeView.PlannedExpenseSnapshot) {
        guard let expense = fetchPlannedExpense(from: snapshot.expenseURI) else { return }
        editingExpenseBox = ExpenseBox(id: expense.objectID)
    }

    private func deletePlannedExpense(for snapshot: HomeView.PlannedExpenseSnapshot) {
        guard let expense = fetchPlannedExpense(from: snapshot.expenseURI) else { return }
        let ctx = CoreDataService.shared.viewContext
        ctx.perform {
            ctx.delete(expense)
            try? ctx.save()
        }
    }

    private func fetchPlannedExpense(from uri: URL) -> PlannedExpense? {
        let coordinator = CoreDataService.shared.container.persistentStoreCoordinator
        guard let id = coordinator.managedObjectID(forURIRepresentation: uri) else { return nil }
        return try? CoreDataService.shared.viewContext.existingObject(with: id) as? PlannedExpense
    }

    private func nextExpenseGradientColors(for expense: PlannedExpense?) -> [Color] {
        var palette: [Color] = []
        if
            let hex = expense?.expenseCategory?.color,
            let color = UBColorFromHex(hex)
        {
            palette.append(color)
        }
        if let theme = cardTheme(from: expense?.card) {
            let (top, bottom) = theme.colors
            palette.append(contentsOf: [top, bottom])
        }
        if palette.isEmpty {
            palette = [HomeView.HomePalette.cards, HomeView.HomePalette.presets]
        } else if palette.count == 1, let first = palette.first {
            palette.append(first.opacity(0.9))
        }
        return Array(palette.prefix(2))
    }

    private func cardTheme(from card: Card?) -> CardTheme? {
        guard
            let card,
            card.entity.attributesByName["theme"] != nil,
            let raw = card.value(forKey: "theme") as? String
        else { return nil }
        return CardTheme(rawValue: raw)
    }
}

// MARK: - Category Spotlight Helpers
private struct CategorySlice: Identifiable {
    let id = UUID()
    let name: String
    let amount: Double
    let color: Color
}

private struct DaySpendTotal {
    var total: Double
    var categoryTotals: [CategorySpendKey: Double]
}

private func categorySlices(from categories: [BudgetSummary.CategorySpending], limit: Int) -> [CategorySlice] {
    guard !categories.isEmpty else { return [] }
    let positive = categories.filter { $0.amount > 0 }
    guard !positive.isEmpty else { return [] }
    let limited = Array(positive.prefix(limit))
    return limited.map {
        CategorySlice(
            name: $0.categoryName,
            amount: $0.amount,
            color: UBColorFromHex($0.hexColor) ?? HomeView.HomePalette.presets
        )
    }
}

private func resolvedPeriod(_ period: BudgetPeriod, range: ClosedRange<Date>) -> BudgetPeriod {
    if period != .custom { return period }
    let cal = Calendar.current
    let start = cal.startOfDay(for: range.lowerBound)
    let end = cal.startOfDay(for: range.upperBound)
    let spanDays = (cal.dateComponents([.day], from: start, to: end).day ?? 0) + 1
    switch spanDays {
    case ...1: return .daily
    case 2...7: return .weekly
    case 8...14: return .biWeekly
    case 15...45: return .monthly
    case 46...120: return .quarterly
    default: return .yearly
    }
}

private func daysInRange(_ range: ClosedRange<Date>) -> [Date] {
    var dates: [Date] = []
    let cal = Calendar.current
    var current = cal.startOfDay(for: range.lowerBound)
    let end = cal.startOfDay(for: range.upperBound)
    while current <= end {
        dates.append(current)
        guard let next = cal.date(byAdding: .day, value: 1, to: current) else { break }
        current = next
    }
    return dates
}

private func weeksInRange(_ range: ClosedRange<Date>) -> [ClosedRange<Date>] {
    var ranges: [ClosedRange<Date>] = []
    let cal = Calendar.current
    var cursor = BudgetPeriod.weekly.start(of: range.lowerBound)
    let end = range.upperBound
    while cursor <= end {
        let weekRange = BudgetPeriod.weekly.range(containing: cursor)
        let boundedStart = max(weekRange.start, range.lowerBound)
        let boundedEnd = min(weekRange.end, end)
        ranges.append(boundedStart...boundedEnd)
        guard let next = cal.date(byAdding: .day, value: 7, to: cursor) else { break }
        cursor = next
    }
    return ranges
}

private func fullWeekRange(for date: Date) -> ClosedRange<Date> {
    let cal = Calendar.current
    guard let interval = cal.dateInterval(of: .weekOfYear, for: date) else {
        let day = cal.startOfDay(for: date)
        return day...day
    }
    let start = cal.startOfDay(for: interval.start)
    let end = cal.date(byAdding: .day, value: 6, to: start) ?? interval.end
    return start...end
}

private func monthsInRange(_ range: ClosedRange<Date>) -> [ClosedRange<Date>] {
    var ranges: [ClosedRange<Date>] = []
    let cal = Calendar.current
    var cursor = BudgetPeriod.monthly.start(of: range.lowerBound)
    let end = range.upperBound
    while cursor <= end {
        let monthRange = BudgetPeriod.monthly.range(containing: cursor)
        let boundedStart = max(monthRange.start, range.lowerBound)
        let boundedEnd = min(monthRange.end, end)
        ranges.append(boundedStart...boundedEnd)
        guard let next = cal.date(byAdding: .month, value: 1, to: cursor) else { break }
        cursor = next
    }
    return ranges
}

private func fullYearRange(for date: Date) -> ClosedRange<Date> {
    let cal = Calendar.current
    guard let interval = cal.dateInterval(of: .year, for: date) else {
        let day = cal.startOfDay(for: date)
        return day...day
    }
    let start = cal.startOfDay(for: interval.start)
    let end = cal.date(byAdding: .day, value: -1, to: interval.end) ?? interval.end
    return start...end
}

private func splitRange(_ range: ClosedRange<Date>, daysPerBucket: Int) -> [ClosedRange<Date>] {
    var ranges: [ClosedRange<Date>] = []
    let cal = Calendar.current
    var cursor = cal.startOfDay(for: range.lowerBound)
    let end = cal.startOfDay(for: range.upperBound)
    while cursor <= end {
        let next = cal.date(byAdding: .day, value: daysPerBucket - 1, to: cursor) ?? cursor
        let bucketEnd = min(next, end)
        ranges.append(cursor...bucketEnd)
        guard let advance = cal.date(byAdding: .day, value: daysPerBucket, to: cursor) else { break }
        cursor = advance
    }
    return ranges
}

private func dayRangeLabel(for range: ClosedRange<Date>) -> String {
    let cal = Calendar.current
    let startDay = cal.component(.day, from: range.lowerBound)
    let endDay = cal.component(.day, from: range.upperBound)
    let sameMonth = cal.isDate(range.lowerBound, equalTo: range.upperBound, toGranularity: .month)
    if sameMonth {
        return "\(startDay)–\(endDay)"
    }
    let formatter = DateFormatter()
    formatter.dateFormat = "MMM d"
    let start = formatter.string(from: range.lowerBound)
    let end = formatter.string(from: range.upperBound)
    return "\(start)–\(end)"
}

private func daySpendTotals(for summary: BudgetSummary, in range: ClosedRange<Date>) async -> [Date: DaySpendTotal] {
    let ctx = CoreDataService.shared.newBackgroundContext()
    let cal = Calendar.current
    return await ctx.perform {
        guard let budget = try? ctx.existingObject(with: summary.id) as? Budget else { return [:] }

        var totals: [Date: DaySpendTotal] = [:]

        func add(amount: Double, date: Date?, category: ExpenseCategory?) {
            let day = cal.startOfDay(for: date ?? range.lowerBound)
            var entry = totals[day] ?? DaySpendTotal(total: 0, categoryTotals: [:])
            entry.total += amount
            if amount > 0 {
                let name = category?.name?.trimmingCharacters(in: .whitespacesAndNewlines)
                let safeName = name?.isEmpty == false ? name! : "Uncategorized"
                let hex = category?.color?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
                let key = CategorySpendKey(name: safeName, hex: hex)
                entry.categoryTotals[key, default: 0] += amount
            }
            totals[day] = entry
        }

        // Planned expenses
        let plannedReq = NSFetchRequest<PlannedExpense>(entityName: "PlannedExpense")
        let workspaceID = (budget.value(forKey: "workspaceID") as? UUID)
            ?? WorkspaceService.activeWorkspaceIDFromDefaults()
        guard let workspaceID else { return totals }
        plannedReq.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
            NSPredicate(format: "budget == %@", budget),
            NSPredicate(format: "transactionDate >= %@ AND transactionDate <= %@", range.lowerBound as NSDate, range.upperBound as NSDate),
            WorkspaceService.predicate(for: workspaceID)
        ])
        if let planned = try? ctx.fetch(plannedReq) {
            for exp in planned {
                add(amount: exp.actualAmount, date: exp.transactionDate, category: exp.expenseCategory)
            }
        }

        // Variable expenses (cards)
        if let cards = budget.cards as? Set<Card>, !cards.isEmpty {
            let varReq = NSFetchRequest<UnplannedExpense>(entityName: "UnplannedExpense")
            varReq.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
                NSPredicate(format: "card IN %@", cards as NSSet),
                NSPredicate(format: "transactionDate >= %@ AND transactionDate <= %@", range.lowerBound as NSDate, range.upperBound as NSDate),
                WorkspaceService.predicate(for: workspaceID)
            ])
            if let vars = try? ctx.fetch(varReq) {
                for exp in vars {
                    add(amount: exp.amount, date: exp.transactionDate, category: exp.expenseCategory)
                }
            }
        }

        return totals
    }
}

private func bucketsForDays(in range: ClosedRange<Date>, dayTotals: [Date: DaySpendTotal], includeAllWeekdays: Bool) -> [SpendBucket] {
    let cal = Calendar.current
    let weekdays = cal.shortWeekdaySymbols
    let baseRange = includeAllWeekdays ? fullWeekRange(for: range.lowerBound) : range
    let dates = daysInRange(baseRange)
    return dates.map { day in
        let entry = dayTotals[day] ?? DaySpendTotal(total: 0, categoryTotals: [:])
        let weekdayIndex = cal.component(.weekday, from: day) - 1
        let dayLabel = weekdays.indices.contains(weekdayIndex) ? weekdays[weekdayIndex] : "Day"
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        let label: String
        if dates.count == 1 {
            label = formatter.string(from: day)
        } else if includeAllWeekdays {
            label = dayLabel
        } else {
            label = String(dayLabel.prefix(1))
        }
        let sortedKeys = entry.categoryTotals.sorted { $0.value > $1.value }.map(\.key)
        let hexes = sortedKeys.map(\.hex).filter { !$0.isEmpty }
        return SpendBucket(
            label: label,
            start: day,
            end: day,
            amount: entry.total,
            categoryHexColors: hexes,
            categoryTotals: entry.categoryTotals
        )
    }
}

private func bucketsForWeeks(in range: ClosedRange<Date>, dayTotals: [Date: DaySpendTotal]) -> [SpendBucket] {
    return weeksInRange(range).map { weekRange in
        let days = daysInRange(weekRange)
        var total = 0.0
        var catTotals: [CategorySpendKey: Double] = [:]
        for day in days {
            let entry = dayTotals[day] ?? DaySpendTotal(total: 0, categoryTotals: [:])
            total += entry.total
            for (key, amt) in entry.categoryTotals {
                catTotals[key, default: 0] += amt
            }
        }
        let label = dayRangeLabel(for: weekRange)
        let sortedKeys = catTotals.sorted { $0.value > $1.value }.map(\.key)
        let hexes = sortedKeys.map(\.hex).filter { !$0.isEmpty }
        return SpendBucket(
            label: label,
            start: weekRange.lowerBound,
            end: weekRange.upperBound,
            amount: total,
            categoryHexColors: hexes,
            categoryTotals: catTotals
        )
    }
}

private func bucketsForRanges(_ ranges: [ClosedRange<Date>], dayTotals: [Date: DaySpendTotal]) -> [SpendBucket] {
    return ranges.map { range in
        let days = daysInRange(range)
        var total = 0.0
        var catTotals: [CategorySpendKey: Double] = [:]
        for day in days {
            let entry = dayTotals[day] ?? DaySpendTotal(total: 0, categoryTotals: [:])
            total += entry.total
            for (key, amt) in entry.categoryTotals {
                catTotals[key, default: 0] += amt
            }
        }
        let label = dayRangeLabel(for: range)
        let sortedKeys = catTotals.sorted { $0.value > $1.value }.map(\.key)
        let hexes = sortedKeys.map(\.hex).filter { !$0.isEmpty }
        return SpendBucket(
            label: label,
            start: range.lowerBound,
            end: range.upperBound,
            amount: total,
            categoryHexColors: hexes,
            categoryTotals: catTotals
        )
    }
}

private func bucketsForMonths(in range: ClosedRange<Date>, dayTotals: [Date: DaySpendTotal]) -> [SpendBucket] {
    let formatter = DateFormatter()
    formatter.dateFormat = "MMM"
    return monthsInRange(range).map { monthRange in
        let days = daysInRange(monthRange)
        var total = 0.0
        var catTotals: [CategorySpendKey: Double] = [:]
        for day in days {
            let entry = dayTotals[day] ?? DaySpendTotal(total: 0, categoryTotals: [:])
            total += entry.total
            for (key, amt) in entry.categoryTotals {
                catTotals[key, default: 0] += amt
            }
        }
        let label = formatter.string(from: monthRange.lowerBound)
        let sortedKeys = catTotals.sorted { $0.value > $1.value }.map(\.key)
        let hexes = sortedKeys.map(\.hex).filter { !$0.isEmpty }
        return SpendBucket(
            label: label,
            start: monthRange.lowerBound,
            end: monthRange.upperBound,
            amount: total,
            categoryHexColors: hexes,
            categoryTotals: catTotals
        )
    }
}

private func spendGradientColors(for bucket: SpendBucket, summary: BudgetSummary, maxColors: Int) -> [Color] {
    let colors = uniqueHexes(from: bucket.categoryHexColors, maxCount: maxColors)
        .compactMap { UBColorFromHex($0) }
    if !colors.isEmpty {
        if colors.count == 1, let first = colors.first { return [first, first] }
        return blendTail(colors: colors, totalCount: bucket.categoryHexColors.count, maxCount: maxColors)
    }
    let fallbackHexes = summary.variableCategoryBreakdown.compactMap { $0.hexColor }
    let fallbackColors = uniqueHexes(from: fallbackHexes, maxCount: maxColors)
        .compactMap { UBColorFromHex($0) }
    if !fallbackColors.isEmpty {
        if fallbackColors.count == 1, let first = fallbackColors.first { return [first, first] }
        return blendTail(colors: fallbackColors, totalCount: fallbackHexes.count, maxCount: maxColors)
    }
    return [HomeView.HomePalette.presets, HomeView.HomePalette.cards]
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

private func detailBarOrientation(for period: BudgetPeriod, bucketCount: Int) -> SpendBarOrientation {
    if period == .yearly { return .vertical }
    if period == .quarterly || period == .monthly { return .horizontal }
    if period == .biWeekly { return .horizontal }
    if bucketCount <= 2 { return .horizontal }
    return .vertical
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

private func fetchCapStatuses(for summary: BudgetSummary) async -> [CapStatus] {
    let caps = categoryCaps(for: summary)
    return CategoryAvailabilitySegment.allCases.flatMap {
        computeCapStatuses(summary: summary, caps: caps, segment: $0)
    }
}

private func capsPeriodKey(start: Date, end: Date, segment: String) -> String {
    let f = DateFormatter()
    f.calendar = Calendar(identifier: .gregorian)
    f.locale = Locale(identifier: "en_US_POSIX")
    f.timeZone = TimeZone(secondsFromGMT: 0)
    f.dateFormat = "yyyy-MM-dd"
    let s = f.string(from: start)
    let e = f.string(from: end)
    return "\(s)|\(e)|\(segment)"
}

// MARK: - Shared helpers
fileprivate func normalizeCategoryName(_ name: String) -> String {
    name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
}

fileprivate func categoryCaps(for summary: BudgetSummary) -> [String: (planned: Double?, variable: Double?)] {
    let ctx = CoreDataService.shared.viewContext
    var map: [String: (planned: Double?, variable: Double?)] = [:]

    func fetchCaps(segment: String) {
        let key = capsPeriodKey(start: summary.periodStart, end: summary.periodEnd, segment: segment)
        let fetch = NSFetchRequest<CategorySpendingCap>(entityName: "CategorySpendingCap")
        fetch.predicate = NSPredicate(format: "period == %@", key)
        let results = (try? ctx.fetch(fetch)) ?? []
        for cap in results {
            guard let category = cap.category,
                  let name = category.name else { continue }
            let norm = normalizeCategoryName(name)
            var entry = map[norm] ?? (planned: nil, variable: nil)
            if (cap.expenseType ?? "").lowercased() == "max" {
                if segment == "planned" { entry.planned = cap.amount } else { entry.variable = cap.amount }
                map[norm] = entry
            }
        }
    }

    fetchCaps(segment: "planned")
    fetchCaps(segment: "variable")
    return map
}

fileprivate func computeCategoryAvailability(summary: BudgetSummary, caps: [String: (planned: Double?, variable: Double?)], segment: CategoryAvailabilitySegment) -> [CategoryAvailability] {
    let remainingIncome = max(summary.actualIncomeTotal - (summary.plannedExpensesActualTotal + summary.variableExpensesTotal), 0)
    let breakdown: [BudgetSummary.CategorySpending]
    switch segment {
    case .combined:
        breakdown = summary.categoryBreakdown
    case .planned:
        breakdown = summary.plannedCategoryBreakdown
    case .variable:
        breakdown = summary.variableCategoryBreakdown
    }

    let availabilities: [CategoryAvailability] = breakdown.map { cat in
        let norm = normalizeCategoryName(cat.categoryName)
        let capTuple = caps[norm]
        let plannedDefault = summary.plannedCategoryDefaultCaps[norm]
        let capValue: Double?
        switch segment {
        case .combined:
            let plannedCap = capTuple?.planned ?? plannedDefault
            let variableCap = capTuple?.variable
            let combined = (plannedCap ?? 0) + (variableCap ?? 0)
            capValue = combined > 0 ? combined : nil
        case .planned:
            capValue = capTuple?.planned ?? plannedDefault
        case .variable:
            capValue = capTuple?.variable
        }
        let hasCap = capValue != nil
        let capAmount = capValue ?? 0
        let capRemaining = max(capAmount - cat.amount, 0)
        let available = hasCap ? capRemaining : remainingIncome
        let color = UBColorFromHex(cat.hexColor) ?? Color.accentColor
        let over = hasCap && cat.amount >= capAmount
        let near = hasCap && cat.amount >= capAmount * 0.85 && cat.amount < capAmount
        return CategoryAvailability(
            name: cat.categoryName,
            spent: cat.amount,
            cap: capValue,
            available: available,
            color: color,
            over: over,
            near: near
        )
    }

    return availabilities
        .sorted { lhs, rhs in
            if lhs.spent == rhs.spent { return lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending }
            return lhs.spent > rhs.spent
        }
}

fileprivate func computeCapStatuses(summary: BudgetSummary, caps: [String: (planned: Double?, variable: Double?)], segment: CategoryAvailabilitySegment) -> [CapStatus] {
    let breakdown: [BudgetSummary.CategorySpending]
    switch segment {
    case .combined:
        breakdown = summary.categoryBreakdown
    case .planned:
        breakdown = summary.plannedCategoryBreakdown
    case .variable:
        breakdown = summary.variableCategoryBreakdown
    }

    let statuses: [CapStatus] = breakdown.compactMap { cat in
        let norm = normalizeCategoryName(cat.categoryName)
        let overrides = caps[norm]
        let plannedDefault = summary.plannedCategoryDefaultCaps[norm]
        let plannedComponent = max((overrides?.planned ?? plannedDefault ?? 0), 0)
        let variableComponent = max(overrides?.variable ?? 0, 0)

        let capAmount: Double
        switch segment {
        case .combined:
            capAmount = plannedComponent + variableComponent
        case .planned:
            capAmount = plannedComponent
        case .variable:
            capAmount = variableComponent
        }

        guard capAmount > 0 else { return nil }
        let color = UBColorFromHex(cat.hexColor) ?? HomeView.HomePalette.presets
        let over = cat.amount >= capAmount
        let near = !over && cat.amount >= capAmount * 0.85

        return CapStatus(
            name: cat.categoryName,
            amount: cat.amount,
            cap: capAmount,
            color: color,
            near: near,
            over: over,
            segment: segment
        )
    }

    return statuses.sorted { lhs, rhs in
        if lhs.over != rhs.over { return lhs.over && !rhs.over }
        let lhsRatio = lhs.cap > 0 ? lhs.amount / lhs.cap : 0
        let rhsRatio = rhs.cap > 0 ? rhs.amount / rhs.cap : 0
        if lhsRatio == rhsRatio {
            return lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending
        }
        return lhsRatio > rhsRatio
    }
}

// MARK: - Typography Helpers
extension Font {
    static let ubWidgetTitle = Font.headline.weight(.semibold)
    static let ubWidgetSubtitle = Font.subheadline
    static let ubSectionTitle = Font.headline.weight(.semibold)
    static let ubMetricValue = Font.title3.weight(.bold)
    static let ubDetailLabel = Font.subheadline
    static let ubBody = Font.body
    static let ubChip = Font.caption.weight(.semibold)
    static let ubCaption = Font.footnote
    static let ubSmallCaption = Font.caption2
}

private struct CategoryDonutView: View {
    let slices: [CategorySlice]
    let total: Double
    let centerTitle: String
    let centerValue: String
    var centerValueGradient: AngularGradient? = nil
    var savingsColor: Color? = nil
    var centerValueColor: Color? = nil

    var body: some View {
        ZStack {
            if #available(iOS 17.0, macCatalyst 17.0, macOS 14.0, *) {
                Chart(slices) { slice in
                    SectorMark(
                        angle: .value("Amount", slice.amount),
                        innerRadius: .ratio(0.60),
                        outerRadius: .ratio(1.0)
                    )
                    .foregroundStyle(style(for: slice))
                    .shadow(
                        color: slice.name == "Savings"
                            ? (savingsColor ?? Color.green).opacity(0.45)
                            : .clear,
                        radius: slice.name == "Savings" ? 2.5 : 0,
                        x: 0,
                        y: 0
                    )
                    .shadow(
                        color: slice.name == "Savings"
                            ? (savingsColor ?? Color.green).opacity(0.3)
                            : .clear,
                        radius: slice.name == "Savings" ? 6 : 0,
                        x: 0,
                        y: 0
                    )
                }
                .chartLegend(.hidden)
                .frame(maxWidth: .infinity)
            } else {
                // Fallback: simple ring using proportional rectangles
                HStack(spacing: 4) {
                    ForEach(slices) { slice in
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .fill(style(for: slice))
                            .frame(maxWidth: .infinity)
                            .frame(height: 8)
                            .opacity(0.9)
                            .shadow(color: savingsColor?.opacity(slice.name == "Savings" ? 0.35 : 0) ?? .clear, radius: 4, x: 0, y: 0)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            if #available(iOS 17.0, macCatalyst 17.0, macOS 14.0, *),
               let outline = specialOutline {
                DonutSliceOutline(
                    startAngle: outline.start,
                    endAngle: outline.end,
                    innerRadiusRatio: 0.60,
                    outerRadiusRatio: 1.0
                )
                .stroke(Color.white.opacity(0.85), lineWidth: 1.5)
                .shadow(color: outline.color.opacity(0.4), radius: 2, x: 0, y: 0)
                .allowsHitTesting(false)
            }

            VStack(spacing: 4) {
                Text(centerTitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(centerValue)
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(centerStyle)
                    .shadow(color: Color.primary.opacity(0.08), radius: 1, x: 0, y: 1)
            }
        }
    }

    private var centerStyle: AnyShapeStyle {
        if let centerValueColor {
            return AnyShapeStyle(centerValueColor)
        }
        if let centerValueGradient {
            return AnyShapeStyle(centerValueGradient)
        }
        return AnyShapeStyle(uniformAngularGradient(Color.primary))
    }

    private func style(for slice: CategorySlice) -> AnyShapeStyle {
        if slice.name == "Savings" {
            if let savingsColor {
                return AnyShapeStyle(savingsColor)
            }
        }
        return AnyShapeStyle(uniformAngularGradient(slice.color))
    }

    private var specialOutline: (start: Angle, end: Angle, color: Color)? {
        let totalAmount = max(total, 1)
        var currentAngle: Double = 0
        for slice in slices {
            let start = currentAngle
            let end = currentAngle + (slice.amount / totalAmount) * 360
            if slice.name == "Savings" {
                return (start: .degrees(start - 90), end: .degrees(end - 90), color: savingsColor ?? slice.color)
            }
            if slice.name == "Deficit" {
                return (start: .degrees(start - 90), end: .degrees(end - 90), color: slice.color)
            }
            currentAngle = end
        }
        return nil
    }
}

fileprivate func uniformAngularGradient(_ color: Color) -> AngularGradient {
    AngularGradient(gradient: Gradient(colors: [color, color]), center: .center)
}

private struct DonutSliceOutline: Shape {
    let startAngle: Angle
    let endAngle: Angle
    let innerRadiusRatio: CGFloat
    let outerRadiusRatio: CGFloat

    func path(in rect: CGRect) -> Path {
        let size = min(rect.width, rect.height)
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let outerRadius = (size / 2) * outerRadiusRatio
        let innerRadius = (size / 2) * innerRadiusRatio
        var path = Path()
        path.addArc(center: center, radius: outerRadius, startAngle: startAngle, endAngle: endAngle, clockwise: false)
        path.addArc(center: center, radius: innerRadius, startAngle: endAngle, endAngle: startAngle, clockwise: true)
        path.closeSubpath()
        return path
    }
}

private struct CategoryTopRow: View {
    let slice: CategorySlice
    let total: Double
    @ScaledMetric(relativeTo: .body) private var dotSize: CGFloat = 12
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    private var isAccessibilitySize: Bool {
        dynamicTypeSize.isAccessibilitySize
    }

    var body: some View {
        let share = max(min(slice.amount / max(total, 1), 1), 0)
        VStack(alignment: .leading, spacing: 6) {
            Group {
                if isAccessibilitySize {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 8) {
                            Circle().fill(slice.color).frame(width: dotSize, height: dotSize)
                            Text(slice.name)
                                .font(.subheadline.weight(.semibold))
                                .lineLimit(nil)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        HStack(spacing: 8) {
                            Text(String(format: "%.0f%%", share * 100))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(formatCurrency(slice.amount))
                                .font(.subheadline)
                        }
                    }
                } else {
                    HStack {
                        Circle().fill(slice.color).frame(width: dotSize, height: dotSize)
                        Text(slice.name)
                            .font(.subheadline.weight(.semibold))
                            .lineLimit(2)
                            .fixedSize(horizontal: false, vertical: true)
                        Spacer()
                        Text(String(format: "%.0f%%", share * 100))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(formatCurrency(slice.amount))
                            .font(.subheadline)
                    }
                }
            }
            GeometryReader { geo in
                RoundedRectangle(cornerRadius: 4, style: .continuous)
                    .fill(slice.color.opacity(0.25))
                    .frame(width: CGFloat(share) * geo.size.width, height: 8)
            }
            .frame(height: 8)
        }
    }

    private func formatCurrency(_ amount: Double) -> String {
        if #available(iOS 15.0, macCatalyst 15.0, *) {
            let currencyCode: String
            if #available(iOS 16.0, macCatalyst 16.0, *) {
                currencyCode = Locale.current.currency?.identifier ?? "USD"
            } else {
                currencyCode = Locale.current.currencyCode ?? "USD"
            }
            return amount.formatted(.currency(code: currencyCode))
        } else {
            let formatter = NumberFormatter()
            formatter.numberStyle = .currency
            formatter.currencyCode = Locale.current.currencyCode ?? "USD"
            return formatter.string(from: amount as NSNumber) ?? String(format: "%.2f", amount)
        }
    }
}

// MARK: - Shared Helpers for Budget Detail Lists
private func categoryPredicate(from uri: URL?) -> NSPredicate? {
    let coordinator = CoreDataService.shared.container.persistentStoreCoordinator
    guard
        let uri = uri,
        uri.scheme == "x-coredata",
        let catID = coordinator.managedObjectID(forURIRepresentation: uri),
        let category = try? CoreDataService.shared.viewContext.existingObject(with: catID) as? ExpenseCategory
    else { return nil }
    return NSPredicate(format: "expenseCategory == %@", category)
}

struct PlannedRowsList: View {
    @FetchRequest var rows: FetchedResults<PlannedExpense>
    let horizontalPadding: CGFloat
    let selectedCategoryURI: URL?
    let confirmBeforeDelete: Bool
    let onEdit: (NSManagedObjectID) -> Void
    let onDelete: (PlannedExpense) -> Void
    @EnvironmentObject private var themeManager: ThemeManager
    @ScaledMetric(relativeTo: .body) private var symbolWidth: CGFloat = 14
    @ScaledMetric(relativeTo: .body) private var dotSize: CGFloat = 8
    @ScaledMetric(relativeTo: .body) private var cardPreviewWidth: CGFloat = 12
    @ScaledMetric(relativeTo: .body) private var cardPreviewHeight: CGFloat = 8

    init(
        budget: Budget,
        start: Date,
        end: Date,
        sortDescriptors: [NSSortDescriptor],
        horizontalPadding: CGFloat,
        selectedCategoryURI: URL?,
        confirmBeforeDelete: Bool,
        onEdit: @escaping (NSManagedObjectID) -> Void,
        onDelete: @escaping (PlannedExpense) -> Void
    ) {
        let req = NSFetchRequest<PlannedExpense>(entityName: "PlannedExpense")
        var predicates: [NSPredicate] = [
            NSPredicate(format: "budget == %@", budget),
            NSPredicate(format: "transactionDate >= %@ AND transactionDate <= %@", start as NSDate, end as NSDate)
        ]
        if let workspaceID = budget.value(forKey: "workspaceID") as? UUID {
            predicates.append(WorkspaceService.predicate(for: workspaceID))
        }
        if let catPredicate = categoryPredicate(from: selectedCategoryURI) {
            predicates.append(catPredicate)
        }
        req.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
        req.sortDescriptors = sortDescriptors
        _rows = FetchRequest(fetchRequest: req)
        self.horizontalPadding = horizontalPadding
        self.selectedCategoryURI = selectedCategoryURI
        self.confirmBeforeDelete = confirmBeforeDelete
        self.onEdit = onEdit
        self.onDelete = onDelete
    }

    var body: some View {
        if rows.isEmpty {
            Text("No planned expenses in this period.\nPress the + to add a planned expense.")
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.vertical, 8)
                .listRowInsets(EdgeInsets(top: 0, leading: horizontalPadding, bottom: 0, trailing: horizontalPadding))
                .listRowSeparator(.hidden)
        } else {
            ForEach(rows, id: \.objectID) { exp in
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 2) {
                        let dotColor = UBColorFromHex(exp.expenseCategory?.color) ?? .secondary
                        HStack(alignment: .firstTextBaseline, spacing: 6) {
                            Circle().fill(dotColor).frame(width: dotSize, height: dotSize)
                                .frame(width: symbolWidth, alignment: .leading)
                            Text(Self.readPlannedDescription(exp) ?? "Expense")
                                .font(.headline)
                        }
                        HStack(alignment: .firstTextBaseline, spacing: 6) {
                            Group {
                                if let card = exp.card {
                                    let theme: CardTheme = {
                                        if card.entity.attributesByName["theme"] != nil,
                                           let raw = card.value(forKey: "theme") as? String,
                                           let t = CardTheme(rawValue: raw) { return t }
                                        return .graphite
                                    }()
                                    RoundedRectangle(cornerRadius: 2, style: .continuous)
                                        .fill(theme.backgroundStyle(for: themeManager.selectedTheme))
                                        .overlay(theme.patternOverlay(cornerRadius: 2))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 2, style: .continuous)
                                                .stroke(Color.primary.opacity(0.18), lineWidth: 1)
                                        )
                                        .frame(width: cardPreviewWidth, height: cardPreviewHeight)
                                } else {
                                    RoundedRectangle(cornerRadius: 2, style: .continuous)
                                        .stroke(Color.primary.opacity(0.12), lineWidth: 1)
                                        .frame(width: cardPreviewWidth, height: cardPreviewHeight)
                                }
                            }
                            .frame(width: symbolWidth, alignment: .leading)
                            Text(Self.dateString(exp.transactionDate))
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                    Spacer(minLength: 8)
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("Planned: \(Self.formatCurrency(exp.plannedAmount))")
                            .font(.subheadline.weight(.semibold))
                        Text("Actual: \(Self.formatCurrency(exp.actualAmount))")
                            .font(.subheadline)
                    }
                }
                .frame(maxWidth: .infinity)
                .unifiedSwipeActions(
                    UnifiedSwipeConfig(allowsFullSwipeToDelete: !confirmBeforeDelete),
                    onEdit: { onEdit(exp.objectID) },
                    onDelete: { onDelete(exp) }
                )
            }
        }
    }

    static func sortDescriptors(for sort: HomeView.Sort) -> [NSSortDescriptor] {
        switch sort {
        case .titleAZ: return [NSSortDescriptor(key: "descriptionText", ascending: true, selector: #selector(NSString.localizedCaseInsensitiveCompare(_:)))]
        case .amountLowHigh: return [NSSortDescriptor(key: "actualAmount", ascending: true)]
        case .amountHighLow: return [NSSortDescriptor(key: "actualAmount", ascending: false)]
        case .dateOldNew: return [NSSortDescriptor(key: "transactionDate", ascending: true)]
        case .dateNewOld: return [NSSortDescriptor(key: "transactionDate", ascending: false)]
        }
    }

    static func sortDescriptors(for sort: BudgetDetailsViewModel.SortOption) -> [NSSortDescriptor] {
        switch sort {
        case .titleAZ: return [NSSortDescriptor(key: "descriptionText", ascending: true, selector: #selector(NSString.localizedCaseInsensitiveCompare(_:)))]
        case .amountLowHigh: return [NSSortDescriptor(key: "actualAmount", ascending: true)]
        case .amountHighLow: return [NSSortDescriptor(key: "actualAmount", ascending: false)]
        case .dateOldNew: return [NSSortDescriptor(key: "transactionDate", ascending: true)]
        case .dateNewOld: return [NSSortDescriptor(key: "transactionDate", ascending: false)]
        }
    }

    private static func dateString(_ date: Date?) -> String {
        guard let d = date else { return "" }
        let f = DateFormatter(); f.dateStyle = .medium
        return f.string(from: d)
    }

    private static func readPlannedDescription(_ object: NSManagedObject) -> String? {
        let keys = object.entity.attributesByName.keys
        if keys.contains("descriptionText") {
            return object.value(forKey: "descriptionText") as? String
        } else if keys.contains("title") {
            return object.value(forKey: "title") as? String
        }
        return nil
    }

    private static func formatCurrency(_ amount: Double) -> String {
        if #available(iOS 15.0, macCatalyst 15.0, *) {
            let currencyCode: String
            if #available(iOS 16.0, macCatalyst 16.0, *) {
                currencyCode = Locale.current.currency?.identifier ?? "USD"
            } else {
                currencyCode = Locale.current.currencyCode ?? "USD"
            }
            return amount.formatted(.currency(code: currencyCode))
        } else {
            let formatter = NumberFormatter()
            formatter.numberStyle = .currency
            formatter.currencyCode = Locale.current.currencyCode ?? "USD"
            return formatter.string(from: amount as NSNumber) ?? String(format: "%.2f", amount)
        }
    }
}

private struct SegmentedGlassStyleModifier: ViewModifier {
    var cornerRadius: CGFloat = 18

    func body(content: Content) -> some View {
        content
            .padding(.vertical, 6)
            .padding(.horizontal, 8)
            .background(background)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
    }

    @ViewBuilder
    private var background: some View {
        if #available(iOS 26.0, macOS 15.0, macCatalyst 26.0, *) {
            Color.clear
                .glassEffect(.regular, in: .rect(cornerRadius: cornerRadius))
        } else {
            #if canImport(UIKit)
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(Color(UIColor.secondarySystemBackground).opacity(0.95))
                .overlay(
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .stroke(Color.black.opacity(0.08), lineWidth: 0.8)
                )
            #elseif os(macOS)
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(Color(NSColor.windowBackgroundColor).opacity(0.92))
                .overlay(
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .stroke(Color.primary.opacity(0.12), lineWidth: 0.8)
                )
            #else
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(Color.white.opacity(0.15))
            #endif
        }
    }
}

fileprivate extension View {
    func ubSegmentedGlassStyle(cornerRadius: CGFloat = 18) -> some View {
        modifier(SegmentedGlassStyleModifier(cornerRadius: cornerRadius))
    }
}

struct VariableRowsList: View {
    @FetchRequest var rows: FetchedResults<UnplannedExpense>
    let horizontalPadding: CGFloat
    let selectedCategoryURI: URL?
    let confirmBeforeDelete: Bool
    let onEdit: (NSManagedObjectID) -> Void
    let onDelete: (UnplannedExpense) -> Void
    @EnvironmentObject private var themeManager: ThemeManager
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @ScaledMetric(relativeTo: .body) private var symbolWidth: CGFloat = 14
    @ScaledMetric(relativeTo: .body) private var dotSize: CGFloat = 8
    @ScaledMetric(relativeTo: .body) private var cardPreviewWidth: CGFloat = 12
    @ScaledMetric(relativeTo: .body) private var cardPreviewHeight: CGFloat = 8

    init(
        budget: Budget,
        start: Date,
        end: Date,
        sortDescriptors: [NSSortDescriptor],
        horizontalPadding: CGFloat,
        selectedCategoryURI: URL?,
        confirmBeforeDelete: Bool,
        onEdit: @escaping (NSManagedObjectID) -> Void,
        onDelete: @escaping (UnplannedExpense) -> Void
    ) {
        let req = NSFetchRequest<UnplannedExpense>(entityName: "UnplannedExpense")
        if let cards = budget.cards as? Set<Card>, !cards.isEmpty {
            var subs: [NSPredicate] = [
                NSPredicate(format: "card IN %@", cards as NSSet),
                NSPredicate(format: "transactionDate >= %@ AND transactionDate <= %@", start as NSDate, end as NSDate)
            ]
            if let workspaceID = budget.value(forKey: "workspaceID") as? UUID {
                subs.append(WorkspaceService.predicate(for: workspaceID))
            }
            if let catPredicate = categoryPredicate(from: selectedCategoryURI) {
                subs.append(catPredicate)
            }
            req.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: subs)
        } else {
            req.predicate = NSPredicate(value: false)
        }
        req.sortDescriptors = sortDescriptors
        _rows = FetchRequest(fetchRequest: req)
        self.horizontalPadding = horizontalPadding
        self.selectedCategoryURI = selectedCategoryURI
        self.confirmBeforeDelete = confirmBeforeDelete
        self.onEdit = onEdit
        self.onDelete = onDelete
    }

    var body: some View {
        if rows.isEmpty {
            Text("No variable expenses in this period.\nTrack purchases as they happen.")
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.vertical, 8)
                .listRowInsets(EdgeInsets(top: 0, leading: horizontalPadding, bottom: 0, trailing: horizontalPadding))
                .listRowSeparator(.hidden)
        } else {
            ForEach(rows, id: \.objectID) { exp in
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 2) {
                        let dotColor = UBColorFromHex(exp.expenseCategory?.color) ?? .secondary
                        HStack(alignment: .firstTextBaseline, spacing: 6) {
                            Circle().fill(dotColor).frame(width: dotSize, height: dotSize)
                                .frame(width: symbolWidth, alignment: .leading)
                            Text(Self.readUnplannedDescription(exp) ?? "Expense")
                                .font(.headline)
                                .lineLimit(dynamicTypeSize.isAccessibilitySize ? 3 : 2)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        HStack(alignment: .firstTextBaseline, spacing: 6) {
                            Group {
                                if let card = exp.card {
                                    let theme: CardTheme = {
                                        if card.entity.attributesByName["theme"] != nil,
                                           let raw = card.value(forKey: "theme") as? String,
                                           let t = CardTheme(rawValue: raw) { return t }
                                        return .graphite
                                    }()
                                    RoundedRectangle(cornerRadius: 2, style: .continuous)
                                        .fill(theme.backgroundStyle(for: themeManager.selectedTheme))
                                        .overlay(theme.patternOverlay(cornerRadius: 2))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 2, style: .continuous)
                                                .stroke(Color.primary.opacity(0.18), lineWidth: 1)
                                        )
                                        .frame(width: cardPreviewWidth, height: cardPreviewHeight)
                                } else {
                                    RoundedRectangle(cornerRadius: 2, style: .continuous)
                                        .stroke(Color.primary.opacity(0.12), lineWidth: 1)
                                        .frame(width: cardPreviewWidth, height: cardPreviewHeight)
                                }
                            }
                            .frame(width: symbolWidth, alignment: .leading)
                            Text(Self.dateString(exp.transactionDate))
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                    Spacer(minLength: 8)
                    Text(Self.formatCurrency(exp.amount))
                        .font(.headline)
                }
                .frame(maxWidth: .infinity)
                .unifiedSwipeActions(
                    UnifiedSwipeConfig(allowsFullSwipeToDelete: !confirmBeforeDelete),
                    onEdit: { onEdit(exp.objectID) },
                    onDelete: { onDelete(exp) }
                )
            }
        }
    }

    static func sortDescriptors(for sort: HomeView.Sort) -> [NSSortDescriptor] {
        switch sort {
        case .titleAZ: return [NSSortDescriptor(key: "descriptionText", ascending: true, selector: #selector(NSString.localizedCaseInsensitiveCompare(_:)))]
        case .amountLowHigh: return [NSSortDescriptor(key: "amount", ascending: true)]
        case .amountHighLow: return [NSSortDescriptor(key: "amount", ascending: false)]
        case .dateOldNew: return [NSSortDescriptor(key: "transactionDate", ascending: true)]
        case .dateNewOld: return [NSSortDescriptor(key: "transactionDate", ascending: false)]
        }
    }

    static func sortDescriptors(for sort: BudgetDetailsViewModel.SortOption) -> [NSSortDescriptor] {
        switch sort {
        case .titleAZ: return [NSSortDescriptor(key: "descriptionText", ascending: true, selector: #selector(NSString.localizedCaseInsensitiveCompare(_:)))]
        case .amountLowHigh: return [NSSortDescriptor(key: "amount", ascending: true)]
        case .amountHighLow: return [NSSortDescriptor(key: "amount", ascending: false)]
        case .dateOldNew: return [NSSortDescriptor(key: "transactionDate", ascending: true)]
        case .dateNewOld: return [NSSortDescriptor(key: "transactionDate", ascending: false)]
        }
    }

    private static func readUnplannedDescription(_ object: NSManagedObject) -> String? {
        let keys = object.entity.attributesByName.keys
        if keys.contains("descriptionText") {
            return object.value(forKey: "descriptionText") as? String
        } else if keys.contains("title") {
            return object.value(forKey: "title") as? String
        }
        return nil
    }

    private static func dateString(_ date: Date?) -> String {
        guard let d = date else { return "" }
        let f = DateFormatter(); f.dateStyle = .medium
        return f.string(from: d)
    }

    private static func formatCurrency(_ amount: Double) -> String {
        if #available(iOS 15.0, macCatalyst 15.0, *) {
            let currencyCode: String
            if #available(iOS 16.0, macCatalyst 16.0, *) {
                currencyCode = Locale.current.currency?.identifier ?? "USD"
            } else {
                currencyCode = Locale.current.currencyCode ?? "USD"
            }
            return amount.formatted(.currency(code: currencyCode))
        } else {
            let formatter = NumberFormatter()
            formatter.numberStyle = .currency
            formatter.currencyCode = Locale.current.currencyCode ?? "USD"
            return formatter.string(from: amount as NSNumber) ?? String(format: "%.2f", amount)
        }
    }
}

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
}

/// Represents a chart section (e.g., a week or month) containing spend buckets.
private struct SpendChartSection: Identifiable {
    let id = UUID()
    let title: String
    let subtitle: String?
    let buckets: [SpendBucket]
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

    enum Sort: String, CaseIterable, Identifiable { case titleAZ, amountLowHigh, amountHighLow, dateOldNew, dateNewOld; var id: String { rawValue } }

    @AppStorage("homePinnedWidgetIDs") private var pinnedStorage: String = ""
    @AppStorage("homeWidgetOrderIDs") private var orderStorage: String = ""
    @AppStorage("homeAvailabilitySegment") private var availabilitySegmentRawValue: String = CategoryAvailabilitySegment.combined.rawValue

    private static let defaultWidgets: [WidgetID] = [
        .income, .expenseToIncome, .savings, .nextPlanned, .categorySpotlight, .dayOfWeek, .caps, .availability
    ]

    @State private var pinnedIDs: [WidgetID] = HomeView.defaultWidgets
    @State private var widgetOrder: [WidgetID] = HomeView.defaultWidgets
    @State private var isEditing: Bool = false
    @State private var draggingID: WidgetID?

    private let gridSpacing: CGFloat = 18
    private let gridRowHeight: CGFloat = 170

    private var isCompactDateRow: Bool {
        horizontalSizeClass == .compact
    }

    private var columnCount: Int {
        #if os(macOS)
        return 4
        #else
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
    @State private var cardWidgets: [CardItem] = []

    enum HomePalette {
        static let budgets = Color(red: 0.15, green: 0.68, blue: 0.45)
        static let income  = Color(red: 0.23, green: 0.55, blue: 0.95)
        static let presets = Color(red: 0.59, green: 0.45, blue: 0.96)
        static let cards   = Color(red: 0.97, green: 0.62, blue: 0.25)
    }

    enum HomeWidgetKind {
        case budgets, income, presets, cards
        case dayOfWeek, caps, availability

        var titleColor: Color {
            switch self {
            case .budgets: return HomePalette.budgets
            case .income:  return HomePalette.income
            case .presets: return HomePalette.presets
            case .cards:   return HomePalette.cards
            case .dayOfWeek: return HomePalette.presets
            case .caps: return HomePalette.presets
            case .availability: return HomePalette.presets
            }
        }
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

    var body: some View {
        ZStack(alignment: .top) {
            heatmapBackground
                .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    dateRow
                    contentBody
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 32)
            }
        }
        .navigationTitle("Home")
        .refreshable { await vm.refresh() }
        .task { await onAppearTask() }
        .onChange(of: vm.period) { _ in syncPickers(with: vm.currentDateRange) }
        .onChange(of: vm.selectedDate) { _ in syncPickers(with: vm.currentDateRange) }
        .onReceive(vm.$customDateRange) { _ in syncPickers(with: vm.currentDateRange) }
        .onChange(of: vm.state) { _ in Task { await stateDidChange() } }
        .onReceive(NotificationCenter.default.publisher(for: .NSManagedObjectContextDidSave, object: CoreDataService.shared.viewContext)) { _ in
            Task { await loadAllCards() }
        }
        .alert(item: $vm.alert, content: alert(for:))
    }

    // MARK: Content
    @ViewBuilder
    private var contentBody: some View {
        switch vm.state {
        case .initial, .loading:
            ProgressView("Loading budgets…")
                .frame(maxWidth: .infinity, alignment: .leading)
        case .empty:
            emptyState
        case .loaded:
            if let summary = primarySummary {
                widgetGrid(for: summary)
            } else {
                emptyState
            }
        }
    }

    @ViewBuilder
    private var dateRow: some View {
        let applyDisabled = startDateSelection > endDateSelection
        let rangeLabel = Text(rangeDescription(currentRange))
            .font(.headline.weight(.semibold))
            .lineLimit(isCompactDateRow ? 2 : 1)
            .minimumScaleFactor(0.75)
            .multilineTextAlignment(.leading)

        let controls = dateRowControls(disabled: applyDisabled)

        Group {
            if isCompactDateRow {
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
        .frame(maxWidth: .infinity)
        .background(glassRowBackground)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    @ViewBuilder
    private func dateRowControls(disabled: Bool) -> some View {
        HStack(spacing: 8) {
            DatePicker("Start date", selection: $startDateSelection, displayedComponents: [.date])
                .labelsHidden()
                .datePickerStyle(.compact)
            DatePicker("End date", selection: $endDateSelection, displayedComponents: [.date])
                .labelsHidden()
                .datePickerStyle(.compact)
            applyButton(disabled)
            periodMenu
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
    private func widgetGrid(for summary: BudgetSummary) -> some View {
        let items = widgetItems(for: summary)
        let visibleItems = orderedVisibleItems(from: items)
        let libraryItems = items.filter { !pinnedIDs.contains($0.id) }

        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Widgets")
                    .font(.headline.weight(.semibold))
                Spacer()
                Button(isEditing ? "Done" : "Edit") {
                    withAnimation(.spring(response: 0.25, dampingFraction: 0.9)) {
                        isEditing.toggle()
                        draggingID = nil
                    }
                }
                .buttonStyle(.plain)
            }

            if #available(iOS 16.0, macOS 13.0, macCatalyst 16.0, *) {
                WidgetGridLayout(columns: columnCount, spacing: gridSpacing, rowHeight: gridRowHeight) {
                    ForEach(visibleItems) { item in
                        widgetCell(for: item)
                    }
                }
                .animation(.spring(response: 0.25, dampingFraction: 0.9), value: widgetOrder)
                .animation(.spring(response: 0.25, dampingFraction: 0.9), value: pinnedIDs)
            } else {
                // Fallback to original stack on older OS versions.
                LazyVStack(spacing: 12) {
                    ForEach(visibleItems) { item in
                        widgetCell(for: item)
                    }
                }
            }

            if isEditing && !libraryItems.isEmpty {
                Divider()
                    .padding(.vertical, 4)
                Text("Add widgets")
                    .font(.subheadline.weight(.semibold))
                LazyVStack(alignment: .leading, spacing: 8) {
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
                    }
                }
            }
        }
        .onAppear { initializeLayoutStateIfNeeded(with: items) }
        .onChange(of: items.map(\.id)) { _ in
            initializeLayoutStateIfNeeded(with: items)
        }
    }

    // MARK: Widgets
    private func incomeWidget(for summary: BudgetSummary) -> some View {
        widgetLink(title: "Income", subtitle: widgetRangeLabel, kind: .income, span: WidgetSpan(width: 1, height: 1), summary: summary) {
            VStack(alignment: .leading, spacing: 8) {
                let total = max(summary.potentialIncomeTotal, 1)
                let percent = min(max(summary.actualIncomeTotal / total, 0), 1)
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Actual Income")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                        Text(formatCurrency(summary.actualIncomeTotal))
                            .font(.headline)
                    }
                    Spacer()
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Planned Income")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                        Text(formatCurrency(summary.potentialIncomeTotal))
                            .font(.headline)
                    }
                }
                HStack(spacing: 8) {
                    Text("0%")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    Gauge(value: percent, in: 0...1) {
                        EmptyView()
                    }
                    .gaugeStyle(.accessoryLinear)
                    .tint(Gradient(colors: [HomeView.HomePalette.income.opacity(0.25), HomeView.HomePalette.income]))
                    .frame(maxWidth: .infinity)
                    Text(String(format: "%.0f%%", percent * 100))
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(.primary)
                }
            }
        }
    }

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
        return widgetLink(title: "Expense to Income", subtitle: widgetRangeLabel, kind: .budgets, span: WidgetSpan(width: 1, height: 1), summary: summary) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Expenses")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                        Text(formatCurrency(metrics.expenses))
                            .font(.headline)
                    }
                    Spacer()
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Actual Income")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                        Text(formatCurrency(summary.actualIncomeTotal))
                            .font(.headline)
                    }
                }
                HStack(spacing: 8) {
                    Text("0%")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    Gauge(value: gaugeValue, in: 0...1) {
                        EmptyView()
                    }
                    .gaugeStyle(.accessoryLinear)
                    .tint(Gradient(colors: [tint.opacity(0.25), tint]))
                    .frame(maxWidth: .infinity)
                    Text(hasReceived ? String(format: "%.0f%%", receivedPercent) : "—")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(overReceived ? .red : .primary)
                }
            }
        }
    }

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
        return widgetLink(title: "Savings Outlook", subtitle: widgetRangeLabel, kind: .budgets, span: WidgetSpan(width: 1, height: 1), summary: summary) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Projected Savings")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                        Text(formatCurrency(projected))
                            .font(.headline)
                    }
                    Spacer()
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Actual Savings")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                        Text(formatCurrency(actual))
                            .font(.headline)
                            .foregroundStyle(statusTint)
                    }
                }
                if projectedPositive {
                    HStack(spacing: 8) {
                        Text("0%")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                        Gauge(value: progressValue, in: 0...1) {
                            EmptyView()
                        }
                        .gaugeStyle(.accessoryLinear)
                        .tint(Gradient(colors: [statusTint.opacity(0.25), statusTint]))
                        .frame(maxWidth: .infinity)
                    Text(percentLabel)
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(statusTint)
                }
            } else {
                HStack(spacing: 8) {
                    Text("-100%")
                        .font(.footnote)
                            .foregroundStyle(.secondary)
                        Gauge(value: deficitRecovery, in: 0...1) {
                            EmptyView()
                        }
                        .gaugeStyle(.accessoryLinear)
                        .tint(Gradient(colors: [deficitTint.opacity(0.25), deficitTint]))
                        .frame(maxWidth: .infinity)
                    Text(deficitLabel)
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(deficitTint)
                }
            }
        }
    }
    }


    private func nextPlannedExpenseWidget(for summary: BudgetSummary) -> some View {
        let snapshot = (nextPlannedSnapshot?.budgetID == summary.id) ? nextPlannedSnapshot : nil
        return NavigationLink {
            NextPlannedPresetsView(summaryID: summary.id, nextExpense: snapshot)
                .environment(\.managedObjectContext, CoreDataService.shared.viewContext)
        } label: {
            widgetCard(title: "Next Planned Expense", subtitle: widgetRangeLabel, kind: .cards, span: WidgetSpan(width: 1, height: 1)) {
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
        return widgetLink(title: "Category Spotlight", subtitle: widgetRangeLabel, kind: .presets, span: WidgetSpan(width: 1, height: 2), summary: summary, topCategory: topCategory) {
            if let top = slices.first, totalExpenses > 0 {
                GeometryReader { geo in
                    let donutHeight = max(180, geo.size.height * 0.6)
                    VStack(alignment: .leading, spacing: 12) {
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
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                }
            } else {
                Text("Add expenses to see category trends.")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    private func cardWidget(card: CardItem, summary: BudgetSummary) -> some View {
        NavigationLink {
            CardDetailView(
                card: card,
                isPresentingAddExpense: .constant(false),
                onDone: {}
            )
        } label: {
            widgetCard(title: card.name, subtitle: "Tap to view", kind: .cards, span: WidgetSpan(width: 1, height: 2)) {
                VStack(alignment: .leading, spacing: 8) {
                    CardTileView(card: card, isInteractive: false, enableMotionShine: true, showsBaseShadow: false)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    if let balance = card.balance {
                        Text("\(formatCurrency(balance))")
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                    }
                }
                .frame(maxHeight: .infinity, alignment: .topLeading)
            }
        }
        .buttonStyle(.plain)
    }

    private func weekdayWidget(for summary: BudgetSummary) -> some View {
        return widgetLink(title: "Day of Week Spend", subtitle: weekdayRangeLabel, kind: .dayOfWeek, span: WidgetSpan(width: 1, height: 2), summary: summary) {
            if self.widgetBuckets.isEmpty {
                Text("No spending yet.")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                let fallbackGradient = weekdayGradientColors(for: summary)
                GeometryReader { geo in
                    let maxAmount = max(self.widgetBuckets.map(\.amount).max() ?? 1, 1)
                    let spacing: CGFloat = 8
                    let count = max(self.widgetBuckets.count, 1)
                    let barWidth = max((geo.size.width - spacing * CGFloat(count - 1)) / CGFloat(count), 10)
                    // Leave room for the footer label; let bars fill the rest.
                    let footerHeight: CGFloat = 28
                    let barAreaHeight = max(70, geo.size.height - footerHeight)

                    VStack(alignment: .leading, spacing: 8) {
                        HStack(alignment: .bottom, spacing: spacing) {
                            ForEach(self.widgetBuckets) { item in
                                let norm = max(min(item.amount / maxAmount, 1), 0)
                                let gradientColors = weekdayGradientColors(for: item, summary: summary, fallback: fallbackGradient)
                                let barColor = LinearGradient(
                                    colors: gradientColors.map { $0.opacity(0.35 + 0.35 * norm) },
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                                VStack(spacing: 4) {
                                    Rectangle()
                                        .fill(barColor)
                                        .frame(width: barWidth, height: max(CGFloat(norm) * (barAreaHeight - 20), 6))
                                        .clipShape(RoundedRectangle(cornerRadius: 3, style: .continuous))
                                    Text(item.label)
                                        .font(.caption2)
                                }
                            }
                        }
                        .frame(maxWidth: .infinity, minHeight: barAreaHeight, maxHeight: barAreaHeight, alignment: .bottomLeading)

                        if let maxItem = self.widgetBuckets.max(by: { $0.amount < $1.amount }) {
                            Text("Highest: \(maxItem.label) • \(formatCurrency(maxItem.amount))")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                }
                .frame(maxHeight: .infinity)
            }
        }
    }

    // MARK: Widget orchestration
    private func widgetItems(for summary: BudgetSummary) -> [WidgetItem] {
        var items: [WidgetItem] = [
            WidgetItem(id: .income, span: WidgetSpan(width: 1, height: 1), view: AnyView(incomeWidget(for: summary)), title: "Income", kind: .income),
            WidgetItem(id: .expenseToIncome, span: WidgetSpan(width: 1, height: 1), view: AnyView(expenseRatioWidget(for: summary)), title: "Expense to Income", kind: .budgets),
            WidgetItem(id: .savings, span: WidgetSpan(width: 1, height: 1), view: AnyView(savingsWidget(for: summary)), title: "Savings Outlook", kind: .budgets),
            WidgetItem(id: .nextPlanned, span: WidgetSpan(width: 1, height: 1), view: AnyView(nextPlannedExpenseWidget(for: summary)), title: "Next Planned Expense", kind: .cards),
            WidgetItem(id: .categorySpotlight, span: WidgetSpan(width: 1, height: 2), view: AnyView(categorySpotlightWidget(for: summary)), title: "Category Spotlight", kind: .presets),
            WidgetItem(id: .dayOfWeek, span: WidgetSpan(width: 1, height: 2), view: AnyView(weekdayWidget(for: summary)), title: "Day of Week Spend", kind: .dayOfWeek),
            WidgetItem(id: .caps, span: WidgetSpan(width: 1, height: 1), view: AnyView(capsWidget(for: summary)), title: "Caps & Alerts", kind: .caps),
            WidgetItem(id: .availability, span: WidgetSpan(width: 1, height: 3), view: AnyView(categoryAvailabilityWidget(for: summary)), title: "Category Availability", kind: .availability)
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
                    pinToggle(for: item.id, isPinned: pinnedIDs.contains(item.id))
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
    private func pinToggle(for id: WidgetID, isPinned: Bool) -> some View {
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
        if pinnedIDs.isEmpty {
            let decoded = decodeIDs(from: pinnedStorage).filter { available.contains($0) }
            let defaults = available
            pinnedIDs = decoded.isEmpty ? defaults : decoded
        } else {
            pinnedIDs = pinnedIDs.filter { available.contains($0) }
        }

        // Auto-add any newly discovered cards so they surface without manual pinning.
        let cardIDs = available.filter {
            if case .card = $0 { return true }
            return false
        }
        for cardID in cardIDs where !pinnedIDs.contains(cardID) {
            pinnedIDs.append(cardID)
        }

        if widgetOrder.isEmpty {
            let decoded = decodeIDs(from: orderStorage)
            widgetOrder = normalize(order: decoded.isEmpty ? available : decoded, available: available)
        } else {
            widgetOrder = normalize(order: widgetOrder, available: available)
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
    }

    private func persistOrder() {
        var unique: [WidgetID] = []
        for id in widgetOrder where !unique.contains(id) {
            unique.append(id)
        }
        widgetOrder = unique
        orderStorage = encodeIDs(unique)
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

    private func capsWidget(for summary: BudgetSummary) -> some View {
        let segment = availabilitySegment
        let statuses = capStatuses.filter { $0.segment == segment }
        let overCount = statuses.filter { $0.over }.count
        let nearCount = statuses.filter { $0.near && !$0.over }.count
        return widgetLink(title: "Caps & Alerts", subtitle: widgetRangeLabel, kind: .caps, span: WidgetSpan(width: 1, height: 1), summary: summary, capStatuses: capStatuses) {
            VStack(alignment: .leading, spacing: 8) {
                PillSegmentedControl(selection: availabilitySegmentBinding) {
                    ForEach(CategoryAvailabilitySegment.allCases) { segment in
                        Text(segment.title).tag(segment)
                    }
                }
                .ubSegmentedGlassStyle()
                .padding(.bottom, 2)
                if statuses.isEmpty {
                    Text("No caps for \(segment.title).")
                        .font(.ubCaption)
                        .foregroundStyle(.secondary)
                } else {
                    HStack {
                        Circle().fill(Color.red.opacity(0.15)).frame(width: 10, height: 10)
                        Text("Over: \(overCount)")
                    }
                    .font(.ubCaption)
                    HStack {
                        Circle().fill(Color.orange.opacity(0.2)).frame(width: 10, height: 10)
                        Text("Near: \(nearCount)")
                    }
                    .font(.ubCaption)
                }
            }
        }
    }

    private func categoryAvailabilityWidget(for summary: BudgetSummary) -> some View {
        let rowHeight: CGFloat = 64
        let rowSpacing: CGFloat = 8
        let maxRowsPerPage: Int = 6
        let tabPadding: CGFloat = 12
        let remainingIncome = max(summary.actualIncomeTotal - (summary.plannedExpensesActualTotal + summary.variableExpensesTotal), 0)

        return widgetLink(title: "Category Availability", subtitle: widgetRangeLabel, kind: .availability, span: WidgetSpan(width: 1, height: 3), summary: summary) {
            GeometryReader { geo in
                let segment = availabilitySegment
                let items = categoryAvailability(for: summary, segment: segment)
                let headerAllowance: CGFloat = 32
                let controlsAllowance: CGFloat = 64
                let availableHeight = max(0, geo.size.height - headerAllowance - controlsAllowance)
                let slotHeight = rowHeight + rowSpacing
                let rowsThatFit = max(3, Int(floor((availableHeight + rowSpacing) / slotHeight)))
                let pageSize = max(3, min(rowsThatFit, maxRowsPerPage))
                let pages = stride(from: 0, to: items.count, by: pageSize).map { idx in
                    Array(items[idx..<min(idx + pageSize, items.count)])
                }
                let pageSelection = Binding(
                    get: { min(availabilityPage, max(pages.count - 1, 0)) },
                    set: { availabilityPage = $0 }
                )
                let maxRowsOnPage = pages.map(\.count).max() ?? 0
                let tabHeight = max(0, CGFloat(maxRowsOnPage) * rowHeight + CGFloat(max(maxRowsOnPage - 1, 0)) * rowSpacing + tabPadding * 2)

                VStack(alignment: .leading, spacing: 0) {
                    HStack(spacing: 8) {
                        Label("Remaining Income", systemImage: "banknote")
                            .font(.ubCaption.weight(.semibold))
                        Spacer()
                        Text(formatCurrency(remainingIncome))
                            .font(.ubDetailLabel.weight(.bold))
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)

                    PillSegmentedControl(selection: availabilitySegmentBinding) {
                        ForEach(CategoryAvailabilitySegment.allCases) { segment in
                            Text(segment.title).tag(segment)
                        }
                    }
                    .ubSegmentedGlassStyle()
                    .padding(.horizontal, 14)
                    .padding(.bottom, 10)

                    Divider()
                        .padding(.horizontal, 14)
                        .opacity(0.35)

                    if pages.isEmpty {
                        Text("No categories yet.")
                            .foregroundStyle(.secondary)
                            .font(.ubCaption)
                            .frame(maxWidth: .infinity, minHeight: rowHeight * 2, alignment: .center)
                            .padding(.vertical, tabPadding)
                    } else {
                        TabView(selection: pageSelection) {
                            ForEach(Array(pages.enumerated()), id: \.offset) { idx, page in
                                VStack(spacing: rowSpacing) {
                                    ForEach(page) { item in
                                        CategoryAvailabilityRow(item: item, currencyFormatter: formatCurrency)
                                    }
                                }
                                .padding(.horizontal, 6)
                                .padding(.vertical, tabPadding)
                                .tag(idx)
                            }
                        }
                        .tabViewStyle(.page(indexDisplayMode: .never))
                        .indexViewStyle(PageIndexViewStyle(backgroundDisplayMode: .never))
                        .frame(height: min(tabHeight, availableHeight), alignment: .top)
                    }

                    if !pages.isEmpty && pages.count > 1 {
                        Divider()
                            .padding(.horizontal, 14)
                            .opacity(0.35)

                        HStack {
                            Spacer(minLength: 0)
                            HStack(spacing: 12) {
                                availabilityNavButton("chevron.left", isDisabled: availabilityPage == 0) {
                                    availabilityPage = max(0, availabilityPage - 1)
                                }

                                HStack(spacing: 8) {
                                    ForEach(0..<pages.count, id: \.self) { idx in
                                        RoundedRectangle(cornerRadius: 4, style: .continuous)
                                            .fill(idx == availabilityPage ? Color.primary.opacity(0.9) : Color.primary.opacity(0.35))
                                            .frame(width: idx == availabilityPage ? 20 : 9, height: 7)
                                    }
                                }

                                availabilityNavButton("chevron.right", isDisabled: availabilityPage >= pages.count - 1) {
                                    availabilityPage = min(pages.count - 1, availabilityPage + 1)
                                }
                            }
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 10)
                            Spacer(minLength: 0)
                        }
                    }
                }
                .padding(.top, 6)
                .onChange(of: availabilitySegmentRawValue) { _ in availabilityPage = 0 }
            }
        }
    }

    @ViewBuilder
    private func availabilityNavButton(_ systemName: String, isDisabled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.body.weight(.semibold))
                .foregroundStyle(.primary)
                .frame(width: 32, height: 32)
                .background(
                    Group {
                        if #available(iOS 26.0, macCatalyst 26.0, *) {
                            Circle()
                                .fill(.ultraThinMaterial)
                                .glassEffect(.regular, in: .rect(cornerRadius: 16))
                        } else {
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .fill(Color.primary.opacity(0.08))
                        }
                    }
                    .opacity(isDisabled ? 0.45 : 1)
                )
        }
        .buttonStyle(.plain)
        .opacity(isDisabled ? 0.45 : 1)
        .disabled(isDisabled)
    }


    // MARK: Widget Helpers
    private func widgetLink<Content: View>(
        title: String,
        subtitle: String? = nil,
        kind: HomeWidgetKind,
        span: WidgetSpan,
        summary: BudgetSummary,
        snapshot: PlannedExpenseSnapshot? = nil,
        topCategory: BudgetSummary.CategorySpending? = nil,
        capStatuses: [CapStatus]? = nil,
        @ViewBuilder content: @escaping () -> Content
    ) -> some View {
        NavigationLink {
            MetricDetailView(
                title: title,
                kind: kind,
                range: currentRange,
                period: vm.period,
                summary: summary,
                nextExpense: snapshot,
                topCategory: topCategory,
                capStatuses: capStatuses
            )
        } label: {
            widgetCard(title: title, subtitle: subtitle, kind: kind, span: span, content: content)
        }
        .buttonStyle(.plain)
    }

    private func widgetCard<Content: View>(title: String, subtitle: String? = nil, kind: HomeWidgetKind, span: WidgetSpan, @ViewBuilder content: () -> Content) -> some View {
        let body = content()
        return GeometryReader { geo in
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .firstTextBaseline) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(title)
                            .font(.ubWidgetTitle)
                            .foregroundStyle(kind.titleColor)
                        if let subtitle {
                            Text(subtitle)
                                .font(.ubWidgetSubtitle)
                                .foregroundStyle(.secondary)
                        }
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(.secondary)
                }
                body
                Spacer(minLength: 0)
            }
            .padding(16)
            .frame(width: geo.size.width, height: geo.size.height, alignment: .topLeading)
        }
        .frame(minHeight: CGFloat(max(span.height, 1)) * gridRowHeight, alignment: .topLeading)
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
        syncPickers(with: currentRange)
        vm.startIfNeeded()
        let summary = primarySummary
        await loadNextPlannedExpense(for: summary)
        await loadWidgetBuckets(for: summary)
        await loadAllCards()
        await loadCaps(for: summary)
    }

    private func stateDidChange() async {
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

    @ViewBuilder
    private func applyButton(_ disabled: Bool) -> some View {
        if #available(iOS 26.0, macCatalyst 26.0, *) {
            Button(action: applyCustomRangeFromPickers) {
                Image(systemName: "arrow.right")
                    .font(.headline.weight(.semibold))
                    .frame(width: 36, height: 36)
                    .glassEffect(.regular.tint(.clear).interactive(true))
            }
            .buttonStyle(.plain)
            .buttonBorderShape(.circle)
            .tint(.accentColor)
            .disabled(disabled)
        } else {
            Button(action: applyCustomRangeFromPickers) {
                Image(systemName: "arrow.right")
                    .font(.headline.weight(.semibold))
            }
            .buttonStyle(.plain)
            .disabled(disabled)
        }
    }

    @ViewBuilder
    private var periodMenu: some View {
        if #available(iOS 26.0, macCatalyst 26.0, *) {
            Menu {
                periodMenuItems
            } label: {
                Image(systemName: "calendar")
                    .font(.headline.weight(.semibold))
                    .frame(width: 36, height: 36)
                    .glassEffect(.regular.tint(.clear).interactive(true))
            }
            .buttonStyle(.plain)
            .buttonBorderShape(.circle)
            .tint(.accentColor)
        } else {
            Menu {
                periodMenuItems
            } label: {
                Image(systemName: "calendar")
                    .font(.headline.weight(.semibold))
            }
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
            await MainActor.run { nextPlannedSnapshot = nil }
            return
        }
        let range = currentRange
        let selectedDate = await MainActor.run { vm.selectedDate }
        let anchorDate = nextExpenseAnchorDate(for: range, selectedDate: selectedDate)
        let bgContext = CoreDataService.shared.newBackgroundContext()
        let snapshot: PlannedExpenseSnapshot? = await bgContext.perform {
            guard let budget = try? bgContext.existingObject(with: summary.id) as? Budget else { return nil }
            let fetch = NSFetchRequest<PlannedExpense>(entityName: "PlannedExpense")
            fetch.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
                NSPredicate(format: "budget == %@", budget),
                NSPredicate(format: "transactionDate >= %@ AND transactionDate <= %@", range.lowerBound as NSDate, range.upperBound as NSDate)
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
        await MainActor.run { nextPlannedSnapshot = snapshot }
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
        let selectedDate = vm.selectedDate
        let focusDate = preferredFocusDate(in: range, selectedDate: selectedDate)
        let period = resolvedPeriod(vm.period, range: range)

        let dayTotals = await daySpendTotals(for: summary, in: range)

        func clamp(_ source: ClosedRange<Date>, to bounds: ClosedRange<Date>) -> ClosedRange<Date> {
            let lower = max(source.lowerBound, bounds.lowerBound)
            let upper = min(source.upperBound, bounds.upperBound)
            return lower...upper
        }

        let buckets: [SpendBucket]
        var displayRange = range
        switch period {
        case .daily:
            buckets = bucketsForDays(in: range, dayTotals: dayTotals)
        case .weekly:
            buckets = bucketsForDays(in: range, dayTotals: dayTotals)
        case .biWeekly:
            let weekRange = BudgetPeriod.weekly.range(containing: focusDate)
            let bounded = clamp(weekRange.start...weekRange.end, to: range)
            displayRange = bounded
            buckets = bucketsForDays(in: bounded, dayTotals: dayTotals)
        case .monthly:
            let weekRange = BudgetPeriod.weekly.range(containing: focusDate)
            let bounded = clamp(weekRange.start...weekRange.end, to: range)
            displayRange = bounded
            buckets = bucketsForDays(in: bounded, dayTotals: dayTotals)
        case .quarterly:
            let monthRange = BudgetPeriod.monthly.range(containing: focusDate)
            let bounded = clamp(monthRange.start...monthRange.end, to: range)
            displayRange = bounded
            buckets = bucketsForWeeks(in: bounded, dayTotals: dayTotals)
        case .yearly:
            buckets = bucketsForMonths(in: range, dayTotals: dayTotals)
        case .custom:
            buckets = bucketsForDays(in: range, dayTotals: dayTotals)
        }

        await MainActor.run {
            widgetBuckets = buckets
            weekdayRangeOverride = displayRange
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
        req.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]
        let fetched = (try? ctx.fetch(req)) ?? []
        let items: [CardItem] = fetched.map { card in
            var item = CardItem(from: card)
            // Aggregate unplanned + planned actual expenses in the current range as balance.
            let expenseReq = NSFetchRequest<UnplannedExpense>(entityName: "UnplannedExpense")
            expenseReq.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
                NSPredicate(format: "card == %@", card),
                NSPredicate(format: "transactionDate >= %@ AND transactionDate <= %@", range.lowerBound as NSDate, range.upperBound as NSDate)
            ])
            if let expenses = try? ctx.fetch(expenseReq) {
                let variableTotal = expenses.reduce(0) { $0 + $1.amount }
                var plannedTotal: Double = 0
                if let cardUUID = card.value(forKey: "id") as? UUID {
                    let plannedReq = NSFetchRequest<PlannedExpense>(entityName: "PlannedExpense")
                    plannedReq.predicate = NSPredicate(format: "card.id == %@ AND isGlobal == NO AND transactionDate >= %@ AND transactionDate <= %@",
                                                       cardUUID as CVarArg, range.lowerBound as NSDate, range.upperBound as NSDate)
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

    private static func readPlannedDescription(_ object: NSManagedObject) -> String? {
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
    struct PlannedExpenseSnapshot: Identifiable {
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
    @State private var expenseIncomeSeries: [DatedValue] = []
    @State private var savingsSeries: [SavingsPoint] = []
    @State private var ratioSelection: DatedValue?
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
    @State private var scenarioAllocations: [String: Double] = [:]
    @State private var scenarioWidth: CGFloat = 0
    @AppStorage("homeAvailabilitySegment") private var detailAvailabilitySegmentRawValue: String = CategoryAvailabilitySegment.combined.rawValue
    private var detailAvailabilitySegment: CategoryAvailabilitySegment {
        CategoryAvailabilitySegment(rawValue: detailAvailabilitySegmentRawValue) ?? .combined
    }
    private var detailAvailabilitySegmentBinding: Binding<CategoryAvailabilitySegment> {
        Binding(
            get: { detailAvailabilitySegment },
            set: { detailAvailabilitySegmentRawValue = $0.rawValue }
        )
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
        case .budgets:
            budgetContent
        case .cards:
            nextExpenseContent
        case .presets:
            categoryContent
        case .caps:
            capsContent
        case .dayOfWeek:
            weekdayContent
        case .availability:
            availabilityContent
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
        VStack(alignment: .leading, spacing: 12) {
            Text("Day-of-Week Spend")
                .font(.headline)
            if spendSections.isEmpty {
                Text("No spending in this range.")
                    .foregroundStyle(.secondary)
            } else {
                let fallbackGradient = weekdayGradientColors(for: summary)
                ForEach(spendSections) { section in
                    VStack(alignment: .leading, spacing: 8) {
                        Text(section.title)
                            .font(.subheadline.weight(.semibold))
                        if let subtitle = section.subtitle {
                            Text(subtitle)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Chart(section.buckets) { item in
                            let gradientColors = weekdayGradientColors(for: item, summary: summary, fallback: fallbackGradient)
                            BarMark(
                                x: .value("Period", item.label),
                                y: .value("Amount", item.amount)
                            )
                            .foregroundStyle(
                                LinearGradient(
                                    colors: gradientColors.map { $0.opacity(0.85) },
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                        }
                        .chartYAxis {
                            AxisMarks(position: .leading) { value in
                                if let val = value.as(Double.self) {
                                    AxisGridLine()
                                    AxisTick()
                                    AxisValueLabel(formatCurrency(val))
                                }
                            }
                        }
                        .frame(height: 200)
                        if let maxItem = section.buckets.max(by: { $0.amount < $1.amount }) {
                            Text("Highest: \(maxItem.label) • \(formatCurrency(maxItem.amount))")
                                .font(.caption)
                                .foregroundStyle(.secondary)
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
                            Circle().fill(cap.color).frame(width: 10, height: 10)
                            Text(cap.name)
                                .font(.ubDetailLabel.weight(.semibold))
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


    private var budgetContent: some View {
        let expenses = summary.plannedExpensesActualTotal + summary.variableExpensesTotal
        let income = max(max(summary.actualIncomeTotal, summary.potentialIncomeTotal), 1)
        let ratio = expenses / income
        let projected = summary.potentialIncomeTotal - summary.plannedExpensesPlannedTotal - summary.variableExpensesTotal
        let ratioPoints = expenseIncomeSeries.isEmpty ? fallbackRatioSeries(expenses: expenses, income: income) : expenseIncomeSeries
        let savingsPoints = savingsSeries.isEmpty ? fallbackSavingsSeries(projected: projected, actual: summary.actualSavingsTotal) : savingsSeries
        return VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Expense to Income")
                    .font(.headline)
                ratioChart(points: ratioPoints)
            }
            VStack(alignment: .leading, spacing: 8) {
                Text("Savings Outlook")
                    .font(.headline)
                savingsChart(points: savingsPoints)
            }
            VStack(alignment: .leading, spacing: 8) {
                metricRow(label: "Expense/Income", value: String(format: "%.0f%%", ratio * 100))
                metricRow(label: "Expenses", value: formatCurrency(expenses))
                metricRow(label: "Projected Savings", value: formatCurrency(projected))
                metricRow(label: "Actual Savings", value: formatCurrency(summary.actualSavingsTotal))
            }
        }
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
                        centerTitle: "Top",
                        centerValue: formatCurrency(leadingCategory.amount)
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
        let remainingIncome = max(summary.actualIncomeTotal - (summary.plannedExpensesActualTotal + summary.variableExpensesTotal), 0)
        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Remaining Income")
                    .font(.ubSectionTitle)
                Spacer()
                Text(formatCurrency(remainingIncome))
                    .font(.ubMetricValue)
            }
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
                VStack(spacing: 10) {
                    ForEach(items) { item in
                        CategoryAvailabilityRow(item: item, currencyFormatter: formatCurrency)
                    }
                    scenarioPlanner(items: items, remainingIncome: remainingIncome, segment: segment)
                }
            }
        }
        .onChange(of: detailAvailabilitySegmentRawValue) { _ in
            scenarioAllocations.removeAll()
        }
    }

    @ViewBuilder
    private func scenarioPlanner(items: [CategoryAvailability], remainingIncome: Double, segment: CategoryAvailabilitySegment) -> some View {
        let totalAllocated = items.reduce(0) { $0 + allocationValue(for: $1, segment: segment) }
        let potentialSavings = remainingIncome - totalAllocated
        let slices = scenarioSlices(items: items, savings: potentialSavings, segment: segment)
        let savingsGradient = potentialSavings >= 0 ? scenarioGradient(for: items) : nil
        let savingsColor = potentialSavings >= 0
            ? (savingsGradient == nil ? HomeView.HomePalette.income : scenarioAverageColor(for: items))
            : Color.red.opacity(0.85)
        let savingsTextStyle = savingsGradient ?? uniformAngularGradient(savingsColor)

        VStack(alignment: .leading, spacing: 12) {
            Divider().padding(.top, 4)
            Text("What If? Scenario Planner")
                .font(.ubSectionTitle)
            Text("Adjust category allocations to see how much you could still save.")
                .font(.ubBody)
                .foregroundStyle(.secondary)

            HStack {
                Text(potentialSavings >= 0 ? "Potential Savings" : "Over-allocated")
                    .font(.ubDetailLabel.weight(.semibold))
                Spacer()
                Text(formatCurrency(potentialSavings))
                    .font(.ubMetricValue)
                    .foregroundStyle(savingsTextStyle)
                    .shadow(color: Color.primary.opacity(0.08), radius: 1, x: 0, y: 1)
            }

            let width = scenarioWidth > 0 ? scenarioWidth : scenarioPlannerDefaultWidth()
            let donutSize = min(max(width * 0.38, 180), 320)
            let listWidth = max(width - donutSize - 16, width * 0.48)

            HStack(alignment: .top, spacing: 16) {
                CategoryDonutView(
                    slices: slices,
                    total: max(slices.map(\.amount).reduce(0, +), 1),
                    centerTitle: potentialSavings >= 0 ? "Potential Savings" : "Deficit",
                    centerValue: formatCurrency(potentialSavings),
                    savingsGradient: savingsGradient,
                    centerValueGradient: savingsTextStyle
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
        .onAppear { ensureScenarioDefaults(items: items, segment: segment) }
        .onChange(of: items.map { scenarioKey(for: $0, segment: segment) }) { _ in
            ensureScenarioDefaults(items: items, segment: segment)
        }
    }

    private func scenarioAllocationRow(item: CategoryAvailability, segment: CategoryAvailabilitySegment) -> some View {
        let binding = allocationBinding(for: item, segment: segment)

        return VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline) {
                HStack(spacing: 6) {
                    Circle().fill(item.color).frame(width: 10, height: 10)
                    Text(item.name)
                }
                    .font(.ubDetailLabel.weight(.semibold))
                    .lineLimit(1)
            }
            HStack(spacing: 12) {
                TextField("0", value: binding, formatter: allocationFormatter)
                    .textFieldStyle(.roundedBorder)
                    .keyboardType(.decimalPad)
                    .frame(minWidth: 120, maxWidth: 170, alignment: .leading)
                Spacer()
                Stepper("", value: binding, in: 0...1_000_000, step: 25)
                    .labelsHidden()
            }
        }
    }

    private func ensureScenarioDefaults(items: [CategoryAvailability], segment: CategoryAvailabilitySegment) {
        var next = scenarioAllocations
        let keys = items.map { scenarioKey(for: $0, segment: segment) }
        let keySet = Set(keys)
        for item in items {
            let key = scenarioKey(for: item, segment: segment)
            if next[key] == nil {
                next[key] = max(item.available, 0)
            }
        }
        let prefix = scenarioKeyPrefix(for: segment)
        next = next.filter { entry in
            guard entry.key.hasPrefix(prefix) else { return true }
            return keySet.contains(entry.key)
        }
        if next != scenarioAllocations {
            scenarioAllocations = next
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
        return scenarioAllocations[key] ?? item.available
    }

    private func allocationBinding(for item: CategoryAvailability, segment: CategoryAvailabilitySegment) -> Binding<Double> {
        let key = scenarioKey(for: item, segment: segment)
        return Binding(
            get: { allocationValue(for: item, segment: segment) },
            set: { newValue in
                scenarioAllocations[key] = max(newValue, 0)
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

private func scenarioSlices(items: [CategoryAvailability], savings: Double, segment: CategoryAvailabilitySegment) -> [CategorySlice] {
    var slices: [CategorySlice] = items.compactMap { item in
        let amount = allocationValue(for: item, segment: segment)
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
        HStack {
            Text(label)
                .font(.ubBody)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(.ubMetricValue)
        }
    }

    // MARK: Income Sections
    private func incomeTimelineSection(total: Double) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Timeline & Pace")
                    .font(.ubSectionTitle)
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

            let maxVal = max((actualLineSeries.map(\.value).max() ?? 0), (plannedSeries.map(\.value).max() ?? 0), 1)
            let domain: ClosedRange<Double> = 0...(maxVal * 1.1)
            VStack(alignment: .leading, spacing: 8) {
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
                    AxisMarks(values: .automatic(desiredCount: 3))
                }
                .chartYAxis {
                    AxisMarks(position: .leading) { value in
                        if let val = value.as(Double.self) {
                            AxisGridLine()
                            AxisTick()
                            AxisValueLabel(formatCurrency(val))
                        }
                    }
                }
                .frame(height: 220)
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

                if let selected = timelineSelection {
                    Text("\(dateString(selected.date)) • \(formatCurrency(selected.value))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    HStack(spacing: 16) {
                        Label("Planned Income", systemImage: "circle.fill")
                            .foregroundStyle(plannedLineColor)
                            .font(.caption)
                        Label("Actual Income", systemImage: "circle.fill")
                            .foregroundStyle(actualLineColor.opacity(0.9))
                            .font(.caption)
                    }
                }
            }
        }
    }

    private var incomeMoMSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Trends")
                    .font(.ubSectionTitle)
                Spacer()
                Picker("Period", selection: $comparisonPeriod) {
                    ForEach(IncomeComparisonPeriod.allCases) { period in
                        Text(period.title).tag(period)
                    }
                }
                .pickerStyle(.menu)
            }
            if incomeBuckets.isEmpty {
                Text("No income history for this period size.")
                    .foregroundStyle(.secondary)
            } else {
                Chart(incomeBuckets) { bucket in
                    BarMark(
                        x: .value("Period", bucket.label),
                        y: .value("Total", bucket.total)
                    )
                    .foregroundStyle(HomeView.HomePalette.income.opacity(0.8))
                }
                .chartYAxis {
                    AxisMarks(position: .leading) { value in
                        if let val = value.as(Double.self) {
                            AxisGridLine()
                            AxisTick()
                            AxisValueLabel(formatCurrency(val))
                        }
                    }
                }
                .frame(height: 180)
            }
        }
    }

    private var quickIncomeActions: some View {
        HStack(spacing: 12) {
            Button {
                showAddIncomeSheet = true
            } label: {
                Label("Add Income", systemImage: "plus.circle.fill")
                    .font(.subheadline.weight(.semibold))
            }
            .buttonStyle(.borderedProminent)
            .tint(HomeView.HomePalette.income)

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
        .sheet(isPresented: $showAddIncomeSheet) {
            AddIncomeFormView(incomeObjectID: nil, budgetObjectID: nil, initialDate: nil)
                .environment(\.managedObjectContext, CoreDataService.shared.viewContext)
        }
        .sheet(item: $editingIncomeBox) { box in
            AddIncomeFormView(incomeObjectID: box.id, budgetObjectID: nil, initialDate: nil)
                .environment(\.managedObjectContext, CoreDataService.shared.viewContext)
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
            self.expenseIncomeSeries = series.ratioPoints
            self.savingsSeries = series.savingsPoints
            self.spendSections = sections
            self.incomeTimeline = income.received
            self.expectedTimeline = income.expected
            self.incomeBuckets = income.buckets
            self.latestIncomeID = income.latestIncomeID
        }
    }

    private struct DailySeriesResult {
        let ratioPoints: [DatedValue]
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
                    ratioPoints: fallbackRatioSeries(expenses: summary.plannedExpensesActualTotal + summary.variableExpensesTotal, income: max(summary.actualIncomeTotal, 1)),
                    savingsPoints: fallbackSavingsSeries(projected: projected, actual: summary.actualSavingsTotal)
                )
            }

            let dates = allDates(in: range)
            if dates.isEmpty {
                let projected = summary.potentialIncomeTotal - summary.plannedExpensesPlannedTotal - summary.variableExpensesTotal
                return DailySeriesResult(
                    ratioPoints: fallbackRatioSeries(expenses: summary.plannedExpensesActualTotal + summary.variableExpensesTotal, income: max(summary.actualIncomeTotal, 1)),
                    savingsPoints: fallbackSavingsSeries(projected: projected, actual: summary.actualSavingsTotal)
                )
            }

            var incomeDaily: [Date: Double] = [:]
            var expenseDaily: [Date: Double] = [:]
            // Incomes (actual)
            let incomeReq = NSFetchRequest<Income>(entityName: "Income")
            let incomeStart = startOfDay(range.lowerBound)
            let incomeEndDay = startOfDay(range.upperBound)
            let incomeEndExclusive = Calendar.current.date(byAdding: .day, value: 1, to: incomeEndDay) ?? range.upperBound
            incomeReq.predicate = NSPredicate(format: "date >= %@ AND date < %@", incomeStart as NSDate, incomeEndExclusive as NSDate)
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
                NSPredicate(format: "transactionDate >= %@ AND transactionDate <= %@", range.lowerBound as NSDate, range.upperBound as NSDate)
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
                    NSPredicate(format: "transactionDate >= %@ AND transactionDate <= %@", range.lowerBound as NSDate, range.upperBound as NSDate)
                ])
                if let vars = try? ctx.fetch(varReq) {
                    for exp in vars {
                        let day = startOfDay(exp.transactionDate ?? range.lowerBound)
                        expenseDaily[day, default: 0] += exp.amount
                    }
                }
            }

            var ratioPoints: [DatedValue] = []
            var savingsPoints: [SavingsPoint] = []

            var cumulativeIncome = 0.0
            var cumulativeExpense = 0.0

            let projectedTotalExpense = summary.plannedExpensesPlannedTotal + summary.variableExpensesTotal
            let daysCount = max(dates.count, 1)

            for (idx, day) in dates.enumerated() {
                cumulativeIncome += incomeDaily[day] ?? 0
                cumulativeExpense += expenseDaily[day] ?? 0
                let safeIncome = cumulativeIncome == 0 ? 1 : cumulativeIncome
                ratioPoints.append(DatedValue(date: day, value: cumulativeExpense / safeIncome))

                let fraction = Double(idx + 1) / Double(daysCount)
                let projectedIncomeLine = summary.potentialIncomeTotal * fraction
                let projectedExpenseLine = projectedTotalExpense * fraction
                let projectedNet = projectedIncomeLine - projectedExpenseLine
                let actualNet = cumulativeIncome - cumulativeExpense
                savingsPoints.append(SavingsPoint(date: day, actual: actualNet, projected: projectedNet))

            }

            if ratioPoints.count == 1, let first = ratioPoints.first {
                ratioPoints.append(DatedValue(date: range.upperBound, value: first.value))
            }
            if savingsPoints.count == 1, let first = savingsPoints.first {
                savingsPoints.append(SavingsPoint(date: range.upperBound, actual: first.actual, projected: first.projected))
            }

            return DailySeriesResult(
                ratioPoints: ratioPoints,
                savingsPoints: savingsPoints
            )
        }
    }

    private func computeSpendSections() async -> [SpendChartSection] {
        let resolved = resolvedPeriod(period, range: range)
        let dayTotals = await daySpendTotals(for: summary, in: range)

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
            let buckets = bucketsForDays(in: range, dayTotals: dayTotals)
            return [SpendChartSection(title: dayFormatter.string(from: range.lowerBound), subtitle: nil, buckets: buckets)]
        case .weekly:
            let buckets = bucketsForDays(in: range, dayTotals: dayTotals)
            return [SpendChartSection(title: weekTitle(range), subtitle: nil, buckets: buckets)]
        case .biWeekly:
            let weeks = weeksInRange(range)
            return weeks.map { week in
                let buckets = bucketsForDays(in: week, dayTotals: dayTotals)
                return SpendChartSection(title: weekTitle(week), subtitle: dayFormatter.string(from: week.lowerBound) + " – " + dayFormatter.string(from: week.upperBound), buckets: buckets)
            }
        case .monthly:
            let weeks = weeksInRange(range)
            let monthTitle = monthFormatter.string(from: range.lowerBound)
            return weeks.enumerated().map { idx, week in
                let buckets = bucketsForDays(in: week, dayTotals: dayTotals)
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
            let monthBuckets = bucketsForMonths(in: range, dayTotals: dayTotals)
            let title = yearFormatter.string(from: range.lowerBound)
            return [SpendChartSection(title: title, subtitle: nil, buckets: monthBuckets)]
        case .custom:
            let buckets = bucketsForDays(in: range, dayTotals: dayTotals)
            return [SpendChartSection(title: dayFormatter.string(from: range.lowerBound) + " – " + dayFormatter.string(from: range.upperBound), subtitle: nil, buckets: buckets)]
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
        return await ctx.perform {
            let dates = allDates(in: range)
            var incomeDaily: [Date: Double] = [:]
            var expectedDaily: [Date: Double] = [:]
            let incomeReq = NSFetchRequest<Income>(entityName: "Income")
            let incomeStart = startOfDay(range.lowerBound)
            let incomeEndDay = startOfDay(range.upperBound)
            let incomeEndExclusive = Calendar.current.date(byAdding: .day, value: 1, to: incomeEndDay) ?? range.upperBound
            incomeReq.predicate = NSPredicate(format: "date >= %@ AND date < %@", incomeStart as NSDate, incomeEndExclusive as NSDate)
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
            let buckets = computeIncomeBuckets(using: ctx, period: comparisonPeriod)
            let latestIncomeID = incomes.last?.objectID
            return IncomeTimelineResult(received: received, expected: expected, buckets: buckets, latestIncomeID: latestIncomeID)
        }
    }

    private func computeIncomeBuckets(using ctx: NSManagedObjectContext, period: IncomeComparisonPeriod) -> [IncomeBucket] {
        var buckets: [IncomeBucket] = []
        let calendar = Calendar.current
        let end = range.upperBound
        let count = 6
        for i in 0..<count {
            guard let bucketRange = bucketRange(endingAt: end, index: i, period: period, calendar: calendar) else { continue }
            let incomeReq = NSFetchRequest<Income>(entityName: "Income")
            incomeReq.predicate = NSPredicate(format: "date >= %@ AND date <= %@", bucketRange.start as NSDate, bucketRange.end as NSDate)
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
    private func ratioChart(points: [DatedValue]) -> some View {
        if points.isEmpty {
            Text("Not enough data for this range.")
                .foregroundStyle(.secondary)
        } else {
            let clampedPoints = points.map { DatedValue(date: $0.date, value: min($0.value, 2.0)) }
            let values = clampedPoints.map(\.value)
            let minVal = values.min() ?? 0
            let maxVal = values.max() ?? 1
            let lineColor = Color.orange
            let targetColor = Color.blue.opacity(0.65)
            let upper = max(maxVal, 1)
            let pad = max((upper - minVal) * 0.12, 0.05)
            let domain: ClosedRange<Double> = 0...(upper + pad)
            let latest = clampedPoints.last

            Chart {
                ForEach(clampedPoints) { point in
                    AreaMark(
                        x: .value("Date", point.date),
                        yStart: .value("Zero", 0),
                        yEnd: .value("Expense to Income", point.value)
                    )
                    .interpolationMethod(.linear)
                    .foregroundStyle(lineColor.opacity(0.18))
                }

                ForEach(clampedPoints) { point in
                    LineMark(
                        x: .value("Date", point.date),
                        y: .value("Expense to Income", point.value)
                    )
                    .interpolationMethod(.linear)
                    .foregroundStyle(lineColor)
                    PointMark(
                        x: .value("Date", point.date),
                        y: .value("Expense to Income", point.value)
                    )
                    .foregroundStyle(lineColor)
                    .symbolSize(point.id == latest?.id ? 32 : 22)
                }
                if let selected = ratioSelection {
                    RuleMark(x: .value("Selected", selected.date))
                        .foregroundStyle(lineColor.opacity(0.35))
                }
                RuleMark(y: .value("100%", 1.0))
                    .foregroundStyle(targetColor)
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 4]))
                    .annotation(position: .trailing) {
                        Text("Target 100%")
                            .font(.caption2)
                            .foregroundStyle(targetColor)
                    }
            }
            .chartYScale(domain: domain)
            .chartXAxisLabel("Date")
            .chartYAxisLabel("Expense to Income")
            .chartYAxis {
                AxisMarks(position: .leading) { value in
                    if let val = value.as(Double.self) {
                        AxisGridLine()
                        AxisTick()
                        AxisValueLabel(String(format: "%.0f%%", val * 100))
                    }
                }
            }
            .chartXAxis {
                AxisMarks(values: .automatic(desiredCount: 3))
            }
            .frame(height: 200)
            .chartOverlay { proxy in
                GeometryReader { geo in
                    Rectangle().fill(.clear).contentShape(Rectangle())
                        .gesture(
                            DragGesture(minimumDistance: 0)
                                .onChanged { gesture in
                                    let origin = geo[proxy.plotAreaFrame].origin
                                    let locationX = gesture.location.x - origin.x
                                    if let date: Date = proxy.value(atX: locationX) {
                                        ratioSelection = nearestPoint(in: clampedPoints, to: date)
                                    }
                                }
                                .onEnded { _ in ratioSelection = nil }
                        )
                }
            }

            HStack(spacing: 12) {
                Label("Expense to Income", systemImage: "circle.fill")
                    .foregroundStyle(lineColor)
                    .font(.caption)
                Label("Target 100%", systemImage: "minus")
                    .foregroundStyle(targetColor)
                    .font(.caption)
            }

            if let selected = ratioSelection {
                let capped = min(selected.value, 2.0)
                let formatted = selected.value > 2 ? "≥200%" : String(format: "%.0f%%", capped * 100)
                Text("\(dateString(selected.date)) • \(formatted)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else if let latest {
                Text("Latest: \(dateString(latest.date)) • \(String(format: "%.0f%%", latest.value * 100))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
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

            VStack(alignment: .leading, spacing: 6) {
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
                .chartYAxis {
                    AxisMarks(position: .leading) { value in
                        if let val = value.as(Double.self) {
                            AxisGridLine()
                            AxisTick()
                            AxisValueLabel(formatCurrency(val))
                        }
                    }
                }
                .frame(height: 220)
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

                HStack(spacing: 12) {
                    Label("Actual", systemImage: "circle.fill")
                        .labelStyle(.titleAndIcon)
                        .foregroundStyle(actualColor)
                        .font(.caption)
                    Label("Projected", systemImage: "circle.fill")
                        .labelStyle(.titleAndIcon)
                        .foregroundStyle(projectedColor)
                        .font(.caption)
                    if let selected = savingsSelection {
                        Text("\(dateString(selected.date)) • \(formatCurrency(selected.actual)) / \(formatCurrency(selected.projected))")
                            .font(.caption)
                            .foregroundStyle(.secondary)
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
        return HStack {
            Circle().fill(color).frame(width: 10, height: 10)
            Text(cat.categoryName)
                .font(.subheadline.weight(.semibold))
            Spacer()
            Text(formatCurrency(cat.amount))
                .font(.subheadline)
            Text(String(format: "%.0f%%", share * 100))
                .font(.caption)
                .foregroundStyle(.secondary)
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

    var body: some View {
        let symbolWidth: CGFloat = 14
        let dotColor = UBColorFromHex(expense?.expenseCategory?.color) ?? .secondary
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 2) {
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Circle().fill(dotColor).frame(width: 8, height: 8)
                        .frame(width: symbolWidth, alignment: .leading)
                    Text(snapshot.title)
                        .font(.headline)
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
                    .frame(width: 12, height: 8)
            } else {
                RoundedRectangle(cornerRadius: 2, style: .continuous)
                    .stroke(Color.primary.opacity(0.12), lineWidth: 1)
                    .frame(width: 12, height: 8)
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

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            cardPreview
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
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
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private var cardPreview: some View {
        if let cardItem {
            CardTileView(card: cardItem, isInteractive: false, enableMotionShine: true, showsBaseShadow: false)
                .frame(width: 120)
        } else {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Color.secondary.opacity(0.12))
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .stroke(Color.primary.opacity(0.12), lineWidth: 1)
                )
                .frame(width: 120, height: 76)
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
    var categoryTotals: [String: Double]
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
            if amount > 0,
               let hex = category?.color?.trimmingCharacters(in: .whitespacesAndNewlines),
               !hex.isEmpty {
                entry.categoryTotals[hex, default: 0] += amount
            }
            totals[day] = entry
        }

        // Planned expenses
        let plannedReq = NSFetchRequest<PlannedExpense>(entityName: "PlannedExpense")
        plannedReq.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
            NSPredicate(format: "budget == %@", budget),
            NSPredicate(format: "transactionDate >= %@ AND transactionDate <= %@", range.lowerBound as NSDate, range.upperBound as NSDate)
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
                NSPredicate(format: "transactionDate >= %@ AND transactionDate <= %@", range.lowerBound as NSDate, range.upperBound as NSDate)
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

private func bucketsForDays(in range: ClosedRange<Date>, dayTotals: [Date: DaySpendTotal]) -> [SpendBucket] {
    let cal = Calendar.current
    let weekdays = cal.shortWeekdaySymbols
    let dates = daysInRange(range)
    return dates.map { day in
        let entry = dayTotals[day] ?? DaySpendTotal(total: 0, categoryTotals: [:])
        let weekdayIndex = cal.component(.weekday, from: day) - 1
        let dayLabel = weekdays.indices.contains(weekdayIndex) ? weekdays[weekdayIndex] : "Day"
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        let label = dates.count == 1 ? formatter.string(from: day) : dayLabel
        let sortedHexes = entry.categoryTotals.sorted { $0.value > $1.value }.map(\.key)
        return SpendBucket(label: label, start: day, end: day, amount: entry.total, categoryHexColors: sortedHexes)
    }
}

private func bucketsForWeeks(in range: ClosedRange<Date>, dayTotals: [Date: DaySpendTotal]) -> [SpendBucket] {
    let formatter = DateFormatter()
    formatter.dateFormat = "MMM d"
    return weeksInRange(range).map { weekRange in
        let days = daysInRange(weekRange)
        var total = 0.0
        var catTotals: [String: Double] = [:]
        for day in days {
            let entry = dayTotals[day] ?? DaySpendTotal(total: 0, categoryTotals: [:])
            total += entry.total
            for (hex, amt) in entry.categoryTotals {
                catTotals[hex, default: 0] += amt
            }
        }
        let startLabel = formatter.string(from: weekRange.lowerBound)
        let endLabel = formatter.string(from: weekRange.upperBound)
        let label = "\(startLabel) – \(endLabel)"
        let sortedHexes = catTotals.sorted { $0.value > $1.value }.map(\.key)
        return SpendBucket(label: label, start: weekRange.lowerBound, end: weekRange.upperBound, amount: total, categoryHexColors: sortedHexes)
    }
}

private func bucketsForMonths(in range: ClosedRange<Date>, dayTotals: [Date: DaySpendTotal]) -> [SpendBucket] {
    let formatter = DateFormatter()
    formatter.dateFormat = "MMM"
    return monthsInRange(range).map { monthRange in
        let days = daysInRange(monthRange)
        var total = 0.0
        var catTotals: [String: Double] = [:]
        for day in days {
            let entry = dayTotals[day] ?? DaySpendTotal(total: 0, categoryTotals: [:])
            total += entry.total
            for (hex, amt) in entry.categoryTotals {
                catTotals[hex, default: 0] += amt
            }
        }
        let label = formatter.string(from: monthRange.lowerBound)
        let sortedHexes = catTotals.sorted { $0.value > $1.value }.map(\.key)
        return SpendBucket(label: label, start: monthRange.lowerBound, end: monthRange.upperBound, amount: total, categoryHexColors: sortedHexes)
    }
}

private func weekdayGradientColors(for item: SpendBucket, summary: BudgetSummary, fallback: [Color]? = nil) -> [Color] {
    let resolved = item.categoryHexColors.compactMap { UBColorFromHex($0) }
    if !resolved.isEmpty {
        if resolved.count == 1, let first = resolved.first { return [first, first] }
        return resolved
    }
    let fallbackColors = fallback ?? weekdayGradientColors(for: summary)
    if fallbackColors.count == 1, let first = fallbackColors.first { return [first, first] }
    return fallbackColors
}

private func weekdayGradientColors(for summary: BudgetSummary) -> [Color] {
    let cats = summary.variableCategoryBreakdown
    let first = UBColorFromHex(cats.first?.hexColor) ?? HomeView.HomePalette.presets
    let second = UBColorFromHex(cats.dropFirst().first?.hexColor) ?? HomeView.HomePalette.cards
    return [first, second]
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
    var savingsGradient: AngularGradient? = nil
    var centerValueGradient: AngularGradient? = nil

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
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
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

    private var centerStyle: some ShapeStyle {
        centerValueGradient ?? uniformAngularGradient(Color.primary)
    }

    private func style(for slice: CategorySlice) -> some ShapeStyle {
        if slice.name == "Savings", let savingsGradient {
            return savingsGradient
        }
        return uniformAngularGradient(slice.color)
    }
}

fileprivate func uniformAngularGradient(_ color: Color) -> AngularGradient {
    AngularGradient(gradient: Gradient(colors: [color, color]), center: .center)
}

private struct CategoryTopRow: View {
    let slice: CategorySlice
    let total: Double

    var body: some View {
        let share = max(min(slice.amount / max(total, 1), 1), 0)
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Circle().fill(slice.color).frame(width: 10, height: 10)
                Text(slice.name)
                    .font(.subheadline.weight(.semibold))
                Spacer()
                Text(String(format: "%.0f%%", share * 100))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(formatCurrency(slice.amount))
                    .font(.subheadline)
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
                        let symbolWidth: CGFloat = 14
                        let dotColor = UBColorFromHex(exp.expenseCategory?.color) ?? .secondary
                        HStack(alignment: .firstTextBaseline, spacing: 6) {
                            Circle().fill(dotColor).frame(width: 8, height: 8)
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
                                        .frame(width: 12, height: 8)
                                } else {
                                    RoundedRectangle(cornerRadius: 2, style: .continuous)
                                        .stroke(Color.primary.opacity(0.12), lineWidth: 1)
                                        .frame(width: 12, height: 8)
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
                        let symbolWidth: CGFloat = 14
                        let dotColor = UBColorFromHex(exp.expenseCategory?.color) ?? .secondary
                        HStack(alignment: .firstTextBaseline, spacing: 6) {
                            Circle().fill(dotColor).frame(width: 8, height: 8)
                                .frame(width: symbolWidth, alignment: .leading)
                            Text(Self.readUnplannedDescription(exp) ?? "Expense")
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
                                        .frame(width: 12, height: 8)
                                } else {
                                    RoundedRectangle(cornerRadius: 2, style: .continuous)
                                        .stroke(Color.primary.opacity(0.12), lineWidth: 1)
                                        .frame(width: 12, height: 8)
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

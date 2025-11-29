import SwiftUI
import Charts
import CoreData
#if canImport(UIKit)
import UIKit
#endif
#if os(macOS)
import AppKit
#endif

// MARK: - Shared Models
private struct WeekdayTotal: Identifiable {
    let id = UUID()
    let weekday: Int
    let label: String
    let amount: Double
}

struct CapStatus: Identifiable {
    let id = UUID()
    let name: String
    let amount: Double
    let cap: Double
    let color: Color
    let near: Bool
    let over: Bool
}

// MARK: - HomeView – Widget Feed
struct HomeView: View {

    @StateObject private var vm = HomeViewModel()

    @State private var nextPlannedSnapshot: PlannedExpenseSnapshot?
    @State private var weekdayWidgetTotals: [WeekdayTotal] = []
    @State private var capStatuses: [CapStatus] = []

    enum Sort: String, CaseIterable, Identifiable { case titleAZ, amountLowHigh, amountHighLow, dateOldNew, dateNewOld; var id: String { rawValue } }

    private let gridColumns = [GridItem(.adaptive(minimum: 280, maximum: 460), spacing: 18, alignment: .top)]
    @State private var cardWidgets: [CardItem] = []

    enum HomePalette {
        static let budgets = Color(red: 0.15, green: 0.68, blue: 0.45)
        static let income  = Color(red: 0.23, green: 0.55, blue: 0.95)
        static let presets = Color(red: 0.59, green: 0.45, blue: 0.96)
        static let cards   = Color(red: 0.97, green: 0.62, blue: 0.25)
    }

    enum HomeWidgetKind {
        case budgets, income, presets, cards
        case dayOfWeek, caps

        var titleColor: Color {
            switch self {
            case .budgets: return HomePalette.budgets
            case .income:  return HomePalette.income
            case .presets: return HomePalette.presets
            case .cards:   return HomePalette.cards
            case .dayOfWeek: return HomePalette.presets
            case .caps: return HomePalette.presets
            }
        }
    }

    private enum HomeWidgetSize {
        case small, wide, large

        var columnSpan: Int {
            switch self {
            case .small: return 1
            case .wide, .large: return 2
            }
        }

        var minHeight: CGFloat {
            switch self {
            case .small: return 150
            case .wide: return 150
            case .large: return 240
            }
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
        .onChange(of: vm.state) { _ in Task { await stateDidChange() } }
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

    private var dateRow: some View {
        HStack(spacing: 12) {
            Label("Date Range", systemImage: "calendar")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.primary)
            Spacer()
            Text(rangeDescription(currentRange))
                .font(.callout.weight(.semibold))
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(datePillBackground)
        }
        .padding(12)
        .background(glassRowBackground)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
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

    private var datePillBackground: some View {
        Group {
            #if canImport(UIKit)
            Color(UIColor.secondarySystemFill)
            #elseif os(macOS)
            Color(NSColor.controlBackgroundColor)
            #else
            Color.gray.opacity(0.15)
            #endif
        }
        .clipShape(Capsule())
    }

    @ViewBuilder
    private func widgetGrid(for summary: BudgetSummary) -> some View {
        LazyVGrid(columns: gridColumns, spacing: 18) {
            incomeWidget(for: summary)
            expenseRatioWidget(for: summary)
            savingsWidget(for: summary)
            nextPlannedExpenseWidget(for: summary)
            categorySpotlightWidget(for: summary)
            weekdayWidget(for: summary)
            capsWidget(for: summary)
            ForEach(cardWidgets, id: \.objectID) { card in
                cardWidget(card: card, summary: summary)
            }
        }
    }

    // MARK: Widgets
    private func incomeWidget(for summary: BudgetSummary) -> some View {
        widgetLink(title: "Income", subtitle: widgetRangeLabel, kind: .income, size: .wide, summary: summary) {
            VStack(alignment: .leading, spacing: 8) {
                let total = max(max(summary.potentialIncomeTotal, summary.actualIncomeTotal), 1)
                Text(formatCurrency(summary.actualIncomeTotal))
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                Text("Received of \(formatCurrency(summary.potentialIncomeTotal)) expected")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                ProgressView(value: summary.actualIncomeTotal, total: total)
                    .tint(.green)
            }
        }
    }

    private func expenseRatioWidget(for summary: BudgetSummary) -> some View {
        let expenses = summary.plannedExpensesActualTotal + summary.variableExpensesTotal
        let income = max(max(summary.actualIncomeTotal, summary.potentialIncomeTotal), 1)
        let ratio = expenses / income
        let percent = ratio * 100
        return widgetLink(title: "Expense to Income", subtitle: widgetRangeLabel, kind: .budgets, size: .small, summary: summary) {
            VStack(alignment: .leading, spacing: 8) {
                Text("\(percent, specifier: "%.0f")% of income spent")
                    .font(.headline)
                Text("Expenses: \(formatCurrency(expenses))")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                Gauge(value: min(ratio, 1.5), in: 0...1.5) {
                    EmptyView()
                } currentValueLabel: {
                    Text(ratio >= 1 ? "Over target" : "On track")
                        .font(.footnote.weight(.semibold))
                } minimumValueLabel: {
                    Text("0%")
                } maximumValueLabel: {
                    Text("150%")
                }
                .tint(Gradient(colors: [.orange.opacity(0.3), .orange]))
            }
        }
    }

    private func savingsWidget(for summary: BudgetSummary) -> some View {
        let projected = summary.potentialIncomeTotal - summary.plannedExpensesPlannedTotal - summary.variableExpensesTotal
        let actual = summary.actualSavingsTotal
        let clampedActual = max(actual, 0) // ProgressView must be non-negative
        let clampedProjected = max(projected, 0)
        let progressTotal = max(max(clampedProjected, clampedActual), 1)
        return widgetLink(title: "Savings Outlook", subtitle: widgetRangeLabel, kind: .budgets, size: .small, summary: summary) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Projected")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                        Text(formatCurrency(projected))
                            .font(.headline)
                    }
                    Spacer()
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Actual")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                        Text(formatCurrency(actual))
                            .font(.headline)
                            .foregroundStyle(actual >= 0 ? .green : .red)
                    }
                }
                ProgressView(value: clampedActual, total: progressTotal)
                    .tint(actual >= 0 ? .green : .red)
            }
        }
    }


    private func nextPlannedExpenseWidget(for summary: BudgetSummary) -> some View {
        let snapshot = (nextPlannedSnapshot?.budgetID == summary.id) ? nextPlannedSnapshot : nil
        return widgetLink(title: "Next Planned Expense", subtitle: widgetRangeLabel, kind: .cards, size: .small, summary: summary, snapshot: snapshot) {
            if let snapshot {
                PresetExpenseRowView(
                    title: snapshot.title,
                    amountText: "Planned: \(formatCurrency(snapshot.plannedAmount)) • Actual: \(formatCurrency(snapshot.actualAmount))",
                    dateText: shortDate(snapshot.date)
                )
            } else {
                Text("No planned expenses in this range.")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    private func categorySpotlightWidget(for summary: BudgetSummary) -> some View {
        let categories = summary.variableCategoryBreakdown
        let totalExpenses = categories.map(\.amount).reduce(0, +)
        let slices = categorySlices(from: categories, limit: 3)
        let topCategory = categories.first ?? summary.plannedCategoryBreakdown.first ?? summary.categoryBreakdown.first
        return widgetLink(title: "Category Spotlight", subtitle: widgetRangeLabel, kind: .presets, size: .large, summary: summary, topCategory: topCategory) {
            if let top = slices.first, totalExpenses > 0 {
                CategoryDonutView(
                    slices: slices,
                    total: totalExpenses,
                    centerTitle: top.name,
                    centerValue: formatCurrency(top.amount)
                )
                .frame(height: 140)
                Text("Top \(min(3, slices.count)) categories in this range.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
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
            widgetCard(title: card.name, subtitle: "Tap to view", kind: .cards, size: .small) {
                CardTileView(card: card, isInteractive: false, showsBaseShadow: false)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .buttonStyle(.plain)
    }

    private func weekdayWidget(for summary: BudgetSummary) -> some View {
        return widgetLink(title: "Day of Week Spend", subtitle: widgetRangeLabel, kind: .dayOfWeek, size: .small, summary: summary) {
            if self.weekdayWidgetTotals.isEmpty {
                Text("No spending yet.")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                let gradientColors = weekdayGradientColors(for: summary)
                GeometryReader { geo in
                    let maxAmount = max(self.weekdayWidgetTotals.map(\.amount).max() ?? 1, 1)
                    let spacing: CGFloat = 8
                    let barWidth = max((geo.size.width - spacing * 6) / 7, 10)
                    HStack(alignment: .bottom, spacing: spacing) {
                        ForEach(self.weekdayWidgetTotals) { item in
                            let norm = max(min(item.amount / maxAmount, 1), 0)
                            let barColor = LinearGradient(
                                colors: gradientColors.map { $0.opacity(0.35 + 0.35 * norm) },
                                startPoint: .top,
                                endPoint: .bottom
                            )
                            VStack(spacing: 4) {
                                Rectangle()
                                    .fill(barColor)
                                    .frame(width: barWidth, height: max(CGFloat(norm) * 60, 6))
                                    .clipShape(RoundedRectangle(cornerRadius: 3, style: .continuous))
                                Text(item.label)
                                    .font(.caption2)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
                }
                .frame(height: 90)
                if let maxItem = self.weekdayWidgetTotals.max(by: { $0.amount < $1.amount }) {
                    Text("Highest: \(maxItem.label) • \(formatCurrency(maxItem.amount))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private func capsWidget(for summary: BudgetSummary) -> some View {
        let overCount = capStatuses.filter { $0.over }.count
        let nearCount = capStatuses.filter { $0.near && !$0.over }.count
        return widgetLink(title: "Caps & Alerts", subtitle: widgetRangeLabel, kind: .caps, size: .small, summary: summary, capStatuses: capStatuses) {
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Circle().fill(Color.red.opacity(0.15)).frame(width: 10, height: 10)
                    Text("Over: \(overCount)")
                }
                .font(.footnote)
                HStack {
                    Circle().fill(Color.orange.opacity(0.2)).frame(width: 10, height: 10)
                    Text("Near: \(nearCount)")
                }
                .font(.footnote)
                Text("Tap to see category caps.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: Widget Helpers
    private func widgetLink<Content: View>(
        title: String,
        subtitle: String? = nil,
        kind: HomeWidgetKind,
        size: HomeWidgetSize,
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
                summary: summary,
                nextExpense: snapshot,
                topCategory: topCategory,
                capStatuses: capStatuses
            )
        } label: {
            widgetCard(title: title, subtitle: subtitle, kind: kind, size: size, content: content)
        }
        .buttonStyle(.plain)
        .gridCellColumns(size.columnSpan)
    }

    private func widgetCard<Content: View>(title: String, subtitle: String? = nil, kind: HomeWidgetKind, size: HomeWidgetSize, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .foregroundStyle(kind.titleColor)
                    if let subtitle {
                        Text(subtitle)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
            content()
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(minHeight: size.minHeight, alignment: .topLeading)
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
        vm.isUsingCustomRange ? "Custom dates" : "\(vm.period.displayName) period"
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
        vm.startIfNeeded()
        let summary = primarySummary
        await loadNextPlannedExpense(for: summary)
        await loadWeekdayTotals(for: summary)
        await loadCards(for: summary)
        await loadCaps(for: summary)
    }

    private func stateDidChange() async {
        let summary = primarySummary
        await loadNextPlannedExpense(for: summary)
        await loadWeekdayTotals(for: summary)
        await loadCards(for: summary)
        await loadCaps(for: summary)
    }

    private func rangeDescription(_ range: ClosedRange<Date>) -> String {
        let f = DateFormatter()
        f.dateStyle = .medium
        return "\(f.string(from: range.lowerBound)) through \(f.string(from: range.upperBound))"
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
        let bgContext = CoreDataService.shared.newBackgroundContext()
        let snapshot: PlannedExpenseSnapshot? = await bgContext.perform {
            guard let budget = try? bgContext.existingObject(with: summary.id) as? Budget else { return nil }
            let fetch = NSFetchRequest<PlannedExpense>(entityName: "PlannedExpense")
            fetch.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
                NSPredicate(format: "budget == %@", budget),
                NSPredicate(format: "transactionDate >= %@ AND transactionDate <= %@", range.lowerBound as NSDate, range.upperBound as NSDate)
            ])
            fetch.sortDescriptors = [NSSortDescriptor(key: "transactionDate", ascending: true)]
            fetch.fetchLimit = 1
            guard let next = try? bgContext.fetch(fetch).first else { return nil }
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

    private func loadWeekdayTotals(for summary: BudgetSummary?) async {
        guard let summary else {
            await MainActor.run { weekdayWidgetTotals = [] }
            return
        }
        let range = currentRange
        let ctx = CoreDataService.shared.newBackgroundContext()
        let totals: [WeekdayTotal] = await ctx.perform {
            guard let budget = try? ctx.existingObject(with: summary.id) as? Budget else { return [] }

            var weekdayTotals: [Int: Double] = [:]
            // Planned expenses
            let plannedReq = NSFetchRequest<PlannedExpense>(entityName: "PlannedExpense")
            plannedReq.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
                NSPredicate(format: "budget == %@", budget),
                NSPredicate(format: "transactionDate >= %@ AND transactionDate <= %@", range.lowerBound as NSDate, range.upperBound as NSDate)
            ])
            if let planned = try? ctx.fetch(plannedReq) {
                for exp in planned {
                    let wd = Calendar.current.component(.weekday, from: exp.transactionDate ?? range.lowerBound)
                    weekdayTotals[wd, default: 0] += exp.actualAmount
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
                        let wd = Calendar.current.component(.weekday, from: exp.transactionDate ?? range.lowerBound)
                        weekdayTotals[wd, default: 0] += exp.amount
                    }
                }
            }

            let symbols = Calendar.current.shortWeekdaySymbols
            let ordered = (1...7).map { wd -> WeekdayTotal in
                let idx = max(min(wd - 1, symbols.count - 1), 0)
                let label = symbols.indices.contains(idx) ? symbols[idx] : "Day \(wd)"
                return WeekdayTotal(weekday: wd, label: label, amount: weekdayTotals[wd] ?? 0)
            }
            return ordered
        }
        await MainActor.run { weekdayWidgetTotals = totals }
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

    private func loadCaps(for summary: BudgetSummary?) async {
        guard let summary else {
            await MainActor.run { capStatuses = [] }
            return
        }
        let caps = await fetchCapStatuses(for: summary)
        await MainActor.run { capStatuses = caps }
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
    @State private var weekdaySpending: [WeekdayTotal] = []

    private var rangeText: String {
        let f = DateFormatter()
        f.dateStyle = .medium
        return "\(f.string(from: range.lowerBound)) – \(f.string(from: range.upperBound))"
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
            if weekdaySpending.isEmpty {
                Text("No spending in this range.")
                    .foregroundStyle(.secondary)
            } else {
                let gradientColors = weekdayGradientColors(for: summary)
                Chart(weekdaySpending) { item in
                    BarMark(
                        x: .value("Day", item.label),
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
                if let maxItem = weekdaySpending.max(by: { $0.amount < $1.amount }) {
                    Text("Highest spend: \(maxItem.label) • \(formatCurrency(maxItem.amount))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private var capsContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Category Caps & Alerts")
                .font(.headline)
            if let capStatuses, !capStatuses.isEmpty {
                ForEach(capStatuses) { cap in
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Circle().fill(cap.color.opacity(0.3)).frame(width: 10, height: 10)
                            Text(cap.name)
                                .font(.subheadline.weight(.semibold))
                            Spacer()
                            if cap.over {
                                Text("Over")
                                    .font(.caption2.weight(.bold))
                                    .padding(6)
                                    .background(Color.red.opacity(0.12))
                                    .clipShape(Capsule())
                            } else if cap.near {
                                Text("Near")
                                    .font(.caption2.weight(.bold))
                                    .padding(6)
                                    .background(Color.orange.opacity(0.12))
                                    .clipShape(Capsule())
                            }
                        }
                        ProgressView(value: min(cap.amount / max(cap.cap, 1), 1))
                            .tint(cap.color)
                        HStack {
                            Text("Spent: \(formatCurrency(cap.amount))")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Spacer()
                            Text("Cap: \(formatCurrency(cap.cap))")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            } else {
                Text("No caps found for this range.")
                    .foregroundStyle(.secondary)
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
            if let topCategory {
                let allCategories = summary.variableCategoryBreakdown
                let totalExpenses = allCategories.map(\.amount).reduce(0, +)
                let totalForList = max(totalExpenses, 1)
                let slices = categorySlices(from: allCategories, limit: showAllCategories ? allCategories.count : 6)
                let topSlices = Array(slices.prefix(3))
                VStack(alignment: .leading, spacing: 12) {
                    CategoryDonutView(
                        slices: slices,
                        total: max(totalExpenses, 1),
                        centerTitle: "Top",
                        centerValue: formatCurrency(topCategory.amount)
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
                    if showAllCategories {
                        categoriesCompactList(allCategories, total: totalForList)
                    }
                    Button(showAllCategories ? "Hide All Categories" : "Show All Categories") {
                        withAnimation(.spring()) { showAllCategories.toggle() }
                    }
                    .buttonStyle(.plain)
                    .font(.footnote.weight(.semibold))
                }
            } else {
                Text("No category data in this range.")
                    .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: Helpers
    private func metricRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(.headline)
        }
    }

    // MARK: Income Sections
    private func incomeTimelineSection(total: Double) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Timeline & Pace")
                    .font(.headline)
                Spacer()
                paceBadge(total: total)
            }
            timelineChart
            HStack(spacing: 12) {
                metricRow(label: "Received", value: formatCurrency(summary.actualIncomeTotal))
                metricRow(label: "Expected", value: formatCurrency(summary.potentialIncomeTotal))
            }
        }
    }

    private func paceBadge(total: Double) -> some View {
        let dates = allDates(in: range)
        let daysElapsed = dates.filter { $0 <= startOfDay(Date()) }.count
        let progress = Double(daysElapsed) / Double(max(dates.count, 1))
        let expectedSoFar = summary.potentialIncomeTotal * progress
        let status: String
        if summary.actualIncomeTotal >= expectedSoFar * 1.02 {
            status = "Ahead"
        } else if summary.actualIncomeTotal >= expectedSoFar * 0.98 {
            status = "On Pace"
        } else {
            status = "Behind"
        }
        return Text(status)
            .font(.caption.weight(.semibold))
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                Capsule().fill(HomeView.HomePalette.income.opacity(0.15))
            )
    }

    @ViewBuilder
    private var timelineChart: some View {
        if incomeTimeline.isEmpty {
            Text("No income in this range.")
                .foregroundStyle(.secondary)
        } else {
            let receivedColor = HomeView.HomePalette.income
            let expectedColor = HomeView.HomePalette.presets.opacity(0.8)
            let expectedSeries = expectedTimeline.isEmpty ? incomeTimeline : expectedTimeline
            let maxVal = max((incomeTimeline.map(\.value).max() ?? 0), (expectedSeries.map(\.value).max() ?? 0), 1)
            let domain: ClosedRange<Double> = 0...(maxVal * 1.1)
            Chart {
                ForEach(expectedSeries) { point in
                    LineMark(
                        x: .value("Date", point.date),
                        y: .value("Expected", point.value)
                    )
                    .interpolationMethod(.monotone)
                    .foregroundStyle(expectedColor)
                }
                ForEach(incomeTimeline) { point in
                    LineMark(
                        x: .value("Date", point.date),
                        y: .value("Received", point.value)
                    )
                    .interpolationMethod(.monotone)
                    .foregroundStyle(receivedColor)
                    PointMark(
                        x: .value("Date", point.date),
                        y: .value("Received", point.value)
                    )
                    .symbolSize(point.id == timelineSelection?.id ? 30 : 18)
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
                                        timelineSelection = nearestPoint(in: incomeTimeline, to: date)
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
                HStack(spacing: 12) {
                    Label("Received", systemImage: "circle.fill")
                        .foregroundStyle(receivedColor)
                        .font(.caption)
                    Label("Expected", systemImage: "circle.fill")
                        .foregroundStyle(expectedColor)
                        .font(.caption)
                        .labelStyle(.titleAndIcon)
                }
            }
        }
    }

    private var incomeMoMSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Trends")
                    .font(.headline)
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
        await MainActor.run {
            self.expenseIncomeSeries = series.ratioPoints
            self.savingsSeries = series.savingsPoints
            self.weekdaySpending = series.weekdayTotals
            self.incomeTimeline = income.received
            self.expectedTimeline = income.expected
            self.incomeBuckets = income.buckets
            self.latestIncomeID = income.latestIncomeID
        }
    }

    private struct DailySeriesResult {
        let ratioPoints: [DatedValue]
        let savingsPoints: [SavingsPoint]
        let weekdayTotals: [WeekdayTotal]
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
                    savingsPoints: fallbackSavingsSeries(projected: projected, actual: summary.actualSavingsTotal),
                    weekdayTotals: []
                )
            }

            let dates = allDates(in: range)
            if dates.isEmpty {
                let projected = summary.potentialIncomeTotal - summary.plannedExpensesPlannedTotal - summary.variableExpensesTotal
                return DailySeriesResult(
                    ratioPoints: fallbackRatioSeries(expenses: summary.plannedExpensesActualTotal + summary.variableExpensesTotal, income: max(summary.actualIncomeTotal, 1)),
                    savingsPoints: fallbackSavingsSeries(projected: projected, actual: summary.actualSavingsTotal),
                    weekdayTotals: []
                )
            }

            var incomeDaily: [Date: Double] = [:]
            var expenseDaily: [Date: Double] = [:]

            // Incomes (actual)
            let incomeReq = NSFetchRequest<Income>(entityName: "Income")
            incomeReq.predicate = NSPredicate(format: "date >= %@ AND date <= %@", range.lowerBound as NSDate, range.upperBound as NSDate)
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
            var weekdayTotals: [Int: Double] = [:]

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

                let wd = Calendar.current.component(.weekday, from: day)
                weekdayTotals[wd, default: 0] += (expenseDaily[day] ?? 0)
            }

            if ratioPoints.count == 1, let first = ratioPoints.first {
                ratioPoints.append(DatedValue(date: range.upperBound, value: first.value))
            }
            if savingsPoints.count == 1, let first = savingsPoints.first {
                savingsPoints.append(SavingsPoint(date: range.upperBound, actual: first.actual, projected: first.projected))
            }

            let symbols = Calendar.current.shortWeekdaySymbols
            let weekdayList: [WeekdayTotal] = (1...7).map { wd in
                let idx = max(min(wd - 1, symbols.count - 1), 0)
                let label = symbols.indices.contains(idx) ? symbols[idx] : "Day \(wd)"
                return WeekdayTotal(weekday: wd, label: label, amount: weekdayTotals[wd] ?? 0)
            }

            return DailySeriesResult(
                ratioPoints: ratioPoints,
                savingsPoints: savingsPoints,
                weekdayTotals: weekdayList
            )
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
            let incomeReq = NSFetchRequest<Income>(entityName: "Income")
            incomeReq.predicate = NSPredicate(format: "date >= %@ AND date <= %@", range.lowerBound as NSDate, range.upperBound as NSDate)
            incomeReq.sortDescriptors = [NSSortDescriptor(key: "date", ascending: true)]
            let incomes = (try? ctx.fetch(incomeReq)) ?? []
            for inc in incomes where inc.isPlanned == false {
                let day = startOfDay(inc.date ?? range.lowerBound)
                incomeDaily[day, default: 0] += inc.amount
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
            let expected: [DatedValue] = dates.enumerated().map { idx, day in
                let fraction = Double(idx + 1) / Double(max(dates.count, 1))
                return DatedValue(date: day, value: summary.potentialIncomeTotal * fraction)
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
            Circle().fill(color.opacity(0.35)).frame(width: 10, height: 10)
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

private func shortDate(_ date: Date) -> String {
    let f = DateFormatter()
    f.dateStyle = .medium
    return f.string(from: date)
}

// MARK: - Category Spotlight Helpers
private struct CategorySlice: Identifiable {
    let id = UUID()
    let name: String
    let amount: Double
    let color: Color
}

private func categorySlices(from categories: [BudgetSummary.CategorySpending], limit: Int) -> [CategorySlice] {
    guard !categories.isEmpty else { return [] }
    let total = categories.map(\.amount).reduce(0, +)
    guard total > 0 else { return [] }
    let top = Array(categories.prefix(limit))
    let topSlices: [CategorySlice] = top.map {
        CategorySlice(
            name: $0.categoryName,
            amount: $0.amount,
            color: UBColorFromHex($0.hexColor) ?? HomeView.HomePalette.presets
        )
    }
    let remaining = categories.dropFirst(limit)
    let otherAmount = remaining.map(\.amount).reduce(0, +)
    if otherAmount > 0 {
        return topSlices + [CategorySlice(name: "Other", amount: otherAmount, color: .secondary)]
    }
    return topSlices
}

private func weekdayGradientColors(for summary: BudgetSummary) -> [Color] {
    let cats = summary.variableCategoryBreakdown
    let first = UBColorFromHex(cats.first?.hexColor) ?? HomeView.HomePalette.presets
    let second = UBColorFromHex(cats.dropFirst().first?.hexColor) ?? HomeView.HomePalette.cards
    return [first, second]
}

private func fetchCapStatuses(for summary: BudgetSummary) async -> [CapStatus] {
    let ctx = CoreDataService.shared.viewContext
    let categories = summary.variableCategoryBreakdown
    guard !categories.isEmpty else { return [] }
    let key = capsPeriodKey(start: summary.periodStart, end: summary.periodEnd)
    let coordinator = CoreDataService.shared.container.persistentStoreCoordinator
    var results: [CapStatus] = []

    for cat in categories {
        guard
            cat.categoryURI.scheme == "x-coredata",
            let catID = coordinator.managedObjectID(forURIRepresentation: cat.categoryURI),
            let category = try? ctx.existingObject(with: catID) as? ExpenseCategory
        else { continue }

        let fetch = NSFetchRequest<CategorySpendingCap>(entityName: "CategorySpendingCap")
        fetch.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
            NSPredicate(format: "category == %@", category),
            NSPredicate(format: "period == %@", key),
            NSPredicate(format: "expenseType == %@", "max")
        ])
        fetch.fetchLimit = 1
        guard
            let cap = try? ctx.fetch(fetch).first,
            let amount = cap.value(forKey: "amount") as? Double,
            amount > 0
        else { continue }

        let color = UBColorFromHex(cat.hexColor) ?? HomeView.HomePalette.presets
        let near = cat.amount >= amount * 0.85 && cat.amount < amount
        let over = cat.amount >= amount
        results.append(CapStatus(
            name: cat.categoryName,
            amount: cat.amount,
            cap: amount,
            color: color,
            near: near,
            over: over
        ))
    }

    return results.sorted { ($0.over ? 1 : 0, $0.amount / max($0.cap, 1)) > ($1.over ? 1 : 0, $1.amount / max($1.cap, 1)) }
}

private func capsPeriodKey(start: Date, end: Date) -> String {
    let f = DateFormatter()
    f.calendar = Calendar(identifier: .gregorian)
    f.locale = Locale(identifier: "en_US_POSIX")
    f.timeZone = TimeZone(secondsFromGMT: 0)
    f.dateFormat = "yyyy-MM-dd"
    let s = f.string(from: start)
    let e = f.string(from: end)
    return "\(s)|\(e)|home"
}

private struct CategoryDonutView: View {
    let slices: [CategorySlice]
    let total: Double
    let centerTitle: String
    let centerValue: String

    var body: some View {
        ZStack {
            if #available(iOS 17.0, macCatalyst 17.0, macOS 14.0, *) {
                Chart(slices) { slice in
                    SectorMark(
                        angle: .value("Amount", slice.amount),
                        innerRadius: .ratio(0.60),
                        outerRadius: .ratio(1.0)
                    )
                    .foregroundStyle(slice.color)
                }
                .chartLegend(.hidden)
                .frame(maxWidth: .infinity)
            } else {
                // Fallback: simple ring using proportional rectangles
                HStack(spacing: 4) {
                    ForEach(slices) { slice in
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .fill(slice.color)
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
            }
        }
    }
}

private struct CategoryTopRow: View {
    let slice: CategorySlice
    let total: Double

    var body: some View {
        let share = max(min(slice.amount / max(total, 1), 1), 0)
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Circle().fill(slice.color.opacity(0.35)).frame(width: 10, height: 10)
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

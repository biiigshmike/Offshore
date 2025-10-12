import SwiftUI
import CoreData

// MARK: - HomeView2
/// A simplified, self‑contained rebuild of the Home screen that follows
/// "Apple Way" SwiftUI layout primitives and native styles.
///
/// Goals:
/// - Minimize indirection and helpers; rely on VStack/HStack/List/ScrollView
/// - Use .glass() on iOS 26/macCatalyst 26/macOS 26 with a sensible fallback
/// - Reuse existing HomeViewModel for data/state
/// - Keep layouts responsive via intrinsic sizing and targeted padding
struct HomeView: View {

    // MARK: State & View Model
    @StateObject private var vm = HomeViewModel()
    @AppStorage(AppSettingsKeys.budgetPeriod.rawValue)
    private var budgetPeriodRawValue: String = BudgetPeriod.monthly.rawValue

    // MARK: Local UI State
    enum Segment: String, CaseIterable, Identifiable { case planned, variable; var id: String { rawValue } }
    @State private var segment: Segment = .planned
    @Namespace private var homeToolbarGlassNamespace

    enum Sort: String, CaseIterable, Identifiable { case titleAZ, amountLowHigh, amountHighLow, dateOldNew, dateNewOld; var id: String { rawValue } }
    @State private var sort: Sort = .dateNewOld

    private struct CategoryCapOverlayData: Identifiable {
        let categoryID: UUID
        var categoryName: String
        var segment: Segment
        var spent: Double
        var capAmount: Double?

        var id: UUID { categoryID }
    }

    @State private var categoryCapOverlay: CategoryCapOverlayData?
    @State private var isShowingCategoryCapOverlay: Bool = false
    @State private var editingCategoryCap: CategoryCapOverlayData?

    // MARK: Sheet Toggles (kept small and focused)
    @State private var isPresentingAddPlanned: Bool = false
    @State private var isPresentingAddVariable: Bool = false
    @State private var isPresentingAddBudget: Bool = false
    @State private var isPresentingManageCards: Bool = false
    @State private var isPresentingManagePresets: Bool = false
    @State private var isAddMenuVisible: Bool = false
    @State private var editingBudget: BudgetSummary?

    // Edit sheets for rows
    private struct ObjectIDBox: Identifiable { let id: NSManagedObjectID }
    @State private var editingPlannedBox: ObjectIDBox?
    @State private var editingUnplannedBox: ObjectIDBox?

    // Backing data for list rows
    @State private var plannedRows: [PlannedExpense] = []
    @State private var variableRows: [UnplannedExpense] = []

    // MARK: Environment
    @Environment(\.managedObjectContext) private var moc

    // MARK: Body
    var body: some View {
        List {
            // Header + controls grouped as one vertical block so List owns scrolling
            Section {
                VStack(alignment: .leading, spacing: 20) {
                    headerBlock
                    periodNavigator
                    metricsGrid
                    categoryChips
                    segmentPicker
                    sortBar
                }
                .padding(.horizontal, horizontalPadding)
                .padding(.top, 8)
                .padding(.bottom, 8) // space before first row section
                .listRowInsets(EdgeInsets())
                .listRowSeparator(.hidden)
            }

            // Rows Section (Planned/Variable)
            Section { listRows }
        }
        .listStyle(.plain)
        .navigationTitle("Home")
        .toolbar { toolbarContent }
        .task {
            vm.startIfNeeded()
            isAddMenuVisible = summary != nil
            reloadRows()
        }
        .onChange(of: segment) { _ in reloadRows() }
        .onChange(of: sort) { _ in reloadRows() }
        .onChange(of: summaryIDString) { _ in
            withAnimation(.easeInOut(duration: 0.2)) {
                isAddMenuVisible = summary != nil
            }
            reloadRows()
        }
        .onChange(of: overlayRefreshToken) { _ in
            refreshCategoryCapOverlay(reloadCap: true)
        }
        .onChange(of: vm.state) { state in
            if case .loaded = state {
                refreshCategoryCapOverlay(reloadCap: true)
            }
        }
        .sheet(isPresented: $isPresentingAddPlanned) { addPlannedSheet }
        .sheet(isPresented: $isPresentingAddVariable) { addVariableSheet }
        .sheet(isPresented: $isPresentingAddBudget, content: makeAddBudgetView)
        .sheet(item: $editingBudget, content: makeEditBudgetView)
        .sheet(isPresented: $isPresentingManageCards) { manageCardsSheet }
        .sheet(isPresented: $isPresentingManagePresets) { managePresetsSheet }
        .sheet(item: $editingPlannedBox) { box in
            AddPlannedExpenseView(
                plannedExpenseID: box.id,
                onSaved: { Task { await vm.refresh(); reloadRows() } }
            )
            .environment(\.managedObjectContext, CoreDataService.shared.viewContext)
        }
        .sheet(item: $editingUnplannedBox) { box in
            AddUnplannedExpenseView(
                unplannedExpenseID: box.id,
                onSaved: { Task { await vm.refresh(); reloadRows() } }
            )
            .environment(\.managedObjectContext, CoreDataService.shared.viewContext)
        }
        .sheet(item: $editingCategoryCap) { data in
            CategoryCapEditorView(
                categoryID: data.categoryID,
                displayName: data.categoryName,
                expenseType: expenseType(for: data.segment),
                period: budgetPeriod,
                existingAmount: data.capAmount,
                onComplete: {
                    Task {
                        await vm.refresh()
                        await MainActor.run {
                            reloadRows()
                            refreshCategoryCapOverlay(reloadCap: true)
                        }
                    }
                }
            )
        }
        .overlay(alignment: .center) {
            categoryCapOverlayView
        }
        .alert(item: $vm.alert, content: alert(for:))
    }

    // MARK: Toolbar
    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        if #available(iOS 26.0, macOS 26.0, macCatalyst 26.0, *) {
            ToolbarItem(placement: .navigationBarTrailing) {
                GlassEffectContainer(spacing: 16) {
                    HStack(spacing: 16) {
                        calendarMenu
                        if isAddMenuVisible {
                            addExpenseMenu
                                .transition(.scale.combined(with: .opacity))
                        }
                        ellipsisMenu
                    }
                }
                .animation(.spring(response: 0.4, dampingFraction: 0.8), value: isAddMenuVisible)
            }
        } else {
            ToolbarItem(placement: .navigationBarTrailing) {
                HStack(spacing: 16) {
                    calendarMenu
                    if isAddMenuVisible {
                        addExpenseMenu
                            .transition(.scale.combined(with: .opacity))
                    }
                    ellipsisMenu
                }
                .animation(.easeInOut(duration: 0.2), value: isAddMenuVisible)
            }
        }
    }

    private var calendarMenu: some View {
        Menu {
            // Calendar period picker
            ForEach(BudgetPeriod.selectableCases) { p in
                Button(p.displayName) { updateBudgetPeriod(to: p) }
            }
        } label: {
            glassToolbarLabel("calendar")
        }
    }

    private var addExpenseMenu: some View {
        Menu {
            Button("Add Planned Expense") { isPresentingAddPlanned = true }
            Button("Add Variable Expense") { isPresentingAddVariable = true }
        } label: {
            glassToolbarLabel("plus")
        }
    }

    private var ellipsisMenu: some View {
        Menu {
            if let summary {
                Button("Manage Cards") { isPresentingManageCards = true }
                Button("Manage Presets") { isPresentingManagePresets = true }
                Button("Edit Budget") { editingBudget = summary }
                Button(role: .destructive) { vm.requestDelete(budgetID: summary.id) } label: { Text("Delete Budget") }
            } else {
                Button("Create Budget") { isPresentingAddBudget = true }
            }
        } label: {
            glassToolbarLabel("ellipsis")
        }
    }

    @ViewBuilder
    private func glassToolbarLabel(_ symbol: String) -> some View {
        if #available(iOS 26.0, macCatalyst 26.0, macOS 26.0, *) {
            Image(systemName: symbol)
                .foregroundStyle(.primary)
                .font(.system(size: 16, weight: .semibold))
                .frame(width: 32, height: 32)
                .glassEffectUnion(id: "home-toolbar", namespace: homeToolbarGlassNamespace)
                .glassEffectTransition(.matchedGeometry)
        } else {
            Image(systemName: symbol)
                .font(.system(size: 16, weight: .semibold))
                .frame(width: 32, height: 32)
        }
    }

    // MARK: Header
    /// Title and date range for the selected period.
    private var headerBlock: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("\(periodTitle) Budget")
                .font(.system(.largeTitle, design: .rounded).weight(.bold))
                .lineLimit(1)
                .minimumScaleFactor(0.7)

            Text(periodRangeString)
                .foregroundStyle(.secondary)
                .font(.callout)
        }
        .accessibilityElement(children: .combine)
    }

    // MARK: Period Navigator
    /// Back/forward chevrons around the centered month/period title.
    private var periodNavigator: some View {
        HStack(alignment: .center, spacing: 16) {
            periodChevron("chevron.left", delta: -1)
            Text(periodTitle)
                .font(.title2.weight(.semibold))
                .frame(maxWidth: .infinity)
            periodChevron("chevron.right", delta: +1)
        }
        .padding(.top, 2)
    }

    @ViewBuilder
    private func periodChevron(_ systemName: String, delta: Int) -> some View {
        if #available(iOS 26.0, macCatalyst 26.0, macOS 26.0, *) {
            Button(action: { vm.adjustSelectedPeriod(by: delta) }) {
                Image(systemName: systemName)
                    .font(.system(size: 16, weight: .semibold))
                    .frame(width: 32, height: 32)
            }
            .buttonStyle(.glass)
            .buttonBorderShape(.circle)
            .tint(.accentColor)
        } else {
            Buttons.toolbarIcon(systemName) { vm.adjustSelectedPeriod(by: delta) }
        }
    }

    // MARK: Metrics Grid
    /// Two columns: income on the left, savings on the right, then the segment‑specific total row.
    private var metricsGrid: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .lastTextBaseline) {
                metricColumn(title: "POTENTIAL INCOME", value: potentialIncome, color: .orange, trailing: false)
                Spacer(minLength: 0)
                metricColumn(title: "POTENTIAL SAVINGS", value: potentialSavings, color: .green, trailing: true)
            }
            HStack(alignment: .lastTextBaseline) {
                metricColumn(title: "ACTUAL INCOME", value: actualIncome, color: .blue, trailing: false)
                Spacer(minLength: 0)
                metricColumn(title: "ACTUAL SAVINGS", value: actualSavings, color: .green, trailing: true)
            }
            HStack(alignment: .lastTextBaseline) {
                Text(segment == .planned ? "PLANNED EXPENSES" : "VARIABLE EXPENSES")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                Spacer(minLength: 0)
                Text(formatCurrency(segment == .planned ? plannedTotal : variableTotal))
                    .font(.title3.weight(.semibold))
            }
        }
    }

    // MARK: Category Chips
    private var categoryChips: some View {
        let categories = (segment == .planned ? summary?.plannedCategoryBreakdown : summary?.variableCategoryBreakdown) ?? []
        return ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(categories) { cat in
                    chipView(
                        categoryID: cat.categoryID,
                        title: cat.categoryName,
                        amount: cat.amount,
                        hex: cat.hexColor,
                        segment: segment
                    )
                }
                if categories.isEmpty {
                    Text("No categories yet")
                        .foregroundStyle(.secondary)
                        .padding(.vertical, 8)
                }
            }
            .frame(maxWidth: .infinity, minHeight: 33, alignment: .leading)
        }
        .frame(height: 33)
    }

    // MARK: Segment Picker
    private var segmentPicker: some View {
        Picker("", selection: $segment) {
            Text("Planned Expenses").tag(Segment.planned)
            Text("Variable Expenses").tag(Segment.variable)
        }
        .pickerStyle(.segmented)
    }

    // MARK: Sort Bar
    private var sortBar: some View {
        Picker("Sort", selection: $sort) {
            Text("A–Z").tag(Sort.titleAZ)
            Text("$↓").tag(Sort.amountLowHigh)
            Text("$↑").tag(Sort.amountHighLow)
            Text("Date ↑").tag(Sort.dateOldNew)
            Text("Date ↓").tag(Sort.dateNewOld)
        }
        .pickerStyle(.segmented)
    }

    // MARK: Expense List / Empty State
    @ViewBuilder
    private var listRows: some View {
        if segment == .variable, variableRows.isEmpty {
            // Empty state CTA inside the List
            Buttons.primary("Add Variable Expense", systemImage: "plus", fillHorizontally: true) {
                isPresentingAddVariable = true
            }
            .listRowInsets(EdgeInsets(top: 0, leading: horizontalPadding, bottom: 0, trailing: horizontalPadding))
            .listRowSeparator(.hidden)
            .frame(minHeight: 33)                   // Comfortable height
            .clipShape(Capsule())                   // Hard-clip to the pill
            .compositingGroup()                     // Prevent odd shape
            Text("No variable expenses in this period.")
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.vertical, 8)
                .listRowInsets(EdgeInsets(top: 0, leading: horizontalPadding, bottom: 0, trailing: horizontalPadding))
                .listRowSeparator(.hidden)
        } else if segment == .planned, plannedRows.isEmpty {
            Buttons.primary("Add Planned Expense", systemImage: "plus", fillHorizontally: true) {
                isPresentingAddPlanned = true
            }
            .listRowInsets(EdgeInsets(top: 0, leading: horizontalPadding, bottom: 0, trailing: horizontalPadding))
            .listRowSeparator(.hidden)
            .frame(minHeight: 33)                   // Comfortable height
            .clipShape(Capsule())                   // Hard-clip to the pill
            .compositingGroup()                     // Prevent odd shape
            Text("No planned expenses in this period.")
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.vertical, 8)
                .listRowInsets(EdgeInsets(top: 0, leading: horizontalPadding, bottom: 0, trailing: horizontalPadding))
                .listRowSeparator(.hidden)
        } else if segment == .planned {
            ForEach(plannedRows, id: \.objectID) { exp in
                plannedRow(exp)
                    .unifiedSwipeActions(.standard,
                        onEdit: { editingPlannedBox = ObjectIDBox(id: exp.objectID) },
                        onDelete: { delete(planned: exp) })
            }
        } else {
            ForEach(variableRows, id: \.objectID) { exp in
                variableRow(exp)
                    .unifiedSwipeActions(.standard,
                        onEdit: { editingUnplannedBox = ObjectIDBox(id: exp.objectID) },
                        onDelete: { delete(unplanned: exp) })
            }
        }
    }

    // MARK: Sheets
    private var addPlannedSheet: some View {
        AddPlannedExpenseView(
            preselectedBudgetID: summary?.id,
            defaultSaveAsGlobalPreset: false,
            showAssignBudgetToggle: true,
            onSaved: { Task { await vm.refresh() } }
        )
        .environment(\.managedObjectContext, CoreDataService.shared.viewContext)
    }

    private var addVariableSheet: some View {
        AddUnplannedExpenseView(
            allowedCardIDs: nil,
            initialDate: vm.selectedDate,
            onSaved: { Task { await vm.refresh() } }
        )
        .environment(\.managedObjectContext, CoreDataService.shared.viewContext)
    }

    // MARK: Manage Sheets
    private var manageCardsSheet: some View {
        Group {
            if let id = summary?.id,
               let budget = try? CoreDataService.shared.viewContext.existingObject(with: id) as? Budget {
                ManageBudgetCardsSheet(budget: budget) { Task { await vm.refresh(); reloadRows() } }
            } else {
                Text("No budget selected")
            }
        }
        .environment(\.managedObjectContext, CoreDataService.shared.viewContext)
    }

    private var managePresetsSheet: some View {
        Group {
            if let id = summary?.id,
               let budget = try? CoreDataService.shared.viewContext.existingObject(with: id) as? Budget {
                ManageBudgetPresetsSheet(budget: budget) { Task { await vm.refresh(); reloadRows() } }
            } else {
                Text("No budget selected")
            }
        }
        .environment(\.managedObjectContext, CoreDataService.shared.viewContext)
    }

    // MARK: Add/Edit Budget Sheets
    @ViewBuilder
    private func makeAddBudgetView() -> some View {
        let (start, end) = budgetPeriod.range(containing: vm.selectedDate)
        if #available(iOS 16.0, *) {
            AddBudgetView(
                initialStartDate: start,
                initialEndDate: end,
                onSaved: { Task { await vm.refresh(); reloadRows() } }
            )
            .presentationDetents([.large, .medium])
            .environment(\.managedObjectContext, CoreDataService.shared.viewContext)
        } else {
            AddBudgetView(
                initialStartDate: start,
                initialEndDate: end,
                onSaved: { Task { await vm.refresh(); reloadRows() } }
            )
            .environment(\.managedObjectContext, CoreDataService.shared.viewContext)
        }
    }

    @ViewBuilder
    private func makeEditBudgetView(summary: BudgetSummary) -> some View {
        if #available(iOS 16.0, *) {
            AddBudgetView(
                editingBudgetObjectID: summary.id,
                fallbackStartDate: summary.periodStart,
                fallbackEndDate: summary.periodEnd,
                onSaved: { Task { await vm.refresh(); reloadRows() } }
            )
            .presentationDetents([.large, .medium])
            .environment(\.managedObjectContext, CoreDataService.shared.viewContext)
        } else {
            AddBudgetView(
                editingBudgetObjectID: summary.id,
                fallbackStartDate: summary.periodStart,
                fallbackEndDate: summary.periodEnd,
                onSaved: { Task { await vm.refresh(); reloadRows() } }
            )
            .environment(\.managedObjectContext, CoreDataService.shared.viewContext)
        }
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

    // MARK: Derived Data
    private var budgetPeriod: BudgetPeriod { BudgetPeriod(rawValue: budgetPeriodRawValue) ?? .monthly }

    private var periodTitle: String { budgetPeriod.title(for: vm.selectedDate) }

    private var periodRangeString: String {
        let (start, end) = budgetPeriod.range(containing: vm.selectedDate)
        let f = DateFormatter()
        f.dateStyle = .medium
        return "\(f.string(from: start)) through \(f.string(from: end))"
    }

    private var summary: BudgetSummary? {
        switch vm.state {
        case .loaded(let items):
            // Prefer a summary that contains the selected date; otherwise the first available.
            let chosen = items.first(where: { $0.periodStart <= vm.selectedDate && vm.selectedDate <= $0.periodEnd })
            return chosen ?? items.first
        default:
            return nil
        }
    }

    private var summaryIDString: String {
        if let s = summary { return s.id.uriRepresentation().absoluteString }
        return "none"
    }

    private var overlayRefreshToken: String {
        guard let summary else { return "none" }
        func token(for breakdown: [BudgetSummary.CategorySpending]) -> String {
            breakdown
                .map { item in
                    let idString = item.categoryID?.uuidString ?? "nil"
                    let amountString = String(format: "%.2f", item.amount)
                    return "\(idString):\(amountString)"
                }
                .joined(separator: "|")
        }
        return [
            summary.id.uriRepresentation().absoluteString,
            token(for: summary.plannedCategoryBreakdown),
            token(for: summary.variableCategoryBreakdown)
        ].joined(separator: "#")
    }

    private var potentialIncome: Double { summary?.potentialIncomeTotal ?? 0 }
    private var potentialSavings: Double { summary?.potentialSavingsTotal ?? 0 }
    private var actualIncome: Double { summary?.actualIncomeTotal ?? 0 }
    private var actualSavings: Double { summary?.actualSavingsTotal ?? 0 }
    private var plannedTotal: Double { summary?.plannedExpensesActualTotal ?? 0 }
    private var variableTotal: Double { summary?.variableExpensesTotal ?? 0 }

    private var horizontalPadding: CGFloat { 20 }

    // MARK: Helpers
    /// Updates the budget period preference and triggers a model refresh.
    private func updateBudgetPeriod(to newValue: BudgetPeriod) {
        budgetPeriodRawValue = newValue.rawValue
        Task { await vm.refresh() }
    }

    /// Renders a metric label/value pair for a given amount.
    private func metricColumn(title: String, value: Double, color: Color, trailing: Bool) -> some View {
        VStack(alignment: trailing ? .trailing : .leading, spacing: 6) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
                .frame(maxWidth: .infinity, alignment: trailing ? .trailing : .leading)
            Text(formatCurrency(value))
                .font(.body.weight(.semibold))
                .foregroundStyle(color)
                .frame(maxWidth: .infinity, alignment: trailing ? .trailing : .leading)
        }
        .frame(maxWidth: .infinity, alignment: trailing ? .trailing : .leading)
    }

    /// Currency formatting that adapts to the device locale.
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

    // MARK: Category Cap Overlay
    @ViewBuilder
    private var categoryCapOverlayView: some View {
        if isShowingCategoryCapOverlay, let overlay = categoryCapOverlay {
            CategoryCapQuickLook(
                model: makeQuickLookModel(from: overlay),
                onDismiss: dismissCategoryCapOverlay,
                onEdit: { editCategoryCap(overlay) }
            )
            .id(overlay.id)
            .transition(.opacity.combined(with: .scale(scale: 0.97)))
            .zIndex(1)
        }
    }

    private func handleCategoryChipLongPress(categoryID: UUID?, fallbackName: String, displayedAmount: Double, segment: Segment) {
        guard let categoryID else { return }
        let resolvedSpending = categorySpending(for: categoryID, segment: segment)
        let resolvedName = resolvedSpending?.categoryName ?? fallbackName
        let resolvedSpent = resolvedSpending?.amount ?? displayedAmount
        let capAmount = loadCapAmount(for: categoryID, segment: segment, period: budgetPeriod)
        let overlayData = CategoryCapOverlayData(
            categoryID: categoryID,
            categoryName: resolvedName,
            segment: segment,
            spent: resolvedSpent,
            capAmount: capAmount
        )
        withAnimation(.easeInOut(duration: 0.2)) {
            categoryCapOverlay = overlayData
            isShowingCategoryCapOverlay = true
        }
    }

    private func refreshCategoryCapOverlay(reloadCap: Bool) {
        guard isShowingCategoryCapOverlay, var overlay = categoryCapOverlay else { return }
        guard let updated = categorySpending(for: overlay.categoryID, segment: overlay.segment) else {
            dismissCategoryCapOverlay()
            return
        }
        overlay.categoryName = updated.categoryName
        overlay.spent = updated.amount
        if reloadCap {
            overlay.capAmount = loadCapAmount(for: overlay.categoryID, segment: overlay.segment, period: budgetPeriod)
        }
        categoryCapOverlay = overlay
    }

    private func dismissCategoryCapOverlay() {
        guard isShowingCategoryCapOverlay else { return }
        withAnimation(.easeInOut(duration: 0.2)) {
            isShowingCategoryCapOverlay = false
        }
        categoryCapOverlay = nil
    }

    private func editCategoryCap(_ data: CategoryCapOverlayData) {
        editingCategoryCap = data
    }

    private func categorySpending(for categoryID: UUID, segment: Segment) -> BudgetSummary.CategorySpending? {
        let breakdown = segment == .planned ? summary?.plannedCategoryBreakdown : summary?.variableCategoryBreakdown
        return breakdown?.first(where: { $0.categoryID == categoryID })
    }

    private func loadCapAmount(for categoryID: UUID, segment: Segment, period: BudgetPeriod) -> Double? {
        do {
            let service = CategorySpendingCapService()
            return try service.loadCap(
                categoryID: categoryID,
                expenseType: expenseType(for: segment),
                period: period
            )?.amount
        } catch {
            return nil
        }
    }

    private func expenseType(for segment: Segment) -> CategorySpendingCapService.ExpenseType {
        switch segment {
        case .planned: return .planned
        case .variable: return .variable
        }
    }

    private func makeQuickLookModel(from data: CategoryCapOverlayData) -> CategoryCapQuickLook.Model {
        let capFormatted = data.capAmount.map { formatCurrency($0) }
        let gaugeCandidate = max(data.capAmount ?? 0, data.spent)
        let gaugeUpperBound = gaugeCandidate > 0 ? gaugeCandidate : 1
        let gaugeMaximumLabel = capFormatted ?? formatCurrency(max(data.spent, 0))
        return CategoryCapQuickLook.Model(
            categoryName: data.categoryName,
            segmentTitle: data.segment.displayTitle,
            spentValue: data.spent,
            spentFormatted: formatCurrency(data.spent),
            capFormatted: capFormatted,
            gaugeUpperBound: gaugeUpperBound,
            gaugeMaximumLabel: gaugeMaximumLabel,
            progressText: data.capAmount.flatMap { percentDescription(spent: data.spent, cap: $0) },
            emptyCapMessage: data.capAmount == nil ? "No cap set" : nil
        )
    }

    private func percentDescription(spent: Double, cap: Double) -> String? {
        guard cap > 0 else { return nil }
        let ratio = max(spent / cap, 0)
        let formatter = NumberFormatter()
        formatter.numberStyle = .percent
        formatter.maximumFractionDigits = ratio < 0.1 ? 1 : 0
        formatter.minimumFractionDigits = 0
        return formatter.string(from: NSNumber(value: ratio)).map { "\($0) of cap used" }
    }

    private struct CategoryCapQuickLook: View {
        struct Model {
            let categoryName: String
            let segmentTitle: String
            let spentValue: Double
            let spentFormatted: String
            let capFormatted: String?
            let gaugeUpperBound: Double
            let gaugeMaximumLabel: String
            let progressText: String?
            let emptyCapMessage: String?
        }

        let model: Model
        let onDismiss: () -> Void
        let onEdit: () -> Void

        var body: some View {
            GeometryReader { proxy in
                ZStack(alignment: .center) {
                    Color.black.opacity(0.35)
                        .ignoresSafeArea()
                        .contentShape(Rectangle())
                        .onTapGesture { onDismiss() }

                    VStack(alignment: .leading, spacing: 18) {
                        HStack {
                            editButton
                            Spacer()
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            Text(model.categoryName)
                                .font(.title3.weight(.semibold))
                            Text(model.segmentTitle)
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(.secondary)
                        }

                        Gauge(value: model.spentValue, in: 0...model.gaugeUpperBound) {
                            Text("Progress")
                                .font(.caption.weight(.semibold))
                        } currentValueLabel: {
                            Text(model.spentFormatted)
                                .font(.caption.weight(.semibold).monospacedDigit())
                        } minimumValueLabel: {
                            Text("$0")
                                .font(.caption2.monospacedDigit())
                                .foregroundStyle(.secondary)
                        } maximumValueLabel: {
                            Text(model.gaugeMaximumLabel)
                                .font(.caption2.monospacedDigit())
                                .foregroundStyle(.secondary)
                        }

                        HStack(alignment: .top, spacing: 20) {
                            valueColumn(title: "Spent", value: model.spentFormatted)
                            if let cap = model.capFormatted {
                                valueColumn(title: "Cap", value: cap)
                            }
                        }

                        if let message = model.emptyCapMessage {
                            Text(message)
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }

                        if let progress = model.progressText {
                            Text(progress)
                                .font(.footnote.weight(.semibold))
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(22)
                    .frame(
                        maxWidth: max(260, min(max(proxy.size.width - 40, 0), 360)),
                        alignment: .leading
                    )
                    .background(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .fill(.ultraThinMaterial)
                    )
                    .shadow(color: Color.black.opacity(0.2), radius: 18, x: 0, y: 6)
                }
            }
        }

        @ViewBuilder
        private var editButton: some View {
            if #available(iOS 26.0, macCatalyst 26.0, macOS 26.0, *) {
                Button(action: onEdit) {
                    Label("Edit", systemImage: "slider.horizontal.3")
                        .font(.callout.weight(.semibold))
                        .labelStyle(.titleAndIcon)
                        .padding(.horizontal, 12)
                        .frame(height: 33)
                }
                .buttonBorderShape(.capsule)
                .buttonStyle(.glass)
            } else {
                Button(action: onEdit) {
                    Label("Edit", systemImage: "slider.horizontal.3")
                        .font(.callout.weight(.semibold))
                        .labelStyle(.titleAndIcon)
                        .padding(.horizontal, 12)
                        .frame(height: 33)
                        .background(
                            Capsule(style: .circular)
                                .fill(Color.primary.opacity(0.08))
                        )
                }
                .buttonBorderShape(.capsule)
                .buttonStyle(.plain)
            }
        }

        private func valueColumn(title: String, value: String) -> some View {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                Text(value)
                    .font(.headline.monospacedDigit())
            }
        }
    }

    private extension Segment {
        var displayTitle: String {
            switch self {
            case .planned: return "Planned Expenses"
            case .variable: return "Variable Expenses"
            }
        }
    }

    // MARK: Chips Styling
    @ViewBuilder
    private func chipView(categoryID: UUID?, title: String, amount: Double, hex: String?, segment: Segment) -> some View {
        let dot = UBColorFromHex(hex) ?? .secondary
        let chipLabel = HStack(spacing: 8) {
            Circle().fill(dot).frame(width: 8, height: 8)
            Text(title).font(.subheadline.weight(.medium))
            Text(formatCurrency(amount)).font(.subheadline.weight(.semibold))
        }
            .padding(.horizontal, 12)
            .frame(height: 33)
            .background(.clear)
        let longPress = LongPressGesture(minimumDuration: 0.5)
            .onEnded { isPressed in
                guard isPressed else { return }
                handleCategoryChipLongPress(
                    categoryID: categoryID,
                    fallbackName: title,
                    displayedAmount: amount,
                    segment: segment
                )
            }
        if #available(iOS 26.0, macCatalyst 26.0, macOS 26.0, *) {
            Button(action: {}) { chipLabel }
                .buttonStyle(.glass)
                .buttonBorderShape(.capsule)
                .foregroundStyle(.primary)
                .allowsHitTesting(true)
                .disabled(false)
                .frame(height: 33)
                .clipShape(Capsule())
                .compositingGroup()
                .simultaneousGesture(longPress)
        } else {
            chipLabel
                .background(
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(Color(UIColor { traits in
                            traits.userInterfaceStyle == .dark ? UIColor(white: 0.22, alpha: 1) : UIColor(white: 0.9, alpha: 1)
                        }))
                )
                .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                .frame(height: 33)
                .gesture(longPress)
        }

    }

    // MARK: Rows + Data
    private func plannedRow(_ exp: PlannedExpense) -> some View {
        let title = (exp.value(forKey: "descriptionText") as? String) ?? (exp.value(forKey: "title") as? String) ?? "Expense"
        let dateStr: String = {
            let f = DateFormatter(); f.dateStyle = .medium
            if let d = exp.transactionDate { return f.string(from: d) }
            return ""
        }()
        return HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title).font(.headline)
                Text(dateStr).font(.subheadline).foregroundStyle(.secondary)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 4) {
                Text("Planned: \(formatCurrency(exp.plannedAmount))")
                    .font(.subheadline.weight(.semibold))
                Text("Actual: \(formatCurrency(exp.actualAmount))")
                    .font(.subheadline)
            }
        }
        .frame(maxWidth: .infinity)
    }

    private func variableRow(_ exp: UnplannedExpense) -> some View {
        let title = readUnplannedDescription(exp) ?? "Expense"
        let f = DateFormatter(); f.dateStyle = .medium
        let dateStr: String = { let f = DateFormatter(); f.dateStyle = .medium; if let d = exp.transactionDate { return f.string(from: d) }; return "" }()
        return HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title).font(.headline)
                Text(dateStr).font(.subheadline).foregroundStyle(.secondary)
            }
            Spacer()
            Text(formatCurrency(exp.amount)).font(.headline)
        }
        .frame(maxWidth: .infinity)
    }

    private func reloadRows() {
        guard let summary else { plannedRows = []; variableRows = []; return }
        let context = CoreDataService.shared.viewContext
        guard let budget = try? context.existingObject(with: summary.id) as? Budget else {
            plannedRows = []; variableRows = []; return
        }

        // Build date range for the selected period
        let (start, end) = budgetPeriod.range(containing: vm.selectedDate)

        // Planned
        do {
            let req = NSFetchRequest<PlannedExpense>(entityName: "PlannedExpense")
            req.predicate = NSPredicate(format: "budget == %@ AND transactionDate >= %@ AND transactionDate <= %@",
                                        budget, start as NSDate, end as NSDate)
            req.sortDescriptors = plannedSortDescriptors
            plannedRows = try context.fetch(req)
        } catch { plannedRows = [] }

        // Variable (Unplanned) via card relation
        do {
            let req = NSFetchRequest<UnplannedExpense>(entityName: "UnplannedExpense")
            if let cards = budget.cards as? Set<Card>, !cards.isEmpty {
                req.predicate = NSPredicate(format: "card IN %@ AND transactionDate >= %@ AND transactionDate <= %@",
                                            cards as NSSet, start as NSDate, end as NSDate)
            } else {
                req.predicate = NSPredicate(value: false)
            }
            req.sortDescriptors = variableSortDescriptors
            variableRows = try context.fetch(req)
        } catch { variableRows = [] }
    }

    private var plannedSortDescriptors: [NSSortDescriptor] {
        switch sort {
        case .titleAZ: return [NSSortDescriptor(key: "descriptionText", ascending: true, selector: #selector(NSString.localizedCaseInsensitiveCompare(_:)))]
        case .amountLowHigh: return [NSSortDescriptor(key: "actualAmount", ascending: true)]
        case .amountHighLow: return [NSSortDescriptor(key: "actualAmount", ascending: false)]
        case .dateOldNew: return [NSSortDescriptor(key: "transactionDate", ascending: true)]
        case .dateNewOld: return [NSSortDescriptor(key: "transactionDate", ascending: false)]
        }
    }

    private var variableSortDescriptors: [NSSortDescriptor] {
        switch sort {
        case .titleAZ: return [NSSortDescriptor(key: "descriptionText", ascending: true, selector: #selector(NSString.localizedCaseInsensitiveCompare(_:)))]
        case .amountLowHigh: return [NSSortDescriptor(key: "amount", ascending: true)]
        case .amountHighLow: return [NSSortDescriptor(key: "amount", ascending: false)]
        case .dateOldNew: return [NSSortDescriptor(key: "transactionDate", ascending: true)]
        case .dateNewOld: return [NSSortDescriptor(key: "transactionDate", ascending: false)]
        }
    }

    private func delete(planned: PlannedExpense) {
        do {
            try PlannedExpenseService().delete(planned)
            reloadRows()
            Task { await vm.refresh() }
        } catch { /* swallow for now */ }
    }

    private func delete(unplanned: UnplannedExpense) {
        do {
            try UnplannedExpenseService().delete(unplanned)
            reloadRows()
            Task { await vm.refresh() }
        } catch { /* swallow for now */ }
    }

    /// Reads `descriptionText` or `title` from an `UnplannedExpense`, matching the service's behavior.
    private func readUnplannedDescription(_ object: NSManagedObject) -> String? {
        let keys = object.entity.attributesByName.keys
        if keys.contains("descriptionText") {
            return object.value(forKey: "descriptionText") as? String
        } else if keys.contains("title") {
            return object.value(forKey: "title") as? String
        }
        return nil
    }
}

//

// MARK: - Hex Color Helper (local)
fileprivate func UBColorFromHex(_ hex: String?) -> Color? {
    guard var value = hex?.trimmingCharacters(in: .whitespacesAndNewlines), !value.isEmpty else { return nil }
    if value.hasPrefix("#") { value.removeFirst() }
    guard value.count == 6, let intVal = Int(value, radix: 16) else { return nil }
    let r = Double((intVal >> 16) & 0xFF) / 255.0
    let g = Double((intVal >> 8) & 0xFF) / 255.0
    let b = Double((intVal & 0xFF)) / 255.0
    return Color(red: r, green: g, blue: b)
}

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

    // Shared width so the left column of the right-side pairs (Max/Min)
    // aligns vertically across rows.
    @State private var rightPairLeftColumnWidth: CGFloat = 0
    // Shared width for the right column of the right-side pairs (Projected/Actual Planned)
    @State private var rightPairRightColumnWidth: CGFloat = 0

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
        .onChange(of: vm.state) { _ in
            reloadRows()
            let shouldShowAddMenu = (summary != nil)
            guard shouldShowAddMenu != isAddMenuVisible else { return }
            withAnimation(.easeInOut(duration: 0.2)) {
                isAddMenuVisible = shouldShowAddMenu
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
                .frame(width: 44, height: 44)
                .glassEffectUnion(id: "home-toolbar", namespace: homeToolbarGlassNamespace)
                .glassEffectID(symbol, in: homeToolbarGlassNamespace)
                .glassEffectTransition(.matchedGeometry)
        } else {
            Image(systemName: symbol)
                .font(.system(size: 16, weight: .semibold))
                .frame(width: 44, height: 44)
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
                    .frame(width: 44, height: 44)
                    .glassEffect(.regular.tint(.clear).interactive(true))
            }
            .buttonStyle(.plain)
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
                // Left: keep Potential Income
                metricColumn(title: "POTENTIAL INCOME", value: potentialIncome, color: .orange, trailing: false, fillHorizontally: false)
                Spacer(minLength: 0)
                // Right: show Max and Projected Savings side‑by‑side; Projected aligns with Actual below.
                HStack(spacing: 8) {
                    metricColumn(title: "MAX SAVINGS", value: maxSavings, color: savingsColor(maxSavings), trailing: false, fillHorizontally: false, valueLeading: true)
                        .fixedSize(horizontal: true, vertical: false)
                        .background(GeometryReader { proxy in
                            Color.clear.preference(key: RightPairLeftWidthKey.self, value: proxy.size.width)
                        })
                        .frame(width: rightPairLeftColumnWidth == 0 ? nil : rightPairLeftColumnWidth, alignment: .leading)
                    metricColumn(title: "PROJECTED SAVINGS", value: projectedSavings, color: savingsColor(projectedSavings), trailing: true, fillHorizontally: false)
                        .fixedSize(horizontal: true, vertical: false)
                        .background(GeometryReader { proxy in
                            Color.clear.preference(key: RightPairRightWidthKey.self, value: proxy.size.width)
                        })
                        .frame(width: rightPairRightColumnWidth == 0 ? nil : rightPairRightColumnWidth, alignment: .trailing)
                }
                .frame(maxWidth: .infinity, alignment: .trailing)
            }
            HStack(alignment: .lastTextBaseline) {
                metricColumn(title: "ACTUAL INCOME", value: actualIncome, color: .blue, trailing: false)
                Spacer(minLength: 0)
                metricColumn(title: "ACTUAL SAVINGS", value: actualSavings, color: savingsColor(actualSavings), trailing: true)
            }
            HStack(alignment: .lastTextBaseline) {
                Text(segment == .planned ? "PLANNED EXPENSES" : "VARIABLE EXPENSES")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                Spacer(minLength: 0)
                if segment == .planned {
                    // Show Minimum Planned and Actual Planned side‑by‑side
                    HStack(spacing: 8) {
                        metricColumn(title: "MIN PLANNED", value: plannedTotal, color: .primary, trailing: false, fillHorizontally: false, valueLeading: true)
                            .fixedSize(horizontal: true, vertical: false)
                            .background(GeometryReader { proxy in
                                Color.clear.preference(key: RightPairLeftWidthKey.self, value: proxy.size.width)
                            })
                            .frame(width: rightPairLeftColumnWidth == 0 ? nil : rightPairLeftColumnWidth, alignment: .leading)
                        metricColumn(title: "ACTUAL PLANNED", value: plannedActualTotal, color: .primary, trailing: true, fillHorizontally: false)
                            .fixedSize(horizontal: true, vertical: false)
                            .background(GeometryReader { proxy in
                                Color.clear.preference(key: RightPairRightWidthKey.self, value: proxy.size.width)
                            })
                            .frame(width: rightPairRightColumnWidth == 0 ? nil : rightPairRightColumnWidth, alignment: .trailing)
                    }
                    .frame(maxWidth: .infinity, alignment: .trailing)
                } else {
                    Text(formatCurrency(variableTotal))
                        .font(.title3.weight(.semibold))
                }
            }
        }
        .onPreferenceChange(RightPairLeftWidthKey.self) { width in
            // Keep the maximum width seen so both rows align.
            if width > rightPairLeftColumnWidth { rightPairLeftColumnWidth = width }
        }
        .onPreferenceChange(RightPairRightWidthKey.self) { width in
            if width > rightPairRightColumnWidth { rightPairRightColumnWidth = width }
        }
    }

    // MARK: Category Chips
    private var categoryChips: some View {
        // Prefer the computed breakdown when a budget summary exists; otherwise
        // show all categories with zero amounts so chips are always visible.
        let categories: [BudgetSummary.CategorySpending] = {
            if let s = summary {
                return (segment == .planned ? s.plannedCategoryBreakdown : s.variableCategoryBreakdown)
            } else {
                let req = NSFetchRequest<ExpenseCategory>(entityName: "ExpenseCategory")
                req.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true, selector: #selector(NSString.localizedCaseInsensitiveCompare(_:)))]
                let items: [ExpenseCategory] = (try? moc.fetch(req)) ?? []
                return items.map { cat in
                    let name = (cat.name ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
                    return BudgetSummary.CategorySpending(categoryURI: cat.objectID.uriRepresentation(), categoryName: name, hexColor: cat.color, amount: 0)
                }
            }
        }()

        return ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(categories) { cat in
                    chipView(title: cat.categoryName, amount: cat.amount, hex: cat.hexColor)
                }
                if categories.isEmpty {
                    Text("No categories yet")
                        .foregroundStyle(.secondary)
                        .padding(.vertical, 8)
                }
            }
            .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
        }
        .frame(height: 44)
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
            Text("No variable expenses in this period.\nPress + to add a planned expense.")
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.vertical, 8)
                .listRowInsets(EdgeInsets(top: 0, leading: horizontalPadding, bottom: 0, trailing: horizontalPadding))
                .listRowSeparator(.hidden)
        } else if segment == .planned, plannedRows.isEmpty {
            Text("No planned expenses in this period.\nPress the + to add a planned expense.")
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
            let targetRange = budgetPeriod.range(containing: vm.selectedDate)
            let calendar = Calendar.current
            return items.first { item in
                calendar.isDate(item.periodStart, inSameDayAs: targetRange.start) &&
                calendar.isDate(item.periodEnd, inSameDayAs: targetRange.end)
            }
        default:
            return nil
        }
    }

    private var potentialIncome: Double { summary?.potentialIncomeTotal ?? 0 }
    private var maxSavings: Double { summary?.potentialSavingsTotal ?? 0 }
    private var projectedSavings: Double {
        let s = summary
        return (s?.potentialIncomeTotal ?? 0) - (s?.plannedExpensesPlannedTotal ?? 0) - (s?.variableExpensesTotal ?? 0)
    }
    private var actualIncome: Double { summary?.actualIncomeTotal ?? 0 }
    private var actualSavings: Double { summary?.actualSavingsTotal ?? 0 }
    // For the Planned segment, show the planned (budgeted) amount, not the
    // amount actually paid so far. The per‑row cells already display both.
    private var plannedTotal: Double { summary?.plannedExpensesPlannedTotal ?? 0 }
    private var plannedActualTotal: Double { summary?.plannedExpensesActualTotal ?? 0 }
    private var variableTotal: Double { summary?.variableExpensesTotal ?? 0 }

    private var horizontalPadding: CGFloat { 20 }

    // MARK: Helpers
    /// Returns green for positive/zero savings and red for negative.
    private func savingsColor(_ amount: Double) -> Color { amount >= 0 ? .green : .red }

    /// Forwards the budget period change to the view model so it can
    /// persist the preference and refresh derived state.
    private func updateBudgetPeriod(to newValue: BudgetPeriod) {
        vm.updateBudgetPeriod(to: newValue)
    }

    /// Renders a metric label/value pair for a given amount.
    private func metricColumn(title: String, value: Double, color: Color, trailing: Bool, fillHorizontally: Bool = true, valueLeading: Bool = false) -> some View {
        let align: Alignment = trailing ? .trailing : .leading
        let valueAlign: Alignment = valueLeading ? .leading : align
        return VStack(alignment: trailing ? .trailing : .leading, spacing: 6) {
            let titleView = Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
            if fillHorizontally {
                titleView.frame(maxWidth: .infinity, alignment: align)
            } else {
                titleView.frame(alignment: align)
            }
            let valueView = Text(formatCurrency(value))
                .font(.body.weight(.semibold))
                .foregroundStyle(color)
            if fillHorizontally {
                valueView.frame(maxWidth: .infinity, alignment: valueAlign)
            } else {
                valueView.frame(alignment: valueAlign)
            }
        }
        .frame(maxWidth: fillHorizontally ? .infinity : nil, alignment: align)
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

    // MARK: Chips Styling
    @ViewBuilder
    private func chipView(title: String, amount: Double, hex: String?) -> some View {
        let dot = UBColorFromHex(hex) ?? .secondary
        let chipLabel = HStack(spacing: 8) {
            Circle().fill(dot).frame(width: 8, height: 8)
            Text(title).font(.subheadline.weight(.medium))
            Text(formatCurrency(amount)).font(.subheadline.weight(.semibold))
        }
        .padding(.horizontal, 12)
        .frame(height: 44)
        .background(.clear)

        if #available(iOS 26.0, macCatalyst 26.0, macOS 26.0, *) {
            Button(action: {}) {
                chipLabel
                    .glassEffect(.regular.tint(.none).interactive(false))
                    .frame(minHeight: 44, maxHeight: 44)
            }
            .buttonBorderShape(.capsule)
            .foregroundStyle(.primary)
            .allowsHitTesting(false)
            .disabled(true)
            .frame(minHeight: 44, maxHeight: 44)
            .clipShape(Capsule())
            .compositingGroup()
        } else {
            chipLabel
                .frame(minHeight: 44, maxHeight: 44)
                .background(
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(Color(UIColor { traits in
                            traits.userInterfaceStyle == .dark ? UIColor(white: 0.22, alpha: 1) : UIColor(white: 0.9, alpha: 1)
                        }))
                )
                .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                .frame(minHeight: 44, maxHeight: 44)
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

        // Build date range based on the budget's actual period
        var startCandidate: Date? = summary.periodStart
        var endCandidate: Date? = summary.periodEnd

        if startCandidate == nil { startCandidate = budget.startDate }
        if endCandidate == nil { endCandidate = budget.endDate }

        guard var start = startCandidate, var end = endCandidate else {
            plannedRows = []
            variableRows = []
            return
        }

        if start > end {
            swap(&start, &end)
        }

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

// Local preference key to align the left column width across right-side pairs
private struct RightPairLeftWidthKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}

private struct RightPairRightWidthKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}

// Disable previously added overlay implementation
#if false
// MARK: - HomeView (Category Cap Overlay)
private extension HomeView {
    // Backdrop behind the bottom overlay
    @ViewBuilder
    var capDimmingBackdrop: some View {
        if isShowingCapOverlay {
            Color.black.opacity(0.25)
                .ignoresSafeArea()
                .transition(.opacity)
                .onTapGesture { dismissCapOverlay() }
        }
    }

    // Bottom-anchored overlay hosting Gauge/Edit
    @ViewBuilder
    var capOverlay: some View {
        if isShowingCapOverlay, let oc = overlayCategory {
            VStack(spacing: 12) {
                HStack {
                    Button(action: { capMode == .gauge ? dismissCapOverlay() : withAnimation(.spring()) { capMode = .gauge } }) {
                        Text(capMode == .gauge ? "Done" : "Back")
                            .font(.headline)
                    }
                    Spacer()
                    Text(oc.name)
                        .font(.headline)
                    Spacer()
                    if capMode == .gauge {
                        Button(action: { withAnimation(.spring()) { enterEditMode() } }) {
                            Text("Edit").font(.headline)
                        }
                    } else {
                        Button(action: { saveCaps() }) {
                            Text("Save").font(.headline)
                        }
                    }
                }
                .frame(maxWidth: .infinity)

                if capMode == .gauge {
                    gaugeContent(categoryColor: oc.color, current: oc.currentAmount)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                } else {
                    editContent(categoryColor: oc.color)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity)
            .modifier(OverlayGlassOrLegacyBackground())
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
            .shadow(color: .black.opacity(0.2), radius: 12, x: 0, y: 4)
            .onChange(of: vm.selectedDate) { _ in reloadCapsForSelectionChange() }
            .onChange(of: budgetPeriodRawValue) { _ in reloadCapsForSelectionChange() }
            .onChange(of: segment) { _ in reloadCapsForSelectionChange(resetAmount: true) }
            .animation(.spring(response: 0.4, dampingFraction: 0.85), value: capMode)
        } else {
            EmptyView()
        }
    }

    private struct OverlayGlassOrLegacyBackground: ViewModifier {
        func body(content: Content) -> some View {
            if #available(iOS 26.0, macCatalyst 26.0, macOS 26.0, *) {
                content
                    .glassEffect(.regular.tint(.none).interactive(true))
            } else {
                content
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(Color(UIColor { traits in
                                traits.userInterfaceStyle == .dark ? UIColor(white: 0.16, alpha: 1) : UIColor(white: 0.97, alpha: 1)
                            }))
                    )
            }
        }
    }

    // MARK: Content Builders
    private func gaugeContent(categoryColor: Color, current: Double) -> some View {
        VStack(spacing: 12) {
            Gauge(value: clamp(current, min: capMin, max: capMax), in: capMin...max(capMax, capMin)) {
                Text("Budget Cap")
            } currentValueLabel: {
                Text(formatCurrency(current))
            } minimumValueLabel: {
                Text(formatCurrency(capMin))
            } maximumValueLabel: {
                Text(formatCurrency(capMax))
            }
            .tint(categoryColor)

            HStack {
                Text("Current: \(formatCurrency(current))").foregroundStyle(.secondary)
                Spacer()
                Text("Range: \(formatCurrency(capMin)) – \(formatCurrency(capMax))").foregroundStyle(.secondary)
            }
            .font(.footnote)
        }
    }

    private func editContent(categoryColor: Color) -> some View {
        VStack(spacing: 16) {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Minimum")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.secondary)
                    TextField("0.00", text: $editMinInput)
                        .keyboardType(.decimalPad)
                        .textFieldStyle(.roundedBorder)
                }
                VStack(alignment: .leading, spacing: 6) {
                    Text("Maximum")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.secondary)
                    TextField("0.00", text: $editMaxInput)
                        .keyboardType(.decimalPad)
                        .textFieldStyle(.roundedBorder)
                }
            }
            .tint(categoryColor)
        }
    }

    // MARK: Overlay Actions
    private func presentCapOverlay(for cat: BudgetSummary.CategorySpending) {
        let color = UBColorFromHex(cat.hexColor) ?? .secondary
        if let id = objectID(from: cat.categoryURI) {
            overlayCategory = OverlayCategory(
                id: id,
                name: cat.categoryName,
                color: color,
                segment: segment,
                currentAmount: cat.amount
            )
        } else {
            return
        }
        loadCaps()
        capMode = .gauge
        isShowingCapOverlay = true
        #if canImport(UIKit)
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        #endif
    }

    private func dismissCapOverlay() {
        withAnimation(.spring()) {
            isShowingCapOverlay = false
            capMode = .gauge
        }
    }

    private func enterEditMode() {
        editMinInput = plainDecimalString(capMin)
        editMaxInput = plainDecimalString(capMax)
        capMode = .edit
    }

    private func reloadCapsForSelectionChange(resetAmount: Bool = false) {
        guard isShowingCapOverlay, overlayCategory != nil else { return }
        if resetAmount {
            // If segment changed, the chip amount changes source – update currentAmount from summary
            if let oc = overlayCategory {
                let categories = (segment == .planned ? summary?.plannedCategoryBreakdown : summary?.variableCategoryBreakdown) ?? []
                let targetURI = oc.id.uriRepresentation()
                if let fresh = categories.first(where: { $0.categoryURI == targetURI }) {
                    overlayCategory = OverlayCategory(id: oc.id, name: oc.name, color: oc.color, segment: segment, currentAmount: fresh.amount)
                } else {
                    // Category missing in this segment – keep amount at 0
                    overlayCategory = OverlayCategory(id: oc.id, name: oc.name, color: oc.color, segment: segment, currentAmount: 0)
                }
            }
        }
        loadCaps()
    }

    private func objectID(from uri: URL) -> NSManagedObjectID? {
        CoreDataService.shared.container.persistentStoreCoordinator.managedObjectID(forURIRepresentation: uri)
    }

    // MARK: Persistence
    private func loadCaps() {
        guard let oc = overlayCategory else { return }
        let key = periodKey(for: budgetPeriod, date: vm.selectedDate, segment: oc.segment)
        guard let category = try? moc.existingObject(with: oc.id) as? ExpenseCategory else {
            let current = overlayCategory?.currentAmount ?? 0
            capMin = 0
            capMax = max(current, 1)
            return
        }
        let fetch = NSFetchRequest<CategorySpendingCap>(entityName: "CategorySpendingCap")
        fetch.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
            NSPredicate(format: "category == %@", category),
            NSPredicate(format: "period == %@", key),
            NSPredicate(format: "expenseType IN %@", ["min", "max"])
        ])
        do {
            let results = try moc.fetch(fetch)
            var minVal: Double? = nil
            var maxVal: Double? = nil
            for r in results {
                if (r.value(forKey: "expenseType") as? String)?.lowercased() == "min" {
                    minVal = r.value(forKey: "amount") as? Double
                } else if (r.value(forKey: "expenseType") as? String)?.lowercased() == "max" {
                    maxVal = r.value(forKey: "amount") as? Double
                }
            }
            let current = overlayCategory?.currentAmount ?? 0
            capMin = minVal ?? 0
            capMax = maxVal ?? max(current, 1)
        } catch {
            let current = overlayCategory?.currentAmount ?? 0
            capMin = 0
            capMax = max(current, 1)
        }
    }

    private func saveCaps() {
        guard let oc = overlayCategory else { return }
        let key = periodKey(for: budgetPeriod, date: vm.selectedDate, segment: oc.segment)
        guard let category = try? moc.existingObject(with: oc.id) as? ExpenseCategory else { return }

        guard let newMin = parseDecimal(editMinInput), let newMax = parseDecimal(editMaxInput) else {
            #if canImport(UIKit)
            UINotificationFeedbackGenerator().notificationOccurred(.error)
            #endif
            return
        }
        guard newMin <= newMax else {
            #if canImport(UIKit)
            UINotificationFeedbackGenerator().notificationOccurred(.error)
            #endif
            return
        }

        // Upsert two records (min and max)
        let fetch = NSFetchRequest<CategorySpendingCap>(entityName: "CategorySpendingCap")
        fetch.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
            NSPredicate(format: "category == %@", category),
            NSPredicate(format: "period == %@", key),
            NSPredicate(format: "expenseType IN %@", ["min", "max"])
        ])

        do {
            let results = try moc.fetch(fetch)
            var minObj = results.first(where: { ($0.value(forKey: "expenseType") as? String)?.lowercased() == "min" })
            var maxObj = results.first(where: { ($0.value(forKey: "expenseType") as? String)?.lowercased() == "max" })

            if minObj == nil {
                minObj = NSEntityDescription.insertNewObject(forEntityName: "CategorySpendingCap", into: moc) as? CategorySpendingCap
                minObj?.setValue(UUID(), forKey: "id")
                minObj?.setValue("min", forKey: "expenseType")
                minObj?.setValue(category, forKey: "category")
                minObj?.setValue(key, forKey: "period")
            }
            if maxObj == nil {
                maxObj = NSEntityDescription.insertNewObject(forEntityName: "CategorySpendingCap", into: moc) as? CategorySpendingCap
                maxObj?.setValue(UUID(), forKey: "id")
                maxObj?.setValue("max", forKey: "expenseType")
                maxObj?.setValue(category, forKey: "category")
                maxObj?.setValue(key, forKey: "period")
            }

            minObj?.setValue(newMin, forKey: "amount")
            maxObj?.setValue(newMax, forKey: "amount")

            try moc.save()
            capMin = newMin
            capMax = newMax
            withAnimation(.spring()) { capMode = .gauge }
            #if canImport(UIKit)
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            #endif
        } catch {
            AppLog.ui.error("Failed to save caps: \(error.localizedDescription)")
            #if canImport(UIKit)
            UINotificationFeedbackGenerator().notificationOccurred(.error)
            #endif
        }
    }

    // MARK: Keys & Formatting
    private func periodKey(for period: BudgetPeriod, date: Date, segment: Segment) -> String {
        let (start, end) = period.range(containing: date)
        let f = DateFormatter()
        f.calendar = Calendar(identifier: .gregorian)
        f.locale = Locale(identifier: "en_US_POSIX")
        f.timeZone = TimeZone(secondsFromGMT: 0)
        f.dateFormat = "yyyy-MM-dd"
        let s = f.string(from: start)
        let e = f.string(from: end)
        return "\(period.rawValue)|\(s)|\(e)|\(segment.rawValue)"
    }

    private func clamp(_ value: Double, min: Double, max: Double) -> Double {
        Swift.max(min, Swift.min(value, max))
    }

    private func plainDecimalString(_ value: Double) -> String {
        let nf = NumberFormatter()
        nf.numberStyle = .decimal
        nf.maximumFractionDigits = 2
        nf.minimumFractionDigits = 0
        return nf.string(from: value as NSNumber) ?? String(format: "%.2f", value)
    }

    private func parseDecimal(_ text: String) -> Double? {
        let nf = NumberFormatter()
        nf.numberStyle = .decimal
        nf.maximumFractionDigits = 2
        nf.minimumFractionDigits = 0
        if let n = nf.number(from: text.trimmingCharacters(in: .whitespacesAndNewlines)) {
            return n.doubleValue
        }
        // Fallback: replace commas and attempt Double init
        let sanitized = text.replacingOccurrences(of: ",", with: ".").replacingOccurrences(of: " ", with: "")
        return Double(sanitized)
    }
}
#endif

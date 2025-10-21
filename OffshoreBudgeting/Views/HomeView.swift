import SwiftUI
import CoreData
import Combine
#if canImport(UIKit)
import UIKit
#endif

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
    @AppStorage(AppSettingsKeys.confirmBeforeDelete.rawValue)
    private var confirmBeforeDelete: Bool = true

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
    @State private var plannedDeletionBox: ObjectIDBox?
    @State private var unplannedDeletionBox: ObjectIDBox?

    // Backing data for list rows
    @State private var plannedRows: [PlannedExpense] = []
    @State private var variableRows: [UnplannedExpense] = []
    @State private var currentSummaryID: NSManagedObjectID? = nil
    @State private var lastNonNilSummary: BudgetSummary? = nil

    // Shared width so the left column of the right-side pairs (Max/Min)
    // aligns vertically across rows.
    @State private var rightPairLeftColumnWidth: CGFloat = 0
    // Shared width for the right column of the right-side pairs (Projected/Actual Planned)
    @State private var rightPairRightColumnWidth: CGFloat = 0

    // MARK: Category Chip Menu (Step 1)
    @State private var chipMenuSelected: BudgetSummary.CategorySpending? = nil
    @State private var chipMenuVisible: Bool = false
    @State private var chipMenuSize: CGSize = .zero
    @State private var chipCapMin: Double = 0
    @State private var chipCapMax: Double = 1
    @State private var chipEditMinInput: String = ""
    @State private var chipEditMaxInput: String = ""
    @State private var chipHasExplicitMinCap: Bool = false
    @State private var chipHasExplicitMaxCap: Bool = false
    @State private var chipValidationError: String? = nil
    // Inline menu mode (preview vs. edit) to keep UX minimal inside the popover
    private enum ChipMenuMode { case preview, edit }
    @State private var chipMenuMode: ChipMenuMode = .preview

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
            isAddMenuVisible = activeSummary != nil
            reloadRows()
        }
        .onChange(of: segment) { _ in reloadRows() }
        .onChange(of: sort) { _ in reloadRows() }
        // If the selected budget period changes (via calendar menu or Settings),
        // clear any cached summary from a previous period so UI doesn't show
        // stale data for periods without an exact match.
        .onChange(of: budgetPeriodRawValue) { _ in
            lastNonNilSummary = nil
            // Immediately reflect active/inactive state in toolbar visibility
            // so the + glyph responds to period changes without waiting on a refresh.
            let shouldShowAddMenu = (activeSummary != nil)
            if shouldShowAddMenu != isAddMenuVisible {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isAddMenuVisible = shouldShowAddMenu
                }
            }
            reloadRows()
        }
        .onChange(of: vm.state) { newState in
            // Only react to stable states to reduce flicker. Keep rows visible
            // during transient .initial/.loading.
            switch newState {
            case .loaded:
                let newID = activeSummary?.id
                // Update rows; do not clear if the summary is unchanged.
                currentSummaryID = newID
                reloadRows()
                if let s = summary { lastNonNilSummary = s }
            case .empty:
                currentSummaryID = nil
                plannedRows = []
                variableRows = []
                lastNonNilSummary = nil
            default:
                break
            }
            let shouldShowAddMenu = (activeSummary != nil)
            if shouldShowAddMenu != isAddMenuVisible {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isAddMenuVisible = shouldShowAddMenu
                }
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
        .confirmationDialog(
            plannedDeletionDialogTitle(),
            isPresented: plannedDeletionDialogBinding,
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) { confirmPlannedDeletion() }
            Button("Cancel", role: .cancel) { plannedDeletionBox = nil }
        } message: {
            Text(plannedDeletionDialogMessage())
        }
        .confirmationDialog(
            unplannedDeletionDialogTitle(),
            isPresented: unplannedDeletionDialogBinding,
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) { confirmUnplannedDeletion() }
            Button("Cancel", role: .cancel) { unplannedDeletionBox = nil }
        } message: {
            Text(unplannedDeletionDialogMessage())
        }
        // Step 1: Anchored custom menu near long-pressed chip
        .overlayPreferenceValue(ChipFramePreferenceKey.self) { anchors in
            chipMenuOverlay(anchors)
        }
        // Proactively clear rows when the data store is wiped or significantly changed
        .onReceive(NotificationCenter.default.publisher(for: .dataStoreDidChange)) { _ in
            plannedRows = []
            variableRows = []
        }
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
            if let summary = activeSummary {
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
            if let s = activeSummary {
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
                        // Ensure a clear hit area for gestures
                        .contentShape(Rectangle())
                        // Capture the chip's bounds for anchored menu placement
                        .anchorPreference(key: ChipFramePreferenceKey.self, value: .bounds) { anchor in
                            [cat.categoryURI: anchor]
                        }
                        // High-priority long press so it wins over horizontal scroll gestures
                        .highPriorityGesture(
                            LongPressGesture(minimumDuration: 0.35)
                                .onEnded { _ in
                                    presentChipMenu(for: cat)
                                }
                        )
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
        // If no budget exactly matches the selected period, show a clear
        // "Budget inactive" message instead of generic empty list text.
        if activeSummary == nil {
            Text("No budget is active for this period.\nCreate a budget to add planned or variable expenses.")
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
        } else if segment == .variable, variableRows.isEmpty {
            Text("No variable expenses in this period.\nTrack purchases as they happen.")
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.vertical, 8)
                .listRowInsets(EdgeInsets(top: 0, leading: horizontalPadding, bottom: 0, trailing: horizontalPadding))
                .listRowSeparator(.hidden)
        } else if segment == .planned {
            ForEach(plannedRows, id: \.objectID) { exp in
                plannedRow(exp)
                    .unifiedSwipeActions(
                        UnifiedSwipeConfig(allowsFullSwipeToDelete: !confirmBeforeDelete),
                        onEdit: { editingPlannedBox = ObjectIDBox(id: exp.objectID) },
                        onDelete: { requestDelete(planned: exp) }
                    )
            }
        } else {
            ForEach(variableRows, id: \.objectID) { exp in
                variableRow(exp)
                    .unifiedSwipeActions(
                        UnifiedSwipeConfig(allowsFullSwipeToDelete: !confirmBeforeDelete),
                        onEdit: { editingUnplannedBox = ObjectIDBox(id: exp.objectID) },
                        onDelete: { requestDelete(unplanned: exp) }
                    )
            }
        }
    }

    // MARK: Sheets
    private var addPlannedSheet: some View {
        AddPlannedExpenseView(
            preselectedBudgetID: activeSummary?.id,
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
            if let id = activeSummary?.id,
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
            if let id = activeSummary?.id,
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

    // Only use the cached lastNonNilSummary during non-loaded states to
    // avoid cross-period bleed. When the state is loaded, require an exact
    // period match (i.e., `summary`).
    private var activeSummary: BudgetSummary? {
        switch vm.state {
        case .loaded:
            return summary
        default:
            return lastNonNilSummary
        }
    }

    private var potentialIncome: Double { activeSummary?.potentialIncomeTotal ?? 0 }
    private var maxSavings: Double { activeSummary?.potentialSavingsTotal ?? 0 }
    private var projectedSavings: Double {
        let s = activeSummary
        return (s?.potentialIncomeTotal ?? 0) - (s?.plannedExpensesPlannedTotal ?? 0) - (s?.variableExpensesTotal ?? 0)
    }
    private var actualIncome: Double { activeSummary?.actualIncomeTotal ?? 0 }
    private var actualSavings: Double { activeSummary?.actualSavingsTotal ?? 0 }
    // For the Planned segment, show the planned (budgeted) amount, not the
    // amount actually paid so far. The per‑row cells already display both.
    private var plannedTotal: Double { activeSummary?.plannedExpensesPlannedTotal ?? 0 }
    private var plannedActualTotal: Double { activeSummary?.plannedExpensesActualTotal ?? 0 }
    private var variableTotal: Double { activeSummary?.variableExpensesTotal ?? 0 }

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
                    .glassEffect(.regular.tint(.clear).interactive(true))
                    .frame(minHeight: 44, maxHeight: 44)
            }
            .buttonBorderShape(.capsule)
            .foregroundStyle(.primary)
            .allowsHitTesting(true)
            .disabled(false)
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
    @ViewBuilder
    private func plannedRow(_ exp: PlannedExpense) -> some View {
        // Re-resolve the object from the current context to avoid crashes if the
        // original instance became invalidated (e.g., after a full data wipe).
        let ctx = CoreDataService.shared.viewContext
        if let managed = try? ctx.existingObject(with: exp.objectID) as? PlannedExpense, !managed.isDeleted {
            let title = readPlannedDescription(managed) ?? "Expense"
            let dateStr: String = {
                let f = DateFormatter(); f.dateStyle = .medium
                if let d = managed.transactionDate { return f.string(from: d) }
                return ""
            }()

            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title).font(.headline)
                    Text(dateStr).font(.subheadline).foregroundStyle(.secondary)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Planned: \(formatCurrency(managed.plannedAmount))")
                        .font(.subheadline.weight(.semibold))
                    Text("Actual: \(formatCurrency(managed.actualAmount))")
                        .font(.subheadline)
                }
            }
            .frame(maxWidth: .infinity)
        } else {
            EmptyView()
        }
    }

    @ViewBuilder
    private func variableRow(_ exp: UnplannedExpense) -> some View {
        let ctx = CoreDataService.shared.viewContext
        if let managed = try? ctx.existingObject(with: exp.objectID) as? UnplannedExpense, !managed.isDeleted {
            let title = readUnplannedDescription(managed) ?? "Expense"
            let dateStr: String = {
                let f = DateFormatter(); f.dateStyle = .medium
                if let d = managed.transactionDate { return f.string(from: d) }
                return ""
            }()

            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title).font(.headline)
                    Text(dateStr).font(.subheadline).foregroundStyle(.secondary)
                }
                Spacer()
                Text(formatCurrency(managed.amount)).font(.headline)
            }
            .frame(maxWidth: .infinity)
        } else {
            EmptyView()
        }
    }

    private func reloadRows() {
        // If no budget is active for the selected period, ensure rows are
        // cleared so presets/expenses from other periods don't appear.
        guard let summary = activeSummary else {
            plannedRows = []
            variableRows = []
            return
        }
        let context = CoreDataService.shared.viewContext
        guard let budget = try? context.existingObject(with: summary.id) as? Budget else {
            // If the budget isn't resolvable yet, keep current rows.
            return
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

    // MARK: Delete Confirmation
    private var plannedDeletionDialogBinding: Binding<Bool> {
        Binding(
            get: { plannedDeletionBox != nil },
            set: { if !$0 { plannedDeletionBox = nil } }
        )
    }

    private var unplannedDeletionDialogBinding: Binding<Bool> {
        Binding(
            get: { unplannedDeletionBox != nil },
            set: { if !$0 { unplannedDeletionBox = nil } }
        )
    }

    private func plannedDeletionDialogTitle() -> String {
        if let name = plannedDeletionDisplayName() {
            return "Delete \"\(name)\"?"
        }
        return "Delete Planned Expense?"
    }

    private func plannedDeletionDialogMessage() -> String {
        if let name = plannedDeletionDisplayName() {
            return "This will remove \"\(name)\" from planned expenses."
        }
        return "This will remove this planned expense from the budget."
    }

    private func unplannedDeletionDialogTitle() -> String {
        if let name = unplannedDeletionDisplayName() {
            return "Delete \"\(name)\"?"
        }
        return "Delete Variable Expense?"
    }

    private func unplannedDeletionDialogMessage() -> String {
        if let name = unplannedDeletionDisplayName() {
            return "This will remove \"\(name)\" from variable expenses."
        }
        return "This will remove this variable expense from the budget."
    }

    private func plannedDeletionDisplayName() -> String? {
        guard let box = plannedDeletionBox else { return nil }
        let ctx = CoreDataService.shared.viewContext
        guard let object = try? ctx.existingObject(with: box.id) as? PlannedExpense else { return nil }
        return sanitizedExpenseName(readPlannedDescription(object))
    }

    private func unplannedDeletionDisplayName() -> String? {
        guard let box = unplannedDeletionBox else { return nil }
        let ctx = CoreDataService.shared.viewContext
        guard let object = try? ctx.existingObject(with: box.id) as? UnplannedExpense else { return nil }
        return sanitizedExpenseName(readUnplannedDescription(object))
    }

    private func sanitizedExpenseName(_ raw: String?) -> String? {
        guard let raw else { return nil }
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    private func requestDelete(planned exp: PlannedExpense) {
        if confirmBeforeDelete {
            plannedDeletionBox = ObjectIDBox(id: exp.objectID)
            unplannedDeletionBox = nil
        } else {
            delete(planned: exp)
        }
    }

    private func requestDelete(unplanned exp: UnplannedExpense) {
        if confirmBeforeDelete {
            unplannedDeletionBox = ObjectIDBox(id: exp.objectID)
            plannedDeletionBox = nil
        } else {
            delete(unplanned: exp)
        }
    }

    private func confirmPlannedDeletion() {
        guard let box = plannedDeletionBox else { return }
        plannedDeletionBox = nil
        let ctx = CoreDataService.shared.viewContext
        if let resolved = try? ctx.existingObject(with: box.id) as? PlannedExpense {
            delete(planned: resolved)
        }
    }

    private func confirmUnplannedDeletion() {
        guard let box = unplannedDeletionBox else { return }
        unplannedDeletionBox = nil
        let ctx = CoreDataService.shared.viewContext
        if let resolved = try? ctx.existingObject(with: box.id) as? UnplannedExpense {
            delete(unplanned: resolved)
        }
    }

    private func delete(planned: PlannedExpense) {
        let ctx = CoreDataService.shared.viewContext
        let id = planned.objectID
        if let obj = try? ctx.existingObject(with: id) as? PlannedExpense, !obj.isDeleted {
            do {
                try PlannedExpenseService().delete(obj)
                reloadRows()
                Task { await vm.refresh() }
            } catch { /* swallow for now */ }
        }
    }

    private func delete(unplanned: UnplannedExpense) {
        let ctx = CoreDataService.shared.viewContext
        let id = unplanned.objectID
        if let obj = try? ctx.existingObject(with: id) as? UnplannedExpense, !obj.isDeleted {
            do {
                try UnplannedExpenseService().delete(obj)
                reloadRows()
                Task { await vm.refresh() }
            } catch { /* swallow for now */ }
        }
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

    /// Reads `descriptionText` or `title` from a `PlannedExpense`, matching the service's behavior.
    private func readPlannedDescription(_ object: NSManagedObject) -> String? {
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

// MARK: - Chip Menu Overlay Builder (extracted for type-check performance)
private extension HomeView {
    func currentAmountForChip(_ cat: BudgetSummary.CategorySpending) -> Double {
        if segment == .variable {
            return cat.amount
        }
        // Planned: use Actual Amount sum for this category within the selected period and budget
        guard
            let summary = activeSummary,
            let budget = try? moc.existingObject(with: summary.id) as? Budget,
            let categoryID = CoreDataService.shared.container.persistentStoreCoordinator.managedObjectID(forURIRepresentation: cat.categoryURI),
            let category = try? moc.existingObject(with: categoryID) as? ExpenseCategory
        else { return cat.amount }

        let (start, end) = budgetPeriod.range(containing: vm.selectedDate)
        let req = NSFetchRequest<PlannedExpense>(entityName: "PlannedExpense")
        req.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
            NSPredicate(format: "budget == %@", budget),
            NSPredicate(format: "expenseCategory == %@", category),
            NSPredicate(format: "transactionDate >= %@ AND transactionDate <= %@", start as NSDate, end as NSDate)
        ])
        do {
            let items = try moc.fetch(req)
            return items.reduce(0.0) { $0 + $1.actualAmount }
        } catch {
            return cat.amount
        }
    }
    @ViewBuilder
    func chipMenuOverlay(_ anchors: [URL: Anchor<CGRect>]) -> some View {
        GeometryReader { proxy in
            ZStack {
                if chipMenuVisible, let cat = chipMenuSelected {
                    let containerSize = proxy.size
                    let insets: EdgeInsets = {
                        if #available(iOS 15.0, macCatalyst 15.0, *) {
                            return proxy.safeAreaInsets
                        } else {
                            return EdgeInsets()
                        }
                    }()
                    let anchor = anchors[cat.categoryURI]
                    let rect = anchor.map { proxy[$0] }
                    let edgePad: CGFloat = 16
                    let visualOutset: CGFloat = 10
                    let verticalOffset: CGFloat = 8
                    let menuW = max(chipMenuSize.width, 220)
                    let menuH = max(chipMenuSize.height, 72)
                    let proposedX = rect?.midX ?? containerSize.width/2
                    let minCenterX = insets.leading + edgePad + (menuW/2) + visualOutset
                    let maxCenterX = containerSize.width - insets.trailing - edgePad - (menuW/2) - visualOutset
                    let centerX = min(max(proposedX, minCenterX), maxCenterX)
                    let belowCenterY = (rect?.maxY ?? (insets.top + 44)) + verticalOffset + menuH/2
                    let aboveCenterY = (rect?.minY ?? (insets.top + 44)) - verticalOffset - menuH/2
                    let minCenterY = insets.top + edgePad + (menuH/2)
                    let maxCenterY = containerSize.height - insets.bottom - edgePad - (menuH/2)
                    let fitsBelow = belowCenterY + menuH/2 <= maxCenterY
                    let rawCenterY = fitsBelow ? belowCenterY : aboveCenterY
                    let centerY = min(max(rawCenterY, minCenterY), maxCenterY)

                    // Tap-outside to dismiss
                    Color.black.opacity(0.001)
                        .ignoresSafeArea()
                        .contentShape(Rectangle())
                        .onTapGesture { dismissChipMenu() }

                    VStack(alignment: .leading, spacing: 12) {
                        // Inline nav controls (glass on iOS 26, plain text on legacy)
                        HStack(spacing: 10) {
                            menuHeaderButton(title: chipMenuMode == .edit ? "Cancel" : "Close") {
                                if chipMenuMode == .edit { chipMenuMode = .preview } else { dismissChipMenu() }
                            }
                            Spacer(minLength: 10)
                            if chipMenuMode == .edit {
                                let saveDisabled = {
                                    let minVal = chipParseDecimal(chipEditMinInput)
                                    let maxVal = chipParseDecimal(chipEditMaxInput)
                                    guard let a = minVal, let b = maxVal else { return true }
                                    return a > b
                                }()
                                menuHeaderButton(title: "Save", disabled: saveDisabled) { saveChipMenuCaps(for: cat) }
                                menuHeaderDestructiveButton(title: "Clear") { clearChipMenuCaps(for: cat) }
                            } else {
                                menuHeaderButton(title: "Edit") {
                                    chipEditMinInput = chipPlainDecimalString(chipCapMin)
                                    chipEditMaxInput = chipPlainDecimalString(chipCapMax)
                                    chipMenuMode = .edit
                                }
                            }
                        }

                        if chipMenuMode == .edit {
                            HStack(spacing: 12) {
                                VStack(alignment: .leading, spacing: 6) {
                                    Text("Minimum")
                                        .font(.footnote.weight(.semibold))
                                        .foregroundStyle(.secondary)
                                    menuGlassTextField(text: $chipEditMinInput, placeholder: "0.00")
                                }
                                VStack(alignment: .leading, spacing: 6) {
                                    Text("Maximum")
                                        .font(.footnote.weight(.semibold))
                                        .foregroundStyle(.secondary)
                                    menuGlassTextField(text: $chipEditMaxInput, placeholder: "0.00")
                                }
                            }
                            Group {
                                if let error = chipValidationError {
                                    Text(error)
                                        .font(.footnote)
                                        .foregroundColor(.red)
                                }
                            }
                            .onChange(of: chipEditMinInput) { _ in chipValidationError = nil }
                            .onChange(of: chipEditMaxInput) { _ in chipValidationError = nil }
                        } else {
                            // Gauge preview
                            let current = currentAmountForChip(cat)
                            let lower = min(chipCapMin, chipCapMax)
                            let upper = max(max(chipCapMin, chipCapMax), max(current, 1))
                            let maxUnset = (segment == .variable) && !chipHasExplicitMaxCap
                            let exceeded = (!maxUnset) && (current > chipCapMax)
                            let maxLabelString = maxUnset ? "—" : formatCurrency(upper)
                            Gauge(value: min(max(current, lower), upper), in: lower...upper) {
                            } currentValueLabel: {
                                EmptyView()
                            } minimumValueLabel: {
                                Text(formatCurrency(lower)).foregroundStyle(Color.secondary)
                            } maximumValueLabel: {
                                Text(maxLabelString).foregroundStyle(exceeded ? Color.red : Color.secondary)
                            }
                            .tint(
                                LinearGradient(
                                    colors: [
                                        (UBColorFromHex(cat.hexColor) ?? .accentColor).opacity(0.35),
                                        (UBColorFromHex(cat.hexColor) ?? .accentColor)
                                    ],
                                    startPoint: .leading, endPoint: .trailing
                                )
                            )

                            HStack {
                                Text("Current: \(formatCurrency(current))")
                                    .foregroundStyle(.secondary)
                                Spacer()
                                Text("Range: \(formatCurrency(lower)) – \(maxLabelString)")
                                    .foregroundStyle(.secondary)
                            }
                            .font(.footnote)
                            if maxUnset {
                                Text("No max set")
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .padding(14)
                    .background(
                        GeometryReader { g in
                            Color.clear
                                .onAppear { chipMenuSize = g.size }
                                .onChange(of: g.size) { newSize in
                                    if abs((chipMenuSize.width - newSize.width)) > 0.5 || abs((chipMenuSize.height - newSize.height)) > 0.5 {
                                        chipMenuSize = newSize
                                    }
                                }
                        }
                    )
                    .frame(
                        minWidth: 220,
                        maxWidth: max(220, containerSize.width - (insets.leading + insets.trailing) - 2*edgePad - 2*visualOutset)
                    )
                    .modifier(MenuGlassOrLegacyBackground(cornerRadius: 12))
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .shadow(color: .black.opacity(0.15), radius: 10, x: 0, y: 4)
                    .position(x: centerX, y: centerY)
                    .transition(.scale.combined(with: .opacity))
                    .animation(.spring(response: 0.35, dampingFraction: 0.85), value: chipMenuVisible)
                    .onAppear { reloadChipMenuCaps(for: cat) }
                    .onChange(of: budgetPeriodRawValue) { _ in reloadChipMenuCaps(for: cat) }
                    .onChange(of: vm.selectedDate) { _ in reloadChipMenuCaps(for: cat) }
                    .onChange(of: segment) { _ in reloadChipMenuCaps(for: cat, resetAmount: true) }
                }
            }
        }
    }
}

// MARK: - Inline Menu Controls (Glass buttons + glass fields)
private extension HomeView {
    @ViewBuilder
    func menuHeaderButton(title: String, disabled: Bool = false, action: @escaping () -> Void) -> some View {
        if #available(iOS 26.0, macCatalyst 26.0, macOS 26.0, *) {
            Button(action: action) {
                Text(title)
                    .font(.footnote.weight(.semibold))
                    .padding(.horizontal, 14)
                    .frame(height: 33)
                    .fixedSize(horizontal: true, vertical: false)
                    .glassEffect(.regular.tint(.clear).interactive(true), in: .capsule)
                    .contentShape(Capsule())
            }
            .buttonStyle(.plain)
            .opacity(disabled ? 0.5 : 1)
            .disabled(disabled)
        } else {
            Button(title, action: action)
                .buttonStyle(.plain)
                .font(.footnote.weight(.semibold))
                .padding(.horizontal, 14)
                .frame(height: 33)
                .fixedSize(horizontal: true, vertical: false)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(Color(UIColor { traits in
                            traits.userInterfaceStyle == .dark ? UIColor(white: 0.22, alpha: 1) : UIColor(white: 0.9, alpha: 1)
                        }))
                )
                .contentShape(RoundedRectangle(cornerRadius: 16))
                .opacity(disabled ? 0.5 : 1)
                .disabled(disabled)
        }
    }

    @ViewBuilder
    func menuGlassTextField(text: Binding<String>, placeholder: String) -> some View {
        if #available(iOS 26.0, macCatalyst 26.0, macOS 26.0, *) {
            TextField(placeholder, text: text)
                .textFieldStyle(.plain)
                .keyboardType(.decimalPad)
                .padding(.horizontal, 10)
                .frame(height: 32)
                .background(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(Color.clear)
                        .glassEffect(.regular.tint(.clear).interactive(true), in: .rect(cornerRadius: 8))
                )
        } else {
            TextField(placeholder, text: text)
                .keyboardType(.decimalPad)
                .textFieldStyle(.roundedBorder)
        }
    }

    @ViewBuilder
    func menuHeaderDestructiveButton(title: String, action: @escaping () -> Void) -> some View {
        if #available(iOS 26.0, macCatalyst 26.0, macOS 26.0, *) {
            Button(action: action) {
                Text(title)
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.red)
                    .padding(.horizontal, 14)
                    .frame(height: 33)
                    .fixedSize(horizontal: true, vertical: false)
                    .glassEffect(.regular.tint(.clear).interactive(true), in: .capsule)
                    .contentShape(Capsule())
            }
            .buttonStyle(.plain)
        } else {
            Button(action: action) {
                Text(title)
                    .font(.footnote.weight(.semibold))
                    .foregroundColor(.red)
                    .padding(.horizontal, 14)
                    .frame(height: 33)
                    .fixedSize(horizontal: true, vertical: false)
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(Color(UIColor { traits in
                                traits.userInterfaceStyle == .dark ? UIColor(white: 0.22, alpha: 1) : UIColor(white: 0.9, alpha: 1)
                            }))
                    )
                    .contentShape(RoundedRectangle(cornerRadius: 16))
            }
            .buttonStyle(.plain)
        }
    }
}
// MARK: - Chip Anchor Preference
private struct ChipFramePreferenceKey: PreferenceKey {
    static var defaultValue: [URL: Anchor<CGRect>] = [:]
    static func reduce(value: inout [URL: Anchor<CGRect>], nextValue: () -> [URL: Anchor<CGRect>]) {
        value.merge(nextValue()) { _, rhs in rhs }
    }
}

// MARK: - Menu Background (Glass on iOS26; fallback legacy)
private struct MenuGlassOrLegacyBackground: ViewModifier {
    var cornerRadius: CGFloat = 12

    func body(content: Content) -> some View {
        if #available(iOS 26.0, macCatalyst 26.0, macOS 26.0, *) {
            content
                .glassEffect(.regular.tint(.clear).interactive(true), in: .rect(cornerRadius: cornerRadius))
        } else {
            content
                .background(
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(Color(UIColor { traits in
                            traits.userInterfaceStyle == .dark ? UIColor(white: 0.16, alpha: 1) : UIColor(white: 0.97, alpha: 1)
                        }))
                )
        }
    }
}

// MARK: - Chip Menu Helpers
private extension HomeView {
    func presentChipMenu(for cat: BudgetSummary.CategorySpending) {
        chipMenuSelected = cat
        chipMenuMode = .preview
        withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
            chipMenuVisible = true
        }
        #if canImport(UIKit)
        UIImpactFeedbackGenerator(style: .soft).impactOccurred()
        #endif
    }

    func dismissChipMenu() {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
            chipMenuVisible = false
        }
        // Slight delay to avoid race with overlayPreference remove
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            if !chipMenuVisible { chipMenuSelected = nil }
        }
    }
}

// MARK: - Caps Loading for Inline Menu (Step 3)
private extension HomeView {
    func reloadChipMenuCaps(for cat: BudgetSummary.CategorySpending, resetAmount: Bool = false) {
        // Optionally refresh the displayed amount if the segment changed
        if resetAmount {
            let fresh = (segment == .planned ? activeSummary?.plannedCategoryBreakdown : activeSummary?.variableCategoryBreakdown)?.first { $0.categoryURI == cat.categoryURI }
            if let fresh { chipMenuSelected = fresh }
        }

        // Resolve category object ID
        guard let objectID = CoreDataService.shared.container.persistentStoreCoordinator.managedObjectID(forURIRepresentation: cat.categoryURI),
              let category = try? moc.existingObject(with: objectID) as? ExpenseCategory else {
            // Fallback: set caps to a sensible default around the current value
            let current = (segment == .planned ? currentAmountForChip(cat) : (chipMenuSelected?.amount ?? cat.amount))
            chipCapMin = 0
            chipCapMax = max(current + 1, 1)
            chipHasExplicitMinCap = false
            chipHasExplicitMaxCap = false
            return
        }

        let key = periodKey(for: budgetPeriod, date: vm.selectedDate, segment: segment)
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
                let type = (r.value(forKey: "expenseType") as? String)?.lowercased()
                if type == "min" { minVal = r.value(forKey: "amount") as? Double }
                if type == "max" { maxVal = r.value(forKey: "amount") as? Double }
            }
            let current = (segment == .planned ? currentAmountForChip(cat) : (chipMenuSelected?.amount ?? cat.amount))
            chipCapMin = minVal ?? 0
            // If no explicit max and we're on Variable segment, do not assume cap equals current.
            // Provide a neutral headroom for gauge display but mark as unset.
            if let m = maxVal {
                chipCapMax = m
                chipHasExplicitMaxCap = true
            } else {
                chipCapMax = max(current + 1, 1)
                chipHasExplicitMaxCap = false
            }
            chipHasExplicitMinCap = (minVal != nil)
        } catch {
            let current = (segment == .planned ? currentAmountForChip(cat) : (chipMenuSelected?.amount ?? cat.amount))
            chipCapMin = 0
            chipCapMax = max(current + 1, 1)
            chipHasExplicitMinCap = false
            chipHasExplicitMaxCap = false
        }
    }

    func periodKey(for period: BudgetPeriod, date: Date, segment: Segment) -> String {
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
}

// MARK: - Save Caps for Inline Menu (Step 4)
private extension HomeView {
    func saveChipMenuCaps(for cat: BudgetSummary.CategorySpending) {
        guard let newMin = chipParseDecimal(chipEditMinInput), let newMax = chipParseDecimal(chipEditMaxInput) else {
            chipValidationError = "Enter valid numbers for Min and Max."
            #if canImport(UIKit)
            UINotificationFeedbackGenerator().notificationOccurred(.error)
            #endif
            return
        }
        guard newMin <= newMax else {
            chipValidationError = "Minimum must be less than or equal to Maximum."
            #if canImport(UIKit)
            UINotificationFeedbackGenerator().notificationOccurred(.error)
            #endif
            return
        }

        guard let objectID = CoreDataService.shared.container.persistentStoreCoordinator.managedObjectID(forURIRepresentation: cat.categoryURI),
              let category = try? moc.existingObject(with: objectID) as? ExpenseCategory else {
            #if canImport(UIKit)
            UINotificationFeedbackGenerator().notificationOccurred(.error)
            #endif
            return
        }

        let key = periodKey(for: budgetPeriod, date: vm.selectedDate, segment: segment)
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
            chipCapMin = newMin
            chipCapMax = newMax
            chipMenuMode = .preview
            chipHasExplicitMinCap = true
            chipHasExplicitMaxCap = true
            chipValidationError = nil
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

    func clearChipMenuCaps(for cat: BudgetSummary.CategorySpending) {
        guard let objectID = CoreDataService.shared.container.persistentStoreCoordinator.managedObjectID(forURIRepresentation: cat.categoryURI),
              let category = try? moc.existingObject(with: objectID) as? ExpenseCategory else {
            #if canImport(UIKit)
            UINotificationFeedbackGenerator().notificationOccurred(.error)
            #endif
            return
        }

        let key = periodKey(for: budgetPeriod, date: vm.selectedDate, segment: segment)
        let fetch = NSFetchRequest<CategorySpendingCap>(entityName: "CategorySpendingCap")
        fetch.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
            NSPredicate(format: "category == %@", category),
            NSPredicate(format: "period == %@", key),
            NSPredicate(format: "expenseType IN %@", ["min", "max"])
        ])
        do {
            let results = try moc.fetch(fetch)
            for r in results { moc.delete(r) }
            try moc.save()

            let current = chipMenuSelected?.amount ?? cat.amount
            chipCapMin = 0
            chipCapMax = max(current + 1, 1)
            chipHasExplicitMinCap = false
            chipHasExplicitMaxCap = false
            chipMenuMode = .preview
            chipValidationError = nil
            #if canImport(UIKit)
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            #endif
        } catch {
            AppLog.ui.error("Failed to clear caps: \(error.localizedDescription)")
            #if canImport(UIKit)
            UINotificationFeedbackGenerator().notificationOccurred(.error)
            #endif
        }
    }

    func chipPlainDecimalString(_ value: Double) -> String {
        let nf = NumberFormatter()
        nf.numberStyle = .decimal
        nf.maximumFractionDigits = 2
        nf.minimumFractionDigits = 0
        return nf.string(from: value as NSNumber) ?? String(format: "%.2f", value)
    }

    func chipParseDecimal(_ text: String) -> Double? {
        let nf = NumberFormatter()
        nf.numberStyle = .decimal
        nf.maximumFractionDigits = 2
        nf.minimumFractionDigits = 0
        if let n = nf.number(from: text.trimmingCharacters(in: .whitespacesAndNewlines)) {
            return n.doubleValue
        }
        let sanitized = text.replacingOccurrences(of: ",", with: ".").replacingOccurrences(of: " ", with: "")
        return Double(sanitized)
    }
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
                    .glassEffect(.regular.tint(.clear).interactive(true))
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
                let categories = (segment == .planned ? activeSummary?.plannedCategoryBreakdown : activeSummary?.variableCategoryBreakdown) ?? []
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

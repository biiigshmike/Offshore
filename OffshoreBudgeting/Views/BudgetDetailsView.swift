import SwiftUI
import CoreData

@MainActor
struct BudgetDetailsView: View {
    private struct ObjectIDBox: Identifiable { let id: NSManagedObjectID }

    let budgetID: NSManagedObjectID
    @StateObject private var vm: BudgetDetailsViewModel

    @State private var segment: BudgetDetailsViewModel.Segment = .planned
    @State private var sort: BudgetDetailsViewModel.SortOption = .dateNewOld
    @State private var selectedCategoryURI: URL? = nil

    @State private var isPresentingAddPlanned = false
    @State private var isPresentingAddVariable = false
    @State private var isPresentingManageCards = false
    @State private var isPresentingManagePresets = false
    @State private var editingBudgetBox: ObjectIDBox?
    @State private var editingPlannedBox: ObjectIDBox?
    @State private var editingUnplannedBox: ObjectIDBox?
    @State private var capGaugeData: CapGaugeData?

    init(budgetID: NSManagedObjectID, store: BudgetDetailsViewModelStore? = nil) {
        self.budgetID = budgetID
        let resolvedStore = store ?? BudgetDetailsViewModelStore.shared
        _vm = StateObject(wrappedValue: resolvedStore.viewModel(for: budgetID))
    }

    var body: some View {
        List {
            Section { summaryCard }
            Section { segmentRow }
            Section { sortRow }
            Section { categoryChipsRow }
            Section { rowsSection }
        }
        .listStyle(.insetGrouped)
        .navigationTitle(vm.budget?.name ?? "Budget")
        .task {
            await vm.load()
            segment = vm.selectedSegment
            sort = vm.sort
        }
        .refreshable { await vm.refreshRows() }
        .onChange(of: segment) { vm.selectedSegment = $0 }
        .onChange(of: sort) { vm.sort = $0 }
        .sheet(isPresented: $isPresentingAddPlanned) { addPlannedSheet }
        .sheet(isPresented: $isPresentingAddVariable) { addVariableSheet }
        .sheet(isPresented: $isPresentingManageCards) { manageCardsSheet }
        .sheet(isPresented: $isPresentingManagePresets) { managePresetsSheet }
        .sheet(item: $editingBudgetBox) { box in
            AddBudgetView(
                editingBudgetObjectID: box.id,
                fallbackStartDate: vm.startDate,
                fallbackEndDate: vm.endDate
            ) { Task { await vm.load() } }
        }
        .sheet(item: $editingPlannedBox) { box in
            AddPlannedExpenseView(plannedExpenseID: box.id, onSaved: { Task { await vm.refreshRows() } })
                .environment(\.managedObjectContext, CoreDataService.shared.viewContext)
        }
        .sheet(item: $editingUnplannedBox) { box in
            AddUnplannedExpenseView(unplannedExpenseID: box.id, onSaved: { Task { await vm.refreshRows() } })
                .environment(\.managedObjectContext, CoreDataService.shared.viewContext)
        }
        .sheet(item: $capGaugeData) { data in
            CategoryCapGaugeSheet(data: data) { capGaugeData = nil }
        }
        .toolbar { toolbarContent }
    }

    @ViewBuilder
    private var summaryCard: some View {
        switch vm.loadState {
        case .loading, .idle:
            ProgressView("Loading budget…")
                .frame(maxWidth: .infinity, alignment: .leading)
        case .failed(let message):
            Text(message)
                .foregroundStyle(.secondary)
        case .loaded:
            if let summary = vm.summary {
                VStack(alignment: .leading, spacing: 8) {
                    Text(summary.budgetName)
                        .font(.title2.weight(.semibold))
                    Text(dateFormatter.string(from: summary.periodStart, to: summary.periodEnd))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    HStack(alignment: .lastTextBaseline, spacing: 16) {
                        summaryMetric(title: "PLANNED", value: summary.plannedExpensesPlannedTotal)
                        summaryMetric(title: "ACTUAL", value: summary.plannedExpensesActualTotal)
                        summaryMetric(title: "VARIABLE", value: summary.variableExpensesTotal)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                Text("Budget unavailable")
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var segmentRow: some View {
        BudgetExpenseSegmentedControl(
            plannedSegment: BudgetDetailsViewModel.Segment.planned,
            variableSegment: BudgetDetailsViewModel.Segment.variable,
            selection: $segment
        )
        .padding(.vertical, 4)
        .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16))
    }

    private var sortRow: some View {
        BudgetSortBar(
            selection: $sort,
            options: [
                (.titleAZ, "A–Z"),
                (.amountLowHigh, "$↓"),
                (.amountHighLow, "$↑"),
                (.dateOldNew, "Date ↑"),
                (.dateNewOld, "Date ↓")
            ]
        )
        .padding(.vertical, 4)
        .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16))
    }

    @ViewBuilder
    private var rowsSection: some View {
        if let budget = vm.budget {
            if segment == .planned {
                PlannedRowsList(
                    budget: budget,
                    start: vm.startDate,
                    end: vm.endDate,
                    sortDescriptors: PlannedRowsList.sortDescriptors(for: sort),
                    horizontalPadding: 16,
                    selectedCategoryURI: selectedCategoryURI,
                    confirmBeforeDelete: true,
                    onEdit: { editingPlannedBox = ObjectIDBox(id: $0) },
                    onDelete: { _ in Task { await vm.refreshRows() } }
                )
            } else {
                VariableRowsList(
                    budget: budget,
                    start: vm.startDate,
                    end: vm.endDate,
                    sortDescriptors: VariableRowsList.sortDescriptors(for: sort),
                    horizontalPadding: 16,
                    selectedCategoryURI: selectedCategoryURI,
                    confirmBeforeDelete: true,
                    onEdit: { editingUnplannedBox = ObjectIDBox(id: $0) },
                    onDelete: { _ in Task { await vm.refreshRows() } }
                )
            }
        } else {
            Text(vm.placeholderText)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .center)
        }
    }

    private var categoryChipsRow: some View {
        let categories: [BudgetSummary.CategorySpending] = {
            if let summary = vm.summary {
                return segment == .planned ? summary.plannedCategoryBreakdown : summary.variableCategoryBreakdown
            }
            let req = NSFetchRequest<ExpenseCategory>(entityName: "ExpenseCategory")
            req.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true, selector: #selector(NSString.localizedCaseInsensitiveCompare(_:)))]
            let items: [ExpenseCategory] = (try? CoreDataService.shared.viewContext.fetch(req)) ?? []
            return items.map {
                let name = ($0.name ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
                return BudgetSummary.CategorySpending(categoryURI: $0.objectID.uriRepresentation(), categoryName: name, hexColor: $0.color, amount: 0)
            }
        }()

        return ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(categories) { cat in
                    let isSelected = (selectedCategoryURI == cat.categoryURI)
                    BudgetCategoryChipView(
                        title: cat.categoryName,
                        amount: cat.amount,
                        hex: cat.hexColor,
                        isSelected: isSelected,
                        isExceeded: false,
                        onTap: {
                            selectedCategoryURI = isSelected ? nil : cat.categoryURI
                        }
                    )
                    .simultaneousGesture(
                        LongPressGesture(minimumDuration: 0.35)
                            .onEnded { _ in presentCapGauge(for: cat) }
                    )
                }
                if categories.isEmpty {
                    Text("No categories yet")
                        .foregroundStyle(.secondary)
                        .padding(.vertical, 8)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(height: 44)
        .padding(.vertical, 2)
        .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16))
    }

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItemGroup(placement: .navigationBarTrailing) {
            Menu {
                Button("Add Planned Expense") { isPresentingAddPlanned = true }
                Button("Add Variable Expense") { isPresentingAddVariable = true }
                Button("Manage Cards") { isPresentingManageCards = true }
                Button("Manage Presets") { isPresentingManagePresets = true }
                if let budget = vm.budget { Button("Edit Budget") { editingBudgetBox = ObjectIDBox(id: budget.objectID) } }
            } label: {
                Image(systemName: "plus")
            }
        }
    }

    private func summaryMetric(title: String, value: Double) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            Text(currencyFormatter.string(from: value as NSNumber) ?? "--")
                .font(.headline)
        }
    }

    private var dateFormatter: DateIntervalFormatter {
        let formatter = DateIntervalFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }

    private var currencyFormatter: NumberFormatter {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        if #available(iOS 16.0, macCatalyst 16.0, *) {
            formatter.currencyCode = Locale.current.currency?.identifier ?? "USD"
        } else {
            let locale = Locale.current as NSLocale
            formatter.currencyCode = (locale.object(forKey: .currencyCode) as? String) ?? "USD"
        }
        return formatter
    }

    private var addPlannedSheet: some View {
        AddPlannedExpenseView(
            preselectedBudgetID: vm.budget?.objectID,
            defaultSaveAsGlobalPreset: false,
            showAssignBudgetToggle: true,
            onSaved: { Task { await vm.refreshRows() } }
        )
        .environment(\.managedObjectContext, CoreDataService.shared.viewContext)
    }

    private var addVariableSheet: some View {
        AddUnplannedExpenseView(
            allowedCardIDs: nil,
            initialDate: vm.startDate,
            onSaved: { Task { await vm.refreshRows() } }
        )
        .environment(\.managedObjectContext, CoreDataService.shared.viewContext)
    }

    private var manageCardsSheet: some View {
        Group {
            if let budget = vm.budget {
                ManageBudgetCardsSheet(budget: budget) { Task { await vm.refreshRows() } }
            } else {
                Text("No budget selected")
            }
        }
        .environment(\.managedObjectContext, CoreDataService.shared.viewContext)
    }

    private var managePresetsSheet: some View {
        Group {
            if let budget = vm.budget {
                ManageBudgetPresetsSheet(budget: budget) { Task { await vm.refreshRows() } }
            } else {
                Text("No budget selected")
            }
        }
        .environment(\.managedObjectContext, CoreDataService.shared.viewContext)
    }

    // MARK: - Cap Gauge (long-press on category chip)
    struct CapGaugeData: Identifiable {
        let id = UUID()
        let category: BudgetSummary.CategorySpending
        let minCap: Double
        let maxCap: Double?
        let current: Double
        let color: Color
        let hasExplicitMax: Bool
    }

    private func presentCapGauge(for cat: BudgetSummary.CategorySpending) {
        let coordinator = CoreDataService.shared.container.persistentStoreCoordinator
        guard cat.categoryURI.scheme == "x-coredata",
              let catID = coordinator.managedObjectID(forURIRepresentation: cat.categoryURI),
              let category = try? CoreDataService.shared.viewContext.existingObject(with: catID) as? ExpenseCategory
        else {
            capGaugeData = CapGaugeData(category: cat, minCap: 0, maxCap: nil, current: cat.amount, color: UBColorFromHex(cat.hexColor) ?? .accentColor, hasExplicitMax: false)
            return
        }

        let key = periodKey(start: vm.startDate, end: vm.endDate, segment: segment)
        let fetch = NSFetchRequest<CategorySpendingCap>(entityName: "CategorySpendingCap")
        fetch.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
            NSPredicate(format: "category == %@", category),
            NSPredicate(format: "period == %@", key),
            NSPredicate(format: "expenseType IN %@", ["min", "max"])
        ])

        var minCap: Double = 0
        var maxCap: Double? = nil
        do {
            let results = try CoreDataService.shared.viewContext.fetch(fetch)
            for r in results {
                let type = (r.value(forKey: "expenseType") as? String)?.lowercased()
                if type == "min" {
                    if let amt = r.value(forKey: "amount") as? Double { minCap = amt }
                }
                if type == "max" {
                    if let amt = r.value(forKey: "amount") as? Double { maxCap = amt }
                }
            }
        } catch {
            // Fall back to defaults on fetch failure
        }

        let color = UBColorFromHex(cat.hexColor) ?? .accentColor
        capGaugeData = CapGaugeData(
            category: cat,
            minCap: minCap,
            maxCap: maxCap,
            current: cat.amount,
            color: color,
            hasExplicitMax: (maxCap != nil)
        )
    }

    private func periodKey(start: Date, end: Date, segment: BudgetDetailsViewModel.Segment) -> String {
        let f = DateFormatter()
        f.calendar = Calendar(identifier: .gregorian)
        f.locale = Locale(identifier: "en_US_POSIX")
        f.timeZone = TimeZone(secondsFromGMT: 0)
        f.dateFormat = "yyyy-MM-dd"
        let s = f.string(from: start)
        let e = f.string(from: end)
        return "\(s)|\(e)|\(segment.rawValue)"
    }

// MARK: - Cap Gauge Sheet
    private struct CategoryCapGaugeSheet: View {
        let data: BudgetDetailsView.CapGaugeData
        let onDismiss: () -> Void

        private var maxValue: Double {
            data.maxCap ?? max(data.current + 1, 1)
        }
        private var lowerBound: Double { data.minCap }
        private var upperBound: Double { max(maxValue, lowerBound) }
        private var maxLabelString: String {
            data.hasExplicitMax ? formatCurrency(maxValue) : "—"
        }

        var body: some View {
            NavigationStack {
                VStack(alignment: .leading, spacing: 16) {
                    Gauge(
                        value: clamp(data.current, min: lowerBound, max: upperBound),
                        in: lowerBound...upperBound
                    ) {
                        EmptyView()
                    } currentValueLabel: {
                        Text(formatCurrency(data.current))
                    }
                    .tint(
                        LinearGradient(
                            colors: [data.color.opacity(0.35), data.color],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )

                    HStack {
                        Text(formatCurrency(lowerBound)).foregroundStyle(.secondary)
                        Spacer()
                        Text(maxLabelString)
                            .foregroundStyle(.secondary)
                            .opacity(data.hasExplicitMax ? 1 : 0.7)
                    }
                    .font(.footnote)

                    HStack {
                        Text("Current: \(formatCurrency(data.current))").foregroundStyle(.secondary)
                        Spacer()
                        Text("Range: \(formatCurrency(lowerBound)) – \(data.hasExplicitMax ? formatCurrency(maxValue) : "No max")")
                            .foregroundStyle(.secondary)
                    }
                    .font(.footnote)

                    if !data.hasExplicitMax {
                        Text("No max set for this category in this period.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()
                }
                .padding()
                .navigationTitle(data.category.categoryName)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Done", action: onDismiss)
                    }
                }
            }
        }
        
        private func formatCurrency(_ value: Double) -> String {
            let formatter = NumberFormatter()
            formatter.numberStyle = .currency
            if #available(iOS 16.0, macCatalyst 16.0, *) {
                formatter.currencyCode = Locale.current.currency?.identifier ?? "USD"
            } else {
                let locale = Locale.current as NSLocale
                formatter.currencyCode = (locale.object(forKey: .currencyCode) as? String) ?? "USD"
            }
            return formatter.string(from: value as NSNumber) ?? String(format: "%.2f", value)
        }
        
        private func clamp(_ value: Double, min: Double, max: Double) -> Double {
            Swift.max(min, Swift.min(value, max))
        }
    }
}

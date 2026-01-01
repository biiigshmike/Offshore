import SwiftUI
import CoreData

@MainActor
struct BudgetDetailsView: View {
    private struct ObjectIDBox: Identifiable { let id: NSManagedObjectID }

    let budgetID: NSManagedObjectID
    @StateObject private var vm: BudgetDetailsViewModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

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
    @State private var capOverrides: [String: (min: Double?, max: Double?)] = [:]
    @State private var isConfirmingDelete = false
    @State private var deleteErrorMessage: String?
    private let budgetService = BudgetService()

    init(budgetID: NSManagedObjectID, store: BudgetDetailsViewModelStore? = nil) {
        self.budgetID = budgetID
        let resolvedStore = store ?? BudgetDetailsViewModelStore.shared
        _vm = StateObject(wrappedValue: resolvedStore.viewModel(for: budgetID))
    }

    var body: some View {
        List {
            Section { summaryCard }
            if case .loaded = vm.loadState, let summary = vm.summary {
                Section { statRow(for: summary) }
                    .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16))
            }
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
            refreshCapOverrides()
        }
        .refreshable { await vm.refreshRows() }
        .onChange(of: segment) { vm.selectedSegment = $0 }
        .onChange(of: sort) { vm.sort = $0 }
        .onChange(of: segment) { _ in refreshCapOverrides() }
        .onChange(of: vm.startDate) { _ in refreshCapOverrides() }
        .onChange(of: vm.endDate) { _ in refreshCapOverrides() }
        .onChange(of: vm.loadState) { state in
            if case .loaded = state { refreshCapOverrides() }
        }
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
            CategoryCapGaugeSheet(
                data: data,
                onDismiss: { capGaugeData = nil },
                onSave: { min, max in await saveCaps(for: data, min: min, max: max) }
            )
        }
        .alert("Delete Budget?", isPresented: $isConfirmingDelete) {
            Button("Delete", role: .destructive) { deleteBudget() }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This action cannot be undone.")
        }
        .alert("Error", isPresented: Binding(get: { deleteErrorMessage != nil }, set: { if !$0 { deleteErrorMessage = nil } })) {
            Button("OK", role: .cancel) { deleteErrorMessage = nil }
        } message: {
            Text(deleteErrorMessage ?? "")
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
            req.predicate = WorkspaceService.shared.activeWorkspacePredicate()
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
                        isExceeded: isOverCap(category: cat, segment: segment),
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
        ToolbarItem(placement: .primaryAction) {
            toolbarActions
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

    @ViewBuilder
    private func statRow(for summary: BudgetSummary) -> some View {
        let projectedSavings = summary.potentialIncomeTotal - summary.plannedExpensesPlannedTotal - summary.variableExpensesTotal
        let maxSavings = summary.potentialIncomeTotal - summary.plannedExpensesPlannedTotal
        let expenseLabel = segment == .planned ? "Planned Expenses" : "Variable Expenses"
        let expenseValue = segment == .planned ? summary.plannedExpensesActualTotal : summary.variableExpensesTotal
        let cardBackground = Color(.systemBackground)
        let cardSpacing: CGFloat = 12
        let isRegularWidth = horizontalSizeClass == .regular || horizontalSizeClass == nil
        let columns = isRegularWidth
            ? Array(repeating: GridItem(.flexible(), spacing: cardSpacing), count: 4)
            : [GridItem(.adaptive(minimum: 150), spacing: cardSpacing)]

        LazyVGrid(columns: columns, alignment: .center, spacing: cardSpacing) {
            statCard(
                title: "Income",
                color: HomeView.HomePalette.income,
                items: [
                    StatItem(label: "Expected", value: currencyFormatter.string(from: summary.potentialIncomeTotal as NSNumber) ?? "--"),
                    StatItem(label: "Received", value: currencyFormatter.string(from: summary.actualIncomeTotal as NSNumber) ?? "--")
                ],
                background: cardBackground
            )
            statCard(
                title: "Projected Savings",
                color: HomeView.HomePalette.budgets,
                items: [
                    StatItem(label: "Projected", value: currencyFormatter.string(from: projectedSavings as NSNumber) ?? "--"),
                    StatItem(label: "Max Savings", value: currencyFormatter.string(from: maxSavings as NSNumber) ?? "--")
                ],
                background: cardBackground
            )
            statCard(
                title: "Actual Savings",
                color: .green,
                items: [
                    StatItem(label: "Actual", value: currencyFormatter.string(from: summary.actualSavingsTotal as NSNumber) ?? "--")
                ],
                background: cardBackground
            )
            statCard(
                title: expenseLabel,
                color: HomeView.HomePalette.cards,
                items: [
                    StatItem(label: segment == .planned ? "Planned (actual)" : "Variable", value: currencyFormatter.string(from: expenseValue as NSNumber) ?? "--")
                ],
                background: cardBackground
            )
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .center)
    }

    private struct StatItem {
        let label: String
        let value: String
    }

    private func statCard(title: String, color: Color, items: [StatItem], background: Color) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(color)
            ForEach(items.indices, id: \.self) { idx in
                VStack(alignment: .leading, spacing: 2) {
                    Text(items[idx].label)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(items[idx].value)
                        .font(.subheadline.weight(.semibold))
                }
            }
            Spacer(minLength: 0)
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 12)
        .frame(maxWidth: .infinity, minHeight: 110, alignment: .topLeading)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(background)
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(Color.secondary.opacity(0.15), lineWidth: 1)
                )
        )
        .multilineTextAlignment(.leading)
    }

    // MARK: Toolbar Actions
    private var toolbarActions: some View {
        HStack(spacing: 8) {
            Menu {
                Button("Add Planned Expense") { isPresentingAddPlanned = true }
                Button("Add Variable Expense") { isPresentingAddVariable = true }
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: 15, weight: .semibold))
                    .frame(width: 30, height: 30)
            }
            .iconButtonA11y(label: "Add", hint: "Shows add options.")

            Menu {
                Button("Manage Cards") { isPresentingManageCards = true }
                Button("Manage Presets") { isPresentingManagePresets = true }
                if let budget = vm.budget {
                    Button("Edit Budget") { editingBudgetBox = ObjectIDBox(id: budget.objectID) }
                }
                Button("Delete Budget", role: .destructive) { isConfirmingDelete = true }
            } label: {
                Image(systemName: "ellipsis")
                    .font(.system(size: 15, weight: .semibold))
                    .frame(width: 30, height: 30)
            }
            .iconButtonA11y(label: "Budget Actions", hint: "Shows budget options.")
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 10)
        .background(.clear)
        .clipShape(Capsule())
    }

    @ViewBuilder
    private var toolbarBackground: some View {
        if #available(iOS 26.0, macOS 15.0, macCatalyst 26.0, *) {
            Color.clear.glassEffect(.regular, in: .capsule)
        } else {
            Color(UIColor.secondarySystemBackground).opacity(0.9)
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

    private func deleteBudget() {
        guard let budget = vm.budget else { return }
        do {
            try budgetService.deleteBudget(budget)
            dismiss()
        } catch {
            // Simple fallback alert; could be expanded for user messaging.
            deleteErrorMessage = "Unable to delete budget."
        }
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
        let categoryObjectID: NSManagedObjectID?
        let periodKey: String
    }

    private func presentCapGauge(for cat: BudgetSummary.CategorySpending) {
        let key = periodKey(start: vm.startDate, end: vm.endDate, segment: segment)
        let context = CoreDataService.shared.viewContext
        let coordinator = CoreDataService.shared.container.persistentStoreCoordinator

        func resolvedCategory() -> (ExpenseCategory, NSManagedObjectID)? {
            if cat.categoryURI.scheme == "x-coredata",
               let catID = coordinator.managedObjectID(forURIRepresentation: cat.categoryURI),
               let category = try? context.existingObject(with: catID) as? ExpenseCategory {
                return (category, catID)
            }
            let name = cat.categoryName.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !name.isEmpty else { return nil }
            let fetch = NSFetchRequest<ExpenseCategory>(entityName: "ExpenseCategory")
            fetch.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
                NSPredicate(format: "name ==[cd] %@", name),
                WorkspaceService.shared.activeWorkspacePredicate()
            ])
            fetch.fetchLimit = 1
            if let category = try? context.fetch(fetch).first {
                return (category, category.objectID)
            }
            return nil
        }

        let defaults = defaultCaps(for: cat.categoryName, segment: segment)

        guard let (category, _) = resolvedCategory() else {
            capGaugeData = CapGaugeData(
                category: cat,
                minCap: defaults.min,
                maxCap: defaults.max,
                current: cat.amount,
                color: UBColorFromHex(cat.hexColor) ?? .accentColor,
                hasExplicitMax: defaults.max != nil,
                categoryObjectID: nil,
                periodKey: key
            )
            return
        }

        let fetch = NSFetchRequest<CategorySpendingCap>(entityName: "CategorySpendingCap")
        fetch.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
            NSPredicate(format: "category == %@", category),
            NSPredicate(format: "period == %@", key),
            NSPredicate(format: "expenseType IN %@", ["min", "max"])
        ])

        var minCap: Double = defaults.min
        var maxCap: Double? = defaults.max
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
            hasExplicitMax: (maxCap != nil),
            categoryObjectID: category.objectID,
            periodKey: key
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

    private func normalizedCategoryName(_ name: String) -> String {
        name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }

    private var plannedPlannedCapTotals: [String: Double] {
        vm.plannedExpenses.reduce(into: [:]) { dict, exp in
            guard let name = exp.expenseCategory?.name else { return }
            let key = normalizedCategoryName(name)
            dict[key, default: 0] += exp.plannedAmount
        }
    }

    private func refreshCapOverrides() {
        let ctx = CoreDataService.shared.viewContext
        let key = periodKey(start: vm.startDate, end: vm.endDate, segment: segment)
        let fetch = NSFetchRequest<CategorySpendingCap>(entityName: "CategorySpendingCap")
        fetch.predicate = NSPredicate(format: "period == %@", key)
        let results = (try? ctx.fetch(fetch)) ?? []
        var map: [String: (min: Double?, max: Double?)] = [:]
        for cap in results {
            guard let cat = cap.category,
                  let name = cat.name else { continue }
            let norm = normalizedCategoryName(name)
            var entry = map[norm] ?? (min: nil, max: nil)
            let type = (cap.expenseType ?? "").lowercased()
            if type == "min" { entry.min = cap.amount }
            if type == "max" { entry.max = cap.amount }
            map[norm] = entry
        }
        capOverrides = map
    }

    private func defaultCaps(for categoryName: String, segment: BudgetDetailsViewModel.Segment) -> (min: Double, max: Double?) {
        let key = normalizedCategoryName(categoryName)
        let defaultMax = segment == .planned ? (plannedPlannedCapTotals[key] ?? 0) : nil
        return (0, defaultMax)
    }

    private func capLimits(for categoryName: String, segment: BudgetDetailsViewModel.Segment) -> (min: Double, max: Double?) {
        let key = normalizedCategoryName(categoryName)
        let defaults = defaultCaps(for: categoryName, segment: segment)
        let overrides = capOverrides[key]
        let min = overrides?.min ?? defaults.min
        let max = overrides?.max ?? defaults.max
        return (min, max)
    }

    private func isOverCap(category: BudgetSummary.CategorySpending, segment: BudgetDetailsViewModel.Segment) -> Bool {
        let limits = capLimits(for: category.categoryName, segment: segment)
        guard let max = limits.max else { return false }
        return category.amount > max
    }

    private func saveCaps(for data: CapGaugeData, min: Double, max: Double?) async {
        let context = CoreDataService.shared.viewContext
        let coordinator = CoreDataService.shared.container.persistentStoreCoordinator
        let catID: NSManagedObjectID? = {
            if let direct = data.categoryObjectID { return direct }
            if data.category.categoryURI.scheme == "x-coredata" {
                return coordinator.managedObjectID(forURIRepresentation: data.category.categoryURI)
            }
            let name = data.category.categoryName.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !name.isEmpty else { return nil }
            let fetch = NSFetchRequest<ExpenseCategory>(entityName: "ExpenseCategory")
            fetch.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
                NSPredicate(format: "name ==[cd] %@", name),
                WorkspaceService.shared.activeWorkspacePredicate()
            ])
            fetch.fetchLimit = 1
            return try? context.fetch(fetch).first?.objectID
        }()
        guard let catID else { return }
        await context.perform {
            guard let category = try? context.existingObject(with: catID) as? ExpenseCategory else { return }

            let fetch = NSFetchRequest<CategorySpendingCap>(entityName: "CategorySpendingCap")
            fetch.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
                NSPredicate(format: "category == %@", category),
                NSPredicate(format: "period == %@", data.periodKey),
                NSPredicate(format: "expenseType IN %@", ["min", "max"])
            ])
            let results = (try? context.fetch(fetch)) ?? []

            func upsert(type: String, amount: Double) {
                if let existing = results.first(where: { ($0.expenseType ?? "").lowercased() == type.lowercased() }) {
                    existing.amount = amount
                    return
                }
                let cap = CategorySpendingCap(context: context)
                cap.id = UUID()
                cap.category = category
                cap.expenseType = type
                cap.period = data.periodKey
                cap.amount = amount
            }

            upsert(type: "min", amount: min)
            if let max {
                upsert(type: "max", amount: max)
            } else {
                for cap in results where (cap.expenseType ?? "").lowercased() == "max" {
                    context.delete(cap)
                }
            }

            do { try context.save() } catch { /* swallow to keep UI responsive */ }
        }

        await MainActor.run {
            capGaugeData = CapGaugeData(
                category: data.category,
                minCap: min,
                maxCap: max,
                current: data.current,
                color: data.color,
                hasExplicitMax: max != nil,
                categoryObjectID: data.categoryObjectID,
                periodKey: data.periodKey
            )
            refreshCapOverrides()
            Task { await vm.refreshRows() }
        }
    }

// MARK: - Cap Gauge Sheet
    private struct CategoryCapGaugeSheet: View {
        let data: BudgetDetailsView.CapGaugeData
        let onDismiss: () -> Void
        let onSave: (Double, Double?) async -> Void

        @State private var minText: String
        @State private var maxText: String
        @State private var isSaving = false

        init(
            data: BudgetDetailsView.CapGaugeData,
            onDismiss: @escaping () -> Void,
            onSave: @escaping (Double, Double?) async -> Void
        ) {
            self.data = data
            self.onDismiss = onDismiss
            self.onSave = onSave
            _minText = State(initialValue: Self.formatInput(data.minCap))
            _maxText = State(initialValue: data.maxCap.map { Self.formatInput($0) } ?? "")
        }

        private var editedMin: Double { parsedMin ?? data.minCap }
        private var editedMax: Double? {
            return parsedMax ?? data.maxCap
        }

        private var maxValue: Double {
            if let editedMax { return editedMax }
            return max(data.current, editedMin) + 1
        }
        private var lowerBound: Double { editedMin }
        private var upperBound: Double { max(maxValue, lowerBound) }
        private var maxLabelString: String {
            editedMax.map { formatCurrency($0) } ?? "—"
        }
        private var isSaveDisabled: Bool {
            guard let min = parsedMin else { return true }
            if let max = parsedMax { return isSaving || max < min }
            return isSaving
        }

        var body: some View {
            navigationContainer {
                content
                    .navigationTitle(data.category.categoryName)
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Cancel", action: onDismiss)
                        }
                        ToolbarItem(placement: .confirmationAction) {
                            Button(isSaving ? "Saving…" : "Save") {
                                Task { await handleSave() }
                            }
                            .disabled(isSaveDisabled)
                        }
                    }
            }
            .applyDetentsIfAvailable(detents: [.medium, .large], selection: nil)
        }

        private var content: some View {
            Form {
                Section {
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
                        .accessibilityLabel(Text("Current spending"))
                        .accessibilityValue(Text(formatCurrency(data.current)))
                        .accessibilityHint(Text("Shows current spending within the cap range."))

                        HStack {
                            Text(formatCurrency(lowerBound)).foregroundStyle(.secondary)
                            Spacer()
                            Text(maxLabelString)
                                .foregroundStyle(.secondary)
                                .opacity(editedMax != nil ? 1 : 0.7)
                        }
                        .font(.footnote)

                        HStack {
                            Text("Current: \(formatCurrency(data.current))").foregroundStyle(.secondary)
                            Spacer()
                            Text("Range: \(formatCurrency(lowerBound)) – \(editedMax.map { formatCurrency($0) } ?? "No max")")
                                .foregroundStyle(.secondary)
                        }
                        .font(.footnote)
                    }
                    .padding(.vertical, 4)
                }

                Section {
                    capEditor
                        .padding(.vertical, 4)
                }
            }
            .listStyle(.insetGrouped)
            .scrollIndicators(.hidden)
        }

        @ViewBuilder
        private func navigationContainer<Inner: View>(@ViewBuilder content: () -> Inner) -> some View {
            if #available(iOS 16.0, macCatalyst 16.0, *) {
                NavigationStack { content() }
            } else {
                NavigationView { content() }
            }
        }

        private var capEditor: some View {
            VStack(alignment: .leading, spacing: 12) {
                Text("Set Spending Limits")
                    .font(.subheadline.weight(.semibold))

                VStack(alignment: .leading, spacing: 6) {
                    Text("Minimum")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    if #available(iOS 26.0, macOS 26.0, macCatalyst 26.0, *) {
                        TextField("0.00", text: $minText)
                            .keyboardType(.decimalPad)
                            .textFieldStyle(.plain)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(
                                Color.clear.glassEffect(
                                    .regular.tint(.clear).interactive(true),
                                    in: .capsule
                                )
                            )
                            .accessibilityLabel("Minimum Amount")
                            .accessibilityHint("Enter the minimum spending limit.")
                    } else {
                        TextField("0.00", text: $minText)
                            .keyboardType(.decimalPad)
                            .textFieldStyle(.roundedBorder)
                            .accessibilityLabel("Minimum Amount")
                            .accessibilityHint("Enter the minimum spending limit.")
                    }
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text("Maximum")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    if #available(iOS 26.0, macOS 26.0, macCatalyst 26.0, *) {
                        TextField("Leave Empty for No Maximum Amount", text: $maxText)
                            .keyboardType(.decimalPad)
                            .textFieldStyle(.plain)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(
                                Color.clear.glassEffect(
                                    .regular.tint(.clear).interactive(true),
                                    in: .capsule
                                )
                            )
                            .accessibilityLabel("Maximum Amount")
                            .accessibilityHint("Leave empty for no maximum.")
                    } else {
                        TextField("Leave Empty for No Maximum Amount", text: $maxText)
                            .keyboardType(.decimalPad)
                            .textFieldStyle(.roundedBorder)
                            .accessibilityLabel("Maximum Amount")
                            .accessibilityHint("Leave empty for no maximum.")
                    }
                }
            }
        }

        private func handleSave() async {
            guard let min = parsedMin else { return }
            let max = parsedMax
            isSaving = true
            defer { isSaving = false }
            await onSave(min, max)
            onDismiss()
        }

        private var parsedMin: Double? { parseAmount(minText) }
        private var parsedMax: Double? { parseAmount(maxText) }

        private func parseAmount(_ text: String) -> Double? {
            let decimalSeparator = Locale.current.decimalSeparator ?? "."
            let cleaned = text
                .replacingOccurrences(of: Locale.current.groupingSeparator ?? ",", with: "")
                .replacingOccurrences(of: Locale.current.currencySymbol ?? "$", with: "")
                .trimmingCharacters(in: .whitespacesAndNewlines)
            let normalized = cleaned.replacingOccurrences(of: decimalSeparator, with: ".")
            return Double(normalized)
        }

        private static func formatInput(_ value: Double) -> String {
            let formatter = NumberFormatter()
            formatter.numberStyle = .decimal
            formatter.maximumFractionDigits = 2
            formatter.minimumFractionDigits = 0
            formatter.usesGroupingSeparator = false
            return formatter.string(from: NSNumber(value: value)) ?? "\(value)"
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

import SwiftUI
import CoreData

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

    init(budgetID: NSManagedObjectID, store: BudgetDetailsViewModelStore = .shared) {
        self.budgetID = budgetID
        _vm = StateObject(wrappedValue: store.viewModel(for: budgetID))
    }

    var body: some View {
        List {
            Section { summaryCard }
            Section { filterControls }
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

    private var filterControls: some View {
        VStack(alignment: .leading, spacing: 12) {
            BudgetExpenseSegmentedControl(
                plannedSegment: BudgetDetailsViewModel.Segment.planned,
                variableSegment: BudgetDetailsViewModel.Segment.variable,
                selection: $segment
            )
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
            categoryChips
        }
        .listRowInsets(EdgeInsets())
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

    private var categoryChips: some View {
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
        formatter.currencyCode = Locale.current.currencyCode ?? "USD"
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
}

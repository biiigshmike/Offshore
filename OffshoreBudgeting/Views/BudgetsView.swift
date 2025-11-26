import SwiftUI
import CoreData

// MARK: - BudgetsView
/// Lists active budgets in reverse chronological order and links to details.
struct BudgetsView: View {
    // MARK: State
    @State private var budgets: [Budget] = []
    @State private var isLoading = false
    @State private var alert: AlertItem?

    // MARK: Services
    private let budgetService = BudgetService()

    var body: some View {
        content
            .navigationTitle("Budgets")
            .task { await loadBudgetsIfNeeded() }
            .refreshable { await loadBudgets() }
            .alert(item: $alert) { alert in
                Alert(title: Text("Error"),
                      message: Text(alert.message),
                      dismissButton: .default(Text("OK")))
            }
    }

    @ViewBuilder
    private var content: some View {
        if isLoading {
            ProgressView("Loading Budgets…")
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        } else if activeBudgets.isEmpty {
            UBEmptyState(
                iconSystemName: "chart.pie",
                title: "No Active Budgets",
                message: "Create a budget to get started."
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        } else {
            List {
                Section("Active Budgets") {
                    ForEach(activeBudgets, id: \.objectID) { budget in
                        NavigationLink(destination: BudgetDetailsDestination(budgetID: budget.objectID)) {
                            BudgetRow(budget: budget)
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
        }
    }

    private var activeBudgets: [Budget] {
        let now = Date()
        return budgets.filter { isActive($0, on: now) }
    }

    // MARK: Data Loading
    private func loadBudgetsIfNeeded() async {
        guard budgets.isEmpty else { return }
        await loadBudgets()
    }

    private func loadBudgets() async {
        await MainActor.run { isLoading = true }
        do {
            let allBudgets = try budgetService.fetchAllBudgets(sortByStartDateDescending: true)
            await MainActor.run {
                budgets = allBudgets
                isLoading = false
            }
        } catch {
            await MainActor.run {
                alert = AlertItem(message: "Couldn’t load budgets. Please try again.")
                isLoading = false
            }
        }
    }

    private func isActive(_ budget: Budget, on date: Date) -> Bool {
        guard let start = budget.startDate, let end = budget.endDate else { return false }
        return start <= date && end >= date
    }
}

// MARK: - Row
private struct BudgetRow: View {
    let budget: Budget

    private let dateFormatter: DateIntervalFormatter = {
        let formatter = DateIntervalFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }()

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.headline)
            if let start = budget.startDate, let end = budget.endDate {
                Text(dateFormatter.string(from: start, to: end))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var title: String {
        let raw = budget.name?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return raw.isEmpty ? "Untitled Budget" : raw
    }
}

// MARK: - Destination
private struct BudgetDetailsDestination: View {
    @Environment(\.managedObjectContext) private var viewContext

    let budgetID: NSManagedObjectID

    @State private var budget: Budget?

    private let dateFormatter: DateIntervalFormatter = {
        let formatter = DateIntervalFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }()

    var body: some View {
        List {
            if let budget {
                Section("Overview") {
                    DetailRow(title: "Name", value: budgetName(for: budget))
                    if let start = budget.startDate, let end = budget.endDate {
                        DetailRow(title: "Dates", value: dateFormatter.string(from: start, to: end))
                    }
                    if budget.isRecurring {
                        DetailRow(title: "Recurring", value: budget.recurrenceType ?? "Yes")
                    }
                }
            } else {
                Section {
                    Text("Budget not found")
                        .foregroundStyle(.secondary)
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle(budgetTitle)
        .task { loadBudget() }
    }

    private var budgetTitle: String { budgetName(for: budget) }

    private func loadBudget() {
        budget = try? viewContext.existingObject(with: budgetID) as? Budget
    }

    private func budgetName(for budget: Budget?) -> String {
        let raw = budget?.name?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return raw.isEmpty ? "Budget" : raw
    }
}

private struct DetailRow: View {
    let title: String
    let value: String

    var body: some View {
        HStack {
            Text(title)
            Spacer()
            Text(value)
                .foregroundStyle(.secondary)
        }
    }
}

private struct AlertItem: Identifiable {
    let id = UUID()
    let message: String
}

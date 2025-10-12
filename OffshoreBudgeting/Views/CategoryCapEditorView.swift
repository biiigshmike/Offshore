import SwiftUI

// MARK: - CategoryCapEditorView
struct CategoryCapEditorView: View {

    // MARK: Inputs
    let categoryID: UUID
    let displayName: String
    let expenseType: CategorySpendingCapService.ExpenseType
    let period: BudgetPeriod
    let existingAmount: Double?
    let onComplete: () -> Void

    // MARK: State
    @State private var amount: Double
    @State private var isSaving: Bool = false
    @State private var errorMessage: String?
    @FocusState private var isAmountFieldFocused: Bool

    // MARK: Environment
    @Environment(\.dismiss) private var dismiss

    // MARK: Currency
    private let currencyCode: String
    private var currencyFormat: FloatingPointFormatStyle<Double>.Currency {
        .currency(code: currencyCode)
    }

    // MARK: Init
    init(categoryID: UUID,
         displayName: String,
         expenseType: CategorySpendingCapService.ExpenseType,
         period: BudgetPeriod,
         existingAmount: Double?,
         onComplete: @escaping () -> Void = {}) {
        self.categoryID = categoryID
        self.displayName = displayName
        self.expenseType = expenseType
        self.period = period
        self.existingAmount = existingAmount
        self.onComplete = onComplete

        if #available(iOS 16.0, macCatalyst 16.0, macOS 13.0, *) {
            self.currencyCode = Locale.current.currency?.identifier ?? "USD"
        } else {
            self.currencyCode = Locale.current.currencyCode ?? "USD"
        }

        _amount = State(initialValue: existingAmount ?? 0)
    }

    // MARK: Body
    var body: some View {
        navigationContainer {
            editorList
                .navigationTitle("Category Cap")
                .toolbar { toolbarContent }
                .disabled(isSaving)
        }
        .onAppear {
            if existingAmount == nil {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    isAmountFieldFocused = true
                }
            }
        }
        .alert("Unable to Save", isPresented: Binding<Bool>(
            get: { errorMessage != nil },
            set: { if !$0 { errorMessage = nil } }
        ), actions: {
            Button("OK", role: .cancel) { errorMessage = nil }
        }, message: {
            if let errorMessage {
                Text(errorMessage)
            }
        })
    }

    @ViewBuilder
    private func navigationContainer<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        if #available(iOS 16.0, macCatalyst 16.0, macOS 13.0, *) {
            NavigationStack { content() }
        } else {
            NavigationView { content() }
        }
    }

    private var editorList: some View {
        List {
            Section("Category") {
                Text(displayName)
            }

            Section("Segment") {
                Text(segmentTitle)
            }

            Section(periodSectionTitle) {
                TextField("0", value: $amount, format: currencyFormat)
                    .keyboardType(.decimalPad)
                    .focused($isAmountFieldFocused)
            }
        }
        .categoryCapListStyle()
    }

    private var periodSectionTitle: String {
        "Cap for \(period.displayName) Period"
    }

    private var segmentTitle: String {
        switch expenseType {
        case .planned:
            return "Planned Expenses"
        case .variable:
            return "Variable Expenses"
        }
    }

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .cancellationAction) {
            Button("Cancel") { dismiss() }
                .applyButtonStyle()
        }
        ToolbarItem(placement: .confirmationAction) {
            Button("Save", action: save)
                .disabled(isSaving || !isAmountValid)
                .applyButtonStyle()
        }
    }

    private var isAmountValid: Bool {
        amount > 0
    }

    private func save() {
        guard isAmountValid else { return }
        isSaving = true
        Task {
            do {
                let service = CategorySpendingCapService()
                _ = try service.upsertCap(
                    amount: amount,
                    categoryID: categoryID,
                    expenseType: expenseType,
                    period: period
                )
                await MainActor.run {
                    isSaving = false
                    dismiss()
                    onComplete()
                }
            } catch {
                await MainActor.run {
                    isSaving = false
                    errorMessage = error.localizedDescription
                }
            }
        }
    }
}

private extension View {
    func applyButtonStyle() -> some View {
        modifier(CategoryCapEditorButtonStyleModifier())
    }

    @ViewBuilder
    func categoryCapListStyle() -> some View {
        if #available(iOS 16.0, macCatalyst 16.0, macOS 13.0, *) {
            self.listStyle(.insetGrouped)
        } else {
            self.listStyle(.grouped)
        }
    }
}

private struct CategoryCapEditorButtonStyleModifier: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 26.0, macCatalyst 26.0, macOS 26.0, *) {
            content.buttonStyle(.glass)
        } else {
            content.buttonStyle(.plain)
        }
    }
}

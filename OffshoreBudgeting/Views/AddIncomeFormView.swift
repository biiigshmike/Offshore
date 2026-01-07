// OffshoreBudgeting/Views/AddIncomeFormView.swift

import SwiftUI
import CoreData

// MARK: - AddIncomeFormView
struct AddIncomeFormView: View {
    @Environment(\.managedObjectContext) var viewContext
    @Environment(\.dismiss) private var dismiss

    let incomeObjectID: NSManagedObjectID?
    let budgetObjectID: NSManagedObjectID?
    let initialDate: Date?

    @StateObject var viewModel: AddIncomeFormViewModel
    @State private var error: SaveError?
    @State private var showEditScopeOptions: Bool = false

    init(incomeObjectID: NSManagedObjectID? = nil,
         budgetObjectID: NSManagedObjectID? = nil,
         initialDate: Date? = nil) {
        self.incomeObjectID = incomeObjectID
        self.budgetObjectID = budgetObjectID
        self.initialDate = initialDate
        _viewModel = StateObject(wrappedValue: AddIncomeFormViewModel(
            incomeObjectID: incomeObjectID,
            budgetObjectID: budgetObjectID
        ))
    }

    var body: some View {
        navigationContainer {
            formContent
                .navigationTitle(viewModel.isEditing ? "Edit Income" : "Add Income")
                .ub_windowTitle(viewModel.isEditing ? "Edit Income" : "Add Income")
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") { dismiss() }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button(viewModel.isEditing ? "Save Changes" : "Add Income") {
                            _ = saveTapped()
                        }
                        .accessibilityIdentifier("btn_confirm")
                        .disabled(!viewModel.canSave)
                    }
                }
        }
        .applyDetentsIfAvailable(detents: [.medium, .large], selection: nil)
        .onAppear {
            do { try viewModel.loadIfNeeded(from: viewContext) }
            catch { /* This error is handled at save time */ }
            if !viewModel.isEditing, let prefill = initialDate {
                viewModel.firstDate = prefill
            }
        }
        .alert(item: $error) { err in
            Alert(
                title: Text("Couldn’t Save"),
                message: Text(err.message),
                dismissButton: .default(Text("OK"))
            )
        }
        .onChange(of: viewModel.isPresentingCustomRecurrenceEditor) { newValue in
            if newValue {
                if case .custom(let raw, _) = viewModel.recurrenceRule {
                    viewModel.customRuleSeed = CustomRecurrence.roughParse(rruleString: raw)
                } else {
                    viewModel.customRuleSeed = CustomRecurrence()
                }
            }
        }
        .sheet(isPresented: $viewModel.isPresentingCustomRecurrenceEditor) {
            CustomRecurrenceEditorView(initial: viewModel.customRuleSeed) {
                viewModel.isPresentingCustomRecurrenceEditor = false
            } onSave: { custom in
                viewModel.applyCustomRecurrence(custom)
                viewModel.isPresentingCustomRecurrenceEditor = false
            }
        }
        .confirmationDialog(
            "Update Recurring Income",
            isPresented: $showEditScopeOptions,
            titleVisibility: .visible
        ) {
            Button("Edit only this instance") { _ = performSave(scope: .instance) }
            Button("Edit this and all future instances (creates a new series)") { _ = performSave(scope: .future) }
            Button("Edit all instances (past and future)") { _ = performSave(scope: .all) }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Selecting \"Edit this and all future instances\" creates a new series. Changes from this point forward will be treated as a new series.")
        }
    }

    // MARK: Navigation container
    @ViewBuilder
    private func navigationContainer<Inner: View>(@ViewBuilder content: () -> Inner) -> some View {
        if #available(iOS 16.0, macCatalyst 16.0, *) {
            NavigationStack { content() }
        } else {
            NavigationView { content() }
        }
    }

    // MARK: - Form content
    @ViewBuilder
    private var formContent: some View {
        Form {
            if viewModel.isEditing && viewModel.isPartOfSeries {
                Text("Editing a recurring income. Choosing \"Edit this and all future instances\" will create a new series. Changes from this point forward will be treated as a new series.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .padding(.bottom, 4)
            }
            typeSection
            sourceSection
            amountSection
            firstDateSection
            recurrenceSection
        }
        .listStyle(.insetGrouped)
        .scrollIndicators(.hidden)
        .multilineTextAlignment(.leading)
    }

    @ViewBuilder
    private var typeSection: some View {
        Section {
            PillSegmentedControl(selection: $viewModel.isPlanned) {
                Text("Planned").tag(true)
                Text("Actual").tag(false)
            }
            .accessibilityIdentifier("incomeTypeSegmentedControl")
        } header: {
            Text("Type")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
        }
    }
    
    // ... (Rest of file is unchanged)
    @ViewBuilder
    private var sourceSection: some View {
        Section {
            HStack(alignment: .center) {
                if #available(iOS 15.0, macCatalyst 15.0, *) {
                    TextField("", text: $viewModel.source, prompt: Text("Paycheck"))
                        .autocorrectionDisabled(true)
                        .textInputAutocapitalization(.never)
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .accessibilityLabel("Income Source")
                        .accessibilityIdentifier("txt_income_source")
                } else {
                    TextField("Paycheck", text: $viewModel.source)
                        .autocorrectionDisabled(true)
                        .textInputAutocapitalization(.never)
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .accessibilityLabel("Income Source")
                        .accessibilityIdentifier("txt_income_source")
                }
                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        } header: {
            Text("Source")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
        }
    }
    @ViewBuilder
    private var amountSection: some View {
        Section {
            HStack(alignment: .center) {
                if #available(iOS 15.0, macCatalyst 15.0, *) {
                    TextField("", text: $viewModel.amountInput, prompt: Text("1000"))
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .accessibilityLabel("Income Amount")
                        .accessibilityIdentifier("txt_income_amount")
                } else {
                    TextField("1542.75", text: $viewModel.amountInput)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .accessibilityLabel("Income Amount")
                        .accessibilityIdentifier("txt_income_amount")
                }
                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        } header: {
            Text("Amount")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
        }
    }
    @ViewBuilder
    private var firstDateSection: some View {
        Section {
            DatePicker("", selection: $viewModel.firstDate, displayedComponents: [.date])
                .labelsHidden()
                .datePickerStyle(.compact)
                .accessibilityIdentifier("incomeFirstDatePicker")
                .accessibilityLabel("Entry Date")
        } header: {
            Text("Entry Date")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
        }
    }
    @ViewBuilder
    private var recurrenceSection: some View {
        Section {
            RecurrencePickerView(rule: $viewModel.recurrenceRule,
                                 isPresentingCustomEditor: $viewModel.isPresentingCustomRecurrenceEditor)
        } header: {
            Text("Recurrence")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
        }
    }
    private func saveTapped() -> Bool {
        if viewModel.isEditing && viewModel.isPartOfSeries {
            showEditScopeOptions = true
            return false
        }
        return performSave(scope: .all)
    }
    private func performSave(scope: RecurrenceScope) -> Bool {
        do {
            try viewModel.save(in: viewContext, scope: scope)
            ub_dismissKeyboard()
            dismiss()
            return true
        } catch let err as SaveError {
            self.error = err
            return false
        } catch {
            self.error = .message("Unexpected error: \(error.localizedDescription)")
            return false
        }
    }
    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.footnote)
            .foregroundStyle(.secondary)
            .textCase(.uppercase)
    }
}

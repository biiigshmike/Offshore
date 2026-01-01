//
//  AddBudgetView.swift
//  SoFar
//
//  Cross-platform Add/Edit Budget form.
//  - Name text field
//  - Start/End date pickers
//  - Toggle list of Cards to track in this budget
//  - Toggle list of global Planned Expense presets to clone
//  - Save/Cancel actions (standardized via EditSheetScaffold)
//
//  Notes:
//  - ViewModel preloads synchronously in init when editing, so first frame is not blank.
//  - We still call `.task { await vm.load() }` to hydrate lists and refresh state.
//

import SwiftUI
import CoreData

// MARK: - AddBudgetView
struct AddBudgetView: View {

    // MARK: Environment
    /// We don't call `dismiss()` directly anymore (the scaffold handles it),
    /// but we keep this in case future platform-specific work needs it.
    @Environment(\.dismiss) private var dismiss

    // MARK: Inputs
    private let initialStartDate: Date?
    private let initialEndDate: Date?
    private let editingBudgetObjectID: NSManagedObjectID?
    private let onSaved: (() -> Void)?

    // MARK: VM
    @StateObject private var vm: AddBudgetViewModel

    // MARK: Local UI State
    /// Populated if saving fails; presented in a SwiftUI alert.
    @State private var saveErrorMessage: String?

    // MARK: Init (ADD)
    /// Use this initializer when **adding** a budget.
    /// - Parameters:
    ///   - initialStartDate: Suggested budget start date to prefill.
    ///   - initialEndDate: Suggested budget end date to prefill.
    ///   - onSaved: Callback fired after a successful save.
    init(
        initialStartDate: Date,
        initialEndDate: Date,
        onSaved: (() -> Void)? = nil
    ) {
        self.initialStartDate = initialStartDate
        self.initialEndDate = initialEndDate
        self.editingBudgetObjectID = nil
        self.onSaved = onSaved
        _vm = StateObject(wrappedValue: AddBudgetViewModel(
            startDate: initialStartDate,
            endDate: initialEndDate,
            editingBudgetObjectID: nil
        ))
    }

    // MARK: Init (EDIT)
    /// Use this initializer when **editing** an existing budget.
    /// - Parameters:
    ///   - editingBudgetObjectID: ObjectID for the Budget being edited.
    ///   - fallbackStartDate: Date to display *until* the real value is preloaded (very brief).
    ///   - fallbackEndDate: Date to display *until* the real value is preloaded (very brief).
    ///   - onSaved: Callback fired after a successful save.
    init(
        editingBudgetObjectID: NSManagedObjectID,
        fallbackStartDate: Date,
        fallbackEndDate: Date,
        onSaved: (() -> Void)? = nil
    ) {
        self.initialStartDate = fallbackStartDate
        self.initialEndDate = fallbackEndDate
        self.editingBudgetObjectID = editingBudgetObjectID
        self.onSaved = onSaved
        _vm = StateObject(wrappedValue: AddBudgetViewModel(
            startDate: fallbackStartDate,
            endDate: fallbackEndDate,
            editingBudgetObjectID: editingBudgetObjectID
        ))
    }

    // MARK: Body
    var body: some View {
        navigationContainer {
            Form {
                // MARK: Form Content

            // ---- Name
            Section {
                // Use an empty label with a prompt so the text acts as a
                // placeholder across platforms.  We expand the field to fill
                // the row and align text to the leading edge for consistency
                // with Add Card and the expense forms.
                HStack(alignment: .center) {
                    TextField(
                        "",
                        text: $vm.budgetName,
                        prompt: Text(vm.defaultBudgetName)
                    )
                    .autocorrectionDisabled(true)
                    .textInputAutocapitalization(.never)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .accessibilityLabel("Budget Name")
                    Spacer(minLength: 0)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            } header: {
                Text("Name")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)
            }

            // ---- Dates
            Section {
                HStack(spacing: DS.Spacing.m) {
                    DatePicker("Start", selection: $vm.startDate, displayedComponents: [.date])
                        .labelsHidden()
                        .accessibilityLabel("Start Date")
                        .datePickerStyle(.compact)
                    DatePicker("End", selection: $vm.endDate, displayedComponents: [.date])
                        .labelsHidden()
                        .accessibilityLabel("End Date")
                        .datePickerStyle(.compact)
                }
            } header: {
                Text("Dates")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)
            }

            // ---- Cards to Track
            Section {
                if vm.allCards.isEmpty {
                    Text("No cards yet. Add cards first to track expenses.")
                        .foregroundStyle(.secondary)
                } else {
                    // Toggle All (button)
                    toggleAllRowButton(
                        action: toggleAllCards,
                        accessibilityLabel: "Toggle All Cards",
                        accessibilityHint: "Selects or deselects every card."
                    )

                    ForEach(vm.allCards, id: \.objectID) { card in
                        let isTracking = Binding(
                            get: { vm.selectedCardObjectIDs.contains(card.objectID) },
                            set: { newValue in
                                if newValue {
                                    vm.selectedCardObjectIDs.insert(card.objectID)
                                } else {
                                    vm.selectedCardObjectIDs.remove(card.objectID)
                                }
                            }
                        )
                        Toggle(card.name ?? "Untitled Card", isOn: isTracking)
                    }
                }
            } header: {
                Text("Cards to Track")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)
            }

            // ---- Preset Planned Expenses
            Section {
                if vm.globalPlannedExpenseTemplates.isEmpty {
                    Text("No presets yet. You can add them later.")
                        .foregroundStyle(.secondary)
                } else {
                    // Toggle All (button)
                    toggleAllRowButton(
                        action: toggleAllPresets,
                        accessibilityLabel: "Toggle All Presets",
                        accessibilityHint: "Selects or deselects every preset."
                    )

                    ForEach(vm.globalPlannedExpenseTemplates, id: \.objectID) { template in
                        let isSelected = Binding(
                            get: { vm.selectedTemplateObjectIDs.contains(template.objectID) },
                            set: { newValue in
                                if newValue {
                                    vm.selectedTemplateObjectIDs.insert(template.objectID)
                                } else {
                                    vm.selectedTemplateObjectIDs.remove(template.objectID)
                                }
                            }
                        )
                        Toggle(template.descriptionText ?? "Untitled", isOn: isSelected)
                    }
                }
            } header: {
                Text("Preset Planned Expenses")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)
            }
            }
            .listStyle(.insetGrouped)
            .scrollIndicators(.hidden)
            .navigationTitle(vm.isEditing ? "Edit Budget" : "Add Budget")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(vm.isEditing ? "Save Changes" : "Create Budget") {
                        if saveTapped() { dismiss() }
                    }
                    .disabled(!vm.canSave)
                }
            }
        }
        .applyDetentsIfAvailable(detents: [.medium, .large], selection: nil)
        // Keep async hydration for lists/templates.
        .task { await vm.load() }
        // Present any save error in a standard alert.
        .alert("Couldn’t Save Budget",
               isPresented: Binding(
                get: { saveErrorMessage != nil },
                set: { if !$0 { saveErrorMessage = nil } })
        ) {
            Button("OK", role: .cancel) { saveErrorMessage = nil }
        } message: {
            Text(saveErrorMessage ?? "")
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

    // MARK: Actions
    /// Attempts to save via the view model.
    /// - Returns: `true` to allow the scaffold to dismiss the sheet; `false` to keep it open.
    private func saveTapped() -> Bool {
        do {
            try vm.save()
            onSaved?()
            // Resign keyboard on iOS/iPadOS via unified helper for a neat dismissal.
            ub_dismissKeyboard()
            return true
        } catch {
            saveErrorMessage = error.localizedDescription
            return false
        }
    }

    // MARK: - Toggle All helpers
    private func toggleAllCards() {
        let allSelected = !vm.allCards.isEmpty && vm.selectedCardObjectIDs.count == vm.allCards.count
        if allSelected {
            vm.selectedCardObjectIDs.removeAll()
        } else {
            vm.selectedCardObjectIDs = Set(vm.allCards.map { $0.objectID })
        }
    }

    private func toggleAllPresets() {
        let allSelected = !vm.globalPlannedExpenseTemplates.isEmpty && vm.selectedTemplateObjectIDs.count == vm.globalPlannedExpenseTemplates.count
        if allSelected {
            vm.selectedTemplateObjectIDs.removeAll()
        } else {
            vm.selectedTemplateObjectIDs = Set(vm.globalPlannedExpenseTemplates.map { $0.objectID })
        }
    }

    @ViewBuilder
    private func toggleAllRowButton(
        action: @escaping () -> Void,
        accessibilityLabel: String,
        accessibilityHint: String
    ) -> some View {
        let label = Text("Toggle All")
            .font(.subheadline.weight(.semibold))
            .frame(maxWidth: .infinity)
            .frame(minHeight: 44, maxHeight: 44)

        if #available(iOS 26.0, macCatalyst 26.0, macOS 26.0, *) {
            Button(action: action) {
                label
            }
            .buttonStyle(.glassProminent)
            .tint(Color.green.opacity(0.75))
            .accessibilityLabel(accessibilityLabel)
            .accessibilityHint(accessibilityHint)
        } else {
            Button(action: action) {
                label
            }
            .buttonStyle(.plain)
            .background(
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(
                        {
                            #if canImport(UIKit)
                            return Color(UIColor { traits in
                                traits.userInterfaceStyle == .dark ? UIColor(white: 0.22, alpha: 1) : UIColor(white: 0.9, alpha: 1)
                            })
                            #elseif canImport(AppKit)
                            return Color(nsColor: NSColor.windowBackgroundColor)
                            #else
                            return Color.gray.opacity(0.2)
                            #endif
                        }()
                    )
            )
            .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
            .contentShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
            .accessibilityLabel(accessibilityLabel)
            .accessibilityHint(accessibilityHint)
        }
    }
}

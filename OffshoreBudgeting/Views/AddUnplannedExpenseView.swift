//
//  AddUnplannedExpenseView.swift
//  SoFar
//
//  Add Variable (Unplanned) Expense
//  -------------------------------------------------------------
//  • Card chooser (horizontal)  ← uses shared CardPickerRow (no local duplicate)
//  • Category chips row (static Add button + live, scrolling chips)
//  • Description, Amount, Date
//  -------------------------------------------------------------?
//

import SwiftUI
import UIKit
import CoreData

// MARK: - AddUnplannedExpenseView
struct AddUnplannedExpenseView: View {

    // MARK: Inputs
    let unplannedExpenseID: NSManagedObjectID?
    let allowedCardIDs: Set<NSManagedObjectID>?
    let initialCardID: NSManagedObjectID?
    let initialDate: Date?
    let onSaved: () -> Void

    // MARK: State
    @StateObject private var vm: AddUnplannedExpenseViewModel
    @EnvironmentObject private var cardPickerStore: CardPickerStore
    @State private var isPresentingAddCard = false
    
    // MARK: - Layout
    /// Height of the card picker row.  This matches the tile height defined in
    /// `CardPickerRow` so adjustments remain centralized.
    private let cardRowHeight: CGFloat = 160


    // MARK: Init
    init(unplannedExpenseID: NSManagedObjectID? = nil,
         allowedCardIDs: Set<NSManagedObjectID>? = nil,
         initialCardID: NSManagedObjectID? = nil,
         initialDate: Date? = nil,
         onSaved: @escaping () -> Void) {
        self.unplannedExpenseID = unplannedExpenseID
        self.allowedCardIDs = allowedCardIDs
        self.initialCardID = initialCardID
        self.initialDate = initialDate
        self.onSaved = onSaved

        let model = AddUnplannedExpenseViewModel(
            unplannedExpenseID: unplannedExpenseID,
            allowedCardIDs: allowedCardIDs,
            initialCardID: initialCardID,
            initialDate: initialDate
        )
        _vm = StateObject<AddUnplannedExpenseViewModel>(wrappedValue: model)
    }

    // MARK: Body
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        navigationContainer {
            formContent
                .navigationTitle(vm.isEditing ? "Edit Variable Expense" : "Add Variable Expense")
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") { dismiss() }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button(vm.isEditing ? "Save Changes" : "Save") {
                            if trySave() { dismiss() }
                        }
                        .disabled(!vm.canSave)
                    }
                }
        }
        .applyDetentsIfAvailable(detents: [.medium, .large], selection: nil)
        .onAppear {
            vm.attachCardPickerStoreIfNeeded(cardPickerStore)
            vm.startIfNeeded()
        }
        // Make sure our chips & sheet share the same context.
        .environment(\.managedObjectContext, CoreDataService.shared.viewContext)
        .sheet(isPresented: $isPresentingAddCard) {
            AddCardFormView { newName, selectedTheme in
                do {
                    let service = CardService()
                    let card = try service.createCard(name: newName)
                    if let uuid = card.value(forKey: "id") as? UUID {
                        CardAppearanceStore.shared.setTheme(selectedTheme, for: uuid)
                    }
                    vm.selectedCardID = card.objectID
                } catch {
                    let alert = UIAlertController(title: "Couldn’t Create Card", message: error.localizedDescription, preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "OK", style: .default))
                    UIApplication.shared.connectedScenes
                        .compactMap { ($0 as? UIWindowScene)?.keyWindow }
                        .first?
                        .rootViewController?
                        .present(alert, animated: true)
                }
            }
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

    // MARK: Form content
    @ViewBuilder
    private var formContent: some View {
        Form {
            // MARK: Card Picker (horizontal)
            Section {
                if !vm.cardsLoaded {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                        .frame(height: cardRowHeight)
                } else if vm.allCards.isEmpty {
                    VStack(spacing: DS.Spacing.m) {
                        Text("No cards yet. Add one to assign this expense.")
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .frame(height: 44)
                        GlassCTAButton(
                            maxWidth: .infinity,
                            height: 33,
                            fillHorizontally: true,
                            fallbackAppearance: .neutral,
                            action: { isPresentingAddCard = true }
                        ) {
                            Label("Add Card", systemImage: "plus")
                        }
                        .accessibilityLabel("Add Card")
                    }
                } else {
                    CardPickerRow(
                        allCards: vm.allCards,
                        selectedCardID: $vm.selectedCardID
                    )
                    .frame(maxWidth: .infinity, alignment: .center)
                    .frame(height: cardRowHeight)
                    .scrollIndicators(.hidden)
                }
            } header: {
                Text("Assign a Card to Expense")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            // MARK: Category Chips Row
            Section {
                CategoryChipsRow(
                    selectedCategoryID: $vm.selectedCategoryID
                )
                .accessibilityElement(children: .contain)
            } header: {
                Text("Category")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
//            .ub_formSectionClearBackground()


            // MARK: Individual Fields
            // Give each field its own section with a header so that the
            // descriptive label appears outside the cell, mirroring the
            // appearance of the Add Card form.  Also left‑align text for
            // improved readability on macOS and avoid right‑aligned text.

            // Expense Description
            Section {
                HStack(alignment: .center) {
                    if #available(iOS 15.0, macCatalyst 15.0, *) {
                        TextField("", text: $vm.descriptionText, prompt: Text("Apple Store"))
                            .autocorrectionDisabled(true)
                            .textInputAutocapitalization(.never)
                            .multilineTextAlignment(.leading)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .accessibilityLabel("Expense Description")
                    } else {
                        TextField("Apple Store", text: $vm.descriptionText)
                            .autocorrectionDisabled(true)
                            .textInputAutocapitalization(.never)
                            .multilineTextAlignment(.leading)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .accessibilityLabel("Expense Description")
                    }
                    Spacer(minLength: 0)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            } header: {
                Text("Expense Description")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            // Amount
            Section {
                HStack(alignment: .center) {
                    if #available(iOS 15.0, macCatalyst 15.0, *) {
                        TextField("", text: $vm.amountString, prompt: Text("299.99"))
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.leading)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .accessibilityLabel("Amount")
                    } else {
                        TextField("299.99", text: $vm.amountString)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.leading)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .accessibilityLabel("Amount")
                    }
                    Spacer(minLength: 0)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            } header: {
                Text("Amount")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            // Transaction Date
            Section {
                DatePicker("", selection: $vm.transactionDate, displayedComponents: [.date])
                    .labelsHidden()
                    .datePickerStyle(.compact)
                    .accessibilityLabel("Transaction Date")
            } header: {
                Text("Transaction Date")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .listStyle(.insetGrouped)
        .scrollIndicators(.hidden)
    }

    // MARK: - trySave()
    /// Validates and persists the expense via the view model.
    /// - Returns: `true` if the sheet should dismiss; `false` to stay open.
    private func trySave() -> Bool {
        guard vm.canSave else { return false }
        do {
            try vm.save()
            onSaved()
            // Resign keyboard on iOS via unified helper
            ub_dismissKeyboard()
            return true
        } catch {
            // Present error via UIKit alert on iOS; macOS simply returns false.
            let alert = UIAlertController(title: "Couldn’t Save", message: error.localizedDescription, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            UIApplication.shared.connectedScenes
                .compactMap { ($0 as? UIWindowScene)?.keyWindow }
                .first?
                .rootViewController?
                .present(alert, animated: true)
            return false
        }
    }
}

// MARK: - CategoryChipsRow
/// Shared layout metrics for the category pill controls.
/// Shows a static “Add” pill followed by a horizontally-scrolling list of
/// category chips (live via @FetchRequest). Selecting a chip updates the binding.
private struct CategoryChipsRow: View {

    // MARK: Binding
    @Binding var selectedCategoryID: NSManagedObjectID?

    // MARK: Environment
    @Environment(\.managedObjectContext) private var viewContext


    // MARK: Live Fetch
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(key: "name", ascending: true,
                                           selector: #selector(NSString.localizedCaseInsensitiveCompare(_:)))]
    )
    private var categories: FetchedResults<ExpenseCategory>

    // MARK: Local State
    @State private var isPresentingNewCategory = false
    @Environment(\.platformCapabilities) private var capabilities

    private let verticalInset: CGFloat = DS.Spacing.s + DS.Spacing.xs
    private let chipRowClipShape = Rectangle()

    var body: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.s) {
            HStack(spacing: DS.Spacing.s) {
                addCategoryButton
                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            chipsScrollContainer()
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .listRowInsets(rowInsets)
        .listRowSeparator(.hidden)
        .sheet(isPresented: $isPresentingNewCategory) {
            // Build as a single expression to avoid opaque 'some View' type mismatches.
            let base = ExpenseCategoryEditorSheet(
                initialName: "",
                initialHex: "#4E9CFF"
            ) { name, hex in
                // Persist the new category and auto-select it.
                let category = ExpenseCategory(context: viewContext)
                category.id = UUID()
                category.name = name
                category.color = hex
                do {
                    // Obtain a permanent ID so the fetch request updates immediately.
                    try viewContext.obtainPermanentIDs(for: [category])
                    try viewContext.save()
                    // Auto-select the newly created category.
                    selectedCategoryID = category.objectID
                } catch {
                    AppLog.ui.error("Failed to create category: \(error.localizedDescription)")
                }
            }
            .environment(\.managedObjectContext, viewContext)

            // Apply detents on supported OS versions without changing the opaque type.
            Group {
                if #available(iOS 16.0, *) {
                    base.presentationDetents([.medium])
                } else {
                    base
                }
            }
        }
        .onChange(of: categories.count) { _ in
            // Auto-pick first category if none selected yet
            if selectedCategoryID == nil, let first = categories.first {
                selectedCategoryID = first.objectID
            }
        }
    }

    private var rowInsets: EdgeInsets {
        EdgeInsets(
            top: verticalInset,
            leading: DS.Spacing.l,
            bottom: verticalInset,
            trailing: DS.Spacing.l
        )
    }
}

private extension CategoryChipsRow {
    @ViewBuilder
    private func chipsScrollContainer() -> some View {
        Group {
            if capabilities.supportsOS26Translucency, #available(iOS 26.0, macOS 26.0, macCatalyst 26.0, *) {
                GlassEffectContainer(spacing: DS.Spacing.s) {
                    chipRowLayout()
                }
            } else {
                chipRowLayout()
            }
        }
        .clipShape(chipRowClipShape)
    }

    private func chipRowLayout() -> some View {
        chipsScrollView()
            .padding(.horizontal, DS.Spacing.s)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func chipsScrollView() -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            categoryChips
                .padding(.trailing, DS.Spacing.s)
        }
        .scrollIndicators(.hidden)
        .ub_disableHorizontalBounce()
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private var categoryChips: some View {
        LazyHStack(spacing: DS.Spacing.s) {
            if categories.isEmpty {
                Text("No categories yet")
                    .foregroundStyle(.secondary)
                    .padding(.vertical, 10)
            } else {
                ForEach(categories, id: \.objectID) { cat in
                    let isSelected = selectedCategoryID == cat.objectID
                    CategoryChip(
                        id: cat.objectID.uriRepresentation().absoluteString,
                        name: cat.name ?? "Untitled",
                        colorHex: cat.color ?? "#999999",
                        isSelected: isSelected,
                        action: { selectedCategoryID = cat.objectID }
                    )
                }
            }
        }
    }

    private var addCategoryButton: some View {
        AddCategoryPill {
            isPresentingNewCategory = true
        }
        .padding(.leading, DS.Spacing.s)
    }
}

// MARK: - AddCategoryPill
/// Compact, fixed “Add” control styled like a pill.
private struct AddCategoryPill: View {
    var fillsWidth: Bool = false
    var onTap: () -> Void
    @EnvironmentObject private var themeManager: ThemeManager

    var body: some View {
        if #available(iOS 26.0, macOS 26.0, macCatalyst 26.0, *) {
            let label = Label("Add", systemImage: "plus")
                .font(.subheadline.weight(.semibold))
                .padding(.horizontal, 12)
                .frame(maxWidth: fillsWidth ? .infinity : nil, minHeight: 44, alignment: .center)
                .glassEffect(.regular.tint(.none).interactive(true))
            Button(action: onTap) {
                label
            }
            .buttonStyle(.plain)
            .frame(maxWidth: fillsWidth ? .infinity : nil, minHeight: 44, alignment: .center)
            .accessibilityLabel("Add Category")
        } else {
            Button(action: onTap) {
                Label("Add", systemImage: "plus")
                    .font(.subheadline.weight(.semibold))
                    .padding(.horizontal, 12)
                    .frame(maxWidth: fillsWidth ? .infinity : nil, minHeight: 44, alignment: .center)
                    .background(
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .fill(Color(UIColor { traits in
                                traits.userInterfaceStyle == .dark ? UIColor(white: 0.22, alpha: 1) : UIColor(white: 0.9, alpha: 1)
                            }))
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                    .contentShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
            }
            .buttonStyle(.plain)
            .controlSize(.regular)
            .frame(maxWidth: fillsWidth ? .infinity : nil, minHeight: 44, alignment: .center)
            .accessibilityLabel("Add Category")
        }
    }
}

// MARK: - CategoryChip
/// A single pill-shaped category with a color dot and name.
private struct CategoryChip: View {
    let id: String
    let name: String
    let colorHex: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        let categoryColor = UBColorFromHex(colorHex) ?? .secondary
        let legacyShape = RoundedRectangle(cornerRadius: 6, style: .continuous)

        let label = HStack(spacing: DS.Spacing.s) {
            Circle()
                .fill(categoryColor)
                .frame(width: 10, height: 10)
            Text(name)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.primary)
        }
        .padding(.horizontal, 12)
        .frame(height: 44)

        let button = Button(action: action) {
            label
        }
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .animation(.easeOut(duration: 0.15), value: isSelected)

        if #available(iOS 26.0, macOS 26.0, macCatalyst 26.0, *) {
            button
                .glassEffect(
                    .regular
                        .tint(isSelected ? categoryColor : .none)
                        .interactive(true)
                )
                .opacity(0.25)
                .buttonStyle(.plain)
                .buttonBorderShape(.capsule)
        } else {
            let neutralFill = DS.Colors.chipFill
            button
                .buttonStyle(.plain)
                .background(
                    legacyShape.fill(isSelected ? categoryColor.opacity(0.25) : neutralFill)
                )
                .overlay(
                    legacyShape
                        .stroke(neutralFill, lineWidth: 1)
                )
                .contentShape(legacyShape)
        }
    }

}

// MARK: - Hex Color Helper (local)
fileprivate func UBColorFromHex(_ hex: String?) -> Color? {
    guard var value = hex?.trimmingCharacters(in: .whitespacesAndNewlines), !value.isEmpty else { return nil }
    if value.hasPrefix("#") { value.removeFirst() }
    guard value.count == 6, let intVal = Int(value, radix: 16) else { return nil }
    let r = Double((intVal >> 16) & 0xFF) / 255.0
    let g = Double((intVal >> 8) & 0xFF) / 255.0
    let b = Double(intVal & 0xFF) / 255.0
    return Color(red: r, green: g, blue: b)
}

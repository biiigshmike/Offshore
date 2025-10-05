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
    @EnvironmentObject private var themeManager: ThemeManager
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
    var body: some View {
        EditSheetScaffold(
            title: vm.isEditing ? "Edit Variable Expense" : "Add Variable Expense",
            saveButtonTitle: vm.isEditing ? "Save Changes" : "Save",
            isSaveEnabled: vm.canSave,
            onSave: { trySave() }
        ) {
            // MARK: Card Picker (horizontal)
            UBFormSection("Assign a Card to Expense", isUppercased: false) {
                if !vm.cardsLoaded {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                        .frame(height: cardRowHeight)
                } else if vm.allCards.isEmpty {
                    VStack(spacing: DS.Spacing.m) {
                        Text("No cards yet. Add one to assign this expense.")
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        GlassCTAButton(
                            maxWidth: .infinity,
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
                    .ub_hideScrollIndicators()
                }
            }

            // MARK: Category Chips Row
            UBFormSection("Category", isUppercased: false) {
                CategoryChipsRow(
                    selectedCategoryID: $vm.selectedCategoryID
                )
                .accessibilityElement(children: .contain)
            }
            .ub_formSectionClearBackground()


            // MARK: Individual Fields
            // Give each field its own section with a header so that the
            // descriptive label appears outside the cell, mirroring the
            // appearance of the Add Card form.  Also left‑align text for
            // improved readability on macOS and avoid right‑aligned text.

            // Expense Description
            UBFormSection("Expense Description", isUppercased: false) {
                UBFormRow {
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
                }
            }

            // Amount
            UBFormSection("Amount", isUppercased: false) {
                UBFormRow {
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
                }
            }

            // Transaction Date
            UBFormSection("Transaction Date", isUppercased: false) {
                DatePicker("", selection: $vm.transactionDate, displayedComponents: [.date])
                    .labelsHidden()
                    .ub_compactDatePickerStyle()
                    .accessibilityLabel("Transaction Date")
            }
        }
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
    @State private var addButtonWidth: CGFloat = .zero
    @Environment(\.platformCapabilities) private var capabilities
    @EnvironmentObject private var themeManager: ThemeManager
    @Namespace private var glassNamespace

    private let verticalInset: CGFloat = DS.Spacing.s + DS.Spacing.xs
    private let addButtonSpacing: CGFloat = DS.Spacing.m
    private let chipRowClipShape = Capsule(style: .continuous)

    var body: some View {
        ZStack(alignment: .leading) {
            chipsScrollContainer()
                .padding(.leading, chipsLeadingPadding)

            addCategoryButton
        }
        .listRowBackground(Color.clear)
        .listRowInsets(
            EdgeInsets(
                top: verticalInset,
                leading: DS.Spacing.l,
                bottom: verticalInset,
                trailing: DS.Spacing.l
            )
        )
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
        .ub_onChange(of: categories.count) {
            // Auto-pick first category if none selected yet
            if selectedCategoryID == nil, let first = categories.first {
                selectedCategoryID = first.objectID
            }
        }
    }
}

private extension CategoryChipsRow {
    private var chipsLeadingPadding: CGFloat { addButtonWidth + addButtonSpacing }

    private var addCategoryButton: some View {
        AddCategoryPill {
            isPresentingNewCategory = true
        }
        .zIndex(1)
        .background(addButtonWidthReader)
    }

    private var addButtonWidthReader: some View {
        GeometryReader { proxy in
            Color.clear
                .onAppear { updateAddButtonWidth(proxy.size.width) }
                .ub_onChange(of: proxy.size.width) { newWidth in
                    updateAddButtonWidth(newWidth)
                }
        }
    }

    @ViewBuilder
    private func chipsScrollContainer() -> some View {
        if capabilities.supportsOS26Translucency, #available(iOS 26.0, macOS 26.0, macCatalyst 26.0, *) {
            GlassEffectContainer(spacing: DS.Spacing.s) {
                chipsScrollView(namespace: glassNamespace)
            }
            .clipShape(chipRowClipShape)
        } else {
            chipsScrollView(namespace: nil)
        }
    }

    @ViewBuilder
    private func chipsScrollView(namespace: Namespace.ID?) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
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
                            namespace: namespace
                        )
                        .onTapGesture { selectedCategoryID = cat.objectID }
                        .glassEffectTransitionIfNeeded(using: namespace)
                    }
                }
            }
            .padding(.horizontal, DS.Spacing.s)
        }
        .ub_hideScrollIndicators()
        .ub_disableHorizontalBounce()
        .clipped()
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func updateAddButtonWidth(_ width: CGFloat) {
        let quantized = (width * 2).rounded() / 2
        let tolerance: CGFloat = 0.5
        DispatchQueue.main.async {
            if abs(addButtonWidth - quantized) > tolerance {
                addButtonWidth = max(0, quantized)
            }
        }
    }
}

private extension View {
    @ViewBuilder
    func glassEffectTransitionIfNeeded(using namespace: Namespace.ID?) -> some View {
        if let namespace, #available(iOS 26.0, macOS 26.0, macCatalyst 26.0, *) {
            self.glassEffectTransition(.matchedGeometry)
        } else {
            self
        }
    }
}

// MARK: - AddCategoryPill
/// Compact, fixed “Add” control styled like a pill.
private struct AddCategoryPill: View {
    var onTap: () -> Void
    @EnvironmentObject private var themeManager: ThemeManager

    var body: some View {
        Button(action: onTap) {
            Label("Add", systemImage: "plus")
                .font(.subheadline.weight(.semibold))
        }
        .buttonStyle(
            AddCategoryPillStyle(
                tint: themeManager.selectedTheme.resolvedTint
            )
        )
        .controlSize(.regular)
        .accessibilityLabel("Add Category")
    }
}

// MARK: - CategoryChip
/// A single pill-shaped category with a color dot and name.
private struct CategoryChip: View {
    let id: String
    let name: String
    let colorHex: String
    let isSelected: Bool
    let namespace: Namespace.ID?
    @Environment(\.platformCapabilities) private var capabilities
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        let categoryColor = Color(hex: colorHex) ?? .secondary
        let style = CategoryChipStyle.make(
            isSelected: isSelected,
            categoryColor: categoryColor,
            colorScheme: colorScheme
        )

        let pill = CategoryChipPill(
            isSelected: isSelected,
            glassTint: style.glassTint,
            glassTextColor: style.glassTextColor,
            fallbackTextColor: style.fallbackTextColor,
            fallbackFill: style.fallbackFill,
            fallbackStrokeColor: style.fallbackStroke.color,
            fallbackStrokeLineWidth: style.fallbackStroke.lineWidth
        ) {
            HStack(spacing: DS.Spacing.s) {
                Circle()
                    .fill(categoryColor)
                    .frame(width: 10, height: 10)
                Text(name)
                    .font(.subheadline.weight(.semibold))
            }
        }
        let resolvedChip = Group {
            if capabilities.supportsOS26Translucency, #available(iOS 26.0, macCatalyst 26.0, *) {
                if let ns = namespace {
                    pill
                        .glassEffectID(id, in: ns)
                } else {
                    pill
                }
            } else {
                pill
            }
        }

        let base = resolvedChip
            .scaleEffect(style.scale)
            .animation(.easeOut(duration: 0.15), value: isSelected)
            .accessibilityAddTraits(isSelected ? .isSelected : [])

        let shouldApplyShadow = style.shadowRadius > 0 || style.shadowY != 0

//        if shouldApplyShadow {
//            base
//                .shadow(
//                    color: style.shadowColor,
//                    radius: style.shadowRadius,
//                    x: 0,
//                    y: style.shadowY
//                )
//        } else {
//            base
//        }
    }

}

// MARK: - Styles
private struct AddCategoryPillStyle: ButtonStyle {
    let tint: Color

    func makeBody(configuration: Configuration) -> some View {
        let isActive = configuration.isPressed

        let capsule = Capsule(style: .continuous)

        return CategoryChipPill(
            isSelected: false,
            glassTextColor: .primary,
            fallbackTextColor: .primary,
            fallbackFill: DS.Colors.chipFill,
            fallbackStrokeColor: DS.Colors.chipFill,
            fallbackStrokeLineWidth: 1
        ) {
            configuration.label
                .font(.subheadline.weight(.semibold))
        }
        .overlay {
            if isActive {
                capsule.strokeBorder(tint.opacity(0.35), lineWidth: 2)
            }
        }
        .animation(.easeOut(duration: 0.15), value: isActive)
    }
}

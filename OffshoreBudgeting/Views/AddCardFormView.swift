//
//  AddCardFormView.swift
//  SoFar
//
//  Cross-platform Add/Edit Card form.
//  - Live preview of the card
//  - Name text field
//  - Theme grid picker
//  - Save/Cancel actions (standardized via EditSheetScaffold)
//
//  Notes:
//  - Matches the Add Budget form’s scaffold, Section layout, and header styling.
//  - Section headers are gray + ALL CAPS + not bold for consistency.
//  - `onSave` closure is preserved to avoid breaking existing call sites.
//

import SwiftUI
import UIKit

// MARK: - AddCardFormView
/// Sheet that lets the user add or edit a card.
/// - Use `mode` to control title/buttons and initial values.
/// - Provide `editingCard` to prefill when editing.
/// - `onSave` returns the finalized name and theme.
struct AddCardFormView: View {

    // MARK: Mode
    /// Controls whether the form creates a new card or edits an existing one.
    enum Mode { case add, edit }

    // MARK: Configuration
    private let mode: Mode
    private let editingCard: CardItem?

    // MARK: Inputs
    /// Callback when user taps Save.
    /// - Parameters:
    ///   - name: The card name the user entered.
    ///   - theme: The selected theme.
    var onSave: (_ name: String, _ theme: CardTheme) -> Void

    // MARK: Init
    /// Designated initializer.
    /// - Parameters:
    ///   - mode: .add or .edit; controls title/buttons and initial values.
    ///   - editingCard: Optional existing card to prefill when editing.
    ///   - onSave: Callback invoked with (name, theme) when the user taps Save.
    init(
        mode: Mode = .add,
        editingCard: CardItem? = nil,
        onSave: @escaping (_ name: String, _ theme: CardTheme) -> Void
    ) {
        self.mode = mode
        self.editingCard = editingCard
        self.onSave = onSave
        // Prefill local state based on editing mode
        _cardName = State(initialValue: editingCard?.name ?? "")
        _selectedTheme = State(initialValue: editingCard?.theme ?? .rose)
    }

    // MARK: Local State
    @State private var cardName: String = ""
    @State private var selectedTheme: CardTheme = .rose
    @State private var saveErrorMessage: String?
    @State private var isMenuActive = false

    // MARK: Computed
    /// Trimmed card name for validation.
    private var trimmedName: String {
        cardName.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Whether the Save button should be enabled.
    private var canSave: Bool {
        !trimmedName.isEmpty
    }

    /// Live preview item for CardTileView. No Core Data identity is needed here.
    private var previewItem: CardItem {
        .init(
            objectID: nil,
            uuid: nil,
            name: trimmedName.isEmpty ? "New Card" : trimmedName,
            theme: selectedTheme
        )
    }

    // MARK: - Body
    /// Main view composition using a native NavigationStack + Form + toolbar.
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        navigationContainer {
            Form {
                // MARK: Form Content

            // ---- Preview
            Section {
                CardTileView(card: previewItem, enableMotionShine: true)
                    .padding(.vertical, DS.Spacing.m)
            } header: {
                // Gray, ALL CAPS, not bold — match Add Budget
                Text("Preview")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)
            }

            // ---- Name
            Section {
                // MARK: Cross-platform placeholder handling
                // On macOS inside a Form, TextField("Title", text:) can render as a static label.
                // Using the `prompt:` initializer ensures true placeholder styling.
                HStack(alignment: .center) {
                    if #available(iOS 15.0, macCatalyst 15.0, *) {
                        TextField("", text: $cardName, prompt: Text("Apple Card"))
                            .autocorrectionDisabled(true)
                            .textInputAutocapitalization(.never)
                            // Align to the leading edge and expand to fill the row
                            .multilineTextAlignment(.leading)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .submitLabel(.done)
                            .accessibilityLabel("Card Name")
                    } else {
                        TextField("Apple Card", text: $cardName)
                            .autocorrectionDisabled(true)
                            .textInputAutocapitalization(.never)
                            .multilineTextAlignment(.leading)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .submitLabel(.done)
                            .accessibilityLabel("Card Name")
                    }
                    Spacer(minLength: 0)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            } header: {
                Text("Name")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)
            }

            // ---- Theme
            Section {
                let columns = [GridItem(.adaptive(minimum: 120), spacing: DS.Spacing.m)]
                LazyVGrid(columns: columns, spacing: DS.Spacing.m) {
                    ForEach(CardTheme.allCases) { theme in
                        ThemeSwatch(theme: theme, isSelected: theme == selectedTheme)
                            .onTapGesture { selectedTheme = theme }
                    }
                }
                .padding(.vertical, DS.Spacing.s)
            } header: {
                Text("Theme")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)
            }
            }
            .listStyle(.insetGrouped)
            .scrollIndicators(.hidden)
            .navigationTitle(mode == .add ? "Add Card" : "Edit Card")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(mode == .add ? "Create Card" : "Save Changes") {
                        if saveTapped() { dismiss() }
                    }
                    .disabled(!canSave)
                }
            }
        }
        .applyDetentsIfAvailable(detents: [.medium, .large], selection: nil)
        .onAppear { isMenuActive = true }
        .onDisappear { isMenuActive = false }
        // Error alert (if validation or save logic fails)
        .alert("Error", isPresented: .constant(saveErrorMessage != nil), actions: {
            Button("OK", role: .cancel) { saveErrorMessage = nil }
        }, message: {
            Text(saveErrorMessage ?? "")
        })
        .focusedSceneValue(
            \.formCommands,
            isMenuActive ? FormCommands(
                saveTitle: mode == .add ? "Create Card" : "Save Changes",
                canSave: canSave,
                save: {
                    if saveTapped() { dismiss() }
                },
                cancelTitle: "Cancel",
                cancel: { dismiss() }
            ) : nil
        )
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

    // MARK: - Actions

    // MARK: saveTapped()
    /// Validates inputs, emits (name, theme) to caller, and returns `true` to allow the scaffold to dismiss.
    /// - Returns: `true` if the sheet should dismiss; `false` to keep it open (e.g., on validation error).
    private func saveTapped() -> Bool {
        guard canSave else {
            saveErrorMessage = "Please enter a card name."
            return false
        }
        onSave(trimmedName, selectedTheme)
        // iOS: nicely resign keyboard for a neat dismissal experience.
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        return true
    }
}

// MARK: - ThemeSwatch
/// Small preview of a theme used in the picker.
/// - Parameters:
///   - theme: The theme represented by the swatch.
///   - isSelected: Whether the swatch is currently selected; adds a glow ring if true.
private struct ThemeSwatch: View {
    let theme: CardTheme
    let isSelected: Bool
    @EnvironmentObject private var themeManager: ThemeManager

    var body: some View {
        ZStack {
            // Background: theme gradient + subtle outline
            ZStack {
                RoundedRectangle(cornerRadius: DS.Radius.card, style: .continuous)
                    .fill(theme.backgroundStyle(for: themeManager.selectedTheme))
                RoundedRectangle(cornerRadius: DS.Radius.card, style: .continuous)
                    .stroke(Color.white.opacity(0.06), lineWidth: 1)
            }
            .frame(height: 72)

            // Metallic/holographic text preview
            HolographicMetallicText(
                text: theme.displayName,
                titleFont: .headline
            )
        }
        // Selection ring + color-matched glow
        .overlay(
            RoundedRectangle(cornerRadius: DS.Radius.card)
                .stroke(isSelected ? theme.glowColor : Color.primary.opacity(0.15), lineWidth: isSelected ? 2 : 1)
                .shadow(color: theme.glowColor.opacity(isSelected ? 0.55 : 0), radius: isSelected ? 12 : 0)
                .shadow(color: theme.glowColor.opacity(isSelected ? 0.30 : 0), radius: isSelected ? 24 : 0)
                .shadow(color: theme.glowColor.opacity(isSelected ? 0.18 : 0), radius: isSelected ? 36 : 0)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Text("\(theme.displayName) theme"))
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

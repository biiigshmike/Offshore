//
//  AddCardFormView.swift
//  SoFar
//
//  Cross-platform Add/Edit Card form.
//  - Live preview of the card
//  - Name text field
//  - Effect picker
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
    ///   - effect: The selected effect.
    var onSave: (_ name: String, _ theme: CardTheme, _ effect: CardEffect) -> Void

    // MARK: Init
    /// Designated initializer.
    /// - Parameters:
    ///   - mode: .add or .edit; controls title/buttons and initial values.
    ///   - editingCard: Optional existing card to prefill when editing.
    ///   - onSave: Callback invoked with (name, theme) when the user taps Save.
    init(
        mode: Mode = .add,
        editingCard: CardItem? = nil,
        onSave: @escaping (_ name: String, _ theme: CardTheme, _ effect: CardEffect) -> Void
    ) {
        self.mode = mode
        self.editingCard = editingCard
        self.onSave = onSave
        // Prefill local state based on editing mode
        _cardName = State(initialValue: editingCard?.name ?? "")
        _selectedTheme = State(initialValue: editingCard?.theme ?? .rose)
        _selectedEffect = State(initialValue: editingCard?.effect ?? .plastic)
    }

    // MARK: Local State
    @State private var cardName: String = ""
    @State private var selectedTheme: CardTheme = .rose
    @State private var selectedEffect: CardEffect = .plastic
    @State private var saveErrorMessage: String?

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
            theme: selectedTheme,
            effect: selectedEffect
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
                CardTileView(card: previewItem, enableMotionShine: true, showsEffectOverlay: true)
                    .padding(.vertical, Spacing.m)
            } header: {
                // Gray, ALL CAPS, not bold — match Add Budget
                Text("Preview")
                    .font(Typography.footnote)
                    .foregroundStyle(Colors.styleSecondary)
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
                    .font(Typography.footnote)
                    .foregroundStyle(Colors.styleSecondary)
                    .textCase(.uppercase)
            }

            // ---- Effect
            Section {
                let columns = [GridItem(.adaptive(minimum: 120), spacing: Spacing.m)]
                LazyVGrid(columns: columns, spacing: Spacing.m) {
                    ForEach(CardEffect.allCases) { effect in
                        EffectSwatch(effect: effect, theme: selectedTheme, isSelected: effect == selectedEffect)
                            .onTapGesture { selectedEffect = effect }
                    }
                }
                .padding(.vertical, Spacing.s)
            } header: {
                Text("Effect")
                    .font(Typography.footnote)
                    .foregroundStyle(Colors.styleSecondary)
                    .textCase(.uppercase)
            }

            // ---- Theme
            Section {
                let columns = [GridItem(.adaptive(minimum: 120), spacing: Spacing.m)]
                LazyVGrid(columns: columns, spacing: Spacing.m) {
                    ForEach(CardTheme.allCases) { theme in
                        ThemeSwatch(theme: theme, isSelected: theme == selectedTheme)
                            .onTapGesture { selectedTheme = theme }
                    }
                }
                .padding(.vertical, Spacing.s)
            } header: {
                Text("Theme")
                    .font(Typography.footnote)
                    .foregroundStyle(Colors.styleSecondary)
                    .textCase(.uppercase)
            }
            }
            .listStyle(.insetGrouped)
            .scrollIndicators(.hidden)
            .navigationTitle(mode == .add ? "Add Card" : "Edit Card")
            .ub_windowTitle(mode == .add ? "Add Card" : "Edit Card")
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
        // Error alert (if validation or save logic fails)
        .alert("Error", isPresented: .constant(saveErrorMessage != nil), actions: {
            Button("OK", role: .cancel) { saveErrorMessage = nil }
        }, message: {
            Text(saveErrorMessage ?? "")
        })
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
        onSave(trimmedName, selectedTheme, selectedEffect)
        // iOS: nicely resign keyboard for a neat dismissal experience.
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        return true
    }
}

// MARK: - EffectSwatch
/// Small preview of an effect used in the picker.
/// - Parameters:
///   - effect: The effect represented by the swatch.
///   - theme: Background theme used behind the effect overlay.
///   - isSelected: Whether the swatch is currently selected; adds a glow ring if true.
private struct EffectSwatch: View {
    let effect: CardEffect
    let theme: CardTheme
    let isSelected: Bool
    @EnvironmentObject private var themeManager: ThemeManager
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.colorSchemeContrast) private var colorSchemeContrast
    @ScaledMetric(relativeTo: .body) private var swatchMinHeight: CGFloat = 72

    var body: some View {
        ZStack {
            ZStack {
                RoundedRectangle(cornerRadius: Radius.card, style: .continuous)
                    .fill(theme.backgroundStyle(for: themeManager.selectedTheme))
                RoundedRectangle(cornerRadius: Radius.card, style: .continuous)
                    .fill(theme.adaptiveOverlay(for: colorScheme, isHighContrast: colorSchemeContrast == .increased))
                theme
                    .patternOverlay(cornerRadius: Radius.card)
                    .blendMode(.overlay)
                CardMaterialBackground(
                    theme: theme,
                    effect: effect,
                    cornerRadius: Radius.card,
                    enableMotion: false
                )
                RoundedRectangle(cornerRadius: Radius.card, style: .continuous)
                    .stroke(Colors.whiteOpacity006, lineWidth: 1)
            }
            .frame(minHeight: swatchMinHeight)

            Text(effect.displayName)
                .font(.headline)
                .foregroundStyle(UBTypography.cardTitleStatic)
                .ub_cardTitleShadow()
        }
        .overlay(
            RoundedRectangle(cornerRadius: Radius.card)
                .stroke(isSelected ? theme.glowColor : Colors.primaryOpacity015, lineWidth: isSelected ? 2 : 1)
                .shadow(color: theme.glowColor.opacity(isSelected ? 0.55 : 0), radius: isSelected ? 12 : 0)
                .shadow(color: theme.glowColor.opacity(isSelected ? 0.30 : 0), radius: isSelected ? 24 : 0)
                .shadow(color: theme.glowColor.opacity(isSelected ? 0.18 : 0), radius: isSelected ? 36 : 0)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Text("\(effect.displayName) effect"))
        .accessibilityAddTraits(isSelected ? .isSelected : [])
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
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.colorSchemeContrast) private var colorSchemeContrast
    @ScaledMetric(relativeTo: .body) private var swatchMinHeight: CGFloat = 72

    var body: some View {
        ZStack {
            // Background: theme gradient + subtle outline
            ZStack {
                RoundedRectangle(cornerRadius: Radius.card, style: .continuous)
                    .fill(theme.backgroundStyle(for: themeManager.selectedTheme))
                RoundedRectangle(cornerRadius: Radius.card, style: .continuous)
                    .fill(theme.adaptiveOverlay(for: colorScheme, isHighContrast: colorSchemeContrast == .increased))
                RoundedRectangle(cornerRadius: Radius.card, style: .continuous)
                    .stroke(Colors.whiteOpacity006, lineWidth: 1)
            }
            .frame(minHeight: swatchMinHeight)

            // Metallic/holographic text preview
            HolographicMetallicText(
                text: theme.displayName,
                titleFont: .headline
            )
        }
        // Selection ring + color-matched glow
        .overlay(
            RoundedRectangle(cornerRadius: Radius.card)
                .stroke(isSelected ? theme.glowColor : Colors.primaryOpacity015, lineWidth: isSelected ? 2 : 1)
                .shadow(color: theme.glowColor.opacity(isSelected ? 0.55 : 0), radius: isSelected ? 12 : 0)
                .shadow(color: theme.glowColor.opacity(isSelected ? 0.30 : 0), radius: isSelected ? 24 : 0)
                .shadow(color: theme.glowColor.opacity(isSelected ? 0.18 : 0), radius: isSelected ? 36 : 0)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Text("\(theme.displayName) theme"))
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

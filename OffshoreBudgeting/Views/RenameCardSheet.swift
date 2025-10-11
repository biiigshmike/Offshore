//
//  RenameCardSheet.swift
//  SoFar
//
//  Minimal rename UI used by CardsView.
//  Now uses native NavigationStack + Form + toolbar.
//

import SwiftUI

// MARK: - RenameCardSheet
/// Simple sheet with a text field to rename a card.
/// - Parameters:
///   - originalName: Prefills the field.
///   - onSave: Callback with the new name when user taps Save.
struct RenameCardSheet: View {
    let originalName: String
    var onSave: (String) -> Void

    // MARK: State
    @State private var name: String = ""

    // MARK: body
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        navigationContainer {
            Form {
                // MARK: Name field
                HStack(alignment: .center) {
                    TextField(
                        "", text: $name,
                        prompt: Text("Card Name"))
                        .autocorrectionDisabled(true)
                        .textInputAutocapitalization(.never)
                        .onAppear { name = originalName }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Spacer(minLength: 0)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .listStyle(.insetGrouped)
            .scrollIndicators(.hidden)
            .navigationTitle("Rename Card")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        guard !trimmedName.isEmpty else { return }
                        onSave(trimmedName)
                        dismiss()
                    }
                    .disabled(trimmedName.isEmpty)
                }
            }
        }
        .applyDetentsIfAvailable(detents: [.fraction(0.25), .medium], selection: nil)
    }

    // MARK: Helpers
    private var trimmedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

// MARK: - Navigation container
private extension RenameCardSheet {
    @ViewBuilder
    func navigationContainer<Inner: View>(@ViewBuilder content: () -> Inner) -> some View {
        if #available(iOS 16.0, macCatalyst 16.0, *) {
            NavigationStack { content() }
        } else {
            NavigationView { content() }
        }
    }
}

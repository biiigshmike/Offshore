import SwiftUI

/// Step 2: Navigation shell for editing category caps.
/// This view wires Cancel/Save navigation buttons and basic scaffolding.
/// Actual min/max fields and persistence will be added in Step 4.
struct EditCategoryCapsView: View {
    let categoryName: String
    let categoryURI: URL
    let categoryHex: String?

    var onCancel: () -> Void
    var onSaved: () -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        content
            .navigationTitle("Edit Caps")
            .ub_windowTitle("Edit Caps")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { toolbar }
            .onAppear { /* placeholder for future data load */ }
    }

    private var content: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 10) {
                Circle()
                    .fill(UBColorFromHex(categoryHex) ?? .secondary)
                    .frame(width: 12, height: 12)
                Text(categoryName)
                    .font(.headline)
            }
            .padding(.top, 8)

            Text("Editor coming next: set Minimum and Maximum for this category.")
                .foregroundStyle(.secondary)

            Spacer()
        }
        .padding()
    }

    @ToolbarContentBuilder
    private var toolbar: some ToolbarContent {
        ToolbarItem(placement: .cancellationAction) {
            Button("Cancel") {
                onCancel()
                dismiss()
            }
        }
        ToolbarItem(placement: .confirmationAction) {
            Button("Save") {
                // Step 2: No persistence yet; just pop
                onSaved()
                dismiss()
            }
        }
    }
}

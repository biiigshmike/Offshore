import SwiftUI
import CoreData

// MARK: - ExpenseCategoryChipsRow
@available(*, deprecated, message: "Use DesignSystem CategoryChips")
struct ExpenseCategoryChipsRow: View {
    @Binding var selectedCategoryID: NSManagedObjectID?

    var body: some View {
        DesignSystemV2.ExpenseCategoryChipsRow(selectedCategoryID: $selectedCategoryID)
    }
}

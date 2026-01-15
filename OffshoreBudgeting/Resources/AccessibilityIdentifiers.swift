import Foundation

// MARK: - AccessibilityRowIdentifier
@available(*, deprecated, message: "Use AccessibilityID (DesignSystem/v2)")
enum AccessibilityRowIdentifier {
    static func budgetRow(id: UUID?) -> String {
        AccessibilityID.Budgets.budgetRow(id: id)
    }

    static func plannedRow(id: UUID?) -> String {
        AccessibilityID.Home.plannedRow(id: id)
    }

    static func unplannedRow(id: UUID?) -> String {
        AccessibilityID.Home.unplannedRow(id: id)
    }

    static func cardExpenseRow(id: UUID?) -> String {
        AccessibilityID.Cards.Detail.cardExpenseRow(id: id)
    }

    static func incomeRow(id: UUID?) -> String {
        AccessibilityID.Income.incomeRow(id: id)
    }

    static func categoryRow(id: UUID?) -> String {
        AccessibilityID.Settings.Categories.categoryRow(id: id)
    }

    static func presetRow(id: UUID?) -> String {
        AccessibilityID.Settings.Presets.presetRow(id: id)
    }
}

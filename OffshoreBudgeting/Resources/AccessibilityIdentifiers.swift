import Foundation

// MARK: - AccessibilityRowIdentifier
enum AccessibilityRowIdentifier {
    static func budgetRow(id: UUID?) -> String {
        guard let id else { return "budget_row_missing_uuid" }
        return "budget_row_\(id.uuidString)"
    }

    static func plannedRow(id: UUID?) -> String {
        guard let id else { return "planned_row_missing_uuid" }
        return "planned_row_\(id.uuidString)"
    }

    static func unplannedRow(id: UUID?) -> String {
        guard let id else { return "unplanned_row_missing_uuid" }
        return "unplanned_row_\(id.uuidString)"
    }

    static func cardExpenseRow(id: UUID?) -> String {
        guard let id else { return "card_expense_row_missing_uuid" }
        return "card_expense_row_\(id.uuidString)"
    }

    static func incomeRow(id: UUID?) -> String {
        guard let id else { return "row_income_missing_uuid" }
        return "row_income_\(id.uuidString)"
    }

    static func categoryRow(id: UUID?) -> String {
        guard let id else { return "category_row_id_missing_uuid" }
        return "category_row_id_\(id.uuidString)"
    }

    static func presetRow(id: UUID?) -> String {
        guard let id else { return "preset_row_missing_uuid" }
        return "preset_row_\(id.uuidString)"
    }
}

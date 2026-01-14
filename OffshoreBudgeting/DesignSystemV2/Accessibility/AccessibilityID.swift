import Foundation

// MARK: - AccessibilityID
enum AccessibilityID {
    enum Budgets {
        static let screen = "budgets_screen"
        static let detailsScreen = "budget_details_screen"
        static let deleteButton = "budget_delete_button"
        static let overflowMenu = "budget_overflow_menu"

        static func budgetRow(id: UUID?) -> String {
            guard let id else { return "budget_row_missing_uuid" }
            return "budget_row_\(id.uuidString)"
        }
    }

    enum Income {
        static let addButton = "btn_add_income"

        enum CalendarNav {
            static let previousMonthButton = "btn_income_calendar_previous_month"
            static let previousDayButton = "btn_income_calendar_previous_day"
            static let todayButton = "btn_income_calendar_today"
            static let nextDayButton = "btn_income_calendar_next_day"
            static let nextMonthButton = "btn_income_calendar_next_month"
        }

        enum UITest {
            static let deleteFirstIncomeButton = "btn_delete_first_income"

            static func deleteIncomeButton(id: String?) -> String {
                guard let id, !id.isEmpty else { return "btn_delete_income_missing_uuid" }
                return "btn_delete_income_\(id)"
            }
        }

        enum Form {
            static let confirmButton = "btn_confirm"
            static let typeSegmentedControl = "incomeTypeSegmentedControl"
            static let sourceField = "txt_income_source"
            static let amountField = "txt_income_amount"
            static let firstDatePicker = "incomeFirstDatePicker"
        }
    }

    enum Settings {
        static let manageCategoriesNavigation = "nav_manage_categories"
        static let managePresetsNavigation = "nav_manage_presets"

        enum Privacy {
            static let appLockToggle = "toggle_app_lock"
            static let appLockUITestState = "app_lock_ui_test_state"
        }

        enum Categories {
            static let addButton = "categories_add_button"
            static let nameField = "categories_name_field"
            static let cancelButton = "categories_cancel_button"
            static let saveButton = "categories_save_button"

            static func categoryRow(id: UUID?) -> String {
                guard let id else { return "category_row_id_missing_uuid" }
                return "category_row_id_\(id.uuidString)"
            }
        }

        enum Presets {
            static let screen = "presets_screen"

            static func presetRow(id: UUID?) -> String {
                guard let id else { return "preset_row_missing_uuid" }
                return "preset_row_\(id.uuidString)"
            }
        }
    }

    enum Cards {
        static let screen = "cards_screen"

        enum Detail {
            static let screen = "card_details_screen"
        }

        enum List {
            static func cardRow(id: String) -> String {
                "card_row_\(id)"
            }
        }

        enum Tile {
            static func cardTile(id: String) -> String {
                "card_tile_\(id)"
            }
        }
    }

    enum ExpenseImport {
        static let screen = "expense_import_screen"
        static let list = "expense_import_list"

        static let cancelButton = "btn_expense_import_cancel"
        static let addCategoryButton = "btn_expense_import_add_category"
        static let selectButton = "btn_expense_import_select"
        static let selectAllButton = "btn_expense_import_select_all"
        static let deselectAllButton = "btn_expense_import_deselect_all"
        static let importButton = "btn_expense_import_import"

        enum Section {
            static let readyForImportHeader = "expense_import_section_ready_for_import"
            static let possibleMatchesHeader = "expense_import_section_possible_matches"
            static let possibleDuplicatesHeader = "expense_import_section_possible_duplicates"
            static let needsMoreDataHeader = "expense_import_section_needs_more_data"
            static let paymentsHeader = "expense_import_section_payments"
            static let creditsHeader = "expense_import_section_credits"
        }

        static func row(id: UUID?) -> String {
            guard let id else { return "expense_import_row_missing_uuid" }
            return "expense_import_row_\(id.uuidString)"
        }

        static func rowCategoryMenu(id: UUID?) -> String {
            guard let id else { return "expense_import_row_category_menu_missing_uuid" }
            return "expense_import_row_category_menu_\(id.uuidString)"
        }
    }
}

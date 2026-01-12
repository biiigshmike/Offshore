import Foundation

// MARK: - AccessibilityID
enum AccessibilityID {
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
}

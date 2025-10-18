import SwiftUI

// MARK: - UITesting Flags
struct UITestingFlags {
    var isUITesting: Bool
    var showTestControls: Bool
}

private struct UITestingFlagsKey: EnvironmentKey {
    static let defaultValue = UITestingFlags(isUITesting: false, showTestControls: false)
}

extension EnvironmentValues {
    var uiTestingFlags: UITestingFlags {
        get { self[UITestingFlagsKey.self] }
        set { self[UITestingFlagsKey.self] = newValue }
    }
}

// MARK: - Start Tab Identifier (for -ui-testing)
private struct StartTabIdentifierKey: EnvironmentKey {
    static let defaultValue: String? = nil
}

extension EnvironmentValues {
    /// Optional string identifier for the tab to select at launch during UI tests.
    /// Expected values: "home", "income", "cards", "presets", "settings".
    var startTabIdentifier: String? {
        get { self[StartTabIdentifierKey.self] }
        set { self[StartTabIdentifierKey.self] = newValue }
    }
}


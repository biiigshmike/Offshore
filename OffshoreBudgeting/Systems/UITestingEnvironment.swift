import SwiftUI

// MARK: - UITesting Flags
struct UITestingFlags {
    var isUITesting: Bool
    var showTestControls: Bool
    var allowAppLock: Bool
    var deviceAuthAvailableOverride: Bool?
    var biometricAuthResult: UITestBiometricAuthResult?
    var cloudAccountAvailableOverride: Bool?
    var cloudDataExistsOverride: Bool?
}

enum UITestBiometricAuthResult: String {
    case success
    case failure
    case cancel
}

private struct UITestingFlagsKey: EnvironmentKey {
    static let defaultValue = UITestingFlags(
        isUITesting: false,
        showTestControls: false,
        allowAppLock: false,
        deviceAuthAvailableOverride: nil,
        biometricAuthResult: nil,
        cloudAccountAvailableOverride: nil,
        cloudDataExistsOverride: nil
    )
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

// MARK: - Start Route Identifier (for -ui-testing)
private struct StartRouteIdentifierKey: EnvironmentKey {
    static let defaultValue: String? = nil
}

extension EnvironmentValues {
    /// Optional string identifier for the screen to show at launch during UI tests.
    /// Expected values: "categories".
    var startRouteIdentifier: String? {
        get { self[StartRouteIdentifierKey.self] }
        set { self[StartRouteIdentifierKey.self] = newValue }
    }
}

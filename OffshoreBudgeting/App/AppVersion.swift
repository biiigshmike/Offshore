import Foundation

// MARK: - AppVersion
struct AppVersion: Sendable {
    static let shared = AppVersion(bundle: .main)

    let displayName: String
    let versionString: String
    let buildString: String
    let versionToken: String?

    /// Title used for “What’s New” sheets (must match existing text formatting).
    let displayTitle: String

    /// Convenience string used in Settings “About” UI (must match existing text formatting).
    let settingsLine: String

    init(bundle: Bundle) {
        let info = bundle.infoDictionary
        let rawDisplayName = (info?["CFBundleDisplayName"] as? String).flatMap { $0.isEmpty ? nil : $0 }
        let rawBundleName = (info?["CFBundleName"] as? String).flatMap { $0.isEmpty ? nil : $0 }
        displayName = rawDisplayName ?? rawBundleName ?? "App"

        let rawVersion = (info?["CFBundleShortVersionString"] as? String).flatMap { $0.isEmpty ? nil : $0 }
        let rawBuild = (info?["CFBundleVersion"] as? String).flatMap { $0.isEmpty ? nil : $0 }

        let versionForWhatsNew = rawVersion ?? "0"
        let buildForWhatsNew = rawBuild ?? "0"
        versionString = versionForWhatsNew
        buildString = buildForWhatsNew
        displayTitle = "What's New • \(versionForWhatsNew) (Build \(buildForWhatsNew))"

        let versionForSettings = rawVersion ?? "-"
        let buildForSettings = rawBuild ?? "-"
        settingsLine = "Version \(versionForSettings) • Build \(buildForSettings)"

        if let rawVersion, let rawBuild {
            versionToken = "\(rawVersion).\(rawBuild)"
        } else {
            versionToken = nil
        }
    }
}

import SwiftUI

// MARK: - App Update Logs
enum AppUpdateLogs {
    struct AppUpdateLogEntry: Identifiable {
        let versionToken: String
        let content: TipsContent

        var id: String { versionToken }
    }

    // MARK: - Version Token Format (Release Log Titles)
    // SettingsView.releaseTitle(for:) parses the token by splitting on "."
    // - The final component is treated as the build number.
    // - All preceding components are joined back into the display version string.
    //
    // Examples:
    // - Version 2.1 (Build 2) -> "2.1.2"
    // - Version 2.0.1 (Build 5) -> "2.0.1.5"
    //
    // Keep tokens consistent across `content(for:)` and `releaseLogs` so the
    // What's New title and Release Logs list stay aligned.
    static func content(for screen: TipsScreen, versionToken: String?) -> TipsContent? {
        guard let versionToken else { return nil }
        switch versionToken {
        case "2.1.1.1":
            return AppUpdateLog_2_1_1.content(for: screen)
        case "2.1.4":
            return AppUpdateLog_2_1.content(for: screen)
        case "2.0.1.1":
            return AppUpdateLog_2_0_1.content(for: screen)
        case "2.0.1":
            return AppUpdateLog_2_0.content(for: screen)
        default:
            return nil
        }
    }

    // MARK: - Release Logs Source (Newest First)
    static var releaseLogs: [AppUpdateLogEntry] {
        let candidates: [(String, TipsContent?)] = [
            ("2.1.1.1", AppUpdateLog_2_1_1.content(for: .home)),
            ("2.1.4", AppUpdateLog_2_1.content(for: .home)),
            ("2.0.1.1", AppUpdateLog_2_0_1.content(for: .home)),
            ("2.0.1", AppUpdateLog_2_0.content(for: .home))
        ]

        return candidates.compactMap { versionToken, content in
            guard let content else { return nil }
            return AppUpdateLogEntry(versionToken: versionToken, content: content)
        }
    }
}

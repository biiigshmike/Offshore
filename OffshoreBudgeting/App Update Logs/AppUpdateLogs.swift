import SwiftUI

// MARK: - App Update Logs
enum AppUpdateLogs {
    struct AppUpdateLogEntry: Identifiable {
        let versionToken: String
        let content: TipsContent

        var id: String { versionToken }
    }

    static func content(for screen: TipsScreen, versionToken: String?) -> TipsContent? {
        guard let versionToken else { return nil }
        switch versionToken {
        case "2.1":
            return AppUpdateLog_2_1.content(for: screen)
        case "2.0.1":
            return AppUpdateLog_2_0_1.content(for: screen)
        default:
            return nil
        }
    }

    static var releaseLogs: [AppUpdateLogEntry] {
        let candidates: [(String, TipsContent?)] = [
            ("2.1", AppUpdateLog_2_1.content(for: .home)),
            ("2.0.1", AppUpdateLog_2_0_1.content(for: .home))
        ]

        return candidates.compactMap { versionToken, content in
            guard let content else { return nil }
            return AppUpdateLogEntry(versionToken: versionToken, content: content)
        }
    }
}

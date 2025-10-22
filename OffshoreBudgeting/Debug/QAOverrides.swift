#if DEBUG
import Foundation

enum QAOverrides {
    private static let forceTourOverlayKey = "GuidedTour.forceOverlaysOnce"

    static func applyOnLaunch() {
        let defaults = UserDefaults.standard
        if defaults.bool(forKey: forceTourOverlayKey) {
            defaults.set(false, forKey: forceTourOverlayKey)
            GuidedTourState.shared.forceAllOverlaysOnce()
            AppLog.ui.debug("QAOverrides applyOnLaunch forced guided tour overlays via defaults")
        }

        if ProcessInfo.processInfo.environment["UB_FORCE_GUIDED_TOUR"] == "1" {
            GuidedTourState.shared.forceAllOverlaysOnce()
            AppLog.ui.debug("QAOverrides applyOnLaunch forced guided tour overlays via env")
        }
    }

    static func scheduleGuidedTourRefresh() {
        UserDefaults.standard.set(true, forKey: forceTourOverlayKey)
    }
}
#endif

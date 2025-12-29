import Foundation
#if canImport(WidgetKit)
import WidgetKit
#endif

// MARK: - WidgetRefreshCoordinator
/// Centralizes lightweight WidgetKit refresh calls.
enum WidgetRefreshCoordinator {
    static func refreshAllTimelines() {
        #if canImport(WidgetKit)
        WidgetCenter.shared.reloadAllTimelines()
        #endif
    }
}

import UIKit
import CloudKit

/// Bridges remote notification callbacks into a SwiftUI App.
/// NSPersistentCloudKitContainer handles CloudKit pushes automatically; we
/// acknowledge them so the system grants background time for imports.
final class OffshoreAppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        application.setMinimumBackgroundFetchInterval(UIApplication.backgroundFetchIntervalMinimum)
        true
    }

    func application(_ application: UIApplication,
                     performFetchWithCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        WidgetRefreshCoordinator.refreshAllTimelines()
        completionHandler(.noData)
    }

    func application(_ application: UIApplication,
                     didReceiveRemoteNotification userInfo: [AnyHashable : Any],
                     fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        // If this is a CloudKit push, let the system know there is potentially new data.
        if CKNotification(fromRemoteNotificationDictionary: userInfo) != nil {
            completionHandler(.newData)
        } else {
            completionHandler(.noData)
        }
    }

    func application(_ application: UIApplication,
                     didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        // No-op; CloudKit silent pushes do not require the token here.
    }

    func application(_ application: UIApplication,
                     didFailToRegisterForRemoteNotificationsWithError error: Error) {
        // Non-fatal; the app will still function locally.
        AppLog.iCloud.error("Failed to register for remote notifications: \(String(describing: error))")
    }
}

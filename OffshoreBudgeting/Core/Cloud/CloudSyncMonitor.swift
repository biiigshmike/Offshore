import Foundation
import CoreData

/// Observes NSPersistentCloudKitContainer events and exposes a simple
/// signal for whether the initial import has completed after enabling Cloud.
@MainActor
final class CloudSyncMonitor: ObservableObject {
    static let shared = CloudSyncMonitor()

    @Published private(set) var initialImportCompleted: Bool = false
    @Published private(set) var isImporting: Bool = false

    private var observer: NSObjectProtocol?

    private init() {
        observer = NotificationCenter.default.addObserver(
            forName: CloudStatus.cloudKitEventChangedNotification,
            object: nil,
            queue: .main
        ) { [weak self] note in
            guard let event = note.userInfo?[NSPersistentCloudKitContainer.eventNotificationUserInfoKey] as? NSPersistentCloudKitContainer.Event else { return }
            Task { @MainActor [weak self] in
                guard let self else { return }
                switch event.type {
                case .import:
                    // Track import activity and completion
                    self.isImporting = !(event.succeeded && event.endDate != nil)
                    if event.succeeded, event.endDate != nil { self.initialImportCompleted = true }
                case .setup:
                    break
                default:
                    break
                }
            }
        }
    }

    deinit { if let observer { NotificationCenter.default.removeObserver(observer) } }

    /// Await initial import completion with a timeout.
    func awaitInitialImport(timeout: TimeInterval = 10.0, pollInterval: TimeInterval = 0.1) async -> Bool {
        if initialImportCompleted { return true }
        let start = Date()
        while !initialImportCompleted {
            if Date().timeIntervalSince(start) > timeout { return false }
            try? await Task.sleep(nanoseconds: UInt64(pollInterval * 1_000_000_000))
        }
        return true
    }
}

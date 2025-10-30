//
//  CoreDataEntityChangeMonitorTests.swift
//  OffshoreBudgetingTests
//

import XCTest
import CoreData
#if canImport(Offshore)
@testable import Offshore
#elseif canImport(OffshoreBudgeting)
@testable import OffshoreBudgeting
#elseif canImport(SoFar)
@testable import SoFar
#else
#error("App module not found. Ensure the test target depends on the app target and update the conditional import.")
#endif

final class CoreDataEntityChangeMonitorTests: XCTestCase {
    func testMergeNotificationWithRefreshedIDsTriggersCallback() {
        let stack = TestCoreDataStack()
        let context = stack.container.viewContext

        let card = NSEntityDescription.insertNewObject(forEntityName: "Card", into: context)
        let objectID = card.objectID

        let expectation = expectation(description: "onRelevantChange fired")
        expectation.assertForOverFulfill = true

        let monitor = CoreDataEntityChangeMonitor(entityNames: ["Card"], debounceMilliseconds: 0) {
            expectation.fulfill()
        }

        let notificationUserInfo: [AnyHashable: Any] = [NSRefreshedObjectIDsKey: [objectID]]

        NotificationCenter.default.post(
            name: .NSManagedObjectContextDidMergeChangesObjectIDs,
            object: nil,
            userInfo: notificationUserInfo
        )

#if os(macOS)
        NotificationCenter.default.post(
            name: .NSManagedObjectContextDidMergeChangesObjectIDs,
            object: nil,
            userInfo: notificationUserInfo
        )
#endif

        wait(for: [expectation], timeout: 1)
        withExtendedLifetime(monitor) {}
    }
}

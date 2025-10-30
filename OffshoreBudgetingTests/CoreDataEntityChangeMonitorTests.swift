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

    func testNotificationsWithDifferentObjectIDsDoNotDeduplicate() {
        let stack = TestCoreDataStack()
        let context = stack.container.viewContext

        let firstCard = NSEntityDescription.insertNewObject(forEntityName: "Card", into: context)
        let secondCard = NSEntityDescription.insertNewObject(forEntityName: "Card", into: context)

        let expectation = expectation(description: "onRelevantChange fired twice")
        expectation.expectedFulfillmentCount = 2
        expectation.assertForOverFulfill = true

        let monitor = CoreDataEntityChangeMonitor(entityNames: ["Card"], debounceMilliseconds: 0) {
            expectation.fulfill()
        }

        NotificationCenter.default.post(
            name: .NSManagedObjectContextDidMergeChangesObjectIDs,
            object: context,
            userInfo: [NSUpdatedObjectIDsKey: [firstCard.objectID]]
        )

        NotificationCenter.default.post(
            name: .NSManagedObjectContextDidMergeChangesObjectIDs,
            object: context,
            userInfo: [NSUpdatedObjectIDsKey: [secondCard.objectID]]
        )

        wait(for: [expectation], timeout: 1)
        withExtendedLifetime(monitor) {}
    }

    func testHomeEntitySetNotificationsDeduplicateButUniquePayloadsTriggerRefresh() {
        let stack = TestCoreDataStack()
        let context = stack.container.viewContext

        let budget = NSEntityDescription.insertNewObject(forEntityName: "Budget", into: context)
        let plannedExpense = NSEntityDescription.insertNewObject(forEntityName: "PlannedExpense", into: context)
        let unplannedExpense = NSEntityDescription.insertNewObject(forEntityName: "UnplannedExpense", into: context)
        let income = NSEntityDescription.insertNewObject(forEntityName: "Income", into: context)
        let expenseCategory = NSEntityDescription.insertNewObject(forEntityName: "ExpenseCategory", into: context)
        let card = NSEntityDescription.insertNewObject(forEntityName: "Card", into: context)

        let duplicateUserInfo: [AnyHashable: Any] = [
            NSInsertedObjectIDsKey: [budget.objectID, income.objectID],
            NSUpdatedObjectIDsKey: [plannedExpense.objectID, card.objectID],
            NSDeletedObjectIDsKey: [unplannedExpense.objectID, expenseCategory.objectID],
        ]

        let newBudget = NSEntityDescription.insertNewObject(forEntityName: "Budget", into: context)
        let newPlannedExpense = NSEntityDescription.insertNewObject(forEntityName: "PlannedExpense", into: context)
        let newUnplannedExpense = NSEntityDescription.insertNewObject(forEntityName: "UnplannedExpense", into: context)
        let newIncome = NSEntityDescription.insertNewObject(forEntityName: "Income", into: context)
        let newExpenseCategory = NSEntityDescription.insertNewObject(forEntityName: "ExpenseCategory", into: context)
        let newCard = NSEntityDescription.insertNewObject(forEntityName: "Card", into: context)

        let uniqueUserInfo: [AnyHashable: Any] = [
            NSInsertedObjectIDsKey: [newBudget.objectID, newIncome.objectID],
            NSUpdatedObjectIDsKey: [newPlannedExpense.objectID, newCard.objectID],
            NSDeletedObjectIDsKey: [newUnplannedExpense.objectID, newExpenseCategory.objectID],
        ]

        let duplicateExpectation = expectation(description: "duplicate home payload triggers once")
        duplicateExpectation.assertForOverFulfill = true

        let uniqueExpectation = expectation(description: "unique home payload triggers again")
        uniqueExpectation.assertForOverFulfill = true

        var expectationIterator = [duplicateExpectation, uniqueExpectation].makeIterator()

        let monitor = CoreDataEntityChangeMonitor(
            entityNames: ["Budget", "PlannedExpense", "UnplannedExpense", "Income", "ExpenseCategory", "Card"],
            debounceMilliseconds: 0
        ) {
            guard let expectation = expectationIterator.next() else {
                XCTFail("Unexpected callback")
                return
            }
            expectation.fulfill()
        }

        NotificationCenter.default.post(
            name: .NSManagedObjectContextDidMergeChangesObjectIDs,
            object: context,
            userInfo: duplicateUserInfo
        )

        NotificationCenter.default.post(
            name: .NSManagedObjectContextDidMergeChangesObjectIDs,
            object: context,
            userInfo: duplicateUserInfo
        )

        NotificationCenter.default.post(
            name: .NSManagedObjectContextDidMergeChangesObjectIDs,
            object: context,
            userInfo: uniqueUserInfo
        )

        wait(for: [duplicateExpectation, uniqueExpectation], timeout: 1)
        withExtendedLifetime(monitor) {}
    }

    func testIncomeEntitySetNotificationsDeduplicateButUniquePayloadsTriggerRefresh() {
        let stack = TestCoreDataStack()
        let context = stack.container.viewContext

        let income = NSEntityDescription.insertNewObject(forEntityName: "Income", into: context)

        let duplicateUserInfo: [AnyHashable: Any] = [
            NSInsertedObjectIDsKey: [income.objectID],
            NSUpdatedObjectIDsKey: [income.objectID],
        ]

        let newIncome = NSEntityDescription.insertNewObject(forEntityName: "Income", into: context)

        let uniqueUserInfo: [AnyHashable: Any] = [
            NSInsertedObjectIDsKey: [newIncome.objectID],
            NSDeletedObjectIDsKey: [income.objectID],
        ]

        let duplicateExpectation = expectation(description: "duplicate income payload triggers once")
        duplicateExpectation.assertForOverFulfill = true

        let uniqueExpectation = expectation(description: "unique income payload triggers again")
        uniqueExpectation.assertForOverFulfill = true

        var expectationIterator = [duplicateExpectation, uniqueExpectation].makeIterator()

        let monitor = CoreDataEntityChangeMonitor(entityNames: ["Income"], debounceMilliseconds: 0) {
            guard let expectation = expectationIterator.next() else {
                XCTFail("Unexpected callback")
                return
            }
            expectation.fulfill()
        }

        NotificationCenter.default.post(
            name: .NSManagedObjectContextDidMergeChangesObjectIDs,
            object: context,
            userInfo: duplicateUserInfo
        )

        NotificationCenter.default.post(
            name: .NSManagedObjectContextDidMergeChangesObjectIDs,
            object: context,
            userInfo: duplicateUserInfo
        )

        NotificationCenter.default.post(
            name: .NSManagedObjectContextDidMergeChangesObjectIDs,
            object: context,
            userInfo: uniqueUserInfo
        )

        wait(for: [duplicateExpectation, uniqueExpectation], timeout: 1)
        withExtendedLifetime(monitor) {}
    }

    func testPresetsEntitySetNotificationsDeduplicateButUniquePayloadsTriggerRefresh() {
        let stack = TestCoreDataStack()
        let context = stack.container.viewContext

        let plannedExpense = NSEntityDescription.insertNewObject(forEntityName: "PlannedExpense", into: context)

        let duplicateUserInfo: [AnyHashable: Any] = [
            NSInsertedObjectIDsKey: [plannedExpense.objectID],
            NSUpdatedObjectIDsKey: [plannedExpense.objectID],
        ]

        let newPlannedExpense = NSEntityDescription.insertNewObject(forEntityName: "PlannedExpense", into: context)

        let uniqueUserInfo: [AnyHashable: Any] = [
            NSInsertedObjectIDsKey: [newPlannedExpense.objectID],
            NSDeletedObjectIDsKey: [plannedExpense.objectID],
        ]

        let duplicateExpectation = expectation(description: "duplicate presets payload triggers once")
        duplicateExpectation.assertForOverFulfill = true

        let uniqueExpectation = expectation(description: "unique presets payload triggers again")
        uniqueExpectation.assertForOverFulfill = true

        var expectationIterator = [duplicateExpectation, uniqueExpectation].makeIterator()

        let monitor = CoreDataEntityChangeMonitor(entityNames: ["PlannedExpense"], debounceMilliseconds: 0) {
            guard let expectation = expectationIterator.next() else {
                XCTFail("Unexpected callback")
                return
            }
            expectation.fulfill()
        }

        NotificationCenter.default.post(
            name: .NSManagedObjectContextDidMergeChangesObjectIDs,
            object: context,
            userInfo: duplicateUserInfo
        )

        NotificationCenter.default.post(
            name: .NSManagedObjectContextDidMergeChangesObjectIDs,
            object: context,
            userInfo: duplicateUserInfo
        )

        NotificationCenter.default.post(
            name: .NSManagedObjectContextDidMergeChangesObjectIDs,
            object: context,
            userInfo: uniqueUserInfo
        )

        wait(for: [duplicateExpectation, uniqueExpectation], timeout: 1)
        withExtendedLifetime(monitor) {}
    }
}

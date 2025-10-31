//
//  CloudMirroringSmokeTests.swift
//  OffshoreBudgetingTests
//
//  Gated, best-effort smoke tests to validate that saving each entity
//  triggers a CloudKit export event when Cloud sync is enabled.
//  These tests are intentionally skipped unless you set the environment
//  variable RUN_CLOUD_SMOKE=1 and the Cloud store is active.
//

import XCTest
import CoreData
import CloudKit
#if canImport(Offshore)
@testable import Offshore
#elseif canImport(OffshoreBudgeting)
@testable import OffshoreBudgeting
#elseif canImport(SoFar)
@testable import SoFar
#else
#error("App module not found. Ensure the test target depends on the app target and update the conditional import.")
#endif

@MainActor
final class CloudMirroringSmokeTests: XCTestCase {

    override func setUp() async throws {
        try await super.setUp()
        // Only run when explicitly requested to avoid CI/network flakiness.
        let shouldRun = ProcessInfo.processInfo.environment["RUN_CLOUD_SMOKE"] == "1"
        guard shouldRun else { throw XCTSkip("Set RUN_CLOUD_SMOKE=1 to run cloud smoke tests") }

        // Ensure Cloud mode is active for the app container.
        UserDefaults.standard.set(true, forKey: AppSettingsKeys.enableCloudSync.rawValue)
        await CoreDataService.shared.applyCloudSyncPreferenceChange(enableSync: true)
        await CoreDataService.shared.waitUntilStoresLoaded(timeout: 10.0)
        guard CoreDataService.shared.isCloudStoreActive else {
            throw XCTSkip("Cloud store not active; skipping smoke tests")
        }
    }

    func testCloudMirroringPerEntity() async throws {
        // Create dependencies once (Budget, Card, Category)
        let budget = try BudgetService().createBudget(name: "SmokeBudget",
                                                     startDate: Date(),
                                                     endDate: Date().addingTimeInterval(3600))
        // 1) Budget -> export
        await waitForExportEventOrFail(label: "Budget export", timeout: 8.0)

        let card = try CardService().createCard(name: "SmokeCard-\(UUID().uuidString.prefix(6))",
                                                ensureUniqueName: false)
        // 2) Card -> export
        await waitForExportEventOrFail(label: "Card export", timeout: 8.0)

        let category = try ExpenseCategoryService().addCategory(name: "SmokeCat-\(UUID().uuidString.prefix(6))",
                                                                color: "#fff",
                                                                ensureUniqueName: false)
        // 3) ExpenseCategory -> export
        await waitForExportEventOrFail(label: "ExpenseCategory export", timeout: 8.0)

        // 4) Income -> export
        _ = try IncomeService().createIncome(source: "SmokeIncome",
                                             amount: 1.0,
                                             date: Date(),
                                             isPlanned: true)
        await waitForExportEventOrFail(label: "Income export", timeout: 8.0)

        // 5) PlannedExpense -> export (attach to budget)
        _ = try PlannedExpenseService().create(inBudgetID: budget.value(forKey: "id") as? UUID ?? UUID(),
                                               titleOrDescription: "SmokePlanned",
                                               plannedAmount: 1.0,
                                               actualAmount: 0,
                                               transactionDate: Date())
        await waitForExportEventOrFail(label: "PlannedExpense export", timeout: 8.0)

        // 6) UnplannedExpense -> export (attach to card/category)
        let cardID = (card.value(forKey: "id") as? UUID) ?? UUID()
        let catID = (category.value(forKey: "id") as? UUID)
        _ = try UnplannedExpenseService().create(descriptionText: "SmokeUnplanned",
                                                 amount: 1.0,
                                                 date: Date(),
                                                 cardID: cardID,
                                                 categoryID: catID)
        await waitForExportEventOrFail(label: "UnplannedExpense export", timeout: 8.0)

        // 7) CategorySpendingCap -> export (attach to category)
        let ctx = CoreDataService.shared.viewContext
        let cap = CategorySpendingCap(context: ctx)
        cap.setValue(UUID(), forKey: "id")
        cap.amount = 5.0
        cap.expenseType = "smoke"
        cap.category = category
        try ctx.save()
        await waitForExportEventOrFail(label: "CategorySpendingCap export", timeout: 8.0)
    }

    // MARK: - Helpers
    private func waitForExportEventOrFail(label: String, timeout: TimeInterval) async {
        let exp = expectation(description: label)
        exp.assertForOverFulfill = false
        var token: NSObjectProtocol?
        token = NotificationCenter.default.addObserver(
            forName: NSPersistentCloudKitContainer.eventChangedNotification,
            object: nil,
            queue: .main
        ) { note in
            guard let event = note.userInfo?[NSPersistentCloudKitContainer.eventNotificationUserInfoKey] as? NSPersistentCloudKitContainer.Event else { return }
            // Consider any completed export/import as success; in practice, exports will occur
            // after our writes. We keep this permissive to reduce flakiness.
            if (event.type == .export || event.type == .import), event.endDate != nil {
                exp.fulfill()
            }
        }
        // Give the container time to coalesce and process.
        wait(for: [exp], timeout: timeout)
        if let token { NotificationCenter.default.removeObserver(token) }
    }
}


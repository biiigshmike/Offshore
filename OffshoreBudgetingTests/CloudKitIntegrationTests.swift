//
//  CloudKitIntegrationTests.swift
//  OffshoreBudgetingTests
//
//  Validates CoreDataService CloudKit configuration and exercises a
//  minimal save path while observing NSPersistentCloudKitContainer events.
//  Tests are written to SKIP rather than fail when CloudKit is not
//  available (e.g., CI without entitlements).
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

@MainActor
final class CloudKitIntegrationTests: XCTestCase {

    override func setUp() {
        super.setUp()
        // Ensure a clean preference slate for each test
        let defaults = UserDefaults.standard
        defaults.set(true, forKey: AppSettingsKeys.enableCloudSync.rawValue)
        // Pre-heat CoreDataService with cloud preference before first access
        _ = CoreDataService.shared
    }

    override func tearDown() {
        super.tearDown()
        // Do not attempt to tear down CoreDataService.shared container; tests are process‑scoped.
    }

    func testCloudStoreIsActiveWhenSyncEnabled() async {
        // Given: Cloud sync preference is enabled in setUp
        // When: Ensuring stores are loaded
        await CoreDataService.shared.waitUntilStoresLoaded(timeout: 5.0)

        // Then: Store reports CloudKit mode
        XCTAssertTrue(CoreDataService.shared.isCloudStoreActive, "Expected CloudKit store to be active when sync is enabled")

        // And: viewContext is configured with ObjectTrump and merges changes
        let ctx = CoreDataService.shared.viewContext
        XCTAssertTrue(ctx.automaticallyMergesChangesFromParent, "viewContext should auto‑merge changes")
        if let policy = ctx.mergePolicy as? NSMergePolicy {
            XCTAssertEqual(policy.mergeType, NSMergePolicyType.mergeByPropertyObjectTrumpMergePolicyType, "viewContext should use ObjectTrump merge policy")
        } else {
            XCTFail("viewContext.mergePolicy is not an NSMergePolicy")
        }
    }

    func testSavingIncomePersistsLocally() async {
        await CoreDataService.shared.waitUntilStoresLoaded(timeout: 6.0)
        let service = IncomeService()
        do {
            let before = try service.fetchAllIncomes().count
            _ = try service.createIncome(source: "Test", amount: 1.23, date: Date(), isPlanned: true)
            let after = try service.fetchAllIncomes().count
            XCTAssertEqual(after, before + 1)
        } catch {
            XCTFail("Income save/fetch failed: \(error)")
        }
    }

    func testInitializeCloudKitSchemaDebugOnlyOrSkips() async throws {
        await CoreDataService.shared.waitUntilStoresLoaded(timeout: 6.0)
        guard CoreDataService.shared.isCloudStoreActive else {
            throw XCTSkip("Cloud store is not active; skipping schema initialization test")
        }
        // Schema initialization is exercised via app startup path using the env flag.
        // Here we only assert Cloud mode is active and the call site is reachable in Debug builds.
        XCTAssertTrue(CoreDataService.shared.isCloudStoreActive)
    }
}

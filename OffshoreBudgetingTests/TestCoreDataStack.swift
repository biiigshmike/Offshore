//
//  TestCoreDataStack.swift
//  OffshoreBudgetingTests
//
//  In-memory Core Data stack for fast, isolated unit tests.
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

// MARK: - TestCoreDataStack
/// Provides an in-memory NSPersistentContainer using the app's data model.
/// Attempts to locate the compiled model in any loaded bundle.
final class TestCoreDataStack: CoreDataStackProviding {
    let container: NSPersistentContainer

    init(modelName: String = "OffshoreBudgetingModel") {
        let model = Self.loadModel(named: modelName)
        container = NSPersistentContainer(name: modelName, managedObjectModel: model)

        let description = NSPersistentStoreDescription()
        // Use SQLite so GROUP BY aggregations are supported in tests
        description.type = NSSQLiteStoreType
        description.url = Self.temporarySQLiteURL(modelName: modelName)
        description.shouldAddStoreAsynchronously = false
        description.setOption(true as NSNumber, forKey: NSMigratePersistentStoresAutomaticallyOption)
        description.setOption(true as NSNumber, forKey: NSInferMappingModelAutomaticallyOption)
        container.persistentStoreDescriptions = [description]

        container.loadPersistentStores { _, error in
            XCTAssertNil(error, "Failed to load SQLite test store: \(String(describing: error))")
        }

        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.undoManager = nil
    }

    private static func loadModel(named name: String) -> NSManagedObjectModel {
        // Try explicit momd/mom lookups across all bundles first
        let candidates = [Bundle(for: TestCoreDataStack.self)] + Bundle.allBundles + Bundle.allFrameworks
        for bundle in candidates {
            if let url = bundle.url(forResource: name, withExtension: "momd"),
               let model = NSManagedObjectModel(contentsOf: url) {
                return model
            }
            if let url = bundle.url(forResource: name, withExtension: "mom"),
               let model = NSManagedObjectModel(contentsOf: url) {
                return model
            }
        }
        // Fallback to merged models
        if let merged = NSManagedObjectModel.mergedModel(from: candidates) {
            return merged
        }
        XCTFail("❌ Could not locate Core Data model \(name).momd for tests")
        return NSManagedObjectModel()
    }

    private static func temporarySQLiteURL(modelName: String) -> URL {
        let tmp = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
        let filename = "\(modelName)-Tests-\(UUID().uuidString).sqlite"
        return tmp.appendingPathComponent(filename)
    }
}

import Foundation
import CoreData
@testable import Offshore

// MARK: - TestCoreDataStack
/// In-memory Core Data stack for unit tests that need CoreDataStackProviding.
final class TestCoreDataStack: CoreDataStackProviding {
    let container: NSPersistentContainer

    enum LoadError: Error {
        case modelURLMissing
        case modelLoadFailed
    }

    init(storeType: String = NSInMemoryStoreType,
         storeURL: URL? = nil,
         file: StaticString = #file,
         line: UInt = #line) throws {
        let bundle = Bundle(identifier: "com.mb.offshore-budgeting") ?? Bundle(for: CoreDataService.self)
        guard let modelURL = bundle.url(forResource: "OffshoreBudgetingModel", withExtension: "momd") else {
            throw LoadError.modelURLMissing
        }
        guard let model = NSManagedObjectModel(contentsOf: modelURL) else {
            throw LoadError.modelLoadFailed
        }

        let container = NSPersistentContainer(name: "OffshoreBudgetingModel", managedObjectModel: model)
        let description = NSPersistentStoreDescription()
        description.type = storeType
        if let storeURL {
            description.url = storeURL
        }
        description.shouldAddStoreAsynchronously = false
        container.persistentStoreDescriptions = [description]

        var loadError: Error?
        container.loadPersistentStores { _, error in
            loadError = error
        }
        if let loadError { throw loadError }
        self.container = container
    }
}

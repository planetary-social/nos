import XCTest
import CoreData
import Dependencies

// swiftlint:disable implicitly_unwrapped_optional

/// A test case that uses a full core data stack including a SQLite backing store.
class SQLiteStoreTestCase: XCTestCase {
        
    var persistenceController: PersistenceController!
    
    override func setUp() {
        super.setUp()
        persistenceController = PersistenceController(containerName: "NosTests", inMemory: true, erase: true)
    }
    
    override func tearDownWithError() throws {
        try persistenceController.tearDown()
        persistenceController = nil
        try super.tearDownWithError()
    }
}

// swiftlint:enable implicitly_unwrapped_optional

extension PersistenceController {
    func tearDown() throws {
        for store in container.persistentStoreCoordinator.persistentStores {
            try container.persistentStoreCoordinator.remove(store)
        }
        
        try container.persistentStoreDescriptions.forEach { storeDescription in
            try container.persistentStoreCoordinator.destroyPersistentStore(
                at: storeDescription.url!,
                ofType: NSSQLiteStoreType,
                options: nil
            )
        }
        
        viewContext.reset()
        backgroundViewContext.reset()
        parseContext.reset()
    }
}

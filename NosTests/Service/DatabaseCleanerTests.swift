import XCTest
import CoreData

final class DatabaseCleanerTests: CoreDataTestCase {
    
    @MainActor func test_emptyDatabase() async throws {
        // Act
        try await DatabaseCleaner.cleanupEntities(before: Date.now, for: KeyFixture.alice.publicKeyHex, in: testContext)
        
        // Assert that the database is still empty
        let managedObjectModel = try XCTUnwrap(testContext.persistentStoreCoordinator?.managedObjectModel)
        let entitiesByName = managedObjectModel.entitiesByName
        XCTAssertGreaterThan(entitiesByName.count, 0) // sanity check
            
        for entityName in entitiesByName.keys {
            let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: entityName)
            XCTAssertEqual(try testContext.count(for: fetchRequest), 0)
        }
    }
}

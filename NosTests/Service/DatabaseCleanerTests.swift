import XCTest

final class DatabaseCleanerTests: CoreDataTestCase {
    
    func test_emptyDatabase() async throws {
        try await DatabaseCleaner.cleanupEntities(before: Date.now, for: KeyFixture.alice.publicKeyHex, in: testContext)
    }
}

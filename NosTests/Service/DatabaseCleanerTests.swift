import XCTest
import CoreData

final class DatabaseCleanerTests: CoreDataTestCase {
    
    func test_emptyDatabase() async throws {
        try await DatabaseCleaner.cleanupEntities(before: Date.now, for: KeyFixture.alice.publicKeyHex, in: testContext)
    }
    
    func test_cleanup_deletesCorrectEventReferences() async throws {
        // Arrange
        let deleteBeforeDate = Date(timeIntervalSince1970: 10)
        let user = KeyFixture.alice
        _ = try Author.findOrCreate(by: user.publicKeyHex, context: testContext)
        let oldEventOne = try createTestEvent(in: testContext, receivedAt: Date(timeIntervalSince1970: 9))
        let oldEventTwo = try createTestEvent(in: testContext, receivedAt: Date(timeIntervalSince1970: 8))
        let newEvent = try createTestEvent(in: testContext, receivedAt: Date(timeIntervalSince1970: 11))
        
        // Create a reference with two old events that should be deleted
        let eventReferenceToBeDeleted = EventReference(context: testContext)
        eventReferenceToBeDeleted.referencedEvent = oldEventOne
        eventReferenceToBeDeleted.referencingEvent = oldEventTwo
        
        // Create references with a new event that should not be deleted
        let eventReferenceToBeKept = EventReference(context: testContext)
        eventReferenceToBeDeleted.referencingEvent = newEvent
        eventReferenceToBeDeleted.referencedEvent = oldEventTwo
        
        try testContext.save()
        
        // Act 
        try await DatabaseCleaner.cleanupEntities(
            before: deleteBeforeDate, 
            for: KeyFixture.alice.publicKeyHex, 
            in: testContext
        )
        
        // Assert
        let eventReferences = try testContext.fetch(EventReference.all())
        XCTAssertEqual(eventReferences.count, 1)
        XCTAssertEqual(eventReferences.first?.referencingEvent, newEvent)
        XCTAssertEqual(eventReferences.first?.referencedEvent, oldEventTwo)
    }
    
    func test_cleanup_deletesOldEvents() async throws {
        let deleteBeforeDate = Date(timeIntervalSince1970: 10)
        let user = KeyFixture.alice
        _ = try Author.findOrCreate(by: user.publicKeyHex, context: testContext)
        let oldEvent = try createTestEvent(in: testContext, receivedAt: Date(timeIntervalSince1970: 9))
        let newEvent = try createTestEvent(in: testContext, receivedAt: Date(timeIntervalSince1970: 11))
        
        try testContext.save()
        
        // Act 
        try await DatabaseCleaner.cleanupEntities(
            before: deleteBeforeDate, 
            for: KeyFixture.alice.publicKeyHex, 
            in: testContext
        )
        
        // Assert
        let events = try testContext.fetch(Event.allEventsRequest())
        XCTAssertEqual(events, [newEvent])
    }
    
    func test_cleanup_savesReferencedEvents() async throws {
        let deleteBeforeDate = Date(timeIntervalSince1970: 10)
        let user = KeyFixture.alice
        _ = try Author.findOrCreate(by: user.publicKeyHex, context: testContext)
        
        // Create an old event that is referenced by a newer event
        let oldEvent = try createTestEvent(in: testContext, receivedAt: Date(timeIntervalSince1970: 9))
        let newEvent = try createTestEvent(in: testContext, receivedAt: Date(timeIntervalSince1970: 11))
        
        let eventReferenceToBeDeleted = EventReference(context: testContext)
        eventReferenceToBeDeleted.referencedEvent = oldEvent
        eventReferenceToBeDeleted.referencingEvent = newEvent
        
        try testContext.save()
        
        // Act 
        try await DatabaseCleaner.cleanupEntities(
            before: deleteBeforeDate, 
            for: KeyFixture.alice.publicKeyHex, 
            in: testContext
        )
        
        // Assert
        let events = try testContext.fetch(Event.allEventsRequest())
        XCTAssertEqual(events.count, 2)
    }
        
    // MARK: - Helpers
    
    private func createTestEvent(
        in context: NSManagedObjectContext,
        publicKey: RawAuthorID = KeyFixture.pubKeyHex,
        receivedAt: Date = .now
    ) throws -> Event {
        let event = Event(context: context)
        event.identifier = UUID().uuidString
        event.createdAt = Date.now
        event.receivedAt = receivedAt
        event.content = "Testing nos #[0]"
        event.kind = 1
        
        let author = Author(context: context)
        author.hexadecimalPublicKey = publicKey
        event.author = author
        
        let tags = [["p", "d0a1ffb8761b974cec4a3be8cbcb2e96a7090dcf465ffeac839aa4ca20c9a59e"]]
        event.allTags = tags as NSObject
        return event
    }
}

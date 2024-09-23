import XCTest
import CoreData

final class DatabaseCleanerTests: CoreDataTestCase {
    
    @MainActor func test_emptyDatabase() async throws {
        // Act
        try await DatabaseCleaner.cleanupEntities(for: KeyFixture.alice.publicKeyHex, in: testContext)
        
        // Assert that the database is still empty
        let managedObjectModel = try XCTUnwrap(testContext.persistentStoreCoordinator?.managedObjectModel)
        let entitiesByName = managedObjectModel.entitiesByName
        XCTAssertGreaterThan(entitiesByName.count, 0) // sanity check
            
        for entityName in entitiesByName.keys {
            let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: entityName)
            XCTAssertEqual(try testContext.count(for: fetchRequest), 0)
        }
    }
    
    // MARK: - EventReferences
    
    @MainActor func test_cleanup_deletesCorrectEventReferences() async throws {
        // Arrange
        // Create the signed in user or the DatabaseCleaner will exit early. 
        _ = try Author.findOrCreate(by: KeyFixture.alice.publicKeyHex, context: testContext)
        let oldEventOne = try EventFixture.build(in: testContext, receivedAt: Date(timeIntervalSince1970: 9))
        let oldEventTwo = try EventFixture.build(in: testContext, receivedAt: Date(timeIntervalSince1970: 8))
        let newEvent = try EventFixture.build(in: testContext, receivedAt: Date(timeIntervalSince1970: 11))
        
        // Create a reference with two old events that should be deleted
        let eventReferenceToBeDeleted = EventReference(context: testContext)
        eventReferenceToBeDeleted.referencedEvent = oldEventOne
        eventReferenceToBeDeleted.referencingEvent = oldEventTwo
        
        // Create references with a new event that should not be deleted
        let eventReferenceToBeKept = EventReference(context: testContext)
        eventReferenceToBeKept.referencingEvent = newEvent
        eventReferenceToBeKept.referencedEvent = oldEventTwo
        
        try testContext.save()
        
        // Act 
        try await DatabaseCleaner.cleanupEntities(
            for: KeyFixture.alice.publicKeyHex, 
            in: testContext,
            keeping: 1
        )
        
        // Assert
        let eventReferences = try testContext.fetch(EventReference.all())
        XCTAssertEqual(eventReferences.count, 1)
        XCTAssertEqual(eventReferences.first?.referencingEvent, newEvent)
        XCTAssertEqual(eventReferences.first?.referencedEvent, oldEventTwo)
    }
    
    @MainActor func test_cleanup_savesReferencedEvents() async throws {
        // Arrange
        // Create the signed in user or the DatabaseCleaner will exit early. 
        _ = try Author.findOrCreate(by: KeyFixture.alice.publicKeyHex, context: testContext)
        // Create an old event that is referenced by a newer event
        let oldEvent = try EventFixture.build(in: testContext, receivedAt: Date(timeIntervalSince1970: 9))
        let newEvent = try EventFixture.build(in: testContext, receivedAt: Date(timeIntervalSince1970: 11))
        
        let eventReferenceToBeDeleted = EventReference(context: testContext)
        eventReferenceToBeDeleted.referencedEvent = oldEvent
        eventReferenceToBeDeleted.referencingEvent = newEvent
        
        try testContext.save()
        
        // Act 
        try await DatabaseCleaner.cleanupEntities(
            for: KeyFixture.alice.publicKeyHex, 
            in: testContext,
            keeping: 1
        )
        
        // Assert
        let events = try testContext.fetch(Event.allEventsRequest())
        XCTAssertEqual(events.count, 2)
    }
    
    @MainActor func test_cleanup_givenEventReferenceChain_thenOldEventsStubbed() async throws {
        // Arrange
        // Create the signed in user or the DatabaseCleaner will exit early. 
        _ = try Author.findOrCreate(by: KeyFixture.alice.publicKeyHex, context: testContext)
        // Create a chain of events that reference one another. Two of them are old enough to be deleted.
        try testContext.save()
        let newEvent = try EventFixture.build(in: testContext, receivedAt: Date(timeIntervalSince1970: 11))
        let oldEvent = try EventFixture.build(in: testContext, receivedAt: Date(timeIntervalSince1970: 9))
        let reallyOldEvent = try EventFixture.build(in: testContext, receivedAt: Date(timeIntervalSince1970: 0))
        try testContext.save()
        
        let eventReferenceToBeKept = EventReference(context: testContext)
        eventReferenceToBeKept.referencingEvent = newEvent
        eventReferenceToBeKept.referencedEvent = oldEvent
        
        let eventReferenceToBeDeleted = EventReference(context: testContext)
        eventReferenceToBeDeleted.referencingEvent = oldEvent
        eventReferenceToBeDeleted.referencedEvent = reallyOldEvent
        
        try testContext.save()
        
        // Act 
        try await DatabaseCleaner.cleanupEntities(
            for: KeyFixture.alice.publicKeyHex, 
            in: testContext,
            keeping: 1
        )
        
        // Assert
        // We expect the really old event to be deleted entirely and the old event should be changed to a stub.
        let events = try testContext.fetch(Event.allEventsRequest())
        XCTAssertEqual(events.count, 2)
        XCTAssertEqual(events.first?.identifier, oldEvent.identifier)
        XCTAssertEqual(events.first?.isStub, true)
        XCTAssertEqual(events.last?.identifier, newEvent.identifier)
        XCTAssertEqual(events.last?.isStub, false)
    }
    
    // MARK: - Events
    
    @MainActor func test_cleanup_keepsNEvents() async throws {
        // Create the signed in user or the DatabaseCleaner will exit early. 
        _ = try Author.findOrCreate(by: KeyFixture.alice.publicKeyHex, context: testContext)
        
        var events = [Event]()
        for i in 0..<10 {
            let date = Date(timeIntervalSince1970: TimeInterval(i))
            events.append(
                try EventFixture.build(
                    in: testContext, 
                    createdAt: date,
                    receivedAt: date
                ) 
            )
        }
        
        try testContext.save()
        
        // Act 
        try await DatabaseCleaner.cleanupEntities(
            for: KeyFixture.alice.publicKeyHex, 
            in: testContext,
            keeping: 5
        )
        
        // Assert
        let fetchedEvents = try testContext.fetch(Event.allEventsRequest())
        XCTAssertEqual(fetchedEvents.map { $0.identifier }, events.suffix(5).map { $0.identifier })
    }
    
    @MainActor func test_cleanup_deletesOldEvents() async throws {
        // Create the signed in user or the DatabaseCleaner will exit early. 
        let user = KeyFixture.alice
        _ = try Author.findOrCreate(by: user.publicKeyHex, context: testContext)
        
        _ = try EventFixture.build(in: testContext, receivedAt: Date(timeIntervalSince1970: 9)) // old event
        let newEvent = try EventFixture.build(in: testContext, receivedAt: Date(timeIntervalSince1970: 11))
        
        try testContext.save()
        
        // Act 
        try await DatabaseCleaner.cleanupEntities(
            for: KeyFixture.alice.publicKeyHex, 
            in: testContext,
            keeping: 1
        )
        
        // Assert
        let events = try testContext.fetch(Event.allEventsRequest())
        XCTAssertEqual(events, [newEvent])
    }
    
    // MARK: - Authors
    
    @MainActor func test_cleanup_keepsInNetworkAuthors() async throws {
        // Arrange
        let alice = try Author.findOrCreate(by: KeyFixture.alice.publicKeyHex, context: testContext)
        let bob   = try Author.findOrCreate(by: "bob", context: testContext)
        let carl  = try Author.findOrCreate(by: "carl", context: testContext)
        let eve   = try Author.findOrCreate(by: "eve", context: testContext)
        
        // Act
        // Create a circle of follows alice -> bob -> carl -> eve -> alice
        _ = try Follow.findOrCreate(source: alice, destination: bob, context: testContext)
        _ = try Follow.findOrCreate(source: bob, destination: carl, context: testContext)
        _ = try Follow.findOrCreate(source: carl, destination: eve, context: testContext)
        _ = try Follow.findOrCreate(source: eve, destination: alice, context: testContext)
        
        try testContext.saveIfNeeded()
        
        // Act 
        try await DatabaseCleaner.cleanupEntities(
            for: KeyFixture.alice.publicKeyHex, 
            in: testContext
        )
        
        // Assert
        let authors = try testContext.fetch(Author.allAuthorsRequest())
        // Eve is out of network and should be deleted. The others should be kept.
        XCTAssertEqual(authors, [carl, bob, alice])
    }
    
    // MARK: - Follows
    
    @MainActor func test_cleanup_keepsInNetworkFollows() async throws {
        // Arrange
        let alice = try Author.findOrCreate(by: KeyFixture.alice.publicKeyHex, context: testContext)
        let bob   = try Author.findOrCreate(by: "bob", context: testContext)
        let carl  = try Author.findOrCreate(by: "carl", context: testContext)
        let eve   = try Author.findOrCreate(by: "eve", context: testContext)
        
        // Act
        // Create a circle of follows alice -> bob -> carl -> eve -> alice
        let followOne = try Follow.findOrCreate(source: alice, destination: bob, context: testContext)
        let followTwo = try Follow.findOrCreate(source: bob, destination: carl, context: testContext)
        let followThree = try Follow.findOrCreate(source: carl, destination: eve, context: testContext)
        _ = try Follow.findOrCreate(source: eve, destination: alice, context: testContext)
        
        try testContext.saveIfNeeded()
        
        // Act 
        try await DatabaseCleaner.cleanupEntities(
            for: KeyFixture.alice.publicKeyHex, 
            in: testContext
        )
        
        // Assert
        let follows = try testContext.fetch(Follow.allFollowsRequest())
        XCTAssertEqual(follows, [followThree, followTwo, followOne])
    }

    // MARK: - Note Composer Preview

    @MainActor func test_cleanup_deletesNoteComposerPreview() async throws {
        // Arrange
        // Create the signed in user or the DatabaseCleaner will exit early.
        _ = try Author.findOrCreate(by: KeyFixture.alice.publicKeyHex, context: testContext)

        // Create the preview event (we expect it to be deleted by the cleanup code)
        _ = try EventFixture.build(
            in: testContext,
            identifier: Event.previewIdentifier
        )

        try testContext.save()

        // Act
        try await DatabaseCleaner.cleanupEntities(
            for: KeyFixture.alice.publicKeyHex,
            in: testContext,
            keeping: 1
        )

        // Assert
        let events = try testContext.fetch(Event.allEventsRequest())
        XCTAssertEqual(events.count, 0)
    }
}

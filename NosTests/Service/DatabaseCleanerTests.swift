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

    @MainActor func test_cleanup_deletesOldNotifications() async throws {
        // Arrange
        let alice = try Author.findOrCreate(by: KeyFixture.alice.publicKeyHex, context: testContext)

        // Creates old notification (2 months + 1 day old)
        let oldDate = Calendar.current.date(byAdding: .day, value: -61, to: .now)!
        let oldNotification = NosNotification(context: testContext)
        oldNotification.createdAt = oldDate
        oldNotification.user = alice

        // Creates recent notification (1 day old)
        let recentDate = Calendar.current.date(byAdding: .day, value: -1, to: .now)!
        let recentNotification = NosNotification(context: testContext)
        recentNotification.createdAt = recentDate
        recentNotification.user = alice

        try testContext.save()

        // Verify initial notifications before cleanup.
        let initialCount = try testContext.fetch(NosNotification.fetchRequest()).count
        XCTAssertEqual(initialCount, 2)

        // Act
        try await DatabaseCleaner.cleanupEntities(
            for: KeyFixture.alice.publicKeyHex,
            in: testContext
        )

        // Assert
        let remainingNotifications = try testContext.fetch(NosNotification.fetchRequest())
        XCTAssertEqual(remainingNotifications.count, 1)
        XCTAssertEqual(remainingNotifications.first?.createdAt, recentDate)
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
    
    @MainActor func test_cleanup_erasesAuthorsWithoutFollows() async throws {
        // Arrange
        let alice = try Author.findOrCreate(by: KeyFixture.alice.publicKeyHex, context: testContext)
        _ = try Author.findOrCreate(by: "bob", context: testContext)
        _ = try Author.findOrCreate(by: "carl", context: testContext)
        _ = try Author.findOrCreate(by: "eve", context: testContext)
        
        // Act
        try testContext.saveIfNeeded()
        
        // Act 
        try await DatabaseCleaner.cleanupEntities(
            for: KeyFixture.alice.publicKeyHex, 
            in: testContext
        )
        
        // Assert
        let authors = try testContext.fetch(Author.allAuthorsRequest())
        // Eve and bob are muted and should be saved even though bob is out of network
        XCTAssertEqual(authors, [alice])
    }
    
    @MainActor func test_cleanup_keepsMutedAuthors() async throws {
        // Arrange
        let alice = try Author.findOrCreate(by: KeyFixture.alice.publicKeyHex, context: testContext)
        let bob   = try Author.findOrCreate(by: "bob", context: testContext)
        _ = try Author.findOrCreate(by: "carl", context: testContext)
        let eve   = try Author.findOrCreate(by: "eve", context: testContext)
        
        // Act
        _ = try Follow.findOrCreate(source: alice, destination: bob, context: testContext)
        bob.muted = true
        eve.muted = true
        
        try testContext.saveIfNeeded()
        
        // Act 
        try await DatabaseCleaner.cleanupEntities(
            for: KeyFixture.alice.publicKeyHex, 
            in: testContext
        )
        
        // Assert
        let authors = try testContext.fetch(Author.allAuthorsRequest())
        // Eve and bob are muted and should be saved even though bob is out of network
        XCTAssertEqual(authors, [eve, bob, alice])
    }
    
    @MainActor func test_cleanup_keepsAuthorsWithEvents() async throws {
        // Arrange
        let alice = try Author.findOrCreate(by: KeyFixture.alice.publicKeyHex, context: testContext)
        let bob   = try Author.findOrCreate(by: KeyFixture.bob.publicKeyHex, context: testContext)
        
        // Act
        // Create an event by an out of network author
        let event = try EventFixture.build(
            in: testContext, 
            publicKey: KeyFixture.bob.publicKeyHex, 
            receivedAt: Date(timeIntervalSince1970: 11)
        )
        
        try testContext.saveIfNeeded()
        
        // Act 
        try await DatabaseCleaner.cleanupEntities(
            for: KeyFixture.alice.publicKeyHex, 
            in: testContext,
            keeping: 1
        )
        
        // Assert
        let authors = try testContext.fetch(Author.allAuthorsRequest())
        // Bob should be kept around because he has published events that weren't deleted.
        XCTAssertEqual(authors, [bob, alice]) 
        
        // Sanity check that Bob's event was kept
        let events = try testContext.fetch(Event.allEventsRequest())
        XCTAssertEqual(events.count, 1)
        XCTAssertEqual(events.first?.identifier, event.identifier)
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
    
    @MainActor func test_deleteAllEntities() async throws {
        _ = try EventFixture.build(in: testContext, identifier: "1", publicKey: "1", content: "test 1")
        _ = try EventFixture.build(in: testContext, identifier: "2", publicKey: "2", content: "test 2")
        _ = try EventFixture.build(in: testContext, identifier: "3", publicKey: "3", content: "test 3")
        
        _ = try Relay.findOrCreate(by: "wss://cool-relay.io", context: testContext)
        
        try testContext.save()
        
        var events = try testContext.fetch(Event.allEventsRequest())
        XCTAssertEqual(events.count, 3)
        events.removeAll()

        var authors = try testContext.fetch(Author.allAuthorsRequest())
        XCTAssertEqual(authors.count, 3)
        authors.removeAll()
        
        let allRelaysRequest = NSFetchRequest<Event>(entityName: "Relay")
        var relays = try testContext.fetch(allRelaysRequest)
        XCTAssertEqual(relays.count, 1)
        relays.removeAll()
        
        await persistenceController.container.deleteAllEntities()
        
        events = try testContext.fetch(Event.allEventsRequest())
        XCTAssertTrue(events.isEmpty)
        
        authors = try testContext.fetch(Author.allAuthorsRequest())
        XCTAssertTrue(authors.isEmpty)
        
        relays = try testContext.fetch(allRelaysRequest)
        XCTAssertTrue(relays.isEmpty)
    }

    @MainActor func test_deleteNotificationsAndEvents() async throws {
        // Arrange
        let alice = try Author.findOrCreate(by: KeyFixture.alice.publicKeyHex, context: testContext)
        let bob = try Author.findOrCreate(by: KeyFixture.bob.publicKeyHex, context: testContext)

        // Create events
        let event1 = try EventFixture.build(in: testContext, publicKey: KeyFixture.alice.publicKeyHex)
        let event2 = try EventFixture.build(in: testContext, publicKey: KeyFixture.bob.publicKeyHex)

        // Create notifications
        let notification1 = NosNotification(context: testContext)
        notification1.createdAt = Date()
        notification1.user = alice
        notification1.event = event1

        let notification2 = NosNotification(context: testContext)
        notification2.createdAt = Date()
        notification2.user = bob
        notification2.event = event2

        try testContext.save()

        // Verify initial state
        XCTAssertEqual(try testContext.count(for: Event.allEventsRequest()), 2)
        XCTAssertEqual(try testContext.count(for: NosNotification.fetchRequest()), 2)
        XCTAssertEqual(try testContext.count(for: Author.allAuthorsRequest()), 2)

        // Act
        try await DatabaseCleaner.deleteNotificationsAndEvents(in: testContext)

        // Assert
        XCTAssertEqual(try testContext.count(for: Event.allEventsRequest()), 0)
        XCTAssertEqual(try testContext.count(for: NosNotification.fetchRequest()), 0)
        XCTAssertEqual(try testContext.count(for: Author.allAuthorsRequest()), 2)
    }
}

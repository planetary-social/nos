import XCTest
import CoreData
import secp256k1
import secp256k1_bindings
import Dependencies

/// Tests for the Event model.
final class EventTests: CoreDataTestCase {
    // MARK: - Serialization
    @MainActor func testSerializedEventForSigning() throws {
        // Arrange
        let tags = [["p", "d0a1ffb8761b974cec4a3be8cbcb2e96a7090dcf465ffeac839aa4ca20c9a59e"]]
        let content = "Testing nos #[0]"
        let event = try EventFixture.build(in: testContext, content: content, tags: tags)
        // swiftlint:disable line_length
        let expectedString = """
        [0,"32730e9dfcab797caf8380d096e548d9ef98f3af3000542f9271a91a9e3b0001",1675264762,1,[["p","d0a1ffb8761b974cec4a3be8cbcb2e96a7090dcf465ffeac839aa4ca20c9a59e"]],"Testing nos #[0]"]
        """.trimmingCharacters(in: .whitespacesAndNewlines)
        // swiftlint:enable line_length

        // Act
        let serializedData = try JSONSerialization.data(withJSONObject: event.serializedEventForSigning)
        let actualString = String(decoding: serializedData, as: UTF8.self)

        // Assert
        XCTAssertEqual(actualString, expectedString)
    }

    // MARK: - Identifier calculation

    @MainActor func testIdentifierCalculation() throws {
        // Arrange
        let tags = [["p", "d0a1ffb8761b974cec4a3be8cbcb2e96a7090dcf465ffeac839aa4ca20c9a59e"]]
        let content = "Testing nos #[0]"
        let event = try EventFixture.build(in: testContext, content: content, tags: tags)

        // Act
        XCTAssertEqual(
            try event.calculateIdentifier(),
            "931b425e55559541451ddb99bd228bd1e0190af6ed21603b6b98544b42ee3317"
        )
    }

    @MainActor func testIdentifierCalculationWithEmptyAndNoTags() throws {
        // Arrange
        let content = "Testing nos #[0]"
        let nilTagsEvent = try EventFixture.build(in: testContext, content: content, tags: nil)
        let emptyTagsEvent = try EventFixture.build(in: testContext, content: content, tags: [])

        // Act
        XCTAssertEqual(
            try nilTagsEvent.calculateIdentifier(),
            "9b906de1db4ae84bda4b61b94724f8dfddd6fd9e6acddfe7ed79accb50052570"
        )
        XCTAssertEqual(
            try emptyTagsEvent.calculateIdentifier(),
            "bc45c3ac53de113e1400fca956048a816ad1c2e6ecceba6b1372ca597066fa9a"
        )
    }

    // MARK: - Signatures and Verification

    /// Verifies that we can sign an event and verify it.
    /// Since Schnorr signatures are non-deterministic we can't assert on constants. That's why all this test really
    /// does is verify that we are internally consistent in our signature logic.
    @MainActor func testSigningAndVerification() throws {
        // Arrange
        let event = try EventFixture.build(in: testContext)

        // Act
        try event.sign(withKey: KeyFixture.keyPair)

        // Assert
        XCTAssert(try event.verifySignature(for: KeyFixture.keyPair.publicKey))
    }

    @MainActor func testVerificationOnBadId() throws {
        // Arrange
        let event = try EventFixture.build(in: testContext)

        // Act
        try event.sign(withKey: KeyFixture.keyPair)
        event.identifier = "invalid"

        // Assert
        XCTAssertFalse(try event.verifySignature(for: KeyFixture.keyPair.publicKey))
    }

    @MainActor func testVerificationOnBadSignature() throws {
        // Arrange
        let event = try EventFixture.build(in: testContext)
        event.identifier = try event.calculateIdentifier()

        // Act
        event.signature = "31c710803d3b77cb2c61697c8e2a980a53ec66e980990ca34cc24f9018bf85bfd2b0" +
        "669c1404f364de776a9d9ed31a5d6d32f5662ac77f2dc6b89c7762132d63"

        // Assert
        XCTAssertFalse(try event.verifySignature(for: KeyFixture.keyPair.publicKey))
    }

    @MainActor func testFetchEventByIDPerformance() throws {
        let testEvent = try EventFixture.build(in: testContext)
        testEvent.identifier = try testEvent.calculateIdentifier()
        let eventID = testEvent.identifier!
        try testContext.save()
        measure {
            for _ in 0..<1000 {
                _ = Event.find(by: eventID, context: testContext)
            }
        }
    }

    // MARK: - Replies

    @MainActor func testReferencedNoteGivenMentionMarker() throws {
        let testEvent = try EventFixture.build(in: testContext)

        let mention = try EventReference(
            jsonTag: ["e", "646daa2f5d2d990dc98fb50a6ce8de65d77419cee689d7153c912175e85ca95d", "", "mention"],
            context: testContext
        )
        testEvent.addToEventReferences(mention)

        XCTAssertNil(testEvent.referencedNote())
    }

    @MainActor func testRepostedNote() throws {
        let testEvent = try EventFixture.build(in: testContext)
        testEvent.kind = 6

        let mention = try EventReference(
            jsonTag: ["e", "646daa2f5d2d990dc98fb50a6ce8de65d77419cee689d7153c912175e85ca95d"],
            context: testContext
        )
        testEvent.addToEventReferences(mention)

        XCTAssertEqual(
            testEvent.repostedNote()?.identifier,
            "646daa2f5d2d990dc98fb50a6ce8de65d77419cee689d7153c912175e85ca95d"
        )
    }

    @MainActor func testRepostedNoteGivenNonRepost() throws {
        let testEvent = try EventFixture.build(in: testContext)
        testEvent.kind = 1

        let mention = try EventReference(
            jsonTag: ["e", "646daa2f5d2d990dc98fb50a6ce8de65d77419cee689d7153c912175e85ca95d"],
            context: testContext
        )
        testEvent.addToEventReferences(mention)

        XCTAssertEqual(testEvent.repostedNote()?.identifier, nil)
    }

    // MARK: - Fetch requests

    @MainActor func test_eventByIdentifierSeenOnRelay_givenAlreadySeen() throws {
        // Arrange
        let eventID = "foo"
        let event = try Event.findOrCreateStubBy(id: eventID, context: testContext)
        let relay = try Relay.findOrCreate(by: "wss://relay.nos.social", context: testContext)
        event.addToSeenOnRelays(relay)
        try testContext.saveIfNeeded()

        // Act
        let events = try testContext.fetch(Event.event(by: eventID, seenOn: relay))

        // Assert
        XCTAssertEqual(events.count, 1)
        XCTAssertEqual(events.first, event)
    }

    @MainActor func test_eventByIdentifierSeenOnRelay_givenNotSeen() throws {
        // Arrange
        let eventID = "foo"
        _ = try Event.findOrCreateStubBy(id: eventID, context: testContext)
        let relay = try Relay.findOrCreate(by: "wss://relay.nos.social", context: testContext)

        // Act
        let events = try testContext.fetch(Event.event(by: eventID, seenOn: relay))

        // Assert
        XCTAssertEqual(events.count, 0)
    }

    @MainActor func test_eventByIdentifierSeenOnRelay_givenSeenOnAnother() throws {
        // Arrange
        let eventID = "foo"
        let event = try Event.findOrCreateStubBy(id: eventID, context: testContext)
        let relayOne = try Relay.findOrCreate(by: "wss://relay.nos.social", context: testContext)
        event.addToSeenOnRelays(relayOne)
        let relayTwo = try Relay.findOrCreate(by: "wss://other.relay.com", context: testContext)

        // Act
        let events = try testContext.fetch(Event.event(by: eventID, seenOn: relayTwo))

        // Assert
        XCTAssertEqual(events.count, 0)
    }

    @MainActor func test_loadAuthorsFromReferences() throws {
        // Arrange
        let eventID = "foo"
        let event = try Event.findOrCreateStubBy(id: eventID, context: testContext)
        let alice = try Author.findOrCreate(by: "alice", context: testContext)
        let bob = try Author.findOrCreate(by: "bob", context: testContext)

        let aliceAuthorReference = AuthorReference(context: testContext)
        aliceAuthorReference.pubkey = alice.hexadecimalPublicKey

        let bobAuthorReference = AuthorReference(context: testContext)
        bobAuthorReference.pubkey = bob.hexadecimalPublicKey

        event.authorReferences = [aliceAuthorReference, bobAuthorReference]

        // Act
        let references = event.loadAuthorsFromReferences(in: testContext)

        // Assert
        XCTAssertEqual(references, [alice, bob])
    }

    @MainActor func test_outOfNetwork_excludesFollowNotifications() throws {
        // Arrange
        let currentUser = try Author.findOrCreate(by: "current_user", context: testContext)
        let follower = try Author.findOrCreate(by: "follower", context: testContext)
        let unconnectedAuthor = try Author.findOrCreate(by: "unconnected", context: testContext)

        let event = Event(context: testContext)
        event.identifier = "test_event"
        event.author = unconnectedAuthor  // This would normally make it appear in outOfNetwork

        try testContext.save()

        // Act
        let fetchRequest = Event.outOfNetworkRequest(for: currentUser)
        let results = try testContext.fetch(fetchRequest)

        // Assert
        XCTAssertEqual(results.count, 0)
    }

    @MainActor func test_outOfNetwork_includesAuthorWithNoFollowers() throws {
        // Arrange
        let currentUser = try Author.findOrCreate(by: "current_user", context: testContext)
        let author = try Author.findOrCreate(by: "author", context: testContext)

        let event = Event(context: testContext)
        event.identifier = "test_event"
        event.author = author
        event.kind = EventKind.text.rawValue

        // Create an author reference to represent the mention
        let mention = AuthorReference(context: testContext)
        mention.pubkey = currentUser.hexadecimalPublicKey
        mention.event = event
        event.addToAuthorReferences(mention)

        try testContext.save()

        // Act
        let fetchRequest = Event.outOfNetworkRequest(for: currentUser)
        let results = try testContext.fetch(fetchRequest)

        // Assert
        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results.first?.author?.hexadecimalPublicKey, author.hexadecimalPublicKey)
    }

    @MainActor func test_outOfNetwork_excludesDirectlyFollowedAuthor() throws {
        // Arrange
        let currentUser = try Author.findOrCreate(by: "current_user", context: testContext)
        let bob = try Author.findOrCreate(by: "bob", context: testContext)

        // Current user follows bob
        let follow = Follow(context: testContext)
        follow.source = currentUser
        follow.destination = bob

        let event = Event(context: testContext)
        event.identifier = "test_event"
        event.author = bob

        try testContext.save()

        // Act
        let fetchRequest = Event.outOfNetworkRequest(for: currentUser)
        let results = try testContext.fetch(fetchRequest)

        // Assert
        XCTAssertEqual(results.count, 0)
    }

    @MainActor func test_outOfNetwork_excludesIndirectlyConnectedAuthor() throws {
        // Arrange
        let currentUser = try Author.findOrCreate(by: "current_user", context: testContext)
        let alice = try Author.findOrCreate(by: "alice", context: testContext)
        let bob = try Author.findOrCreate(by: "bob", context: testContext)

        // Create follow chain: currentUser -> alice -> bob
        let currentUserFollowsAlice = Follow(context: testContext)
        currentUserFollowsAlice.source = currentUser
        currentUserFollowsAlice.destination = alice

        let aliceFollowsBob = Follow(context: testContext)
        aliceFollowsBob.source = alice
        aliceFollowsBob.destination = bob

        let event = Event(context: testContext)
        event.identifier = "test_event"
        event.author = bob

        try testContext.save()

        // Act
        let fetchRequest = Event.outOfNetworkRequest(for: currentUser)
        let results = try testContext.fetch(fetchRequest)

        // Assert
        XCTAssertEqual(results.count, 0)
    }

    // MARK: - In Network Request Tests

    @MainActor func test_inNetwork_includesDirectlyFollowedAuthor() throws {
        // Arrange
        let currentUser = try Author.findOrCreate(by: "current_user", context: testContext)
        let alice = try Author.findOrCreate(by: "alice", context: testContext)

        // Create follow relationship
        let currentUserFollowsAlice = Follow(context: testContext)
        currentUserFollowsAlice.source = currentUser
        currentUserFollowsAlice.destination = alice

        let event = Event(context: testContext)
        event.identifier = "test_event"
        event.author = alice
        event.kind = 1

        // Create an author reference to represent the mention
        let mention = AuthorReference(context: testContext)
        mention.pubkey = currentUser.hexadecimalPublicKey
        mention.event = event
        event.addToAuthorReferences(mention)

        try testContext.save()

        // Act
        let fetchRequest = Event.inNetworkRequest(for: currentUser)
        let results = try testContext.fetch(fetchRequest)

        // Assert
        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results.first?.author?.hexadecimalPublicKey, alice.hexadecimalPublicKey)
    }

    @MainActor func test_inNetwork_includesIndirectlyConnectedAuthor() throws {
        // Arrange
        let currentUser = try Author.findOrCreate(by: "current_user", context: testContext)
        let alice = try Author.findOrCreate(by: "alice", context: testContext)
        let bob = try Author.findOrCreate(by: "bob", context: testContext)

        // Create follow chain: currentUser -> alice -> bob
        let currentUserFollowsAlice = Follow(context: testContext)
        currentUserFollowsAlice.source = currentUser
        currentUserFollowsAlice.destination = alice

        let aliceFollowsBob = Follow(context: testContext)
        aliceFollowsBob.source = alice
        aliceFollowsBob.destination = bob

        let event = Event(context: testContext)
        event.identifier = "test_event"
        event.author = bob
        event.kind = 1

        // Create an author reference to represent the mention
        let mention = AuthorReference(context: testContext)
        mention.pubkey = currentUser.hexadecimalPublicKey
        mention.event = event
        event.addToAuthorReferences(mention)

        try testContext.save()

        // Act
        let fetchRequest = Event.inNetworkRequest(for: currentUser)
        let results = try testContext.fetch(fetchRequest)

        // Assert
        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results.first?.author?.hexadecimalPublicKey, bob.hexadecimalPublicKey)
    }

    @MainActor func test_inNetwork_excludesAuthorWithNoConnection() throws {
        // Arrange
        let currentUser = try Author.findOrCreate(by: "current_user", context: testContext)
        let unconnectedAuthor = try Author.findOrCreate(by: "unconnected", context: testContext)

        let event = Event(context: testContext)
        event.identifier = "test_event"
        event.author = unconnectedAuthor

        try testContext.save()

        // Act
        let fetchRequest = Event.inNetworkRequest(for: currentUser)
        let results = try testContext.fetch(fetchRequest)

        // Assert
        XCTAssertEqual(results.count, 0)
    }

    @MainActor func test_inNetwork_excludesFollowEvents() throws {
        // Arrange
        let currentUser = try Author.findOrCreate(by: "current_user", context: testContext)
        let follower = try Author.findOrCreate(by: "follower", context: testContext)

        // Create follow relationship to ensure the author would be "in network"
        let follow = Follow(context: testContext)
        follow.source = currentUser
        follow.destination = follower

        let event = Event(context: testContext)
        event.identifier = "test_event"
        event.author = follower  // This would normally make it appear in inNetwork

        try testContext.save()

        // Act
        let fetchRequest = Event.inNetworkRequest(for: currentUser)
        let results = try testContext.fetch(fetchRequest)

        // Assert
        XCTAssertEqual(results.count, 0)
    }
}

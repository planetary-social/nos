//
//  EventTests.swift
//  NosTests
//
//  Created by Matthew Lorentz on 1/31/23.
//

import XCTest
import CoreData
import secp256k1
import secp256k1_bindings
import Dependencies

/// Tests for the Event model.
final class EventTests: CoreDataTestCase {
    
    // swiftlint:disable line_length
    // swiftlint:disable indentation_width
    let sampleEventJSONString =
        """
        {
          "kind": 1,
          "content": "Testing nos #[0]",
          "tags": [
            [
              "p",
              "d0a1ffb8761b974cec4a3be8cbcb2e96a7090dcf465ffeac839aa4ca20c9a59e"
            ]
          ],
          "created_at": 1675264762,
          "pubkey": "32730e9dfcab797caf8380d096e548d9ef98f3af3000542f9271a91a9e3b0001",
          "id": "931b425e55559541451ddb99bd228bd1e0190af6ed21603b6b98544b42ee3317",
          "sig": "79862bd81b316411c23467632239750c97f3aa974593c01bd61d2ca85eedbcfd9a18886b0dad1c17b2e8ceb231db37add136fc23120b45aa5403d6fd2d693e9b"
        }
        """
    
    let sampleContactListJSONString =
        """
        {
          "kind": 3,
          "content": "Testing nos #[0]",
          "tags": [
            [
              "p",
              "d0a1ffb8761b974cec4a3be8cbcb2e96a7090dcf465ffeac839aa4ca20c9a59e",
              "wss://nostr.lorentz.is/",
              "Test Name"
            ]
          ],
          "created_at": 1675264762,
          "pubkey": "32730e9dfcab797caf8380d096e548d9ef98f3af3000542f9271a91a9e3b0001",
          "id": "404c87ca6095233cb82b35e2d39d82514124f933addd5514d3dc862b30e4cb4d",
          "sig": "a01fa191a0236ffe5ee1fbd9401cd7b1da7daad5e19a25962eb7ea4c9335522478bdff255f1de40ca6c98cdf8cf26aa1f5f1b6c263c5004b0b6dcdc12573cfd7"
        }
        """
    // swiftlint:enable indentation_width
    
    let sampleEventSignature = "31c710803d3b77cb2c61697c8e2a980a53ec66e980990ca34cc24f9018bf85bfd2b0669c1404f364de776a9d9ed31a5d6d32f5662ac77f2dc6b89c7762132d63"
    let sampleEventPubKey = "d0a1ffb8761b974cec4a3be8cbcb2e96a7090dcf465ffeac839aa4ca20c9a59e"
    let sampleEventContent = "Spent today on our company retreat talking a lot about Nostr. The team seems very keen to build something in this space. It’s exciting to be opening our minds to so many possibilities after being deep in the Scuttlebutt world for so long."
    let sampleRelay = "wss://nostr.lorentz.is"
    let sampleName = "Test Name"
    
    let sampleContactListSignature = "a01fa191a0236ffe5ee1fbd9401cd7b1da7daad5e19a25962eb7ea4c9335522478bdff255f1de40ca6c98cdf8cf26aa1f5f1b6c263c5004b0b6dcdc12573cfd7"
    
    // swiftlint:enable line_length

    func testParseSampleData() throws {
        // Arrange
        let sampleData = try Data(contentsOf: Bundle.current.url(forResource: "sample_data", withExtension: "json")!)
        let sampleEventID = "afc8a1cf67bddd12595c801bdc8c73ec1e8dfe94920f6c5ae5575c433722840e"
        
        // Act
        let events = try EventProcessor.parse(
            jsonData: sampleData,
            from: nil,
            in: persistenceController
        )
        let sampleEvent = try XCTUnwrap(events.first(where: { $0.identifier == sampleEventID }))
        
        // Assert
        XCTAssertEqual(events.count, 115)
        XCTAssertEqual(sampleEvent.signature, sampleEventSignature)
        XCTAssertEqual(sampleEvent.kind, 1)
        XCTAssertEqual(sampleEvent.author?.hexadecimalPublicKey, sampleEventPubKey)
        XCTAssertEqual(sampleEvent.content, sampleEventContent)
        XCTAssertEqual(sampleEvent.createdAt?.timeIntervalSince1970, 1_674_624_689)
    }
    
    func testParseSampleRepliesAndFetchReplies() throws {
        // Arrange
        let sampleData = try Data(contentsOf: Bundle.current.url(forResource: "sample_replies", withExtension: "json")!)
        let sampleEventID = "57b994eb5903d37ee11d507872611eec843098d24eb5d21a1678983dffd92b86"
        
        // Act
        let events = try EventProcessor.parse(jsonData: sampleData, from: nil, in: persistenceController)
        let sampleEvent = try XCTUnwrap(events.first(where: { $0.identifier == sampleEventID }))

        let fetchRequest: NSFetchRequest<Event> = Event.allReplies(to: sampleEvent)
        let replies = try? testContext.fetch(fetchRequest) as [Event]
    
        // Assert
        XCTAssertEqual(events.count, 3)
        XCTAssertEqual(replies?.count, 2)
    }
    
    func testParseRepost() throws {
        // Arrange
        let sampleData = try Data(contentsOf: Bundle.current.url(forResource: "sample_repost", withExtension: "json")!)
        let sampleEventID = "f41e430f632b1e747da7efbb0ce11616876851e2fa3bbac440101c1b8a091152"
        let repostedEventID = "f82507f7c770a39d0eabf276ced34fbd6a172be869bd3a3231c9c0272f405008"
        let repostedEventContents = "#kraftwerk https://v.nostr.build/lx7e.mp4 "
        
        // Act
        let events = try EventProcessor.parse(jsonData: sampleData, from: nil, in: persistenceController)
        let sampleEvent = try XCTUnwrap(events.first(where: { $0.identifier == sampleEventID }))
        
        // Assert
        XCTAssertEqual(sampleEvent.identifier, sampleEventID)
        let repostedEvent = try XCTUnwrap(sampleEvent.repostedNote())
        XCTAssertEqual(repostedEvent.identifier, repostedEventID)
        XCTAssertEqual(repostedEvent.content, repostedEventContents)
    }
    
    func testSerializedEventForSigning() throws {
        // Arrange
        let event = try createTestEvent(in: testContext)
        // swiftlint:disable line_length
        let expectedString = """
        [0,"32730e9dfcab797caf8380d096e548d9ef98f3af3000542f9271a91a9e3b0001",1675264762,1,[["p","d0a1ffb8761b974cec4a3be8cbcb2e96a7090dcf465ffeac839aa4ca20c9a59e"]],"Testing nos #[0]"]
        """.trimmingCharacters(in: .whitespacesAndNewlines)
        // swiftlint:enable line_length
        
        // Act
        let serializedData = try JSONSerialization.data(withJSONObject: event.serializedEventForSigning)
        let actualString = String(data: serializedData, encoding: .utf8)
        
        // Assert
        XCTAssertEqual(actualString, expectedString)
    }
    
    func testIdentifierCalculation() throws {
        // Arrange
        let event = try createTestEvent(in: testContext)
        
        // Act
        XCTAssertEqual(
            try event.calculateIdentifier(),
            "931b425e55559541451ddb99bd228bd1e0190af6ed21603b6b98544b42ee3317"
        )
    }
    
    func testIdentifierCalculationWithNoTags() throws {
        // Arrange
        let event = try createTestEventWithNoTags(in: testContext)
        // Act
        XCTAssertEqual(
            try event.calculateIdentifier(),
            "9b906de1db4ae84bda4b61b94724f8dfddd6fd9e6acddfe7ed79accb50052570"
        )
    }

    func testParseContactList() throws {
        // Arrange
        guard let jsonData = sampleContactListJSONString.data(using: .utf8) else {
            XCTFail("Sample data cannot be parsed")
            return
        }

        let jsonEvent = try JSONDecoder().decode(JSONEvent.self, from: jsonData)
        let context = persistenceController.viewContext

        // Act
        let parsedEvent = try EventProcessor.parse(jsonEvent: jsonEvent, from: nil, in: context)!
         
        // Assert
        XCTAssertEqual(parsedEvent.signature, sampleContactListSignature)
        XCTAssertEqual(parsedEvent.kind, 3)
        XCTAssertEqual(parsedEvent.author?.follows.count, 1)
        XCTAssertEqual(parsedEvent.author?.hexadecimalPublicKey, KeyFixture.pubKeyHex)
        XCTAssertEqual(parsedEvent.createdAt?.timeIntervalSince1970, 1_675_264_762)
        
        guard let follow = parsedEvent.author?.follows.first as? Follow else {
            XCTFail("Tag is not of the Follow type")
            return
        }
        
        XCTAssertEqual(parsedEvent.author?.relays.count, 1)
        let relay = parsedEvent.author!.relays.first!
        XCTAssertEqual(relay.address, sampleRelay)
        XCTAssertEqual(follow.petName, sampleName)
    }
    
    func testParseContactListIgnoresInvalidKeys() throws {
        // Arrange
        let jsonData = try Data(contentsOf: Bundle.current.url(forResource: "bad_contact_list", withExtension: "json")!)
        let jsonEvent = try JSONDecoder().decode(JSONEvent.self, from: jsonData)

        // Act
        let parsedEvent = try EventProcessor.parse(jsonEvent: jsonEvent, from: nil, in: testContext)!
         
        // Assert
        let follows = try XCTUnwrap(parsedEvent.author?.follows)
        XCTAssertEqual(follows.count, 1)
    }
    
    func testParseExpirationDate() throws {
        // Arrange
        guard let jsonData = sampleEventJSONString.data(using: .utf8) else {
            XCTFail("Sample data cannot be parsed")
            return
        }
        
        var jsonEvent = try JSONDecoder().decode(JSONEvent.self, from: jsonData)
        jsonEvent.tags = [["expiration", "2378572992"]]
        let context = persistenceController.viewContext
        
        // Act
        let parsedEvent = try EventProcessor.parse(
            jsonEvent: jsonEvent, 
            from: nil, 
            in: context, 
            skipVerification: true
        )!
        
        // Assert
        XCTAssertEqual(parsedEvent.expirationDate?.timeIntervalSince1970, 2_378_572_992)
    }
    
    func testParseExpirationDateDouble() throws {
        // Arrange
        guard let jsonData = sampleEventJSONString.data(using: .utf8) else {
            XCTFail("Sample data cannot be parsed")
            return
        }
        
        var jsonEvent = try JSONDecoder().decode(JSONEvent.self, from: jsonData)
        jsonEvent.tags = [["expiration", "2378572992.123"]]
        let context = persistenceController.viewContext
        
        // Act
        let parsedEvent = try EventProcessor.parse(
            jsonEvent: jsonEvent, 
            from: nil, 
            in: context, 
            skipVerification: true
        )!
        
        // Assert
        XCTAssertEqual(parsedEvent.expirationDate!.timeIntervalSince1970, 2_378_572_992.123, accuracy: 0.001)
    }
    
    func testExpiredEventNotSaved() throws {
        // Arrange
        guard let jsonData = sampleEventJSONString.data(using: .utf8) else {
            XCTFail("Sample data cannot be parsed")
            return
        }
        
        var jsonEvent = try JSONDecoder().decode(JSONEvent.self, from: jsonData)
        jsonEvent.tags = [["expiration", "1"]]
        let context = persistenceController.viewContext
        
        // Act & Assert
        XCTAssertThrowsError(try EventProcessor.parse(
            jsonEvent: jsonEvent, 
            from: nil, 
            in: context, 
            skipVerification: true
        ))
    }
    
    /// Verifies that when we see an event we already have in Core Data as a stub it is updated correctly.
    func testParsingEventStub() throws {
        let referencingJSONEvent = JSONEvent(
            id: "1",
            pubKey: KeyFixture.alice.publicKeyHex,
            createdAt: 1,
            kind: 1,
            tags: [["e", "2"]],
            content: "Hello, bob",
            signature: "sig1"
        )
        
        let referencingEvent = try EventProcessor.parse(
            jsonEvent: referencingJSONEvent,
            from: nil,
            in: testContext,
            skipVerification: true
        )!
        try testContext.save()
        
        var allEvents = try testContext.fetch(Event.allEventsRequest())
        XCTAssertEqual(allEvents.count, 2)
        XCTAssertEqual(referencingEvent.eventReferences.count, 1)
        var eventReference = referencingEvent.eventReferences.firstObject as! EventReference
        XCTAssertEqual(eventReference.referencedEvent?.isStub, true)
        
        let referencedJSONEvent = JSONEvent(
            id: "2",
            pubKey: KeyFixture.bob.publicKeyHex,
            createdAt: 2,
            kind: 1,
            tags: [],
            content: "hello, world",
            signature: "sig2"
        )
        let referencedEvent = try EventProcessor.parse(
            jsonEvent: referencedJSONEvent,
            from: nil,
            in: testContext,
            skipVerification: true
        )!
        try testContext.save()
        
        allEvents = try testContext.fetch(Event.allEventsRequest())
        XCTAssertEqual(allEvents.count, 2)
        XCTAssertEqual(referencedEvent.referencingEvents.count, 1)
        eventReference = referencedEvent.referencingEvents.first! 
        XCTAssertEqual(eventReference.referencingEvent, referencingEvent)
    }
    
    // MARK: - Signatures and Verification
    
    /// Verifies that we can sign an event and verify it.
    /// Since Schnorr signatures are non-deterministic we can't assert on constants. That's why all this test really
    /// does is verify that we are internally consistent in our signature logic.
    func testSigningAndVerification() throws {
        // Arrange
        let event = try createTestEvent(in: testContext)
        
        // Act
        try event.sign(withKey: KeyFixture.keyPair)
        
        // Assert
        XCTAssert(try KeyFixture.keyPair.publicKey.verifySignature(on: event))
    }
    
    func testVerificationOnBadId() throws {
        // Arrange
        let event = try createTestEvent(in: testContext)
        
        // Act
        try event.sign(withKey: KeyFixture.keyPair)
        event.identifier = "invalid"
        
        // Assert
        XCTAssertFalse(try KeyFixture.keyPair.publicKey.verifySignature(on: event))
    }
    
    func testVerificationOnBadSignature() throws {
        // Arrange
        let event = try createTestEvent(in: testContext)
        event.identifier = try event.calculateIdentifier()
        
        // Act
        event.signature = "31c710803d3b77cb2c61697c8e2a980a53ec66e980990ca34cc24f9018bf85bfd2b0" +
            "669c1404f364de776a9d9ed31a5d6d32f5662ac77f2dc6b89c7762132d63"
        
        // Assert
        XCTAssertFalse(try KeyFixture.keyPair.publicKey.verifySignature(on: event))
    }

    func testFetchEventByIDPerformance() throws {
        let testEvent = try createTestEvent(in: testContext)
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
    
    func testReferencedNoteGivenMentionMarker() throws {
        let testEvent = try createTestEvent(in: testContext)
        
        let mention = try EventReference(
            jsonTag: ["e", "646daa2f5d2d990dc98fb50a6ce8de65d77419cee689d7153c912175e85ca95d", "", "mention"], 
            context: testContext
        )
        testEvent.addToEventReferences(mention)
        
        XCTAssertNil(testEvent.referencedNote())
    }
    
    func testRepostedNote() throws {
        let testEvent = try createTestEvent(in: testContext)
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
    
    func testRepostedNoteGivenNonRepost() throws {
        let testEvent = try createTestEvent(in: testContext)
        testEvent.kind = 1
        
        let mention = try EventReference(
            jsonTag: ["e", "646daa2f5d2d990dc98fb50a6ce8de65d77419cee689d7153c912175e85ca95d"], 
            context: testContext
        )
        testEvent.addToEventReferences(mention)
        
        XCTAssertEqual(testEvent.repostedNote()?.identifier, nil)
    }

    // MARK: - Helpers
    
    private func createTestEvent(
        in context: NSManagedObjectContext,
        publicKey: RawAuthorID = KeyFixture.pubKeyHex
    ) throws -> Event {
        let event = Event(context: context)
        event.createdAt = Date(timeIntervalSince1970: TimeInterval(1_675_264_762))
        event.content = "Testing nos #[0]"
        event.kind = 1
        
        let author = Author(context: context)
        author.hexadecimalPublicKey = publicKey
        event.author = author
        
        let tags = [["p", "d0a1ffb8761b974cec4a3be8cbcb2e96a7090dcf465ffeac839aa4ca20c9a59e"]]
        event.allTags = tags as NSObject
        return event
    }
    
    private func createTestEventWithNoTags(
        in context: NSManagedObjectContext,
        publicKey: RawAuthorID = KeyFixture.pubKeyHex
    ) throws -> Event {
        let event = Event(context: context)
        event.createdAt = Date(timeIntervalSince1970: TimeInterval(1_675_264_762))
        event.content = "Testing nos #[0]"
        event.kind = 1
        
        let author = Author(context: context)
        author.hexadecimalPublicKey = publicKey
        event.author = author
        
        return event
    }
}

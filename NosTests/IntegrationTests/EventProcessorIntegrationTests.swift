import CoreData
import XCTest
import Dependencies

/// Tests for `EventProcessor` which calls methods on `Event`, hence the name "IntegrationTests".
class EventProcessorIntegrationTests: CoreDataTestCase {
    // swiftlint:disable line_length

    let sampleEventSignature = "31c710803d3b77cb2c61697c8e2a980a53ec66e980990ca34cc24f9018bf85bfd2b0669c1404f364de776a9d9ed31a5d6d32f5662ac77f2dc6b89c7762132d63"
    let sampleEventPubKey = "d0a1ffb8761b974cec4a3be8cbcb2e96a7090dcf465ffeac839aa4ca20c9a59e"
    let sampleEventContent = "Spent today on our company retreat talking a lot about Nostr. The team seems very keen to build something in this space. It’s exciting to be opening our minds to so many possibilities after being deep in the Scuttlebutt world for so long."

    // swiftlint:enable line_length

    // MARK: - Event Parsing

    func testParseSampleData() throws {
        // Arrange
        let sampleData = try jsonData(filename: "sample_data")
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

    func testParseLongFormContentWithReplaceableIdentifier() throws {
        // Arrange
        let data = try jsonData(filename: "long_form_data")

        // Act
        let events = try EventProcessor.parse(
            jsonData: data,
            from: nil,
            in: persistenceController
        )

        // Assert
        XCTAssertEqual(events.count, 1)
        let event = try XCTUnwrap(events.first)
        XCTAssertEqual(event.identifier, "01b86b45fa23be9c4f7bb2615274fcfab6241a8809a09094b4276cc36590255a")
        XCTAssertEqual(event.replaceableIdentifier, "TGnBRh9-b1jrqSJ-ByWQx")
        XCTAssertEqual(
            event.author?.hexadecimalPublicKey, "0267aa3d92d2a479ad6bccdc6fe7657037deab4b77a8bbcfd3663b0eef196b58"
        )
        XCTAssertEqual(event.kind, EventKind.longFormContent.rawValue)
    }

    @MainActor func testParseLongFormContentHydratesStubWithOnlyIdentifier() async throws {
        // Arrange
        let data = try jsonData(filename: "long_form_data")

        _ = try Event.findOrCreateStubBy(
            id: "01b86b45fa23be9c4f7bb2615274fcfab6241a8809a09094b4276cc36590255a",
            context: testContext
        )
        try testContext.save()

        // Act
        let events = try EventProcessor.parse(jsonData: data, from: nil, in: persistenceController)

        XCTAssertEqual(events.count, 1)
        let event = try XCTUnwrap(events.first)
        XCTAssertEqual(event.identifier, "01b86b45fa23be9c4f7bb2615274fcfab6241a8809a09094b4276cc36590255a")
        XCTAssertEqual(event.replaceableIdentifier, "TGnBRh9-b1jrqSJ-ByWQx")
        XCTAssertEqual(
            event.author?.hexadecimalPublicKey, "0267aa3d92d2a479ad6bccdc6fe7657037deab4b77a8bbcfd3663b0eef196b58"
        )
        XCTAssertEqual(event.kind, EventKind.longFormContent.rawValue)
    }

    @MainActor func testParseLongFormContentHydratesStubWithReplaceableIdentifier() async throws {
        // Arrange
        let data = try jsonData(filename: "long_form_data")

        _ = try Event.findOrCreateStubBy(
            replaceableID: "TGnBRh9-b1jrqSJ-ByWQx",
            authorID: "0267aa3d92d2a479ad6bccdc6fe7657037deab4b77a8bbcfd3663b0eef196b58",
            kind: 30_023,
            context: testContext
        )
        try testContext.save()

        // Act
        let events = try EventProcessor.parse(jsonData: data, from: nil, in: persistenceController)

        XCTAssertEqual(events.count, 1)
        let event = try XCTUnwrap(events.first)
        XCTAssertEqual(event.identifier, "01b86b45fa23be9c4f7bb2615274fcfab6241a8809a09094b4276cc36590255a")
        XCTAssertEqual(event.replaceableIdentifier, "TGnBRh9-b1jrqSJ-ByWQx")
        XCTAssertEqual(
            event.author?.hexadecimalPublicKey, "0267aa3d92d2a479ad6bccdc6fe7657037deab4b77a8bbcfd3663b0eef196b58"
        )
        XCTAssertEqual(event.kind, EventKind.longFormContent.rawValue)
    }

    func testParseOnlySupportedKinds() throws {
        // Arrange
        let sampleData = try jsonData(filename: "unsupported_kinds")

        // Act
        let events = try EventProcessor.parse(
            jsonData: sampleData,
            from: nil,
            in: persistenceController
        )

        // Assert
        XCTAssertEqual(events.count, 0)
    }

    @MainActor func testParseSampleRepliesAndFetchReplies() throws {
        // Arrange
        let sampleData = try jsonData(filename: "sample_replies")
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
        let sampleData = try jsonData(filename: "sample_repost")
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

    /// When we get a duplicate event, verify that it's marked as seen.
    func testParseDuplicateIsMarkedSeen() throws {
        // Arrange
        let textData = try jsonData(filename: "text_note")
        let textEvent = try JSONDecoder().decode(JSONEvent.self, from: textData)
        let context = persistenceController.viewContext
        let parsedEvent = try EventProcessor.parse(jsonEvent: textEvent, from: nil, in: context)

        // Act
        let relay = Relay(context: context)
        relay.address = "wss://test.example.com"
        _ = try EventProcessor.parse(jsonEvent: textEvent, from: relay, in: context)

        // Assert
        XCTAssertTrue(parsedEvent!.seenOnRelays.contains(relay))
    }

    // MARK: - Contact List parsing

    func testParseContactList() throws {
        // Arrange
        let contactListData = try jsonData(filename: "contact_list")
        let jsonEvent = try JSONDecoder().decode(JSONEvent.self, from: contactListData)
        let context = persistenceController.viewContext
        let sampleRelay = "wss://nostr.lorentz.is"
        let sampleName = "Test Name"
        let sampleContactListSignature = "a01fa191a0236ffe5ee1fbd9401cd7b1da7daad5e19a25962eb7ea4c9335522478bdff255f1de40ca6c98cdf8cf26aa1f5f1b6c263c5004b0b6dcdc12573cfd7" // swiftlint:disable:this line_length

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

    @MainActor func testParseContactListIgnoresInvalidKeys() throws {
        // Arrange
        let jsonData = try jsonData(filename: "bad_contact_list")
        let jsonEvent = try JSONDecoder().decode(JSONEvent.self, from: jsonData)

        // Act
        let parsedEvent = try EventProcessor.parse(jsonEvent: jsonEvent, from: nil, in: testContext)!

        // Assert
        let follows = try XCTUnwrap(parsedEvent.author?.follows)
        XCTAssertEqual(follows.count, 1)
    }

    /// When we get an old contact list, ignore it.
    func testParseContactListIgnoresOldList() throws {
        // Arrange
        let contactListData = try jsonData(filename: "contact_list")
        let contactListEvent = try JSONDecoder().decode(JSONEvent.self, from: contactListData)

        let context = persistenceController.viewContext
        _ = try EventProcessor.parse(jsonEvent: contactListEvent, from: nil, in: context)!

        let oldContactListData = try jsonData(filename: "old_contact_list")
        var oldContactListEvent = try JSONDecoder().decode(JSONEvent.self, from: oldContactListData)
        try oldContactListEvent.sign(withKey: KeyFixture.keyPair)

        // Act
        let event = try EventProcessor.parse(jsonEvent: oldContactListEvent, from: nil, in: context)

        // Assert
        XCTAssertEqual(event?.author?.follows.count, 1)
    }

    /// When we get a new list, replace the old one.
    func testParseContactListUsesNewList() throws {
        // Arrange
        let contactListData = try jsonData(filename: "contact_list")
        let contactListEvent = try JSONDecoder().decode(JSONEvent.self, from: contactListData)

        let context = persistenceController.viewContext
        _ = try EventProcessor.parse(jsonEvent: contactListEvent, from: nil, in: context)!

        let newContactListData = try jsonData(filename: "new_contact_list")
        var newContactListEvent = try JSONDecoder().decode(JSONEvent.self, from: newContactListData)
        try newContactListEvent.sign(withKey: KeyFixture.keyPair)

        // Act
        let event = try EventProcessor.parse(jsonEvent: newContactListEvent, from: nil, in: context)

        // Assert
        XCTAssertEqual(event?.author?.follows.count, 2)
    }
    
    // MARK: - Mute List parsing
    
    @MainActor func test_parseMuteList_mutesNewUsers() async throws {
        // Arrange
        let muteListData = try jsonData(filename: "mute_list")
        let jsonEvent = try JSONDecoder().decode(JSONEvent.self, from: muteListData)
        
        let mutedUserOne = "756bcacddd4fd7051cde3e39464cdd3557fec416ab1f496e2e91da0534b14272"
        let mutedUserTwo = "d0a1ffb8761b974cec4a3be8cbcb2e96a7090dcf465ffeac839aa4ca20c9a59e"
        let mutedUserThree = "27cf2c68535ae1fc06510e827670053f5dcd39e6bd7e05f1ffb487ef2ac13549"
        let nonMutedUser = try Author.findOrCreate(
            by: "31c7f8c1a6c81eef0029c1a91a52f5da29dc14c599bfb0c93b645207e8413cfd",
            context: testContext
        )
        
        // Act
        let parsedEvent = try EventProcessor.parse(jsonEvent: jsonEvent, from: nil, in: testContext)!
        
        // Assert
        XCTAssertEqual(parsedEvent.identifier, "f1171a8ef1983fb1d55089092da5e7bbcb204bf9219697a3cf08d8e53ddbcec5")
        XCTAssertEqual(try Author.find(by: mutedUserOne, context: testContext)?.muted, true)
        XCTAssertEqual(try Author.find(by: mutedUserTwo, context: testContext)?.muted, true)
        XCTAssertEqual(try Author.find(by: mutedUserThree, context: testContext)?.muted, true)
        
        // sanity check
        XCTAssertEqual(try Author.find(by: nonMutedUser.hexadecimalPublicKey!, context: testContext)?.muted, false)
    }
    
    @MainActor func test_parseMuteList_unmutesUsers() async throws {
        // Arrange
        let muteListData = try jsonData(filename: "mute_list_2")
        let jsonEvent = try JSONDecoder().decode(JSONEvent.self, from: muteListData)
        
        let mutedUserOne = "756bcacddd4fd7051cde3e39464cdd3557fec416ab1f496e2e91da0534b14272"
        let mutedUserTwo = "d0a1ffb8761b974cec4a3be8cbcb2e96a7090dcf465ffeac839aa4ca20c9a59e"
        let unmutedUser = "27cf2c68535ae1fc06510e827670053f5dcd39e6bd7e05f1ffb487ef2ac13549"
        
        // Start with all users muted
        try Author.findOrCreate(by: mutedUserOne, context: testContext).muted = true
        try Author.findOrCreate(by: mutedUserTwo, context: testContext).muted = true
        try Author.findOrCreate(by: unmutedUser, context: testContext).muted = true
        try testContext.save()
        
        // Act
        _ = try EventProcessor.parse(jsonEvent: jsonEvent, from: nil, in: testContext)!
        
        // Assert
        XCTAssertEqual(try Author.find(by: mutedUserOne, context: testContext)?.muted, true)
        XCTAssertEqual(try Author.find(by: mutedUserTwo, context: testContext)?.muted, true)
        XCTAssertEqual(try Author.find(by: unmutedUser, context: testContext)?.muted, false)
    }
    
    @MainActor func test_parseMuteList_skipsOldList() async throws {
        // Arrange
        let mutedUserOne = "756bcacddd4fd7051cde3e39464cdd3557fec416ab1f496e2e91da0534b14272"
        let mutedUserTwo = "d0a1ffb8761b974cec4a3be8cbcb2e96a7090dcf465ffeac839aa4ca20c9a59e"
        let mutedUserThree = "27cf2c68535ae1fc06510e827670053f5dcd39e6bd7e05f1ffb487ef2ac13549"
        
        let oldMuteListData = try jsonData(filename: "mute_list")
        let newMuteListData = try jsonData(filename: "mute_list_2")
        let oldMuteListEvent = try JSONDecoder().decode(JSONEvent.self, from: oldMuteListData)
        let newMuteListEvent = try JSONDecoder().decode(JSONEvent.self, from: newMuteListData)
        
        // Act 
        // process the newer event first and then the old event
        _ = try EventProcessor.parse(jsonEvent: newMuteListEvent, from: nil, in: testContext)!
        _ = try EventProcessor.parse(jsonEvent: oldMuteListEvent, from: nil, in: testContext)!
        
        // Assert
        // The third user should not be muted because they are not muted in the newer list.
        XCTAssertEqual(try Author.find(by: mutedUserOne, context: testContext)?.muted, true)
        XCTAssertEqual(try Author.find(by: mutedUserTwo, context: testContext)?.muted, true)
        XCTAssertEqual(try Author.find(by: mutedUserThree, context: testContext)?.muted, nil)
    }
    
    @MainActor func test_parseMuteList_unMutesSelf() async throws {
        // Arrange
        let keyPair = KeyPair(nsec: "nsec17vdaesh5tp6u5dy74vdy7a7e5x5ww4wfdnrn6ewgnsfxav8pcurqnlmj88")
        @Dependency(\.currentUser) var currentUser
        await currentUser.setKeyPair(keyPair)
        
        let muteListData = try jsonData(filename: "mute_list_self")
        let jsonEvent = try JSONDecoder().decode(JSONEvent.self, from: muteListData)
        
        // Act
        _ = try EventProcessor.parse(jsonEvent: jsonEvent, from: nil, in: testContext)!
        
        XCTAssertEqual(try Author.find(by: keyPair!.publicKeyHex, context: testContext)?.muted, false)
    }

    // MARK: - Zap Receipt/Request parsing
    
    /// When a zap receipt event is parsed, expect that its embedded zap request is also parsed.
    func testParseZapReceiptAndEmbeddedZapRequest() throws {
        // Arrange
        let zapReceiptData = try jsonData(filename: "zap_receipt")
        let zapReceiptJSONEvent = try JSONDecoder().decode(JSONEvent.self, from: zapReceiptData)

        let context = persistenceController.viewContext
        
        // Act
        try EventProcessor.parse(jsonEvent: zapReceiptJSONEvent, from: nil, in: context)
        
        // Assert
        
        // zap receipt
        let zapReceiptEventID = "9e722b2b62772f9f48c786e084038ffc039f5600bace1f068bcc2307a5de1553"
        let zapReceiptEvent = try XCTUnwrap(Event.find(by: zapReceiptEventID, context: context))
        
        XCTAssertEqual(zapReceiptEvent.kind, EventKind.zapReceipt.rawValue)
        
        let walletPubKey = "8b7cd4981e30ed2dd6b5ef1f816763453b282b3e44f41ef2a3da77ff5ef8d141"
        XCTAssertEqual(zapReceiptEvent.author?.hexadecimalPublicKey, walletPubKey)
        XCTAssertEqual(zapReceiptEvent.createdAt?.timeIntervalSince1970, 1_722_712_858)
        
        // embedded zap request
        let zapRequestEventID = "6715260809f6f62ea82f8b213ca4cc0abd0426dc860f1c963c0f0207f9fadddb"
        let zapRequestEvent = try XCTUnwrap(Event.find(by: zapRequestEventID, context: context))
        
        XCTAssertEqual(zapRequestEvent.kind, EventKind.zapRequest.rawValue)
        
        let zapSenderPubKey = "2656d1495cccf384035a59cce13451c6f280a329f0d1b3bb6758b4830f67909c"
        XCTAssertEqual(zapRequestEvent.author?.hexadecimalPublicKey, zapSenderPubKey)
        XCTAssertEqual(zapRequestEvent.createdAt?.timeIntervalSince1970, 1_722_712_850)
    }
    
    // MARK: - Expiration

    func testParseExpirationDate() throws {
        // Arrange
        let jsonData = try jsonData(filename: "text_note")
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
        let jsonData = try jsonData(filename: "text_note")
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
        let jsonData = try jsonData(filename: "text_note")
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

    // MARK: - Stub

    /// Verifies that when we see an event we already have in Core Data as a stub it is updated correctly.
    @MainActor func testParsingEventStub() throws {
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
        var eventReference = referencingEvent.eventReferences.firstObject as? EventReference
        XCTAssertEqual(eventReference?.referencedEvent?.isStub, true)

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
        XCTAssertEqual(eventReference?.referencingEvent, referencingEvent)
    }
}

import XCTest

class JSONEventTests: XCTestCase {
    // NIP-89 client tag that should be included in supported event kinds
    let clientId = "31990:0f22c06eac1002684efcc68f568540e8342d1609d508bcd4312c038e6194f8b6:nos-ios"
    let expectedClientTag = ["client", "nos.social", clientId]
    
    // Taggable event kinds that should include client tag
    let taggableKinds: [EventKind] = [.text, .metaData, .contactList, .mute, .followSet]
    
    // Non-taggable event kinds that should NOT include client tag
    let nonTaggableKinds: [EventKind] = [.directMessage, .delete, .repost, .like, .zapRequest, .longFormContent]
    
    func test_replaceableID() throws {
        // Arrange
        let replaceableID = "TGnBRh9-b1jrqSJ-ByWQx"
        let subject = JSONEvent(
            pubKey: "",
            kind: .longFormContent,
            tags: [["d", replaceableID]],
            content: "Test"
        )

        // Act & Assert
        XCTAssertEqual(subject.replaceableID, replaceableID)
    }
    
    func test_contactList_withRelays() {
        let pTags = [
            ["p", "91cf94e5ca", "wss://alicerelay.com/", "alice"],
            ["p", "14aeb8dad4", "wss://bobrelay.com/nostr", "bob"],
            ["p", "612aee610f", "ws://carolrelay.com/ws", "carol"]
        ]
        // Use the new client tag format
        let expectedTags = pTags + [expectedClientTag]
        let relayAddresses = [
            "wss://relay1.lol",
            "wss://relay2.lol"
        ]
        
        let event = JSONEvent.contactList(
            pubKey: "",
            tags: pTags,
            relayAddresses: relayAddresses
        )
        
        let expectedContent = """
        {"wss://relay1.lol":{"write":true,"read":true},"wss://relay2.lol":{"write":true,"read":true}}
        """
        
        XCTAssertEqual(event.kind, 3)
        XCTAssertEqual(event.tags, expectedTags)
        XCTAssertEqual(event.content, expectedContent)
    }
    
    func test_contactList_withNoRelays() {
        let pTags = [
            ["p", "91cf94e5ca", "wss://alicerelay.com/", "alice"],
            ["p", "14aeb8dad4", "wss://bobrelay.com/nostr", "bob"],
            ["p", "612aee610f", "ws://carolrelay.com/ws", "carol"]
        ]
        // Use the new client tag format
        let expectedTags = pTags + [expectedClientTag]
        
        let event = JSONEvent.contactList(
            pubKey: "",
            tags: pTags,
            relayAddresses: []
        )
        
        let expectedContent = "{}"
        
        XCTAssertEqual(event.kind, 3)
        XCTAssertEqual(event.tags, expectedTags)
        XCTAssertEqual(event.content, expectedContent)
    }
    
    func test_requestToVanish_fromSpecificRelays() {
        let event = JSONEvent.requestToVanish(
            pubKey: "",
            relays: [
                URL(string: "wss://relay1.lol")!,
                URL(string: "wss://relay2.lol")!,
                URL(string: "wss://relay3.lol")!
            ],
            reason: "I'm done with this."
        )
        
        let expectedTags = [
            ["relay", "wss://relay1.lol"],
            ["relay", "wss://relay2.lol"],
            ["relay", "wss://relay3.lol"]
        ]
        
        XCTAssertEqual(event.kind, 62)
        XCTAssertEqual(event.tags, expectedTags)
        XCTAssertEqual(event.content, "I'm done with this.")
    }
    
    func test_requestToVanish_fromAllRelays() {
        let event = JSONEvent.requestToVanish(
            pubKey: "",
            reason: "I'm done with this."
        )
        
        let expectedTags = [
            ["relay", "ALL_RELAYS"]
        ]
        
        XCTAssertEqual(event.kind, 62)
        XCTAssertEqual(event.tags, expectedTags)
        XCTAssertEqual(event.content, "I'm done with this.")
    }
    
    // MARK: - Client Tag Tests
    
    func test_clientTag_addedToTaggableEventKinds() {
        // Test each taggable event kind to verify client tag is added
        for kind in taggableKinds {
            let event = JSONEvent(
                pubKey: "test_pubkey",
                kind: kind,
                tags: [],
                content: "Test content"
            )
            
            // Check that the client tag exists in the tags array
            XCTAssertTrue(
                event.tags.contains(expectedClientTag),
                "Client tag should be added to event kind \(kind)"
            )
            
            // Check the tag count to ensure only one tag was added
            XCTAssertEqual(event.tags.count, 1, "Only one tag should be added for event kind \(kind)")
        }
    }
    
    func test_clientTag_notAddedToNonTaggableEventKinds() {
        // Test each non-taggable event kind to verify client tag is NOT added
        for kind in nonTaggableKinds {
            let event = JSONEvent(
                pubKey: "test_pubkey",
                kind: kind,
                tags: [],
                content: "Test content"
            )
            
            // Check that the client tag does NOT exist in the tags array
            XCTAssertFalse(
                event.tags.contains(expectedClientTag),
                "Client tag should NOT be added to event kind \(kind)"
            )
            
            // Check that no tags were added
            XCTAssertTrue(event.tags.isEmpty, "No tags should be added for event kind \(kind)")
        }
    }
    
    func test_clientTag_notDuplicated() {
        // Arrange: Create event with existing client tag
        let existingClientTag = ["client", "old-client", "some-identifier"]
        
        for kind in taggableKinds {
            let event = JSONEvent(
                pubKey: "test_pubkey",
                kind: kind,
                tags: [existingClientTag],
                content: "Test content"
            )
            
            // Assert: The existing client tag should remain, and no new one should be added
            XCTAssertTrue(event.tags.contains(existingClientTag), "Existing client tag should remain")
            XCTAssertFalse(event.tags.contains(expectedClientTag), "New client tag should not be added")
            XCTAssertEqual(event.tags.count, 1, "Only one client tag should exist")
        }
    }
    
    func test_contactList_usesCorrectClientTag() {
        // The static contactList constructor used to add its own client tag
        // Now it should use the one added by the JSONEvent initializer
        let pTags = [["p", "pubkey123"]]
        
        let event = JSONEvent.contactList(
            pubKey: "test_pubkey",
            tags: pTags,
            relayAddresses: ["wss://relay.example.com"]
        )
        
        // Verify the new client tag is present (not the old one)
        XCTAssertTrue(
            event.tags.contains(expectedClientTag), 
            "Contact list should use the new client tag format"
        )
        
        // Verify the old client tag is not present
        let oldClientTag = ["client", "nos", "https://nos.social"]
        XCTAssertFalse(
            event.tags.contains(oldClientTag),
            "Contact list should not contain the old client tag format"
        )
        
        // Verify tags include the p-tag and client tag
        XCTAssertEqual(event.tags.count, pTags.count + 1, "Should have p-tags plus client tag")
    }
}

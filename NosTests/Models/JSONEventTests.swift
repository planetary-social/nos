import XCTest

class JSONEventTests: XCTestCase {
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
        let expectedTags = pTags + [["client", "nos", "https://nos.social"]]
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
        let expectedTags = pTags + [["client", "nos", "https://nos.social"]]
        
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
}

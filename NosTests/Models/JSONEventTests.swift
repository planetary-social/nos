import XCTest

class JSONEventTests: XCTestCase {
    
    // MARK: - NIP-68 and NIP-71 Tests
    
    func test_picturePost() {
        // Arrange
        let pubKey = "a1b2c3d4e5f6"
        let title = "Mountain Landscape"
        let description = "A beautiful mountain landscape I captured last weekend."
        let imageMetadata = [
            ["imeta", "url https://example.com/image1.jpg", "m image/jpeg", "x 1200", "y 800"],
            ["imeta", "url https://example.com/image2.jpg", "m image/jpeg", "x 800", "y 600"]
        ]
        let additionalTags = [
            ["location", "Mountain Range"],
            ["alt", "Mountains with snow at sunset"]
        ]
        
        // Act
        let event = JSONEvent.picturePost(
            pubKey: pubKey,
            title: title,
            description: description,
            imageMetadata: imageMetadata,
            tags: additionalTags
        )
        
        // Assert
        XCTAssertEqual(event.kind, .picturePost)
        XCTAssertEqual(event.pubKey, pubKey)
        XCTAssertEqual(event.content, description)
        
        // Test the title tag is first
        XCTAssertEqual(event.tags.first, ["title", title])
        
        // Test image metadata is included
        XCTAssert(event.tags.contains(imageMetadata[0]))
        XCTAssert(event.tags.contains(imageMetadata[1]))
        
        // Test additional tags are included
        XCTAssert(event.tags.contains(additionalTags[0]))
        XCTAssert(event.tags.contains(additionalTags[1]))
    }
    
    func test_videoPost() {
        // Arrange
        let pubKey = "a1b2c3d4e5f6"
        let title = "Mountain Timelapse"
        let description = "A timelapse of clouds moving over mountains."
        let duration = 120 // 2 minutes
        let publishedAt = Int(Date().timeIntervalSince1970) - 3600 // 1 hour ago
        let videoMetadata = [
            ["imeta", "url https://example.com/video.mp4", "m video/mp4", "x 1920", "y 1080"],
            ["imeta", "url https://example.com/thumbnail.jpg", "m image/jpeg", "thumb"]
        ]
        let contentWarning = "Fast moving clouds"
        let altText = "Timelapse video of clouds moving over mountain peaks"
        let additionalTags = [["hashtag", "nature"], ["hashtag", "mountains"]]
        
        // Test normal video (kind 21)
        let normalVideo = JSONEvent.videoPost(
            pubKey: pubKey,
            title: title,
            description: description,
            isShortForm: false,
            publishedAt: publishedAt,
            duration: duration,
            videoMetadata: videoMetadata,
            contentWarning: contentWarning,
            altText: altText,
            tags: additionalTags
        )
        
        // Assert normal video
        XCTAssertEqual(normalVideo.kind, .video)
        XCTAssertEqual(normalVideo.pubKey, pubKey)
        XCTAssertEqual(normalVideo.content, description)
        
        // Verify tags
        XCTAssert(normalVideo.tags.contains(["title", title]))
        XCTAssert(normalVideo.tags.contains(["published_at", String(publishedAt)]))
        XCTAssert(normalVideo.tags.contains(["duration", String(duration)]))
        XCTAssert(normalVideo.tags.contains(videoMetadata[0]))
        XCTAssert(normalVideo.tags.contains(videoMetadata[1]))
        XCTAssert(normalVideo.tags.contains(["content-warning", contentWarning]))
        XCTAssert(normalVideo.tags.contains(["alt", altText]))
        XCTAssert(normalVideo.tags.contains(additionalTags[0]))
        XCTAssert(normalVideo.tags.contains(additionalTags[1]))
        
        // Test short-form video (kind 22)
        let shortVideo = JSONEvent.videoPost(
            pubKey: pubKey,
            title: title,
            description: description,
            isShortForm: true,
            publishedAt: publishedAt,
            duration: duration,
            videoMetadata: videoMetadata,
            contentWarning: contentWarning,
            altText: altText,
            tags: additionalTags
        )
        
        // Assert short video
        XCTAssertEqual(shortVideo.kind, .shortVideo)
    }
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

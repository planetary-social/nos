//
//  String+MarkdownTests.swift
//  NosTests
//
//  Created by Josh on 2/12/24.
//

import XCTest

class String_MarkdownTests: XCTestCase {
    func testExtractURLsFromNote() throws {
        // swiftlint:disable line_length
        let string = "Classifieds incoming... 👀\n\nhttps://nostr.build/i/2170fa01a69bca5ad0334430ccb993e41bb47eb15a4b4dbdfbee45585f63d503.jpg"
        let expectedString = "Classifieds incoming... 👀\n\n[nostr.build...](https://nostr.build/i/2170fa01a69bca5ad0334430ccb993e41bb47eb15a4b4dbdfbee45585f63d503.jpg)"
        // swiftlint:enable line_length
        let expectedURLs = [
            URL(string: "https://nostr.build/i/2170fa01a69bca5ad0334430ccb993e41bb47eb15a4b4dbdfbee45585f63d503.jpg")!
        ]

        // Act
        let (actualString, actualURLs) = string.extractURLs()
        XCTAssertEqual(actualString, expectedString)
        XCTAssertEqual(actualURLs, expectedURLs)
    }

    func testExtractURLsFromNoteWithMultipleURLs() throws {
        // swiftlint:disable line_length
        let string = "Classifieds incoming... 👀\n\nhttps://nostr.build/i/2170fa01a69bca5ad0334430ccb993e41bb47eb15a4b4dbdfbee45585f63d503.jpg\n\nhttps://cdn.ymaws.com/nacfm.com/resource/resmgr/images/blog_photos/footprints.jpg"
        let expectedString = "Classifieds incoming... 👀\n\n[nostr.build...](https://nostr.build/i/2170fa01a69bca5ad0334430ccb993e41bb47eb15a4b4dbdfbee45585f63d503.jpg)\n\n[cdn.ymaws.com...](https://cdn.ymaws.com/nacfm.com/resource/resmgr/images/blog_photos/footprints.jpg)"
        // swiftlint:enable line_length
        let expectedURLs = [
            URL(string: "https://nostr.build/i/2170fa01a69bca5ad0334430ccb993e41bb47eb15a4b4dbdfbee45585f63d503.jpg")!,
            URL(string: "https://cdn.ymaws.com/nacfm.com/resource/resmgr/images/blog_photos/footprints.jpg")!
        ]

        // Act
        let (actualString, actualURLs) = string.extractURLs()
        XCTAssertEqual(actualString, expectedString)
        XCTAssertEqual(actualURLs, expectedURLs)
    }

    func testExtractURLsFromImageNote() throws {
        let string = "Hello, world!https://cdn.ymaws.com/footprints.jpg"
        let expectedString = "Hello, world![cdn.ymaws.com...](https://cdn.ymaws.com/footprints.jpg)"
        let expectedURLs = [
            URL(string: "https://cdn.ymaws.com/footprints.jpg")!
        ]

        // Act
        let (actualString, actualURLs) = string.extractURLs()
        XCTAssertEqual(actualString, expectedString)
        XCTAssertEqual(actualURLs, expectedURLs)
    }

    func testExtractURLsFromImageNoteWithExtraNewlines() throws {
        let string = "https://cdn.ymaws.com/footprints.jpg\n\nHello, world!"
        let expectedString = "[cdn.ymaws.com...](https://cdn.ymaws.com/footprints.jpg)\n\nHello, world!"
        let expectedURLs = [
            URL(string: "https://cdn.ymaws.com/footprints.jpg")!
        ]

        // Act
        let (actualString, actualURLs) = string.extractURLs()
        XCTAssertEqual(actualString, expectedString)
        XCTAssertEqual(actualURLs, expectedURLs)
    }

    func testExtractURLsRetainsUpToTwoDuplicateNewlines() throws {
        let string = "Hello!\n\nWorld!"
        let expectedString = "Hello!\n\nWorld!"
        let expectedURLs: [URL] = []

        // Act
        let (actualString, actualURLs) = string.extractURLs()
        XCTAssertEqual(actualString, expectedString)
        XCTAssertEqual(actualURLs, expectedURLs)
    }

    func testExtractURLsReducesTooManyDuplicateNewlinesToTwo() throws {
        let string = "Hello!\n\n\nWorld!"
        let expectedString = "Hello!\n\nWorld!"
        let expectedURLs: [URL] = []

        // Act
        let (actualString, actualURLs) = string.extractURLs()
        XCTAssertEqual(actualString, expectedString)
        XCTAssertEqual(actualURLs, expectedURLs)
    }

    func testExtractURLsRemovesLeadingAndTrailingWhitespace() throws {
        let string = "  \n\nHello world!\n\n  "
        let expectedString = "Hello world!"
        let expectedURLs: [URL] = []

        // Act
        let (actualString, actualURLs) = string.extractURLs()
        XCTAssertEqual(actualString, expectedString)
        XCTAssertEqual(actualURLs, expectedURLs)
    }
}

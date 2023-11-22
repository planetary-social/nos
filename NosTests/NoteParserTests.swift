//
//  NoteNoteParserTests.swift
//  NosTests
//
//  Created by Martin Dutra on 17/4/23.
//

import CoreData
import XCTest
import Dependencies

// swiftlint:disable type_body_length

final class NoteNoteParserTests: XCTestCase {

    @Dependency(\.persistenceController) private var persistenceController
    var context: NSManagedObjectContext?
    var continuation: DependencyValues.Continuation?

    override func setUp() async throws {
        persistenceController.resetForTesting()
        context = persistenceController.viewContext
    }
    
    /// Example taken from [NIP-27](https://github.com/nostr-protocol/nips/blob/master/27.md)
    func testMentionWithNPub() throws {
        let mention = "@mattn"
        let npub = "npub1937vv2nf06360qn9y8el6d8sevnndy7tuh5nzre4gj05xc32tnwqauhaj6"
        let hex = "2c7cc62a697ea3a7826521f3fd34f0cb273693cbe5e9310f35449f43622a5cdc"
        let link = "nostr:\(npub)"
        let markdown = "hello [\(mention)](\(link))"
        let attributedString = try AttributedString(markdown: markdown)
        let (content, tags) = NoteParser.parse(attributedText: attributedString)
        let expectedContent = "hello nostr:\(npub)"
        let expectedTags = [["p", hex]]
        XCTAssertEqual(content, expectedContent)
        XCTAssertEqual(tags, expectedTags)
    }

    func testContentWithNIP08Mention() throws {
        let name = "mattn"
        let content = "hello #[0]"
        let hex = "2c7cc62a697ea3a7826521f3fd34f0cb273693cbe5e9310f35449f43622a5cdc"
        let expectedContent = "hello @\(name)"
        let tags = [["p", hex]]
        let context = try XCTUnwrap(context)
        let author = try Author.findOrCreate(by: hex, context: context)
        author.displayName = name
        try context.save()
        let (attributedContent, _) = NoteParser.parse(content: content, tags: tags, context: context)
        let parsedContent = String(attributedContent.characters)
        XCTAssertEqual(parsedContent, expectedContent)
        let links = attributedContent.links
        XCTAssertEqual(links.count, 1)
        XCTAssertEqual(links.first?.key, "@\(name)")
        XCTAssertEqual(links.first?.value, URL(string: "@\(hex)"))
    }

    func testContentWithNIP08MentionToUnknownAuthor() async throws {
        let content = "hello #[0]"
        let displayName = "npub1937vv..."
        let hex = "2c7cc62a697ea3a7826521f3fd34f0cb273693cbe5e9310f35449f43622a5cdc"
        let expectedContent = "hello @\(displayName)"
        let tags = [["p", hex]]
        let context = persistenceController.viewContext
        let (attributedContent, _) = NoteParser.parse(content: content, tags: tags, context: context)
        let parsedContent = String(attributedContent.characters)
        XCTAssertEqual(parsedContent, expectedContent)
        let links = attributedContent.links
        XCTAssertEqual(links.count, 1)
        XCTAssertEqual(links.first?.key, "@\(displayName)")
        XCTAssertEqual(links.first?.value, URL(string: "@\(hex)"))
    }

    func testContentWithNIP08MentionAtBeginning() throws {
        let content = "#[0]"
        let displayName = "npub1937vv..."
        let hex = "2c7cc62a697ea3a7826521f3fd34f0cb273693cbe5e9310f35449f43622a5cdc"
        let expectedContent = "@\(displayName)"
        let tags = [["p", hex]]
        let context = try XCTUnwrap(context)
        let (attributedContent, _) = NoteParser.parse(content: content, tags: tags, context: context)
        let parsedContent = String(attributedContent.characters)
        XCTAssertEqual(parsedContent, expectedContent)
        let links = attributedContent.links
        XCTAssertEqual(links.count, 1)
        XCTAssertEqual(links.first?.key, "@\(displayName)")
        XCTAssertEqual(links.first?.value, URL(string: "@\(hex)"))
    }

    func testContentWithNIP08MentionAfterNewline() throws {
        let content = "Hello\n#[0]"
        let displayName = "npub1937vv..."
        let hex = "2c7cc62a697ea3a7826521f3fd34f0cb273693cbe5e9310f35449f43622a5cdc"
        let expectedContent = "Hello\n@\(displayName)"
        let tags = [["p", hex]]
        let context = try XCTUnwrap(context)
        let (attributedContent, _) = NoteParser.parse(content: content, tags: tags, context: context)
        let parsedContent = String(attributedContent.characters)
        XCTAssertEqual(parsedContent, expectedContent)
        let links = attributedContent.links
        XCTAssertEqual(links.count, 1)
        XCTAssertEqual(links.first?.key, "@\(displayName)")
        XCTAssertEqual(links.first?.value, URL(string: "@\(hex)"))
    }

    func testContentWithNIP08MentionInsideAWord() throws {
        let content = "hello#[0]"
        let hex = "2c7cc62a697ea3a7826521f3fd34f0cb273693cbe5e9310f35449f43622a5cdc"
        let expectedContent = "hello#[0]"
        let tags = [["p", hex]]
        let context = try XCTUnwrap(context)
        let (attributedContent, _) = NoteParser.parse(content: content, tags: tags, context: context)
        let parsedContent = String(attributedContent.characters)
        XCTAssertEqual(parsedContent, expectedContent)
        let links = attributedContent.links
        XCTAssertEqual(links.count, 0)
    }

    /// Example taken from [NIP-27](https://github.com/nostr-protocol/nips/blob/master/27.md)
    func testContentWithNIP27Mention() throws {
        let name = "mattn"
        let content = "hello nostr:npub1937vv2nf06360qn9y8el6d8sevnndy7tuh5nzre4gj05xc32tnwqauhaj6"
        let hex = "2c7cc62a697ea3a7826521f3fd34f0cb273693cbe5e9310f35449f43622a5cdc"
        let tags = [["p", hex]]
        let context = try XCTUnwrap(context)
        let author = try Author.findOrCreate(by: hex, context: context)
        author.displayName = name
        try context.save()
        let (attributedContent, _) = NoteParser.parse(content: content, tags: tags, context: context)
        let links = attributedContent.links
        XCTAssertEqual(links.count, 1)
        XCTAssertEqual(links.first?.key, "@\(name)")
        XCTAssertEqual(links.first?.value, URL(string: "@\(hex)"))
    }

    /// Example taken from [NIP-27](https://github.com/nostr-protocol/nips/blob/master/27.md)
    func testContentWithNIP27MentionToUnknownAuthor() throws {
        let displayName = "npub1937vv..."
        let content = "hello nostr:npub1937vv2nf06360qn9y8el6d8sevnndy7tuh5nzre4gj05xc32tnwqauhaj6"
        let hex = "2c7cc62a697ea3a7826521f3fd34f0cb273693cbe5e9310f35449f43622a5cdc"
        let tags = [["p", hex]]
        let context = try XCTUnwrap(context)
        let (attributedContent, _) = NoteParser.parse(content: content, tags: tags, context: context)
        let links = attributedContent.links
        XCTAssertEqual(links.count, 1)
        XCTAssertEqual(links.first?.key, "@\(displayName)")
        XCTAssertEqual(links.first?.value, URL(string: "@\(hex)"))
    }

    /// Example taken from [NIP-27](https://github.com/nostr-protocol/nips/blob/master/27.md)
    func testContentWithNIP27ProfileMention() throws {
        let name = "mattn"
        let content = "hello nostr:nprofile1qqszclxx9f5haga8sfjjrulaxncvkfekj097t6f3pu65f86rvg49ehqj6f9dh"
        let hex = "2c7cc62a697ea3a7826521f3fd34f0cb273693cbe5e9310f35449f43622a5cdc"
        let tags = [["p", hex]]
        let context = try XCTUnwrap(context)
        let author = try Author.findOrCreate(by: hex, context: context)
        author.displayName = name
        try context.save()
        let (attributedContent, _) = NoteParser.parse(content: content, tags: tags, context: context)
        let links = attributedContent.links
        XCTAssertEqual(links.count, 1)
        XCTAssertEqual(links.first?.key, "@\(name)")
        XCTAssertEqual(links.first?.value, URL(string: "@\(hex)"))
    }

    func testContentWithNIP27ProfileMentionWithADot() throws {
        let name = "mattn"
        let content = "Hello nostr:npub1pu3vqm4vzqpxsnhuc684dp2qaq6z69sf65yte4p39spcucv5lzmqswtfch.\n\nBye"
        let hex = "0f22c06eac1002684efcc68f568540e8342d1609d508bcd4312c038e6194f8b6"
        let tags = [["p", hex]]
        let context = try XCTUnwrap(context)
        let author = try Author.findOrCreate(by: hex, context: context)
        author.displayName = name
        try context.save()
        let (attributedContent, _) = NoteParser.parse(content: content, tags: tags, context: context)
        let links = attributedContent.links
        XCTAssertEqual(links.count, 1)
        XCTAssertEqual(links.first?.key, "@\(name)")
        XCTAssertEqual(links.first?.value, URL(string: "@\(hex)"))
    }

    func testContentWithMixedMentions() throws {
        let content = "hello nostr:npub1937vv2nf06360qn9y8el6d8sevnndy7tuh5nzre4gj05xc32tnwqauhaj6 and #[1]"
        let displayName1 = "npub1937vv..."
        let hex1 = "2c7cc62a697ea3a7826521f3fd34f0cb273693cbe5e9310f35449f43622a5cdc"
        let displayName2 = "npub180cvv..."
        let hex2 = "3bf0c63fcb93463407af97a5e5ee64fa883d107ef9e558472c4eb9aaaefa459d"
        let tags = [["p", hex1], ["p", hex2]]
        let context = try XCTUnwrap(context)
        let (attributedContent, _) = NoteParser.parse(content: content, tags: tags, context: context)
        let links = attributedContent.links
        XCTAssertEqual(links.count, 2)
        XCTAssertEqual(links[safe: 0]?.key, "@\(displayName1)")
        XCTAssertEqual(links[safe: 0]?.value, URL(string: "@\(hex1)"))
        XCTAssertEqual(links[safe: 1]?.key, "@\(displayName2)")
        XCTAssertEqual(links[safe: 1]?.value, URL(string: "@\(hex2)"))
    }

    func testContentWithUntaggedNpub() throws {
        let content = "hello npub1937vv2nf06360qn9y8el6d8sevnndy7tuh5nzre4gj05xc32tnwqauhaj6"
        let npub = "npub1937vv2nf06360qn9y8el6d8sevnndy7tuh5nzre4gj05xc32tnwqauhaj6"
        let hex = "2c7cc62a697ea3a7826521f3fd34f0cb273693cbe5e9310f35449f43622a5cdc"
        let tags: [[String]] = [[]]
        let context = try XCTUnwrap(context)
        let (attributedContent, _) = NoteParser.parse(content: content, tags: tags, context: context)
        let links = attributedContent.links
        XCTAssertEqual(links.count, 1)
        XCTAssertEqual(links[safe: 0]?.key, "\(npub)")
        XCTAssertEqual(links[safe: 0]?.value, URL(string: "@\(hex)"))
    }

    func testContentWithUntaggedNote() throws {
        let content = "Check this note1h2mmqfjqle48j8ytmdar22v42g5y9n942aumyxatgtxpqj29pjjsjecraw"
        let hex = "bab7b02640fe6a791c8bdb7a352995522842ccb55779b21bab42cc1049450ca5"
        let tags: [[String]] = [[]]
        let context = try XCTUnwrap(context)
        let (attributedContent, _) = NoteParser.parse(content: content, tags: tags, context: context)
        let links = attributedContent.links
        XCTAssertEqual(links.count, 1)
        XCTAssertEqual(links[safe: 0]?.key, "🔗 Link to note")
        XCTAssertEqual(links[safe: 0]?.value, URL(string: "%\(hex)"))
    }
    
    func testContentWithUntaggedNIP27Note() throws {
        let content = "Check this nostr:note1h2mmqfjqle48j8ytmdar22v42g5y9n942aumyxatgtxpqj29pjjsjecraw"
        let hex = "bab7b02640fe6a791c8bdb7a352995522842ccb55779b21bab42cc1049450ca5"
        let tags: [[String]] = [[]]
        let context = try XCTUnwrap(context)
        let (attributedContent, _) = NoteParser.parse(content: content, tags: tags, context: context)
        let links = attributedContent.links
        XCTAssertEqual(links.count, 1)
        XCTAssertEqual(links[safe: 0]?.key, "🔗 Link to note")
        XCTAssertEqual(links[safe: 0]?.value, URL(string: "%\(hex)"))
    }

    func testContentWithUntaggedNIP27NoteAndTaggedNIP27Profile() throws {
        let profileDisplayName = "@npub1pu3vq..."
        let profile = "npub1pu3vqm4vzqpxsnhuc684dp2qaq6z69sf65yte4p39spcucv5lzmqswtfch"
        let note = "note1h2mmqfjqle48j8ytmdar22v42g5y9n942aumyxatgtxpqj29pjjsjecraw"
        let content = "Check this nostr:\(note) from nostr:\(profile)"
        let profileHex = "0f22c06eac1002684efcc68f568540e8342d1609d508bcd4312c038e6194f8b6"
        let noteHex = "bab7b02640fe6a791c8bdb7a352995522842ccb55779b21bab42cc1049450ca5"
        let tags: [[String]] = [["p", profileHex]]
        let context = try XCTUnwrap(context)
        let (attributedContent, _) = NoteParser.parse(content: content, tags: tags, context: context)
        let links = attributedContent.links
        XCTAssertEqual(links.count, 2)
        XCTAssertEqual(links[safe: 0]?.key, "🔗 Link to note")
        XCTAssertEqual(links[safe: 0]?.value, URL(string: "%\(noteHex)"))
        XCTAssertEqual(links[safe: 1]?.key, "\(profileDisplayName)")
        XCTAssertEqual(links[safe: 1]?.value, URL(string: "@\(profileHex)"))
    }
    
    func testContentWithUntaggedProfile() throws {
        let profile = "nprofile1qqszclxx9f5haga8sfjjrulaxncvkfekj097t6f3pu65f86rvg49ehqj6f9dh"
        let hex = "2c7cc62a697ea3a7826521f3fd34f0cb273693cbe5e9310f35449f43622a5cdc"

        let content = "hello \(profile)"
        let tags: [[String]] = [[]]
        
        let expectedContent = content
        let context = try XCTUnwrap(context)
        let (attributedContent, _) = NoteParser.parse(content: content, tags: tags, context: context)

        let parsedContent = String(attributedContent.characters)
        XCTAssertEqual(parsedContent, expectedContent)

        let links = attributedContent.links
        XCTAssertEqual(links.count, 1)
        XCTAssertEqual(links[safe: 0]?.key, "\(profile)")
        XCTAssertEqual(links[safe: 0]?.value, URL(string: "@\(hex)"))
    }

    func testContentWithUntaggedEvent() throws {
        // swiftlint:disable line_length
        let event = "nevent1qqst8cujky046negxgwwm5ynqwn53t8aqjr6afd8g59nfqwxpdhylpcpzamhxue69uhhyetvv9ujuetcv9khqmr99e3k7mg8arnc9"
        // swiftlint:enable line_length

        let hex = "b3e392b11f5d4f28321cedd09303a748acfd0487aea5a7450b3481c60b6e4f87"

        let content = "check this \(event)"
        let tags: [[String]] = [[]]

        let expectedContent = "check this 🔗 Link to note"
        let context = try XCTUnwrap(context)
        let (attributedContent, _) = NoteParser.parse(content: content, tags: tags, context: context)

        let parsedContent = String(attributedContent.characters)
        XCTAssertEqual(parsedContent, expectedContent)

        let links = attributedContent.links
        XCTAssertEqual(links.count, 1)
        XCTAssertEqual(links[safe: 0]?.key, "🔗 Link to note")
        XCTAssertEqual(links[safe: 0]?.value, URL(string: "%\(hex)"))
    }

    func testContentWithUntaggedEventWithADot() throws {
        // swiftlint:disable line_length
        let event = "nevent1qqst8cujky046negxgwwm5ynqwn53t8aqjr6afd8g59nfqwxpdhylpcpzamhxue69uhhyetvv9ujuetcv9khqmr99e3k7mg8arnc9"
        // swiftlint:enable line_length

        let hex = "b3e392b11f5d4f28321cedd09303a748acfd0487aea5a7450b3481c60b6e4f87"

        let content = "check this \(event). Bye!"
        let tags: [[String]] = [[]]

        let expectedContent = "check this 🔗 Link to note. Bye!"
        let context = try XCTUnwrap(context)
        let (attributedContent, _) = NoteParser.parse(content: content, tags: tags, context: context)

        let parsedContent = String(attributedContent.characters)
        XCTAssertEqual(parsedContent, expectedContent)

        let links = attributedContent.links
        XCTAssertEqual(links.count, 1)
        XCTAssertEqual(links[safe: 0]?.key, "🔗 Link to note")
        XCTAssertEqual(links[safe: 0]?.value, URL(string: "%\(hex)"))
    }

    func testContentWithMalformedEvent() throws {
        // swiftlint:disable line_length
        let event = "nevent1qqst8cujky046negxgwwm5ynqwn53t8aqjr6afd8g59nfqwxpdhylpcpzamhxue69uhhyetvv9ujuetcv9khqmr99e3k7mg8arnc9"
        // swiftlint:enable line_length

        let content = "check this \(event)andthisshouldbreakmaybe. Bye!"
        let tags: [[String]] = [[]]

        let expectedContent = content
        let context = try XCTUnwrap(context)
        let (attributedContent, _) = NoteParser.parse(content: content, tags: tags, context: context)

        let parsedContent = String(attributedContent.characters)
        XCTAssertEqual(parsedContent, expectedContent)

        let links = attributedContent.links
        XCTAssertEqual(links.count, 0)
    }
    
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

fileprivate extension AttributedString {
    var links: [(key: String, value: URL)] {
        runs.compactMap {
            guard let link = $0.link else {
                return nil
            }
            return (key: String(self[$0.range].characters), value: link)
        }
    }
}

// swiftlint:enable type_body_length

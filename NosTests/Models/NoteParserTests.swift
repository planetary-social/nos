import CoreData
import XCTest
import Dependencies

final class NoteParserTests: CoreDataTestCase {

    // swiftlint:disable:next implicitly_unwrapped_optional
    var sut: NoteParser!
    
    // swiftlint:disable:next implicitly_unwrapped_optional
    var noteEditor: NoteEditorController!
    
    // swiftlint:disable:next implicitly_unwrapped_optional
    var textView: UITextView!

    @MainActor
    override func setUp() async throws {
        sut = NoteParser()
        noteEditor = NoteEditorController()
        textView = UITextView()
        noteEditor.textView = textView
        try await super.setUp()
    }

    @MainActor func testContentWithRawNpubPrecededByAt() throws {
        // Arrange
        let npub = "npub1pu3vqm4vzqpxsnhuc684dp2qaq6z69sf65yte4p39spcucv5lzmqswtfch"
        let hex = "0f22c06eac1002684efcc68f568540e8342d1609d508bcd4312c038e6194f8b6"
        let content = "You can find me at @\(npub)"
        let expected = "You can find me at \(npub)"

        // Act
        let tags: [[String]] = [[]]
        let components = sut.components(
            from: content,
            tags: tags,
            context: testContext
        )
        let attributedContent = components.attributedContent

        // Assert
        XCTAssertEqual(String(attributedContent.characters), expected)
        let links = attributedContent.links
        XCTAssertEqual(links.count, 1)
        XCTAssertEqual(links[safe: 0]?.key, npub)
        XCTAssertEqual(links[safe: 0]?.value, URL(string: "@\(hex)"))
    }

    @MainActor func testContentWithRawNIP05() throws {
        // Arrange
        let nip05 = "linda@nos.social"
        let webLink = "@linda@nos.social"
        let content = "hello linda@nos.social"
        let expected = content

        // Act
        let tags: [[String]] = [[]]
        let components = sut.components(
            from: content,
            tags: tags,
            context: testContext
        )
        let attributedContent = components.attributedContent

        // Assert
        XCTAssertEqual(String(attributedContent.characters), expected)
        let links = attributedContent.links
        XCTAssertEqual(links.count, 1)
        XCTAssertEqual(links[safe: 0]?.key, nip05)
        XCTAssertEqual(links[safe: 0]?.value, URL(string: webLink))
    }

    @MainActor func testContentWithRawNIP05AndAtPrepended() throws {
        // Arrange
        let nip05 = "linda@nos.social"
        let webLink = "@linda@nos.social"
        let content = "hello @linda@nos.social"
        let expected = "hello linda@nos.social"

        // Act
        let tags: [[String]] = [[]]
        let components = sut.components(
            from: content,
            tags: tags,
            context: testContext
        )
        let attributedContent = components.attributedContent

        // Assert
        XCTAssertEqual(String(attributedContent.characters), expected)
        let links = attributedContent.links
        XCTAssertEqual(links.count, 1)
        XCTAssertEqual(links[safe: 0]?.key, nip05)
        XCTAssertEqual(links[safe: 0]?.value, URL(string: webLink))
    }

    @MainActor func testContentWithMixedMentions() throws {
        let content = "hello nostr:npub1937vv2nf06360qn9y8el6d8sevnndy7tuh5nzre4gj05xc32tnwqauhaj6 and #[1]"
        let displayName1 = "npub1937vv..."
        let hex1 = "2c7cc62a697ea3a7826521f3fd34f0cb273693cbe5e9310f35449f43622a5cdc"
        let displayName2 = "npub180cvv..."
        let hex2 = "3bf0c63fcb93463407af97a5e5ee64fa883d107ef9e558472c4eb9aaaefa459d"
        let tags = [["p", hex1], ["p", hex2]]
        let components = sut.components(
            from: content,
            tags: tags,
            context: testContext
        )
        let attributedContent = components.attributedContent
        let links = attributedContent.links
        XCTAssertEqual(links.count, 2)
        XCTAssertEqual(links[safe: 0]?.key, "@\(displayName1)")
        XCTAssertEqual(links[safe: 0]?.value, URL(string: "@\(hex1)"))
        XCTAssertEqual(links[safe: 1]?.key, "@\(displayName2)")
        XCTAssertEqual(links[safe: 1]?.value, URL(string: "@\(hex2)"))
    }

    @MainActor func testContentWithUntaggedNpub() throws {
        let content = "hello npub1937vv2nf06360qn9y8el6d8sevnndy7tuh5nzre4gj05xc32tnwqauhaj6"
        let npub = "npub1937vv2nf06360qn9y8el6d8sevnndy7tuh5nzre4gj05xc32tnwqauhaj6"
        let hex = "2c7cc62a697ea3a7826521f3fd34f0cb273693cbe5e9310f35449f43622a5cdc"
        let tags: [[String]] = [[]]
        let components = sut.components(
            from: content,
            tags: tags,
            context: testContext
        )
        let attributedContent = components.attributedContent
        let links = attributedContent.links
        XCTAssertEqual(links.count, 1)
        XCTAssertEqual(links[safe: 0]?.key, npub)
        XCTAssertEqual(links[safe: 0]?.value, URL(string: "@\(hex)"))
    }

    @MainActor func testContentWithUntaggedNote() throws {
        let content = "Check this note1h2mmqfjqle48j8ytmdar22v42g5y9n942aumyxatgtxpqj29pjjsjecraw"
        let hex = "bab7b02640fe6a791c8bdb7a352995522842ccb55779b21bab42cc1049450ca5"
        let tags: [[String]] = [[]]
        let components = sut.components(
            from: content,
            tags: tags,
            context: testContext
        )
        let attributedContent = components.attributedContent
        XCTAssertTrue(attributedContent.links.isEmpty)
        XCTAssertEqual(components.quotedNoteID, hex)
    }
    
    @MainActor func testContentWithUntaggedNIP27Note() throws {
        let content = "Check this nostr:note1h2mmqfjqle48j8ytmdar22v42g5y9n942aumyxatgtxpqj29pjjsjecraw"
        let hex = "bab7b02640fe6a791c8bdb7a352995522842ccb55779b21bab42cc1049450ca5"
        let tags: [[String]] = [[]]
        let components = sut.components(
            from: content,
            tags: tags,
            context: testContext
        )
        let attributedContent = components.attributedContent
        XCTAssertTrue(attributedContent.links.isEmpty)
        XCTAssertEqual(components.quotedNoteID, hex)
    }
    
    @MainActor func testContentWithUntaggedProfile() throws {
        let profile = "nprofile1qqszclxx9f5haga8sfjjrulaxncvkfekj097t6f3pu65f86rvg49ehqj6f9dh"
        let hex = "2c7cc62a697ea3a7826521f3fd34f0cb273693cbe5e9310f35449f43622a5cdc"

        let content = "hello \(profile)"
        let tags: [[String]] = [[]]
        
        let expectedContent = content
        let components = sut.components(
            from: content,
            tags: tags,
            context: testContext
        )
        let attributedContent = components.attributedContent

        let parsedContent = String(attributedContent.characters)
        XCTAssertEqual(parsedContent, expectedContent)

        let links = attributedContent.links
        XCTAssertEqual(links.count, 1)
        XCTAssertEqual(links[safe: 0]?.key, "\(profile)")
        XCTAssertEqual(links[safe: 0]?.value, URL(string: "@\(hex)"))
    }

    @MainActor func testContentWithUntaggedEvent() throws {
        // swiftlint:disable line_length
        let event = "nevent1qqst8cujky046negxgwwm5ynqwn53t8aqjr6afd8g59nfqwxpdhylpcpzamhxue69uhhyetvv9ujuetcv9khqmr99e3k7mg8arnc9"
        // swiftlint:enable line_length

        let hex = "b3e392b11f5d4f28321cedd09303a748acfd0487aea5a7450b3481c60b6e4f87"

        let content = "check this \(event)"
        let tags: [[String]] = [[]]

        let expectedContent = "check this"
        let components = sut.components(
            from: content,
            tags: tags,
            context: testContext
        )
        let attributedContent = components.attributedContent

        let parsedContent = String(attributedContent.characters)
        XCTAssertEqual(parsedContent, expectedContent)
        
        XCTAssertTrue(attributedContent.links.isEmpty)
        XCTAssertEqual(components.quotedNoteID, hex)
    }

    @MainActor func testContentWithUntaggedEventWithADot() throws {
        // swiftlint:disable line_length
        let event = "nevent1qqst8cujky046negxgwwm5ynqwn53t8aqjr6afd8g59nfqwxpdhylpcpzamhxue69uhhyetvv9ujuetcv9khqmr99e3k7mg8arnc9"
        // swiftlint:enable line_length

        let hex = "b3e392b11f5d4f28321cedd09303a748acfd0487aea5a7450b3481c60b6e4f87"

        let content = "check this \(event). Bye!"
        let tags: [[String]] = [[]]

        let expectedContent = "check this . Bye!"
        let components = sut.components(
            from: content,
            tags: tags,
            context: testContext
        )
        let attributedContent = components.attributedContent
        let parsedContent = String(attributedContent.characters)
        XCTAssertEqual(parsedContent, expectedContent)
        
        XCTAssertTrue(attributedContent.links.isEmpty)
        XCTAssertEqual(components.quotedNoteID, hex)
    }

    @MainActor func testContentWithMalformedEvent() throws {
        // swiftlint:disable line_length
        let event = "nevent1qqst8cujky046negxgwwm5ynqwn53t8aqjr6afd8g59nfqwxpdhylpcpzamhxue69uhhyetvv9ujuetcv9khqmr99e3k7mg8arnc9"
        // swiftlint:enable line_length

        let content = "check this \(event)andthisshouldbreakmaybe. Bye!"
        let tags: [[String]] = [[]]

        let expectedContent = content
        let components = sut.components(
            from: content,
            tags: tags,
            context: testContext
        )
        let attributedContent = components.attributedContent

        let parsedContent = String(attributedContent.characters)
        XCTAssertEqual(parsedContent, expectedContent)
        
        XCTAssertTrue(attributedContent.links.isEmpty)
    }
    
    @MainActor func testContentWithNAddr() throws {
        let naddrLink = "$3355903008550074;fa984bd7dbb282f07e16e7ae87b26a2a7b9b90b7246a44771f0cf5ae58018f52;31890"

        // swiftlint:disable line_length
        let content = """
        People are using Coracle's custom feeds! Here are some interesting ones:\n\nnostr:naddr1qvzqqqrujgpzp75cf0tahv5z7plpdeaws7ex52nmnwgtwfr2g3m37r844evqrr6jqyghwumn8ghj7vf5xqhxvdm69e5k7tcpzdmhxue69uhhqatjwpkx2urpvuhx2ue0qythwumn8ghj7un9d3shjtnswf5k6ctv9ehx2ap0qy2hwumn8ghj7un9d3shjtnyv9kh2uewd9hj7qg6waehxw309ac8junpd45kgtnxd9shg6npvchxxmmd9uq3xamnwvaz7tmjv4kxz7fwvcmh5tnfduhsz9thwden5te0wfjkccte9ejhs6t59ec82c30qyf8wumn8ghj7un9d3shjtn5dahkcue0qy88wumn8ghj7mn0wvhxcmmv9uqpqvenx56njvpnxqcrsdf4xqcrwdqufrevn\nnostr:naddr1qvzqqqrujgpzqlxr9zsgmke2lhuln0nhhml5eq6gnluhjuscyltz3f2z7v4zglqwqyghwumn8ghj7mn0wd68ytnhd9hx2tcpzfmhxue69uhkummnw3eryvfwvdhk6tcpr4mhxue69uhksmm5wf5kw6r5dehhwtnwdaehgu339e3k7mf0qydhwumn8ghj7argv4nx7un9wd6zumn0wd68yvfwvdhk6tcpr4mhxue69uhkummnw3ezumt4w35ku7thv9kxcet59e3k7mf0qyt8wumn8ghj7cn9wehjumn0wd68yvfwvdhk6tcprfmhxue69uhkummnw3ezuargv4ekzmt9vdshgtnfduhszxnhwden5te0wpex7enfd3jhxtnwdaehgu339e3k7mf0qy2hwumn8ghj7un9d3shjtnyv9kh2uewd9hj7qgwwaehxw309ahx7uewd3hkctcqzycrgvpsxy6nwwfhxqer2wpjxycrx895qk5\nnostr:naddr1qvzqqqrujgpzqczwjmsfnym2zpyg89vtqs95weewpuzgex9v0yln0llycusz084jqyghwumn8ghj7mn0wd68ytnhd9hx2tcpz4mhxue69uhhyetvv9ujuerpd46hxtnfduhszymhwden5te0wp6hyurvv4cxzeewv4ej7qghwaehxw309aex2mrp0yhxummnw3ezucnpdejz7qghwaehxw309aex2mrp0yh8qunfd4skctnwv46z7qgawaehxw309ahx7um5wghx6at5d9h8jampd3kx2apwvdhk6tcppemhxue69uhkummn9ekx7mp0qqgrvdps8ymnqvf3xcersdfhxqmryx9hdms\nnostr:naddr1qvzqqqrujgpzq3an3axnwgfep4dkhmmcmt3l8cug3mxm7xzylwenhzrjr5mx6hygqy2hwumn8ghj7un9d3shjtnyv9kh2uewd9hj7qghwaehxw309aex2mrp0yhxummnw3ezucnpdejz7qg3waehxw309ahx7um5wgh8w6twv5hsz9mhwden5te0wfjkccte9cc8scmgv96zucm0d5hszrnhwden5te0dehhxtnvdakz7qqsxgurwdpkxg6nwdf58qer2ve3xvwjjnjg\n\nI encourage you to try it out — create your own and paste its address into a reply to this note to share it.
        """
        let tags: [[String]] = [[]]
        
        let expectedContent = "People are using Coracle's custom feeds! Here are some interesting ones:\n\n🔗 Link to note\n🔗 Link to note\n🔗 Link to note\n🔗 Link to note\n\nI encourage you to try it out — create your own and paste its address into a reply to this note to share it."
        // swiftlint:enable line_length
        
        let components = sut.components(
            from: content,
            tags: tags,
            context: testContext
        )
        let attributedContent = components.attributedContent
        
        let parsedContent = String(attributedContent.characters)
        XCTAssertEqual(parsedContent, expectedContent)
        
        let links = attributedContent.links
        XCTAssertEqual(links.count, 4)
        XCTAssertEqual(links[safe: 0]?.key, "🔗 Link to note")
        XCTAssertEqual(links[safe: 0]?.value, URL(string: naddrLink))
    }
    
    @MainActor func testContentWithYakihonneNeventLink() {
        // swiftlint:disable line_length
        let content = """
        "https://yakihonne.com/notes/nevent1qgszpxr0hql8whvk6xyv5hya7yxwd4snur4hu4mg5rctz2ehekkzrvcqyrej80hs0k7ydd60p4zpdddqlx4zr66fwns5frwn2zf2gg3u8vr3w725fc0"
        """
        
        let expectedContent = "\"yakihonne.com...\""
        // swiftlint:enable line_length
        
        let components = sut.components(
            from: content,
            tags: [[]],
            context: testContext
        )
        let attributedContent = components.attributedContent
        
        let parsedContent = String(attributedContent.characters)
        XCTAssertEqual(parsedContent, expectedContent)
        
        let links = attributedContent.links
        XCTAssertEqual(links.count, 1)
        XCTAssertEqual(links[safe: 0]?.key, "yakihonne.com...")
        
        XCTAssertNil(components.quotedNoteID)
    }
}

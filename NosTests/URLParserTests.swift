import XCTest

class URLParserTests: XCTestCase {

    // swiftlint:disable:next implicitly_unwrapped_optional
    private var sut: URLParser!

    override func setUp() async throws {
        sut = URLParser()
        try await super.setUp()
    }

    func testExtractURLs() throws {
        // swiftlint:disable line_length
        let string = "Classifieds incoming... 👀\n\nhttps://nostr.build/i/2170fa01a69bca5ad0334430ccb993e41bb47eb15a4b4dbdfbee45585f63d503.jpg"
        let expectedString = "Classifieds incoming... 👀\n\n[nostr.build...](https://nostr.build/i/2170fa01a69bca5ad0334430ccb993e41bb47eb15a4b4dbdfbee45585f63d503.jpg)"
        // swiftlint:enable line_length
        let expectedURLs = [
            URL(string: "https://nostr.build/i/2170fa01a69bca5ad0334430ccb993e41bb47eb15a4b4dbdfbee45585f63d503.jpg")!
        ]

        // Act
        let (actualString, actualURLs) = sut.replaceUnformattedURLs(in: string)
        XCTAssertEqual(actualString, expectedString)
        XCTAssertEqual(actualURLs, expectedURLs)
    }

    func testExtractNIP05() throws {
        let string = "Hello bob@example.com"
        let expectedString = "Hello [bob@example.com](@bob@example.com)"
        let expectedURLs = [
            URL(string: "@bob@example.com")!
        ]

        // Act
        let (actualString, actualURLs) = sut.replaceUnformattedURLs(in: string)
        XCTAssertEqual(actualString, expectedString)
        XCTAssertEqual(actualURLs, expectedURLs)
    }

    func testExtractNIP05WithUnderscore() throws {
        let string = "Hello _@bob.example.com"
        let expectedString = "Hello [_@bob.example.com](@_@bob.example.com)"
        let expectedURLs = [
            URL(string: "@_@bob.example.com")!
        ]

        // Act
        let (actualString, actualURLs) = sut.replaceUnformattedURLs(in: string)
        XCTAssertEqual(actualString, expectedString)
        XCTAssertEqual(actualURLs, expectedURLs)
    }

    func testExtractURLsWithMultipleURLs() throws {
        let string = """
        A few links...

        https://nostr.build/i/2170fa01a69bca5ad0334430ccb993e41bb47eb15a4b4dbdfbee45585f63d503.jpg
        nos.social
        www.nostr.com/get-started
        """
        let expectedString = """
        A few links...

        [nostr.build...](https://nostr.build/i/2170fa01a69bca5ad0334430ccb993e41bb47eb15a4b4dbdfbee45585f63d503.jpg)
        [nos.social](https://nos.social)
        [nostr.com...](https://www.nostr.com/get-started)
        """

        let expectedURLs = [
            URL(string: "https://nostr.build/i/2170fa01a69bca5ad0334430ccb993e41bb47eb15a4b4dbdfbee45585f63d503.jpg")!,
            URL(string: "https://nos.social")!,
            URL(string: "https://www.nostr.com/get-started")
        ]

        // Act
        let (actualString, actualURLs) = sut.replaceUnformattedURLs(in: string)
        XCTAssertEqual(actualString, expectedString)
        XCTAssertEqual(actualURLs, expectedURLs)
    }

    func testExtractURLsDoesNotInterpretAllDotsAsURLs() throws {
        // Arrange
        let string = "No links...and just some tricks for the extractor..to try to trip it up. ...Ready for It?"

        // Act
        let (actualString, actualURLs) = sut.replaceUnformattedURLs(in: string)

        // Assert
        XCTAssertEqual(actualString, string)
        XCTAssertTrue(actualURLs.isEmpty)
    }

    func testExtractURLsDoesNotIncludeCommasInURLs() throws {
        // Arrange
        let string = "Welcome to nos.social, a place for humans"
        let expectedString = "Welcome to [nos.social](https://nos.social), a place for humans"
        let expectedURLs = [
            URL(string: "https://nos.social")!
        ]

        // Act
        let (actualString, actualURLs) = sut.replaceUnformattedURLs(in: string)

        // Assert
        XCTAssertEqual(actualString, expectedString)
        XCTAssertEqual(actualURLs, expectedURLs)
    }
    
    func testExtractURLsDoesNotIncludePeriodsInURLs() throws {
        // Arrange
        let string = "Welcome to nos.social. It's a place for humans"
        let expectedString = "Welcome to [nos.social](https://nos.social). It's a place for humans"
        let expectedURLs = [
            URL(string: "https://nos.social")!
        ]

        // Act
        let (actualString, actualURLs) = sut.replaceUnformattedURLs(in: string)

        // Assert
        XCTAssertEqual(actualString, expectedString)
        XCTAssertEqual(actualURLs, expectedURLs)
    }

    func testExtractURLsWithImage() throws {
        let string = "Hello, world!https://cdn.ymaws.com/footprints.jpg"
        let expectedString = "Hello, world![cdn.ymaws.com...](https://cdn.ymaws.com/footprints.jpg)"
        let expectedURLs = [
            URL(string: "https://cdn.ymaws.com/footprints.jpg")!
        ]

        // Act
        let (actualString, actualURLs) = sut.replaceUnformattedURLs(in: string)
        XCTAssertEqual(actualString, expectedString)
        XCTAssertEqual(actualURLs, expectedURLs)
    }

    func testExtractURLsWithImageWithExtraNewlines() throws {
        let string = "https://cdn.ymaws.com/footprints.jpg\n\nHello, world!"
        let expectedString = "[cdn.ymaws.com...](https://cdn.ymaws.com/footprints.jpg)\n\nHello, world!"
        let expectedURLs = [
            URL(string: "https://cdn.ymaws.com/footprints.jpg")!
        ]

        // Act
        let (actualString, actualURLs) = sut.replaceUnformattedURLs(in: string)
        XCTAssertEqual(actualString, expectedString)
        XCTAssertEqual(actualURLs, expectedURLs)
    }

    func testExtractURLsRetainsUpToTwoDuplicateNewlines() throws {
        let string = "Hello!\n\nWorld!"
        let expectedString = "Hello!\n\nWorld!"
        let expectedURLs: [URL] = []

        // Act
        let (actualString, actualURLs) = sut.replaceUnformattedURLs(in: string)
        XCTAssertEqual(actualString, expectedString)
        XCTAssertEqual(actualURLs, expectedURLs)
    }

    func testExtractURLsReducesTooManyDuplicateNewlinesToTwo() throws {
        let string = "Hello!\n\n\nWorld!"
        let expectedString = "Hello!\n\nWorld!"
        let expectedURLs: [URL] = []

        // Act
        let (actualString, actualURLs) = sut.replaceUnformattedURLs(in: string)
        XCTAssertEqual(actualString, expectedString)
        XCTAssertEqual(actualURLs, expectedURLs)
    }

    func testExtractURLsRemovesLeadingAndTrailingWhitespace() throws {
        let string = "  \n\nHello world!\n\n  "
        let expectedString = "Hello world!"
        let expectedURLs: [URL] = []

        // Act
        let (actualString, actualURLs) = sut.replaceUnformattedURLs(in: string)
        XCTAssertEqual(actualString, expectedString)
        XCTAssertEqual(actualURLs, expectedURLs)
    }
}

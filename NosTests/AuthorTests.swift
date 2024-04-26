import XCTest

/// Tests for the `Author` model.
final class AuthorTests: CoreDataTestCase {
    
    /// Verifies that the `followedKeys` property returns the correct set of keys followed by the author.
    /// Written for bug [#845](https://github.com/planetary-social/nos/issues/845).
    func testFollowedKeys() throws {
        let context = persistenceController.viewContext
        let author = try Author.findOrCreate(by: "test", context: context)
        var expectedFollowedKeys = [String]()
        for _ in 0..<700 {
            let key = RawNostrID.random
            let followee = try Author.findOrCreate(by: "\(key)", context: context)
            let follow = Follow(context: context)
            follow.source = author
            follow.destination = followee
            expectedFollowedKeys.append("\(key)")
        }
        XCTAssertEqual(author.follows.count, 700)
        XCTAssertEqual(Set(author.followedKeys), Set(expectedFollowedKeys))
    }
    
    func testFollowedKeysIgnoresInvalidKeys() throws {
        // inject bad data into the database
        let user = try Author.findOrCreate(by: "user", context: testContext)
        let followee = try Author.findOrCreate(by: "followee", context: testContext)
        let follow = Follow(context: testContext)
        follow.source = user
        follow.destination = followee
        
        let fetchedAuthor = try Author.find(by: "user", context: testContext)
        XCTAssertEqual(fetchedAuthor?.followedKeys, [])
    }

    func testHumanFriendlyIdentifier() throws {
        let context = persistenceController.viewContext
        let key = RawNostrID.random
        let publicKey = try XCTUnwrap(PublicKey(hex: key))
        let truncatedKey = "\(publicKey.npub.prefix(10))..."
        let nip05 = "me@nip05.com"
        let author = try Author.findOrCreate(by: key, context: context)
        XCTAssertEqual(author.humanFriendlyIdentifier, truncatedKey)
        author.nip05 = nip05
        XCTAssertEqual(author.humanFriendlyIdentifier, nip05)
        let nip05WithUnderscore = "_@nip05.com"
        author.nip05 = nip05WithUnderscore
        XCTAssertEqual(author.humanFriendlyIdentifier, "nip05.com")
    }

    func test_hasNIP05_false_when_nip05_is_nil() throws {
        let context = persistenceController.viewContext
        let author = try Author.findOrCreate(by: "test", context: context)
        author.nip05 = nil

        XCTAssertFalse(author.hasNIP05)
    }

    func test_hasNIP05_false_when_nip05_is_empty() throws {
        let context = persistenceController.viewContext
        let author = try Author.findOrCreate(by: "test", context: context)
        author.nip05 = ""

        XCTAssertFalse(author.hasNIP05)
    }

    func test_hasNIP05_true_when_nip05_exists() throws {
        let context = persistenceController.viewContext
        let author = try Author.findOrCreate(by: "test", context: context)
        author.nip05 = "iamgroot@nos.social"

        XCTAssertTrue(author.hasNIP05)
    }

    func test_hasUNS_false_when_uns_is_nil() throws {
        let context = persistenceController.viewContext
        let author = try Author.findOrCreate(by: "test", context: context)
        author.uns = nil

        XCTAssertFalse(author.hasUNS)
    }

    func test_hasUNS_false_when_uns_is_empty() throws {
        let context = persistenceController.viewContext
        let author = try Author.findOrCreate(by: "test", context: context)
        author.uns = ""

        XCTAssertFalse(author.hasUNS)
    }

    func test_hasUNS_true_when_uns_exists() throws {
        let context = persistenceController.viewContext
        let author = try Author.findOrCreate(by: "test", context: context)
        author.uns = "me@example.com"

        XCTAssertTrue(author.hasUNS)
    }

    func test_nip05Parts() throws {
        let context = persistenceController.viewContext
        let author = try Author.findOrCreate(by: "test", context: context)
        author.nip05 = "iamgroot@nos.social"

        let parts = try XCTUnwrap(author.nip05Parts)
        XCTAssertEqual(parts.username, "iamgroot")
        XCTAssertEqual(parts.domain, "nos.social")
    }

    func test_formattedNIP05() throws {
        let nip05 = "iamgroot@nos.social"
        let context = persistenceController.viewContext
        let author = try Author.findOrCreate(by: "test", context: context)
        author.nip05 = nip05

        XCTAssertEqual(author.formattedNIP05, nip05)
    }

    func test_formattedNIP05_with_underscore_username() throws {
        let nip05 = "_@nos.social"
        let expected = "nos.social"
        let context = persistenceController.viewContext
        let author = try Author.findOrCreate(by: "test", context: context)
        author.nip05 = nip05

        XCTAssertEqual(author.formattedNIP05, expected)
    }

    func test_formattedNIP05_with_nil_nip05() throws {
        let nip05: String? = nil
        let expected: String? = nil
        let context = persistenceController.viewContext
        let author = try Author.findOrCreate(by: "test", context: context)
        author.nip05 = nip05

        XCTAssertEqual(author.formattedNIP05, expected)
    }

    func test_formattedNIP05_with_no_at_symbol() throws {
        let nip05 = "testing"
        let expected = "testing"
        let context = persistenceController.viewContext
        let author = try Author.findOrCreate(by: "test", context: context)
        author.nip05 = nip05

        XCTAssertEqual(author.formattedNIP05, expected)
    }
}

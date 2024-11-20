import CoreData
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
    
    @MainActor func testFollowedKeysIgnoresInvalidKeys() throws {
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

    func test_weblink_with_nos_social_NIP05() throws {
        let context = persistenceController.viewContext
        let author = try Author.findOrCreate(by: "test", context: context)
        author.nip05 = "test@nos.social"
        let expected = "https://test.nos.social"
        
        XCTAssertEqual(author.webLink, expected)
    }
    
    func test_weblink_with_non_nos_social_NIP05() throws {
        let expected = "https://njump.me/user@test.net"
        let context = persistenceController.viewContext
        let author = try Author.findOrCreate(by: "test", context: context)
        author.nip05 = "user@test.net"
        
        XCTAssertEqual(author.webLink, expected)
    }
    
    func test_weblink_with_nil_NIP05() throws {
        let expected = "https://njump.me/\(KeyFixture.alice.npub)"
        let context = persistenceController.viewContext
        let author = try Author.findOrCreate(by: KeyFixture.alice.publicKeyHex, context: context)
        author.nip05 = nil
        XCTAssertEqual(author.webLink, expected)
    }
    
    // MARK: Fetch requests
    
    @MainActor func test_knownFollowers_givenMultipleFollowers() throws {
        // Arrange
        let alice = try Author.findOrCreate(by: "alice", context: testContext)
        let bob   = try Author.findOrCreate(by: "bob", context: testContext)
        bob.lastUpdatedContactList = Date(timeIntervalSince1970: 1) // for sorting
        let carl  = try Author.findOrCreate(by: "carl", context: testContext)
        carl.lastUpdatedContactList = Date(timeIntervalSince1970: 0) // for sorting
        let eve   = try Author.findOrCreate(by: "eve", context: testContext)
        
        // Act
        // Alice follows bob and carl who both follow eve
        _ = try Follow.findOrCreate(source: alice, destination: bob, context: testContext)
        _ = try Follow.findOrCreate(source: alice, destination: carl, context: testContext)
        _ = try Follow.findOrCreate(source: bob, destination: eve, context: testContext)
        _ = try Follow.findOrCreate(source: carl, destination: eve, context: testContext)
        
        try testContext.saveIfNeeded()
        
        // Assert
        XCTAssertEqual(try testContext.fetch(alice.knownFollowers(of: eve)), [bob, carl])
        XCTAssertEqual(try testContext.fetch(alice.knownFollowers(of: bob)), [])
        XCTAssertEqual(try testContext.fetch(alice.knownFollowers(of: carl)), [])
        XCTAssertEqual(try testContext.fetch(alice.knownFollowers(of: alice)), [])
    }
    
    @MainActor func test_knownFollowers_givenFollowCircle() throws {
        // Arrange
        let alice = try Author.findOrCreate(by: "alice", context: testContext)
        let bob   = try Author.findOrCreate(by: "bob", context: testContext)
        let carl  = try Author.findOrCreate(by: "carl", context: testContext)
        let eve   = try Author.findOrCreate(by: "eve", context: testContext)
        
        // Act
        // Create a circle of follows.
        _ = try Follow.findOrCreate(source: alice, destination: bob, context: testContext)
        _ = try Follow.findOrCreate(source: bob, destination: carl, context: testContext)
        _ = try Follow.findOrCreate(source: carl, destination: eve, context: testContext)
        _ = try Follow.findOrCreate(source: eve, destination: alice, context: testContext)
        
        try testContext.saveIfNeeded()
        
        // Assert
        XCTAssertEqual(try testContext.fetch(alice.knownFollowers(of: carl)), [bob])
        XCTAssertEqual(try testContext.fetch(alice.knownFollowers(of: eve)), [])
        XCTAssertEqual(try testContext.fetch(alice.knownFollowers(of: bob)), [])
        XCTAssertEqual(try testContext.fetch(alice.knownFollowers(of: alice)), [])
    }
    
    @MainActor func test_knownFollowers_givenSelfFollow() throws {
        // Arrange
        let alice = try Author.findOrCreate(by: "alice", context: testContext)
        let eve   = try Author.findOrCreate(by: "eve", context: testContext)
        
        // Act
        _ = try Follow.findOrCreate(source: alice, destination: alice, context: testContext)
        _ = try Follow.findOrCreate(source: alice, destination: eve, context: testContext)
        _ = try Follow.findOrCreate(source: eve, destination: alice, context: testContext)
        _ = try Follow.findOrCreate(source: eve, destination: eve, context: testContext)
        
        try testContext.saveIfNeeded()
        
        // Assert
        XCTAssertEqual(try testContext.fetch(alice.knownFollowers(of: eve)), [])
    }

    @MainActor func test_allPostsRequest_onlyRootPosts() throws {
        // Arrange
        let publicKey = "test"
        _ = try EventFixture.build(in: testContext, publicKey: publicKey, deletedOn: [Relay(context: testContext)])
        let author = try XCTUnwrap(Author.find(by: publicKey, context: testContext))

        // Act
        let fetchRequest = author.allPostsRequest(onlyRootPosts: true)
        let events = try testContext.fetch(fetchRequest)

        // Assert
        XCTAssertEqual(events.count, 0)
    }
    
    @MainActor func test_orphaned_givenCircleOfFollows() throws {
        // Arrange
        let alice = try Author.findOrCreate(by: "alice", context: testContext)
        let bob   = try Author.findOrCreate(by: "bob", context: testContext)
        let carl  = try Author.findOrCreate(by: "carl", context: testContext)
        let eve   = try Author.findOrCreate(by: "eve", context: testContext)
        
        // Act
        // Create a circle of follows alice -> bob -> carl -> eve -> alice
        _ = try Follow.findOrCreate(source: alice, destination: bob, context: testContext)
        _ = try Follow.findOrCreate(source: bob, destination: carl, context: testContext)
        _ = try Follow.findOrCreate(source: carl, destination: eve, context: testContext)
        _ = try Follow.findOrCreate(source: eve, destination: alice, context: testContext)
        
        try testContext.saveIfNeeded()
        
        // Act 
        let authors = try testContext.fetch(Author.orphaned(for: alice))
        
        // Assert
        XCTAssertEqual(authors, [eve])
    }
    
    @MainActor func test_orphaned_givenNoFollows() throws {
        // Arrange
        let alice = try Author.findOrCreate(by: "alice", context: testContext)
        let bob   = try Author.findOrCreate(by: "bob", context: testContext)
        let carl  = try Author.findOrCreate(by: "carl", context: testContext)
        let eve   = try Author.findOrCreate(by: "eve", context: testContext)
        
        // Act
        try testContext.saveIfNeeded()
        
        // Act 
        let authors = try testContext.fetch(Author.orphaned(for: alice))
        
        // Assert
        XCTAssertEqual(authors, [eve, carl, bob])
    }
    
        /// Test that the `pronouns` field can be set and saved correctly in Core Data.
    func testSetPronouns() throws {
        let context = persistenceController.viewContext
        let author = try Author.findOrCreate(by: "testAuthor", context: context)
        
        // Set the pronouns
        let pronouns = "they/them"
        author.pronouns = pronouns
        
        // Save the context
        try context.save()
        
        // Fetch the saved author to verify
        let fetchedAuthor = try Author.find(by: "testAuthor", context: context)
        
        XCTAssertNotNil(fetchedAuthor)
        XCTAssertEqual(fetchedAuthor?.pronouns, pronouns, "The pronouns should match the saved value.")
    }

        /// Test that the `pronouns` field can be retrieved correctly from Core Data.
    func testGetPronouns() throws {
        let context = persistenceController.viewContext
        
        // Create and set up an author with pronouns
        let pronouns = "she/her"
        let author = try Author.findOrCreate(by: "testAuthor2", context: context)
        author.pronouns = pronouns
        
        // Save the context
        try context.save()
        
        // Fetch the author again and verify pronouns
        let fetchedAuthor = try Author.find(by: "testAuthor2", context: context)
        
        XCTAssertNotNil(fetchedAuthor, "The author should have been fetched successfully.")
        XCTAssertEqual(fetchedAuthor?.pronouns, pronouns, "The fetched pronouns should match the saved value.")
    }
}

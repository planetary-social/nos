import CoreData
import Dependencies
import XCTest

final class SocialGraphCacheTests: CoreDataTestCase {

    @MainActor func testEmpty() async throws {
        // Arrange
        _ = try Author.findOrCreate(by: KeyFixture.alice.publicKeyHex, context: testContext)

        // Act
        let sut = SocialGraphCache(userKey: KeyFixture.alice.publicKeyHex, context: testContext)
        try testContext.save()

        // Assert
        try await eventually { await sut.followedKeys == Set([KeyFixture.alice.publicKeyHex]) }
    }

    /// The `XCTExpectFailure` below does _not_ work in CI. That is, when the test fails, CI still fails.
    @MainActor func testOneFollower() async throws {
        XCTExpectFailure("This test is failing intermittently, see #671", options: .nonStrict())

        // Arrange
        let alice = try Author.findOrCreate(by: KeyFixture.alice.publicKeyHex, context: testContext)
        let bob = try Author.findOrCreate(by: KeyFixture.bob.publicKeyHex, context: testContext)
        let follow = try Follow.findOrCreate(
            source: alice,
            destination: bob,
            context: testContext
        )

        // Add to the current user's follows
        alice.follows.insert(follow)
        try testContext.save()

        // Act
        let sut = SocialGraphCache(userKey: KeyFixture.alice.publicKeyHex, context: testContext)

        // Assert
        let expectedKeys = Set([KeyFixture.alice.publicKeyHex, KeyFixture.bob.publicKeyHex])
        try await eventually { await sut.followedKeys == expectedKeys }
    }

    /// The `XCTExpectFailure` below does _not_ work in CI. That is, when the test fails, CI still fails.
    @MainActor func testFollow() async throws {
        XCTExpectFailure("This test is failing intermittently, see #671", options: .nonStrict())

        // Arrange
        let alice = try Author.findOrCreate(by: KeyFixture.alice.publicKeyHex, context: testContext)
        let bob = try Author.findOrCreate(by: KeyFixture.bob.publicKeyHex, context: testContext)

        // Act
        let sut = SocialGraphCache(userKey: KeyFixture.alice.publicKeyHex, context: testContext)
        try testContext.save()

        // Assert
        let followedKeys = await sut.followedKeys
        XCTAssertEqual(followedKeys, [KeyFixture.alice.publicKeyHex])

        // Rearrange
        // alice follows bob
        let follow = try Follow.findOrCreate(source: alice, destination: bob, context: testContext)
        alice.addToFollows(follow)
        try testContext.save()

        // Reassert
        let expectedKeys = Set([KeyFixture.alice.publicKeyHex, KeyFixture.bob.publicKeyHex])
        try await eventually { await sut.followedKeys == expectedKeys }
    }

    /// The `XCTExpectFailure` below does _not_ work in CI. That is, when the test fails, CI still fails.
    @MainActor func testTwoFollows() async throws {
        XCTExpectFailure("This test is failing intermittently, see #671", options: .nonStrict())

        // Arrange
        let alice = try Author.findOrCreate(by: KeyFixture.alice.publicKeyHex, context: testContext)
        let bob = try Author.findOrCreate(by: KeyFixture.bob.publicKeyHex, context: testContext)
        let eve = try Author.findOrCreate(by: KeyFixture.eve.publicKeyHex, context: testContext)

        // Act
        let sut = SocialGraphCache(userKey: KeyFixture.alice.publicKeyHex, context: testContext)
        try testContext.save()

        // Assert
        let followedKeys = await sut.followedKeys
        XCTAssertEqual(followedKeys, [KeyFixture.alice.publicKeyHex])

        // Rearrange
        // alice follows bob
        let follow1 = try Follow.findOrCreate(source: alice, destination: bob, context: testContext)
        alice.addToFollows(follow1)
        try testContext.save()

        // alice follows carol
        let follow2 = try Follow.findOrCreate(source: alice, destination: eve, context: testContext)
        alice.addToFollows(follow2)
        try testContext.save()

        // Reassert

        let expectedKeys = Set([
            KeyFixture.alice.publicKeyHex,
            KeyFixture.eve.publicKeyHex,
            KeyFixture.bob.publicKeyHex,
        ])
        try await eventually { await sut.followedKeys == expectedKeys }
    }

    @MainActor func testTwoHops() async throws {
        // Arrange
        let alice = try Author.findOrCreate(by: KeyFixture.alice.publicKeyHex, context: testContext)
        let bob = try Author.findOrCreate(by: KeyFixture.bob.publicKeyHex, context: testContext)
        let eve = try Author.findOrCreate(by: KeyFixture.eve.publicKeyHex, context: testContext)

        // Act
        let sut = SocialGraphCache(userKey: KeyFixture.alice.publicKeyHex, context: testContext)
        try testContext.save()

        // Rearrange
        // alice follows bob
        let follow1 = try Follow.findOrCreate(source: alice, destination: bob, context: testContext)
        alice.addToFollows(follow1)
        try testContext.save()

        var expectedKeys = Set([
            KeyFixture.alice.publicKeyHex,
            KeyFixture.bob.publicKeyHex,
        ])
        try await eventually { await sut.followedKeys == expectedKeys }
        try await eventually { await !sut.isInNetwork(KeyFixture.eve.publicKeyHex) }

        // bob follows eve
        let follow2 = try Follow.findOrCreate(source: bob, destination: eve, context: testContext)
        bob.addToFollows(follow2)
        try testContext.save()

        // Reassert
        expectedKeys = Set([
            KeyFixture.alice.publicKeyHex,
            KeyFixture.bob.publicKeyHex,
        ])
        try await eventually { await sut.followedKeys == expectedKeys }
        try await eventually { await sut.isInNetwork(KeyFixture.eve.publicKeyHex) }
    }

    @MainActor func testOutOfNetwork() async throws {
        // Arrange
        _ = try Author.findOrCreate(by: KeyFixture.alice.publicKeyHex, context: testContext)
        _ = try Author.findOrCreate(by: KeyFixture.bob.publicKeyHex, context: testContext)
        _ = try Author.findOrCreate(by: KeyFixture.eve.publicKeyHex, context: testContext)

        // Act
        let sut = SocialGraphCache(userKey: KeyFixture.alice.publicKeyHex, context: testContext)
        try testContext.save()

        // Assert
        // assert twice for each key - first time hits db, second time hits cache
        var isInNetwwork = await sut.isInNetwork(KeyFixture.eve.publicKeyHex)
        XCTAssertFalse(isInNetwwork)
        isInNetwwork = await sut.isInNetwork(KeyFixture.eve.publicKeyHex)
        XCTAssertFalse(isInNetwwork)

        isInNetwwork = await sut.isInNetwork(KeyFixture.bob.publicKeyHex)
        XCTAssertFalse(isInNetwwork)
        isInNetwwork = await sut.isInNetwork(KeyFixture.bob.publicKeyHex)
        XCTAssertFalse(isInNetwwork)
    }
}

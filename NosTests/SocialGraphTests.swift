import XCTest
import CoreData
import Dependencies

final class SocialGraphTests: CoreDataTestCase {
    
    func testEmpty() async throws {
        // Arrange
        _ = try Author.findOrCreate(by: KeyFixture.alice.publicKeyHex, context: testContext)
        
        // Act
        let sut = SocialGraphCache(userKey: KeyFixture.alice.publicKeyHex, context: testContext)
        try testContext.save()
        
        // Assert
        try await eventually { await sut.followedKeys == Set([KeyFixture.alice.publicKeyHex]) }
    }
    
    func testOneFollower() async throws {
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
    
    func testOutOfNetwork() async throws {
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

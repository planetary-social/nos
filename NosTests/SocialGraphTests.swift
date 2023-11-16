//
//  SocialGraphTests.swift
//  NosTests
//
//  Created by Matthew Lorentz on 4/18/23.
//

import XCTest
import CoreData
import Dependencies

// swiftlint:disable implicitly_unwrapped_optional

final class SocialGraphTests: XCTestCase {
    
    var testContext: NSManagedObjectContext!
    
    override func invokeTest() {
        // For some reason that I can't figure out using an in-memory persistent store causes these tests to take
        // several minutes instead of seconds, so we are using an on-disk store for these tests instead.
        withDependencies { dependencies in
            let persistenceController = PersistenceController(containerName: "NosTests")
            persistenceController.resetForTesting()
            dependencies.persistenceController = persistenceController
            self.testContext = persistenceController.viewContext
        } operation: {
            super.invokeTest()
        }
    }

    func testEmpty() async throws {
        // Arrange
        _ = try Author.findOrCreate(by: KeyFixture.alice.publicKeyHex, context: testContext)
        
        // Act
        let sut = await SocialGraphCache(userKey: KeyFixture.alice.publicKeyHex, context: testContext)
        try testContext.save()
        
        // Assert
        let followedKeys = await sut.followedKeys
        XCTAssertEqual(followedKeys, [KeyFixture.alice.publicKeyHex])
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
        
        // Add from the current user to the author's followers
        bob.followers.insert(follow)
        
        // Act
        let sut = await SocialGraphCache(userKey: KeyFixture.alice.publicKeyHex, context: testContext)
        try testContext.save()
        
        // Assert
        let followedKeys = await sut.followedKeys
        XCTAssertEqual(followedKeys, [KeyFixture.alice.publicKeyHex, KeyFixture.bob.publicKeyHex])
    }
    
    func testFollow() async throws {
        // Arrange
        let alice = try Author.findOrCreate(by: KeyFixture.alice.publicKeyHex, context: testContext)
        let bob = try Author.findOrCreate(by: KeyFixture.bob.publicKeyHex, context: testContext)
        
        // Act
        let sut = await SocialGraphCache(userKey: KeyFixture.alice.publicKeyHex, context: testContext)
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
        try await eventually { await sut.followedKeys.count == 2 }
        let newFollowedKeys = await sut.followedKeys
        XCTAssertEqual(newFollowedKeys, [KeyFixture.alice.publicKeyHex, KeyFixture.bob.publicKeyHex])
    }
    
    func testTwoFollows() async throws {
        // Arrange
        let alice = try Author.findOrCreate(by: KeyFixture.alice.publicKeyHex, context: testContext)
        let bob = try Author.findOrCreate(by: KeyFixture.bob.publicKeyHex, context: testContext)
        let eve = try Author.findOrCreate(by: KeyFixture.eve.publicKeyHex, context: testContext)
        
        // Act
        let sut = await SocialGraphCache(userKey: KeyFixture.alice.publicKeyHex, context: testContext)
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
        try await eventually { await sut.followedKeys.count == 3 }
        let newFollowedKeys = await sut.followedKeys.sorted()
        let expected = [
            KeyFixture.alice.publicKeyHex,
            KeyFixture.eve.publicKeyHex,
            KeyFixture.bob.publicKeyHex
        ].sorted()
        XCTAssertEqual(newFollowedKeys, expected)
    }
}
// swiftlint:enable implicitly_unwrapped_optional

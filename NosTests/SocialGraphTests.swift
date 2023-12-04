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
            let persistenceController = PersistenceController(containerName: "NosTests", inMemory: true)
            testContext = persistenceController.viewContext
            dependencies.persistenceController = persistenceController
        } operation: {
            super.invokeTest()
        }
    }

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
    
    func testFollow() async throws {
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
    
    func testTwoFollows() async throws {
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
            KeyFixture.bob.publicKeyHex
        ])
        try await eventually { await sut.followedKeys == expectedKeys }
    }
    
    func testTwoHops() async throws {
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
            KeyFixture.bob.publicKeyHex
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
            KeyFixture.bob.publicKeyHex
        ])
        try await eventually { await sut.followedKeys == expectedKeys }
        try await eventually { await sut.isInNetwork(KeyFixture.eve.publicKeyHex) }
    }
}
// swiftlint:enable implicitly_unwrapped_optional

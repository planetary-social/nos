//
//  AuthorTests.swift
//  NosTests
//
//  Created by Matthew Lorentz on 1/24/24.
//

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
}

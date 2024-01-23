//
//  AuthorTests.swift
//  NosTests
//
//  Created by Matthew Lorentz on 1/22/24.
//

import XCTest
import Dependencies

/// Tests for the `Author` model.
final class AuthorTests: XCTestCase {
    
    @Dependency(\.persistenceController) private var persistenceController
    
    override func setUpWithError() throws {
        persistenceController.resetForTesting()
    }

    /// Verifies that the `followedKeys` property returns the correct set of keys followed by the author. 
    /// Written for bug [#845](https://github.com/planetary-social/nos/issues/845).
    func testFollowedKeys() throws {
        let context = persistenceController.viewContext
        let author = try Author.findOrCreate(by: "test", context: context)
        var expectedFollowedKeys = [String]()
        
        for i in 0..<700 {
            let followee = try Author.findOrCreate(by: "\(i)", context: context)
            let follow = Follow(context: context)
            follow.source = author
            follow.destination = followee
            expectedFollowedKeys.append("\(i)")
        }
        
        XCTAssertEqual(author.follows.count, 700)
        XCTAssertEqual(Set(author.followedKeys), Set(expectedFollowedKeys))
    }
}

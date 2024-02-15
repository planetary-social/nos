//
//  FollowTests.swift
//  NosTests
//
//  Created by Matthew Lorentz on 1/24/24.
//

import XCTest

/// Tests for the `Follow` model.
final class FollowTests: CoreDataTestCase {

    func testFollowWithBadHexDoesNotSave() throws {
        let author = try Author.findOrCreate(by: "test", context: testContext)
        XCTAssertThrowsError(try Follow.upsert(by: author, jsonTag: ["p", "artstr"], context: testContext))
    }
}

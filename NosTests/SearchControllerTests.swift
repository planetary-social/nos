//
//  SearchControllerTests.swift
//  NosTests
//
//  Created by Josh on 2/5/24.
//

import XCTest

class SearchControllerTests: XCTestCase {
    static var previewData = PreviewData()

    /// Verifies that `clear()` resets the state.
    func test_clear() {
        // Arrange
        let subject = SearchController()
        subject.query = "hello"
        subject.state = .results
        subject.authorResults = [Self.previewData.alice]

        // Act
        subject.clear()

        // Assert
        XCTAssertEqual(subject.query, "")
        XCTAssertEqual(subject.state, .noQuery)
        XCTAssertTrue(subject.authorResults.isEmpty)
    }
}

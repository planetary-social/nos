//
//  NosTests.swift
//  NosTests
//
//  Created by Matthew Lorentz on 1/31/23.
//

import XCTest
@testable import Nos

final class NosTests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testParseSampleData() throws {
        // Arrange
        let sampleData = try Data(contentsOf: Bundle.current.url(forResource: "sample_data", withExtension: "json")!)
        let sampleEventID = "afc8a1cf67bddd12595c801bdc8c73ec1e8dfe94920f6c5ae5575c433722840e"
        
        // Act
        let events = try Event.parse(jsonData: sampleData, in: PersistenceController(inMemory: true))
        let sampleEvent = try XCTUnwrap(events.first(where: { $0.identifier == sampleEventID }))
        
        // Assert
        XCTAssertEqual(events.count, 142)
        XCTAssertEqual(sampleEvent.signature, "31c710803d3b77cb2c61697c8e2a980a53ec66e980990ca34cc24f9018bf85bfd2b0669c1404f364de776a9d9ed31a5d6d32f5662ac77f2dc6b89c7762132d63")
        XCTAssertEqual(sampleEvent.kind, 1)
        XCTAssertEqual(sampleEvent.tags?.count, 0)
        XCTAssertEqual(sampleEvent.author?.hex, "d0a1ffb8761b974cec4a3be8cbcb2e96a7090dcf465ffeac839aa4ca20c9a59e")
        XCTAssertEqual(sampleEvent.content, "Spent today on our company retreat talking a lot about Nostr. The team seems very keen to build something in this space. It’s exciting to be opening our minds to so many possibilities after being deep in the Scuttlebutt world for so long.")
        XCTAssertEqual(sampleEvent.createdAt?.timeIntervalSince1970, 1674624689)
    }

}

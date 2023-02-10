//
//  EventTests.swift
//  NosTests
//
//  Created by Matthew Lorentz on 1/31/23.
//

import XCTest
import CoreData
import secp256k1
import secp256k1_bindings
@testable import Nos

// swiftlint:disable force_unwrapping

/// Tests for the Event model.
final class EventTests: XCTestCase {
    
    // swiftlint:disable line_length
    // swiftlint:disable indentation_width
    let sampleEventJSONString =
        """
        {
          "kind": 1,
          "content": "Testing nos #[0]",
          "tags": [
            [
              "p",
              "d0a1ffb8761b974cec4a3be8cbcb2e96a7090dcf465ffeac839aa4ca20c9a59e"
            ]
          ],
          "created_at": 1675264762,
          "pubkey": "32730e9dfcab797caf8380d096e548d9ef98f3af3000542f9271a91a9e3b0001",
          "id": "931b425e55559541451ddb99bd228bd1e0190af6ed21603b6b98544b42ee3317",
          "sig": "79862bd81b316411c23467632239750c97f3aa974593c01bd61d2ca85eedbcfd9a18886b0dad1c17b2e8ceb231db37add136fc23120b45aa5403d6fd2d693e9b"
        }
        """
    // swiftlint:enable indentation_width
    
    let sampleEventSignature = "31c710803d3b77cb2c61697c8e2a980a53ec66e980990ca34cc24f9018bf85bfd2b0669c1404f364de776a9d9ed31a5d6d32f5662ac77f2dc6b89c7762132d63"
    let sampleEventPubKey = "d0a1ffb8761b974cec4a3be8cbcb2e96a7090dcf465ffeac839aa4ca20c9a59e"
    let sampleEventContent = "Spent today on our company retreat talking a lot about Nostr. The team seems very keen to build something in this space. It’s exciting to be opening our minds to so many possibilities after being deep in the Scuttlebutt world for so long."
    
    // swiftlint:enable line_length

    func testParseSampleData() throws {
        // Arrange
        let sampleData = try Data(contentsOf: Bundle.current.url(forResource: "sample_data", withExtension: "json")!)
        let sampleEventID = "afc8a1cf67bddd12595c801bdc8c73ec1e8dfe94920f6c5ae5575c433722840e"
        
        // Act
        let events = try Event.parse(jsonData: sampleData, in: PersistenceController(inMemory: true))
        let sampleEvent = try XCTUnwrap(events.first(where: { $0.identifier == sampleEventID }))
        
        // Assert
        XCTAssertEqual(events.count, 142)
        XCTAssertEqual(sampleEvent.signature, sampleEventSignature)
        XCTAssertEqual(sampleEvent.kind, 1)
        XCTAssertEqual(sampleEvent.tags?.count, 0)
        XCTAssertEqual(sampleEvent.author?.hexadecimalPublicKey, sampleEventPubKey)
        XCTAssertEqual(sampleEvent.content, sampleEventContent)
        XCTAssertEqual(sampleEvent.createdAt?.timeIntervalSince1970, 1_674_624_689)
    }
    
    func testTagJSONRepresentation() throws {
        let persistenceController = PersistenceController(inMemory: true)
        let testContext = persistenceController.container.viewContext
        let tag = Tag(context: testContext)
        tag.identifier = "x"
        tag.metadata = ["blah", "blah", "foo"] as NSObject
        
        XCTAssertEqual(tag.jsonRepresentation, ["x", "blah", "blah", "foo"])
    }
    
    func testSerializedEventForSigning() throws {
        // Arrange
        let persistenceController = PersistenceController(inMemory: true)
        let testContext = persistenceController.container.viewContext
        let event = try createTestEvent(in: testContext)
        // swiftlint:disable line_length
        let expectedString = """
        [0,"32730e9dfcab797caf8380d096e548d9ef98f3af3000542f9271a91a9e3b0001",1675264762,1,[["p","d0a1ffb8761b974cec4a3be8cbcb2e96a7090dcf465ffeac839aa4ca20c9a59e"]],"Testing nos #[0]"]
        """.trimmingCharacters(in: .whitespacesAndNewlines)
        // swiftlint:enable line_length
        
        // Act
        let serializedData = try JSONSerialization.data(withJSONObject: event.serializedEventForSigning)
        let actualString = String(data: serializedData, encoding: .utf8)
        
        // Assert
        XCTAssertEqual(actualString, expectedString)
    }
    
    func testIdentifierCalcuation() throws {
        // Arrange
        let persistenceController = PersistenceController(inMemory: true)
        let testContext = persistenceController.container.viewContext
        let event = try createTestEvent(in: testContext)
        
        // Act
        XCTAssertEqual(
            try event.calculateIdentifier(),
            "931b425e55559541451ddb99bd228bd1e0190af6ed21603b6b98544b42ee3317"
        )
    }
    
    func testSigning() throws {
        // Arrange
        
        let persistenceController = PersistenceController(inMemory: true)
        let testContext = persistenceController.container.viewContext
        let event = try createTestEvent(in: testContext)
        
        // Act
        try event.sign(withKey: KeyFixture.keyPair)
        
        // Assert
        XCTAssertEqual(event.identifier, "931b425e55559541451ddb99bd228bd1e0190af6ed21603b6b98544b42ee3317")
        XCTExpectFailure(
            "I think the signature is non-deterministic. Update this test after we write code to verify signatures."
        )
        XCTAssertEqual(
            event.signature,
            // swiftlint:disable line_length
            "79862bd81b316411c23467632239750c97f3aa974593c01bd61d2ca85eedbcfd9a18886b0dad1c17b2e8ceb231db37add136fc23120b45aa5403d6fd2d693e9b"
            // swiftlint:enable line_length
        )
    }

    // MARK: - Helpers
    
    private func createTestEvent(in context: NSManagedObjectContext) throws -> Event {
        let event = Event(context: context)
        event.createdAt = Date(timeIntervalSince1970: TimeInterval(1_675_264_762))
        event.content = "Testing nos #[0]"
        event.kind = 1
        
        let author = Author(context: context)
        author.hexadecimalPublicKey = KeyFixture.pubKeyHex
        event.author = author
        
        let tag = Tag(context: context)
        tag.identifier = "p"
        tag.metadata = ["d0a1ffb8761b974cec4a3be8cbcb2e96a7090dcf465ffeac839aa4ca20c9a59e"] as NSObject
        event.tags = NSOrderedSet(array: [tag])
        return event
    }
}

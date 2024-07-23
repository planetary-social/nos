import XCTest

class JSONEventTests: XCTestCase {
    func test_replaceableID() throws {
        // Arrange
        let replaceableID = "TGnBRh9-b1jrqSJ-ByWQx"
        let subject = JSONEvent(
            pubKey: "",
            kind: .longFormContent,
            tags: [["d", replaceableID]],
            content: "Test"
        )

        // Act & Assert
        XCTAssertEqual(subject.replaceableID, replaceableID)
    }
}

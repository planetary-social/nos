import CoreData
import XCTest

/// Tests for the `AuthorList` model.
/// - Note: There are additional tests for `AuthorList` in `EventProcessorIntegrationTests+FollowSet.swift`.
final class AuthorListTests: CoreDataTestCase {
    @MainActor func test_createOrUpdate_throws_when_json_event_is_the_wrong_kind() throws {
        // Arrange
        let data = try jsonData(filename: "long_form_data")
        let events = try JSONDecoder().decode([JSONEvent].self, from: data)
        let jsonEvent = try XCTUnwrap(events.first)

        // Act & Assert
        XCTAssertThrowsError(try AuthorList.createOrUpdate(from: jsonEvent, in: testContext)) { error in
            XCTAssertEqual(error as? AuthorListError, AuthorListError.invalidKind)
        }
    }

    @MainActor func test_createOrUpdate_throws_when_json_event_is_missing_replaceableID() throws {
        // Arrange
        let data = try jsonData(filename: "follow_set")
        var event = try JSONDecoder().decode(JSONEvent.self, from: data)
        event.tags = [[]]

        // Act & Assert
        XCTAssertThrowsError(try AuthorList.createOrUpdate(from: event, in: testContext)) { error in
            XCTAssertEqual(error as? AuthorListError, AuthorListError.missingReplaceableID)
        }
    }

    @MainActor func test_createOrUpdate_includes_all_data() throws {
        // Arrange
        let data = try jsonData(filename: "follow_set")
        let event = try JSONDecoder().decode(JSONEvent.self, from: data)

        // Act
        let list = try AuthorList.createOrUpdate(from: event, in: testContext)

        // Assert
        XCTAssertEqual(list.kind, EventKind.followSet.rawValue)
        XCTAssertEqual(list.identifier, "85e1542678164c321c413706b9c029da2355809884902dbbfd6879917148c221")
        XCTAssertEqual(
            list.author?.hexadecimalPublicKey,
            "27cf2c68535ae1fc06510e827670053f5dcd39e6bd7e05f1ffb487ef2ac13549"
        )
        // swiftlint:disable:next number_separator
        XCTAssertEqual(list.createdAt, Date(timeIntervalSince1970: 1733516879))
        XCTAssertEqual(list.authors.count, 2)
        XCTAssertEqual(list.title, "A few good people")
        XCTAssertEqual(list.listDescription, "They're great. Trust me.")
        XCTAssertEqual(list.replaceableIdentifier, "listr-7ad818d7-1360-4fcb-8dbd-2ad76be88465")
        XCTAssertEqual(list.content, "")
        XCTAssertEqual(list.signature, "acdf769441a6644e3ae64f8aa1e5f4175a1045e2129e31ae806508515cb65fb5d3207a1f5f05094e09e46cb28c5a3dad5bb2886ab6f5b1faa1f4da8a9f202b04") // swiftlint:disable:this line_length
    }

    @MainActor func test_signature() throws {
        // Arrange
        let data = try jsonData(filename: "follow_set")
        let event = try JSONDecoder().decode(JSONEvent.self, from: data)
        let list = try AuthorList.createOrUpdate(from: event, in: testContext)

        // Act
        let verified = try list.verifySignature()

        // Assert
        XCTAssertTrue(verified)
    }
}

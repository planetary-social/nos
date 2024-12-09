import CoreData
import XCTest

/// Tests for the `AuthorList` model.
/// - Note: There are additional tests for `AuthorList` in `EventProcessorIntegrationTests+FollowSet.swift`.
final class AuthorListTests: CoreDataTestCase {
    @MainActor func test_createOrUpdate_throws_when_json_event_is_the_wrong_kind() throws {
        let data = try jsonData(filename: "long_form_data")
        let events = try JSONDecoder().decode([JSONEvent].self, from: data)
        let jsonEvent = try XCTUnwrap(events.first)

        XCTAssertThrowsError(try AuthorList.createOrUpdate(from: jsonEvent, in: testContext)) { error in
            XCTAssertEqual(error as? AuthorListError, AuthorListError.invalidKind)
        }
    }

    @MainActor func test_createOrUpdate_throws_when_json_event_is_missing_replaceableID() throws {
        let data = try jsonData(filename: "follow_set")
        var event = try JSONDecoder().decode(JSONEvent.self, from: data)
        event.tags = [[]]

        XCTAssertThrowsError(try AuthorList.createOrUpdate(from: event, in: testContext)) { error in
            XCTAssertEqual(error as? AuthorListError, AuthorListError.missingReplaceableID)
        }
    }
}

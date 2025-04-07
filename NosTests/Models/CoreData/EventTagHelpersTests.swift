import XCTest
import CoreData

/// Tests for the Event tag parsing helper methods.
final class EventTagHelpersTests: CoreDataTestCase {
    
    @MainActor func testTagArray() throws {
        // Arrange
        let tags = [["title", "Test Title"], ["imeta", "url https://example.com/image.jpg"]]
        let event = try EventFixture.build(in: testContext, tags: tags)
        
        // Act
        let tagArray = event.tagArray
        
        // Assert
        XCTAssertEqual(tagArray, tags)
    }
    
    @MainActor func testGetTagValue() throws {
        // Arrange
        let tags = [["title", "Test Title"], ["imeta", "url https://example.com/image.jpg"]]
        let event = try EventFixture.build(in: testContext, tags: tags)
        
        // Act
        let title = event.getTagValue(key: "title")
        let nonExistent = event.getTagValue(key: "nonexistent")
        
        // Assert
        XCTAssertEqual(title, "Test Title")
        XCTAssertNil(nonExistent)
    }
    
    @MainActor func testGetTags() throws {
        // Arrange
        let tags = [
            ["imeta", "url https://example.com/image1.jpg"],
            ["imeta", "url https://example.com/image2.jpg"],
            ["title", "Test Title"]
        ]
        let event = try EventFixture.build(in: testContext, tags: tags)
        
        // Act
        let imetaTags = event.getTags(withKey: "imeta")
        
        // Assert
        XCTAssertEqual(imetaTags.count, 2)
        XCTAssertEqual(imetaTags, [
            ["imeta", "url https://example.com/image1.jpg"],
            ["imeta", "url https://example.com/image2.jpg"]
        ])
    }
    
    @MainActor func testGetMediaMetaTags() throws {
        // Arrange
        let tags = [
            ["imeta", "url https://example.com/image1.jpg"],
            ["imeta", "url https://example.com/image2.jpg"],
            ["title", "Test Title"]
        ]
        let event = try EventFixture.build(in: testContext, tags: tags)
        
        // Act
        let mediaTags = event.getMediaMetaTags()
        
        // Assert
        XCTAssertEqual(mediaTags.count, 2)
        XCTAssertEqual(mediaTags, [
            ["imeta", "url https://example.com/image1.jpg"],
            ["imeta", "url https://example.com/image2.jpg"]
        ])
    }
    
    @MainActor func testGetURLFromTag() throws {
        // Arrange
        let event = try EventFixture.build(in: testContext)
        let validTag = ["imeta", "url https://example.com/image.jpg"]
        let invalidTag = ["imeta", "not a url"]
        
        // Act
        let validURL = event.getURLFromTag(validTag)
        let invalidURL = event.getURLFromTag(invalidTag)
        
        // Assert
        XCTAssertEqual(validURL?.absoluteString, "https://example.com/image.jpg")
        XCTAssertNil(invalidURL)
    }
    
    @MainActor func testGetURLFromTag_EmptyTag() throws {
        // Arrange
        let event = try EventFixture.build(in: testContext)
        let emptyTag: [String] = []
        
        // Act
        let url = event.getURLFromTag(emptyTag)
        
        // Assert
        XCTAssertNil(url)
    }
}
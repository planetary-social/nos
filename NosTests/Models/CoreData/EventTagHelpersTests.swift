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
    
    @MainActor func testGetMimeType_WithExplicitMimeTag() throws {
        // Arrange
        let event = try EventFixture.build(in: testContext)
        let tag = ["imeta", "url https://example.com/video.mp4", "m video/mp4"]
        
        // Act
        let mimeType = event.getMimeType(from: tag)
        
        // Assert
        XCTAssertEqual(mimeType, "video/mp4")
    }
    
    @MainActor func testGetMimeType_WithImplicitMimeString() throws {
        // Arrange
        let event = try EventFixture.build(in: testContext)
        let tag = ["imeta", "url https://example.com/video.mp4", "video/mp4"]
        
        // Act
        let mimeType = event.getMimeType(from: tag)
        
        // Assert
        XCTAssertEqual(mimeType, "video/mp4")
    }
    
    @MainActor func testGetMimeType_FromURLExtension() throws {
        // Arrange
        let event = try EventFixture.build(in: testContext)
        let videoTag = ["imeta", "url https://example.com/video.mp4"]
        let imageTag = ["imeta", "url https://example.com/image.jpg"]
        let audioTag = ["imeta", "url https://example.com/audio.mp3"]
        
        // Act
        let videoMimeType = event.getMimeType(from: videoTag)
        let imageMimeType = event.getMimeType(from: imageTag)
        let audioMimeType = event.getMimeType(from: audioTag)
        
        // Assert
        XCTAssertEqual(videoMimeType, "video/mp4")
        XCTAssertEqual(imageMimeType, "image/jpeg")
        XCTAssertEqual(audioMimeType, "audio/mp3")
    }
    
    @MainActor func testGetMimeType_WithNoMimeInfo() throws {
        // Arrange
        let event = try EventFixture.build(in: testContext)
        let tag = ["imeta", "url https://example.com/unknown"]
        
        // Act
        let mimeType = event.getMimeType(from: tag)
        
        // Assert
        XCTAssertNil(mimeType)
    }
    
    @MainActor func testIsVideoTag_WithExplicitMimeType() throws {
        // Arrange
        let event = try EventFixture.build(in: testContext)
        let videoTag = ["imeta", "url https://example.com/video.mp4", "m video/mp4"]
        let imageTag = ["imeta", "url https://example.com/image.jpg", "m image/jpeg"]
        
        // Act & Assert
        XCTAssertTrue(event.isVideoTag(videoTag))
        XCTAssertFalse(event.isVideoTag(imageTag))
    }
    
    @MainActor func testIsVideoTag_WithURLExtension() throws {
        // Arrange
        let event = try EventFixture.build(in: testContext)
        let mp4Tag = ["imeta", "url https://example.com/video.mp4"]
        let movTag = ["imeta", "url https://example.com/video.mov"]
        let webmTag = ["imeta", "url https://example.com/video.webm"]
        let jpgTag = ["imeta", "url https://example.com/image.jpg"]
        let txtTag = ["imeta", "url https://example.com/document.txt"]
        
        // Act & Assert
        XCTAssertTrue(event.isVideoTag(mp4Tag))
        XCTAssertTrue(event.isVideoTag(movTag))
        XCTAssertTrue(event.isVideoTag(webmTag))
        XCTAssertFalse(event.isVideoTag(jpgTag))
        XCTAssertFalse(event.isVideoTag(txtTag))
    }
    
    @MainActor func testIsVideoTag_WithNoIdentifiableInfo() throws {
        // Arrange
        let event = try EventFixture.build(in: testContext)
        let tag = ["imeta", "url https://example.com/unknown"]
        
        // Act & Assert
        XCTAssertFalse(event.isVideoTag(tag))
    }
}

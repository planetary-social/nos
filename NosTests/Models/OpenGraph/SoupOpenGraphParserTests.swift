import Foundation
import XCTest

class SoupOpenGraphParserTests: XCTestCase {
    // swiftlint:disable:next implicitly_unwrapped_optional
    var youTubeHTML: Data!

    override func setUpWithError() throws {
        youTubeHTML = try htmlData(filename: "youtube_video_toxic")
    }

    func test_parse_sample_video() throws {
        // Arrange
        let parser = SoupOpenGraphParser()
        let data = try XCTUnwrap(sampleVideoHTML.data(using: .utf8))

        // Act
        let metadata = try XCTUnwrap(parser.metadata(html: data))

        // Assert
        XCTAssertEqual(metadata.type, .video)
        
        XCTAssertEqual(metadata.video?.url?.absoluteString, "https://example.com/movie.swf")
        XCTAssertEqual(metadata.video?.width, 2560)
        XCTAssertEqual(metadata.video?.height, 1440)

        XCTAssertEqual(metadata.image?.url?.absoluteString, "https://example.com/rock.jpg")
        XCTAssertEqual(metadata.image?.width, 1280)
        XCTAssertEqual(metadata.image?.height, 720)
    }

    func test_parse_sample_video_secure_url() throws {
        // Arrange
        let parser = SoupOpenGraphParser()
        let data = try XCTUnwrap(sampleVideoSecureURLHTML.data(using: .utf8))

        // Act
        let metadata = try XCTUnwrap(parser.metadata(html: data))

        // Assert
        XCTAssertEqual(metadata.type, .unknown)
        
        XCTAssertEqual(metadata.video?.url?.absoluteString, "https://example.com/rock.mp4")
        XCTAssertEqual(metadata.image?.url?.absoluteString, "https://example.com/rock.jpg")
    }

    func test_parse_sample_video_missing_metadata() throws {
        // Arrange
        let parser = SoupOpenGraphParser()
        let data = try XCTUnwrap(sampleVideoMissingMetadataHTML.data(using: .utf8))

        // Act
        let metadata = try XCTUnwrap(parser.metadata(html: data))

        // Assert
        XCTAssertEqual(metadata.type, .video)

        XCTAssertNil(metadata.video?.url)
        XCTAssertEqual(metadata.video?.width, 1280)
        XCTAssertNil(metadata.video?.height)

        XCTAssertNil(metadata.image)
    }

    func test_parse_sample_website() throws {
        // Arrange
        let parser = SoupOpenGraphParser()
        let data = try XCTUnwrap(sampleWebsiteHTML.data(using: .utf8))

        // Act
        let metadata = try XCTUnwrap(parser.metadata(html: data))

        // Assert
        XCTAssertEqual(metadata.type, .website)

        XCTAssertEqual(metadata.image?.url?.absoluteString, "https://example.com/rock.jpg")
        XCTAssertEqual(metadata.image?.width, 640)
        XCTAssertEqual(metadata.image?.height, 480)
    }

    func test_parse_sample_website_with_missing_metadata() throws {
        // Arrange
        let parser = SoupOpenGraphParser()
        let data = try XCTUnwrap(sampleWebsiteMissingMetadataHTML.data(using: .utf8))

        // Act
        let metadata = try XCTUnwrap(parser.metadata(html: data))

        // Assert
        XCTAssertEqual(metadata.type, .unknown)
        XCTAssertEqual(metadata.image?.width, 640)
    }

    func test_parse_youTube() throws {
        // Arrange
        let parser = SoupOpenGraphParser()
        let data = try XCTUnwrap(youTubeHTML)

        // Act
        let metadata = try XCTUnwrap(parser.metadata(html: data))

        // Assert
        XCTAssertEqual(metadata.title, "Toxic - Vintage 1930s Torch Song Britney Spears Cover ft. Melinda Doolittle")

        XCTAssertEqual(metadata.type, .video)

        XCTAssertEqual(metadata.video?.url?.absoluteString, "https://www.youtube.com/embed/ZILsHowUjpQ")
        XCTAssertEqual(metadata.video?.width, 1280)
        XCTAssertEqual(metadata.video?.height, 720)
        
        XCTAssertEqual(metadata.image?.width, 1280)
        XCTAssertEqual(metadata.image?.height, 720)
    }

    func test_parse_youTube_fornight_short() throws {
        // Arrange
        let parser = SoupOpenGraphParser()
        let data = try XCTUnwrap(try htmlData(filename: "youTube_fortnight_short"))

        // Act
        let metadata = try XCTUnwrap(parser.metadata(html: data))

        // Assert
        XCTAssertEqual(
            metadata.title, 
            "A fortnight since TTPD 🤍 brought to you by YouTube Shorts #ForAFortnightChallenge"
        )

        XCTAssertEqual(metadata.type, .video)

        XCTAssertEqual(metadata.video?.width, 405)
        XCTAssertEqual(metadata.video?.height, 720)

        let sample = OpenGraphMetadata(title: "", type: .unknown, image: nil, video: nil)
        XCTAssertNotNil(sample)
    }
}

extension SoupOpenGraphParserTests {
    var sampleVideoHTML: String {
        """
        <!DOCTYPE html>
        <html>
        <head>
            <meta property="og:type" content="video.movie">
            <meta property="og:video" content="https://example.com/movie.swf">
            <meta property="og:video:width" content="2560">
            <meta property="og:video:height" content="1440">
            <meta property="og:image" content="https://example.com/rock.jpg">
            <meta property="og:image:width" content="1280">
            <meta property="og:image:height" content="720">
        </head>
        <body>
            <h1>Sample HTML</h1>
        </body>
        </html>
        """
    }

    var sampleVideoSecureURLHTML: String {
        """
        <!DOCTYPE html>
        <html>
        <head>
            <meta property="og:video:secure_url" content="https://example.com/rock.mp4">
            <meta property="og:image:secure_url" content="https://example.com/rock.jpg">
        </head>
        <body>
            <h1>Sample HTML</h1>
        </body>
        </html>
        """
    }

    var sampleVideoMissingMetadataHTML: String {
        """
        <!DOCTYPE html>
        <html>
        <head>
            <meta property="og:type" content="video.other">
            <meta property="og:video:width" content="1280">
        </head>
        <body>
            <h1>Video with less metadata</h1>
        </body>
        </html>
        """
    }

    var sampleWebsiteHTML: String {
        """
        <!DOCTYPE html>
        <html>
        <head>
            <meta property="og:type" content="website">
            <meta property="og:image:url" content="https://example.com/rock.jpg">
            <meta property="og:image:width" content="640">
            <meta property="og:image:height" content="480">
        </head>
        <body>
            <blink>Welcome to my website!</blink>
        </body>
        </html>
        """
    }

    var sampleWebsiteMissingMetadataHTML: String {
        """
        <!DOCTYPE html>
        <html>
        <head>
            <meta property="og:image:width" content="640">
        </head>
        <body>
            <blink>Welcome to my website!</blink>
        </body>
        </html>
        """
    }
}

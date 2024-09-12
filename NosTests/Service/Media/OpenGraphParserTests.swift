import Foundation
import XCTest

class OpenGraphParserTests: XCTestCase {
    let sampleHTML = """
    <!DOCTYPE html>
    <html>
    <head>
        <meta property="og:video:width" content="2560">
        <meta property="og:video:height" content="1440">
    </head>
    <body>
        <h1>Sample HTML</h1>
    </body>
    </html>
    """

    var youTubeHTML: String!

    override func setUpWithError() throws {
        youTubeHTML = try htmlString(filename: "youtube_video_toxic")
    }

    func test_parse() throws {
        // Arrange
        let parser = XMLOpenGraphParser()

        // Act
        let videoMetadata = try XCTUnwrap(parser.videoMetadata(html: sampleHTML))

        // Assert
        XCTAssertEqual(videoMetadata.width, 2560)
    }

    func test_parse_youTube() throws {
        // Arrange
        let parser = XMLOpenGraphParser()

        // Act
        let videoMetadata = try XCTUnwrap(parser.videoMetadata(html: youTubeHTML))

        // Assert
        XCTAssertEqual(videoMetadata.width, 1280)
    }
}

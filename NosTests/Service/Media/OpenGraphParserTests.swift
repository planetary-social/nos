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

    // swiftlint:disable:next implicitly_unwrapped_optional
    var youTubeHTML: String!

    override func setUpWithError() throws {
        youTubeHTML = try htmlString(filename: "youtube_video_toxic")
    }

    func test_parse() throws {
        // Arrange
        let parser = XMLOpenGraphParser()
        let data = try XCTUnwrap(sampleHTML.data(using: .utf8))

        // Act
        let videoMetadata = try XCTUnwrap(parser.videoMetadata(html: data))

        // Assert
        XCTAssertEqual(videoMetadata.width, 2560)
        XCTAssertEqual(videoMetadata.height, 1440)
    }

    func test_parse_youTube() throws {
        // Arrange
        let parser = XMLOpenGraphParser()
        let data = try XCTUnwrap(youTubeHTML.data(using: .utf8))

        // Act
        let videoMetadata = try XCTUnwrap(parser.videoMetadata(html: data))

        // Assert
        XCTAssertEqual(videoMetadata.width, 1280)
        XCTAssertEqual(videoMetadata.width, 720)
    }
}

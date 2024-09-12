import Foundation
import XCTest

class OpenGraphParser: NSObject, XMLParserDelegate {
    private var currentElement = ""
    private var videoWidth: String?

    func videoWidth(data: Data) -> Double? {
        let parser = XMLParser(data: data)
        parser.delegate = self
        parser.parse()

        guard let videoWidth else { return nil }
        return Double(videoWidth)
    }

    // XMLParserDelegate methods
    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String] = [:]) {
        currentElement = elementName
        if elementName == "meta", let property = attributeDict["property"], property == "og:video:width" {
            videoWidth = attributeDict["content"]
        }
    }

    func parser(_ parser: XMLParser, foundCharacters string: String) {
        // No need to handle characters for meta tags
    }

    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        currentElement = ""
    }

    func parser(_ parser: XMLParser, parseErrorOccurred parseError: Error) {
        print("Parse error: \(parseError.localizedDescription)")
    }
}

class XMLParserTests: XCTestCase {
    func test_parse() throws {
        // Arrange
        let htmlString = """
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

        let data = try XCTUnwrap(htmlString.data(using: .utf8))
        let parser = OpenGraphParser()

        // Act
        let videoWidth = try XCTUnwrap(parser.videoWidth(data: data))

        // Assert
        XCTAssertEqual(videoWidth, 2560)
    }

    func test_parse_youtube() throws {
        // Arrange
        let htmlString = try htmlString(filename: "youtube_video_toxic")
        let data = try XCTUnwrap(htmlString.data(using: .utf8))
        let parser = OpenGraphParser()

        // Act
        let videoWidth = try XCTUnwrap(parser.videoWidth(data: data))

        // Assert
        XCTAssertEqual(videoWidth, 1280)
    }
}

import Dependencies
import XCTest

class DefaultOpenGraphServiceTests: XCTestCase {
    func test_fetchMetadata_when_content_is_html_calls_parser() async throws {
        // Arrange
        let url = try XCTUnwrap(URL(string: "https://youtu.be/5qvdbyRH9wA?si=y_KTgLR22nH0-cs8"))
        let mockParser = MockOpenGraphParser()
        let subject = withDependencies {
            let response = htmlResponse(url: url)
            $0.urlSession = MockURLSession(responseData: Data(), urlResponse: response)
        } operation: {
            DefaultOpenGraphService(parser: mockParser)
        }

        // Act
        _ = try await subject.fetchMetadata(for: url)

        // Assert
        XCTAssertEqual(mockParser.metadataCallCount, 1)
    }

    func test_fetchMetadata_when_content_is_mp4_does_not_call_parser() async throws {
        // Arrange
        let url = try XCTUnwrap(URL(string: "https://example.com/rocks.mp4"))
        let mockParser = MockOpenGraphParser()
        let subject = withDependencies {
            let response = videoResponse(url: url)
            $0.urlSession = MockURLSession(responseData: Data(), urlResponse: response)
        } operation: {
            DefaultOpenGraphService(parser: mockParser)
        }

        // Act
        _ = try await subject.fetchMetadata(for: url)

        // Assert
        XCTAssertEqual(mockParser.metadataCallCount, 0)
    }
}

extension DefaultOpenGraphServiceTests {
    private func htmlResponse(url: URL) -> HTTPURLResponse {
        HTTPURLResponse(
            url: url,
            mimeType: "text/html",
            expectedContentLength: 0,
            textEncodingName: nil
        )
    }

    private func videoResponse(url: URL) -> HTTPURLResponse {
        HTTPURLResponse(
            url: url,
            mimeType: "video/mp4",
            expectedContentLength: 0,
            textEncodingName: nil
        )
    }
}

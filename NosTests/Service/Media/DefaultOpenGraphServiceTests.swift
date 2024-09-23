import XCTest

class DefaultOpenGraphServiceTests: XCTestCase {
    func test_fetchMetadata() async throws {
        // Arrange
        let url = try XCTUnwrap(URL(string: "https://youtu.be/5qvdbyRH9wA?si=y_KTgLR22nH0-cs8"))
        let subject = DefaultOpenGraphService(session: MockURLSession(), parser: MockOpenGraphParser())

        // Act
        let metadata = try await subject.fetchMetadata(for: url)

        // Assert
        XCTAssertNil(metadata)
    }
}

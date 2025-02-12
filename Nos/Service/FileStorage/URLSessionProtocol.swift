import Foundation

/// A protocol for fetching data with a `URLRequest`.
protocol URLSessionProtocol {
    func data(for request: URLRequest) async throws -> (Data, URLResponse)
}

extension URLSession: URLSessionProtocol {}

/// A mock URL session that conforms to `URLSessionProtocol` and does not send network requests.
final class MockURLSession: URLSessionProtocol {
    private let responseData: Data
    private let urlResponse: URLResponse

    private(set) var receivedRequest: URLRequest?

    init(responseData: Data = Data(), urlResponse: URLResponse = URLResponse()) {
        self.responseData = responseData
        self.urlResponse = urlResponse
    }

    func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        receivedRequest = request
        return (responseData, urlResponse)
    }
}

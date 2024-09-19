import Foundation

protocol URLSessionProtocol {
    func data(for request: URLRequest) async throws -> (Data, URLResponse)
}

extension URLSession: URLSessionProtocol {}

class MockURLSession: URLSessionProtocol {
    private let responseData: Data
    private let urlResponse: URLResponse

    init(responseData: Data = Data(), urlResponse: URLResponse = URLResponse()) {
        self.responseData = responseData
        self.urlResponse = urlResponse
    }

    func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        (responseData, urlResponse)
    }
}

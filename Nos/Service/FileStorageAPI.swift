import Foundation
import SwiftUI

protocol FileStorageAPI {
    func upload(fileAt fileURL: URL) async throws -> URL
}

class NostrBuildFileStorageAPI: FileStorageAPI {
    static let uploadURL = URL(string: "https://nostr.build/api/v2/upload/files")!
    static let paramName = "fileToUpload"

    var decoder: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return decoder
    }

    func upload(fileAt fileURL: URL) async throws -> URL {
        let fileName = fileURL.lastPathComponent
        let fileData = try Data(contentsOf: fileURL)
        
        let boundary = UUID().uuidString
        var request = URLRequest(url: Self.uploadURL)
        request.httpMethod = "POST"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        var header = ""
        header.append("\r\n--\(boundary)\r\n")
        header.append("Content-Disposition: form-data; name=\"\(Self.paramName)\"; filename=\"\(fileName)\"\r\n")
        header.append("Content-Type: image/jpg\r\n\r\n")
        
        var trailer = ""
        trailer.append("\r\n--\(boundary)--\r\n")

        guard let headerData = header.data(using: .utf8), let trailerData = trailer.data(using: .utf8) else {
            throw FileStorageAPIError.errorEncodingHeaderOrFooter
        }
        
        var data = Data()
        data.append(headerData)
        data.append(fileData)
        data.append(trailerData)
        
        let (responseData, _) = try await URLSession.shared.upload(for: request, from: data)

        do {
            let response = try decoder.decode(NostrBuildResponseJSON.self, from: responseData)
            guard let urlString = response.data?.first?.url else {
                throw FileStorageAPIError.uploadFailed(response.message ?? String(describing: response))
            }
            guard let url = URL(string: urlString) else {
                throw FileStorageAPIError.invalidResponseURL(urlString)
            }
            return url
        } catch {
            throw FileStorageAPIError.unexpectedAPIResponse(responseData)
        }
    }
}

enum FileStorageAPIError: Error {
    case invalidResponseURL(String)
    case unexpectedAPIResponse(Data)
    case uploadFailed(String)
    case errorEncodingHeaderOrFooter
    case errorEncodingImage

    var localizedDescription: String {
        switch self {
        case .invalidResponseURL(let string):
            return "invalid URL: \(string)"
        case .unexpectedAPIResponse(let data):
            return "unexpected API response:\n\(String(describing: String(data: data, encoding: .utf8)))"
        case .uploadFailed(let message):
            return "upload failed: \(message)"
        case .errorEncodingHeaderOrFooter:
            return "error encoding multipart header or footer"
        case .errorEncodingImage:
            return "error encoding the image"
        }
    }
}

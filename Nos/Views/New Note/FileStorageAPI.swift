import Foundation
import SwiftUI

protocol FileStorageAPI {
    func upload(fileAt fileURL: URL) async throws -> URL
}

class NostrBuildFileStorageAPI: FileStorageAPI {

    static let uploadURL = URL(string: "https://nostr.build/api/upload/ios.php")!
    static let paramName = "fileToUpload"
    
    func upload(fileAt fileURL: URL) async throws -> URL {
        var fileName = fileURL.lastPathComponent
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
        let urlString = try JSONSerialization.jsonObject(with: responseData, options: .allowFragments) as? String
        guard let urlString else {
            throw FileStorageAPIError.unexpectedOutputType
        }
        guard let url = URL(string: urlString) else {
            throw FileStorageAPIError.couldNotParseURL(urlString)
        }
        return url
    }
}

enum FileStorageAPIError: Error {
    case unexpectedOutputType
    case couldNotParseURL(String)
    case errorEncodingHeaderOrFooter
    case errorEncodingImage

    var localizedDescription: String {
        switch self {
        case .unexpectedOutputType:
            return "unexpected API output type"
        case .couldNotParseURL(let urlString):
            return "could not parse the string as url '\(urlString)'"
        case .errorEncodingHeaderOrFooter:
            return "error encoding multipart header or footer"
        case .errorEncodingImage:
            return "error encoding the image"
        }
    }
}

import Dependencies
import Foundation
import Logger

/// A client for a File Storage API, as defined in [NIP-96](https://github.com/nostr-protocol/nips/blob/master/96.md)
protocol FileStorageAPIClient {
    /// Uploads the file at the given URL.
    /// - Parameters:
    ///   - fileURL: The file URL to upload.
    ///   - isProfilePhoto: Indicates that the file is a profile photo.
    /// - Returns: The remote URL of the uploaded file.
    func upload(fileAt fileURL: URL, isProfilePhoto: Bool) async throws -> URL
}

enum HTTPMethod: String {
    case delete = "DELETE"
    case post = "POST"
}

/// Defines a set of errors that may be thrown from a `FileStorageAPIClient`.
enum FileStorageAPIClientError: Error {
    case decodingError
    case encodingError
    case invalidResponseURL(String)
    case invalidURLRequest
    case missingKeyPair
    case fileTooBig(String?)
    case uploadFailed(String?)
}

/// A `FileStorageAPIClient` that uses nostr.build for uploading files.
final class NostrBuildAPIClient: FileStorageAPIClient {
    /// The `URLSession` to fetch data from the API.
    @Dependency(\.urlSession) private var urlSession

    @Dependency(\.currentUser) private var currentUser

    /// The URL string used to get server info.
    private static let serverInfoURLString = "https://nostr.build/.well-known/nostr/nip96.json"

    /// Cached server info which contains the API URL for uploading files.
    var serverInfo: FileStorageServerInfoResponseJSON?

    /// The `JSONDecoder` to use for decoding responses from the API.
    private var decoder: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return decoder
    }

    // MARK: - FileStorageAPIClient protocol

    func upload(fileAt fileURL: URL, isProfilePhoto: Bool = false) async throws -> URL {
        assert(fileURL.isFileURL, "The URL must point to a file.")
        let apiURL = try await apiURL()
        let (request, data) = try uploadRequest(fileAt: fileURL, isProfilePhoto: isProfilePhoto, apiURL: apiURL)
        let (responseData, response) = try await URLSession.shared.upload(for: request, from: data)
        /// Attempt to retrieve the asset URL from the response data and HTTP response.
        return try assetURL(from: responseData, response: response as? HTTPURLResponse)
    }

    // MARK: - Internal
    
    /// The URL of the API to upload data to.
    private func apiURL() async throws -> URL {
        if serverInfo?.apiUrl == nil {
            serverInfo = try await fetchServerInfo()
        }

        guard let apiURLString = serverInfo?.apiUrl,
            let apiURL = URL(string: apiURLString) else {
            throw FileStorageAPIClientError.invalidURLRequest
        }
        
        return apiURL
    }
    
    /// The URL of the uploaded asset parsed from the API's response.
    private func assetURL(from responseData: Data, response: HTTPURLResponse?) throws -> URL {
        let decodedResponse = try decoder.decode(FileStorageUploadResponseJSON.self, from: responseData)

        guard let urlString = decodedResponse.nip94Event?.urlString else {
            // Assign an empty string if the response message is nil.
            let message = decodedResponse.message ?? ""

            // Checks if the response contains a status code of `413 Payload Too Large`.
            if let errorCode = response?.statusCode, errorCode == 413 {
                // Verify if the error message indicates the file size exceeds the limit.
                let fileSizeLimit = fileSizeLimit(from: message)
                throw FileStorageAPIClientError.fileTooBig(fileSizeLimit)
            }
            // Throw an error indicating the upload failed with the provided message.
            throw FileStorageAPIClientError.uploadFailed(message)
        }

        guard let url = URL(string: urlString) else {
            throw FileStorageAPIClientError.invalidResponseURL(urlString)
        }
        return url
    }

    /// Fetches server info from the file storage API.
    /// - Returns: the decoded JSON containing server info for the file storage API.
    func fetchServerInfo() async throws -> FileStorageServerInfoResponseJSON {
        guard let url = URL(string: Self.serverInfoURLString) else {
            throw FileStorageAPIClientError.invalidURLRequest
        }

        let urlRequest = URLRequest(url: url)
        let (responseData, _) = try await urlSession.data(for: urlRequest)
        do {
            return try decoder.decode(FileStorageServerInfoResponseJSON.self, from: responseData)
        } catch {
            throw FileStorageAPIClientError.decodingError
        }
    }
    
    /// Gets the file size limit from the error message.
    /// - Parameter message: The error message from nostr.build.
    /// - Returns: The file size limit from the error message.
    func fileSizeLimit(from message: String) -> String? {
        let pattern = /File size exceeds the limit of (\d*\.\d* [MKGT]B)/

        guard let match = message.firstMatch(of: pattern) else {
            return nil
        }
        
        return String(match.1)
    }

    /// Creates a URLRequest and Data from a file URL to be uploaded to the file storage API.
    func uploadRequest(fileAt fileURL: URL, isProfilePhoto: Bool, apiURL: URL) throws -> (URLRequest, Data) {
        assert(fileURL.isFileURL, "The URL must point to a file.")
        return try uploadRequest(
            data: try Data(contentsOf: fileURL),
            isProfilePhoto: isProfilePhoto,
            filename: fileURL.lastPathComponent,
            apiURL: apiURL
        )
    }
    
    /// Creates a URLRequest and Data to be uploaded to the file storage API.
    private func uploadRequest(
        data: Data,
        isProfilePhoto: Bool,
        filename: String,
        apiURL: URL
    ) throws -> (URLRequest, Data) {
        var request = URLRequest(url: apiURL)
        request.httpMethod = HTTPMethod.post.rawValue

        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        var header = ""
        
        if isProfilePhoto {
            header.append("\r\n--\(boundary)\r\n")
            header.append("Content-Disposition: form-data; name=\"media_type\"\r\n")
            header.append("\"avatar\"\r\n\r\n")
        }
        
        header.append("\r\n--\(boundary)\r\n")
        header.append("Content-Disposition: form-data; name=\"file\"; filename=\"\(filename)\"\r\n")
        header.append("Content-Type: image/jpg\r\n\r\n")

        var footer = ""
        footer.append("\r\n--\(boundary)--\r\n")

        guard let headerData = header.data(using: .utf8),
            let footerData = footer.data(using: .utf8) else {
            throw FileStorageAPIClientError.encodingError
        }

        guard let keyPair = currentUser.keyPair else {
            throw FileStorageAPIClientError.missingKeyPair
        }

        let wrappedData = headerData + data + footerData

        let authorizationHeader = try buildAuthorizationHeader(
            url: apiURL,
            method: .post,
            payload: wrappedData,
            keyPair: keyPair
        )
        request.setValue(authorizationHeader, forHTTPHeaderField: "Authorization")

        return (request, wrappedData)
    }

    private func buildAuthorizationHeader(
        url: URL,
        method: HTTPMethod,
        payload: Data?,
        keyPair: KeyPair
    ) throws -> String {
        var tags = [
            ["method", method.rawValue],
            ["u", url.absoluteString],
        ]
        if let payload {
            tags.append(["payload", payload.sha256().toHexString()])
        }
        var jsonEvent = JSONEvent(
            pubKey: keyPair.publicKeyHex,
            kind: .httpAuth,
            tags: tags,
            content: ""
        )
        try jsonEvent.sign(withKey: keyPair)
        let jsonObject = jsonEvent.dictionary
        let requestData = try JSONSerialization.data(withJSONObject: jsonObject)
        return "Nostr \(requestData.base64EncodedString())"
    }
}

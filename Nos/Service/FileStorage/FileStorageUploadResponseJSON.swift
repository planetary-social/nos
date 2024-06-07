import Foundation

/// The response JSON that's returned after uploading a file via the file storage API.
/// - Note: See [NIP-96](https://github.com/nostr-protocol/nips/blob/master/96.md) for more info.
struct FileStorageUploadResponseJSON: Decodable {
    let status: FileStorageUploadResponseStatus?
    let message: String?
    let nip94Event: NIP94Event?
}

enum FileStorageUploadResponseStatus: String, Decodable {
    case error
    case success
    case unknown

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let statusString = try container.decode(String.self)
        switch statusString {
        case "error":
            self = .error
        case "success":
            self = .success
        default:
            self = .unknown
        }
    }
}

struct NIP94Event: Decodable {
    let tags: [[String]]

    var urlString: String? {
        let urlTag = tags.first { $0.contains("url") }
        return urlTag?.last
    }
}

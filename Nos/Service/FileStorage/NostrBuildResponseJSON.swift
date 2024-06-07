import Foundation

/// The response JSON that's returned from the nostr.build API.
struct NostrBuildResponseJSON: Codable {
    let status: NostrBuildResponseStatus?
    let message: String?
    let data: [NostrBuildResponseDataItem]?
}

enum NostrBuildResponseStatus: String, Codable {
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

struct NostrBuildResponseDataItem: Codable {
    let url: String?
    let type: String?
    let mime: String?
    let thumbnail: String?
}

import Foundation

/// The response JSON that's returned by the file storage metadata API,
/// as defined in [NIP-96](https://github.com/nostr-protocol/nips/blob/master/96.md)
struct FileStorageMetadataResponseJSON: Codable {
    let apiUrl: String
}

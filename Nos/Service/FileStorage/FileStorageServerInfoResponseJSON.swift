import Foundation

/// The response JSON that's returned by the file storage server info API,
/// as defined in [NIP-96](https://github.com/nostr-protocol/nips/blob/master/96.md)
struct FileStorageServerInfoResponseJSON: Codable {
    let apiUrl: String
}

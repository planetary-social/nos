import Foundation

/// See https://github.com/nostr-protocol/nips/blob/master/11.md
struct JSONRelayMetadata: Codable {

    let name: String?
    let description: String?
    let supportedNIPs: [Int]?
    let pubkey: String?
    let contact: String?
    let software: String?
    let version: String?

    enum CodingKeys: String, CodingKey {
        case name
        case description
        case supportedNIPs = "supported_nips"
        case pubkey
        case contact
        case software
        case version
    }
}

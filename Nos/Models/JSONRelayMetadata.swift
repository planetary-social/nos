//
//  JSONRelayMetadata.swift
//  Nos
//
//  Created by Martin Dutra on 1/6/23.
//

import Foundation

/// See https://github.com/nostr-protocol/nips/blob/master/11.md
struct JSONRelayMetadata: Codable {

    var name: String?
    var description: String?
    var supportedNIPs: [Int]?
    var pubkey: String?
    var contact: String?
    var software: String?
    var version: String?

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

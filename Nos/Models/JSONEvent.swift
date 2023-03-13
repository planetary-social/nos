//
//  JSONEvent.swift
//  Nos
//
//  Created by Matthew Lorentz on 2/28/23.
//

import Foundation

struct JSONEvent: Codable {
    
    var id: String
    var pubKey: String
    var createdAt: Int64
    var kind: Int64
    var tags: [[String]]
    var content: String
    var signature: String
    
    enum CodingKeys: String, CodingKey {
        case id
        case pubKey = "pubkey"
        case createdAt = "created_at"
        case kind
        case tags
        case content
        case signature = "sig"
    }
    
    internal init(
        id: String,
        pubKey: String,
        createdAt: Int64,
        kind: Int64,
        tags: [[String]],
        content: String,
        signature: String
    ) {
        self.id = id
        self.pubKey = pubKey
        self.createdAt = createdAt
        self.kind = kind
        self.tags = tags
        self.content = content
        self.signature = signature
    }
    
    internal init(pubKey: String, createdAt: Int64, kind: Int64, tags: [[String]], content: String) {
        self.id = ""
        self.pubKey = pubKey
        self.createdAt = createdAt
        self.kind = kind
        self.tags = tags
        self.content = content
        self.signature = ""
    }
    
    mutating func sign(withKey privateKey: KeyPair) throws {
        id = try calculateIdentifier()
        var serializedBytes = try id.bytes
        signature = try privateKey.sign(bytes: &serializedBytes)
    }
    
    var serializedEventForSigning: [Any?] {
        [
            0,
            pubKey,
            createdAt,
            kind,
            tags,
            content
        ]
    }
    
    func calculateIdentifier() throws -> String {
        let serializedEventData = try JSONSerialization.data(
            withJSONObject: serializedEventForSigning,
            options: [.withoutEscapingSlashes]
        )
        return serializedEventData.sha256
    }
}

struct MetadataEventJSON: Codable {
    var displayName: String?
    var name: String?
    var nip05: String?
    var about: String?
    var picture: String?
    
    var profilePhotoURL: URL? {
        URL(string: picture ?? "")
    }

    private enum CodingKeys: String, CodingKey {
        case displayName = "display_name", name, nip05, about, picture
    }
    
    var dictionary: [String: String] {
        [
            "display_name": displayName ?? "",
            "name": name ?? "",
            "nip05": nip05 ?? "",
            "about": about ?? "",
            "picture": picture ?? "",
        ]
    }
    
    init (displayName: String?, name: String?, nip05: String?, about: String?, picture: String?) {
        self.displayName = displayName
        self.name = name
        self.nip05 = nip05
        self.about = about
        self.picture = picture
    }
}

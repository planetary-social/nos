import secp256k1
import Foundation
import Logger

struct JSONEvent: Codable, Hashable {
    
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
    
    internal init(
        pubKey: RawAuthorID,
        createdAt: Date = .now,
        kind: EventKind,
        tags: [[String]],
        content: String
    ) {
        self.id = ""
        self.pubKey = pubKey
        self.createdAt = Int64(createdAt.timeIntervalSince1970)
        self.kind = kind.rawValue
        self.tags = tags
        self.content = content
        self.signature = ""
    }
    
    static func from(json: String) -> JSONEvent? {
        guard let jsonData = json.data(using: .utf8) else {
            return nil
        }
        
        let decoder = JSONDecoder()
        return try? decoder.decode(JSONEvent.self, from: jsonData)
    }
    
    func toJSON() throws -> String? {
        let encoder = JSONEncoder()
        let data = try encoder.encode(self)
        return String(data: data, encoding: .utf8)
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
    
    var dictionary: [String: Any] {
        [
            "id": id,
            "pubkey": pubKey,
            "created_at": createdAt,
            "kind": kind,
            "tags": tags,
            "content": content,
            "sig": signature,
        ]
    }
    
    var createdDate: Date {
        Date(timeIntervalSince1970: TimeInterval(createdAt))
    }
    
    /// Formats this event as a string that can be sent to a relay over a websocket to publish this event.
    func buildPublishRequest() throws -> String {
        let request: [Any] = ["EVENT", dictionary]
        let requestData = try JSONSerialization.data(withJSONObject: request)
        if let string = String(data: requestData, encoding: .utf8) {
            return string
        } else {
            Log.error("Couldn't create a utf8 string for a publish request")
            return ""
        }
    }
}

struct MetadataEventJSON: Codable {
    var displayName: String?
    var name: String?
    var nip05: String?
    var uns: String?
    var about: String?
    var website: String?
    var picture: String?
    
    var profilePhotoURL: URL? {
        URL(string: picture ?? "")
    }
    
    private enum CodingKeys: String, CodingKey {
        case displayName = "display_name", name, nip05, uns = "uns_name", about, website, picture
    }
    
    var dictionary: [String: String] {
        [
            "display_name": displayName ?? "",
            "name": name ?? "",
            "nip05": nip05 ?? "",
            "uns_name": uns ?? "",
            "about": about ?? "",
            "website": website ?? "",
            "picture": picture ?? "",
        ]
    }
}

import secp256k1
import Foundation
import Logger

struct JSONEvent: Codable, Hashable, VerifiableEvent {
    
    var id: String
    var pubKey: String
    var createdAt: Int64
    var kind: Int64
    var tags: [[String]]
    var content: String
    var signature: String?
    var identifier: String? { self.id }

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

    /// Initializes a JSONEvent object for a given text and key pair.
    /// - Parameters:
    ///   - attributedText: The text the user wrote.
    ///   - noteParser: The algorithm that parses the text.
    ///   - expirationTime: The expiration time for the note, if any. Defaults to `nil`.
    ///   - replyToNote: The note that the user is replying to, if any. Defaults to `nil`.
    ///   - keyPair: Key pair of the logged in user.
    init(
        attributedText: AttributedString,
        noteParser: NoteParser,
        expirationTime: TimeInterval? = nil,
        replyToNote: Event? = nil,
        keyPair: KeyPair
    ) {
        var (content, tags) = noteParser.parse(attributedText: attributedText)

        if let expirationTime {
            tags.append(["expiration", String(Date.now.timeIntervalSince1970 + expirationTime)])
        }

        // Attach the new note to the one it is replying to, if any.
        if let replyToNote = replyToNote, let replyToNoteID = replyToNote.identifier {
            // TODO: Append ptags for all authors involved in the thread
            if let replyToAuthor = replyToNote.author?.publicKey?.hex {
                tags.append(["p", replyToAuthor])
            }

            // If `note` is a reply to another root, tag that root
            if let rootNoteIdentifier = replyToNote.rootNote()?.identifier, rootNoteIdentifier != replyToNoteID {
                tags.append(["e", rootNoteIdentifier, "", EventReferenceMarker.root.rawValue])
                tags.append(["e", replyToNoteID, "", EventReferenceMarker.reply.rawValue])
            } else {
                tags.append(["e", replyToNoteID, "", EventReferenceMarker.root.rawValue])
            }
        }

        self.init(pubKey: keyPair.publicKeyHex, kind: .text, tags: tags, content: content)
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
        return String(decoding: data, as: UTF8.self)
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
            "sig": signature ?? "",
        ]
    }
    
    var createdDate: Date {
        Date(timeIntervalSince1970: TimeInterval(createdAt))
    }

    /// The replaceable identifier, or `"d"` tag, of the event.
    var replaceableID: String? {
        for tag in tags where tag[safe: 0] == "d" {
            return tag[safe: 1]
        }
        return nil
    }

    /// Formats this event as a string that can be sent to a relay over a websocket to publish this event.
    func buildPublishRequest() throws -> String {
        let request: [Any] = ["EVENT", dictionary]
        let requestData = try JSONSerialization.data(withJSONObject: request)
        return String(decoding: requestData, as: UTF8.self) 
    }
}

struct MetadataEventJSON: Codable {
    var displayName: String?
    var name: String?
    var nip05: String?
    var about: String?
    var website: String?
    var picture: String?
    var pronouns: String?
    
    var profilePhotoURL: URL? {
        URL(string: picture ?? "")
    }
    
    private enum CodingKeys: String, CodingKey {
        case displayName = "display_name", name, nip05, about, website, picture, pronouns
    }
    
    var dictionary: [String: String] {
        [
            "display_name": displayName ?? "",
            "name": name ?? "",
            "nip05": nip05 ?? "",
            "about": about ?? "",
            "website": website ?? "",
            "picture": picture ?? "",
            "pronouns": pronouns ?? "",
        ]
    }
}

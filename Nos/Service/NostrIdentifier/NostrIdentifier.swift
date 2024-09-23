import Foundation

/// A decoding error for [NIP-19](https://github.com/nostr-protocol/nips/blob/master/19.md) identifiers.
enum NostrIdentifierError: Error {
    /// The format of the bech32-encoded entity is unknown.
    case unknownFormat

    /// The prefix of the bech32-encoded entity is unknown.
    case unknownPrefix
}

/// Represents a [NIP-19](https://github.com/nostr-protocol/nips/blob/master/19.md) bech32-encoded entity.
enum NostrIdentifier {
    /// A nostr public key
    case npub(publicKey: RawAuthorID)

    /// A nostr private key
    case nsec(privateKey: String)

    /// A nostr note
    case note(eventID: RawEventID)

    /// A nostr profile
    case nprofile(publicKey: RawAuthorID, relays: [String])

    /// A nostr event
    case nevent(eventID: RawEventID, relays: [String], eventPublicKey: String?, kind: UInt32?)

    /// A nostr replaceable event coordinate
    case naddr(replaceableID: RawReplaceableID, relays: [String], authorID: RawAuthorID, kind: UInt32)

    /// A nostr address

    /// Transforms the given bech32-encoded `String` into a `NostrIdentifier`.
    /// - Parameter bech32String: The bech32-encoded `String` to decode.
    /// - Returns: The `NostrIdentifier` that was encoded in the given `String`.
    static func decode(bech32String: String) throws -> NostrIdentifier {
        let (humanReadablePart, data) = try Bech32.decode(bech32String)
        switch humanReadablePart {
        case NostrIdentifierPrefix.publicKey:
            return try decodeNostrPublicKey(data: data)
        case NostrIdentifierPrefix.privateKey:
            return try decodeNostrPrivateKey(data: data)
        case NostrIdentifierPrefix.note:
            return try decodeNostrNote(data: data)
        case NostrIdentifierPrefix.profile:
            return try decodeNostrProfile(data: data)
        case NostrIdentifierPrefix.event:
            return try decodeNostrEvent(data: data)
        case NostrIdentifierPrefix.address:
            return try decodeNostrAddress(data: data)
        default:
            throw NostrIdentifierError.unknownPrefix
        }
    }

    /// Decodes npub data into a `NostrIdentifier.npub`.
    /// - Parameter data: The encoded npub data.
    /// - Returns: The `.npub` with the public key.
    private static func decodeNostrPublicKey(data: Data) throws -> NostrIdentifier {
        guard let publicKey = SHA256Key.decode(base5: data) else {
            throw NostrIdentifierError.unknownFormat
        }
        return .npub(publicKey: publicKey)
    }

    /// Decodes nsec data into a `NostrIdentifier.nsec`.
    /// - Parameter data: The encoded nsec data.
    /// - Returns: The `.nsec` with the private key.
    private static func decodeNostrPrivateKey(data: Data) throws -> NostrIdentifier {
        guard let privateKey = SHA256Key.decode(base5: data) else {
            throw NostrIdentifierError.unknownFormat
        }
        return .nsec(privateKey: privateKey)
    }

    /// Decodes note data into a `NostrIdentifier.note`.
    /// - Parameter data: The encoded note data.
    /// - Returns: The `.note` with the event ID.
    private static func decodeNostrNote(data: Data) throws -> NostrIdentifier {
        guard let eventID = SHA256Key.decode(base5: data) else {
            throw NostrIdentifierError.unknownFormat
        }
        return .note(eventID: eventID)
    }

    /// Decodes nprofile data into a `NostrIdentifier.nprofile`.
    /// - Parameter data: The encoded nprofile data.
    /// - Returns: The `.nprofile` with the public key and relays from the given `data`.
    private static func decodeNostrProfile(data: Data) throws -> NostrIdentifier {
        let tlvElements = TLVElement.decodeElements(data: data)

        var publicKey = ""
        var relays: [String] = []
        for element in tlvElements {
            switch element.type {
            case .special:
                publicKey = SHA256Key.decode(base8: element.value)
            case .relay:
                if let string = String(data: element.value, encoding: .ascii) {
                    relays.append(string)
                }
            default:
                break
            }
        }

        return .nprofile(publicKey: publicKey, relays: relays)
    }

    /// Decodes nevent data into a `NostrIdentifier.nevent`.
    /// - Parameter data: The encoded nevent data.
    /// - Returns: The `.nevent` with the id, relays, public key, and kind from the given `data`.
    private static func decodeNostrEvent(data: Data) throws -> NostrIdentifier {
        let tlvElements = TLVElement.decodeElements(data: data)

        var eventID = ""
        var relays: [String] = []
        var publicKey: String?
        var kind: UInt32?
        for element in tlvElements {
            switch element.type {
            case .special:
                eventID = SHA256Key.decode(base8: element.value)
            case .relay:
                if let string = String(data: element.value, encoding: .ascii) {
                    relays.append(string)
                }
            case .author:
                publicKey = SHA256Key.decode(base8: element.value)
            case .kind:
                kind = UInt32(bigEndian: element.value.withUnsafeBytes { $0.load(as: UInt32.self) })
            }
        }

        return .nevent(eventID: eventID, relays: relays, eventPublicKey: publicKey, kind: kind)
    }

    /// Decodes naddr data into a `NostrIdentifier.naddr`.
    /// - Parameter data: The encoded naddr data.
    /// - Returns: The `.naddr` with the id, relays, public key, and kind from the given `data`.
    private static func decodeNostrAddress(data: Data) throws -> NostrIdentifier {
        let tlvElements = TLVElement.decodeElements(data: data)

        var replaceableID = ""
        var relays: [String] = []
        var authorID: String = ""
        var kind = UInt32.max
        for element in tlvElements {
            switch element.type {
            case .special:
                if let string = String(data: element.value, encoding: .ascii) {
                    replaceableID = string
                }
            case .relay:
                if let valueString = String(data: element.value, encoding: .ascii) {
                    relays.append(valueString)
                }
            case .author:
                authorID = SHA256Key.decode(base8: element.value)
            case .kind:
                kind = UInt32(bigEndian: element.value.withUnsafeBytes { $0.load(as: UInt32.self) })
            }
        }

        return .naddr(replaceableID: replaceableID, relays: relays, authorID: authorID, kind: kind)
    }
}

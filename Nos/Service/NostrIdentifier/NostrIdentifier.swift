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

    /// A nostr note
    case note(eventID: RawEventID)

    /// A nostr profile
    case nprofile(publicKey: RawAuthorID, relays: [String])

    /// A nostr event
    case nevent(eventID: RawEventID, relays: [String], eventPublicKey: String?, kind: UInt32?)

    /// A nostr replaceable event coordinate
    case naddr(eventID: RawEventID, relays: [String], eventPublicKey: String, kind: UInt32)

    /// A nostr address

    /// Transforms the given bech32-encoded `String` into a `NostrIdentifier`.
    /// - Parameter bech32String: The bech32-encoded `String` to decode.
    /// - Returns: The `NostrIdentifier` that was encoded in the given `String`.
    static func decode(bech32String: String) throws -> NostrIdentifier {
        let (humanReadablePart, data) = try Bech32.decode(bech32String)
        switch humanReadablePart {
        case Nostr.publicKeyPrefix:
            return try decodeNostrPublicKey(data: data)
        case Nostr.notePrefix:
            return try decodeNostrNote(data: data)
        case Nostr.profilePrefix:
            return try decodeNostrProfile(data: data)
        case Nostr.eventPrefix:
            return try decodeNostrEvent(data: data)
        case Nostr.addressPrefix:
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

    /// Decodes npub data into a `NostrIdentifier.note`.
    /// - Parameter data: The encoded npub data.
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
            switch element {
            case .special(let value):
                publicKey = value
            case .relay(let value):
                relays.append(value)
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
            switch element {
            case .special(let value):
                eventID = value
            case .relay(let value):
                relays.append(value)
            case .author(let value):
                publicKey = value
            case .kind(let value):
                kind = value
            case .unknown:
                break
            }
        }

        return .nevent(eventID: eventID, relays: relays, eventPublicKey: publicKey, kind: kind)
    }

    /// Decodes naddr data into a `NostrIdentifier.naddr`.
    /// - Parameter data: The encoded naddr data.
    /// - Returns: The `.naddr` with the id, relays, public key, and kind from the given `data`.
    private static func decodeNostrAddress(data: Data) throws -> NostrIdentifier {
        let tlvElements = TLVElement.decodeElements(data: data)

        var eventID = ""
        var relays: [String] = []
        var publicKey: String = ""
        var kind = UInt32.max
        for element in tlvElements {
            switch element {
            case .special(let value):
                eventID = value
            case .relay(let value):
                relays.append(value)
            case .author(let value):
                publicKey = value
            case .kind(let value):
                kind = value
            case .unknown:
                break
            }
        }

        return .naddr(eventID: eventID, relays: relays, eventPublicKey: publicKey, kind: kind)
    }
}

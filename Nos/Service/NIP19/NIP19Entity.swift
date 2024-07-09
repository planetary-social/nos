import Foundation

/// A decoding error for [NIP-19](https://github.com/nostr-protocol/nips/blob/master/19.md) entities.
enum NIP19EntityError: Error {
    /// The format of the bech32-encoded entity is unknown.
    case unknownFormat

    /// The prefix of the bech32-encoded entity is unknown.
    case unknownPrefix
}

/// Represents a [NIP-19](https://github.com/nostr-protocol/nips/blob/master/19.md) bech32-encoded entity.
enum NIP19Entity {
    /// A nostr profile, which includes a public key and zero or more relays.
    case nprofile(publicKey: String, relays: [String])

    /// A nostr event
    case nevent(eventID: RawEventID, relays: [String], eventPublicKey: String?, kind: UInt32?)

    /// A nostr replaceable event coordinate
    case naddr(eventID: RawEventID, relays: [String], eventPublicKey: String, kind: UInt32)

    /// A nostr address

    /// Transforms the given bech32-encoded `String` into a `NIP19Entity`.
    /// - Parameter bech32String: The bech32-encoded `String` to decode.
    /// - Returns: The `NIP19Entity` that was encoded in the given `String`.
    static func decode(bech32String: String) throws -> NIP19Entity {
        let (humanReadablePart, data) = try Bech32.decode(bech32String)
        switch humanReadablePart {
        case Nostr.profilePrefix:
            return try decodeNostrProfile(data: data)
        case Nostr.eventPrefix:
            return try decodeNostrEvent(data: data)
        case Nostr.addressPrefix:
            return try decodeNostrAddress(data: data)
        default:
            throw NIP19EntityError.unknownPrefix
        }
    }
    
    /// Decodes nprofile data into a `NIP19Entity.nprofile`.
    /// - Parameter data: The encoded nprofile data.
    /// - Returns: The `.nprofile` entity with the public key and relays from the given `data`.
    private static func decodeNostrProfile(data: Data) throws -> NIP19Entity {
        let tlvEntities = TLVEntity.decodeEntities(data: data)

        var publicKey = ""
        var relays: [String] = []
        for entity in tlvEntities {
            switch entity {
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

    /// Decodes nevent data into a `NIP19Entity.nevent`.
    /// - Parameter data: The encoded nevent data.
    /// - Returns: The `.nevent` entity with the id, relays, public key, and kind
    ///            from the given `data`.
    private static func decodeNostrEvent(data: Data) throws -> NIP19Entity {
        let tlvEntities = TLVEntity.decodeEntities(data: data)

        var eventID = ""
        var relays: [String] = []
        var publicKey: String?
        var kind: UInt32?
        for entity in tlvEntities {
            switch entity {
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

    /// Decodes naddr data into a `NIP19Entity.naddr`.
    /// - Parameter data: The encoded naddr data.
    /// - Returns: The `.naddr` entity with the id, relays, public key, and kind
    ///            from the given `data`.
    private static func decodeNostrAddress(data: Data) throws -> NIP19Entity {
        let tlvEntities = TLVEntity.decodeEntities(data: data)

        var eventID = ""
        var relays: [String] = []
        var publicKey: String = ""
        var kind = UInt32.max
        for entity in tlvEntities {
            switch entity {
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

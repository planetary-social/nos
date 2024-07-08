import Foundation

/// A decoding error for NIP-19 entities.
enum NIP19EntityError: Error {
    /// The format of the bech32-encoded entity is unknown.
    case unknownFormat

    /// The prefix of the bech32-encoded entity is unknown.
    case unknownPrefix
}

/// Represents a NIP-19 bech32-encoded entity.
enum NIP19Entity {
    /// A nostr profile, which includes a public key and zero or more relays.
    case nprofile(publicKey: String, relays: [String])

    /// A nostr event
    case nevent // TODO: add associated values

    /// Transforms the given bech32-encoded `String` into a `NIP19Entity`.
    /// - Parameter bech32String: The bech32-encoded `String` to decode.
    /// - Returns: The `NIP19Entity` that was encoded in the given `String`.
    static func decode(bech32String: String) throws -> NIP19Entity {
        let (humanReadablePart, data) = try Bech32.decode(bech32String)
        switch humanReadablePart {
        case Nostr.profilePrefix:
            let profile = try decodeNprofile(data: data)
            return .nprofile(publicKey: profile.publicKey, relays: profile.relays)
        default:
            throw NIP19EntityError.unknownPrefix
        }
    }
    
    /// Decodes nprofile data into String values for its public key and relays.
    /// - Parameter data: The encoded nprofile data.
    /// - Returns: The public key and relays from the given `data` as `String` values.
    private static func decodeNprofile(data: Data) throws -> (publicKey: String, relays: [String]) {
        let tlvEntities = TLVEntity.decodeEntities(data: data)

        guard let publicKey = (tlvEntities.first { $0.type == .special }.map { $0.value }) else {
            throw NIP19EntityError.unknownFormat
        }
        let relays = tlvEntities.filter { $0.type == .relay }.map { $0.value }

        return (publicKey, relays)
    }
}

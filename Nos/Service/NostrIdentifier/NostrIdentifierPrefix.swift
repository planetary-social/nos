import Foundation

/// A collection of constants used in Nostr.
/// Note: See [NIP-19](https://github.com/nostr-protocol/nips/blob/master/19.md) for details.
enum NostrIdentifierPrefix {
    /// The Bech32 prefix for a private key.
    static let privateKey = "nsec"

    /// The Bech32 prefix for a public key.
    static let publicKey = "npub"

    /// The Bech32 prefix for note ID.
    static let note = "note"

    /// The Bech32 prefix for a nostr profile.
    static let profile = "nprofile"

    /// The Bech32 prefix for a nostr event.
    static let event = "nevent"

    /// The Bech32 prefix for a nostr replaceable event coordinate, or address.
    static let address = "naddr"
}

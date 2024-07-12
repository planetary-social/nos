import Foundation

/// A collection of constants used in Nostr.
/// Note: See [NIP-19](https://github.com/nostr-protocol/nips/blob/master/19.md) for details.
enum Nostr {
    /// The Bech32 prefix for a private key.
    static let privateKeyPrefix = "nsec"

    /// The Bech32 prefix for a public key.
    static let publicKeyPrefix = "npub"
    
    /// The Bech32 prefix for note ID.
    static let notePrefix = "note"

    /// The Bech32 prefix for a nostr profile.
    static let profilePrefix = "nprofile"
    
    /// The Bech32 prefix for a nostr event.
    static let eventPrefix = "nevent"
    
    /// The Bech32 prefix for a nostr replaceable event coordinate, or address.
    static let addressPrefix = "naddr"
}

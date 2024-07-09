import Foundation

/// A collection of constants used in Nostr.
enum Nostr {
    // https://github.com/nostr-protocol/nips/blob/master/19.md
    static let privateKeyPrefix = "nsec"
    static let publicKeyPrefix = "npub"
    static let notePrefix = "note"

    /// See https://github.com/nostr-protocol/nips/blob/master/19.md
    static let profilePrefix = "nprofile"
    static let eventPrefix = "nevent"
    static let addressPrefix = "naddr"
}

import Foundation

// swiftlint:disable line_length

/// A unique ID for either a Nostr user or event. In the case of a user this is their hex-encoded public key. If it's
/// an event it is the hex-encoded sha256 of the serialized event data. See [NIP-01](https://github.com/nostr-protocol/nips/blob/master/01.md)) 
/// for details.
///
/// These IDs are widely used at the protocol level, but should never be displayed to users. When displaying IDs to 
/// users they should be bech-32 formatted strings as described by [NIP-19](https://github.com/nostr-protocol/nips/blob/master/19.md)
/// 
/// For now we are modeling this as a String because it's easy and can be stored natively in Core Data but it could be 
/// refactored to be its own type.
public typealias RawNostrID = String
// swiftlint:enable line_length

/// An alias for a RawNostrID that we know is for an Event. See docs for `RawNostrID`.
public typealias RawEventID = RawNostrID

/// An alias for a RawNostrID that we know is for an Author. See docs for `RawNostrID`.
public typealias RawAuthorID = RawNostrID

extension RawNostrID {
    
    public var id: String {
        self
    }
    
    /// Verifies that this ID is the right length and is a hexadecimal string. It cannot check that this refers to a
    /// real Nostr user or event.
    var isValid: Bool {
        if count != 64 {
            return false
        }
        
        return isValidHexadecimal
    }
}

/// A replaceable ID, such as the one found in a `d` tag. Used for `naddr` events, and maybe others!
public typealias RawReplaceableID = String

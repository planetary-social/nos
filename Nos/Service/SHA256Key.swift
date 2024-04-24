import Foundation
import secp256k1

public enum SHA256Key {

    /// Decode the special part of a binary-encoded list of TLV. The meaning of the decoded value will depend on
    /// the Bech32 human readable part.
    ///
    /// - parameter base5: Base5-encoded checksum
    ///
    /// Check https://github.com/nostr-protocol/nips/blob/master/19.md for more information.
    public static func decode(base5 checksum: Data) -> String? {
        guard let converted = try? checksum.base8FromBase5() else {
            return nil
        }
        return decode(base8: converted)
    }

    /// Decode the special part of a binary-encoded list of TLV. The meaning of the decoded value will depend on
    /// the Bech32 human readable part.
    ///
    /// - parameter base8: Base8-encoded checksum
    ///
    /// Check https://github.com/nostr-protocol/nips/blob/master/19.md for more information.
    public static func decode(base8 checksum: Data) -> String {
        let underlyingKey = secp256k1.Signing.XonlyKey(dataRepresentation: checksum, keyParity: 0)
        return Data(underlyingKey.bytes).hexString
    }
}

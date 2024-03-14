import Foundation
import secp256k1

public enum TLV {

    /// Decode the special part of a binary-encoded list of TLV. The meaning of the decoded value will depend on
    /// the Bech32 human readable part.
    ///
    /// Check https://github.com/nostr-protocol/nips/blob/master/19.md for more information.
    public static func decode(checksum: Data) -> String? {
        guard let converted = try? checksum.base8FromBase5() else {
            return nil
        }
        var offset = 0
        while offset + 1 < converted.count {
            let type = converted[offset]
            let length = Int(converted[offset + 1])
            if type == 0 {
                let value = converted.subdata(in: offset + 2 ..< offset + 2 + length)
                return SHA256Key.decode(base8: value)
            }
            offset += length + 2
        }
        return nil
    }
}

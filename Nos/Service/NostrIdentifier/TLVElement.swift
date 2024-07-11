import Foundation

/// A TLV (type-length-value) element, which represents a single type, length, and value.
/// - Note: See [NIP-19](https://github.com/nostr-protocol/nips/blob/master/19.md) for more information.
enum TLVElement {
    /// The special type with its associated value as a String.
    case special(value: String)
    
    /// The relay type with its associated value as a String.
    case relay(value: String)

    /// The author type with its associated value as a String.
    case author(value: String)
    
    /// The kind type with its associated value as a UInt32.
    case kind(value: UInt32)

    /// An unknown type.
    case unknown
    
    /// Decodes the given binary-encoded list of TLV (type-length-value). The meaning of the decoded value will depend
    /// on the Bech32 human readable part. Unreadable entities are included in the array as `.unknown`.
    /// - Parameter data: The TLV data to decode.
    /// - Returns: An array containing decoded TLV entities, with `.unknown` values for any that could not be decoded.
    static func decodeElements(data: Data) -> [TLVElement] {
        guard let converted = try? data.base8FromBase5() else {
            return []
        }

        var result: [TLVElement] = []

        var offset = 0
        while offset + 1 < converted.count {
            let rawType = converted[offset]
            let type = TLVType(rawValue: rawType)
            let length = Int(converted[offset + 1])
            let value = converted.subdata(in: offset + 2 ..< offset + 2 + length)

            let element: TLVElement
            switch type {
            case .special:
                let valueString = SHA256Key.decode(base8: value)
                element = .special(value: valueString)
            case .relay:
                if let valueString = String(data: value, encoding: .ascii) {
                    element = .relay(value: valueString)
                } else {
                    element = .unknown
                }
            case .author:
                let valueString = SHA256Key.decode(base8: value)
                element = .author(value: valueString)
            case .kind:
                let valueInt = UInt32(bigEndian: value.withUnsafeBytes { $0.load(as: UInt32.self) })
                element = .kind(value: valueInt)
            case nil:
                element = .unknown
            }
            result.append(element)

            offset += length + 2
        }

        return result
    }
}

/// The type of the TLV (type-length-value) element. This type determines how the associated value is encoded.
/// - Note: See [NIP-19](https://github.com/nostr-protocol/nips/blob/master/19.md) for more information.
enum TLVType: UInt8 {
    /// The special type.
    case special = 0

    /// The relay type.
    case relay = 1

    /// The author type.
    case author = 2

    /// The kind type.
    case kind = 3
}

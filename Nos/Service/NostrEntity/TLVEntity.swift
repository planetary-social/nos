import Foundation

enum TLVEntity {
    case special(value: String)
    case relay(value: String)
    case author(value: String)
    case kind(value: UInt32)
    case unknown

    static func decodeEntities(data: Data) -> [TLVEntity] {
        guard let converted = try? data.base8FromBase5() else {
            return []
        }

        var result: [TLVEntity] = []

        var offset = 0
        while offset + 1 < converted.count {
            let rawType = converted[offset]
            let type = TLVType(rawValue: rawType)
            let length = Int(converted[offset + 1])
            let value = converted.subdata(in: offset + 2 ..< offset + 2 + length)

            let entity: TLVEntity?
            switch type {
            case .special:
                let valueString = SHA256Key.decode(base8: value)
                entity = .special(value: valueString)
            case .relay:
                if let valueString = String(data: value, encoding: .ascii) {
                    entity = .relay(value: valueString)
                } else {
                    entity = nil
                }
            case .author:
                let valueString = SHA256Key.decode(base8: value)
                entity = .author(value: valueString)
            case .kind:
                let valueInt = UInt32(bigEndian: value.withUnsafeBytes { $0.load(as: UInt32.self) })
                entity = .kind(value: valueInt)
            case nil:
                entity = .unknown
            }

            if let entity {
                result.append(entity)
            }
            offset += length + 2
        }

        return result
    }
}

enum TLVType: UInt8 {
    case special = 0
    case relay = 1
    case author = 2
    case kind = 3
}

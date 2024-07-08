import Foundation

struct TLVEntity {
    let type: TLVType
    let length: Int
    let value: String

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

            switch type {
            case .special:
                let valueString = SHA256Key.decode(base8: value)
                let entity = TLVEntity(type: .special, length: length, value: valueString)
                result.append(entity)
            case .relay:
                let valueString = String(data: value, encoding: .ascii)
                let entity = TLVEntity(type: .relay, length: length, value: valueString ?? "") // TODO: handle error
                result.append(entity)
            case .author:
                break // TODO: support author
            case .kind:
                break // TODO: support kind
            case nil:
                break // TODO: hmmm...we have an issue reading the type for this entity; this is bad
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

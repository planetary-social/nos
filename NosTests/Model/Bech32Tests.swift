import Foundation
import XCTest

final class Bech32Tests: CoreDataTestCase {

    /// Example taken from [NIP-19](https://github.com/nostr-protocol/nips/blob/master/19.md)
    func testBareKey() throws {
        let prefix = "npub"
        let npub = "npub180cvv07tjdrrgpa0j7j7tmnyl2yr6yr7l8j4s3evf6u64th6gkwsyjh6w6"
        let hex = "3bf0c63fcb93463407af97a5e5ee64fa883d107ef9e558472c4eb9aaaefa459d"
        let decoded = try Bech32.decode(npub)
        XCTAssertEqual(decoded.hrp, prefix)
        XCTAssertEqual(try decoded.checksum.base8FromBase5().hexString, hex)
    }

    /// Example taken from [NIP-19](https://github.com/nostr-protocol/nips/blob/master/19.md)
    func testShareableIdentifier() throws {
        let prefix = "nprofile"
        // swiftlint:disable:next line_length
        let nprofile = "nprofile1qqsrhuxx8l9ex335q7he0f09aej04zpazpl0ne2cgukyawd24mayt8gpp4mhxue69uhhytnc9e3k7mgpz4mhxue69uhkg6nzv9ejuumpv34kytnrdaksjlyr9p"

        let hex = "3bf0c63fcb93463407af97a5e5ee64fa883d107ef9e558472c4eb9aaaefa459d"
        let decoded = try Bech32.decode(nprofile)
        XCTAssertEqual(decoded.hrp, prefix)
        let base8data = try XCTUnwrap(try decoded.checksum.base8FromBase5())
        let offset = 0
        let length = base8data[offset + 1]
        let value = base8data.subdata(in: offset + 2 ..< offset + 2 + Int(length))
        XCTAssertEqual(value.hexString, hex)
    }

    /// Example taken from [NIP-19](https://github.com/nostr-protocol/nips/blob/master/19.md)
    @MainActor func test_nprofile() throws {
        let prefix = "nprofile"

        // swiftlint:disable:next line_length
        let nprofile = "nprofile1qqsrhuxx8l9ex335q7he0f09aej04zpazpl0ne2cgukyawd24mayt8gpp4mhxue69uhhytnc9e3k7mgpz4mhxue69uhkg6nzv9ejuumpv34kytnrdaksjlyr9p"

        let decoded = try Bech32.decode(nprofile)
        print("decoded: \(decoded)")
        XCTAssertEqual(decoded.hrp, prefix)

        let entity = try Bech32Entity.decode(bech32String: nprofile)
        switch entity {
        case .nprofile(let publicKey, let relays):
            XCTAssertEqual(publicKey, "3bf0c63fcb93463407af97a5e5ee64fa883d107ef9e558472c4eb9aaaefa459d")
            XCTAssertEqual(relays.count, 2)
            let firstRelay = try XCTUnwrap(relays.first)
            XCTAssertEqual(firstRelay, "wss://r.x.com")
            let secondRelay = try XCTUnwrap(relays.last)
            XCTAssertEqual(secondRelay, "wss://djbas.sadkb.com")
        default:
            XCTFail("Expected to get a nprofile")
        }
    }
}

enum Bech32EntityError: Error {
    case unknownFormat
    case unknownPrefix
}

enum Bech32Entity {
    case nprofile(publicKey: String, relays: [String])
    case nevent // TODO: add associated values

    static func decode(bech32String: String) throws -> Bech32Entity {
        let (humanReadablePart, data) = try Bech32.decode(bech32String)
        switch humanReadablePart {
        case "nprofile":
            let profile = try decodeNprofile(data: data)
            return .nprofile(publicKey: profile.publicKey, relays: profile.relays)
        default:
            throw Bech32EntityError.unknownPrefix
        }
    }

    private static func decodeNprofile(data: Data) throws -> (publicKey: String, relays: [String]) {
        let tlvEntities = TLVEntity.decodeEntities(data: data)

        guard let publicKey = (tlvEntities.first { $0.type == .special }.map { $0.value }) else {
            throw Bech32EntityError.unknownFormat
        }
        let relays = tlvEntities.filter { $0.type == .relay }.map { $0.value }
        
        return (publicKey, relays)
    }
}

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

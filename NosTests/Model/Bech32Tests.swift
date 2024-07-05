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

        let tlvString = try XCTUnwrap(TLV.decode(checksum: decoded.checksum))
        print("tlvString: \(tlvString)")

        let base8Data = try XCTUnwrap(try decoded.checksum.base8FromBase5())
        let offset = 0
        let type = base8Data[offset]
        print("type: \(type)")
        let length = base8Data[offset + 1]
        let value = base8Data.subdata(in: offset + 2 ..< offset + 2 + Int(length))
        print("value hex, which is the profile pubkey: \(value.hexString)")

        let pubkey = value // or tlvString
        XCTAssertEqual(pubkey.hexString, "3bf0c63fcb93463407af97a5e5ee64fa883d107ef9e558472c4eb9aaaefa459d")
        XCTAssertEqual(pubkey.hexString, tlvString)

        let nextOffset = offset + 2 + Int(length)
        let nextType = base8Data[nextOffset]
        print("nextType: \(nextType)")
        let nextLength = base8Data[nextOffset + 1]
        let nextValue = base8Data.subdata(in: nextOffset + 2 ..< nextOffset + 2 + Int(nextLength))
        print("nextValue hex: \(nextValue.hexString)")

        let firstRelay = String(data: nextValue, encoding: .ascii)
        XCTAssertEqual(firstRelay, "wss://r.x.com")

        let thirdOffset = nextOffset + 2 + Int(nextLength)
        let thirdType = base8Data[thirdOffset]
        print("thirdType: \(thirdType)")
        let thirdLength = base8Data[thirdOffset + 1]
        let thirdValue = base8Data.subdata(in: thirdOffset + 2 ..< thirdOffset + 2 + Int(thirdLength))
        print("thirdValue hex: \(thirdValue.hexString)")

        let secondRelay = String(data: thirdValue, encoding: .ascii)
        XCTAssertEqual(secondRelay, "wss://djbas.sadkb.com")
    }
}

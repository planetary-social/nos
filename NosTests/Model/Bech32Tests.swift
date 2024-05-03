import Foundation
import XCTest

final class Bech32Tests: XCTestCase {

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
        // swiftlint:disable line_length
        let nprofile = "nprofile1qqsrhuxx8l9ex335q7he0f09aej04zpazpl0ne2cgukyawd24mayt8gpp4mhxue69uhhytnc9e3k7mgpz4mhxue69uhkg6nzv9ejuumpv34kytnrdaksjlyr9p"
        // swiftlint:enable line_length
        let hex = "3bf0c63fcb93463407af97a5e5ee64fa883d107ef9e558472c4eb9aaaefa459d"
        let decoded = try Bech32.decode(nprofile)
        XCTAssertEqual(decoded.hrp, prefix)
        let base8data = try XCTUnwrap(try decoded.checksum.base8FromBase5())
        let offset = 0
        let length = base8data[offset + 1]
        let value = base8data.subdata(in: offset + 2 ..< offset + 2 + Int(length))
        XCTAssertEqual(value.hexString, hex)
    }
}

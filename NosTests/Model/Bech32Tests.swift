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
        XCTAssertEqual(decoded.hrp, prefix)

        let entity = try NIP19Entity.decode(bech32String: nprofile)
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

    // swiftlint:disable line_length
    /// Example taken from [#1231](https://github.com/planetary-social/nos/issues/1231), which points to
    /// [this note](https://njump.me/nevent1qqsqq0wah49rd6hjpezm275vys8pu6l5lcqddj9mz8cwrwf3m00k56gzyqalp33lewf5vdq847t6te0wvnags0gs0mu72kz8938tn24wlfze6a2cs3x)
    @MainActor func test_nevent() throws {
        let prefix = "nevent"

        let nevent = "nevent1qyt8wumn8ghj7un9d3shjtnddaehgu3wwp6kytcpz9mhxue69uhkummnw3ezumrpdejz7qg4waehxw309aex2mrp0yhxgctdw4eju6t09uq3wamnwvaz7tmjv4kxz7fwwpexjmtpdshxuet59uq32amnwvaz7tmwdaehgu3wdau8gu3wv3jhvtcpr4mhxue69uhkummnw3ezucnfw33k76twv4ezuum0vd5kzmp0qyv8wumn8ghj7mn0wd68ytnxd46zuamf0ghxy6t69uq3jamnwvaz7tmjv4kxz7fwwdhx7un59eek7cmfv9kz7qghwaehxw309aex2mrp0yhxummnw3ezucnpdejz7qg3waehxw309ahx7um5wgh8w6twv5hsqg9p8569xea0fgnv0zuqnt3wsk5mu9j6xal7ten6332pg9r5h8g32gl7wn5w"

        let decoded = try Bech32.decode(nevent)
        XCTAssertEqual(decoded.hrp, prefix)

        let entity = try NIP19Entity.decode(bech32String: nevent)
        switch entity {
        case .nevent(let eventID, let relays, let publicKey, let kind):
            XCTAssertEqual(eventID, "a13d345367af4a26c78b809ae2e85a9be165a377fe5e67a8c54141474b9d1152")

            XCTAssertEqual(relays.count, 10)
            let firstRelay = try XCTUnwrap(relays.first)
            XCTAssertEqual(firstRelay, "wss://relay.mostr.pub/")
            let secondRelay = try XCTUnwrap(relays.last)
            XCTAssertEqual(secondRelay, "wss://nostr.wine/")

            XCTAssertNil(publicKey)
            XCTAssertNil(kind)
        default:
            XCTFail("Expected to get a nevent")
        }
    }
    // swiftlint:enable line_length
}

import Foundation
import XCTest

final class TLVElementTests: XCTestCase {

    /// Verify that we can decode the elements of a nprofile.
    func test_decodeElements_nprofile() throws {
        // swiftlint:disable:next line_length
        let nprofile = "nprofile1qqsrhuxx8l9ex335q7he0f09aej04zpazpl0ne2cgukyawd24mayt8gpp4mhxue69uhhytnc9e3k7mgpz4mhxue69uhkg6nzv9ejuumpv34kytnrdaksjlyr9p"

        let expectedSpecial = "3bf0c63fcb93463407af97a5e5ee64fa883d107ef9e558472c4eb9aaaefa459d"
        let (_, checksum) = try Bech32.decode(nprofile)
        let elements = TLVElement.decodeElements(data: checksum)
        XCTAssertEqual(elements.count, 3)

        let special = try XCTUnwrap(elements.first { $0.type == .special })
        XCTAssertEqual(special.value.hexString, expectedSpecial)

        let relays = elements
            .filter { $0.type == .relay }
            .map { String(data: $0.value, encoding: .ascii) }
        XCTAssertEqual(
            relays,
            [
                "wss://r.x.com",
                "wss://djbas.sadkb.com"
            ]
        )
    }

    /// Verify that decoding data with the wrong encoding returns an empty array.
    func test_decodeElements_bad_data() throws {
        let string = "hello"
        let data = try XCTUnwrap(string.data(using: .utf8))
        let result = TLVElement.decodeElements(data: data)
        XCTAssertTrue(result.isEmpty)
    }
}

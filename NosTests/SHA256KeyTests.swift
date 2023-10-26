//
//  SHA256KeyTests.swift
//  NosTests
//
//  Created by Martin Dutra on 26/5/23.
//

import Foundation
import XCTest

final class SHA256Tests: XCTestCase {

    func testDecodeBase5() throws {
        let npub = "npub180cvv07tjdrrgpa0j7j7tmnyl2yr6yr7l8j4s3evf6u64th6gkwsyjh6w6"
        let expectedHex = "3bf0c63fcb93463407af97a5e5ee64fa883d107ef9e558472c4eb9aaaefa459d"
        let (_, checksum) = try Bech32.decode(npub)
        let hex = SHA256Key.decode(base5: checksum)
        XCTAssertEqual(hex, expectedHex)
    }

    func testDecodeBase8() throws {
        let npub = "npub180cvv07tjdrrgpa0j7j7tmnyl2yr6yr7l8j4s3evf6u64th6gkwsyjh6w6"
        let expectedHex = "3bf0c63fcb93463407af97a5e5ee64fa883d107ef9e558472c4eb9aaaefa459d"
        let (_, checksum) = try Bech32.decode(npub)
        let base8 = try XCTUnwrap(try checksum.base8FromBase5())
        let hex = SHA256Key.decode(base8: base8)
        XCTAssertEqual(hex, expectedHex)
    }
}

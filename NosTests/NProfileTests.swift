//
//  NProfileTests.swift
//  NosTests
//
//  Created by Martin Dutra on 27/4/23.
//

import XCTest

final class NProfileTests: XCTestCase {

    func testInitProfileFromNprofile() throws {
        // swiftlint:disable line_length
        let nprofile = "nprofile1qqsrhuxx8l9ex335q7he0f09aej04zpazpl0ne2cgukyawd24mayt8gpp4mhxue69uhhytnc9e3k7mgpz4mhxue69uhkg6nzv9ejuumpv34kytnrdaksjlyr9p"
        // swiftlint:enable line_length
        let expectedHex = "3bf0c63fcb93463407af97a5e5ee64fa883d107ef9e558472c4eb9aaaefa459d"
        let profile = try XCTUnwrap(NProfile(nprofile: nprofile))
        XCTAssertEqual(profile.publicKeyHex, expectedHex)
    }
}

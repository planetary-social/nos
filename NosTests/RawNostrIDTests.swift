//
//  RawNostrIDTests.swift
//  NosTests
//
//  Created by Matthew Lorentz on 1/24/24.
//

import XCTest

final class RawNostrIDTest: XCTestCase {

    func testHexadecimalKeyIsValid() throws {
        let testKey = RawNostrID("76c71aae3a491f1d9eec47cba17e229cda4113a0bbb6e6ae1776d7643e29cafa")
        XCTAssertEqual(testKey.isValid, true)
    }
    
    func testHexadecimalKeyWithInvalidCharactersIsNotValid() throws {
        let testKey = RawNostrID("!6c71aae3a491f1d9eec47cba17e229cda4113a0bbb6e6ae1776d7643e29cafa")
        XCTAssertEqual(testKey.isValid, false)
    }
    
    func testHexadecimalKeyTooShortIsNotValid() throws {
        let testKey = RawNostrID("6c71aae3a491f1d9eec47cba17e229cda4113a0bbb6e6ae1776d7643e29cafa")
        XCTAssertEqual(testKey.isValid, false)
    }

    func testHexadecimalKeyTooLongIsNotValid() throws {
        let testKey = RawNostrID("006c71aae3a491f1d9eec47cba17e229cda4113a0bbb6e6ae1776d7643e29cafa")
        XCTAssertEqual(testKey.isValid, false)
    }
}

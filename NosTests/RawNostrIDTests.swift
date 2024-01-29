//
//  RawNostrIDTests.swift
//  NosTests
//
//  Created by Matthew Lorentz on 1/24/24.
//

import XCTest

final class RawNostrIDTests: XCTestCase {

    func testHexadecimalKeyIsValid() throws {
        let validKey = RawNostrID("76c71aae3a491f1d9eec47cba17e229cda4113a0bbb6e6ae1776d7643e29cafa")
        XCTAssertEqual(validKey.isValid, true)
    }
    
    func testHexadecimalKeyWithInvalidCharactersIsNotValid() throws {
        let invalidCharacterKey = RawNostrID("!6c71aae3a491f1d9eec47cba17e229cda4113a0bbb6e6ae1776d7643e29cafa")
        XCTAssertEqual(invalidCharacterKey.isValid, false)
    }
    
    func testHexadecimalKeyTooShortIsNotValid() throws {
        let invalidShortKey = RawNostrID("6c71aae3a491f1d9eec47cba17e229cda4113a0bbb6e6ae1776d7643e29cafa")
        XCTAssertEqual(invalidShortKey.isValid, false)
    }

    func testHexadecimalKeyTooLongIsNotValid() throws {
        let invalidLongKey = RawNostrID("006c71aae3a491f1d9eec47cba17e229cda4113a0bbb6e6ae1776d7643e29cafa")
        XCTAssertEqual(invalidLongKey.isValid, false)
    }
}

import XCTest

class PublicKeyTests: XCTestCase {
    func test_build_with_npub() throws {
        let subject = try XCTUnwrap(PublicKey.build(npubOrHex: KeyFixture.npub))
        XCTAssertEqual(subject.hex, KeyFixture.pubKeyHex)
    }

    func test_build_with_hex() throws {
        let subject = try XCTUnwrap(PublicKey.build(npubOrHex: KeyFixture.pubKeyHex))
        XCTAssertEqual(subject.hex, KeyFixture.pubKeyHex)
    }

    func test_init_with_hex() throws {
        let subject = try XCTUnwrap(PublicKey(hex: KeyFixture.pubKeyHex))
        XCTAssertEqual(subject.hex, KeyFixture.pubKeyHex)
        XCTAssertEqual(subject.npub, KeyFixture.npub)
    }

    func test_init_with_hex_when_hex_is_invalid() throws {
        let subject = PublicKey(hex: "hi!")
        XCTAssertNil(subject)
    }

    func test_init_with_npub() throws {
        let subject = try XCTUnwrap(PublicKey(npub: KeyFixture.npub))
        XCTAssertEqual(subject.hex, KeyFixture.pubKeyHex)
        XCTAssertEqual(subject.npub, KeyFixture.npub)
    }

    func test_init_with_npub_when_npub_is_invalid() throws {
        let subject = PublicKey(npub: "hello!")
        XCTAssertNil(subject)
    }

    func test_init_with_npub_when_npub_is_actually_note() throws {
        let note = "note1q5mqsn7kvd4z6smaz328t477xatwg954y0qlletxareqwph2jnesp4vzaw"
        let subject = PublicKey(npub: note)
        XCTAssertNil(subject)
    }
}

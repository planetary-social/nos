import XCTest
import secp256k1

final class KeyPairTests: XCTestCase {

    func testInitPrivateKeyFromHex() throws {
        let keyPair = try XCTUnwrap(KeyPair(privateKeyHex: KeyFixture.privateKeyHex))
        XCTAssertEqual(keyPair.privateKeyHex, KeyFixture.privateKeyHex)
        XCTAssertEqual(keyPair.nsec, KeyFixture.nsec)
        XCTAssertEqual(keyPair.publicKeyHex, KeyFixture.pubKeyHex)
        XCTAssertEqual(keyPair.npub, KeyFixture.npub)
    }

    func testInitPrivateKeyFromNsec() throws {
        let keyPair = try XCTUnwrap(KeyPair(nsec: KeyFixture.nsec))
        XCTAssertEqual(keyPair.privateKeyHex, KeyFixture.privateKeyHex)
        XCTAssertEqual(keyPair.nsec, KeyFixture.nsec)
        XCTAssertEqual(keyPair.publicKeyHex, KeyFixture.pubKeyHex)
        XCTAssertEqual(keyPair.npub, KeyFixture.npub)
    }
}

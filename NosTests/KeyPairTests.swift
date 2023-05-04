//
//  KeyPairTests.swift
//  NosTests
//
//  Created by Matthew Lorentz on 2/7/23.
//

import XCTest
import secp256k1

final class KeyPairTests: XCTestCase {
    
    func testInitPublicKeyFromHex() throws {
        let publicKey = try XCTUnwrap(PublicKey(hex: KeyFixture.pubKeyHex))
        XCTAssertEqual(publicKey.hex, KeyFixture.pubKeyHex)
        XCTAssertEqual(publicKey.npub, KeyFixture.npub)
    }
    
    func testInitPublicKeyFromNpub() throws {
        let publicKey = try XCTUnwrap(PublicKey(npub: KeyFixture.npub))
        XCTAssertEqual(publicKey.hex, KeyFixture.pubKeyHex)
        XCTAssertEqual(publicKey.npub, KeyFixture.npub)
    }
    
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

    func testBechKeyFromNpub() throws {
        let npub = "npub10elfcs4fr0l0r8af98jlmgdh9c8tcxjvz9qkw038js35mp4dma8qzvjptg"
        let publicKey = try XCTUnwrap(PublicKey(npub: npub))
        print(publicKey.hex)
    }
}

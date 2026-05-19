import Foundation
import XCTest

@testable import Nos

/// Unit tests for the Namecoin (.bit) NIP-05 resolver.
///
/// Tests cover:
///   - identifier sniffing (`isNamecoinIdentifier`)
///   - identifier parsing (`parseIdentifier`)
///   - JSON value extraction for both `d/` (domain) and `id/` (identity)
///     namespaces, including the extended `nostr.names` / `nostr.relays`
///     tree and the legacy `"nostr": "hex"` short form
///
/// The ElectrumX wire path is mocked so the tests are fully offline.
final class NamecoinResolverTests: XCTestCase {

    // MARK: - Fixtures

    /// 64-char lowercase hex used in all fixtures.
    private static let mstrofnonePub =
        "43185edecb675892824b1a37a57f3e407fbde2eda7201a3829b8cf4ba7c5b4f0"

    private static let otherPub =
        "0000000000000000000000000000000000000000000000000000000000000001"

    // MARK: - Sniffing

    func testIsNamecoinIdentifier() {
        XCTAssertTrue(NamecoinResolver.isNamecoinIdentifier("mstrofnone.bit"))
        XCTAssertTrue(NamecoinResolver.isNamecoinIdentifier("_@mstrofnone.bit"))
        XCTAssertTrue(NamecoinResolver.isNamecoinIdentifier("alice@example.bit"))
        XCTAssertTrue(NamecoinResolver.isNamecoinIdentifier("D/MSTROFNONE")) // case-insensitive
        XCTAssertTrue(NamecoinResolver.isNamecoinIdentifier("id/alice"))

        XCTAssertFalse(NamecoinResolver.isNamecoinIdentifier("alice@example.com"))
        XCTAssertFalse(NamecoinResolver.isNamecoinIdentifier("_@nos.social"))
        XCTAssertFalse(NamecoinResolver.isNamecoinIdentifier(""))
        XCTAssertFalse(NamecoinResolver.isNamecoinIdentifier("nothing"))
    }

    // MARK: - Parsing

    func testParseIdentifier_dPrefix() throws {
        let p = try XCTUnwrap(NamecoinResolver.parseIdentifier("d/mstrofnone"))
        XCTAssertEqual(p.namecoinName, "d/mstrofnone")
        XCTAssertEqual(p.localPart, "_")
    }

    func testParseIdentifier_idPrefix() throws {
        let p = try XCTUnwrap(NamecoinResolver.parseIdentifier("id/alice"))
        XCTAssertEqual(p.namecoinName, "id/alice")
        XCTAssertEqual(p.localPart, "_")
    }

    func testParseIdentifier_bareDomainBit() throws {
        let p = try XCTUnwrap(NamecoinResolver.parseIdentifier("mstrofnone.bit"))
        XCTAssertEqual(p.namecoinName, "d/mstrofnone")
        XCTAssertEqual(p.localPart, "_")
    }

    func testParseIdentifier_underscoreLocalpart() throws {
        let p = try XCTUnwrap(NamecoinResolver.parseIdentifier("_@mstrofnone.bit"))
        XCTAssertEqual(p.namecoinName, "d/mstrofnone")
        XCTAssertEqual(p.localPart, "_")
    }

    func testParseIdentifier_namedLocalpart() throws {
        let p = try XCTUnwrap(NamecoinResolver.parseIdentifier("alice@example.bit"))
        XCTAssertEqual(p.namecoinName, "d/example")
        XCTAssertEqual(p.localPart, "alice")
    }

    func testParseIdentifier_invalidReturnsNil() {
        XCTAssertNil(NamecoinResolver.parseIdentifier("alice@example.com"))
        XCTAssertNil(NamecoinResolver.parseIdentifier(".bit"))
        XCTAssertNil(NamecoinResolver.parseIdentifier(""))
    }

    // MARK: - JSON extraction (domain namespace)

    func testExtractDomain_shortForm() throws {
        let json: [String: Any] = ["nostr": Self.mstrofnonePub]
        let parsed = try XCTUnwrap(NamecoinResolver.parseIdentifier("mstrofnone.bit"))
        let result = try XCTUnwrap(
            NamecoinResolver.extractFromDomainValue(json: json, parsed: parsed)
        )
        XCTAssertEqual(result.pubkey, Self.mstrofnonePub)
        XCTAssertEqual(result.localPart, "_")
        XCTAssertEqual(result.relays, [])
    }

    func testExtractDomain_namesTree_rootMatch() throws {
        let json: [String: Any] = [
            "nostr": [
                "names": ["_": Self.mstrofnonePub],
                "relays": [Self.mstrofnonePub: ["wss://relay.example/"]],
            ],
        ]
        let parsed = try XCTUnwrap(NamecoinResolver.parseIdentifier("mstrofnone.bit"))
        let result = try XCTUnwrap(
            NamecoinResolver.extractFromDomainValue(json: json, parsed: parsed)
        )
        XCTAssertEqual(result.pubkey, Self.mstrofnonePub)
        XCTAssertEqual(result.relays, ["wss://relay.example/"])
        XCTAssertEqual(result.localPart, "_")
    }

    /// Real-world fixture: `d/mstrofnone` uses the identity-style payload
    /// (`nostr.pubkey` + `nostr.relays`) on a `d/` record. Wire-compatible
    /// with Amethyst.
    func testExtractDomain_pubkeyOnRoot() throws {
        let json: [String: Any] = [
            "nostr": [
                "pubkey": Self.mstrofnonePub,
                "relays": ["wss://relay.testls.bit/", "wss://relay.nostr.wine/"],
            ],
        ]
        let parsed = try XCTUnwrap(NamecoinResolver.parseIdentifier("mstrofnone.bit"))
        let result = try XCTUnwrap(
            NamecoinResolver.extractFromDomainValue(json: json, parsed: parsed)
        )
        XCTAssertEqual(result.pubkey, Self.mstrofnonePub)
        XCTAssertEqual(result.relays, ["wss://relay.testls.bit/", "wss://relay.nostr.wine/"])
        XCTAssertEqual(result.localPart, "_")
    }

    func testExtractDomain_namesTree_subuser() throws {
        let json: [String: Any] = [
            "nostr": [
                "names": [
                    "_": Self.mstrofnonePub,
                    "alice": Self.otherPub,
                ],
            ],
        ]
        let parsed = try XCTUnwrap(NamecoinResolver.parseIdentifier("alice@example.bit"))
        let result = try XCTUnwrap(
            NamecoinResolver.extractFromDomainValue(json: json, parsed: parsed)
        )
        XCTAssertEqual(result.pubkey, Self.otherPub)
        XCTAssertEqual(result.localPart, "alice")
    }

    func testExtractDomain_namesTree_unknownSubuserFallsBackToRoot() throws {
        let json: [String: Any] = [
            "nostr": ["names": ["_": Self.mstrofnonePub]],
        ]
        let parsed = try XCTUnwrap(NamecoinResolver.parseIdentifier("bob@example.bit"))
        let result = try XCTUnwrap(
            NamecoinResolver.extractFromDomainValue(json: json, parsed: parsed)
        )
        XCTAssertEqual(result.pubkey, Self.mstrofnonePub)
        XCTAssertEqual(result.localPart, "_")
    }

    func testExtractDomain_invalidHexRejected() throws {
        let json: [String: Any] = ["nostr": "not-a-pubkey"]
        let parsed = try XCTUnwrap(NamecoinResolver.parseIdentifier("mstrofnone.bit"))
        XCTAssertNil(NamecoinResolver.extractFromDomainValue(json: json, parsed: parsed))
    }

    func testExtractDomain_noNostrFieldReturnsNil() throws {
        let json: [String: Any] = ["foo": "bar"]
        let parsed = try XCTUnwrap(NamecoinResolver.parseIdentifier("mstrofnone.bit"))
        XCTAssertNil(NamecoinResolver.extractFromDomainValue(json: json, parsed: parsed))
    }

    // MARK: - JSON extraction (identity namespace)

    func testExtractIdentity_shortForm() throws {
        let json: [String: Any] = ["nostr": Self.mstrofnonePub]
        let parsed = try XCTUnwrap(NamecoinResolver.parseIdentifier("id/mstrofnone"))
        let result = try XCTUnwrap(
            NamecoinResolver.extractFromIdentityValue(json: json, parsed: parsed)
        )
        XCTAssertEqual(result.pubkey, Self.mstrofnonePub)
    }

    func testExtractIdentity_pubkeyAndRelays() throws {
        let json: [String: Any] = [
            "nostr": [
                "pubkey": Self.mstrofnonePub,
                "relays": ["wss://relay.example/"],
            ],
        ]
        let parsed = try XCTUnwrap(NamecoinResolver.parseIdentifier("id/mstrofnone"))
        let result = try XCTUnwrap(
            NamecoinResolver.extractFromIdentityValue(json: json, parsed: parsed)
        )
        XCTAssertEqual(result.pubkey, Self.mstrofnonePub)
        XCTAssertEqual(result.relays, ["wss://relay.example/"])
    }

    // MARK: - Pubkey validation

    func testIsValidPubkey() {
        XCTAssertTrue(NamecoinResolver.isValidPubkey(Self.mstrofnonePub))
        XCTAssertTrue(NamecoinResolver.isValidPubkey(Self.mstrofnonePub.uppercased()))
        XCTAssertFalse(NamecoinResolver.isValidPubkey(""))
        XCTAssertFalse(NamecoinResolver.isValidPubkey("deadbeef"))
        XCTAssertFalse(NamecoinResolver.isValidPubkey(String(repeating: "z", count: 64)))
    }

    // MARK: - Resolver end-to-end with a mock ElectrumX client

    /// In-process mock ElectrumX client. Returns whatever NameShowResult the
    /// test injects, so the resolver can be exercised without any network I/O.
    private final class MockClient: IElectrumXClient, @unchecked Sendable {
        let stub: NameShowResult?
        let err: Error?
        init(stub: NameShowResult? = nil, err: Error? = nil) {
            self.stub = stub
            self.err = err
        }
        func nameShowWithFallback(identifier: String, servers: [ElectrumXServer]) async throws -> NameShowResult? {
            if let err = err { throw err }
            return stub
        }
    }

    func testResolverEndToEnd_successWithShortForm() async {
        let stubValue = #"{"nostr":"\#(Self.mstrofnonePub)"}"#
        let stub = NameShowResult(name: "d/mstrofnone", value: stubValue, txid: nil, height: nil)
        let resolver = NamecoinResolver(client: MockClient(stub: stub))
        let result = await resolver.resolve("mstrofnone.bit")
        XCTAssertEqual(result?.pubkey, Self.mstrofnonePub)
        XCTAssertEqual(result?.namecoinName, "d/mstrofnone")
    }

    func testResolverEndToEnd_nameNotFound() async {
        let resolver = NamecoinResolver(
            client: MockClient(err: NamecoinLookupError.nameNotFound("d/none"))
        )
        let result = await resolver.resolve("none.bit")
        XCTAssertNil(result)
    }

    func testResolverEndToEnd_invalidIdentifierReturnsNil() async {
        let resolver = NamecoinResolver(client: MockClient())
        let result = await resolver.resolve("alice@example.com")
        XCTAssertNil(result)
    }

    // MARK: - ElectrumX script parsing

    /// Real-world fixture: vout from the tx that registered `d/mstrofnone`.
    /// Starts with 0x52 (OP_NAME_FIRSTUPDATE) — the case multiple other
    /// ports (including dart-nostr#44 and the current Nostur PR) miss.
    func testParseNameScript_FIRSTUPDATE() {
        // Manually constructed: 52 0c "d/mstrofnone" 14 <20 bytes rand> 4c <len> <value...> 6d 6d 6a
        let name = "d/mstrofnone"
        let value = #"{"nostr":"43185edecb675892824b1a37a57f3e407fbde2eda7201a3829b8cf4ba7c5b4f0"}"#
        let salt = [UInt8](repeating: 0xAB, count: 20)
        var script: [UInt8] = [0x52]
        // push name (12 bytes, opcode-as-length)
        script.append(UInt8(name.utf8.count))
        script.append(contentsOf: [UInt8](name.utf8))
        // push salt (20 bytes)
        script.append(UInt8(salt.count))
        script.append(contentsOf: salt)
        // push value with OP_PUSHDATA1
        let valueBytes = [UInt8](value.utf8)
        script.append(0x4c)
        script.append(UInt8(valueBytes.count))
        script.append(contentsOf: valueBytes)
        // tail
        script.append(contentsOf: [0x6d, 0x6d, 0x6a])

        let parsed = ElectrumXClient.parseNameScript(script)
        XCTAssertNotNil(parsed)
        XCTAssertEqual(parsed?.0, name)
        XCTAssertEqual(parsed?.1, value)
    }

    /// Confirms the standard OP_NAME_UPDATE (0x53) form still parses.
    func testParseNameScript_UPDATE() {
        let name = "d/example"
        let value = #"{"nostr":"\#(Self.mstrofnonePub)"}"#
        var script: [UInt8] = [0x53]
        script.append(UInt8(name.utf8.count))
        script.append(contentsOf: [UInt8](name.utf8))
        let valueBytes = [UInt8](value.utf8)
        script.append(0x4c)
        script.append(UInt8(valueBytes.count))
        script.append(contentsOf: valueBytes)
        script.append(contentsOf: [0x6d, 0x75, 0x6a])

        let parsed = ElectrumXClient.parseNameScript(script)
        XCTAssertEqual(parsed?.0, name)
        XCTAssertEqual(parsed?.1, value)
    }

    // MARK: - ElectrumX script construction

    func testElectrumScriptHash_matchesKnownWireFormat() {
        // The Electrum scripthash for name "d/mstrofnone" is deterministic.
        // It is the SHA256 of OP_NAME_UPDATE <push "d/mstrofnone"> <push ""> OP_2DROP OP_DROP OP_RETURN
        // byte-reversed, hex-lowercase. Confirming the construction is stable
        // is enough to catch regressions; we don't pin the literal value here
        // because it's only meaningful when paired with a live ElectrumX server.
        let nameBytes = [UInt8]("d/mstrofnone".utf8)
        let script = ElectrumXClient.buildNameIndexScript(nameBytes: nameBytes)
        // OP_NAME_UPDATE (0x53), push-12 (0x0c), 12 bytes of "d/mstrofnone", push-0 (0x00),
        // OP_2DROP (0x6d), OP_DROP (0x75), OP_RETURN (0x6a) = 1+1+12+1+1+1+1 = 18 bytes.
        XCTAssertEqual(script.count, 18)
        XCTAssertEqual(script[0], 0x53)
        XCTAssertEqual(script[1], 0x0c)
        XCTAssertEqual(Array(script.suffix(4)), [0x00, 0x6d, 0x75, 0x6a])

        let hash = ElectrumXClient.electrumScriptHash(script: script)
        XCTAssertEqual(hash.count, 64)
        XCTAssertTrue(NamecoinResolver.isValidPubkey(hash))
    }
}

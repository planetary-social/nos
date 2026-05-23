import Foundation
import XCTest

@testable import Nos

/// Hermetic tests for `NamecoinImportResolver` and the import-aware
/// NIP-05 resolution path through `NamecoinResolver`.
///
/// Tests do NOT touch the network: every "imported" name is served by
/// an in-memory map keyed by Namecoin name.
final class NamecoinImportTests: XCTestCase {

    // MARK: - Helpers

    /// Parse a JSON literal into the dictionary shape the resolver uses.
    private func parse(_ s: String) -> [String: Any] {
        guard let data = s.data(using: .utf8),
              let obj = try? JSONSerialization.jsonObject(
                with: data, options: [.allowFragments]
              ) as? [String: Any]
        else {
            XCTFail("fixture parse failed: \(s)")
            return [:]
        }
        return obj
    }

    /// Convenience: in-memory fetcher backed by a dictionary.
    private func mapFetcher(_ records: [String: String]) -> NamecoinValueFetcher {
        let snapshot = records
        return { name in snapshot[name] }
    }

    // MARK: - Pure unit tests (NamecoinImportResolver only)

    func test_noImportKey_returnsObjectUnchanged() async {
        let obj = parse(#"{"ip":"1.2.3.4"}"#)
        let expanded = await NamecoinImportResolver.expandImports(root: obj) { _ in
            XCTFail("fetcher must not be called for non-import records")
            return nil
        }
        XCTAssertEqual(expanded["ip"] as? String, "1.2.3.4")
        XCTAssertNil(expanded["import"])
    }

    func test_stringShorthand_mergesImportedItems() async {
        // ifa-0001 §"import" canonical form is array-of-arrays, but the
        // string form `"import": "d/foo"` is widely used in practice; we
        // accept it as shorthand for `[["d/foo"]]`.
        let obj = parse(#"{"import":"d/lib","ip":"1.1.1.1"}"#)
        let expanded = await NamecoinImportResolver.expandImports(root: obj, fetcher: mapFetcher([
            "d/lib": #"{"ip":"9.9.9.9","nostr":{"names":{"_":"abc"}}}"#,
        ]))
        // importer wins on `ip`, imports fill in `nostr.names`.
        XCTAssertEqual(expanded["ip"] as? String, "1.1.1.1")
        let nostr = expanded["nostr"] as? [String: Any]
        let names = nostr?["names"] as? [String: Any]
        XCTAssertEqual(names?["_"] as? String, "abc")
        XCTAssertNil(expanded["import"], "import key must not survive expansion")
    }

    func test_arrayShorthand_singleEntry() async {
        let obj = parse(#"{"import":["d/lib"]}"#)
        let expanded = await NamecoinImportResolver.expandImports(root: obj, fetcher: mapFetcher([
            "d/lib": #"{"ip":"9.9.9.9"}"#,
        ]))
        XCTAssertEqual(expanded["ip"] as? String, "9.9.9.9")
    }

    func test_canonicalArrayOfArrays_processedInOrder() async {
        let obj = parse(#"{"import":[["d/a"],["d/b"]]}"#)
        let expanded = await NamecoinImportResolver.expandImports(root: obj, fetcher: mapFetcher([
            "d/a": #"{"ip":"10.0.0.1","tag":"from-a"}"#,
            "d/b": #"{"ip":"10.0.0.2","extra":"from-b"}"#,
        ]))
        // d/b is processed AFTER d/a, so its `ip` (10.0.0.2) overrides d/a's.
        // The importer has no `ip`, so the last imported one wins.
        XCTAssertEqual(expanded["ip"] as? String, "10.0.0.2")
        XCTAssertEqual(expanded["tag"] as? String, "from-a")
        XCTAssertEqual(expanded["extra"] as? String, "from-b")
    }

    func test_pairArrayShorthand_usesSubdomainSelector() async {
        let obj = parse(#"{"import":["d/lib","relay"]}"#)
        let expanded = await NamecoinImportResolver.expandImports(root: obj, fetcher: mapFetcher([
            "d/lib": #"{"ip":"1.1.1.1","map":{"relay":{"ip":"7.7.7.7","tag":"selected"}}}"#,
        ]))
        // We selected `map.relay` from d/lib, so its contents
        // (ip=7.7.7.7, tag=selected) are merged at the top level of the
        // importer. d/lib's top-level ip (1.1.1.1) is NOT seen because
        // we descended into the selected subtree.
        XCTAssertEqual(expanded["ip"] as? String, "7.7.7.7")
        XCTAssertEqual(expanded["tag"] as? String, "selected")
    }

    func test_importerWins_onPlainKeys() async {
        let obj = parse(#"{"import":"d/lib","ip":"1.1.1.1","extra":"local"}"#)
        let expanded = await NamecoinImportResolver.expandImports(root: obj, fetcher: mapFetcher([
            "d/lib": #"{"ip":"9.9.9.9","extra":"remote","only-imported":"yes"}"#,
        ]))
        XCTAssertEqual(expanded["ip"] as? String, "1.1.1.1")
        XCTAssertEqual(expanded["extra"] as? String, "local")
        XCTAssertEqual(expanded["only-imported"] as? String, "yes")
    }

    func test_nullInImporter_suppressesImportedValue() async {
        // ifa-0001: null is "present for precedence" — semantic
        // suppression. The importer says ip=null, so imported ip is gone.
        let obj = parse(#"{"import":"d/lib","ip":null}"#)
        let expanded = await NamecoinImportResolver.expandImports(root: obj, fetcher: mapFetcher([
            "d/lib": #"{"ip":"9.9.9.9","other":"keep"}"#,
        ]))
        // The merged object still has `ip` as NSNull, not removed.
        // Downstream parsers ignore NSNull as if absent (same outcome).
        XCTAssertNotNil(expanded["ip"])
        XCTAssertTrue(expanded["ip"] is NSNull)
        XCTAssertEqual(expanded["other"] as? String, "keep")
    }

    func test_recursionDepthFour_isSupported() async {
        // ifa-0001 mandates implementations support a recursion degree
        // of at least 4. Test pins the 4-deep happy path.
        let obj = parse(#"{"import":"d/a"}"#)
        let expanded = await NamecoinImportResolver.expandImports(root: obj, fetcher: mapFetcher([
            "d/a": #"{"import":"d/b","layer":"a"}"#,
            "d/b": #"{"import":"d/c","layer":"b"}"#,
            "d/c": #"{"import":"d/d","layer":"c"}"#,
            "d/d": #"{"layer":"d","deep":"reached"}"#,
        ]))
        // Each layer overrides "layer" so the importer sees "a".
        // "deep" only exists on d/d and survives to the top.
        XCTAssertEqual(expanded["layer"] as? String, "a")
        XCTAssertEqual(expanded["deep"] as? String, "reached")
    }

    func test_recursion_deeperThanMaxDepth_isTruncated() async {
        // Anything past the depth limit is dropped, but the importing
        // record's own items still apply.
        let obj = parse(#"{"import":"d/a","local":"keep"}"#)
        let expanded = await NamecoinImportResolver.expandImports(
            root: obj,
            maxDepth: 1,
            fetcher: mapFetcher([
                "d/a": #"{"import":"d/b","tag":"from-a"}"#,
                "d/b": #"{"tag":"from-b","leaf":"won't-show"}"#,
            ])
        )
        XCTAssertEqual(expanded["tag"] as? String, "from-a")
        XCTAssertEqual(expanded["local"] as? String, "keep")
        // d/b was never expanded so its keys are NOT present.
        XCTAssertNil(expanded["leaf"])
    }

    func test_failedImportLookup_treatedAsEmptyObject() async {
        // Per our docs: spec says a failed import MAY fail the whole
        // record; we choose the more lenient "empty object" semantics
        // so transient ElectrumX hiccups don't kill resolution.
        let obj = parse(#"{"import":"d/missing","local":"survives"}"#)
        let expanded = await NamecoinImportResolver.expandImports(root: obj) { _ in nil }
        XCTAssertEqual(expanded["local"] as? String, "survives")
        XCTAssertNil(expanded["import"])
    }

    func test_fetcherTaskCancellation_treatedAsFailure() async {
        // The Swift idiom replaces "fetcher throws" with "fetcher returns
        // nil" — exposed as the documented lenient failure contract.
        // This test simulates a fetcher that bails out (e.g. async
        // cancellation observed by the caller) by returning nil for any
        // queried name. Outcome must match the missing-name case.
        let obj = parse(#"{"import":"d/anywhere","local":"keep"}"#)
        let expanded = await NamecoinImportResolver.expandImports(root: obj) { _ in nil }
        XCTAssertEqual(expanded["local"] as? String, "keep")
    }

    func test_importTarget_malformedJson_isSkipped() async {
        let obj = parse(#"{"import":"d/broken","local":"keep"}"#)
        let expanded = await NamecoinImportResolver.expandImports(root: obj, fetcher: mapFetcher([
            "d/broken": "not valid json {{{",
        ]))
        XCTAssertEqual(expanded["local"] as? String, "keep")
    }

    func test_cycle_inImports_isBroken() async {
        // d/a imports d/b which imports d/a. A naive resolver would
        // hang. The visited-set guard breaks the loop on the second
        // appearance of d/a; importer's own items still apply.
        let obj = parse(#"{"import":"d/a","local":"top"}"#)
        let expanded = await NamecoinImportResolver.expandImports(root: obj, fetcher: mapFetcher([
            "d/a": #"{"import":"d/b","fromA":"yes"}"#,
            "d/b": #"{"import":"d/a","fromB":"yes"}"#,
        ]))
        XCTAssertEqual(expanded["local"] as? String, "top")
        // At least one of fromA/fromB should have made it through —
        // we don't pin which because the cycle-break point is an
        // implementation detail, but the call MUST terminate.
        XCTAssertTrue(expanded["fromA"] != nil || expanded["fromB"] != nil)
    }

    func test_malformedImportValue_isSkippedWithoutThrowing() async {
        let obj = parse(#"{"import":42,"local":"keep"}"#)
        let expanded = await NamecoinImportResolver.expandImports(root: obj) { _ in nil }
        XCTAssertEqual(expanded["local"] as? String, "keep")
        XCTAssertNil(expanded["import"])
    }

    func test_selector_multipleLabels_descendsInDNSOrder() async {
        // selector "a.b" means: descend map.b, then map.a (DNS-rightmost
        // first). The empty-key and "*" wildcard rules apply too.
        let obj = parse(#"{"import":[["d/lib","a.b"]]}"#)
        let expanded = await NamecoinImportResolver.expandImports(root: obj, fetcher: mapFetcher([
            "d/lib": #"{"map":{"b":{"map":{"a":{"value":"deep"}}}}}"#,
        ]))
        XCTAssertEqual(expanded["value"] as? String, "deep")
    }

    func test_selector_fallsBackToWildcardStar() async {
        let obj = parse(#"{"import":["d/lib","ghost"]}"#)
        let expanded = await NamecoinImportResolver.expandImports(root: obj, fetcher: mapFetcher([
            "d/lib": #"{"map":{"*":{"value":"wildcard"}}}"#,
        ]))
        XCTAssertEqual(expanded["value"] as? String, "wildcard")
    }

    // MARK: - Integration: NamecoinResolver follows import

    /// In-memory ElectrumX double that records the names it was queried
    /// for and returns whatever the test registered for each.
    private final class RecordingClient: IElectrumXClient, @unchecked Sendable {
        private var records: [String: String] = [:]
        private(set) var queriedNames: [String] = []

        func register(_ name: String, _ value: String) {
            records[name] = value
        }

        func nameShowWithFallback(
            identifier: String,
            servers: [ElectrumXServer]
        ) async throws -> NameShowResult? {
            queriedNames.append(identifier)
            guard let v = records[identifier] else { return nil }
            return NameShowResult(name: identifier, value: v, txid: nil, height: nil)
        }
    }

    func test_NIP05_lookupFollowsImport_forSharedNostrNamesBlock() async {
        // The real-world `testls.bit` deployment: the apex record at
        // `d/testls` is up against the 520-byte per-name limit and
        // delegates its `nostr.names` block to a sibling name via
        // `"import":"dd/testls"`. Without import support, NIP-05
        // resolution sees no `nostr` field at d/testls and fails.
        let client = RecordingClient()
        client.register(
            "d/testls",
            #"{"import":"dd/testls","ip":"107.152.38.155"}"#
        )
        client.register(
            "dd/testls",
            #"""
            {"nostr":{"names":{
                "_":"460c25e682fda7832b52d1f22d3d22b3176d972f60dcdc3212ed8c92ef85065c",
                "m":"6cdebccabda1dfa058ab85352a79509b592b2bdfa0370325e28ec1cb4f18667d"
            }}}
            """#
        )
        let resolver = NamecoinResolver(
            client: client,
            lookupTimeoutSeconds: 1,
            serverListProvider: { [] }
        )

        // Bare `.bit` resolves to root entry via the imported names block.
        let rootResult = await resolver.resolve("testls.bit")
        XCTAssertEqual(
            rootResult?.pubkey,
            "460c25e682fda7832b52d1f22d3d22b3176d972f60dcdc3212ed8c92ef85065c",
            "bare testls.bit should resolve via import"
        )

        // Named identity `m@testls.bit` resolves through the same import.
        let mResult = await resolver.resolve("m@testls.bit")
        XCTAssertEqual(
            mResult?.pubkey,
            "6cdebccabda1dfa058ab85352a79509b592b2bdfa0370325e28ec1cb4f18667d",
            "m@testls.bit should resolve via import"
        )

        // Both names must have been queried (parent + import target).
        XCTAssertTrue(client.queriedNames.contains("d/testls"))
        XCTAssertTrue(client.queriedNames.contains("dd/testls"))
    }

    func test_resolveDetailed_returnsSuccess_whenImportSuppliesNamesBlock() async {
        let client = RecordingClient()
        client.register("d/testls", #"{"import":"dd/testls"}"#)
        client.register(
            "dd/testls",
            #"""
            {"nostr":{"names":{
                "m":"6cdebccabda1dfa058ab85352a79509b592b2bdfa0370325e28ec1cb4f18667d"
            }}}
            """#
        )
        let resolver = NamecoinResolver(
            client: client,
            lookupTimeoutSeconds: 1,
            serverListProvider: { [] }
        )
        let outcome = await resolver.resolveDetailed("m@testls.bit")
        guard case .success(let result) = outcome else {
            XCTFail("expected .success, got \(outcome)")
            return
        }
        XCTAssertEqual(
            result.pubkey,
            "6cdebccabda1dfa058ab85352a79509b592b2bdfa0370325e28ec1cb4f18667d"
        )
    }

    func test_resolveDetailed_returnsNoNostrField_whenImportTargetLacksNostr() async {
        let client = RecordingClient()
        client.register("d/testls", #"{"import":"dd/testls"}"#)
        client.register("dd/testls", #"{"ip":"1.2.3.4"}"#) // no nostr field even after merge
        let resolver = NamecoinResolver(
            client: client,
            lookupTimeoutSeconds: 1,
            serverListProvider: { [] }
        )
        let outcome = await resolver.resolveDetailed("testls.bit")
        if case .noNostrField = outcome {
            // expected
        } else {
            XCTFail("expected .noNostrField, got \(outcome)")
        }
    }

    func test_recordWithoutImport_skipsImportResolverEntirely() async {
        // Pure regression guard: ensure non-import records pay zero
        // I/O cost (no extra ElectrumX queries beyond the parent).
        let client = RecordingClient()
        client.register(
            "d/plain",
            #"""
            {"nostr":{"names":{
                "_":"460c25e682fda7832b52d1f22d3d22b3176d972f60dcdc3212ed8c92ef85065c"
            }}}
            """#
        )
        let resolver = NamecoinResolver(
            client: client,
            lookupTimeoutSeconds: 1,
            serverListProvider: { [] }
        )
        let result = await resolver.resolve("plain.bit")
        XCTAssertEqual(
            result?.pubkey,
            "460c25e682fda7832b52d1f22d3d22b3176d972f60dcdc3212ed8c92ef85065c"
        )
        // Exactly one query: d/plain. No import means no extra fetches.
        XCTAssertEqual(client.queriedNames, ["d/plain"])
    }

    func test_importerWins_forNostrNames_apexOverridesNamedEntry() async {
        // Importer declares its own `nostr.names.m`; imported value
        // declares a different one. Importer wins on the whole `nostr`
        // key (shallow merge per spec).
        let client = RecordingClient()
        client.register(
            "d/testls",
            #"""
            {"import":"dd/testls",
             "nostr":{"names":{"m":"aaaa000000000000000000000000000000000000000000000000000000000001"}}}
            """#
        )
        client.register(
            "dd/testls",
            #"""
            {"nostr":{"names":{"m":"bbbb000000000000000000000000000000000000000000000000000000000002"}}}
            """#
        )
        let resolver = NamecoinResolver(
            client: client,
            lookupTimeoutSeconds: 1,
            serverListProvider: { [] }
        )
        let result = await resolver.resolve("m@testls.bit")
        XCTAssertEqual(
            result?.pubkey,
            "aaaa000000000000000000000000000000000000000000000000000000000001"
        )
    }
}

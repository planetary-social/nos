//
//  NamecoinResolver.swift
//  Nos
//
//  Parses user input, performs the ElectrumX lookup, and extracts a Nostr
//  pubkey from the Namecoin name value. Wire-compatible with Amethyst,
//  dart-nostr, and Nostur.
//
//  Ported from nostur-com/nostur-ios-public PR #60.
//

import Foundation

public final class NamecoinResolver: @unchecked Sendable {
    private let client: IElectrumXClient
    private let lookupTimeoutNs: UInt64
    private let serverListProvider: () -> [ElectrumXServer]

    public init(
        client: IElectrumXClient,
        lookupTimeoutSeconds: TimeInterval = 20,
        serverListProvider: @escaping () -> [ElectrumXServer] = { DEFAULT_ELECTRUMX_SERVERS }
    ) {
        self.client = client
        self.lookupTimeoutNs = UInt64(lookupTimeoutSeconds * 1_000_000_000)
        self.serverListProvider = serverListProvider
    }

    // MARK: - Public

    /// Return true if the identifier should be routed through Namecoin
    /// rather than the standard HTTP NIP-05 flow.
    public static func isNamecoinIdentifier(_ identifier: String) -> Bool {
        let n = identifier.trimmingCharacters(in: .whitespaces).lowercased()
        // Match user@domain.bit, domain.bit, d/foo, or id/foo.
        if n.hasSuffix(".bit") { return true }
        if n.hasPrefix("d/") || n.hasPrefix("id/") { return true }
        return false
    }

    /// Simple resolver — returns nil if anything goes wrong.
    public func resolve(_ identifier: String) async -> NamecoinNostrResult? {
        guard let parsed = Self.parseIdentifier(identifier) else { return nil }
        return await withTimeout(ns: lookupTimeoutNs) {
            do { return try await self.performLookup(parsed: parsed) } catch { return nil }
        } ?? nil
    }

    /// Detailed resolver — returns a specific outcome for UI reporting.
    public func resolveDetailed(_ identifier: String) async -> NamecoinResolveOutcome {
        guard let parsed = Self.parseIdentifier(identifier) else {
            return .invalidIdentifier(identifier)
        }
        let outcome: NamecoinResolveOutcome? = await withTimeout(ns: lookupTimeoutNs) {
            await self.performLookupDetailed(parsed: parsed)
        }
        return outcome ?? .timeout
    }

    // MARK: - Identifier parsing

    enum Namespace { case domain, identity }
    struct ParsedIdentifier {
        /// Namecoin name to query, e.g. "d/testls" or "id/alice".
        let namecoinName: String
        /// Local-part to extract; "_" for root.
        let localPart: String
        let namespace: Namespace
    }

    static func parseIdentifier(_ raw: String) -> ParsedIdentifier? {
        let input = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        let lower = input.lowercased()

        if lower.hasPrefix("d/") {
            return ParsedIdentifier(namecoinName: lower, localPart: "_", namespace: .domain)
        }
        if lower.hasPrefix("id/") {
            return ParsedIdentifier(namecoinName: lower, localPart: "_", namespace: .identity)
        }

        // user@domain.bit
        if input.contains("@"), lower.hasSuffix(".bit") {
            let parts = input.split(separator: "@", maxSplits: 1, omittingEmptySubsequences: false)
            guard parts.count == 2 else { return nil }
            let localPart: String = {
                let l = String(parts[0]).lowercased()
                return l.isEmpty ? "_" : l
            }()
            let domain = String(parts[1]).lowercased()
            guard domain.hasSuffix(".bit") else { return nil }
            let bare = String(domain.dropLast(4))
            guard !bare.isEmpty else { return nil }
            return ParsedIdentifier(namecoinName: "d/\(bare)", localPart: localPart, namespace: .domain)
        }

        // domain.bit
        if lower.hasSuffix(".bit") {
            let bare = String(lower.dropLast(4))
            guard !bare.isEmpty else { return nil }
            return ParsedIdentifier(namecoinName: "d/\(bare)", localPart: "_", namespace: .domain)
        }

        return nil
    }

    // MARK: - Lookup

    private func performLookup(parsed: ParsedIdentifier) async throws -> NamecoinNostrResult? {
        let result = try await client.nameShowWithFallback(
            identifier: parsed.namecoinName,
            servers: serverListProvider()
        )
        guard let result = result else { return nil }
        guard let json = Self.tryParseJSON(result.value) else { return nil }
        switch parsed.namespace {
        case .domain:   return Self.extractFromDomainValue(json: json, parsed: parsed)
        case .identity: return Self.extractFromIdentityValue(json: json, parsed: parsed)
        }
    }

    private func performLookupDetailed(parsed: ParsedIdentifier) async -> NamecoinResolveOutcome {
        let result: NameShowResult?
        do {
            result = try await client.nameShowWithFallback(
                identifier: parsed.namecoinName,
                servers: serverListProvider()
            )
        } catch NamecoinLookupError.nameNotFound {
            return .nameNotFound(name: parsed.namecoinName)
        } catch NamecoinLookupError.nameExpired {
            return .nameNotFound(name: parsed.namecoinName)
        } catch let NamecoinLookupError.serversUnreachable(msg) {
            return .serversUnreachable(message: msg)
        } catch {
            return .serversUnreachable(message: "\(error)")
        }

        guard let result = result else { return .nameNotFound(name: parsed.namecoinName) }
        guard let json = Self.tryParseJSON(result.value) else { return .noNostrField(name: parsed.namecoinName) }
        let nostr: NamecoinNostrResult?
        switch parsed.namespace {
        case .domain:   nostr = Self.extractFromDomainValue(json: json, parsed: parsed)
        case .identity: nostr = Self.extractFromIdentityValue(json: json, parsed: parsed)
        }
        if let nostr = nostr { return .success(nostr) }
        return .noNostrField(name: parsed.namecoinName)
    }

    // MARK: - Value extraction

    private static let hexRegex: NSRegularExpression = {
        // swiftlint:disable:next force_try
        try! NSRegularExpression(pattern: "^[0-9a-fA-F]{64}$", options: [])
    }()

    static func isValidPubkey(_ s: String) -> Bool {
        let range = NSRange(location: 0, length: s.utf16.count)
        return hexRegex.firstMatch(in: s, options: [], range: range) != nil
    }

    static func tryParseJSON(_ raw: String) -> [String: Any]? {
        guard let data = raw.data(using: .utf8),
              let obj = try? JSONSerialization.jsonObject(with: data, options: [.allowFragments]) as? [String: Any]
        else { return nil }
        return obj
    }

    static func extractFromDomainValue(json: [String: Any], parsed: ParsedIdentifier) -> NamecoinNostrResult? {
        guard let nostrField = json["nostr"] else { return nil }

        // Simple form: "nostr": "hex"
        if let hex = nostrField as? String {
            guard parsed.localPart == "_", isValidPubkey(hex) else { return nil }
            return NamecoinNostrResult(pubkey: hex.lowercased(), namecoinName: parsed.namecoinName, localPart: "_")
        }

        // Extended form: "nostr": { "names": {...}, "relays": {...} }
        guard let nostrObj = nostrField as? [String: Any] else { return nil }

        // Fallback: "nostr": { "pubkey": "hex", "relays": [...] } directly on the
        // d/ record (no `names` tree). Wire-compatible with Amethyst.
        // Only valid for the root local-part.
        if let pk = nostrObj["pubkey"] as? String,
           parsed.localPart == "_",
           isValidPubkey(pk) {
            let relays = (nostrObj["relays"] as? [String]) ?? extractRelays(nostrObj: nostrObj, pubkey: pk)
            return NamecoinNostrResult(pubkey: pk.lowercased(), relays: relays, namecoinName: parsed.namecoinName, localPart: "_")
        }

        guard let names = nostrObj["names"] as? [String: Any] else { return nil }

        var resolvedLocal: String?
        var pubkey: String?

        if let exact = names[parsed.localPart] as? String, isValidPubkey(exact) {
            resolvedLocal = parsed.localPart
            pubkey = exact
        } else if let root = names["_"] as? String, isValidPubkey(root) {
            resolvedLocal = "_"
            pubkey = root
        } else if parsed.localPart == "_",
                  let (k, v) = names.first,
                  let s = v as? String,
                  isValidPubkey(s) {
            resolvedLocal = k
            pubkey = s
        }
        guard let rl = resolvedLocal, let pk = pubkey else { return nil }
        let relays = extractRelays(nostrObj: nostrObj, pubkey: pk)
        return NamecoinNostrResult(pubkey: pk.lowercased(), relays: relays, namecoinName: parsed.namecoinName, localPart: rl)
    }

    static func extractFromIdentityValue(json: [String: Any], parsed: ParsedIdentifier) -> NamecoinNostrResult? {
        guard let nostrField = json["nostr"] else { return nil }

        if let hex = nostrField as? String, isValidPubkey(hex) {
            return NamecoinNostrResult(pubkey: hex.lowercased(), namecoinName: parsed.namecoinName)
        }

        guard let nostrObj = nostrField as? [String: Any] else { return nil }

        if let pk = nostrObj["pubkey"] as? String, isValidPubkey(pk) {
            let relays = (nostrObj["relays"] as? [String]) ?? []
            return NamecoinNostrResult(pubkey: pk.lowercased(), relays: relays, namecoinName: parsed.namecoinName)
        }

        if let names = nostrObj["names"] as? [String: Any],
           let root = names["_"] as? String,
           isValidPubkey(root) {
            let relays = extractRelays(nostrObj: nostrObj, pubkey: root)
            return NamecoinNostrResult(pubkey: root.lowercased(), relays: relays, namecoinName: parsed.namecoinName)
        }
        return nil
    }

    private static func extractRelays(nostrObj: [String: Any], pubkey: String) -> [String] {
        guard let relaysMap = nostrObj["relays"] as? [String: Any] else { return [] }
        if let arr = (relaysMap[pubkey.lowercased()] as? [String]) ?? (relaysMap[pubkey] as? [String]) {
            return arr
        }
        return []
    }
}

// MARK: - Timeout helper

/// Wrap an async operation with a timeout. Returns nil on timeout.
func withTimeout<T: Sendable>(ns: UInt64, _ op: @Sendable @escaping () async -> T?) async -> T? {
    await withTaskGroup(of: T?.self) { group in
        group.addTask {
            await op()
        }
        group.addTask {
            try? await Task.sleep(nanoseconds: ns)
            return nil
        }
        let first = await group.next()
        group.cancelAll()
        return first ?? nil
    }
}

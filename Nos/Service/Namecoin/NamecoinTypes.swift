//
//  NamecoinTypes.swift
//  Nos
//
//  Namecoin (.bit) NIP-05 resolution types.
//  Ported from nostur-com/nostur-ios-public PR #60.
//

import Foundation

/// A single ElectrumX server endpoint.
public struct ElectrumXServer: Hashable, Codable, Sendable {
    public let host: String
    public let port: Int
    public let useSsl: Bool
    /// If true, skip system TLS validation (use TOFU cert pinning).
    /// Required for ElectrumX servers that use self-signed certs,
    /// which is the norm for the Namecoin ElectrumX ecosystem.
    public let usePinnedTrustStore: Bool

    public init(host: String, port: Int, useSsl: Bool = true, usePinnedTrustStore: Bool = true) {
        self.host = host
        self.port = port
        self.useSsl = useSsl
        self.usePinnedTrustStore = usePinnedTrustStore
    }
}

/// Result of an ElectrumX `name_show`-equivalent lookup.
public struct NameShowResult: Sendable {
    public let name: String
    public let value: String
    public let txid: String?
    public let height: Int?
}

/// Successful resolution of a Namecoin name to a Nostr identity.
public struct NamecoinNostrResult: Sendable, Equatable {
    /// Hex-encoded 32-byte Schnorr public key.
    public let pubkey: String
    public let relays: [String]
    /// The Namecoin name queried, e.g. "d/testls".
    public let namecoinName: String
    /// Local-part that matched, e.g. "_" or "alice".
    public let localPart: String

    public init(pubkey: String, relays: [String] = [], namecoinName: String, localPart: String = "_") {
        self.pubkey = pubkey
        self.relays = relays
        self.namecoinName = namecoinName
        self.localPart = localPart
    }
}

/// Detailed outcome for UI-level error reporting.
public enum NamecoinResolveOutcome: Sendable {
    case success(NamecoinNostrResult)
    case nameNotFound(name: String)
    case noNostrField(name: String)
    case serversUnreachable(message: String)
    case invalidIdentifier(String)
    case timeout
}

/// Specific error types for internal signalling.
public enum NamecoinLookupError: Error, Sendable {
    case nameNotFound(String)
    case nameExpired(String)
    case serversUnreachable(String)
    case invalidResponse(String)
    case connectionFailed(String)
    case timeout
}

/// Public clearnet Namecoin ElectrumX servers.
/// Matches the wire-compatible default set used by Amethyst (Kotlin),
/// dart-nostr, and Nostur. iOS native networking means no browser-WSS
/// restrictions; bare IPs and self-signed certs are fine.
public let DEFAULT_ELECTRUMX_SERVERS: [ElectrumXServer] = [
    ElectrumXServer(host: "electrumx.testls.space", port: 50002, useSsl: true, usePinnedTrustStore: true),
    ElectrumXServer(host: "nmc2.bitcoins.sk", port: 57002, useSsl: true, usePinnedTrustStore: true),
    ElectrumXServer(host: "46.229.238.187", port: 57002, useSsl: true, usePinnedTrustStore: true),
    ElectrumXServer(host: "relay.testls.bit", port: 50002, useSsl: true, usePinnedTrustStore: true),
    ElectrumXServer(host: "23.158.233.10", port: 50002, useSsl: true, usePinnedTrustStore: true),
    ElectrumXServer(host: "electrum.nmc.ethicnology.com", port: 50002, useSsl: true, usePinnedTrustStore: false),
]

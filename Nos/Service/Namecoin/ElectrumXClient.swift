//
//  ElectrumXClient.swift
//  Nos
//
//  ElectrumX JSON-RPC client for Namecoin name resolution.
//
//  TLS is implemented with Apple's Network.framework (`NWConnection` +
//  `NWProtocolTLS.Options` + `sec_protocol_options_set_verify_block`).
//  This approach is required because SecureTransport (`SSLCreateContext`)
//  does not honour `break-on-server-auth` for self-signed certs on iOS —
//  it returns errSSLPeerUnknownCA (-9841) before the break-on-auth
//  callback fires. The native Network.framework path lets us pin certs
//  TOFU-style.
//
//  Resolution flow (wire-compatible with Amethyst, dart-nostr, Nostur):
//    1. Connect (TLS TCP, newline-delimited JSON-RPC).
//    2. `server.version` handshake.
//    3. Build canonical "name index" script for the identifier.
//    4. SHA-256 + byte-reverse → Electrum scripthash.
//    5. `blockchain.scripthash.get_history` → list of [txhash, height].
//    6. Fetch the latest tx via `blockchain.transaction.get`.
//    7. Check current block height for expiry (NAME_EXPIRE_DEPTH = 36000).
//    8. Parse name value from the tx's OP_NAME_UPDATE scriptPubKey.
//
//  Ported from nostur-com/nostur-ios-public PR #60.
//

import CryptoKit
import Foundation
import Network

public protocol IElectrumXClient: Sendable {
    /// Resolve a Namecoin name (e.g. "d/testls") by trying each server until one succeeds.
    func nameShowWithFallback(identifier: String, servers: [ElectrumXServer]) async throws -> NameShowResult?
}

public actor ElectrumXClient: IElectrumXClient {
    // MARK: - Config

    private static let PROTOCOL_VERSION = "1.4"
    /// Namecoin name expiry depth in blocks (~200 days).
    private static let NAME_EXPIRE_DEPTH = 36_000

    /// Namecoin Script opcodes.
    /// The ElectrumX name index is built from `OP_NAME_UPDATE` (used by the
    /// `name_update` tx that refreshes a name) but parsing must also accept
    /// `OP_NAME_FIRSTUPDATE`, which is the *first* tx for any newly-registered
    /// name. Skipping FIRSTUPDATE means names whose latest tx is still in
    /// their first-update window resolve to nil even when the chain has the
    /// data — a known bug in several other ports (see dart-nostr#44).
    private static let OP_NAME_FIRSTUPDATE: UInt8 = 0x52
    private static let OP_NAME_UPDATE: UInt8 = 0x53
    private static let OP_2DROP: UInt8 = 0x6d
    private static let OP_DROP: UInt8 = 0x75
    private static let OP_RETURN: UInt8 = 0x6a
    private static let OP_PUSHDATA1: UInt8 = 0x4c
    private static let OP_PUSHDATA2: UInt8 = 0x4d

    private let connectTimeout: TimeInterval = 10
    private let rpcTimeout: TimeInterval = 15

    private var requestId = 0

    public init() {}

    // MARK: - Public API

    public func nameShowWithFallback(identifier: String, servers: [ElectrumXServer]) async throws -> NameShowResult? {
        var lastError: Error?
        for server in servers {
            do {
                if let result = try await nameShow(identifier: identifier, server: server) {
                    return result
                }
            } catch NamecoinLookupError.nameNotFound(let n) {
                throw NamecoinLookupError.nameNotFound(n)
            } catch NamecoinLookupError.nameExpired(let n) {
                throw NamecoinLookupError.nameExpired(n)
            } catch {
                lastError = error
            }
        }
        throw NamecoinLookupError.serversUnreachable(
            lastError.map { "\($0)" } ?? "All ElectrumX servers unreachable"
        )
    }

    public func nameShow(identifier: String, server: ElectrumXServer) async throws -> NameShowResult? {
        let conn = try await openConnection(server: server)
        defer { conn.cancel() }

        let io = LineIO(connection: conn, rpcTimeout: rpcTimeout)

        // 1. Version handshake
        let versionReq = try buildRpcRequest(method: "server.version", params: [.string("Nos/1.0"), .string(Self.PROTOCOL_VERSION)])
        try await io.writeLine(versionReq)
        _ = try await io.readLine()

        // 2. Build scripthash for the name
        guard let nameBytes = identifier.data(using: .utf8) else {
            throw NamecoinLookupError.invalidResponse("identifier not utf-8")
        }
        let script = Self.buildNameIndexScript(nameBytes: [UInt8](nameBytes))
        let scriptHash = Self.electrumScriptHash(script: script)

        // 3. Get history for this scripthash
        let historyReq = try buildRpcRequest(method: "blockchain.scripthash.get_history", params: [.string(scriptHash)])
        try await io.writeLine(historyReq)
        guard let historyLine = try await io.readLine() else { return nil }
        guard let history = Self.parseHistoryResponse(historyLine) else {
            throw NamecoinLookupError.invalidResponse("bad history response")
        }
        guard !history.isEmpty else {
            throw NamecoinLookupError.nameNotFound(identifier)
        }

        // 4. Fetch the latest transaction
        let latest = history.last!
        let txHash = latest.txHash
        let height = latest.height

        let txReq = try buildRpcRequest(method: "blockchain.transaction.get", params: [.string(txHash), .bool(true)])
        try await io.writeLine(txReq)
        guard let txLine = try await io.readLine() else { return nil }

        // 5. Current block height for expiry check
        let hdrsReq = try buildRpcRequest(method: "blockchain.headers.subscribe", params: [])
        try await io.writeLine(hdrsReq)
        let hdrsLine = try await io.readLine()
        let currentHeight = Self.parseBlockHeight(hdrsLine)

        // 6. Check expiry
        if let currentHeight = currentHeight, height > 0 {
            let blocksSince = currentHeight - height
            if blocksSince >= Self.NAME_EXPIRE_DEPTH {
                throw NamecoinLookupError.nameExpired(identifier)
            }
        }

        // 7. Parse the name/value from the tx
        return Self.parseNameFromTransaction(identifier: identifier, txHash: txHash, height: height, raw: txLine)
    }

    // MARK: - Connection

    /// Open a TLS NWConnection, waiting for .ready or failure.
    private func openConnection(server: ElectrumXServer) async throws -> NWConnection {
        let params = Self.makeTLSParams(server: server)
        let endpoint = NWEndpoint.hostPort(host: NWEndpoint.Host(server.host), port: NWEndpoint.Port(integerLiteral: UInt16(server.port)))
        let connection = NWConnection(to: endpoint, using: params)

        try await withCheckedThrowingContinuation { (cont: CheckedContinuation<Void, Error>) in
            let finished = FinishedBox()
            connection.stateUpdateHandler = { state in
                switch state {
                case .ready:
                    if finished.set() { cont.resume() }
                case .failed(let err):
                    if finished.set() { cont.resume(throwing: NamecoinLookupError.connectionFailed("\(err)")) }
                case .cancelled:
                    if finished.set() { cont.resume(throwing: NamecoinLookupError.connectionFailed("cancelled")) }
                default:
                    break
                }
            }

            connection.start(queue: NamecoinQueues.network)

            // Connect timeout
            NamecoinQueues.network.asyncAfter(deadline: .now() + connectTimeout) {
                if finished.set() {
                    connection.cancel()
                    cont.resume(throwing: NamecoinLookupError.connectionFailed("connect timeout"))
                }
            }
        }

        return connection
    }

    // MARK: - TLS parameters (trust-all + TOFU pinning)

    private static func makeTLSParams(server: ElectrumXServer) -> NWParameters {
        let tlsOpts = NWProtocolTLS.Options()
        let secOpts = tlsOpts.securityProtocolOptions

        // Set SNI so servers with vhosts return the right cert.
        sec_protocol_options_set_tls_server_name(secOpts, server.host)

        if server.usePinnedTrustStore {
            sec_protocol_options_set_verify_block(secOpts, { _, sec_trust, complete in
                // Capture the leaf certificate's SHA-256 fingerprint for TOFU.
                let trust = sec_trust_copy_ref(sec_trust).takeRetainedValue()
                var derFingerprint: String?
                if SecTrustGetCertificateCount(trust) > 0,
                   let leaf = SecTrustCopyCertificateChain(trust) as? [SecCertificate],
                   let first = leaf.first {
                    let der = SecCertificateCopyData(first) as Data
                    derFingerprint = NamecoinCertPinning.fingerprint(der: der)
                }

                // TOFU logic: if we have a pinned fp, must match. Else, pin.
                if let fp = derFingerprint {
                    if let pinned = NamecoinCertPinning.pinned(for: server) {
                        if pinned == fp {
                            complete(true)
                        } else {
                            complete(false)
                        }
                    } else {
                        NamecoinCertPinning.pinIfMissing(server: server, fingerprint: fp)
                        complete(true)
                    }
                } else {
                    complete(false)
                }
            }, NamecoinQueues.network)
        }

        let tcpOpts = NWProtocolTCP.Options()
        tcpOpts.connectionTimeout = 10
        let params = NWParameters(tls: tlsOpts, tcp: tcpOpts)
        return params
    }

    // MARK: - JSON-RPC encoding

    private enum RpcParam {
        case string(String)
        case int(Int)
        case bool(Bool)
    }

    private func buildRpcRequest(method: String, params: [RpcParam]) throws -> String {
        requestId += 1
        var obj: [String: Any] = [
            "jsonrpc": "2.0",
            "id": requestId,
            "method": method,
        ]
        obj["params"] = params.map { param -> Any in
            switch param {
            case .string(let s): return s
            case .int(let i): return i
            case .bool(let b): return b
            }
        }
        let data = try JSONSerialization.data(withJSONObject: obj, options: [])
        guard let s = String(data: data, encoding: .utf8) else {
            throw NamecoinLookupError.invalidResponse("json encoding")
        }
        return s
    }

    // MARK: - Response parsing

    struct HistoryEntry {
        let txHash: String
        let height: Int
    }

    static func parseHistoryResponse(_ raw: String) -> [HistoryEntry]? {
        guard let data = raw.data(using: .utf8),
              let envelope = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
        else { return nil }
        if let err = envelope["error"], !(err is NSNull) { return nil }
        guard let result = envelope["result"] as? [[String: Any]] else { return nil }
        return result.compactMap { entry -> HistoryEntry? in
            guard let txHash = entry["tx_hash"] as? String,
                  let height = entry["height"] as? Int else { return nil }
            return HistoryEntry(txHash: txHash, height: height)
        }
    }

    static func parseBlockHeight(_ raw: String?) -> Int? {
        guard let raw = raw,
              let data = raw.data(using: .utf8),
              let envelope = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let result = envelope["result"] as? [String: Any],
              let h = result["height"] as? Int
        else { return nil }
        return h
    }

    static func parseNameFromTransaction(identifier: String, txHash: String, height: Int, raw: String) -> NameShowResult? {
        guard let data = raw.data(using: .utf8),
              let envelope = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
        else { return nil }
        if let err = envelope["error"], !(err is NSNull) { return nil }
        guard let result = envelope["result"] as? [String: Any],
              let vouts = result["vout"] as? [[String: Any]]
        else { return nil }
        for vout in vouts {
            guard let spk = vout["scriptPubKey"] as? [String: Any],
                  let hex = spk["hex"] as? String else { continue }
            // Accept both OP_NAME_UPDATE (0x53) and OP_NAME_FIRSTUPDATE (0x52).
            // FIRSTUPDATE is the first tx for any newly-registered name; if we
            // only matched 0x53 we'd miss names still in their first-update window.
            if !(hex.hasPrefix("53") || hex.hasPrefix("52")) { continue }
            guard let bytes = hexToBytes(hex) else { continue }
            guard let (name, value) = parseNameScript(bytes) else { continue }
            if name == identifier {
                return NameShowResult(name: name, value: value, txid: txHash, height: height)
            }
        }
        return nil
    }

    // MARK: - Script construction

    /// Build the canonical script used by ElectrumX to index Namecoin names:
    ///   OP_NAME_UPDATE <push(name)> <push(empty)> OP_2DROP OP_DROP OP_RETURN
    static func buildNameIndexScript(nameBytes: [UInt8]) -> [UInt8] {
        var out: [UInt8] = []
        out.append(OP_NAME_UPDATE)
        out.append(contentsOf: pushData(nameBytes))
        out.append(contentsOf: pushData([]))
        out.append(OP_2DROP)
        out.append(OP_DROP)
        out.append(OP_RETURN)
        return out
    }

    private static func pushData(_ data: [UInt8]) -> [UInt8] {
        let len = data.count
        if len < 0x4c {
            return [UInt8(len)] + data
        } else if len <= 0xff {
            return [OP_PUSHDATA1, UInt8(len)] + data
        } else {
            let lo = UInt8(len & 0xff)
            let hi = UInt8((len >> 8) & 0xff)
            return [OP_PUSHDATA2, lo, hi] + data
        }
    }

    /// Electrum scripthash: SHA-256 of the script, byte-reversed, as hex.
    static func electrumScriptHash(script: [UInt8]) -> String {
        let digest = SHA256.hash(data: Data(script))
        let reversed = Array(digest.reversed())
        return reversed.map { String(format: "%02x", $0) }.joined()
    }

    // MARK: - Script parsing

    static func parseNameScript(_ script: [UInt8]) -> (String, String)? {
        guard !script.isEmpty else { return nil }
        let head = script[0]
        if head == OP_NAME_UPDATE {
            // <NAME_UPDATE> <push name> <push value> OP_2DROP OP_DROP OP_RETURN
            var pos = 1
            guard let (nameBytes, p1) = readPushData(script, pos: pos) else { return nil }
            pos = p1
            guard let (valueBytes, _) = readPushData(script, pos: pos) else { return nil }
            guard let name = String(bytes: nameBytes, encoding: .utf8),
                  let value = String(bytes: valueBytes, encoding: .utf8) else { return nil }
            return (name, value)
        }
        if head == OP_NAME_FIRSTUPDATE {
            // <NAME_FIRSTUPDATE> <push name> <push rand> <push value> OP_2DROP OP_2DROP OP_RETURN
            var pos = 1
            guard let (nameBytes, p1) = readPushData(script, pos: pos) else { return nil }
            pos = p1
            // Skip the random salt push.
            guard let (_, p2) = readPushData(script, pos: pos) else { return nil }
            pos = p2
            guard let (valueBytes, _) = readPushData(script, pos: pos) else { return nil }
            guard let name = String(bytes: nameBytes, encoding: .utf8),
                  let value = String(bytes: valueBytes, encoding: .utf8) else { return nil }
            return (name, value)
        }
        return nil
    }

    private static func readPushData(_ script: [UInt8], pos: Int) -> ([UInt8], Int)? {
        guard pos < script.count else { return nil }
        let opcode = Int(script[pos])
        switch opcode {
        case 0:
            return ([], pos + 1)
        case 0x01..<0x4c:
            let end = pos + 1 + opcode
            guard end <= script.count else { return nil }
            return (Array(script[(pos + 1)..<end]), end)
        case 0x4c:
            guard pos + 2 <= script.count else { return nil }
            let len = Int(script[pos + 1])
            let end = pos + 2 + len
            guard end <= script.count else { return nil }
            return (Array(script[(pos + 2)..<end]), end)
        case 0x4d:
            guard pos + 3 <= script.count else { return nil }
            let len = Int(script[pos + 1]) | (Int(script[pos + 2]) << 8)
            let end = pos + 3 + len
            guard end <= script.count else { return nil }
            return (Array(script[(pos + 3)..<end]), end)
        default:
            return nil
        }
    }

    static func hexToBytes(_ hex: String) -> [UInt8]? {
        let chars = Array(hex)
        guard chars.count % 2 == 0 else { return nil }
        var out: [UInt8] = []
        out.reserveCapacity(chars.count / 2)
        var i = 0
        while i < chars.count {
            guard let hi = hexVal(chars[i]), let lo = hexVal(chars[i + 1]) else { return nil }
            out.append(UInt8((hi << 4) | lo))
            i += 2
        }
        return out
    }

    private static func hexVal(_ c: Character) -> Int? {
        switch c {
        case "0"..."9": return Int(c.asciiValue! - 48)
        case "a"..."f": return Int(c.asciiValue! - 87)
        case "A"..."F": return Int(c.asciiValue! - 55)
        default: return nil
        }
    }
}

// MARK: - Helpers

/// Serial queue for all Namecoin Network.framework I/O.
enum NamecoinQueues {
    static let network = DispatchQueue(label: "nos.namecoin.network", qos: .userInitiated)
}

/// One-shot "finished" flag safe for concurrent callbacks.
final class FinishedBox: @unchecked Sendable {
    private let lock = NSLock()
    private var done = false
    /// Returns true if *this* call set the flag.
    func set() -> Bool {
        lock.lock()
        defer { lock.unlock() }
        if done { return false }
        done = true
        return true
    }
}

/// Line-buffered async I/O wrapper around NWConnection.
/// Not thread-safe; call sequentially from a single actor.
final class LineIO: @unchecked Sendable {
    private let connection: NWConnection
    private let rpcTimeout: TimeInterval
    private var buffer = Data()

    init(connection: NWConnection, rpcTimeout: TimeInterval) {
        self.connection = connection
        self.rpcTimeout = rpcTimeout
    }

    func writeLine(_ line: String) async throws {
        let payload = (line + "\n").data(using: .utf8) ?? Data()
        try await withCheckedThrowingContinuation { (cont: CheckedContinuation<Void, Error>) in
            let finished = FinishedBox()
            connection.send(content: payload, completion: .contentProcessed { err in
                if let err = err {
                    if finished.set() { cont.resume(throwing: NamecoinLookupError.connectionFailed("send: \(err)")) }
                } else {
                    if finished.set() { cont.resume() }
                }
            })
        }
    }

    /// Reads one newline-terminated frame, or nil on clean EOF.
    func readLine() async throws -> String? {
        // Try to serve from buffer first.
        if let line = popLine() { return line }

        let deadline = Date().addingTimeInterval(rpcTimeout)
        while Date() < deadline {
            let chunk = try await receiveChunk()
            if chunk.isEmpty {
                // EOF — flush whatever is left as a final "line".
                if !buffer.isEmpty {
                    let s = String(data: buffer, encoding: .utf8)
                    buffer.removeAll()
                    return s
                }
                return nil
            }
            buffer.append(chunk)
            if let line = popLine() { return line }
        }
        throw NamecoinLookupError.timeout
    }

    private func popLine() -> String? {
        guard let idx = buffer.firstIndex(of: 0x0a) else { return nil }
        let lineData = buffer.prefix(upTo: idx)
        buffer.removeSubrange(0...idx)
        return String(data: lineData, encoding: .utf8)
    }

    private func receiveChunk() async throws -> Data {
        try await withCheckedThrowingContinuation { (cont: CheckedContinuation<Data, Error>) in
            let finished = FinishedBox()
            connection.receive(minimumIncompleteLength: 1, maximumLength: 8192) { data, _, isComplete, err in
                if let err = err {
                    if finished.set() { cont.resume(throwing: NamecoinLookupError.connectionFailed("recv: \(err)")) }
                    return
                }
                if let data = data, !data.isEmpty {
                    if finished.set() { cont.resume(returning: data) }
                    return
                }
                if isComplete {
                    if finished.set() { cont.resume(returning: Data()) }
                    return
                }
                if finished.set() { cont.resume(returning: Data()) }
            }
        }
    }
}

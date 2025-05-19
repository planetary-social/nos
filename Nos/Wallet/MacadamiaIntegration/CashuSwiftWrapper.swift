import Foundation
import NostrSDKWrapper

// This is a wrapper to handle CashuSwift functionality without directly importing the library
// We'll use our NostrSDKWrapper module which provides implementations that don't have 
// dependency conflicts with secp256k1

/// Wrapper for CashuSwift functionality that takes care of dependency conflicts
enum CashuSwiftWrapper {
    
    /// Check if CashuSwift is available
    static func isCashuSwiftAvailable() -> Bool {
        // We're now using our wrapper implementation, so we'll always return true
        return true
    }
    
    /// Calls parseToken function via our wrapper
    /// - Parameter token: The token string to parse
    /// - Returns: A dictionary containing the parsed token data
    static func parseToken(_ token: String) -> [String: Any]? {
        return CashuSupport.parseToken(token)
    }
    
    /// Initializes a mint connection
    /// - Parameter url: The URL of the mint
    /// - Returns: A dictionary containing mint information
    static func initializeMint(with url: URL) async throws -> [String: Any] {
        let mint = try await CashuSupport.initializeMint(with: url)
        
        return [
            "url": mint.url.absoluteString,
            "name": mint.name,
            "description": "Mint at \(mint.url.absoluteString)",
            "keysets": mint.keysets
        ]
    }
    
    /// Restore proofs from a mint using the seed
    static func restore(mint url: URL, with seed: String) async throws -> [CashuSupport.RestoreResult] {
        return try await CashuSupport.restore(mint: url, with: seed)
    }
    
    /// Send tokens to another wallet
    static func send(amount: Int, proofs: [CashuSupport.Proof], mint: URL) async throws -> String {
        return try await CashuSupport.send(amount: amount, proofs: proofs, mint: mint)
    }
    
    /// Receive tokens from a token string
    static func receive(token: String, mint: URL) async throws -> [CashuSupport.Proof] {
        return try await CashuSupport.receive(token: token, mint: mint)
    }
    
    /// Mint tokens by paying a Lightning invoice
    static func mint(amount: Int, mint: URL) async throws -> [CashuSupport.Proof] {
        return try await CashuSupport.mint(amount: amount, mint: mint)
    }
    
    /// Pay a Lightning invoice with tokens
    static func melt(invoice: String, proofs: [CashuSupport.Proof], mint: URL) async throws -> [CashuSupport.Proof] {
        return try await CashuSupport.melt(invoice: invoice, proofs: proofs, mint: mint)
    }
}
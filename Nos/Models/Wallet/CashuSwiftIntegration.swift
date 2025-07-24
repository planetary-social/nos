// ABOUTME: Bridge between CashuSwift library types and Nos wallet implementation
// ABOUTME: Provides type conversions and real Cashu protocol operations

import Foundation
import CashuSwift

/// Extension to integrate real CashuSwift functionality into CashuWallet
extension CashuWallet {
    
    /// Initializes the CashuSwift wallet instance with the provided configuration
    func initializeCashuSwiftWallet() async throws {
        guard let url = URL(string: mintURL) else {
            throw CashuSwiftError.networkError("Invalid mint URL: \(mintURL)")
        }
        
        // Load mint information
        let mint = try await CashuSwift.loadMint(url: url)
        
        // Store mint reference (would need to add this property to CashuWallet)
        // self.cashuMint = mint
        
        // Initialize with wallet's seed phrase (derived from private key)
        // This ensures deterministic key generation
    }
    
    /// Mints new tokens from a Lightning invoice
    func mintTokens(amount: Int) async throws -> [Token] {
        guard let url = URL(string: mintURL) else {
            throw CashuSwiftError.networkError("Invalid mint URL")
        }
        
        let mint = try await CashuSwift.loadMint(url: url)
        
        // Request mint quote
        let mintQuoteRequest = CashuSwift.Bolt11.RequestMintQuote(unit: "sat", amount: amount)
        let quote = try await CashuSwift.getQuote(mint: mint, quoteRequest: mintQuoteRequest)
        
        // In production, would pay the Lightning invoice here
        // For now, assume payment is handled externally
        
        // Mint tokens after payment
        let (proofs, validDLEQ) = try await CashuSwift.issue(
            for: quote,
            with: mint,
            seed: walletPrivateKey // Use wallet's private key as seed for deterministic generation
        )
        
        guard validDLEQ else {
            throw CashuSwiftError.invalidProof
        }
        
        // Convert proofs to tokens
        return [Token(mint: mint, proofs: proofs)]
    }
    
    /// Melts tokens back to Lightning
    func meltTokens(tokens: [Token], lightningInvoice: String) async throws -> String {
        guard !tokens.isEmpty else {
            throw CashuSwiftError.insufficientBalance
        }
        
        guard let firstToken = tokens.first,
              let url = URL(string: mintURL) else {
            throw CashuSwiftError.networkError("Invalid configuration")
        }
        
        let mint = try await CashuSwift.loadMint(url: url)
        
        // Extract proofs from tokens
        let proofs = tokens.flatMap { $0.proofs }
        
        // Request melt quote
        let meltQuoteRequest = CashuSwift.Bolt11.RequestMeltQuote(
            unit: "sat",
            request: lightningInvoice
        )
        let meltQuote = try await CashuSwift.getMeltQuote(mint: mint, quoteRequest: meltQuoteRequest)
        
        // Melt tokens
        let (paid, change, dleqValid) = try await CashuSwift.melt(
            with: meltQuote,
            mint: mint,
            proofs: proofs
        )
        
        guard dleqValid else {
            throw CashuSwiftError.invalidProof
        }
        
        // Return payment preimage if successful
        return paid ? meltQuote.quote : ""
    }
    
    /// Creates P2PK-locked tokens for a nutzap
    func createP2PKLockedTokens(amount: Int, recipientPubkey: String) async throws -> [Token] {
        guard let url = URL(string: mintURL) else {
            throw CashuSwiftError.networkError("Invalid mint URL")
        }
        
        let mint = try await CashuSwift.loadMint(url: url)
        
        // Get available tokens/proofs from wallet
        // For now, assume we have proofs available
        // In production, would fetch from storage
        let availableProofs: [Proof] = [] // TODO: Get from wallet storage
        
        // Ensure recipient pubkey is in correct format (remove "02" prefix if present)
        let cleanPubkey = recipientPubkey.hasPrefix("02") ? String(recipientPubkey.dropFirst(2)) : recipientPubkey
        
        // Create P2PK locked tokens
        let (lockedToken, change, dleqValid) = try await CashuSwift.send(
            inputs: availableProofs,
            mint: mint,
            amount: amount,
            lockToPublicKey: cleanPubkey
        )
        
        guard dleqValid else {
            throw CashuSwiftError.invalidProof
        }
        
        // Store change tokens back to wallet if any
        if !change.isEmpty {
            // TODO: Store change tokens
        }
        
        return [lockedToken]
    }
    
    /// Redeems P2PK-locked tokens from a nutzap
    func redeemP2PKTokens(tokens: [Token]) async throws -> [Token] {
        // TODO: Implement P2PK redemption
        // 1. Verify we have the private key for the P2PK lock
        // 2. Create signature proof
        // 3. Swap for unlocked tokens
        return []
    }
    
    /// Gets the current balance across all mints
    func getBalance() async throws -> [String: Int] {
        // TODO: Query balance from each trusted mint
        var balances: [String: Int] = [:]
        for mint in trustedMints {
            // Query mint balance
            balances[mint] = 0
        }
        return balances
    }
    
    /// Validates proofs with a mint
    func validateProofs(_ tokens: [Token], mint: String) async throws -> Bool {
        // TODO: Check if proofs are still valid (not spent)
        return true
    }
}

/// Conversion utilities between CashuSwift types and Nos types
struct CashuSwiftConverter {
    
    /// Converts CashuSwift Token to JSON for storage in Nostr events
    static func tokenToJSON(_ token: Token) throws -> [String: Any] {
        // CashuSwift tokens can be serialized in V3 (JSON) or V4 (CBOR) format
        // For NIP-60 compatibility, we'll use V3 JSON format
        
        // Extract token data
        var tokenData: [String: Any] = [:]
        
        // Add mint URL
        if let mintURL = token.mint?.url {
            tokenData["mint"] = mintURL.absoluteString
        }
        
        // Serialize proofs
        let proofsData = token.proofs.map { proof in
            return [
                "amount": proof.amount,
                "id": proof.id,
                "secret": proof.secret,
                "C": proof.C
            ]
        }
        tokenData["proofs"] = proofsData
        
        // Add unit if available
        tokenData["unit"] = "sat"
        
        return tokenData
    }
    
    /// Converts JSON from Nostr events back to CashuSwift Token
    static func jsonToToken(_ json: [String: Any]) throws -> Token? {
        // Parse mint URL
        guard let mintURLString = json["mint"] as? String,
              let mintURL = URL(string: mintURLString) else {
            return nil
        }
        
        // Parse proofs
        guard let proofsArray = json["proofs"] as? [[String: Any]] else {
            return nil
        }
        
        let proofs = proofsArray.compactMap { proofData -> Proof? in
            guard let amount = proofData["amount"] as? Int,
                  let id = proofData["id"] as? String,
                  let secret = proofData["secret"] as? String,
                  let C = proofData["C"] as? String else {
                return nil
            }
            
            return Proof(amount: amount, id: id, secret: secret, C: C)
        }
        
        // Create mint info (minimal for deserialization)
        let mint = Mint(url: mintURL, keys: [:])
        
        return Token(mint: mint, proofs: proofs)
    }
    
    /// Converts multiple tokens to JSON array
    static func tokensToJSON(_ tokens: [Token]) throws -> [[String: Any]] {
        return try tokens.map { try tokenToJSON($0) }
    }
    
    /// Converts JSON array to tokens
    static func jsonToTokens(_ jsonArray: [[String: Any]]) throws -> [Token] {
        return jsonArray.compactMap { try? jsonToToken($0) }
    }
}

/// Error types for CashuSwift integration
enum CashuSwiftError: LocalizedError {
    case walletNotInitialized
    case mintNotTrusted(String)
    case insufficientBalance
    case invalidProof
    case p2pkLockFailed
    case networkError(String)
    
    var errorDescription: String? {
        switch self {
        case .walletNotInitialized:
            return "Cashu wallet not initialized"
        case .mintNotTrusted(let mint):
            return "Mint not trusted: \(mint)"
        case .insufficientBalance:
            return "Insufficient balance"
        case .invalidProof:
            return "Invalid or spent proof"
        case .p2pkLockFailed:
            return "Failed to create P2PK lock"
        case .networkError(let error):
            return "Network error: \(error)"
        }
    }
}
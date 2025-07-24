import Foundation
import NostrSDK

/// Handles NIP-44 encryption for Cashu wallet data
public enum CashuNIP44Encryption {
    
    /// Encrypts wallet private key using NIP-44 for storage in wallet events
    /// - Parameters:
    ///   - privateKey: The wallet's private key to encrypt
    ///   - authorKeyPair: The author's Nostr keypair for encryption
    /// - Returns: Encrypted private key string
    public static func encryptWalletPrivateKey(
        _ privateKey: String,
        authorKeyPair: KeyPair
    ) throws -> String {
        // For wallet events, we encrypt to ourselves (author's public key)
        let privateKeyA = try toNostrSDKPrivateKey(keyPair: authorKeyPair)
        let publicKeyB = try toNostrSDKPublicKey(rawAuthorId: authorKeyPair.publicKeyHex)
        
        return try NIP44v2Encrypter().encrypt(
            plaintext: privateKey,
            privateKeyA: privateKeyA,
            publicKeyB: publicKeyB
        )
    }
    
    /// Decrypts wallet private key from wallet events using NIP-44
    /// - Parameters:
    ///   - encryptedKey: The encrypted private key from the event
    ///   - authorKeyPair: The author's Nostr keypair for decryption
    /// - Returns: Decrypted wallet private key
    public static func decryptWalletPrivateKey(
        _ encryptedKey: String,
        authorKeyPair: KeyPair
    ) throws -> String {
        let privateKeyA = try toNostrSDKPrivateKey(keyPair: authorKeyPair)
        let publicKeyB = try toNostrSDKPublicKey(rawAuthorId: authorKeyPair.publicKeyHex)
        
        return try NIP44v2Encrypter().decrypt(
            payload: encryptedKey,
            privateKeyA: privateKeyA,
            publicKeyB: publicKeyB
        )
    }
    
    /// Encrypts Cashu tokens/proofs for storage in token events
    /// - Parameters:
    ///   - tokensJSON: JSON string containing token data
    ///   - authorKeyPair: The author's Nostr keypair for encryption
    /// - Returns: Encrypted tokens string
    public static func encryptTokens(
        _ tokensJSON: String,
        authorKeyPair: KeyPair
    ) throws -> String {
        let privateKeyA = try toNostrSDKPrivateKey(keyPair: authorKeyPair)
        let publicKeyB = try toNostrSDKPublicKey(rawAuthorId: authorKeyPair.publicKeyHex)
        
        return try NIP44v2Encrypter().encrypt(
            plaintext: tokensJSON,
            privateKeyA: privateKeyA,
            publicKeyB: publicKeyB
        )
    }
    
    /// Decrypts Cashu tokens/proofs from token events
    /// - Parameters:
    ///   - encryptedTokens: The encrypted tokens from the event
    ///   - authorKeyPair: The author's Nostr keypair for decryption
    /// - Returns: Decrypted tokens JSON string
    public static func decryptTokens(
        _ encryptedTokens: String,
        authorKeyPair: KeyPair
    ) throws -> String {
        let privateKeyA = try toNostrSDKPrivateKey(keyPair: authorKeyPair)
        let publicKeyB = try toNostrSDKPublicKey(rawAuthorId: authorKeyPair.publicKeyHex)
        
        return try NIP44v2Encrypter().decrypt(
            payload: encryptedTokens,
            privateKeyA: privateKeyA,
            publicKeyB: publicKeyB
        )
    }
    
    // MARK: - Private Helpers
    
    private static func toNostrSDKPrivateKey(keyPair: KeyPair) throws -> PrivateKey {
        guard let privateKey = PrivateKey(hex: keyPair.privateKeyHex) else {
            throw CashuWalletError.encryptionFailed
        }
        return privateKey
    }
    
    private static func toNostrSDKPublicKey(rawAuthorId: RawAuthorID) throws -> NostrSDK.PublicKey {
        guard let publicKey = NostrSDK.PublicKey(hex: rawAuthorId) else {
            throw CashuWalletError.encryptionFailed
        }
        return publicKey
    }
}

// NIP44v2 Encrypter instance
private struct NIP44v2Encrypter: NIP44v2Encrypting {}

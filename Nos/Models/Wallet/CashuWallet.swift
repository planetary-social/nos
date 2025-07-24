// ABOUTME: Core CashuWallet model for managing Cashu ecash wallets and implements NIP-60/NIP-61 support

import Foundation
import CashuSwift
import secp256k1
import Dependencies

/// Represents a Cashu wallet that can send and receive ecash tokens
public class CashuWallet {
    
    // MARK: - Properties
    
    /// Human-readable name for the wallet
    public let name: String
    
    /// Primary mint URL for this wallet
    public let mintURL: String
    
    /// Private key used for P2PK ecash operations (different from Nostr key)
    public let walletPrivateKey: String
    
    /// Public key derived from walletPrivateKey, used for receiving nutzaps
    public let walletPublicKey: String
    
    /// Set of all trusted mint URLs
    public private(set) var trustedMints: Set<String>
    
    /// Lightning address for receiving zaps as ecash
    public var lightningAddress: String?
    
    /// Selected Lightning gateway URL for conversions
    public var lightningGateway: String?
    
    /// Underlying CashuSwift wallet instance
    private var cashuWallet: Wallet?
    
    // MARK: - Initialization
    
    public init(name: String, mintURL: String) {
        self.name = name
        self.mintURL = mintURL
        self.trustedMints = [mintURL]
        
        // Generate a new keypair for this wallet
        let keypair = CashuWallet.generateWalletKeypair()
        self.walletPrivateKey = keypair.privateKey
        self.walletPublicKey = keypair.publicKey
        
        // Initialize the CashuSwift wallet
        // Note: Actual CashuSwift initialization would go here
    }
    
    // MARK: - Public Methods
    
    /// Adds a new mint to the list of trusted mints
    public func addMint(_ mintURL: String) {
        trustedMints.insert(mintURL)
    }
    
    /// Creates a NIP-60 wallet event containing encrypted wallet data
    public func createWalletEvent(author: Author) throws -> Event {
        let event = Event(context: author.managedObjectContext!)
        event.kind = EventKind.cashuWallet.rawValue
        event.author = author
        
        // Build tags array
        var tags: [[String]] = []
        
        // Add mint tags
        for mint in trustedMints {
            tags.append(["mint", mint])
        }
        
        // Add name tag
        tags.append(["name", name])
        
        // Add P2PK pubkey tag
        tags.append(["pubkey", walletPublicKey])
        
        // Add Lightning address tag if configured
        if let lightningAddress = lightningAddress {
            tags.append(["lud16", lightningAddress])
        }
        
        // Add Lightning gateway tag if configured
        if let lightningGateway = lightningGateway {
            tags.append(["gateway", lightningGateway])
        }
        
        // Set tags on event
        event.allTags = tags as NSObject
        
        // Encrypt the private key using NIP-44
        guard let keypair = author.keypair else {
            throw CashuWalletError.missingKeypair
        }
        event.content = try CashuNIP44Encryption.encryptWalletPrivateKey(walletPrivateKey, authorKeyPair: keypair)
        
        return event
    }
    
    /// Creates a NIP-60 token event containing encrypted Cashu tokens
    public func createTokenEvent(tokens: [Token], mint: String, author: Author) throws -> Event {
        let event = Event(context: author.managedObjectContext!)
        event.kind = EventKind.cashuToken.rawValue
        event.author = author
        
        // Build tags array
        var tags: [[String]] = []
        tags.append(["mint", mint])
        event.allTags = tags as NSObject
        
        // Encrypt the tokens using NIP-44
        let tokensJSON = try CashuSwiftConverter.tokensToJSON(tokens)
        let jsonData = try JSONSerialization.data(withJSONObject: tokensJSON)
        let jsonString = String(data: jsonData, encoding: .utf8) ?? ""
        
        guard let keypair = author.keypair else {
            throw CashuWalletError.missingKeypair
        }
        event.content = try CashuNIP44Encryption.encryptTokens(jsonString, authorKeyPair: keypair)
        
        return event
    }
    
    /// Creates a NIP-61 nutzap info event advertising mints and P2PK pubkey
    public func createNutzapInfoEvent(author: Author, relays: [String], p2pkPubkey: String) throws -> Event {
        let event = Event(context: author.managedObjectContext!)
        event.kind = EventKind.nutzapInfo.rawValue
        event.author = author
        
        // Build tags array
        var tags: [[String]] = []
        
        // Add mint tags for all trusted mints
        for mint in trustedMints {
            tags.append(["mint", mint])
        }
        
        // Add relay tags
        for relay in relays {
            tags.append(["relay", relay])
        }
        
        // Add P2PK pubkey tag with "02" prefix
        tags.append(["pubkey", "02" + p2pkPubkey])
        
        event.allTags = tags as NSObject
        
        return event
    }
    
    /// Creates a NIP-61 nutzap event with P2PK-locked tokens
    public func createNutzap(amount: Int, recipientPubkey: String, mint: String, comment: String?, author: Author) async throws -> Event {
        let event = Event(context: author.managedObjectContext!)
        event.kind = EventKind.nutzap.rawValue
        event.author = author
        
        // Build tags array
        var tags: [[String]] = []
        
        // Add recipient tag (without P2PK prefix)
        let cleanPubkey = recipientPubkey.hasPrefix("02") ? String(recipientPubkey.dropFirst(2)) : recipientPubkey
        tags.append(["p", cleanPubkey])
        
        // Add mint URL tag
        tags.append(["u", mint])
        
        // Add amount tag
        tags.append(["amount", String(amount)])
        
        // Add comment tag if provided
        if let comment = comment {
            tags.append(["comment", comment])
        }
        
        event.allTags = tags as NSObject
        
        // Create P2PK-locked tokens
        // TODO: Replace with actual P2PK locking once CashuSwift integration is complete
        let lockedTokens = try await createP2PKLockedTokens(amount: amount, recipientPubkey: recipientPubkey)
        let tokensJSON = try CashuSwiftConverter.tokensToJSON(lockedTokens)
        
        if let jsonData = try? JSONSerialization.data(withJSONObject: ["proofs": tokensJSON]),
           let jsonString = String(data: jsonData, encoding: .utf8) {
            event.content = jsonString
        }
        
        return event
    }
    
    /// Gets the managed object context from current app state
    func getManagedObjectContext() -> NSManagedObjectContext? {
        // Try to get context from persistence controller
        @Dependency(\.persistenceController) var persistenceController
        return persistenceController.viewContext
    }
    
    /// Validates if this wallet can receive a nutzap
    public func canReceiveNutzap(_ nutzapEvent: Event, recipientPubkey: String) -> Bool {
        // Check if the nutzap is addressed to this pubkey
        guard let tags = nutzapEvent.allTags as? [[String]] else { return false }
        let recipientTags = tags.filter { $0.first == "p" }
        return recipientTags.contains { $0.count > 1 && $0[1] == recipientPubkey }
    }
    
    // MARK: - Private Methods
    
    /// Generates a new wallet keypair for P2PK operations
    private static func generateWalletKeypair() -> (privateKey: String, publicKey: String) {
        // Generate a random private key
        var privateKeyBytes = [UInt8](repeating: 0, count: 32)
        _ = SecRandomCopyBytes(kSecRandomDefault, privateKeyBytes.count, &privateKeyBytes)
        
        let privateKeyHex = privateKeyBytes.map { String(format: "%02x", $0) }.joined()
        
        // Derive public key (simplified for now)
        // In real implementation, would use secp256k1 library
        let publicKeyHex = "02" + privateKeyHex.prefix(32) // Mock derivation
        
        return (privateKey: privateKeyHex, publicKey: String(publicKeyHex.dropFirst(2)))
    }
}
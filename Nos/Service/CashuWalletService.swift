// ABOUTME: Service layer for managing Cashu wallet operations, persistence, and Nostr event integration

import Foundation
import CoreData
import CashuSwift
import Logger

/// Service responsible for managing Cashu wallets and their operations
public class CashuWalletService {
    
    private let context: NSManagedObjectContext
    private var walletCache: [String: CashuWallet] = [:]
    
    public init(context: NSManagedObjectContext) {
        self.context = context
    }
    
    // MARK: - Wallet Management
    
    /// Creates a new Cashu wallet and publishes a wallet event
    public func createWallet(name: String, mintURL: String, for author: Author) async throws -> CashuWallet {
        let wallet = CashuWallet(name: name, mintURL: mintURL)
        
        // Create and save wallet event
        let walletEvent = try wallet.createWalletEvent(author: author)
        walletEvent.createdAt = Date()
        
        try context.save()
        
        // Cache the wallet
        walletCache[walletEvent.identifier ?? ""] = wallet
        
        return wallet
    }
    
    /// Loads all wallets for a user from their wallet events
    public func loadWallets(for author: Author) async throws -> [CashuWallet] {
        let walletEvents = try await fetchWalletEvents(for: author)
        var wallets: [CashuWallet] = []
        
        for event in walletEvents {
            if let wallet = try? parseWalletFromEvent(event) {
                wallets.append(wallet)
                walletCache[event.identifier ?? ""] = wallet
            }
        }
        
        return wallets
    }
    
    /// Fetches all wallet events for a user
    public func fetchWalletEvents(for author: Author) async throws -> [Event] {
        let request = NSFetchRequest<Event>(entityName: "Event")
        request.predicate = NSPredicate(
            format: "author == %@ AND kind == %d",
            author,
            EventKind.cashuWallet.rawValue
        )
        request.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: false)]
        
        return try context.fetch(request)
    }
    
    // MARK: - Token Management
    
    /// Saves Cashu tokens as a token event
    public func saveTokens(_ tokens: [Token], for wallet: CashuWallet, mint: String, author: Author) async throws {
        let tokenEvent = try wallet.createTokenEvent(tokens: tokens, mint: mint, author: author)
        tokenEvent.createdAt = Date()
        
        try context.save()
    }
    
    /// Fetches all token events for a user and mint
    public func fetchTokenEvents(for author: Author, mint: String) async throws -> [Event] {
        let request = NSFetchRequest<Event>(entityName: "Event")
        request.predicate = NSPredicate(
            format: "author == %@ AND kind == %d",
            author,
            EventKind.cashuToken.rawValue
        )
        
        let events = try context.fetch(request)
        
        // Filter by mint tag
        return events.filter { event in
            guard let tags = event.allTags as? [[String]] else { return false }
            return tags.contains { $0.count >= 2 && $0[0] == "mint" && $0[1] == mint }
        }
    }
    
    /// Marks tokens as spent by creating a deletion event
    public func markTokensAsSpent(_ tokenEvent: Event, author: Author) async throws {
        let deleteEvent = Event(context: context)
        deleteEvent.kind = EventKind.delete.rawValue
        deleteEvent.author = author
        deleteEvent.createdAt = Date()
        
        // Add reference to the token event being deleted
        let eventTag = ["e", tokenEvent.identifier ?? ""]
        deleteEvent.allTags = [eventTag] as NSObject
        
        try context.save()
    }
    
    /// Calculates the total balance for a wallet
    public func getBalance(for wallet: CashuWallet, author: Author) async throws -> Int {
        let tokenEvents = try await fetchTokenEvents(for: author, mint: wallet.mintURL)
        let deletedEventIds = try await fetchDeletedTokenEventIds(for: author)
        
        var totalBalance = 0
        
        for event in tokenEvents {
            // Skip if this token event has been deleted
            if deletedEventIds.contains(event.identifier ?? "") {
                continue
            }
            
            // Decrypt and parse proofs
            if let proofs = try? parseProofsFromTokenEvent(event) {
                totalBalance += proofs.reduce(0) { $0 + $1.amount }
            }
        }
        
        return totalBalance
    }
    
    // MARK: - Private Methods
    
    /// Parses a wallet from a wallet event
    private func parseWalletFromEvent(_ event: Event) throws -> CashuWallet {
        guard let tags = event.allTags as? [[String]] else {
            throw CashuWalletError.invalidEventFormat
        }
        
        // Extract wallet data from tags
        var name = "Unnamed Wallet"
        var mintURL = ""
        var lightningAddress: String?
        var lightningGateway: String?
        
        for tag in tags {
            if tag.count >= 2 {
                switch tag[0] {
                case "name":
                    name = tag[1]
                case "mint":
                    if mintURL.isEmpty {
                        mintURL = tag[1]
                    }
                case "lud16":
                    lightningAddress = tag[1]
                case "gateway":
                    lightningGateway = tag[1]
                default:
                    break
                }
            }
        }
        
        guard !mintURL.isEmpty else {
            throw CashuWalletError.missingMintURL
        }
        
        // For now, create a new wallet instance
        // In production, would decrypt the private key from content
        let wallet = CashuWallet(name: name, mintURL: mintURL)
        wallet.lightningAddress = lightningAddress
        wallet.lightningGateway = lightningGateway
        
        // Add all mints from tags
        for tag in tags {
            if tag.count >= 2 && tag[0] == "mint" {
                wallet.addMint(tag[1])
            }
        }
        
        return wallet
    }
    
    /// Parses proofs from a token event
    private func parseTokensFromTokenEvent(_ event: Event) throws -> [Token] {
        guard let content = event.content else {
            throw CashuWalletError.missingContent
        }
        
        // Decrypt content using NIP-44
        guard let author = event.author,
              let keypair = author.keypair else {
            throw CashuWalletError.missingKeypair
        }
        
        let decryptedContent = try CashuNIP44Encryption.decryptTokens(content, authorKeyPair: keypair)
        
        guard let jsonData = decryptedContent.data(using: .utf8),
              let proofsArray = try? JSONSerialization.jsonObject(with: jsonData) as? [[String: Any]] else {
            throw CashuWalletError.decryptionFailed
        }
        
        // Convert JSON to Token objects using CashuSwiftConverter
        return try CashuSwiftConverter.jsonToTokens(proofsArray)
    }
    
    /// Fetches IDs of deleted token events
    private func fetchDeletedTokenEventIds(for author: Author) async throws -> Set<String> {
        let request = NSFetchRequest<Event>(entityName: "Event")
        request.predicate = NSPredicate(
            format: "author == %@ AND kind == %d",
            author,
            EventKind.delete.rawValue
        )
        
        let deleteEvents = try context.fetch(request)
        var deletedIds = Set<String>()
        
        for event in deleteEvents {
            guard let tags = event.allTags as? [[String]] else { continue }
            for tag in tags {
                if tag.count >= 2 && tag[0] == "e" {
                    deletedIds.insert(tag[1])
                }
            }
        }
        
        return deletedIds
    }
}

// MARK: - Errors

public enum CashuWalletError: LocalizedError {
    case invalidEventFormat
    case missingMintURL
    case missingContent
    case decryptionFailed
    case missingKeypair
    case encryptionFailed
    
    public var errorDescription: String? {
        switch self {
        case .invalidEventFormat:
            return "Invalid event format"
        case .missingMintURL:
            return "Missing mint URL in wallet event"
        case .missingContent:
            return "Missing content in event"
        case .decryptionFailed:
            return "Failed to decrypt event content"
        case .missingKeypair:
            return "Missing author keypair for encryption"
        case .encryptionFailed:
            return "Failed to encrypt wallet data"
        }
    }
}
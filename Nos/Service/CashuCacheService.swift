// ABOUTME: Service for managing Core Data cache of Cashu wallet data
// ABOUTME: Handles synchronization between Nostr events and local cache

import Foundation
import CoreData
import CashuSwift
import Logger

/// Service responsible for caching Cashu wallet data in Core Data
public class CashuCacheService {
    
    private let context: NSManagedObjectContext
    private let walletService: CashuWalletService
    
    public init(context: NSManagedObjectContext, walletService: CashuWalletService) {
        self.context = context
        self.walletService = walletService
    }
    
    // MARK: - Wallet Cache Management
    
    /// Creates or updates a wallet cache from a wallet event
    public func cacheWallet(_ wallet: CashuWallet, walletEvent: Event, for author: Author) throws -> CashuWalletCache {
        // Check if cache already exists
        let request = CashuWalletCache.fetchRequest()
        request.predicate = NSPredicate(format: "walletEvent == %@", walletEvent)
        
        let existingCache = try context.fetch(request).first
        let cache = existingCache ?? CashuWalletCache(context: context)
        
        // Set initial values if new
        if existingCache == nil {
            cache.id = UUID().uuidString
            cache.createdAt = Date()
            cache.author = author
        }
        
        // Sync with wallet data
        cache.sync(with: wallet, walletEvent: walletEvent)
        
        try context.save()
        return cache
    }
    
    /// Fetches all wallet caches for an author
    public func fetchWalletCaches(for author: Author) throws -> [CashuWalletCache] {
        let request = CashuWalletCache.fetchRequest()
        request.predicate = NSPredicate(format: "author == %@", author)
        request.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: false)]
        
        return try context.fetch(request)
    }
    
    // MARK: - Token Cache Management
    
    /// Caches tokens from a token event
    public func cacheTokens(_ tokens: [Token], tokenEvent: Event, wallet: CashuWalletCache) throws {
        for token in tokens {
            let cache = try CashuTokenCache.create(from: token, wallet: wallet, in: context)
            cache.tokenEvent = tokenEvent
            wallet.addToTokens(cache)
        }
        
        // Update wallet balance
        wallet.updateBalance()
        wallet.updatedAt = Date()
        
        try context.save()
    }
    
    /// Fetches unspent tokens for a wallet
    public func fetchUnspentTokens(for wallet: CashuWalletCache, mint: String? = nil) throws -> [CashuTokenCache] {
        let request = CashuTokenCache.fetchRequest()
        
        var predicates = [
            NSPredicate(format: "wallet == %@", wallet),
            NSPredicate(format: "isSpent == NO")
        ]
        
        if let mint = mint {
            predicates.append(NSPredicate(format: "mintURL == %@", mint))
        }
        
        request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
        request.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: false)]
        
        return try context.fetch(request)
    }
    
    /// Marks tokens as spent
    public func markTokensAsSpent(_ tokenIds: Set<String>, in wallet: CashuWalletCache) throws {
        let request = CashuTokenCache.fetchRequest()
        request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
            NSPredicate(format: "wallet == %@", wallet),
            NSPredicate(format: "id IN %@", tokenIds)
        ])
        
        let tokens = try context.fetch(request)
        for token in tokens {
            token.markAsSpent()
        }
        
        // Update wallet balance
        wallet.updateBalance()
        wallet.updatedAt = Date()
        
        try context.save()
    }
    
    // MARK: - Transaction Management
    
    /// Records a mint transaction
    public func recordMintTransaction(amount: Int64, mintURL: String, wallet: CashuWalletCache, tokens: [CashuTokenCache]) throws -> CashuTransaction {
        let transaction = CashuTransaction.createMint(
            amount: amount,
            mintURL: mintURL,
            wallet: wallet,
            in: context
        )
        
        // Link tokens to transaction
        for token in tokens {
            transaction.addToTokens(token)
            token.transaction = transaction
        }
        
        transaction.complete()
        
        try context.save()
        return transaction
    }
    
    /// Records a melt transaction
    public func recordMeltTransaction(amount: Int64, mintURL: String, invoice: String, wallet: CashuWalletCache, spentTokens: [CashuTokenCache]) throws -> CashuTransaction {
        let transaction = CashuTransaction.createMelt(
            amount: amount,
            mintURL: mintURL,
            invoice: invoice,
            wallet: wallet,
            in: context
        )
        
        // Link and mark tokens as spent
        for token in spentTokens {
            transaction.addToTokens(token)
            token.transaction = transaction
            token.markAsSpent()
        }
        
        transaction.complete()
        wallet.updateBalance()
        
        try context.save()
        return transaction
    }
    
    /// Records a nutzap send transaction
    public func recordNutzapSend(amount: Int64, mintURL: String, recipientPubkey: String, comment: String?, wallet: CashuWalletCache, nutzapEvent: Event) throws -> CashuTransaction {
        let transaction = CashuTransaction.createSend(
            amount: amount,
            mintURL: mintURL,
            recipientPubkey: recipientPubkey,
            comment: comment,
            wallet: wallet,
            in: context
        )
        
        transaction.nutzapEvent = nutzapEvent
        transaction.complete()
        
        try context.save()
        return transaction
    }
    
    /// Records a nutzap receive transaction
    public func recordNutzapReceive(amount: Int64, mintURL: String, wallet: CashuWalletCache, tokens: [CashuTokenCache], nutzapEvent: Event) throws -> CashuTransaction {
        let transaction = CashuTransaction.createReceive(
            amount: amount,
            mintURL: mintURL,
            wallet: wallet,
            in: context
        )
        
        // Link tokens to transaction
        for token in tokens {
            transaction.addToTokens(token)
            token.transaction = transaction
        }
        
        transaction.nutzapEvent = nutzapEvent
        wallet.updateBalance()
        
        try context.save()
        return transaction
    }
    
    // MARK: - Sync Operations
    
    /// Syncs all wallet data from Nostr events
    public func syncFromEvents(for author: Author) async throws {
        // Load all wallets from events
        let wallets = try await walletService.loadWallets(for: author)
        
        // Cache each wallet
        for (wallet, event) in wallets {
            guard let walletEvent = event else { continue }
            
            let cache = try cacheWallet(wallet, walletEvent: walletEvent, for: author)
            
            // Sync tokens for this wallet
            try await syncTokensForWallet(wallet, cache: cache, author: author)
        }
    }
    
    /// Syncs tokens for a specific wallet
    private func syncTokensForWallet(_ wallet: CashuWallet, cache: CashuWalletCache, author: Author) async throws {
        // This would fetch token events and cache them
        // Implementation depends on how token events are stored
        Log.info("Syncing tokens for wallet: \(wallet.name)")
    }
    
    // MARK: - Analytics
    
    /// Fetches transaction history for a wallet
    public func fetchTransactionHistory(for wallet: CashuWalletCache, limit: Int = 50) throws -> [CashuTransaction] {
        let request = CashuTransaction.fetchRequest()
        request.predicate = NSPredicate(format: "wallet == %@", wallet)
        request.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: false)]
        request.fetchLimit = limit
        
        return try context.fetch(request)
    }
    
    /// Calculates spending statistics for a wallet
    public func calculateSpendingStats(for wallet: CashuWalletCache, days: Int = 30) throws -> (sent: Int64, received: Int64) {
        let startDate = Calendar.current.date(byAdding: .day, value: -days, to: Date())!
        
        let request = CashuTransaction.fetchRequest()
        request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
            NSPredicate(format: "wallet == %@", wallet),
            NSPredicate(format: "createdAt >= %@", startDate as NSDate),
            NSPredicate(format: "status == %@", CashuTransaction.TransactionStatus.completed.rawValue)
        ])
        
        let transactions = try context.fetch(request)
        
        var sent: Int64 = 0
        var received: Int64 = 0
        
        for transaction in transactions {
            switch transaction.transactionType {
            case .send, .melt:
                sent += transaction.amount
            case .receive, .mint:
                received += transaction.amount
            default:
                break
            }
        }
        
        return (sent, received)
    }
}
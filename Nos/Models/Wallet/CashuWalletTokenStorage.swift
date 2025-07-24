// ABOUTME: Token storage and retrieval methods for CashuWallet
// ABOUTME: Manages fetching and storing tokens using Core Data cache

import Foundation
import CoreData
import CashuSwift

extension CashuWallet {
    
    /// Gets the wallet's Core Data cache
    private func getWalletCache(in context: NSManagedObjectContext) throws -> CashuWalletCache? {
        guard let author = try? context.fetch(Author.fetchRequest()).first else {
            return nil
        }
        
        let request = CashuWalletCache.fetchRequest()
        request.predicate = NSPredicate(
            format: "author == %@ AND primaryMintURL == %@",
            author,
            mintURL
        )
        request.fetchLimit = 1
        
        return try context.fetch(request).first
    }
    
    /// Fetches available tokens for spending
    func fetchAvailableTokens(amount: Int, mint: String, in context: NSManagedObjectContext) async throws -> [Token] {
        let cacheService = CashuCacheService(
            context: context,
            walletService: CashuWalletService(context: context)
        )
        
        guard let walletCache = try getWalletCache(in: context) else {
            throw CashuSwiftError.walletNotInitialized
        }
        
        // Fetch unspent tokens for this mint
        let tokenCaches = try cacheService.fetchUnspentTokens(for: walletCache, mint: mint)
        
        // Convert cached tokens to CashuSwift tokens
        var availableTokens: [Token] = []
        var totalAvailable = 0
        
        for tokenCache in tokenCaches {
            if let token = try tokenCache.getToken() {
                availableTokens.append(token)
                totalAvailable += Int(tokenCache.amount)
            }
        }
        
        // Check if we have enough balance
        guard totalAvailable >= amount else {
            throw CashuSwiftError.insufficientBalance
        }
        
        return availableTokens
    }
    
    /// Stores tokens received from minting or as change
    func storeTokens(_ tokens: [Token], author: Author, context: NSManagedObjectContext) async throws {
        let cacheService = CashuCacheService(
            context: context,
            walletService: CashuWalletService(context: context)
        )
        
        // Get or create wallet cache
        var walletCache = try getWalletCache(in: context)
        if walletCache == nil {
            // Create wallet event first
            let walletEvent = try self.createWalletEvent(author: author)
            context.insert(walletEvent)
            
            // Create cache
            walletCache = try cacheService.cacheWallet(self, walletEvent: walletEvent, for: author)
        }
        
        guard let cache = walletCache else {
            throw CashuWalletError.missingContent
        }
        
        // Create token event
        let tokenEvent = try self.createTokenEvent(tokens: tokens, mint: mintURL, author: author)
        context.insert(tokenEvent)
        
        // Cache tokens
        try cacheService.cacheTokens(tokens, tokenEvent: tokenEvent, wallet: cache)
        
        // Save context
        try context.save()
    }
    
    /// Marks tokens as spent after successful send/melt
    func markTokensAsSpent(_ tokens: [Token], context: NSManagedObjectContext) async throws {
        let cacheService = CashuCacheService(
            context: context,
            walletService: CashuWalletService(context: context)
        )
        
        guard let walletCache = try getWalletCache(in: context) else {
            throw CashuSwiftError.walletNotInitialized
        }
        
        // Extract token IDs to mark as spent
        var tokenIds = Set<String>()
        for token in tokens {
            for proof in token.proofs {
                // Use proof secret as unique identifier
                tokenIds.insert(proof.secret)
            }
        }
        
        // Mark tokens as spent in cache
        try cacheService.markTokensAsSpent(tokenIds, in: walletCache)
        
        // Create deletion event for spent tokens
        // This would be a NIP-09 deletion event referencing the original token events
        // TODO: Implement deletion event creation
    }
    
    /// Gets available proofs for P2PK operations
    func getAvailableProofs(amount: Int, context: NSManagedObjectContext) async throws -> [Proof] {
        let tokens = try await fetchAvailableTokens(amount: amount, mint: mintURL, in: context)
        return tokens.flatMap { $0.proofs }
    }
    
    /// Stores change tokens after a send operation
    func storeChangeTokens(_ tokens: [Token], author: Author, context: NSManagedObjectContext) async throws {
        if !tokens.isEmpty {
            try await storeTokens(tokens, author: author, context: context)
        }
    }
}
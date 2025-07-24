// ABOUTME: Core Data entity for caching individual Cashu tokens
// ABOUTME: Tracks token state and provides efficient querying

import Foundation
import CoreData
import CashuSwift

@objc(CashuTokenCache)
public class CashuTokenCache: NSManagedObject {
    
    /// Marks the token as spent
    func markAsSpent() {
        isSpent = true
        spentAt = Date()
        updatedAt = Date()
    }
    
    /// Stores encrypted token data
    func setTokenData(_ token: Token) throws {
        let tokenJSON = try CashuSwiftConverter.tokenToJSON(token)
        self.tokenData = try JSONSerialization.data(withJSONObject: tokenJSON)
        self.updatedAt = Date()
    }
    
    /// Retrieves the token from encrypted data
    func getToken() throws -> Token? {
        guard let data = tokenData,
              let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return nil
        }
        
        return try CashuSwiftConverter.jsonToToken(json)
    }
    
    /// Creates a cache entry from a Token
    static func create(from token: Token, wallet: CashuWalletCache, in context: NSManagedObjectContext) throws -> CashuTokenCache {
        let cache = CashuTokenCache(context: context)
        cache.id = UUID().uuidString
        cache.mintURL = token.mint?.url?.absoluteString ?? wallet.primaryMintURL
        cache.amount = Int64(token.proofs.reduce(0) { $0 + $1.amount })
        try cache.setTokenData(token)
        cache.wallet = wallet
        cache.createdAt = Date()
        cache.updatedAt = Date()
        cache.isSpent = false
        
        return cache
    }
}
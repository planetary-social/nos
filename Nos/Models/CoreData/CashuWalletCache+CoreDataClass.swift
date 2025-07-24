// ABOUTME: Core Data entity for caching Cashu wallet data locally
// ABOUTME: Provides fast access to wallet information and balance calculations

import Foundation
import CoreData

@objc(CashuWalletCache)
public class CashuWalletCache: NSManagedObject {
    
    /// Computed property for total balance across all unspent tokens
    var calculatedBalance: Int64 {
        guard let tokens = tokens as? Set<CashuTokenCache> else { return 0 }
        return tokens
            .filter { !$0.isSpent }
            .reduce(0) { $0 + $1.amount }
    }
    
    /// Updates the cached total balance
    func updateBalance() {
        totalBalance = calculatedBalance
    }
    
    /// Syncs with a CashuWallet model object
    func sync(with wallet: CashuWallet, walletEvent: Event) {
        self.name = wallet.name
        self.primaryMintURL = wallet.mintURL
        self.trustedMints = wallet.trustedMints as NSSet
        self.walletPublicKey = wallet.walletPublicKey
        self.lightningAddress = wallet.lightningAddress
        self.lightningGateway = wallet.lightningGateway
        self.walletEvent = walletEvent
        self.lastSyncDate = Date()
        self.updatedAt = Date()
    }
    
    /// Creates a CashuWallet model from cached data
    func toCashuWallet() -> CashuWallet {
        let wallet = CashuWallet(name: name, mintURL: primaryMintURL)
        
        // Restore trusted mints
        if let mints = trustedMints as? Set<String> {
            for mint in mints {
                wallet.addMint(mint)
            }
        }
        
        // Restore Lightning configuration
        wallet.lightningAddress = lightningAddress
        wallet.lightningGateway = lightningGateway
        
        return wallet
    }
}
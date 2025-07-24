import Foundation
import CoreData

extension CashuWalletCache {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<CashuWalletCache> {
        return NSFetchRequest<CashuWalletCache>(entityName: "CashuWalletCache")
    }

    @NSManaged public var id: String
    @NSManaged public var name: String
    @NSManaged public var primaryMintURL: String
    @NSManaged public var trustedMints: NSSet?
    @NSManaged public var walletPublicKey: String
    @NSManaged public var lightningAddress: String?
    @NSManaged public var lightningGateway: String?
    @NSManaged public var totalBalance: Int64
    @NSManaged public var lastSyncDate: Date
    @NSManaged public var createdAt: Date
    @NSManaged public var updatedAt: Date
    
    @NSManaged public var author: Author
    @NSManaged public var tokens: NSSet?
    @NSManaged public var transactions: NSSet?
    @NSManaged public var walletEvent: Event?

}

// MARK: Generated accessors for tokens
extension CashuWalletCache {

    @objc(addTokensObject:)
    @NSManaged public func addToTokens(_ value: CashuTokenCache)

    @objc(removeTokensObject:)
    @NSManaged public func removeFromTokens(_ value: CashuTokenCache)

    @objc(addTokens:)
    @NSManaged public func addToTokens(_ values: NSSet)

    @objc(removeTokens:)
    @NSManaged public func removeFromTokens(_ values: NSSet)

}

// MARK: Generated accessors for transactions
extension CashuWalletCache {

    @objc(addTransactionsObject:)
    @NSManaged public func addToTransactions(_ value: CashuTransaction)

    @objc(removeTransactionsObject:)
    @NSManaged public func removeFromTransactions(_ value: CashuTransaction)

    @objc(addTransactions:)
    @NSManaged public func addToTransactions(_ values: NSSet)

    @objc(removeTransactions:)
    @NSManaged public func removeFromTransactions(_ values: NSSet)

}
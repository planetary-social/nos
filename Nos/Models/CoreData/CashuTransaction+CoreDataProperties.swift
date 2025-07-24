// ABOUTME: Core Data generated properties for CashuTransaction entity
// ABOUTME: Defines attributes and relationships for transaction tracking

import Foundation
import CoreData

extension CashuTransaction {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<CashuTransaction> {
        return NSFetchRequest<CashuTransaction>(entityName: "CashuTransaction")
    }

    @NSManaged public var id: String
    @NSManaged public var type: String
    @NSManaged public var amount: Int64
    @NSManaged public var mintURL: String
    @NSManaged public var lightningInvoice: String?
    @NSManaged public var recipientPubkey: String?
    @NSManaged public var comment: String?
    @NSManaged public var status: String
    @NSManaged public var createdAt: Date
    @NSManaged public var completedAt: Date?
    
    @NSManaged public var wallet: CashuWalletCache
    @NSManaged public var tokens: NSSet?
    @NSManaged public var nutzapEvent: Event?

}

// MARK: Generated accessors for tokens
extension CashuTransaction {

    @objc(addTokensObject:)
    @NSManaged public func addToTokens(_ value: CashuTokenCache)

    @objc(removeTokensObject:)
    @NSManaged public func removeFromTokens(_ value: CashuTokenCache)

    @objc(addTokens:)
    @NSManaged public func addToTokens(_ values: NSSet)

    @objc(removeTokens:)
    @NSManaged public func removeFromTokens(_ values: NSSet)

}
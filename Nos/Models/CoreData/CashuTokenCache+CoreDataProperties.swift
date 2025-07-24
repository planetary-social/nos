import Foundation
import CoreData

extension CashuTokenCache {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<CashuTokenCache> {
        return NSFetchRequest<CashuTokenCache>(entityName: "CashuTokenCache")
    }

    @NSManaged public var id: String
    @NSManaged public var mintURL: String
    @NSManaged public var amount: Int64
    @NSManaged public var tokenData: Data?
    @NSManaged public var isSpent: Bool
    @NSManaged public var spentAt: Date?
    @NSManaged public var createdAt: Date
    @NSManaged public var updatedAt: Date
    
    @NSManaged public var wallet: CashuWalletCache
    @NSManaged public var tokenEvent: Event?
    @NSManaged public var transaction: CashuTransaction?

}
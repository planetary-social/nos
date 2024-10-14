import CoreData
import Foundation

extension AuthorReference {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<AuthorReference> {
        NSFetchRequest<AuthorReference>(entityName: "AuthorReference")
    }

    @NSManaged public var pubkey: String?
    @NSManaged public var recommendedRelayUrl: String?
    @NSManaged public var event: Event?
}

extension AuthorReference: Identifiable {}

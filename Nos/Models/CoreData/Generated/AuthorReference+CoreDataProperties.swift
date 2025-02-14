import Foundation
import CoreData

extension AuthorReference {

    @nonobjc static func fetchRequest() -> NSFetchRequest<AuthorReference> {
        NSFetchRequest<AuthorReference>(entityName: "AuthorReference")
    }

    @NSManaged var pubkey: String?
    @NSManaged var recommendedRelayUrl: String?
    @NSManaged var event: Event?
}

extension AuthorReference: Identifiable {}

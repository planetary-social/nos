import Foundation
import CoreData

extension AuthorReference {
    @NSManaged public var pubkey: String?
    @NSManaged public var recommendedRelayUrl: String?
    @NSManaged public var event: Event?
}

extension AuthorReference: Identifiable {}

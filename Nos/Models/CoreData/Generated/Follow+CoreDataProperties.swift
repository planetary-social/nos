import Foundation
import CoreData

extension Follow {

    @nonobjc static func fetchRequest() -> NSFetchRequest<Follow> {
        NSFetchRequest<Follow>(entityName: "Follow")
    }

    @NSManaged var petName: String?
    @NSManaged var destination: Author?
    @NSManaged var source: Author?
}

extension Follow: Identifiable {}

import CoreData
import Foundation

extension Follow {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Follow> {
        NSFetchRequest<Follow>(entityName: "Follow")
    }

    @NSManaged public var petName: String?
    @NSManaged public var destination: Author?
    @NSManaged public var source: Author?
}

extension Follow: Identifiable {}

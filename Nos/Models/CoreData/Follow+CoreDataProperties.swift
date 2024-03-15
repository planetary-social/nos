import Foundation
import CoreData

extension Follow {
    @NSManaged public var petName: String?
    @NSManaged public var destination: Author?
    @NSManaged public var source: Author?
}

extension Follow: Identifiable {}

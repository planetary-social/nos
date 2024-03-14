import Foundation
import CoreData

extension NSManagedObjectContext {
    func saveIfNeeded() throws {
        try performAndWait {
            if hasChanges {
                try save()
            }
        }
    }
}

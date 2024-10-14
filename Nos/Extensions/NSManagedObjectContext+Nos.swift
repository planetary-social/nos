import CoreData
import Foundation

extension NSManagedObjectContext {
    func saveIfNeeded() throws {
        try performAndWait {
            if hasChanges {
                try save()
            }
        }
    }
}

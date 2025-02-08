import CoreData
import Logger

class NosManagedObject: NSManagedObject {
    
    // Not sure why this is necessary, but SwiftUI previews crash on NSManagedObject.init(context:) otherwise.
    convenience init(context: NSManagedObjectContext) {
        self.init(entity: Self.entityDescription(in: context), insertInto: context)
    }
    
    class func entityDescription(in context: NSManagedObjectContext) -> NSEntityDescription {
        if let entity = NSEntityDescription.entity(forEntityName: String(describing: Self.self), in: context) {
            return entity
        } else {
            Log.error("Couldn't create entity description")
            return NSEntityDescription()
        }
    }
}

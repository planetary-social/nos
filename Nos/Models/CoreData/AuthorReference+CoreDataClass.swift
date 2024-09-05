import Foundation
import CoreData

@objc(AuthorReference)
public class AuthorReference: NosManagedObject {
    
    /// Retreives all the AuthorReferences 
    static func all() -> NSFetchRequest<AuthorReference> {
        let fetchRequest = NSFetchRequest<AuthorReference>(entityName: "AuthorReference")
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \AuthorReference.pubkey, ascending: false)]
        return fetchRequest
    }
    
    /// Retreives all the AuthorReferences whose referencing Event has been deleted.
    static func orphanedRequest() -> NSFetchRequest<AuthorReference> {
        let fetchRequest = NSFetchRequest<AuthorReference>(entityName: "AuthorReference")
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \AuthorReference.pubkey, ascending: false)]
        fetchRequest.predicate = NSPredicate(format: "event = nil")
        return fetchRequest
    }
}

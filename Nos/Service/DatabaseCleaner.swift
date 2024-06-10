import Foundation
import Logger
import CoreData
import Dependencies

enum DatabaseCleaner {
    
    /// Deletes unneeded entities from Core Data.
    ///
    /// This should only be called once right at app launch.
    /// 
    /// The general strategy here is to:
    /// - keep some max number of events, delete the others 
    /// - delete authors outside the user's network 
    /// - delete any other models that are orphaned by the previous deletions
    /// - fix EventReferences whose referencedEvent was deleted by createing a stubbed Event
    static func cleanupEntities(
        before deleteBefore: Date, 
        for authorKey: RawAuthorID, 
        in context: NSManagedObjectContext
    ) async throws {
        // this function was written in a hurry and probably should be refactored and tested thorougly.
        @Dependency(\.analytics) var analytics
        
        let startTime = Date.now
        Log.info("Starting Core Data cleanup...")
        
        Log.info("Database statistics: \(try await PersistenceController.databaseStatistics(from: context))")
        
        try await context.perform {
            
            guard let currentUser = try? Author.find(by: authorKey, context: context) else {
                return
            }
            
            let deleteRequests: [NSPersistentStoreRequest] = [
                EventReference.all(before: deleteBefore),
                Event.cleanupRequest(before: deleteBefore, for: currentUser),
                Event.expiredRequest(),
                EventReference.orphanedRequest(),
                AuthorReference.orphanedRequest(),
                Author.outOfNetwork(for: currentUser),
                Follow.orphanedRequest(),
                Relay.orphanedRequest(),
                NosNotification.oldNotificationsRequest(),
            ]
            
            for request in deleteRequests {
                guard let fetchRequest = request as? NSFetchRequest<any NSFetchRequestResult> else {
                    Log.error("Bad fetch request: \(request)")
                    continue
                }
                
                let batchDeleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
                batchDeleteRequest.resultType = .resultTypeCount
                let deleteResult = try context.execute(batchDeleteRequest) as? NSBatchDeleteResult
                if let entityName = fetchRequest.entityName {
                    Log.info("Deleted \(deleteResult?.result ?? 0) of type \(entityName)")
                }
            }
            
            try context.saveIfNeeded()
        }
        
        let newStatistics = try await PersistenceController.databaseStatistics(from: context)
        Log.info("Database statistics: \(newStatistics)")
        analytics.databaseStatistics(newStatistics)
        
        let elapsedTime = Date.now.timeIntervalSince1970 - startTime.timeIntervalSince1970 
        Log.info("Finished Core Data cleanup in \(elapsedTime) seconds.")
    }
}

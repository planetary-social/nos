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
        for authorKey: RawAuthorID, 
        in context: NSManagedObjectContext,
        keeping eventsToKeep: Int = 1000
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
            
            let deleteBefore = try computeDeleteBeforeDate(keeping: eventsToKeep, context: context)
            
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
    
    /// Takes the number of events we want to keep in our database and computes a date after which we can safely delete
    /// events. We use a date because you can't tell Core Data to just delete events after a certain index. Also the
    /// date is used for other fetch requests, i.e. to avoid deleting older events that are referenced by newer events.
    ///
    /// This must be called inside a `NSManagedObjectContext.perform` block. 
    private static func computeDeleteBeforeDate(
        keeping eventsToKeep: Int, 
        context: NSManagedObjectContext
    ) throws -> Date {
        // Delete all but the most recent n events
        var deleteBefore = Date.now
        guard eventsToKeep > 0 else {
            return deleteBefore
        }
        let fetchFirstEventToDelete = Event.allEventsRequest()
        fetchFirstEventToDelete.sortDescriptors = [NSSortDescriptor(keyPath: \Event.receivedAt, ascending: false)]
        fetchFirstEventToDelete.fetchLimit = 1
        fetchFirstEventToDelete.fetchOffset = eventsToKeep - 1
        fetchFirstEventToDelete.predicate = NSPredicate(format: "receivedAt != nil")
        if let firstEventToDelete = try context.fetch(fetchFirstEventToDelete).first,
            let receivedAt = firstEventToDelete.receivedAt {
            deleteBefore = receivedAt
        }
        
        return deleteBefore
    }
}

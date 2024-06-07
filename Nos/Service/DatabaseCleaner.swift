import Foundation
import Logger
import CoreData
import Dependencies

enum DatabaseCleaner {
    
    // swiftlint:disable function_body_length 
    
    /// Deletes unneeded entities from Core Data.
    /// The general strategy here is to:
    /// - keep some max number of events, delete the others 
    /// - delete authors outside the user's network 
    /// - delete any other models that are orphaned by the previous deletions
    /// - fix EventReferences whose referencedEvent was deleted by createing a stubbed Event
    static func cleanupEntities(
        before date: Date, 
        for authorKey: RawAuthorID, 
        in context: NSManagedObjectContext
    ) async throws {
        // this function was written in a hurry and probably should be refactored and tested thorougly.
        @Dependency(\.analytics) var analytics
        
        let startTime = Date.now
        Log.info("Starting Core Data cleanup...")
        
        Log.info("Database statistics: \(try await PersistenceController.databaseStatistics(from: context))")
        
        // Delete all but the most recent n events
        let eventsToKeep = 1000
        let fetchFirstEventToDelete = Event.allEventsRequest()
        fetchFirstEventToDelete.sortDescriptors = [NSSortDescriptor(keyPath: \Event.receivedAt, ascending: false)]
        fetchFirstEventToDelete.fetchLimit = 1
        fetchFirstEventToDelete.fetchOffset = eventsToKeep
        fetchFirstEventToDelete.predicate = NSPredicate(format: "receivedAt != nil")
        var deleteBefore = Date.distantPast
        try await context.perform {
            
            guard let currentAuthor = try? Author.find(by: authorKey, context: context) else {
                return
            }
            
            if let firstEventToDelete = try context.fetch(fetchFirstEventToDelete).first,
                let receivedAt = firstEventToDelete.receivedAt {
                deleteBefore = receivedAt
            }
            
            let oldStoryCutoff = Calendar.current.date(byAdding: .day, value: -2, to: .now) ?? .now
            
            // Delete events older than `deleteBefore`
            let oldEventsRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Event")
            oldEventsRequest.sortDescriptors = [NSSortDescriptor(keyPath: \Event.receivedAt, ascending: true)]
            let oldEventClause = "(receivedAt <= %@ OR receivedAt == nil)"
            let notOwnEventClause = "(author.hexadecimalPublicKey != %@)"
            let readStoryClause = "(isRead = 1 AND receivedAt > %@)"
            let userReportClause = "(kind == \(EventKind.report.rawValue) AND " +
            "authorReferences.@count > 0 AND eventReferences.@count == 0)"
            let clauses = "\(oldEventClause) AND" +
            "\(notOwnEventClause) AND " +
            "NOT \(readStoryClause) AND " +
            "NOT \(userReportClause)"
            oldEventsRequest.predicate = NSPredicate(
                format: clauses,
                deleteBefore as CVarArg,
                authorKey,
                oldStoryCutoff as CVarArg
            )
            
            let deleteRequests: [NSPersistentStoreRequest] = [
                oldEventsRequest,
                Event.expiredRequest(),
                EventReference.orphanedRequest(),
                AuthorReference.orphanedRequest(),
                Author.outOfNetwork(for: currentAuthor),
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
            
            // Heal EventReferences
            let brokenEventReferencesRequest = NSFetchRequest<EventReference>(entityName: "EventReference")
            brokenEventReferencesRequest.sortDescriptors = [
                NSSortDescriptor(keyPath: \EventReference.eventId, ascending: false)
            ]
            brokenEventReferencesRequest.predicate = NSPredicate(format: "referencedEvent = nil")
            let brokenEventReferences = try context.fetch(brokenEventReferencesRequest)
            Log.info("Healing \(brokenEventReferences.count) EventReferences")
            for eventReference in brokenEventReferences {
                guard let eventID = eventReference.eventId else {
                    Log.error("Found an EventReference with no eventID")
                    continue
                }
                let referencedEvent = try Event.findOrCreateStubBy(id: eventID, context: context)
                eventReference.referencedEvent = referencedEvent
            }
            
            try context.saveIfNeeded()
            context.refreshAllObjects()
        }
        
        let newStatistics = try await PersistenceController.databaseStatistics(from: context)
        Log.info("Database statistics: \(newStatistics)")
        analytics.databaseStatistics(newStatistics)
        
        let elapsedTime = Date.now.timeIntervalSince1970 - startTime.timeIntervalSince1970 
        Log.info("Finished Core Data cleanup in \(elapsedTime) seconds.")
    }
    // swiftlint:enable function_body_length    
}

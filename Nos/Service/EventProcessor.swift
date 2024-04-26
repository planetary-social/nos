import Foundation
import CoreData
import Logger

/// The event processor consumes raw event data from the relays and writes it to Core Data.
enum EventProcessor {
    static func parse(
        jsonEvent: JSONEvent,
        from relay: Relay?,
        in parseContext: NSManagedObjectContext,
        skipVerification: Bool = false
    ) throws -> Event? {
        if let event = try Event().createIfNecessary(jsonEvent: jsonEvent, relay: relay, context: parseContext) {
            relay.unwrap {
                do {
                    try event.trackDelete(on: $0, context: parseContext)
                } catch {
                    Log.error(error.localizedDescription)
                }
            }
        
            guard let publicKey = event.author?.publicKey else {
                throw EventError.missingAuthor
            }
            
            if skipVerification == false {
                guard try event.verifySignature(for: publicKey) else {
                    parseContext.delete(event)
                    Log.info("Invalid signature on event: \(jsonEvent) from \(relay?.address ?? "error")")
                    throw EventError.invalidSignature(event)
                }
                event.isVerified = true
            }
            
            return event
            
        // Verify that this event has been marked seen on the given relay.
        } else if let relay, 
            try parseContext.count(for: Event.event(by: jsonEvent.id, seenOn: relay)) == 0, 
            let event = Event.find(by: jsonEvent.id, context: parseContext) {
            event.markSeen(on: relay)
            try event.trackDelete(on: relay, context: parseContext)
            return nil
        }
        
        return nil
    }
    
    static func parse(jsonData: Data, from relay: Relay?, in context: NSManagedObjectContext) throws -> [Event] {
        let jsonEvents = try JSONDecoder().decode([JSONEvent].self, from: jsonData)
        var events = [Event]()
        for jsonEvent in jsonEvents {
            do {
                if let event = try parse(jsonEvent: jsonEvent, from: relay, in: context) {
                    events.append(event)
                }
            } catch {
                Log.error("Error parsing eventJSON: \(jsonEvent): \(error.localizedDescription)")
            }
        }
        
        return events
    }
    
    static func parse(
        jsonData: Data,
        from relay: Relay?,
        in persistenceController: PersistenceController
    ) throws -> [Event] {
        let parseContext = persistenceController.container.viewContext
        return try parse(jsonData: jsonData, from: relay, in: parseContext)
    }
}

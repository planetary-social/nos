import Foundation
import CoreData
import Logger

/// The event processor consumes raw event data from the relays and writes it to Core Data.
enum EventProcessor {
    @discardableResult
    static func parse(
        jsonEvent: JSONEvent,
        from relay: Relay?,
        in parseContext: NSManagedObjectContext,
        skipVerification: Bool = false
    ) throws -> Event? {
        if jsonEvent.kind == EventKind.followSet.rawValue {
            try saveFollowSet(
                jsonEvent: jsonEvent,
                relay: relay,
                parseContext: parseContext,
                skipVerification: skipVerification
            )
            return nil
        } else if let event = try Event.createIfNecessary(jsonEvent: jsonEvent, relay: relay, context: parseContext) {
            try updateEvent(
                event: event,
                jsonEvent: jsonEvent,
                relay: relay,
                parseContext: parseContext,
                skipVerification: skipVerification
            )
            return event
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
                // don't parse this event if we don't support the kind
                if EventKind(rawValue: jsonEvent.kind) != nil,
                    let event = try parse(jsonEvent: jsonEvent, from: relay, in: context) {
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
        let parseContext = persistenceController.viewContext
        return try parse(jsonData: jsonData, from: relay, in: parseContext)
    }
}

extension EventProcessor {
    private static func saveFollowSet(
        jsonEvent: JSONEvent,
        relay: Relay?,
        parseContext: NSManagedObjectContext,
        skipVerification: Bool
    ) throws {
        let authorList = try AuthorList.createOrUpdate(from: jsonEvent, in: parseContext)
        if skipVerification == false {
            guard try authorList.verifySignature() else {
                parseContext.delete(authorList)
                Log.info("Invalid signature on author list: \(jsonEvent) from \(relay?.address ?? "error")")
                throw AuthorListError.invalidSignature(authorList)
            }
            authorList.isVerified = true
        }
    }

    private static func updateEvent(
        event: Event,
        jsonEvent: JSONEvent,
        relay: Relay?,
        parseContext: NSManagedObjectContext,
        skipVerification: Bool
    ) throws {
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

        // if this is a zap receipt, pull the zap request out of the description tag and parse it as well
        if event.kind == EventKind.zapReceipt.rawValue,
            let tags = event.allTags as? [[String]],
            let descriptionTag = tags.first(where: { $0.first == "description" }),
            let zapRequestJSONData = descriptionTag.last?.data(using: .utf8) {
            let zapRequest = try JSONDecoder().decode(JSONEvent.self, from: zapRequestJSONData)
            try parse(jsonEvent: zapRequest, from: relay, in: parseContext, skipVerification: skipVerification)
        }
    }
}

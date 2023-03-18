//
//  EventProcessor.swift
//  Nos
//
//  Created by Matthew Lorentz on 2/10/23.
//

import Foundation
import CoreData

/// The event processor consumes raw event data from the relays and writes it to Core Data.
enum EventProcessor {    
    static func parse(
        jsonObject: [String: Any],
        from relay: Relay?,
        in context: NSManagedObjectContext
    ) throws -> Event {
        let jsonData = try JSONSerialization.data(withJSONObject: jsonObject)
        let jsonEvent = try JSONDecoder().decode(JSONEvent.self, from: jsonData)
        return try parse(jsonEvent: jsonEvent, from: relay, in: context)
    }
    
    static func parse(
        jsonEvent: JSONEvent,
        from relay: Relay?,
        in parseContext: NSManagedObjectContext,
        skipVerification: Bool = false
    ) throws -> Event {
        let event = try Event.findOrCreate(jsonEvent: jsonEvent, relay: relay, context: parseContext)
        
        guard let publicKey = event.author?.publicKey else {
            throw EventError.missingAuthor
        }
        
        if skipVerification == false {
            guard try publicKey.verifySignature(on: event) else {
                parseContext.delete(event)
                print("Invalid signature on event: \(jsonEvent)")
                throw EventError.invalidSignature(event)
            }
        }
        
        try parseContext.save()
        
        return event
    }
    
    static func parse(jsonData: Data, from relay: Relay?, in context: NSManagedObjectContext) throws -> [Event] {
        let jsonEvents = try JSONDecoder().decode([JSONEvent].self, from: jsonData)
        var events = [Event]()
        for jsonEvent in jsonEvents {
            do {
                let event = try parse(jsonEvent: jsonEvent, from: relay, in: context)
                events.append(event)
            } catch {
                print("Error parsing eventJSON: \(jsonEvent): \(error.localizedDescription)")
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

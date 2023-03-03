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
    static func parse(jsonObject: [String: Any], in context: NSManagedObjectContext) throws -> Event {
        let jsonData = try JSONSerialization.data(withJSONObject: jsonObject)
        let jsonEvent = try JSONDecoder().decode(JSONEvent.self, from: jsonData)
        return try parse(jsonEvent: jsonEvent, in: context)
    }
    
    static func parse(jsonEvent: JSONEvent, in parseContext: NSManagedObjectContext) throws -> Event {
        guard let event = Event.findOrCreate(jsonEvent: jsonEvent, context: parseContext) else {
            throw EventError.jsonEncoding
        }
        
        guard let publicKey = event.author?.publicKey else {
            throw EventError.missingAuthor
        }
        
        guard try publicKey.verifySignature(on: event) else {
            parseContext.delete(event)
            print("Invalid signature on event: \(jsonEvent)")
            throw EventError.invalidSignature(event)
        }
        
        try parseContext.save()
        
        return event
    }
    
    static func parse(jsonData: Data, in context: NSManagedObjectContext) throws -> [Event] {
        let jsonEvents = try JSONDecoder().decode([JSONEvent].self, from: jsonData)
        var events = [Event]()
        for jsonEvent in jsonEvents {
            do {
                let event = try parse(jsonEvent: jsonEvent, in: context)
                events.append(event)
            } catch {
                print("Error parsing eventJSON: \(jsonEvent): \(error.localizedDescription)")
            }
        }
        
        return events
    }
    
    static func parse(jsonData: Data, in persistenceController: PersistenceController) throws -> [Event] {
        let parseContext = persistenceController.container.viewContext
        return try parse(jsonData: jsonData, in: parseContext)
    }
}

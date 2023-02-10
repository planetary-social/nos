//
//  EventProcessor.swift
//  Nos
//
//  Created by Matthew Lorentz on 2/10/23.
//

import Foundation

/// The event processor consumes raw event data from the relays and writes it to Core Data.
enum EventProcessor {
    
    static func parse(jsonObject: [String: Any], in persistenceController: PersistenceController) throws -> Event {
        let jsonData = try JSONSerialization.data(withJSONObject: jsonObject)
        let jsonEvent = try JSONDecoder().decode(JSONEvent.self, from: jsonData)
        return try parse(jsonEvent: jsonEvent, in: persistenceController)
    }
    
    static func parse(jsonEvent: JSONEvent, in persistenceController: PersistenceController) throws -> Event {
        let parseContext = persistenceController.container.viewContext
        
        if let existingEvent = try parseContext.fetch(Event.event(by: jsonEvent.id)).first {
            return existingEvent
        }
        
        let event = Event(context: parseContext)
        event.createdAt = Date(timeIntervalSince1970: TimeInterval(jsonEvent.createdAt))
        event.content = jsonEvent.content
        event.identifier = jsonEvent.id
        event.kind = jsonEvent.kind
        event.signature = jsonEvent.signature
        
        let author = Author(context: parseContext)
        author.hexadecimalPublicKey = jsonEvent.pubKey
        event.author = author
        
        let tags = NSMutableOrderedSet()
        for jsonTag in jsonEvent.tags {
            let tag = Tag(context: parseContext)
            tag.identifier = jsonTag.first
            tag.metadata = Array(jsonTag[1...]) as NSObject
            tags.add(tag)
        }
        event.tags = tags
        
        return event
    }
    
    static func parse(jsonData: Data, in persistenceController: PersistenceController) throws -> [Event] {
        let parseContext = persistenceController.container.viewContext
        let jsonEvents = try JSONDecoder().decode([JSONEvent].self, from: jsonData)
        var events = [Event]()
        for jsonEvent in jsonEvents {
            let event = try parse(jsonEvent: jsonEvent, in: persistenceController)
            events.append(event)
        }
        
        try parseContext.save()
        
        return events
    }
}

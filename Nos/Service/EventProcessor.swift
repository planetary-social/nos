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
        
        let event = Event(context: parseContext, jsonEvent: jsonEvent)
        
		guard let eventKind = EventKind(rawValue: event.kind) else {
			print("Error: unrecognized event kind: \(event.kind)")
			throw EventError.unrecognizedKind
		}
		
		switch eventKind {
		case .metaData:
			if let contentData = jsonEvent.content.data(using: .utf8) {
				do {
					let metadata = try JSONDecoder().decode(MetadataEventJSON.self, from: contentData)
					
					print("!! Author before: \(event.author?.name ?? "not set")")
					if let author = event.author {
						author.name = metadata.name
						author.about = metadata.about
						author.profilePhotoURL = metadata.profilePhotoURL
						print("!! Author after: \(author.name ?? "not set")")
					}
				} catch {
					print("Failed to decode kind \(eventKind) event content with ID \(String(describing: event.identifier))")
				}
			}
		default:
			print("No action for kind: \(eventKind)")
		}
        
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

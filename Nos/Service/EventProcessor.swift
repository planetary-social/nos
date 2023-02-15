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
        
		guard let eventKind = EventKind(rawValue: jsonEvent.kind) else {
			print("Error: unrecognized event kind: \(jsonEvent.kind)")
			throw EventError.unrecognizedKind
		}
        
        guard let contentData = jsonEvent.content.data(using: .utf8) else {
            throw EventError.jsonEncoding
        }
		
		let event = Event(context: parseContext, jsonEvent: jsonEvent)
		
        switch eventKind {
        case .contactList:
			let eventFollows = NSMutableOrderedSet()
			for jsonTag in jsonEvent.tags {
				let followTag = Follow(context: parseContext)
                followTag.identifier = jsonTag[1]

                if jsonTag.count > 2 {
                    if let relay = try parseContext.fetch(Relay.relay(by: jsonTag[2])).first {
                        followTag.relay = relay
                    } else {
                        followTag.relay = Relay(context: parseContext)
                        followTag.relay?.address = jsonTag[2]
                    }
				}

                if jsonTag.count > 3 {
                    followTag.petName = jsonTag[3]
                }
                eventFollows.add(followTag)
			}
			event.tags = eventFollows
        case .metaData:
            do {
                let metadata = try JSONDecoder().decode(MetadataEventJSON.self, from: contentData)
                
                if let author = event.author {
                    author.name = metadata.name
                    author.about = metadata.about
                    author.profilePhotoURL = metadata.profilePhotoURL
                }
            } catch {
                print("Failed to decode kind \(eventKind) event with ID \(String(describing: event.identifier))")
            }
        default:
			let eventTags = NSMutableOrderedSet()
			for jsonTag in jsonEvent.tags {
				let tag = Tag(context: parseContext)
				tag.identifier = jsonTag.first
				tag.metadata = Array(jsonTag[1...]) as NSObject
				eventTags.add(tag)
			}
			event.tags = eventTags
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

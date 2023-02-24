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
		guard let eventKind = EventKind(rawValue: jsonEvent.kind) else {
			print("Error: unrecognized event kind: \(jsonEvent.kind)")
			throw EventError.unrecognizedKind
		}
        
        let parseContext = persistenceController.container.viewContext

        // Retain an existing event so we can modify it as needed with new data
        let event = Event.findOrCreate(jsonEvent: jsonEvent, context: parseContext)
        
        guard let publicKey = event.author?.publicKey else {
            throw EventError.missingAuthor
        }
        
        switch eventKind {
        case .contactList:
            let eventFollows = NSMutableOrderedSet()
            for jsonTag in jsonEvent.tags {
                eventFollows.add(Follow(context: parseContext, jsonTag: jsonTag))
            }
            event.tags = eventFollows
            
            // In the special case that we've requested our own follows, set it on the profile
            if let author = event.author, author.hexadecimalPublicKey == CurrentUser.publicKey {
                CurrentUser.follows = eventFollows.array as? [Follow]
                CurrentUser.refresh()
            }

        case .metaData:
            if let contentData = jsonEvent.content.data(using: .utf8) {
                do {
                    let metadata = try JSONDecoder().decode(MetadataEventJSON.self, from: contentData)
                    
                    // Every event has an author created, so it just needs to be populated
                    if let author = event.author {
                        author.name = metadata.name
                        author.displayName = metadata.displayName
                        author.about = metadata.about
                        author.profilePhotoURL = metadata.profilePhotoURL
                    }
                } catch {
                    print("Failed to decode kind \(eventKind) event with ID \(String(describing: event.identifier))")
                }
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
        
        guard try publicKey.verifySignature(on: event) else {
            parseContext.delete(event)
            print("Invalid signature on event: \(jsonEvent)")
            throw EventError.invalidSignature(event)
        }
        
        return event
    }
    
    static func parse(jsonData: Data, in persistenceController: PersistenceController) throws -> [Event] {
        let parseContext = persistenceController.container.viewContext
        let jsonEvents = try JSONDecoder().decode([JSONEvent].self, from: jsonData)
        var events = [Event]()
        for jsonEvent in jsonEvents {
            do {
                let event = try parse(jsonEvent: jsonEvent, in: persistenceController)
                events.append(event)
            } catch {
                print("Error parsing eventJSON: \(jsonEvent): \(error.localizedDescription)")
            }
        }
        
        try parseContext.save()
        
        return events
    }
}

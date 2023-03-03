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
    
    // swiftlint:disable function_body_length
    static func parse(jsonEvent: JSONEvent, in parseContext: NSManagedObjectContext) throws -> Event {
		guard let eventKind = EventKind(rawValue: jsonEvent.kind) else {
			print("Error: unrecognized event kind: \(jsonEvent.kind)")
			throw EventError.unrecognizedKind
		}

        // Retain an existing event so we can modify it as needed with new data
        let event = Event.findOrCreate(jsonEvent: jsonEvent, context: parseContext)
        
        guard let publicKey = event.author?.publicKey else {
            throw EventError.missingAuthor
        }
        
        event.allTags = jsonEvent.tags as NSObject
        
        switch eventKind {
        case .contactList:
            var eventFollows = Set<Follow>()
            for jsonTag in jsonEvent.tags {
                do {
                    eventFollows.insert(try Follow.upsert(by: event.author!, jsonTag: jsonTag, context: parseContext))
                } catch {
                    print("could not parse Follow from: \(jsonEvent)")
                }
            }
            
            // TODO: we need to delete Follows for keys that were removed from the follow list here
            
            // In the special case that we've requested our own follows, set it on the profile
            if let author = event.author, author.hexadecimalPublicKey == CurrentUser.publicKey {
                CurrentUser.follows = eventFollows
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
            let eventReferences = NSMutableOrderedSet()
            let authorReferences = NSMutableOrderedSet()
            for jsonTag in jsonEvent.tags {
                if jsonTag.first == "e" {
                    let eTag = EventReference(context: parseContext)
                    eTag.eventId = jsonTag[safe: 1]
                    eTag.recommendedRelayUrl = jsonTag[safe: 2]
                    eTag.marker = jsonTag[safe: 3]
                    eventReferences.add(eTag)
                } else {
                    let authorReference = AuthorReference(context: parseContext)
                    authorReference.pubkey = jsonTag[safe: 1]
                    authorReference.recommendedRelayUrl = jsonTag[safe: 2]
                }
            }
            event.eventReferences = eventReferences
            event.authorReferences = authorReferences
        }
        
        guard try publicKey.verifySignature(on: event) else {
            parseContext.delete(event)
            print("Invalid signature on event: \(jsonEvent)")
            throw EventError.invalidSignature(event)
        }
        
        try parseContext.save()
        
        return event
    }
    // swiftlint:enable function_body_length
    
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

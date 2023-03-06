//
//  Event+CoreDataClass.swift
//  Nos
//
//  Created by Matthew Lorentz on 1/31/23.
//
//

import Foundation
import CoreData

enum EventError: Error {
	case jsonEncoding
	case utf8Encoding
	case unrecognizedKind
    case missingAuthor
    case invalidSignature(Event)
    
    var description: String? {
        switch self {
        case .unrecognizedKind:
            return "Unrecognized event kind"
        case .missingAuthor:
            return "Could not parse author on event"
        case .invalidSignature(let event):
            return "Invalid signature on event: \(String(describing: event.identifier))"
        default:
            return ""
        }
	}
}

public enum EventKind: Int64, CaseIterable {
	case metaData = 0
	case text = 1
	case contactList = 3
	case directMessage = 4
	case delete = 5
	case boost = 6
	case like = 7
    case channelMessage = 42
    case parameterizedReplaceableEvent = 30_000
}

@objc(Event)
public class Event: NosManagedObject {
    
    static var replyEventReferences =
    "kind = 1 AND SUBQUERY(eventReferences, $reference, $reference.eventId == %@).@count > 0"
    
    @nonobjc public class func allEventsRequest() -> NSFetchRequest<Event> {
        let fetchRequest = NSFetchRequest<Event>(entityName: "Event")
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \Event.createdAt, ascending: true)]
        return fetchRequest
    }
    
    /// The userId mapped to an array of strings witn information of the user
    static let discoverTabUserIdToInfo: [String: [String]] = [
        "npub1sg6plzptd64u62a878hep2kev88swjh3tw00gjsfl8f237lmu63q0uf63m": ["Jack Dorsey"],
        "npub1g53mukxnjkcmr94fhryzkqutdz2ukq4ks0gvy5af25rgmwsl4ngq43drvk": ["Martti Malmi/sirius"],
        "npub19mun7qwdyjf7qs3456u8kyxncjn5u2n7klpu4utgy68k4aenzj6synjnft": ["Unclebobmartin"],
        "npub1qlkwmzmrhzpuak7c2g9akvcrh7wzkd7zc7fpefw9najwpau662nqealf5y": ["Katie"],
        "npub176ar97pxz4t0t5twdv8psw0xa45d207elwauu5p93an0rfs709js4600cg": ["arjwright"],
        "npub1nstrcu63lzpjkz94djajuz2evrgu2psd66cwgc0gz0c0qazezx0q9urg5l": ["nostrica"]
    ]
    
    @nonobjc public class func discoverFeedRequest() -> NSFetchRequest<Event> {
        let fetchRequest = NSFetchRequest<Event>(entityName: "Event")
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \Event.createdAt, ascending: false)]
        let kind = EventKind.text.rawValue
        let followersPredicate = NSPredicate(
            format: "kind = %i AND eventReferences.@count = 0 AND author.hexadecimalPublicKey IN %@",
            kind,
            Array(Event.discoverTabUserIdToInfo.keys).compactMap {
                PublicKey(npub: $0)?.hex
            }
        )

            fetchRequest.predicate = followersPredicate
        
        return fetchRequest
    }
    
	@nonobjc public class func allPostsRequest(_ eventKind: EventKind = .text) -> NSFetchRequest<Event> {
        let fetchRequest = NSFetchRequest<Event>(entityName: "Event")
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \Event.createdAt, ascending: false)]
		fetchRequest.predicate = NSPredicate(format: "kind = %i", eventKind.rawValue)
        return fetchRequest
    }
    
    @nonobjc public class func allReplies(to rootEvent: Event) -> NSFetchRequest<Event> {
        let fetchRequest = NSFetchRequest<Event>(entityName: "Event")
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \Event.createdAt, ascending: false)]
        fetchRequest.predicate = NSPredicate(
            format: replyEventReferences,
            rootEvent.identifier ?? ""
        )
        return fetchRequest
    }
    
    @nonobjc public class func event(by identifier: String) -> NSFetchRequest<Event> {
        let fetchRequest = NSFetchRequest<Event>(entityName: "Event")
        fetchRequest.predicate = NSPredicate(format: "identifier = %@", identifier)
        fetchRequest.fetchLimit = 1
        return fetchRequest
    }
    
    @nonobjc public class func homeFeed(for user: Author) -> NSFetchRequest<Event> {
        let fetchRequest = NSFetchRequest<Event>(entityName: "Event")
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \Event.createdAt, ascending: false)]
        let kind = EventKind.text.rawValue
        let followersPredicate = NSPredicate(format: "kind = %i AND ANY author.followers.source = %@", kind, user)
        if let publicKey = user.publicKey?.hex {
            let currentUserPredicate = NSPredicate(
                format: "kind = %i AND author.hexadecimalPublicKey = %@", kind, publicKey
            )
            let compoundPredicate = NSCompoundPredicate(
                orPredicateWithSubpredicates:
                    [followersPredicate, currentUserPredicate]
            )
            fetchRequest.predicate = compoundPredicate
        } else {
            fetchRequest.predicate = followersPredicate
        }
        return fetchRequest
    }
    
    @nonobjc public class func allFollowedPostsRequest(from publicKeys: [String]) -> NSFetchRequest<Event> {
        let fetchRequest = NSFetchRequest<Event>(entityName: "Event")
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \Event.createdAt, ascending: false)]
        let kind = EventKind.text.rawValue
        let predicate = NSPredicate(format: "kind = %i AND author.hexadecimalPublicKey IN %@", kind, publicKeys)
        fetchRequest.predicate = predicate
        return fetchRequest
    }
    
    @nonobjc public class func emptyRequest() -> NSFetchRequest<Event> {
        let fetchRequest = NSFetchRequest<Event>(entityName: "Event")
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \Event.createdAt, ascending: true)]
        fetchRequest.predicate = NSPredicate(format: "FALSEPREDICATE")
        return fetchRequest
    }
    
    @nonobjc public class func deleteAllEvents() -> NSBatchDeleteRequest {
        let fetchRequest: NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: "Event")
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
        return deleteRequest
    }
    
    @nonobjc public class func deleteAllPosts(by author: Author) -> NSBatchDeleteRequest {
        let fetchRequest: NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: "Event")
        let kind = EventKind.text.rawValue
        let key = author.hexadecimalPublicKey ?? "notakey"
        fetchRequest.predicate = NSPredicate(format: "kind = %i AND author.hexadecimalPublicKey = %@", kind, key)
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
        return deleteRequest
    }
    
    @nonobjc public class func contactListRequest(_ author: Author) -> NSFetchRequest<Event> {
        let fetchRequest = NSFetchRequest<Event>(entityName: "Event")
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \Event.createdAt, ascending: false)]
        let kind = EventKind.contactList.rawValue
        let key = author.hexadecimalPublicKey ?? "notakey"
        fetchRequest.predicate = NSPredicate(format: "kind = %i AND author.hexadecimalPublicKey = %@", kind, key)
        return fetchRequest
    }
    
    class func findOrCreate(jsonEvent: JSONEvent, context: NSManagedObjectContext) -> Event? {
        if let existingEvent = try? context.fetch(Event.event(by: jsonEvent.id)).first {
            return existingEvent
        } else {
            return try? Event(context: context, jsonEvent: jsonEvent)
        }
    }
    
    var serializedEventForSigning: [Any?] {
        [
            0,
            author?.hexadecimalPublicKey,
            Int64(createdAt!.timeIntervalSince1970),
            kind,
            allTags,
            content
        ]
    }
    
    func calculateIdentifier() throws -> String {
        let serializedEventData = try JSONSerialization.data(
            withJSONObject: serializedEventForSigning,
            options: [.withoutEscapingSlashes]
        )
        return serializedEventData.sha256
    }
    
    func sign(withKey privateKey: KeyPair) throws {
        if allTags == nil {
            allTags = [] as NSObject
        }
        identifier = try calculateIdentifier()
        var serializedBytes = try identifier!.bytes
        signature = try privateKey.sign(bytes: &serializedBytes)
    }
    
    var jsonRepresentation: [String: Any]? {
        if let jsonEvent = codable {
            do {
                let data = try JSONEncoder().encode(jsonEvent)
                return try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
            } catch {
                print("Error encoding event as JSON: \(error.localizedDescription)\n\(self)")
            }
        }
        
        return nil
    }
    
    var codable: JSONEvent? {
        guard let identifier = identifier,
            let pubKey = author?.hexadecimalPublicKey,
            let createdAt = createdAt,
            let content = content,
            let signature = signature else {
            return nil
        }
                           
        let allTags = (allTags as? [[String]]) ?? []
            
        return JSONEvent(
            id: identifier,
            pubKey: pubKey,
            createdAt: Int64(createdAt.timeIntervalSince1970),
            kind: kind,
            tags: allTags,
            content: content,
            signature: signature
        )
    }
	
    // swiftlint:disable function_body_length
	convenience init(context: NSManagedObjectContext, jsonEvent: JSONEvent) throws {
		self.init(context: context)
		
		// Meta data
		createdAt = Date(timeIntervalSince1970: TimeInterval(jsonEvent.createdAt))
		content = jsonEvent.content
		identifier = jsonEvent.id
		kind = jsonEvent.kind
		signature = jsonEvent.signature
        
        // Tags
        allTags = jsonEvent.tags as NSObject
        
		// Author
        guard let newAuthor = try? Author.findOrCreate(by: jsonEvent.pubKey, context: context) else {
            throw EventError.missingAuthor
        }
        
        author = newAuthor
        newAuthor.lastUpdated = Date.now

        print("\(author!.hexadecimalPublicKey!) last updated \(author!.lastUpdated!)")

        guard let eventKind = EventKind(rawValue: kind) else {
            throw EventError.unrecognizedKind
        }

        switch eventKind {
        case .contactList:
            // Make a copy of what was followed before
            let originalFollows = newAuthor.follows?.copy() as? Set<Follow>
            
            var eventFollows = Set<Follow>()
            for jsonTag in jsonEvent.tags {
                do {
                    eventFollows.insert(try Follow.upsert(by: newAuthor, jsonTag: jsonTag, context: context))
                } catch {
                    print("Error: could not parse Follow from: \(jsonEvent)")
                }
            }
            
            // Did we unfollow someone? If so, remove them from core data
            if let follows = originalFollows, follows.count > eventFollows.count {
                let removedFollows = follows.subtracting(eventFollows)
                if !removedFollows.isEmpty {
                    print("Removing \(removedFollows.count) follows")
                    Follow.deleteFollows(in: removedFollows, context: context)
                }
            }

            // In the special case that we've requested our own follows, set it on the profile
            if newAuthor.hexadecimalPublicKey == CurrentUser.publicKey {
                CurrentUser.follows = eventFollows
            }

        case .metaData:
            if let contentData = jsonEvent.content.data(using: .utf8) {
                do {
                    let metadata = try JSONDecoder().decode(MetadataEventJSON.self, from: contentData)
                    
                    // Every event has an author created, so it just needs to be populated
                    newAuthor.name = metadata.name
                    newAuthor.displayName = metadata.displayName
                    newAuthor.about = metadata.about
                    newAuthor.profilePhotoURL = metadata.profilePhotoURL
                } catch {
                    print("Failed to decode kind \(eventKind) event with ID \(String(describing: identifier))")
                }
            }

        default:
            let newEventReferences = NSMutableOrderedSet()
            let newAuthorReferences = NSMutableOrderedSet()
            for jsonTag in jsonEvent.tags {
                if jsonTag.first == "e" {
                    let eTag = EventReference(context: context)
                    eTag.eventId = jsonTag[safe: 1]
                    eTag.recommendedRelayUrl = jsonTag[safe: 2]
                    eTag.marker = jsonTag[safe: 3]
                    newEventReferences.add(eTag)
                } else {
                    let authorReference = AuthorReference(context: context)
                    authorReference.pubkey = jsonTag[safe: 1]
                    authorReference.recommendedRelayUrl = jsonTag[safe: 2]
                    newAuthorReferences.add(authorReference)
                }
            }
            eventReferences = newEventReferences
            authorReferences = newAuthorReferences
        }
	}
    // swiftlint:enable function_body_length
    
    class func all(context: NSManagedObjectContext) -> [Event] {
        let allRequest = Event.allPostsRequest()
        
        do {
            let results = try context.fetch(allRequest)
            return results
        } catch let error as NSError {
            print("Failed to fetch events. Error: \(error.description)")
            return []
        }
    }
    
    class func deleteAll(context: NSManagedObjectContext) {
        let deleteRequest = Event.deleteAllEvents()
        
        do {
            try context.execute(deleteRequest)
        } catch let error as NSError {
            print("Failed to delete events. Error: \(error.description)")
        }
    }
}

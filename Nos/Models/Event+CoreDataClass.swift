//
//  Event+CoreDataClass.swift
//  Nos
//
//  Created by Matthew Lorentz on 1/31/23.
//
//

import Foundation
import CoreData
import secp256k1
import CryptoKit
import CommonCrypto

struct JSONEvent: Codable {
    var id: String
    var pubKey: String
    var createdAt: Int64
    var kind: Int64
    var tags: [[String]]
    var content: String
    var signature: String
    
    enum CodingKeys: String, CodingKey {
        case id
        case pubKey = "pubkey"
        case createdAt = "created_at"
        case kind
        case tags
        case content
        case signature = "sig"
    }
}

enum EventError: Error {
    case jsonEncoding
    case utf8Encoding
}

@objc(Event)
public class Event: NosManagedObject {
    
    @nonobjc public class func allEventsRequest() -> NSFetchRequest<Event> {
        let fetchRequest = NSFetchRequest<Event>(entityName: "Event")
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \Event.createdAt, ascending: true)]
        return fetchRequest
    }
    
    @nonobjc public class func allPostsRequest() -> NSFetchRequest<Event> {
        let fetchRequest = NSFetchRequest<Event>(entityName: "Event")
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \Event.createdAt, ascending: false)]
        fetchRequest.predicate = NSPredicate(format: "kind = %i", 1)
        return fetchRequest
    }
    
    @nonobjc public class func event(by identifier: String) -> NSFetchRequest<Event> {
        let fetchRequest = NSFetchRequest<Event>(entityName: "Event")
        fetchRequest.predicate = NSPredicate(format: "identifier = %@", identifier)
        fetchRequest.fetchLimit = 1
        return fetchRequest
    }
    
    class func parse(jsonObject: [String: Any], in persistenceController: PersistenceController) throws -> Event {
        let jsonData = try JSONSerialization.data(withJSONObject: jsonObject)
        let jsonEvent = try JSONDecoder().decode(JSONEvent.self, from: jsonData)
        return try parse(jsonEvent: jsonEvent, in: persistenceController)
    }
    
    class func parse(jsonEvent: JSONEvent, in persistenceController: PersistenceController) throws -> Event {
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
    
    class func parse(jsonData: Data, in persistenceController: PersistenceController) throws -> [Event] {
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
    
    var serializedEventForSigning: [Any?] {
        [
            0,
            author?.hexadecimalPublicKey,
            Int64(createdAt!.timeIntervalSince1970),
            kind,
            tagsJSONRepresentation,
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
        identifier = try calculateIdentifier()
        var serializedBytes = try identifier!.bytes
        signature = try privateKey.sign(bytes: &serializedBytes)
    }
    
    var tagsJSONRepresentation: [[String]] {
        (tags?.array as? [Tag])?.map { $0.jsonRepresentation } ?? []
    }
    
    var jsonRepresentation: [String: Any]? {
        guard let identifier = identifier,
            let pubKey = author?.hexadecimalPublicKey,
            let createdAt = createdAt,
            let content = content,
            let signature = signature else {
            return nil
        }
              
        return [
            "id": identifier,
            "pubkey": pubKey,
            "created_at": Int64(createdAt.timeIntervalSince1970),
            "kind": kind,
            "tags": tagsJSONRepresentation,
            "content": content,
            "sig": signature
        ]
    }
}

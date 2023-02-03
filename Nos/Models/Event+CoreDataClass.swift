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
    var sig: String
    
    enum CodingKeys: String, CodingKey {
        case id
        case pubKey = "pubkey"
        case createdAt = "created_at"
        case kind
        case tags
        case content
        case sig
    }
}

@objc(Event)
public class Event: NSManagedObject {
    
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
        
        let event = Event(entity: NSEntityDescription.entity(forEntityName: "Event", in: parseContext)!, insertInto: parseContext)
        event.createdAt = Date(timeIntervalSince1970: TimeInterval(jsonEvent.createdAt))
        event.content = jsonEvent.content
        event.identifier = jsonEvent.id
        event.kind = jsonEvent.kind
        event.signature = jsonEvent.sig
        
        let author = PubKey(entity: NSEntityDescription.entity(forEntityName: "PubKey", in: parseContext)!, insertInto: parseContext)
        author.hex = jsonEvent.pubKey
        event.author = author
        
        let tags = NSMutableOrderedSet()
        for jsonTag in jsonEvent.tags {
            let tag = Tag(entity: NSEntityDescription.entity(forEntityName: "Tag", in: parseContext)!, insertInto: parseContext)
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
        return [
            0,
            author?.hex,
            Int64(createdAt!.timeIntervalSince1970),
            kind,
            tagsJSONRepresentation,
            content
        ]
    }
    
    func calculateIdentifier() throws -> String {
        let serializedEventData = try JSONSerialization.data(withJSONObject: serializedEventForSigning, options: [.withoutEscapingSlashes])
        return serializedEventData.sha256
    }
    
    func sign(withKey privateKeyString: String) throws {
        let privateKeyBytes = try privateKeyString.bytes
        let privateKey = try secp256k1.Signing.PrivateKey(rawRepresentation: privateKeyBytes)
        
        var randomBytes = [Int8](repeating: 0, count: 64)
        guard
            SecRandomCopyBytes(kSecRandomDefault, randomBytes.count, &randomBytes) == errSecSuccess
        else {
            fatalError("can't copy secure random data")
        }
        
        identifier = try calculateIdentifier()
        var serializedBytes = try identifier!.bytes
        let rawSignature = try privateKey.schnorr.signature(message: &serializedBytes, auxiliaryRand: &randomBytes)
        signature = rawSignature.rawRepresentation.hexString
    }
    
    var tagsJSONRepresentation: [[String]] {
        (tags?.array as? [Tag])?.map { $0.jsonRepresentation } ?? []
    }
    
    var jsonRepresentation: [String: Any]? {
        guard let identifier = identifier,
              let pubKey = author?.hex,
              let createdAt = createdAt,
              
              let content = content,
              let sig = signature else {
            return nil
        }
              
        return [
            "id": identifier,
            "pubkey": pubKey,
            "created_at": Int64(createdAt.timeIntervalSince1970),
            "kind": kind,
            "tags": tagsJSONRepresentation,
            "content": content,
            "sig": sig
        ]
    }
}

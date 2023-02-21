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
	case unrecognizedKind
	
	var description: String? {
		switch self {
		case .unrecognizedKind:
			return "Unrecognized event kind"
		default:
			return ""
		}
	}
}

public enum EventKind: Int64 {
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

struct MetadataEventJSON: Codable {
    var display_name: String?
    var name: String?
    var about: String?
    var picture: String?
    
    var profilePhotoURL: URL? {
        URL(string: picture ?? "")
    }
}

@objc(Event)
public class Event: NosManagedObject {
    
    @nonobjc public class func allEventsRequest() -> NSFetchRequest<Event> {
        let fetchRequest = NSFetchRequest<Event>(entityName: "Event")
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \Event.createdAt, ascending: true)]
        return fetchRequest
    }
    
	@nonobjc public class func allPostsRequest(_ eventKind: EventKind = .text) -> NSFetchRequest<Event> {
        let fetchRequest = NSFetchRequest<Event>(entityName: "Event")
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \Event.createdAt, ascending: false)]
		fetchRequest.predicate = NSPredicate(format: "kind = %i", eventKind.rawValue)
        return fetchRequest
    }
    
    @nonobjc public class func followedPostsRequest(_ eventKind: EventKind = .text) -> NSFetchRequest<Event> {
        let fetchRequest = NSFetchRequest<Event>(entityName: "Event")
        let authors = Profile.follows?.map { $0.event?.author?.hexadecimalPublicKey } ?? []
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \Event.createdAt, ascending: false)]
        let kind = eventKind.rawValue
        fetchRequest.predicate = NSPredicate(format: "kind = %i AND author.hexadecimalPublicKey IN %@", kind, authors)
        return fetchRequest
    }
    
    @nonobjc public class func event(by identifier: String) -> NSFetchRequest<Event> {
        let fetchRequest = NSFetchRequest<Event>(entityName: "Event")
        fetchRequest.predicate = NSPredicate(format: "identifier = %@", identifier)
        fetchRequest.fetchLimit = 1
        return fetchRequest
    }
    
    class func findOrCreate(jsonEvent: JSONEvent, context: NSManagedObjectContext) -> Event {
        if let existingEvent = try? context.fetch(Event.event(by: jsonEvent.id)).first {
            return existingEvent
        } else {
            return Event(context: context, jsonEvent: jsonEvent)
        }
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
	
	convenience init(context: NSManagedObjectContext, jsonEvent: JSONEvent) {
		self.init(context: context)
		
		// Meta data
		createdAt = Date(timeIntervalSince1970: TimeInterval(jsonEvent.createdAt))
		content = jsonEvent.content
		identifier = jsonEvent.id
		kind = jsonEvent.kind
		signature = jsonEvent.signature
		
		// Author
		author = try? Author.findOrCreate(by: jsonEvent.pubKey, context: context)
	}
}

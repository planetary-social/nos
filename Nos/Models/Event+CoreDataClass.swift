//
//  Event+CoreDataClass.swift
//  Nos
//
//  Created by Matthew Lorentz on 1/31/23.
//
//

import Foundation
import CoreData

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
        let event = Event(entity: NSEntityDescription.entity(forEntityName: "Event", in: parseContext)!, insertInto: parseContext)
        event.createdAt = Date(timeIntervalSince1970: TimeInterval(jsonEvent.createdAt))
        event.content = jsonEvent.content
        event.identifier = jsonEvent.id
        event.kind = jsonEvent.kind
        event.signature = jsonEvent.sig
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
}

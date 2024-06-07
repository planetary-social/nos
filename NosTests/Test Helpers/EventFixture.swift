import Foundation
import CoreData

enum EventFixture {
    
    /// Builds an event with sensible defaults. Just pass the values you need to specify.
    static func build(
        in context: NSManagedObjectContext,
        publicKey: RawAuthorID = KeyFixture.pubKeyHex,
        content: String = UUID().uuidString,
        createdAt: Date = Date(timeIntervalSince1970: TimeInterval(1_675_264_762)),
        receivedAt: Date = .now,
        tags: [[String]]? = [],
        deletedOn: Set<Relay> = []
    ) throws -> Event {
        let event = Event(context: context)
        event.createdAt = createdAt
        event.receivedAt = receivedAt
        event.content = content
        event.kind = 1
        event.allTags = tags as? NSObject
        
        let author = try Author.findOrCreate(by: publicKey, context: context)
        event.author = author
        
        event.identifier = try event.calculateIdentifier()
        
        event.deletedOn = deletedOn
        
        return event
    }
}

//
//  Event+CoreDataClass.swift
//  Nos
//
//  Created by Matthew Lorentz on 1/31/23.
//
//

// swiftlint:disable file_length
import Foundation
import CoreData
import RegexBuilder
import SwiftUI
import Logger

enum EventError: Error {
	case jsonEncoding
	case utf8Encoding
	case unrecognizedKind
    case missingAuthor
    case invalidETag([String])
    case invalidSignature(Event)
    
    var description: String? {
        switch self {
        case .unrecognizedKind:
            return "Unrecognized event kind"
        case .missingAuthor:
            return "Could not parse author on event"
        case .invalidETag(let strings):
            return "Invalid e tag \(strings.joined(separator: ","))"
        case .invalidSignature(let event):
            return "Invalid signature on event: \(String(describing: event.identifier))"
        default:
            return ""
        }
	}
}

public enum EventKind: Int64, CaseIterable, Hashable {
	case metaData = 0
	case text = 1
	case contactList = 3
	case directMessage = 4
	case delete = 5
	case boost = 6
	case like = 7
    case channelMessage = 42
    case mute = 10_000
    case parameterizedReplaceableEvent = 30_000
}

extension FetchedResults where Element == Event {
    var unmuted: [Event] {
        filter {
            if let author = $0.author {
                let notDeleted = ($0.deletedOn?.count ?? 0) == 0
                return !author.muted && notDeleted
            }
            return false
        }
    }
}

// swiftlint:disable type_body_length
@objc(Event)
public class Event: NosManagedObject {
    
    static var replyNoteReferences = "kind = 1 AND ANY eventReferences.referencedEvent.identifier == %@ " +
        "AND author.muted == false"
    
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
        "npub1nstrcu63lzpjkz94djajuz2evrgu2psd66cwgc0gz0c0qazezx0q9urg5l": ["nostrica"],
        "npub1pez4lttr28mhfdzx3047wt4j7qzgkh2asjuxa6626rzdrkk39ggqe0xdvg": ["Daniel Onren Latorre"],
        "npub14ps5krdd2wezq4kytmzv3t5rt6p4hl5tx6ecqfdxt5y0kchm5rtsva57gc": ["Martin"],
        "npub1uaajg6r8hfgh9c3vpzm2m5w8mcgynh5e0tf0um4q5dfpx8u6p6dqmj87z6": ["Chardot"],
        "npub1uucu5snurqze6enrdh06am432qftctdnehf8h8jv4hjs27nwstkshxatty": ["boreq"],
        "npub1wmr34t36fy03m8hvgl96zl3znndyzyaqhwmwdtshwmtkg03fetaqhjg240": ["rabble"],
        "npub16zsllwrkrwt5emz2805vhjewj6nsjrw0ge0latyrn2jv5gxf5k0q5l92l7": ["Matt Lorentz"],
        "npub1lur3ft9rk43fmjd2skwefz0jxlhfj0nyz3zjfkxwe3y8xlf5r6nquat0xg": ["Shaina Dane"],
        "npub1xdtducdnjerex88gkg2qk2atsdlqsyxqaag4h05jmcpyspqt30wscmntxy": ["brugeman"],
        "npub1sn0wdenkukak0d9dfczzeacvhkrgz92ak56egt7vdgzn8pv2wfqqhrjdv9": ["Edward Snowden"],
        "npub12ye6p9r6h6qpg3wrfch4v9gas6g0g7y6knrkxf6mzstxuax9sv8sdxrdku": ["Heather Everdeen"],
        "npub1pvgcusxk7006hvtlyx555erhq8c5pk9svw57snlxujpkgnkup89sekdx8c": ["Pam"],
    ]
    
    @nonobjc public class func allPostsRequest(_ eventKind: EventKind = .text) -> NSFetchRequest<Event> {
        let fetchRequest = NSFetchRequest<Event>(entityName: "Event")
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \Event.createdAt, ascending: false)]
        fetchRequest.predicate = NSPredicate(format: "kind = %i", eventKind.rawValue)
        return fetchRequest
    }
    
    @nonobjc public class func emptyDiscoverRequest() -> NSFetchRequest<Event> {
        let fetchRequest = NSFetchRequest<Event>(entityName: "Event")
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \Event.createdAt, ascending: false)]
        fetchRequest.fetchLimit = 200
        fetchRequest.predicate = NSPredicate.false
        return fetchRequest
    }
    
    @MainActor @nonobjc public class func extendedNetworkPredicate(featuredAuthors: [String]) -> NSPredicate {
        guard let currentUser = CurrentUser.shared.author else {
            return NSPredicate.false
        }
        let kind = EventKind.text.rawValue
        let featuredPredicate = NSPredicate(
            format: "kind = %i AND eventReferences.@count = 0 AND author.hexadecimalPublicKey IN %@ " +
                "AND NOT author IN %@.follows.destination",
            kind,
            featuredAuthors.compactMap {
                PublicKey(npub: $0)?.hex
            },
            currentUser
        )
            
        let twoHopsPredicate = NSPredicate(
            format: "kind = %i AND eventReferences.@count = 0 " +
                "AND ANY author.followers.source IN %@.follows.destination AND NOT author IN %@.follows.destination",
            kind,
            currentUser,
            currentUser
        )

        return NSCompoundPredicate(orPredicateWithSubpredicates: [
            featuredPredicate,
            twoHopsPredicate
        ])
    }
    
    @nonobjc public class func seen(on relay: Relay) -> NSPredicate {
        let kind = EventKind.text.rawValue
        return NSPredicate(format: "kind = %i AND eventReferences.@count = 0 AND %@ IN seenOnRelays", kind, relay)
    }
    
    @nonobjc public class func allMentionsPredicate(for user: Author) -> NSPredicate {
        guard let publicKey = user.hexadecimalPublicKey, !publicKey.isEmpty else {
            return NSPredicate.false
        }
        
        return NSPredicate(
            format: "kind = %i AND ANY authorReferences.pubkey = %@",
            EventKind.text.rawValue,
            publicKey
        )
    }

    @nonobjc public class func unpublishedEventsRequest() -> NSFetchRequest<Event> {
        let fetchRequest = NSFetchRequest<Event>(entityName: "Event")
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \Event.createdAt, ascending: false)]
        fetchRequest.predicate = NSPredicate(format: "author.hexadecimalPublicKey = %@ AND " +
            "SUBQUERY(shouldBePublishedTo, $relay, TRUEPREDICATE).@count != " +
            "SUBQUERY(seenOnRelays, $relay, TRUEPREDICATE).@count"
        )
        return fetchRequest
    }
    
    @nonobjc public class func allRepliesPredicate(for user: Author) -> NSPredicate {
        NSPredicate(format: "kind = 1 AND ANY eventReferences.referencedEvent.author = %@", user)
    }
    
    @nonobjc public class func allNotifications(for user: Author) -> NSFetchRequest<Event> {
        let fetchRequest = NSFetchRequest<Event>(entityName: "Event")
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \Event.createdAt, ascending: false)]
        
        let mentionsPredicate = allMentionsPredicate(for: user)
        let repliesPredicate = allRepliesPredicate(for: user)
        let notSelfPredicate = NSPredicate(format: "author != %@", user)
        let allNotificationsPredicate = NSCompoundPredicate(
            orPredicateWithSubpredicates: [mentionsPredicate, repliesPredicate]
        )
        fetchRequest.predicate = NSCompoundPredicate(
            andPredicateWithSubpredicates: [allNotificationsPredicate, notSelfPredicate]
        )
        
        return fetchRequest
    }
    
    @nonobjc public class func allReplies(to rootEvent: Event) -> NSFetchRequest<Event> {
        allReplies(toNoteWith: rootEvent.identifier)
    }
        
    @nonobjc public class func allReplies(toNoteWith noteID: String?) -> NSFetchRequest<Event> {
        guard let noteID else {
            return emptyRequest()
        }
        let fetchRequest = NSFetchRequest<Event>(entityName: "Event")
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \Event.createdAt, ascending: false)]
        fetchRequest.predicate = NSPredicate(
            format: replyNoteReferences,
            noteID
        )
        return fetchRequest
    }
    
    @MainActor @nonobjc public class func allReplies(toEventWith id: String) -> NSFetchRequest<Event> {
        guard let currentUser = CurrentUser.shared.author else {
            return emptyRequest()
        }
        let fetchRequest = NSFetchRequest<Event>(entityName: "Event")
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \Event.createdAt, ascending: false)]
        fetchRequest.predicate = NSPredicate(
            format: replyNoteReferences,
            id,
            currentUser,
            currentUser,
            currentUser
        )
        return fetchRequest
    }
    
    @nonobjc public class func event(by identifier: String) -> NSFetchRequest<Event> {
        let fetchRequest = NSFetchRequest<Event>(entityName: "Event")
        fetchRequest.predicate = NSPredicate(format: "identifier = %@", identifier)
        fetchRequest.fetchLimit = 1
        return fetchRequest
    }
    
    @nonobjc public class func homeFeedPredicate(for user: Author) -> NSPredicate {
        NSPredicate(
            // swiftlint:disable line_length
            format: "kind = 1 AND SUBQUERY(eventReferences, $reference, $reference.marker = 'root' OR $reference.marker = 'reply' OR $reference.marker = nil).@count = 0 AND (ANY author.followers.source = %@ OR author = %@)",
            // swiftlint:enable line_length
            user,
            user
        )
    }
    
    @nonobjc public class func homeFeed(for user: Author) -> NSFetchRequest<Event> {
        let fetchRequest = NSFetchRequest<Event>(entityName: "Event")
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \Event.createdAt, ascending: false)]
        let homeFeedPredicate = homeFeedPredicate(for: user)
        fetchRequest.predicate = homeFeedPredicate
        return fetchRequest
    }
    
    @nonobjc public class func noteIsLikedByUser(for userPubKey: String, noteId: String) -> NSFetchRequest<Event> {
        let fetchRequest = NSFetchRequest<Event>(entityName: "Event")
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \Event.createdAt, ascending: false)]
        let noteIsLikedByUserPredicate = NSPredicate(
            // swiftlint:disable line_length
            format: "kind = \(String(EventKind.like.rawValue)) AND author.hexadecimalPublicKey = %@ AND SUBQUERY(eventReferences, $reference, $reference.eventId = %@).@count > 0",
            // swiftlint:enable line_length
            userPubKey,
            noteId
        )
        fetchRequest.predicate = noteIsLikedByUserPredicate
        return fetchRequest
    }
    
    @nonobjc public class func likes(noteId: String) -> NSFetchRequest<Event> {
        let fetchRequest = NSFetchRequest<Event>(entityName: "Event")
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \Event.createdAt, ascending: false)]
        let noteIsLikedByUserPredicate = NSPredicate(
            // swiftlint:disable line_length
            format: "kind = \(String(EventKind.like.rawValue)) AND SUBQUERY(eventReferences, $reference, $reference.eventId = %@).@count > 0",
            // swiftlint:enable line_length
            noteId
        )
        fetchRequest.predicate = noteIsLikedByUserPredicate
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
        fetchRequest.predicate = NSPredicate.false
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
    
    @nonobjc public class func deletePostsRequest(for identifiers: [String]) -> NSBatchDeleteRequest {
        let fetchRequest: NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: "Event")
        fetchRequest.predicate = NSPredicate(format: "identifier IN %@", identifiers)
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

    class func find(by identifier: String, context: NSManagedObjectContext) -> Event? {
        if let existingEvent = try? context.fetch(Event.event(by: identifier)).first {
            return existingEvent
        }

        return nil
    }
    
    class func findOrCreate(jsonEvent: JSONEvent, relay: Relay?, context: NSManagedObjectContext) throws -> Event {
        if let existingEvent = try context.fetch(Event.event(by: jsonEvent.id)).first {
            relay.unwrap { existingEvent.markSeen(on: $0) }
            if existingEvent.isStub {
                try existingEvent.hydrate(from: jsonEvent, relay: relay, in: context)
            }
            return existingEvent
        }
        
        return try Event(context: context, jsonEvent: jsonEvent, relay: relay)
    }
    
    class func findOrCreateStubBy(id: String, context: NSManagedObjectContext) throws -> Event {
        if let existingEvent = try context.fetch(Event.event(by: id)).first {
            return existingEvent
        } else {
            let event = Event(context: context)
            event.identifier = id
            return event
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
    
    /// Returns true if this event doesn't have content. Usually this means we saw it referenced by another event
    /// but we haven't actually downloaded it yet.
    var isStub: Bool {
        author == nil || createdAt == nil || content == nil
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
    
    var bech32NoteID: String? {
        guard let identifier = self.identifier,
            let identifierBytes = try? identifier.bytes else {
            return nil
        }
        return Bech32.encode(Nostr.notePrefix, baseEightData: Data(identifierBytes))
    }
    
    func attributedContent(with context: NSManagedObjectContext) async -> AttributedString? {
        guard let content = self.content else {
            return nil
        }
        
        let regex = Regex {
            "#["
            TryCapture {
                OneOrMore(.digit)
            } transform: {
                Int($0)
            }
            "]"
        }
        
        guard let tags = self.allTags as? [[String]] else {
            return AttributedString(content)
        }
        
        return await context.perform {
            let result = content.replacing(regex) { match in
                if let tag = tags[safe: match.1],
                    let type = tag[safe: 0],
                    let id = tag[safe: 1] {
                    if type == "p",
                        let author = try? Author.find(by: id, context: context),
                        let pubkey = author.hexadecimalPublicKey {
                        return "[@\(author.safeName)](@\(pubkey))"
                    }
                    if type == "e",
                        let event = Event.find(by: id, context: context),
                        let bech32NoteID = event.bech32NoteID {
                        return "[@\(bech32NoteID)](%\(id))"
                    }
                }
                return ""
            }
            
            let linkedString = (try? result.findAndReplaceUnformattedLinks(in: result)) ?? result
            
            return try? AttributedString(
                markdown: linkedString,
                options: AttributedString.MarkdownParsingOptions(interpretedSyntax: .inlineOnlyPreservingWhitespace)
            )
        }
    }
	
    convenience init(context: NSManagedObjectContext, jsonEvent: JSONEvent, relay: Relay?) throws {
        self.init(context: context)
        identifier = jsonEvent.id
        try hydrate(from: jsonEvent, relay: relay, in: context)
    }

    func deleteEvents(identifiers: [String], context: NSManagedObjectContext) async {
        print("Deleting: \(identifiers)")
        let deleteRequest = Event.deletePostsRequest(for: identifiers)

        do {
            try context.execute(deleteRequest)
        } catch let error as NSError {
            print("Failed to delete posts in \(identifiers). Error: \(error.description)")
        }
        
        await context.perform {
            try? context.save()
        }
    }
    
    /// Populates an event stub (with only its ID set) using the data in the given JSON.
    func hydrate(from jsonEvent: JSONEvent, relay: Relay?, in context: NSManagedObjectContext) throws {
        guard isStub else {
            fatalError("Tried to hydrate an event that isn't a stub. This is a programming error")
        }
        
        // Meta data
        createdAt = Date(timeIntervalSince1970: TimeInterval(jsonEvent.createdAt))
        content = jsonEvent.content
        kind = jsonEvent.kind
        signature = jsonEvent.signature
        sendAttempts = 0
        
        // Tags
        allTags = jsonEvent.tags as NSObject
        
        // Author
        guard let newAuthor = try? Author.findOrCreate(by: jsonEvent.pubKey, context: context) else {
            throw EventError.missingAuthor
        }
        
        author = newAuthor
        
        // Relay
        relay.unwrap { markSeen(on: $0) }
        
        guard let eventKind = EventKind(rawValue: kind) else {
            throw EventError.unrecognizedKind
        }
        
        switch eventKind {
        case .contactList:
            hydrateContactList(from: jsonEvent, author: newAuthor, context: context)
            
        case .metaData:
            hydrateMetaData(from: jsonEvent, author: newAuthor, context: context)
            
        case .mute:
            hydrateMuteList(from: jsonEvent, context: context)
            
        default:
            hydrateDefault(from: jsonEvent, context: context)
        }
    }
    
    // swiftlint:disable function_body_length cyclomatic_complexity
    func hydrateContactList(from jsonEvent: JSONEvent, author newAuthor: Author, context: NSManagedObjectContext) {
        guard createdAt! > newAuthor.lastUpdatedContactList ?? Date.distantPast else {
            return
        }
        
        newAuthor.lastUpdatedContactList = Date(timeIntervalSince1970: TimeInterval(jsonEvent.createdAt))

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
        
        // Get the user's active relays out of the content property
        if let data = jsonEvent.content.data(using: .utf8, allowLossyConversion: false),
            let relayEntries = try? JSONSerialization.jsonObject(with: data, options: .mutableContainers),
            let relays = (relayEntries as? [String: Any])?.keys {
            newAuthor.relays = NSMutableSet()

            for address in relays {
                if let relay = try? Relay.findOrCreate(by: address, context: context) {
                    newAuthor.add(relay: relay)
                }
            }
        }
    }
    // swiftlint:enable function_body_length cyclomatic_complexity
    
    func hydrateDefault(from jsonEvent: JSONEvent, context: NSManagedObjectContext) {
        let newEventReferences = NSMutableOrderedSet()
        let newAuthorReferences = NSMutableOrderedSet()
        for jsonTag in jsonEvent.tags {
            if jsonTag.first == "e" {
                // TODO: validdate that the tag looks like an event ref
                do {
                    let eTag = try EventReference(jsonTag: jsonTag, context: context)
                    newEventReferences.add(eTag)
                } catch {
                    print("error parsing e tag: \(error.localizedDescription)")
                }
            } else if jsonTag.first == "p" {
                // TODO: validdate that the tag looks like a pubkey
                let authorReference = AuthorReference(context: context)
                authorReference.pubkey = jsonTag[safe: 1]
                authorReference.recommendedRelayUrl = jsonTag[safe: 2]
                newAuthorReferences.add(authorReference)
            }
        }
        eventReferences = newEventReferences
        authorReferences = newAuthorReferences
    }
    
    func hydrateMetaData(from jsonEvent: JSONEvent, author newAuthor: Author, context: NSManagedObjectContext) {
        guard createdAt! > newAuthor.lastUpdatedMetadata ?? Date.distantPast else {
            // This is old data
            return
        }
        
        if let contentData = jsonEvent.content.data(using: .utf8) {
            newAuthor.lastUpdatedMetadata = Date(timeIntervalSince1970: TimeInterval(jsonEvent.createdAt))
            // There may be unsupported metadata. Store it to send back later in metadata publishes.
            newAuthor.rawMetadata = contentData

            do {
                let metadata = try JSONDecoder().decode(MetadataEventJSON.self, from: contentData)
                
                // Every event has an author created, so it just needs to be populated
                newAuthor.name = metadata.name
                newAuthor.displayName = metadata.displayName
                newAuthor.about = metadata.about
                newAuthor.profilePhotoURL = metadata.profilePhotoURL
                newAuthor.nip05 = metadata.nip05
                newAuthor.uns = metadata.uns
            } catch {
                print("Failed to decode metaData event with ID \(String(describing: identifier))")
            }
        }
    }

    func markSeen(on relay: Relay) {
        // swiftlint:disable legacy_objc_type
        seenOnRelays = (seenOnRelays ?? NSSet()).adding(relay)
        // swiftlint:enable legacy_objc_type
    }
    
    func hydrateMuteList(from jsonEvent: JSONEvent, context: NSManagedObjectContext) {
        let mutedKeys = jsonEvent.tags.map { $0[1] }
        
        let request = Author.allAuthorsRequest(muted: true)
        
        // Un-Mute anyone (locally only) who is muted but not in the mutedKeys
        if let authors = try? context.fetch(request) {
            for author in authors where !mutedKeys.contains(author.hexadecimalPublicKey!) {
                author.muted = false
                print("Parse-Un-Muted \(author.hexadecimalPublicKey ?? "")")
            }
        }
        
        // Mute anyone (locally only) in the mutedKeys
        for key in mutedKeys {
            if let author = try? Author.find(by: key, context: context) {
                author.muted = true
                print("Parse-Muted \(author.hexadecimalPublicKey ?? "")")
            }
        }
        
        // Force ensure current user never was muted
        Task { @MainActor in
            CurrentUser.shared.author?.muted = false
        }
    }
    
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
    
    class func unpublishedEvents(context: NSManagedObjectContext) -> [Event] {
        let allRequest = Event.unpublishedEventsRequest()
        
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
    
    /// Returns true if this event tagged the given author.
    func references(author: Author) -> Bool {
        guard let authorReferences = authorReferences else {
            return false
        }
        
        return authorReferences.contains(where: { element in
            (element as? AuthorReference)?.pubkey == author.hexadecimalPublicKey
        })
    }
    
    /// Returns true if this event is a reply to an event by the given author.
    func isReply(to author: Author) -> Bool {
        guard let eventReferences else {
            return false
        }
        
        return eventReferences.contains(where: { element in
            let rootEvent = (element as? EventReference)?.referencedEvent
            return rootEvent?.author?.hexadecimalPublicKey == author.hexadecimalPublicKey
        })
    }
    
    var isReply: Bool {
        rootNote() != nil
    }
    
    /// Returns the event this note is directly replying to, or nil if there isn't one.
    func referencedNote() -> Event? {
        if let lastReference = eventReferences?.lastObject as? EventReference,
            let referencedNote = lastReference.referencedEvent {
            return referencedNote
        }
        return nil
    }
    
    /// Returns the root event of the thread that this note is replying to, or nil if there isn't one.
    func rootNote() -> Event? {
        let rootReference = eventReferences?.first(where: {
            ($0 as? EventReference)?.marker ?? "" == "root"
        }) as? EventReference
        
        if let rootReference, let rootNote = rootReference.referencedEvent {
            return rootNote
        }
        return nil
    }
    
    // swiftlint:disable legacy_objc_type
    /// This tracks which relays this event is deleted on. Hide posts with deletedOn.count > 0
    func trackDelete(on relay: Relay, context: NSManagedObjectContext) {
        if EventKind(rawValue: kind) == .delete, let eTags = allTags as? [[String]] {
            for deletedEventId in eTags.map({ $0[1] }) {
                if let deletedEvent = Event.find(by: deletedEventId, context: context),
                    deletedEvent.author?.hexadecimalPublicKey == author?.hexadecimalPublicKey {
                    print("\(deletedEvent.identifier ?? "n/a") was deleted on \(relay.address ?? "unknown")")
                    deletedEvent.deletedOn = (deletedEvent.deletedOn ?? NSSet()).adding(relay)
                }
            }
            try! context.save()
        }
    }
    // swiftlint:enable legacy_objc_type
    
    func requestAuthorsMetadataIfNeeded(using relayService: RelayService, in context: NSManagedObjectContext) async -> [RelaySubscription.ID] {
        guard let authorKey = author?.hexadecimalPublicKey else {
            return []
        }
        
        return await context.perform {
            var subscriptionIDs = [RelaySubscription.ID]()
            
            let author = try! Author.findOrCreate(by: authorKey, context: context)
            
            if author.needsMetadata {
                author.requestMetadata(using: relayService).unwrap { subscriptionIDs.append($0) }
            }
            
            self.authorReferences?.forEach { reference in
                if let reference = reference as? AuthorReference,
                   let pubKey = reference.pubkey,
                   let author = try? Author.findOrCreate(by: pubKey, context: context),
                   author.needsMetadata {
                    author.requestMetadata(using: relayService).unwrap { subscriptionIDs.append($0) }
                }
            }
            
            return subscriptionIDs
        }
    }
    
    var webLink: String {
        "https://iris.to/\(bech32NoteID!)"
    }
}
// swiftlint:enable type_body_length
// swiftlint:enable file_length

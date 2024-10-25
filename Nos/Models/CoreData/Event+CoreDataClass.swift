// swiftlint:disable file_length
import secp256k1
import Foundation
import CoreData
import RegexBuilder
import SwiftUI
import Logger
import Dependencies

enum EventError: Error, LocalizedError {
	case utf8Encoding
	case unrecognizedKind
    case missingAuthor
    case invalidETag([String])
    case invalidSignature(Event)
    case expiredEvent

    var errorDescription: String? {
        switch self {
        case .unrecognizedKind:
            return "Unrecognized event kind"
        case .missingAuthor:
            return "Could not parse author on event"
        case .invalidETag(let strings):
            return "Invalid e tag \(strings.joined(separator: ","))"
        case .invalidSignature(let event):
            return "Invalid signature on event: \(String(describing: event.identifier))"
        case .expiredEvent:
            return "This event has expired"
        default:
            return "An unkown error occurred."
        }
	}
}

// swiftlint:disable type_body_length
@objc(Event)
@Observable
public class Event: NosManagedObject, VerifiableEvent {
    @Dependency(\.currentUser) @ObservationIgnored private var currentUser

    var pubKey: String { author?.hexadecimalPublicKey ?? "" }
    static var replyNoteReferences = "kind = 1 AND ANY eventReferences.referencedEvent.identifier == %@ " +
        "AND author.muted = false"

    @nonobjc public class func allEventsRequest() -> NSFetchRequest<Event> {
        let fetchRequest = NSFetchRequest<Event>(entityName: "Event")
        fetchRequest.sortDescriptors = [
            NSSortDescriptor(keyPath: \Event.createdAt, ascending: true),
            NSSortDescriptor(keyPath: \Event.receivedAt, ascending: true)
        ]
        return fetchRequest
    }
    
    // MARK: - Fetching
    
    @nonobjc public class func allPostsRequest(_ eventKind: EventKind = .text) -> NSFetchRequest<Event> {
        let fetchRequest = NSFetchRequest<Event>(entityName: "Event")
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \Event.createdAt, ascending: false)]
        fetchRequest.predicate = NSPredicate(format: "kind = %i", eventKind.rawValue)
        return fetchRequest
    }
    
    @nonobjc public class func allMentionsPredicate(for user: Author) -> NSPredicate {
        guard let publicKey = user.hexadecimalPublicKey, !publicKey.isEmpty else {
            return NSPredicate.false
        }
        
        return NSPredicate(
            format: "kind = %i AND ANY authorReferences.pubkey = %@ AND deletedOn.@count = 0",
            EventKind.text.rawValue,
            publicKey
        )
    }

    @nonobjc public class func unpublishedEventsRequest(for user: Author) -> NSFetchRequest<Event> {
        let fetchRequest = NSFetchRequest<Event>(entityName: "Event")
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \Event.createdAt, ascending: false)]
        fetchRequest.predicate = NSPredicate(
            format: "author.hexadecimalPublicKey = %@ AND " +
            "SUBQUERY(shouldBePublishedTo, $relay, TRUEPREDICATE).@count > " +
            "SUBQUERY(publishedTo, $relay, TRUEPREDICATE).@count AND " +
            "deletedOn.@count = 0",
            user.hexadecimalPublicKey ?? ""
        )
        return fetchRequest
    }
    
    @nonobjc public class func allRepliesPredicate(for user: Author) -> NSPredicate {
        NSPredicate(
            format: "kind = 1 AND ANY eventReferences.referencedEvent.author = %@ AND deletedOn.@count = 0", 
            user
        )
    }
    
    @nonobjc public class func allZapsPredicate(for user: Author) -> NSPredicate {
        guard let publicKey = user.hexadecimalPublicKey, !publicKey.isEmpty else {
            return NSPredicate.false
        }
        
        return NSPredicate(
            format: "kind = %i AND ANY authorReferences.pubkey = %@ AND deletedOn.@count = 0",
            EventKind.zapRequest.rawValue,
            publicKey
        )
    }
    
    /// A request for all events that the given user should receive a notification for.
    /// - Parameters:
    ///   - user: the author you want to view notifications for.
    ///   - since: a date that will be used as a lower bound for the request.
    ///   - limit: a max number of events to fetch.
    /// - Returns: A fetch request for the events described.
    @nonobjc public class func all(
        notifying user: Author, 
        since: Date? = nil, 
        limit: Int? = nil
    ) -> NSFetchRequest<Event> {
        let fetchRequest = NSFetchRequest<Event>(entityName: "Event")
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \Event.createdAt, ascending: false)]
        if let limit {
            fetchRequest.fetchLimit = limit
        }
        
        let mentionsPredicate = allMentionsPredicate(for: user)
        let repliesPredicate = allRepliesPredicate(for: user)
        let zapsPredicate = allZapsPredicate(for: user)
        let notSelfPredicate = NSPredicate(format: "author != %@", user)
        let notMuted = NSPredicate(format: "author.muted == 0", user)
        let allNotificationsPredicate = NSCompoundPredicate(
            orPredicateWithSubpredicates: [mentionsPredicate, repliesPredicate, zapsPredicate]
        )
        var andPredicates = [allNotificationsPredicate, notSelfPredicate, notMuted]
        if let since {
            let sincePredicate = NSPredicate(format: "receivedAt >= %@", since as CVarArg)  
            andPredicates.append(sincePredicate)
        } 
        fetchRequest.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: andPredicates)
        
        return fetchRequest
    }
    
    @nonobjc public class func lastReceived(for user: Author) -> NSFetchRequest<Event> {
        let fetchRequest = NSFetchRequest<Event>(entityName: "Event")
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \Event.createdAt, ascending: false)]
        fetchRequest.predicate = NSPredicate(format: "author != %@", user)
        fetchRequest.fetchLimit = 1
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \Event.receivedAt, ascending: false)]
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
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \Event.receivedAt, ascending: false)]
        fetchRequest.predicate = NSPredicate(
            format: replyNoteReferences,
            noteID
        )
        return fetchRequest
    }

    /// A request for all events that responded to a specific note.
    ///
    /// - Parameter noteIdentifier: ID of the note to retrieve replies for.
    ///
    /// Intented to be used primarily to compute the number of replies and for
    /// building a set of author avatars.
    @nonobjc public class func replies(to noteID: RawEventID) -> FetchRequest<Event> {
        let format = """
            SUBQUERY(
                eventReferences,
                $e,
                $e.referencedEvent.identifier = %@ AND
                    ($e.marker = 'reply' OR $e.marker = 'root')
            ).@count > 0
        """

        let predicate = NSCompoundPredicate(
            andPredicateWithSubpredicates: [
                NSPredicate(format: "kind = 1"),
                NSPredicate(
                    format: format,
                    noteID,
                    noteID
                ),
                NSPredicate(format: "deletedOn.@count = 0"),
                NSPredicate(format: "author.muted = false")
            ]
        )

        let fetchRequest = Event.fetchRequest()
        fetchRequest.includesPendingChanges = false
        fetchRequest.includesSubentities = false
        fetchRequest.sortDescriptors = [
            NSSortDescriptor(keyPath: \Event.identifier, ascending: true)
        ]

        fetchRequest.predicate = predicate
        fetchRequest.relationshipKeyPathsForPrefetching = ["author"]
        return FetchRequest(fetchRequest: fetchRequest)
    }

    /// A fetch request for all the events that should be cleared out of the database by 
    /// `DatabaseCleaner.cleanupEntities(...)`.
    ///
    /// It will save the events for the given `user`, as well as other important events matching various other
    /// criteria.
    /// - Parameter before: The date before which events will be considered for cleanup. 
    /// - Parameter user: The Author record for the currently logged in user. Special treatment is given to their data.
    @nonobjc public class func cleanupRequest(before date: Date, for user: Author) -> NSFetchRequest<Event> {
        let oldStoryCutoff = Calendar.current.date(byAdding: .day, value: -2, to: .now) ?? .now
        
        let request = NSFetchRequest<Event>(entityName: "Event")
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Event.receivedAt, ascending: true)]
        let oldUnreferencedEventsClause = "(receivedAt < %@ OR receivedAt == nil) AND referencingEvents.@count = 0" 
        let notOwnEventClause = "(author != %@)"
        let readStoryClause = "(isRead = 1 AND receivedAt > %@)"
        let userReportClause = "(kind == \(EventKind.report.rawValue) AND " +
        "authorReferences.@count > 0 AND eventReferences.@count == 0)"
        let clauses = "\(oldUnreferencedEventsClause) AND" +
        "\(notOwnEventClause) AND " +
        "NOT \(readStoryClause) AND " +
        "NOT \(userReportClause)"
        request.predicate = NSPredicate(
            format: clauses,
            date as CVarArg,
            user,
            oldStoryCutoff as CVarArg
        )
        
        return request
    }
    
    /// This constructs a predicate for events that should be protected from deletion when we are purging the database.
    /// - Parameter user: The Author record for the currently logged in user. Special treatment is given to their data.
    /// - Parameter asSubquery: If true then each attribute in the predicate will prefixed with "$event." so the 
    ///   predicate can be used in a SUBQUERY. 
    @nonobjc public class func protectedFromCleanupPredicate(
        for user: Author, 
        asSubquery: Bool = false
    ) -> NSPredicate {
        guard let userKey = user.hexadecimalPublicKey else {
            return NSPredicate.false
        }
        
        // The string we use to reference the current event if we are constructing this predicate to be used in a 
        // subquery
        let eventReference = asSubquery ? "$event." : ""
        
        // protect all events authored by the current user 
        let userEventsPredicate = NSPredicate(format: "\(eventReference)author.hexadecimalPublicKey = '\(userKey)'")
        
        // protect stories that were read recently, so we don't redownload and show them as unread again 
        let oldStoryCutoffDate = Calendar.current.date(byAdding: .day, value: -2, to: .now) ?? .now
        let recentlyReadStoriesPredicate = NSPredicate(
            format: "(\(eventReference)isRead = 1 AND \(eventReference)receivedAt > %@)", 
            oldStoryCutoffDate as CVarArg
        )
        
        // keep author reports from people we follow
        let userReportPredicate = NSPredicate(
            format: "(\(eventReference)kind == \(EventKind.report.rawValue) AND " +
                "SUBQUERY(\(eventReference)authorReferences, $references, TRUEPREDICATE).@count > 0 AND " +
                "SUBQUERY(\(eventReference)eventReferences, $references, TRUEPREDICATE).@count == 0 AND " +
                "ANY \(eventReference)author.followers.source.hexadecimalPublicKey == %@)",
            userKey
        )
        
        return NSCompoundPredicate(
            orPredicateWithSubpredicates: [
                userEventsPredicate, 
                recentlyReadStoriesPredicate, 
                userReportPredicate
            ]
        )
    }
    
    @nonobjc public class func expiredRequest() -> NSFetchRequest<Event> {
        let fetchRequest = NSFetchRequest<Event>(entityName: "Event")
        fetchRequest.predicate = NSPredicate(format: "expirationDate <= %@", Date.now as CVarArg)
        return fetchRequest
    }
    
    @nonobjc public class func event(by identifier: RawEventID) -> NSFetchRequest<Event> {
        let fetchRequest = NSFetchRequest<Event>(entityName: "Event")
        fetchRequest.predicate = NSPredicate(format: "identifier = %@", identifier)
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \Event.identifier, ascending: true)]
        fetchRequest.fetchLimit = 1
        return fetchRequest
    }
    
    @nonobjc public class func event(
        by replaceableID: RawReplaceableID, 
        author: Author,
        kind: Int64
    ) -> NSFetchRequest<Event> {
        let fetchRequest = NSFetchRequest<Event>(entityName: "Event")
        fetchRequest.predicate = NSPredicate(
            format: "replaceableIdentifier = %@ AND author = %@ AND kind = %i",
            replaceableID,
            author,
            kind
        )
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \Event.replaceableIdentifier, ascending: true)]
        fetchRequest.fetchLimit = 1
        return fetchRequest
    }
    
    @nonobjc public class func hydratedEvent(by identifier: String) -> NSFetchRequest<Event> {
        let fetchRequest = NSFetchRequest<Event>(entityName: "Event")
        fetchRequest.predicate = NSPredicate(
            format: "identifier = %@ AND createdAt != nil AND author != nil", identifier
        )
        fetchRequest.fetchLimit = 1
        return fetchRequest
    }
    
    @nonobjc public class func event(by identifier: String, seenOn relay: Relay) -> NSFetchRequest<Event> {
        guard let relayAddress = relay.address else {
            return Event.emptyRequest()
        }
        
        let fetchRequest = NSFetchRequest<Event>(entityName: "Event")
        fetchRequest.predicate = NSPredicate(
            format: "identifier = %@ AND ANY seenOnRelays.address = %@", 
            identifier, 
            relayAddress
        )
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \Relay.createdAt, ascending: true)]
        fetchRequest.fetchLimit = 1
        return fetchRequest
    }
    
    @nonobjc class func mostRecentPosts(from author: Author) -> NSFetchRequest<Event> {
        
        let kind1Predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
            NSPredicate(format: "kind = 1"),
            NSPredicate(
                format: "SUBQUERY(" +
                "eventReferences, $reference, $reference.marker = 'root'" +
                " OR $reference.marker = 'reply'" +
                " OR $reference.marker = nil" +
                ").@count = 0"
            )
        ])

        let notDeletedPredicate = NSPredicate(format: "deletedOn.@count = 0")
        let authorPredicate = NSPredicate(format: "author = %@", author)

        let allPredicates = [kind1Predicate, notDeletedPredicate, authorPredicate]

        let fetchRequest = NSFetchRequest<Event>(entityName: "Event")
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \Event.createdAt, ascending: false)]
        fetchRequest.fetchLimit = 1
        fetchRequest.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: allPredicates)
        return fetchRequest
    }
    
    /// Returns a predicate that can be used to fetch the given user's home feed.
    /// - Parameters:
    ///   - user: The user whose home feed should appear.
    ///   - before: Only fetch events that were created before this date. Defaults to `nil`.
    ///   - after: Only fetch events that were created after this date. Defaults to `nil`.
    ///   - relay: Only fetch events on this relay. Defaults to `nil`, which uses all the user's relays.
    /// - Returns: A predicate matching the given parameters that can be used to fetch the user's home feed.
    @nonobjc private class func homeFeedPredicate(
        for user: Author,
        before: Date? = nil,
        after: Date? = nil,
        seenOn relay: Relay? = nil
    ) -> NSPredicate {
        let kind1Predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
            NSPredicate(format: "kind = 1"),
            NSPredicate(
                format: "SUBQUERY(" +
                "eventReferences, $reference, $reference.marker = 'root'" +
                " OR $reference.marker = 'reply'" +
                " OR $reference.marker = nil" +
                ").@count = 0"
            )
        ])
        let kind6Predicate = NSPredicate(format: "kind = 6")
        let kind30023Predicate = NSPredicate(format: "kind = 30023")

        let kindsPredicate = NSCompoundPredicate(orPredicateWithSubpredicates: [
            kind1Predicate,
            kind6Predicate,
            kind30023Predicate
        ])

        let notMutedPredicate = NSPredicate(format: "author.muted = 0")
        let notDeletedPredicate = NSPredicate(format: "deletedOn.@count = 0")

        var andPredicates = [kindsPredicate, notMutedPredicate, notDeletedPredicate]

        if let before {
            andPredicates.append(NSPredicate(format: "createdAt <= %@", before as CVarArg))
        }

        if let after {
            andPredicates.append(NSPredicate(format: "createdAt > %@", after as CVarArg))
        }

        if let relay {
            andPredicates.append(NSPredicate(format: "ANY seenOnRelays = %@", relay as CVarArg))
        } else {
            andPredicates.append(
                NSPredicate(format: "(ANY author.followers.source = %@ OR author = %@)", user, user)
            )
        }

        return NSCompoundPredicate(andPredicateWithSubpredicates: andPredicates)
    }

    @nonobjc public class func homeFeed(
        for user: Author, 
        before: Date, 
        seenOn relay: Relay? = nil
    ) -> NSFetchRequest<Event> {
        let fetchRequest = NSFetchRequest<Event>(entityName: "Event")
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \Event.createdAt, ascending: false)]
        fetchRequest.predicate = homeFeedPredicate(for: user, before: before, seenOn: relay)
        return fetchRequest
    }

    @nonobjc public class func homeFeed(
        for user: Author, 
        after: Date,
        seenOn relay: Relay? = nil
    ) -> NSFetchRequest<Event> {
        let fetchRequest = NSFetchRequest<Event>(entityName: "Event")
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \Event.createdAt, ascending: false)]
        fetchRequest.predicate = homeFeedPredicate(for: user, after: after, seenOn: relay)
        return fetchRequest
    }

    @nonobjc public class func likes(noteID: String) -> NSFetchRequest<Event> {
        let fetchRequest = NSFetchRequest<Event>(entityName: "Event")
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \Event.createdAt, ascending: false)]
        let noteIsLikedByUserPredicate = NSPredicate(
            // swiftlint:disable line_length
            format: "kind = \(String(EventKind.like.rawValue)) AND SUBQUERY(eventReferences, $reference, $reference.eventId = %@).@count > 0 AND deletedOn.@count = 0",
            // swiftlint:enable line_length
            noteID
        )
        fetchRequest.predicate = noteIsLikedByUserPredicate
        return fetchRequest
    }
    
    @nonobjc public class func reposts(noteID: String) -> NSFetchRequest<Event> {
        let fetchRequest = NSFetchRequest<Event>(entityName: "Event")
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \Event.createdAt, ascending: false)]
        let noteIsLikedByUserPredicate = NSPredicate(
            // swiftlint:disable line_length
            format: "kind = \(String(EventKind.repost.rawValue)) AND SUBQUERY(eventReferences, $reference, $reference.eventId = %@).@count > 0 AND deletedOn.@count = 0",
            // swiftlint:enable line_length
            noteID
        )
        fetchRequest.predicate = noteIsLikedByUserPredicate
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
    
    class func unpublishedEvents(for user: Author, context: NSManagedObjectContext) -> [Event] {
        let allRequest = Event.unpublishedEventsRequest(for: user)
        
        do {
            let results = try context.fetch(allRequest)
            return results
        } catch let error as NSError {
            print("Failed to fetch events. Error: \(error.description)")
            return []
        }
    }
    
    class func find(by identifier: RawEventID, context: NSManagedObjectContext) -> Event? {
        if let existingEvent = try? context.fetch(Event.event(by: identifier)).first {
            return existingEvent
        }

        return nil
    }    
    
    func reportsRequest() -> NSFetchRequest<Event> {
        let request = NSFetchRequest<Event>(entityName: "Event")
        request.predicate = NSPredicate(
            format: "kind = %i AND ANY eventReferences.referencedEvent = %@ AND deletedOn.@count = 0", 
            EventKind.report.rawValue,
            self
        )
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Event.identifier, ascending: true)]
        return request
    }
    
    // MARK: - Creating

    func createIfNecessary(
        jsonEvent: JSONEvent, 
        relay: Relay?, 
        context: NSManagedObjectContext
    ) throws -> Event? {
        // Optimization: check that no record exists before doing any fetching
        guard try context.count(for: Event.hydratedEvent(by: jsonEvent.id)) == 0 else {
            return nil
        }

        if let existingEvent = try context.fetch(Event.event(by: jsonEvent.id)).first {
            if existingEvent.isStub {
                try existingEvent.hydrate(from: jsonEvent, relay: relay, in: context)
            }
            return existingEvent
        } else {
            if let replaceableID = jsonEvent.replaceableID {
                let author = try Author.findOrCreate(by: jsonEvent.pubKey, context: context)
                let request = Event.event(by: replaceableID, author: author, kind: jsonEvent.kind)
                if let existingEvent = try context.fetch(request).first {
                    if existingEvent.isStub {
                        try existingEvent.hydrate(from: jsonEvent, relay: relay, in: context)
                    }
                    return existingEvent
                }
            }

            let event = Event(context: context)
            event.identifier = jsonEvent.id
            event.receivedAt = .now
            try event.hydrate(from: jsonEvent, relay: relay, in: context)
            return event
        }
    }

    /// Fetches the event with the given ID out of the database, and otherwise creates a stubbed Event.
    /// A stubbed event created here only has an `identifier`. We know an event with this identifier exists but we don't
    /// have its content or tags yet.
    ///  
    /// - Parameters:
    ///   - id: The hexadecimal Nostr ID of the event.
    /// - Returns: The Event model with the given ID.
    class func findOrCreateStubBy(id: RawEventID, context: NSManagedObjectContext) throws -> Event {
        if let existingEvent = try context.fetch(Event.event(by: id)).first {
            return existingEvent
        } else {
            let event = Event(context: context)
            event.identifier = id
            return event
        }
    }

    /// Fetches the event with the given replaceable ID and author ID out of the database, and otherwise
    /// creates a stubbed Event.
    /// A stubbed event created here will only have a `replaceableIdentifier` and an author. We know an event with this
    /// `replaceableIdentifier` and author exists but we don't have its content or tags yet.
    ///
    /// - Parameters:
    ///   - replaceableID: The replaceable ID of the event. This is encoded in the `d` tag.
    ///   - authorID: The public key of the author associated with the event.
    ///   - kind: The kind of the event. If this is `nil`, it's ignored. Defaults to `nil`.
    ///   - context: The managed object context to use.
    /// - Returns: The Event model with the given ID.
    class func findOrCreateStubBy(
        replaceableID: RawReplaceableID,
        authorID: RawAuthorID,
        kind: Int64,
        context: NSManagedObjectContext
    ) throws -> Event {
        let author = try Author.findOrCreate(by: authorID, context: context)
        if let existingEvent = try context.fetch(Event.event(by: replaceableID, author: author, kind: kind)).first {
            return existingEvent
        } else {
            let event = Event(context: context)
            event.replaceableIdentifier = replaceableID
            event.author = author
            event.kind = kind
            return event
        }
    }
    
    /// Populates an event stub (with only its ID set) using the data in the given JSON.
    func hydrate(from jsonEvent: JSONEvent, relay: Relay?, in context: NSManagedObjectContext) throws {
        guard isStub else {
            fatalError("Tried to hydrate an event that isn't a stub. This is a programming error")
        }

        // if this stub was created with a replaceableIdentifier and author, it won't have an identifier yet
        identifier = jsonEvent.id

        // Meta data
        createdAt = Date(timeIntervalSince1970: TimeInterval(jsonEvent.createdAt))
        if let createdAt, createdAt > .now {
            self.createdAt = .now
        }
        content = jsonEvent.content
        kind = jsonEvent.kind
        signature = jsonEvent.signature
        sendAttempts = 0
        
        // Tags
        allTags = jsonEvent.tags as NSObject
        for tag in jsonEvent.tags {
            if tag[safe: 0] == "expiration",
                let expirationDateString = tag[safe: 1],
                let expirationDateUnix = TimeInterval(expirationDateString),
                expirationDateUnix != 0 {
                let expirationDate = Date(timeIntervalSince1970: expirationDateUnix)
                self.expirationDate = expirationDate
                if isExpired {
                    throw EventError.expiredEvent
                }
            } else if tag[safe: 0] == "d",
                let dTag = tag[safe: 1] {
                replaceableIdentifier = dTag
            }
        }
        
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
        case .repost:
            
            hydrateDefault(from: jsonEvent, context: context)
            parseContent(from: jsonEvent, context: context)
            
        default:
            hydrateDefault(from: jsonEvent, context: context)
        }
    }
    
    func hydrateContactList(from jsonEvent: JSONEvent, author newAuthor: Author, context: NSManagedObjectContext) {
        guard createdAt! > newAuthor.lastUpdatedContactList ?? Date.distantPast else {
            return
        }
        
        newAuthor.lastUpdatedContactList = Date(timeIntervalSince1970: TimeInterval(jsonEvent.createdAt))

        // Put existing follows into a dictionary so we can avoid doing a fetch request to look up each one.
        var originalFollows = [RawAuthorID: Follow]()
        for follow in newAuthor.follows {
            if let pubKey = follow.destination?.hexadecimalPublicKey {
                originalFollows[pubKey] = follow
            }
        }
        
        var newFollows = Set<Follow>()
        for jsonTag in jsonEvent.tags {
            if let followedKey = jsonTag[safe: 1], 
                let existingFollow = originalFollows[followedKey] {
                // We already have a Core Data Follow model for this user
                newFollows.insert(existingFollow)
            } else {
                do {
                    newFollows.insert(try Follow.upsert(by: newAuthor, jsonTag: jsonTag, context: context))
                } catch {
                    Log.error("Error: could not parse Follow from: \(jsonEvent)")
                }
            }
        }
        
        // Did we unfollow someone? If so, remove them from core data
        let removedFollows = Set(originalFollows.values).subtracting(newFollows)
        if !removedFollows.isEmpty {
            Log.info("Removing \(removedFollows.count) follows")
            Follow.deleteFollows(in: removedFollows, context: context)
        }
        
        newAuthor.follows = newFollows
        
        // Get the user's active relays out of the content property
        if let data = jsonEvent.content.data(using: .utf8, allowLossyConversion: false),
            let relayEntries = try? JSONSerialization.jsonObject(with: data, options: .mutableContainers),
            let relays = (relayEntries as? [String: Any])?.keys {
            newAuthor.relays = Set()

            for address in relays {
                if let relay = try? Relay.findOrCreate(by: address, context: context) {
                    newAuthor.add(relay: relay)
                }
            }
        }
    }
    
    func hydrateDefault(from jsonEvent: JSONEvent, context: NSManagedObjectContext) {
        let newEventReferences = NSMutableOrderedSet()
        let newAuthorReferences = NSMutableOrderedSet()
        for jsonTag in jsonEvent.tags {
            if jsonTag.first == "e" {
                // TODO: validate that the tag looks like an event ref
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
                newAuthor.website = metadata.website
                newAuthor.nip05 = metadata.nip05
                newAuthor.uns = metadata.uns
            } catch {
                print("Failed to decode metaData event with ID \(String(describing: identifier))")
            }
        }
    }

    func markSeen(on relay: Relay) {
        seenOnRelays.insert(relay) 
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
            currentUser.author?.muted = false
        }
    }

    /// Tries to parse a new event out of the given jsonEvent's `content` field.
    @discardableResult
    func parseContent(from jsonEvent: JSONEvent, context: NSManagedObjectContext) -> Event? {
        do {
            if let contentData = jsonEvent.content.data(using: .utf8) {
                let jsonEvent = try JSONDecoder().decode(JSONEvent.self, from: contentData)
                return try Event().createIfNecessary(jsonEvent: jsonEvent, relay: nil, context: context)
            }
        } catch {
            Log.error("Could not parse content for jsonEvent: \(jsonEvent)")
            return nil
        }
        
        return nil
    }
    
    // MARK: - Preloading and Caching
    // Probably should refactor this stuff into a view model
    
    @MainActor var loadingViewData = false
    @MainActor var attributedContent = LoadingContent<AttributedString>.loading
    @MainActor var contentLinks = [URL]()
    @MainActor var relaySubscriptions = SubscriptionCancellables()
    
    /// Instructs this event to load supplementary data like author name and photo, reference events, and produce
    /// formatted `content` and cache it on this object. Idempotent.
    @MainActor func loadViewData() async {
        guard !loadingViewData else {
            return
        }
        loadingViewData = true 
        Log.debug("\(identifier ?? "null") loading view data")
        
        if isStub {
            await loadContent()
            loadingViewData = false
            // TODO: how do we load details for the event again after we hydrate the stub?
        } else {
            Task { await loadReferencedNote() }
            Task { await loadAuthorMetadata() }
            Task { await loadAttributedContent() }
        }
    }
    
    /// Tries to download this event from relays.
    @MainActor private func loadContent() async {
        @Dependency(\.relayService) var relayService
        if let identifier {
            relaySubscriptions.append(await relayService.requestEvent(with: identifier))
        } else if let replaceableIdentifier, let authorKey = author?.hexadecimalPublicKey {
            relaySubscriptions.append(
                await relayService.requestEvent(with: replaceableIdentifier, authorKey: authorKey)
            )
        }
    }

    /// Requests any missing metadata for authors referenced by this note from relays.
    @MainActor private func loadAuthorMetadata() async {
        @Dependency(\.relayService) var relayService
        @Dependency(\.persistenceController) var persistenceController
        let backgroundContext = persistenceController.backgroundViewContext
        relaySubscriptions.append(await Event.requestAuthorsMetadataIfNeeded(
            noteID: identifier, 
            using: relayService, 
            in: backgroundContext
        ))
    }
    
    /// Tries to load the note this note is reposting or replying to from relays.
    @MainActor private func loadReferencedNote() async {
        if let referencedNote = referencedNote() {
            await referencedNote.loadViewData()
        } else {
            await rootNote()?.loadViewData()
        }
    }
    
    @MainActor private var loadingAttributedContent = false
    
    /// Processes the note `content` to populate mentions and extract links. The results are saved in 
    /// `attributedContent` and `contentLinks`. Idempotent.
    @MainActor func loadAttributedContent() async {
        guard !loadingAttributedContent else {
            return
        }
        loadingAttributedContent = true
        defer { loadingAttributedContent = false }
        
        @Dependency(\.persistenceController) var persistenceController
        let backgroundContext = persistenceController.backgroundViewContext
        if let parsedAttributedContent = await Event.attributedContentAndURLs(
            note: self,
            context: backgroundContext
        ) {
            let (attributedString, contentLinks) = parsedAttributedContent
            self.attributedContent = .loaded(attributedString)
            self.contentLinks = contentLinks
        } else {
            self.attributedContent = .loaded(AttributedString(content ?? "")) 
        }
    }
    
    // MARK: - Helpers
    
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
        author == nil || createdAt == nil || identifier == nil
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
            allTags = [[String]]() as NSObject
        }
        identifier = try calculateIdentifier()
        if let identifier {
            var serializedBytes = try identifier.bytes
            signature = try privateKey.sign(bytes: &serializedBytes)
        } else {
            Log.error("Couldn't calculate identifier when signing a private key")
        }
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
    
    var jsonString: String? {
        guard let jsonRepresentation,  
            let data = try? JSONSerialization.data(withJSONObject: jsonRepresentation) else {
            return nil
        }
        return String(decoding: data, as: UTF8.self)
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
        return Bech32.encode(NostrIdentifierPrefix.note, baseEightData: Data(identifierBytes))
    }
    
    var seenOnRelayURLs: [String] {
        seenOnRelays.compactMap { $0.addressURL?.absoluteString }
    }
    
    class func attributedContent(
        noteID: String?,
        noteParser: NoteParser = NoteParser(),
        context: NSManagedObjectContext
    ) async -> AttributedString {
        guard let noteID else {
            return AttributedString()
        }
        
        return await context.perform {
            guard let note = try? Event.findOrCreateStubBy(id: noteID, context: context),
                let content = note.content else {
                return AttributedString()
            }
            try? context.saveIfNeeded()
            let tags = note.allTags as? [[String]] ?? []
            return noteParser.parse(
                content: content,
                tags: tags,
                context: context
            )
        }
    }
   
    /// This function formats an Event's content for display in the UI. It does things like replacing raw npub links
    /// with the author's name, and extracting any URLs so that previews can be displayed for them.
    ///
    /// The given note should be initialized in a main queue NSManagedObjectContext (probably viewContext).
    /// 
    /// - Parameter note: the note whose content should be processed.
    /// - Parameter context: the context to use for database queries - this does not need to be the same context that
    ///     `note` is in.
    /// - Returns: A tuple where the first object is the note content formatted for display, and the second is a list
    ///     of HTTP links found in the note's context.  
    @MainActor class func attributedContentAndURLs(
        note: Event,
        noteParser: NoteParser = NoteParser(),
        context: NSManagedObjectContext
    ) async -> (AttributedString, [URL])? {
        guard let content = note.content else {
            return nil
        }
        let tags = note.allTags as? [[String]] ?? []
        
        return await context.perform {
            noteParser.parse(content: content, tags: tags, context: context)
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
        authorReferences.contains(where: { element in
            (element as? AuthorReference)?.pubkey == author.hexadecimalPublicKey
        })
    }
    
    /// Returns true if this event is a reply to an event by the given author.
    func isReply(to author: Author) -> Bool {
        eventReferences.contains(where: { element in
            let rootEvent = (element as? EventReference)?.referencedEvent
            return rootEvent?.author?.hexadecimalPublicKey == author.hexadecimalPublicKey
        })
    }
    
    /// Returns true if this event is a zap request targeting the given author.
    func isProfileZap(to author: Author) -> Bool {
        kind == EventKind.zapRequest.rawValue && references(author: author)
    }
    
    var isReply: Bool {
        rootNote() != nil || referencedNote() != nil
    }
    
    var isExpired: Bool {
        if let expirationDate {
            return expirationDate <= .now
        } else {
            return false
        }
    }
    
    /// Returns the event this note is directly replying to, or nil if there isn't one.
    func referencedNote() -> Event? {
        if let rootReference = eventReferences.first(where: {
            ($0 as? EventReference)?.type == .reply
        }) as? EventReference,
            let referencedNote = rootReference.referencedEvent {
            return referencedNote
        }
        
        if let lastReference = eventReferences.lastObject as? EventReference,
            lastReference.marker == nil,
            let referencedNote = lastReference.referencedEvent {
            return referencedNote
        }
        return nil
    }
    
    /// Returns the root event of the thread that this note is replying to, or nil if there isn't one.
    func rootNote() -> Event? {
        let rootReference = eventReferences.first(where: {
            ($0 as? EventReference)?.type == .root
        }) as? EventReference
        
        if let rootReference, let rootNote = rootReference.referencedEvent {
            return rootNote
        }
        return nil
    }
    
    /// Returns the event this note is reposting, if this note is a kind 6 repost.
    func repostedNote() -> Event? {
        guard kind == EventKind.repost.rawValue else {
            return nil
        }
        
        if let reference = eventReferences.firstObject as? EventReference,
            let repostedNote = reference.referencedEvent {
            return repostedNote
        }
        
        return nil
    }
    
    /// This tracks which relays this event is deleted on. Hide posts with deletedOn.count > 0
    func trackDelete(on relay: Relay, context: NSManagedObjectContext) throws {
        if EventKind(rawValue: kind) == .delete, let eTags = allTags as? [[String]] {
            for deletedEventId in eTags.map({ $0[1] }) {
                if let deletedEvent = Event.find(by: deletedEventId, context: context),
                    deletedEvent.author?.hexadecimalPublicKey == author?.hexadecimalPublicKey {
                    print("\(deletedEvent.identifier ?? "n/a") was deleted on \(relay.address ?? "unknown")")
                    deletedEvent.deletedOn.insert(relay)
                }
            }
        }
    }
    
    class func requestAuthorsMetadataIfNeeded(
        noteID: RawEventID?,
        using relayService: RelayService,
        in context: NSManagedObjectContext
    ) async -> SubscriptionCancellable {
        guard let noteID else {
            return SubscriptionCancellable(subscriptionIDs: [], relayService: relayService)
        }
        
        let requestData: [(RawAuthorID?, Date?)] = await context.perform {
            guard let note = try? Event.findOrCreateStubBy(id: noteID, context: context),
                let authorKey = note.author?.hexadecimalPublicKey else {
                return []
            }
        
            var requestData = [(RawAuthorID?, Date?)]()
            
            guard let author = try? Author.findOrCreate(by: authorKey, context: context) else {
                Log.debug("Author not found when requesting metadata of a note's author")
                return []
            }
            
            if author.needsMetadata {
                requestData.append((author.hexadecimalPublicKey, author.lastUpdatedMetadata))
            }
            
            note.authorReferences.forEach { reference in
                if let reference = reference as? AuthorReference,
                    let pubKey = reference.pubkey,
                    let author = try? Author.findOrCreate(by: pubKey, context: context),
                    author.needsMetadata {
                    requestData.append((author.hexadecimalPublicKey, author.lastUpdatedMetadata))
                }
            }
            
            try? context.saveIfNeeded()
            return requestData
        }
        
        var cancellables = [SubscriptionCancellable]()
        for requestDatum in requestData {
            let authorKey = requestDatum.0
            let sinceDate = requestDatum.1
            cancellables.append(await relayService.requestMetadata(for: authorKey, since: sinceDate))
        }
        
        return SubscriptionCancellable(cancellables: cancellables, relayService: relayService)
    }
    
    var webLink: String {
        if let bech32NoteID {
            return "https://njump.me/\(bech32NoteID)"
        } else {
            Log.error("Couldn't find a bech32note key when generating web link")
            return "https://njump.me"
        }
    }
    
    /// Converts an event back to a stubbed event by deleting all data except the `identifier`.
    func stub() {
        allTags = nil
        content = nil
        createdAt = nil
        isVerified = false
        receivedAt = nil
        sendAttempts = 0
        signature = nil
        author = nil
        authorReferences = NSOrderedSet()
        deletedOn = Set()
        eventReferences = NSOrderedSet()
        publishedTo = Set()
        seenOnRelays = Set()
        shouldBePublishedTo = Set()
    }
}
// swiftlint:enable type_body_length
// swiftlint:enable file_length

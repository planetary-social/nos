//
//  Author+CoreDataClass.swift
//  Nos
//
//  Created by Matthew Lorentz on 1/31/23.
//
//

import Foundation
import CoreData
import Dependencies
import Logger

enum AuthorError: Error {
    case coreData
}

@objc(Author)
public class Author: NosManagedObject {
    
    @Dependency(\.currentUser) var currentUser
    
    var npubString: String? {
        publicKey?.npub
    }
    
    var safeName: String {
        if let displayName, !displayName.isEmpty {
            return displayName
        }
        
        if let name, !name.isEmpty {
            return name
        }
        
        return npubString?.prefix(10).appending("...") ?? hexadecimalPublicKey ?? "error"
    }
    
    var publicKey: PublicKey? {
        guard let hex = hexadecimalPublicKey else {
            return nil
        }
        
        return PublicKey(hex: hex)
    }
    
    var needsMetadata: Bool {
        // TODO: consider checking lastUpdated time as an optimization.
        about == nil && name == nil && displayName == nil && profilePhotoURL == nil
    }
    
    var webLink: String {
        if let publicKey {
            return "https://njump.me/\(publicKey.npub)"
        } else {
            Log.error("Coudln't find public key when creating weblink")
            return "https://njump.me/"
        }
    }

    /// A URL that links to this author, suitable for being shared with others.
    ///
    /// See [NIP-21](https://github.com/nostr-protocol/nips/blob/master/21.md)
    var uri: URL? {
        if let npub = publicKey?.npub {
            return URL(string: "nostr:\(npub)")
        }
        return nil
    }
    
    var followedKeys: [HexadecimalString] {
        follows.compactMap({ $0.destination?.hexadecimalPublicKey }) 
    }

    var hasHumanFriendlyName: Bool {
        name?.isEmpty == false || displayName?.isEmpty == false
    }
    
    class func request(by pubKey: HexadecimalString) -> NSFetchRequest<Author> {
        let fetchRequest = NSFetchRequest<Author>(entityName: String(describing: Author.self))
        fetchRequest.predicate = NSPredicate(format: "hexadecimalPublicKey = %@", pubKey)
        fetchRequest.fetchLimit = 1
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \Author.hexadecimalPublicKey, ascending: false)]
        return fetchRequest
    }
    
    class func find(by pubKey: HexadecimalString, context: NSManagedObjectContext) throws -> Author? {
        let fetchRequest = request(by: pubKey)
        if let author = try context.fetch(fetchRequest).first {
            return author
        }
        
        return nil
    }
    
    class func find(named name: String, context: NSManagedObjectContext) throws -> [Author] {
        let fetchRequest = NSFetchRequest<Author>(entityName: String(describing: Author.self))
        fetchRequest.predicate = NSPredicate(
            format: "name CONTAINS[cd] %@ OR displayName CONTAINS[cd] %@ OR uns CONTAINS[cd] %@", name, name, name
        )
        let authors = try context.fetch(fetchRequest)
        return authors
    }
    
    @discardableResult
    class func findOrCreate(by pubKey: HexadecimalString, context: NSManagedObjectContext) throws -> Author {
        @Dependency(\.persistenceController) var persistenceController
        @Dependency(\.crashReporting) var crashReporting
        
        if let author = try? Author.find(by: pubKey, context: context) {
            return author
        } else {
            /// Always create authors in the creationContext first to make sure we never end up with two identical
            /// Authors in different contexts with the same objectID, because this messes up SwiftUI's observation
            /// of changes.
            let creationContext = persistenceController.creationContext
            let objectID = try creationContext.performAndWait {
                let author = Author(context: creationContext)
                author.hexadecimalPublicKey = pubKey
                author.muted = false
                try creationContext.save()
                return author.objectID
            }
            guard let fetchedAuthor = context.object(with: objectID) as? Author else {
                let error = AuthorError.coreData
                crashReporting.report(error)
                throw error
            }
            return fetchedAuthor
        }
    }
    
    @nonobjc public class func allAuthorsRequest() -> NSFetchRequest<Author> {
        let fetchRequest = NSFetchRequest<Author>(entityName: "Author")
        return fetchRequest
    }
    
    @nonobjc public class func allAuthorsRequest(muted: Bool) -> NSFetchRequest<Author> {
        let fetchRequest = NSFetchRequest<Author>(entityName: "Author")
        fetchRequest.predicate = NSPredicate(format: "muted == %i", muted)
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \Author.hexadecimalPublicKey, ascending: false)]
        return fetchRequest
    }

    @nonobjc public class func allAuthorsWithNameOrDisplayNameRequest(muted: Bool) -> NSFetchRequest<Author> {
        let fetchRequest = NSFetchRequest<Author>(entityName: "Author")
        fetchRequest.predicate = NSPredicate(format: "muted == %i AND (displayName != nil OR name != nil)", muted)
        return fetchRequest
    }
    
    @nonobjc func allPostsRequest() -> NSFetchRequest<Event> {
        let fetchRequest = NSFetchRequest<Event>(entityName: "Event")
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \Event.createdAt, ascending: false)]
        fetchRequest.predicate = NSPredicate(
            format: "(kind = %i OR kind = %i OR kind = %i) AND author = %@", 
            EventKind.text.rawValue, 
            EventKind.repost.rawValue, 
            EventKind.longFormContent.rawValue, 
            self
        )
        return fetchRequest
    }

    @nonobjc func allPostsRequest(eventKind: EventKind) -> NSFetchRequest<Event> {
        let fetchRequest = NSFetchRequest<Event>(entityName: "Event")
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \Event.createdAt, ascending: false)]
        fetchRequest.predicate = NSPredicate(
            format: "kind = %i AND author = %@",
            eventKind.rawValue,
            self
        )
        return fetchRequest
    }
    
    @nonobjc func followedWithNewNotesPredicate(since: Date) -> NSPredicate {
        let onlyFollowedAuthorsClause = "ANY followers.source = %@"
        let onlyUnreadStoriesClause = "$event.isRead != 1"
        let onlyPostsClause = "($event.kind = 1 OR $event.kind = 6 OR $event.kind = 30023)"
        let onlyRecentStoriesClause = "$event.createdAt > %@"
        let onlyRootPostsClause = "SUBQUERY(" +
            "$event.eventReferences, " +
            "$reference, " +
            "$reference.marker = 'root' OR $reference.marker = 'reply' OR $reference.marker = nil" +
        ").@count = 0"
        let onlyAuthorsWithStoriesClause = "SUBQUERY(events, $event, \(onlyPostsClause) " +
            "AND \(onlyUnreadStoriesClause) " +
            "AND \(onlyRecentStoriesClause) " +
            "AND \(onlyRootPostsClause)).@count > 0"
        return NSPredicate(
            format: "\(onlyFollowedAuthorsClause) AND \(onlyAuthorsWithStoriesClause)",
            self,
            since as CVarArg
        )
    }

    @nonobjc func followedWithNewNotes(since: Date) -> NSFetchRequest<Author> {
        let fetchRequest = NSFetchRequest<Author>(entityName: "Author")
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \Author.hexadecimalPublicKey, ascending: false)]
        fetchRequest.predicate = followedWithNewNotesPredicate(since: since)
        fetchRequest.fetchLimit = 50
        return fetchRequest
    }

    @nonobjc func storiesRequest(since: Date) -> NSFetchRequest<Event> {
        let fetchRequest = NSFetchRequest<Event>(entityName: "Event")
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \Event.createdAt, ascending: false)]
        let onlyStoriesFromTheAuthorClause = "author = %@"
        let onlyPostsClause = "(kind = 1 OR kind = 6 OR kind = 30023)"
        let onlyRecentStoriesClause = "createdAt > %@"
        let onlyRootPostsClause = "SUBQUERY(" +
            "eventReferences, " +
            "$reference, " +
            "$reference.marker = 'root' OR $reference.marker = 'reply' OR $reference.marker = nil" +
        ").@count = 0"
        fetchRequest.predicate = NSPredicate(
            format: "\(onlyStoriesFromTheAuthorClause) " +
                "AND \(onlyRecentStoriesClause) " +
                "AND \(onlyRootPostsClause) " +
                "AND \(onlyPostsClause)",
            self,
            since as CVarArg
        )
        fetchRequest.fetchLimit = 10
        return fetchRequest
    }

    @nonobjc func allEventsRequest() -> NSFetchRequest<Event> {
        let fetchRequest = NSFetchRequest<Event>(entityName: "Event")
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \Event.createdAt, ascending: false)]
        fetchRequest.predicate = NSPredicate(
            format: "author = %@",
            self
        )
        return fetchRequest
    }
    
    @nonobjc class func oneHopRequest(for author: Author) -> NSFetchRequest<Author> {
        let fetchRequest = NSFetchRequest<Author>(entityName: "Author")
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \Author.lastUpdatedContactList, ascending: false)]
        fetchRequest.predicate = NSPredicate(
            format: "hexadecimalPublicKey IN %@.follows.destination.hexadecimalPublicKey",
            author
        )
        return fetchRequest
    }

    /// Fetches all the authors who are further than 2 hops away on the social graph for the given `author`.
    static func outOfNetwork(for author: Author) -> NSFetchRequest<Author> {
        let fetchRequest = NSFetchRequest<Author>(entityName: "Author")
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \Author.hexadecimalPublicKey, ascending: false)]
        fetchRequest.predicate = NSPredicate(
            format: "NOT (ANY followers.source IN %@.follows.destination) " +
                "AND NOT (hexadecimalPublicKey IN %@.follows.destination.hexadecimalPublicKey) AND " +
                "hexadecimalPublicKey != %@.hexadecimalPublicKey AND muted = 0",
            author,
            author,
            author
        )
        return fetchRequest
    }
    
    @nonobjc public class func emptyRequest() -> NSFetchRequest<Author> {
        let fetchRequest = NSFetchRequest<Author>(entityName: "Author")
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \Author.hexadecimalPublicKey, ascending: true)]
        fetchRequest.predicate = NSPredicate.false
        return fetchRequest
    }
    
    class func all(context: NSManagedObjectContext) -> [Author] {
        let allRequest = Author.allAuthorsRequest()
        
        do {
            let results = try context.fetch(allRequest)
            return results
        } catch let error as NSError {
            print("Failed to fetch authors. Error: \(error.description)")
            return []
        }
    }
    
    func add(relay: Relay) {
        relays.insert(relay) 
        print("Adding \(relay.address ?? "") to \(hexadecimalPublicKey ?? "")")
    }
    
    @MainActor func mute(viewContext context: NSManagedObjectContext) async throws {
        guard let mutedAuthorKey = hexadecimalPublicKey, let currentAuthor = currentUser.author,
            mutedAuthorKey != currentAuthor.hexadecimalPublicKey else {
            return
        }
        
        print("Muting \(mutedAuthorKey)")
        muted = true

        var mutedList = try await loadMuteList(viewContext: context)

        mutedList.append(mutedAuthorKey)

        try await context.perform {
            do {
                let deleteRequest = Event.deleteAllPosts(by: self)
                deleteRequest.resultType = .resultTypeObjectIDs
                try context.execute(deleteRequest)
                context.refreshAllObjects()
            } catch {
                Log.error(error.localizedDescription)
            }

            if let author = try Author.find(by: mutedAuthorKey, context: context) {
                author.muted = true
            }
            try context.save()
        }
        // Publish the modified list
        await currentUser.publishMuteList(keys: Array(Set(mutedList)))
    }
    
    func remove(relay: Relay) {
        relays.remove(relay)
        print("Removed \(relay.address ?? "") from \(hexadecimalPublicKey ?? "")")
    }

    @MainActor func loadMuteList(viewContext context: NSManagedObjectContext) async throws -> [String] {
        guard let currentAuthor = currentUser.author else {
            throw CurrentUserError.authorNotFound
        }
        let request = currentAuthor.allPostsRequest(eventKind: .mute)
        let results = try context.fetch(request)
        if let mostRecentMuteList = results.first, let pTags = mostRecentMuteList.allTags as? [[String]] {
            return pTags.map { $0[1] }
        } else {
            return []
        }
    }
    
    @MainActor func unmute(viewContext context: NSManagedObjectContext) async throws {
        guard let unmutedAuthorKey = hexadecimalPublicKey, let currentAuthor = currentUser.author,
            unmutedAuthorKey != currentAuthor.hexadecimalPublicKey else {
            return
        }
        
        print("Un-muting \(unmutedAuthorKey)")
        muted = false

        var mutedList = try await loadMuteList(viewContext: context)

        mutedList.removeAll(where: { $0 == unmutedAuthorKey })

        try await context.perform {
            if let author = try Author.find(by: unmutedAuthorKey, context: context) {
                author.muted = false
            }
            try context.save()
        }

        // Publish the modified list
        await currentUser.publishMuteList(keys: Array(Set(mutedList)))
    }
}

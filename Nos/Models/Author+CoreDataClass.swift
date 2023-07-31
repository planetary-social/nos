//
//  Author+CoreDataClass.swift
//  Nos
//
//  Created by Matthew Lorentz on 1/31/23.
//
//

import Foundation
import CoreData
import Logger

@objc(Author)
public class Author: NosManagedObject {
    
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
        "https://iris.to/\(publicKey!.npub)"
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
        fetchRequest.predicate = NSPredicate(format: "name CONTAINS[cd] %@ OR displayName CONTAINS[cd] %@", name, name)
        let authors = try context.fetch(fetchRequest)
        return authors
    }
    
    @discardableResult
    class func findOrCreate(by pubKey: HexadecimalString, context: NSManagedObjectContext) throws -> Author {
        if let author = try? Author.find(by: pubKey, context: context) {
            return author
        } else {
            let author = Author(context: context)
            author.hexadecimalPublicKey = pubKey
            author.muted = false
            return author
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
    
    @MainActor @nonobjc class func inNetworkRequest(for author: Author? = nil) -> NSFetchRequest<Author> {
        var author = author
        if author == nil {
            guard let currentUser = CurrentUser.shared.author else {
                return emptyRequest()
            }
            author = currentUser
        }
        
        let fetchRequest = NSFetchRequest<Author>(entityName: "Author")
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \Author.hexadecimalPublicKey, ascending: false)]
        fetchRequest.predicate = NSPredicate(
            format: "ANY followers.source IN %@.follows.destination " +
                "OR hexadecimalPublicKey IN %@.follows.destination.hexadecimalPublicKey OR " +
                "hexadecimalPublicKey = %@.hexadecimalPublicKey",
            author!,
            author!,
            author!
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
    
    @nonobjc func followsRequest() -> NSFetchRequest<Author> {
        let fetchRequest = NSFetchRequest<Author>(entityName: "Author")
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \Author.hexadecimalPublicKey, ascending: false)]
        fetchRequest.predicate = NSPredicate(
            format: "ANY followers = %@",
            self
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
    
    func mute(context: NSManagedObjectContext) async throws {
        guard let mutedAuthorKey = hexadecimalPublicKey, let currentAuthor = await CurrentUser.shared.author,
            mutedAuthorKey != currentAuthor.hexadecimalPublicKey else {
            return
        }
        
        print("Muting \(mutedAuthorKey)")
        muted = true

        var mutedList = try await loadMuteList(context: context)

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
        await CurrentUser.shared.publishMuteList(keys: Array(Set(mutedList)))
    }
    
    func remove(relay: Relay) {
        relays.remove(relay)
        print("Removed \(relay.address ?? "") from \(hexadecimalPublicKey ?? "")")
    }

    func loadMuteList(context: NSManagedObjectContext) async throws -> [String] {
        guard let currentAuthor = await CurrentUser.shared.author else {
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
    
    func unmute(context: NSManagedObjectContext) async throws {
        guard let unmutedAuthorKey = hexadecimalPublicKey, let currentAuthor = await CurrentUser.shared.author,
            unmutedAuthorKey != currentAuthor.hexadecimalPublicKey else {
            return
        }
        
        print("Un-muting \(unmutedAuthorKey)")
        muted = false

        var mutedList = try await loadMuteList(context: context)

        mutedList.removeAll(where: { $0 == unmutedAuthorKey })

        try await context.perform {
            if let author = try Author.find(by: unmutedAuthorKey, context: context) {
                author.muted = false
            }
            try context.save()
        }

        // Publish the modified list
        await CurrentUser.shared.publishMuteList(keys: Array(Set(mutedList)))
    }
}

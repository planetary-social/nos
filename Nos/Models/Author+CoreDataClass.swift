//
//  Author+CoreDataClass.swift
//  Nos
//
//  Created by Matthew Lorentz on 1/31/23.
//
//

import Foundation
import CoreData

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
    var deepLink: URL? {
        if let npub = publicKey?.npub {
            return URL(string: "nostr:\(npub)")
        }
        return nil
    }
    
    var followedKeys: [HexadecimalString] {
        follows?.compactMap({ ($0 as? Follow)?.destination?.hexadecimalPublicKey }) ?? []
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
        return fetchRequest
    }

    @nonobjc public class func allAuthorsWithDisplayNameRequest(muted: Bool) -> NSFetchRequest<Author> {
        let fetchRequest = NSFetchRequest<Author>(entityName: "Author")
        fetchRequest.predicate = NSPredicate(format: "muted == %i AND displayName != nil", muted)
        return fetchRequest
    }
    
    @nonobjc func allPostsRequest() -> NSFetchRequest<Event> {
        let fetchRequest = NSFetchRequest<Event>(entityName: "Event")
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \Event.createdAt, ascending: false)]
        fetchRequest.predicate = NSPredicate(
            format: "(kind = %i OR kind = %i) AND author = %@", 
            EventKind.text.rawValue, 
            EventKind.repost.rawValue, 
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
                "hexadecimalPublicKey != %@.hexadecimalPublicKey",
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
        relays = (relays ?? NSSet()).adding(relay)
        print("Adding \(relay.address ?? "") to \(hexadecimalPublicKey ?? "")")
    }
    
    func deleteAllPosts(context: NSManagedObjectContext) {
        let deleteRequest = Event.deleteAllPosts(by: self)
        
        do {
            try context.execute(deleteRequest)
        } catch let error as NSError {
            print("Failed to delete texts from \(hexadecimalPublicKey ?? ""). Error: \(error.description)")
        }
        
        try? context.save()
    }
    
    func mute(context: NSManagedObjectContext) async {
        guard let mutedAuthorKey = hexadecimalPublicKey,
            mutedAuthorKey != CurrentUser.shared.publicKeyHex else {
            return
        }
        
        print("Muting \(mutedAuthorKey)")
        muted = true
        await CurrentUser.shared.publishMuteList(keys: [mutedAuthorKey])
        deleteAllPosts(context: context)
    }
    
    func remove(relay: Relay) {
        relays = relays?.removing(relay)
        print("Removed \(relay.address ?? "") from \(hexadecimalPublicKey ?? "")")
    }
    
    func unmute(context: NSManagedObjectContext) async {
        guard let unmutedAuthorKey = hexadecimalPublicKey,
            unmutedAuthorKey != CurrentUser.shared.publicKeyHex else {
            return
        }
        
        print("Un-muting \(unmutedAuthorKey)")
        muted = false
        
        let request = Event.allPostsRequest(.mute)
        
        if let results = try? context.fetch(request),
            let mostRecentMuteList = results.first,
            let pTags = mostRecentMuteList.allTags as? [[String]] {

            // Get the current list of muted keys
            var mutedList = pTags.map { $0[1] }
            mutedList.removeAll(where: { $0 == unmutedAuthorKey })

            // Publish that modified list
            await CurrentUser.shared.publishMuteList(keys: mutedList)
        }
    }
}

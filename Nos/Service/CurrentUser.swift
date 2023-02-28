//
//  CurrentUser.swift
//  Nos
//
//  Created by Christopher Jorgensen on 2/21/23.
//

import Foundation
import CoreData

enum CurrentUser {
    static var privateKey: String? {
        if let privateKeyData = KeyChain.load(key: KeyChain.keychainPrivateKey) {
            let hexString = String(decoding: privateKeyData, as: UTF8.self)
            return hexString
        }
        
        return nil
    }
    
    static var publicKey: String? {
        if let privateKey = privateKey {
            if let keyPair = KeyPair.init(privateKeyHex: privateKey) {
                print("Profile public hex: \(keyPair.publicKey.hex).")
                return keyPair.publicKey.hex
            }
        }
        return nil
    }
    
    static var context: NSManagedObjectContext?
    
    static var relayService: RelayService? {
        didSet {
            if let pubKey = publicKey {
                // Load contact list into memory from Core Data
                if let context = context,
                    let author = author(in: context),
                    let follows = author.follows as? Set<Follow> {
                    CurrentUser.follows = follows
                }
                
                // Refresh contact list and metadata from the relays
                let metadataFilter = Filter(authorKeys: [pubKey], kinds: [.metaData], limit: 1)
                relayService?.requestEventsFromAll(filter: metadataFilter)
                let contactListFilter = Filter(authorKeys: [pubKey], kinds: [.contactList], limit: 1)
                relayService?.requestEventsFromAll(filter: contactListFilter)
            }
        }
    }
    
    static var follows: Set<Follow>?
    
    static func isFollowing(key: String) -> Bool {
        guard let following = follows else {
            return false
        }
        
        let followKeys = following.compactMap({ $0.destination?.hexadecimalPublicKey })
        return followKeys.contains(key)
    }
    
    static func refreshHomeFeed() {
        var authors = follows?.compactMap { $0.destination?.hexadecimalPublicKey } ?? []
        if let pubKey = publicKey {
            authors.append(pubKey)
        }

        if !authors.isEmpty {
            let filter = Filter(authorKeys: authors, kinds: [.text], limit: 100)
            relayService?.requestEventsFromAll(filter: filter)
        }
    }
    
    static func updateFollows(pubKey: String, followKey: String, tags: [[String]], context: NSManagedObjectContext) {
        guard let relays = relayService?.allRelayAddresses else {
            print("Error: No relay service")
            return
        }
        
        var relayString = ""
        for relay in relays {
            relayString += "{\"\(relay)\":{\"write\":true,\"read\":true}"
        }
        
        let time = Int64(Date.now.timeIntervalSince1970)
        let kind = EventKind.contactList.rawValue
        var jsonEvent = JSONEvent(pubKey: pubKey, createdAt: time, kind: kind, tags: tags, content: relayString)
        
        if let privateKey = privateKey, let pair = KeyPair(privateKeyHex: privateKey) {
            do {
                try jsonEvent.sign(withKey: pair)
                let event = try EventProcessor.parse(jsonEvent: jsonEvent, in: PersistenceController.shared)
                relayService?.sendEventToAll(event: event)
            } catch {
                print("failed to update Follows \(error.localizedDescription)")
            }
        }
        
        // Refresh contact list and meta data
        let metadataFilter = Filter(authorKeys: [pubKey], kinds: [.metaData], limit: 1)
        relayService?.requestEventsFromAll(filter: metadataFilter)
        let contactListFilter = Filter(authorKeys: [followKey], kinds: [.contactList], limit: 1)
        relayService?.requestEventsFromAll(filter: contactListFilter)
    }
    
    /// Follow by public hex key
    static func follow(key: String, context: NSManagedObjectContext) {
        guard let pubKey = publicKey else {
            print("Error: No pubkey for current user")
            return
        }

        print("Following \(key)")

        var followKeys = follows?.compactMap { $0.destination?.hexadecimalPublicKey } ?? []
        followKeys.append(key)
        let tags = followKeys.map { ["p", $0] }
        
        updateFollows(pubKey: pubKey, followKey: key, tags: tags, context: context)
        
        // Refresh everyone's meta data and contact list
        refreshHomeFeed()
    }
    
    /// Unfollow by public hex key
    static func unfollow(key unfollowedKey: String, context: NSManagedObjectContext) {
        guard let pubKey = publicKey else {
            print("Error: No pubkey for current user")
            return
        }

        print("Unfollowing \(unfollowedKey)")
        
        let stillFollowingKeys = (follows ?? [])
            .compactMap { $0.destination?.hexadecimalPublicKey }
            .filter { $0 != unfollowedKey }
        let tags = stillFollowingKeys.map { ["p", $0] }

        updateFollows(pubKey: pubKey, followKey: unfollowedKey, tags: tags, context: context)

        // Delete cached texts from this person
        if let author = try? Author.find(by: unfollowedKey, context: context) {
            let deleteRequest = Event.deleteAllPosts(by: author)
            
            do {
                try context.execute(deleteRequest)
            } catch let error as NSError {
                print("Failed to delete texts from \(unfollowedKey). Error: \(error.description)")
            }
        }
    }
    
    static func author(in context: NSManagedObjectContext) -> Author? {
        if let publicKey = Self.publicKey {
            let author = try? Author.findOrCreate(by: publicKey, context: context)
            if context.hasChanges {
                try? context.save()
            }
            return author
        } else {
            return nil
        }
    }
}

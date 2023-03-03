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
                return keyPair.publicKey.hex
            }
        }
        return nil
    }
    
    static var context: NSManagedObjectContext?
    
    static var relayService: RelayService? {
        didSet {
            // Load contact list into memory from Core Data
            if let context = context,
                let author = author(in: context),
                let follows = author.follows as? Set<Follow> {
                    CurrentUser.follows = follows
            }
        }
    }
    
    static var author: Author {
        try! Author.findOrCreate(by: publicKey!, context: context!)
    }
    
    static var follows: Set<Follow>? {
        didSet {
            print("Following: \(follows?.count ?? 0)")
        }
    }
    
    static func isFollowing(author: Author) -> Bool {
        guard let following = follows, let key = author.hexadecimalPublicKey else {
            return false
        }
        
        let followKeys = following.compactMap { $0.destination?.hexadecimalPublicKey }
        return followKeys.contains(key)
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
                let event = try EventProcessor.parse(jsonEvent: jsonEvent, in: context)
                relayService?.sendEventToAll(event: event)
            } catch {
                print("failed to update Follows \(error.localizedDescription)")
            }
        }
    }
    
    /// Follow by public hex key
    static func follow(author toFollow: Author, context: NSManagedObjectContext) {
        guard let pubKey = publicKey, let followKey = toFollow.hexadecimalPublicKey else {
            print("Error: No pubkey for current user")
            return
        }

        print("Following \(followKey)")

        var followKeys = follows?.compactMap { $0.destination?.hexadecimalPublicKey } ?? []
        followKeys.append(followKey)
        let tags = followKeys.map { ["p", $0] }
        
        // Update author to add the new follow
        if let followedAuthor = try? Author.find(by: followKey, context: context) {
            // Add to the current user's follows
            let follow = try! Follow.findOrCreate(source: author, destination: followedAuthor, context: context)
            if let currentFollows = author.follows?.mutableCopy() as? NSMutableSet {
                currentFollows.add(follow)
                author.follows = currentFollows
            }

            // Add from the current user to the author's followers
            if let followedAuthorFollowers = followedAuthor.followers?.mutableCopy() as? NSMutableSet {
                followedAuthorFollowers.add(follow)
                followedAuthor.followers = followedAuthorFollowers
            }
        }
        
        updateFollows(pubKey: pubKey, followKey: followKey, tags: tags, context: context)
    }
    
    /// Unfollow by public hex key
    static func unfollow(author toUnfollow: Author, context: NSManagedObjectContext) {
        guard let pubKey = publicKey, let unfollowedKey = toUnfollow.hexadecimalPublicKey else {
            print("Error: No pubkey for current user")
            return
        }

        print("Unfollowing \(unfollowedKey)")
        
        let stillFollowingKeys = (follows ?? [])
            .compactMap { $0.destination?.hexadecimalPublicKey }
            .filter { $0 != unfollowedKey }
        let tags = stillFollowingKeys.map { ["p", $0] }
        
        // Update author to only follow those still following
        if let unfollowedAuthor = try? Author.find(by: unfollowedKey, context: context) {
            // Remove from the current user's follows
            let unfollows = Follow.follows(source: author, destination: unfollowedAuthor, context: context)
            if let currentFollows = author.follows?.mutableCopy() as? NSMutableSet {
                currentFollows.remove(unfollows)
                author.follows = currentFollows
            }
            
            // Remove from the unfollowed author's followers
            if let unfollowedAuthorFollowers = unfollowedAuthor.followers?.mutableCopy() as? NSMutableSet {
                unfollowedAuthorFollowers.remove(unfollows)
                unfollowedAuthor.followers = unfollowedAuthorFollowers
            }
        }
        
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

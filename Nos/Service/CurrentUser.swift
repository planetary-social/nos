//
//  CurrentUser.shared.swift
//  Nos
//
//  Created by Christopher Jorgensen on 2/21/23.
//

import Foundation
import CoreData
import Logger

class CurrentUser: ObservableObject {
    
    static let shared = CurrentUser()
    
    var privateKey: String? {
        if let privateKeyData = KeyChain.load(key: KeyChain.keychainPrivateKey) {
            let hexString = String(decoding: privateKeyData, as: UTF8.self)
            return hexString
        }
        
        return nil
    }
    
    var publicKey: String? {
        if let privateKey = privateKey {
            if let keyPair = KeyPair.init(privateKeyHex: privateKey) {
                return keyPair.publicKey.hex
            }
        }
        return nil
    }
    
    // swiftlint:disable implicitly_unwrapped_optional
    var context: NSManagedObjectContext!
    var relayService: RelayService! {
        didSet {
            subscribe()
        }
    }
    // swiftlint:enable implicitly_unwrapped_optional
    
    var subscriptions: [String] = []

    var editing = false

    var onboardingRelays: [Relay] = []

    var author: Author? {
        if let publicKey {
            return try? Author.findOrCreate(by: publicKey, context: context)
        }
        return nil
    }
    
    var follows: Set<Follow>? {
        let followSet = author?.follows as? Set<Follow>
        let umutedSet = followSet?.filter({
            if let author = $0.destination {
                return author.muted == false
            }
            return false
        })
        return umutedSet
    }
    
    @Published var inNetworkAuthors = [Author]()

    // Pass in relays if you want to request from something other
    // than the Current User's relays (ie onboarding)
    func subscribe(relays: [Relay]? = nil) {
        
        var relays = relays
        if relays == nil || relays?.isEmpty == true {
            // Fetch relays from Core Data
            relays = CurrentUser.shared.author?.relays?.allObjects as? [Relay] ?? []
            if relays?.isEmpty == true {
                // If we're still empty connect to all known relays hoping to get some metadata
                relays = Relay.allKnown.map {
                    Relay.findOrCreate(by: $0, context: context)
                }
            }
        }
        
        // Always listen to my changes
        if let key = publicKey {
            // Close out stale requests
            if !subscriptions.isEmpty {
                relayService.sendCloseToAll(subscriptions: subscriptions)
                subscriptions.removeAll()
            }

            let textFilter = Filter(authorKeys: [key], kinds: [.text], limit: 100)
            let textSub = relayService.requestEventsFromAll(filter: textFilter, relays: relays)
            subscriptions.append(textSub)

            let metaFilter = Filter(authorKeys: [key], kinds: [.metaData], limit: 1)
            let metaSub = relayService.requestEventsFromAll(filter: metaFilter, relays: relays)
            subscriptions.append(metaSub)
            
            let contactFilter = Filter(authorKeys: [key], kinds: [.contactList], limit: 1)
            let contactSub = relayService.requestEventsFromAll(filter: contactFilter, relays: relays)
            subscriptions.append(contactSub)
        }
    }
    
    func isFollowing(author profile: Author) -> Bool {
        guard let following = author?.follows as? Set<Follow>, let key = profile.hexadecimalPublicKey else {
            return false
        }
        
        let followKeys = following.keys
        return followKeys.contains(key)
    }
    
    func publishMetaData() {
        guard let pubKey = publicKey else {
            Log.debug("Error: no pubKey")
            return
        }

        var metaEvent = MetadataEventJSON(
            displayName: author!.displayName,
            name: author!.name,
            nip05: author!.nip05,
            about: author!.about,
            picture: author!.profilePhotoURL?.absoluteString
        ).dictionary
        
        // Tack on any unsupported fields back onto the dictionary before publish
        if let rawData = author!.rawMetadata,
            let rawJson = try? JSONSerialization.jsonObject(with: rawData),
            let rawDictionary = rawJson as? [String: AnyObject] {
            for key in rawDictionary.keys {
                if metaEvent[key] == nil, let rawValue = rawDictionary[key] as? String {
                    metaEvent[key] = rawValue
                    Log.debug("Added \(key) : \(rawValue)")
                }
            }
        }

        guard let metaData = try? JSONSerialization.data(withJSONObject: metaEvent),
            let metaString = String(data: metaData, encoding: .utf8) else {
            Log.debug("Error: Invalid meta data")
            return
        }

        let time = Int64(Date.now.timeIntervalSince1970)
        let kind = EventKind.metaData.rawValue
        var jsonEvent = JSONEvent(pubKey: pubKey, createdAt: time, kind: kind, tags: [], content: metaString)
                
        if let privateKey = privateKey, let pair = KeyPair(privateKeyHex: privateKey) {
            do {
                try jsonEvent.sign(withKey: pair)
                let event = try EventProcessor.parse(jsonEvent: jsonEvent, in: context)
                relayService.publishToAll(event: event)
            } catch {
                Log.debug("failed to update Follows \(error.localizedDescription)")
            }
        }
    }
    
    func publishContactList(tags: [[String]]) {
        guard let pubKey = publicKey else {
            Log.debug("Error: no pubKey")
            return
        }
        
        guard let relays = author?.relays?.allObjects as? [Relay] else {
            Log.debug("Error: No relay service")
            return
        }

        var relayString = "{"
        for relay in relays {
            if let address = relay.address {
                relayString += "\"\(address)\":{\"write\":true,\"read\":true},"
            }
        }
        relayString.removeLast()
        relayString += "}"
        
        let time = Int64(Date.now.timeIntervalSince1970)
        let kind = EventKind.contactList.rawValue
        var jsonEvent = JSONEvent(pubKey: pubKey, createdAt: time, kind: kind, tags: tags, content: relayString)
        
        if let privateKey = privateKey, let pair = KeyPair(privateKeyHex: privateKey) {
            do {
                try jsonEvent.sign(withKey: pair)
                let event = try EventProcessor.parse(jsonEvent: jsonEvent, in: context)
                relayService.publishToAll(event: event)
            } catch {
                Log.debug("failed to update Follows \(error.localizedDescription)")
            }
        }
        
        updateInNetworkAuthors()
    }
    
    /// Follow by public hex key
    func follow(author toFollow: Author) {
        guard let followKey = toFollow.hexadecimalPublicKey else {
            Log.debug("Error: followKey is nil")
            return
        }

        Log.debug("Following \(followKey)")

        var followKeys = follows?.keys ?? []
        followKeys.append(followKey)
        
        // Update author to add the new follow
        if let followedAuthor = try? Author.find(by: followKey, context: context), let currentUser = author {
            // Add to the current user's follows
            let follow = try! Follow.findOrCreate(source: currentUser, destination: followedAuthor, context: context)
            if let currentFollows = currentUser.follows?.mutableCopy() as? NSMutableSet {
                currentFollows.add(follow)
                currentUser.follows = currentFollows
            }

            // Add from the current user to the author's followers
            if let followedAuthorFollowers = followedAuthor.followers?.mutableCopy() as? NSMutableSet {
                followedAuthorFollowers.add(follow)
                followedAuthor.followers = followedAuthorFollowers
            }
        }
        
        try! context.save()
        publishContactList(tags: followKeys.tags)
    }
    
    /// Unfollow by public hex key
    func unfollow(author toUnfollow: Author) {
        guard let unfollowedKey = toUnfollow.hexadecimalPublicKey else {
            Log.debug("Error: unfollowedKey is nil")
            return
        }

        Log.debug("Unfollowing \(unfollowedKey)")
        
        let stillFollowingKeys = (follows ?? [])
            .keys
            .filter { $0 != unfollowedKey }
        
        // Update author to only follow those still following
        if let unfollowedAuthor = try? Author.find(by: unfollowedKey, context: context), let currentUser = author {
            // Remove from the current user's follows
            let unfollows = Follow.follows(source: currentUser, destination: unfollowedAuthor, context: context)
            if let currentFollows = currentUser.follows?.mutableCopy() as? NSMutableSet {
                currentFollows.remove(unfollows)
                currentUser.follows = currentFollows
            }
            
            // Remove from the unfollowed author's followers
            if let unfollowedAuthorFollowers = unfollowedAuthor.followers?.mutableCopy() as? NSMutableSet {
                unfollowedAuthorFollowers.remove(unfollows)
                unfollowedAuthor.followers = unfollowedAuthorFollowers
            }
        }

        publishContactList(tags: stillFollowingKeys.tags)

        // Delete cached texts from this person
        if let author = try? Author.find(by: unfollowedKey, context: context) {
            author.deleteAllPosts(context: context)
        }
    }
    
    func updateInNetworkAuthors() {
        do {
            let inNetworkAuthors = try context.fetch(Author.inNetworkRequest())
            DispatchQueue.main.async {
                self.inNetworkAuthors = inNetworkAuthors
            }
        } catch {
            Log.error("Error updating in network authors: \(error.localizedDescription)")
        }
    }
}

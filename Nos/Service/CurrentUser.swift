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
    
    /// Step 1: Get public key
    static var publicKey: String? {
        if let privateKey = CurrentUser.privateKey {
            if let keyPair = KeyPair.init(privateKeyHex: privateKey) {
                print("Profile public hex: \(keyPair.publicKey.hex).")
                return keyPair.publicKey.hex
            }
        }
        return nil
    }
    
    /// Step 2: Set relay service and get profile data
    static var relayService: RelayService? {
        didSet {
            if let key = CurrentUser.publicKey {
                let filter = Filter(authorKeys: [key], kinds: [.contactList, .metaData], limit: 2)
                CurrentUser.relayService?.requestEventsFromAll(filter: filter)
            } else {
                print("Error: no public key set for profile")
            }
        }
    }
    
    /// Step 3: Set follows
    static var follows: [Follow]? {
        didSet {
            print("Profile has \(follows?.count ?? 0) follows. Requesting texts.")
            
            let authors = follows?.map { $0.identifier! } ?? []
            let filter = Filter(authorKeys: authors, kinds: [.text], limit: 100)
            CurrentUser.relayService?.requestEventsFromAll(filter: filter)
        }
    }
    
    static func isFollowing(key: String) -> Bool {
        guard let follows = CurrentUser.follows else {
            return false
        }
        
        let followKeys = follows.map({ $0.identifier })
        return followKeys.contains(key)
    }
    
    /// Follow by public hex key
    static func follow(key: String, context: NSManagedObjectContext) {
        guard let pubKey = CurrentUser.publicKey else {
            print("Error: No pubkey for current user")
            return
        }

        print("Following \(key)")

        var follows = CurrentUser.follows?.map({ $0.identifier! }) ?? []
        follows.append(key)
        let tags = follows.map({ ["p", $0] })

        let jsonEvent = JSONEvent(id: "0",
                                  pubKey: pubKey,
                                  createdAt: Int64(Date.now.timeIntervalSince1970),
                                  kind: EventKind.contactList.rawValue,
                                  tags: tags,
                                  content: "{\"wss://nos.lol\":{\"write\":true,\"read\":true},\"wss://relay.damus.io\":{\"write\":true,\"read\":true}}",
                                  signature: "")
        
        let event = Event(context: context, jsonEvent: jsonEvent)
        event.identifier = try? event.calculateIdentifier()
        
        if let privateKey = CurrentUser.privateKey, let pair = KeyPair(privateKeyHex: privateKey) {
            try? event.sign(withKey: pair)
            CurrentUser.relayService?.sendEventToAll(event: event)
        }
        
        // Refresh everyone's meta data and contact list
        let filter = Filter(authorKeys: [pubKey, key], kinds: [.contactList, .metaData], limit: 4)
        CurrentUser.relayService?.requestEventsFromAll(filter: filter)
    }
    
    /// Unfollow by public hex key
    static func unfollow(key: String, context: NSManagedObjectContext) {
        guard let pubKey = CurrentUser.publicKey else {
            print("Error: No pubkey for current user")
            return
        }

        print("Unfollowing \(key)")
        
        let follows = CurrentUser.follows?.filter({ $0.identifier! != key }) ?? []
        let followStrings = follows.map { $0.identifier! }
        let tags = followStrings.map({ ["p", $0] })

        let jsonEvent = JSONEvent(id: "0",
                                  pubKey: pubKey,
                                  createdAt: Int64(Date.now.timeIntervalSince1970),
                                  kind: EventKind.contactList.rawValue,
                                  tags: tags,
                                  content: "{\"wss://nos.lol\":{\"write\":true,\"read\":true},\"wss://relay.damus.io\":{\"write\":true,\"read\":true}}",
                                  signature: "")
        
        let event = Event(context: context, jsonEvent: jsonEvent)
        event.identifier = try? event.calculateIdentifier()
        
        if let privateKey = CurrentUser.privateKey, let pair = KeyPair(privateKeyHex: privateKey) {
            try? event.sign(withKey: pair)
            CurrentUser.relayService?.sendEventToAll(event: event)
        }
        
        // Refresh everyone's meta data and contact list
        let contactFilter = Filter(authorKeys: [pubKey, key], kinds: [.contactList, .metaData], limit: 4)
        CurrentUser.relayService?.requestEventsFromAll(filter: contactFilter)

        // Delete cached texts from this person
        if let author = try? Author.find(by: key, context: context) {
            let deleteRequest = Event.deleteAllPosts(by: author)
            
            do {
                try context.execute(deleteRequest)
            } catch let error as NSError {
                print("Failed to delete texts from \(key). Error: \(error.description)")
            }
            
            // HACK: force clear the author's events
            author.events = NSSet()
        }
    }
}

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
    
    static var relayService: RelayService? {
        didSet {
            if let pubKey = publicKey {
                let filter = Filter(authorKeys: [pubKey], kinds: [.metaData, .contactList], limit: 2)
                relayService?.requestEventsFromAll(filter: filter)
            }
        }
    }
    
    static var follows: [Follow]?
    
    static func isFollowing(key: String) -> Bool {
        guard let following = follows else {
            return false
        }
        
        let followKeys = following.map({ $0.identifier })
        return followKeys.contains(key)
    }
    
    static func refresh() {
        var authors = follows?.map { $0.identifier! } ?? []
        if let pubKey = publicKey {
            authors.append(pubKey)
        }

        if !authors.isEmpty {
            let filter = Filter(authorKeys: authors, kinds: [.text], limit: 100)
            relayService?.requestEventsFromAll(filter: filter)
        }
    }
    
    static func updateFollows(pubKey: String, tags: [[String]], context: NSManagedObjectContext) {
        guard let relays = CurrentUser.relayService?.allRelayAddresses else {
            print("Error: No relay service")
            return
        }
        
        var relayString = ""
        for relay in relays {
            relayString += "{\"\(relay)\":{\"write\":true,\"read\":true}"
        }
        
        // swiftlint:disable line_length
        let time = Int64(Date.now.timeIntervalSince1970)
        let kind = EventKind.contactList.rawValue
        let jsonEvent = JSONEvent(id: "0", pubKey: pubKey, createdAt: time, kind: kind, tags: tags, content: relayString, signature: "")
        // swiftlint:enable line_length
        
        let event = Event(context: context, jsonEvent: jsonEvent)
        event.identifier = try? event.calculateIdentifier()
        
        if let privateKey = CurrentUser.privateKey, let pair = KeyPair(privateKeyHex: privateKey) {
            try? event.sign(withKey: pair)
            CurrentUser.relayService?.sendEventToAll(event: event)
        }
    }
    
    /// Follow by public hex key
    static func follow(key: String, context: NSManagedObjectContext) {
        guard let pubKey = CurrentUser.publicKey else {
            print("Error: No pubkey for current user")
            return
        }

        print("Following \(key)")

        var follows = CurrentUser.follows?.map { $0.identifier! } ?? []
        follows.append(key)
        let tags = follows.map { ["p", $0] }

        updateFollows(pubKey: pubKey, tags: tags, context: context)
        
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
        
        let follows = CurrentUser.follows?.filter { $0.identifier! != key } ?? []
        let followStrings = follows.map { $0.identifier! }
        let tags = followStrings.map { ["p", $0] }

        updateFollows(pubKey: pubKey, tags: tags, context: context)
        
        // Refresh everyone's meta data and contact list
        CurrentUser.follows = []
        let filter = Filter(authorKeys: [pubKey, key], kinds: [.contactList, .metaData], limit: 4)
        CurrentUser.relayService?.requestEventsFromAll(filter: filter)

        // Delete cached texts from this person
        if let author = try? Author.find(by: key, context: context) {
            let deleteRequest = Event.deleteAllPosts(by: author)
            
            do {
                try context.execute(deleteRequest)
            } catch let error as NSError {
                print("Failed to delete texts from \(key). Error: \(error.description)")
            }
        }
    }
}

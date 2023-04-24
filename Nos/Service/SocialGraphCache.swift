//
//  SocialGraphCache.swift
//  Nos
//
//  Created by Matthew Lorentz on 4/18/23.
//

import Foundation
import CoreData
import Logger

/// A representation of the people a given user follows and the people they follow designed to cache this data in 
/// memory and make it cheap to access. This class watches the database for changes to the social graph and updates 
/// itself accordingly.
@MainActor class SocialGraphCache: NSObject, ObservableObject, NSFetchedResultsControllerDelegate {
    
    // MARK: Public interface 
    
    @Published var inNetworkKeys = [HexadecimalString]()
    
    @Published var followedKeys = [HexadecimalString]()  
    
    func contains(_ key: HexadecimalString?) -> Bool {
        guard let key, let user else {
            return false
        }
        
        return twoHopKeys.contains(key) || oneHopKeys.contains(key) || user.hexadecimalPublicKey == key
    }
    
    // MARK: - Private properties
    
    private let user: Author?
    private let context: NSManagedObjectContext
    
    private var userWatcher: NSFetchedResultsController<Author>?
    private var oneHopWatcher: NSFetchedResultsController<Author>?
    
    private(set) var oneHopKeys: Set<HexadecimalString>
    private(set) var twoHopKeys: Set<HexadecimalString>
    
    private var oneHopAuthors: [HexadecimalString: Author]
    private var twoHopReferences: [HexadecimalString: Int]

    init(userKey: HexadecimalString?, context: NSManagedObjectContext) {
        self.context = context
        self.oneHopKeys = Set()
        self.twoHopKeys = Set()
        self.oneHopAuthors = [:]
        self.twoHopReferences = [:]
        
        guard let userKey else {
            self.user = nil
            super.init()
            return
        }
        
        self.user = context.performAndWait {
            try! Author.findOrCreate(by: userKey, context: context)
        }
        
        super.init()
        
        followedKeys.append(userKey)
        userWatcher = NSFetchedResultsController(
            fetchRequest: Author.request(by: userKey),
            managedObjectContext: context,
            sectionNameKeyPath: nil,
            cacheName: "SocialGraphCache.userWatcher"
        )
        oneHopWatcher = NSFetchedResultsController(
            fetchRequest: Author.oneHopRequest(for: user!),
            managedObjectContext: context,
            sectionNameKeyPath: nil,
            cacheName: "SocialGraphCache.oneHopWatcher"
        )
        
        userWatcher?.delegate = self
        try! userWatcher?.performFetch()
        oneHopWatcher?.delegate = self
        try! oneHopWatcher?.performFetch()
        oneHopWatcher?.fetchedObjects?.forEach {
            processUser(followed: $0)
        }
    }
    
    // MARK: - Processing Changes
    
    /// Takes an author that the `user` has followed and updates our cache of one-hop and two-hop authors appropriately.
    private func processUser(followed author: Author) {
        guard let authorKey = author.hexadecimalPublicKey, let user else {
            Log.error("SocialGraphCache cannot process followed author with no key")
            return
        }
        
        let oneHopKeysCount = oneHopKeys.count
        let twoHopKeysCount = twoHopKeys.count
        
        oneHopAuthors[authorKey] = author
        oneHopKeys.insert(authorKey)
        author.follows?.forEach { 
            if let follow = $0 as? Follow,
                let followedKey = follow.destination?.hexadecimalPublicKey {
                twoHopKeys.insert(followedKey)
                var referenceCount = twoHopReferences[followedKey] ?? 0
                referenceCount += 1
                twoHopReferences[followedKey] = referenceCount
            }
        }
        
        if oneHopKeysCount != oneHopKeys.count {
            followedKeys = [user.hexadecimalPublicKey!] + Array(oneHopKeys) 
            inNetworkKeys = [user.hexadecimalPublicKey!] + Array(oneHopKeys) + Array(twoHopKeys)
        } else if twoHopKeysCount != twoHopKeys.count {
            inNetworkKeys = [user.hexadecimalPublicKey!] + Array(oneHopKeys) + Array(twoHopKeys)
        }
    }
    
    /// Takes an author that the `user` has unfollowed and updates our cache of one-hop and two-hop 
    /// authors appropriately.
    private func processUser(unfollowed author: Author) {
        guard let authorKey = author.hexadecimalPublicKey, let user else {
            Log.error("SocialGraphCache cannot process unfollowed author with no key")
            return
        }
        
        let oneHopKeysCount = oneHopKeys.count
        let twoHopKeysCount = twoHopKeys.count
        
        oneHopAuthors.removeValue(forKey: authorKey)
        oneHopKeys.remove(authorKey)
        author.follows?.forEach { 
            if let follow = $0 as? Follow,
                let followedKey = follow.destination?.hexadecimalPublicKey {
                let referenceCount = twoHopReferences[followedKey] ?? 1
                if referenceCount <= 1 {
                    twoHopKeys.remove(followedKey)
                    twoHopReferences.removeValue(forKey: followedKey)
                }
            }
        }
        
        if oneHopKeysCount != oneHopKeys.count {
            followedKeys = [user.hexadecimalPublicKey!] + Array(oneHopKeys) 
            inNetworkKeys = [user.hexadecimalPublicKey!] + Array(oneHopKeys) + Array(twoHopKeys)
        } else if twoHopKeysCount != twoHopKeys.count {
            inNetworkKeys = [user.hexadecimalPublicKey!] + Array(oneHopKeys) + Array(twoHopKeys)
        }
    }
    
    // MARK: - NSFetchedResultsControllerDelegate
    
    nonisolated func controller(
        _ controller: NSFetchedResultsController<NSFetchRequestResult>, 
        didChange anObject: Any, 
        at indexPath: IndexPath?, 
        for type: NSFetchedResultsChangeType, 
        newIndexPath: IndexPath?
    ) {
        guard let author = anObject as? Author else {
            return
        }
        
        Task { @MainActor in
            if controller === oneHopWatcher {
                switch type {
                case .insert:
                    processUser(followed: author)
                case .delete:
                    processUser(unfollowed: author)
                case .update:
                    processUser(unfollowed: author)
                    processUser(followed: author)
                case .move:
                    return
                @unknown default:
                    return
                }
            } else if controller === userWatcher {
                do {
                    try oneHopWatcher?.performFetch()
                } catch {
                    fatalError("SocialGraphCache could not performFetch on oneHopWatcher")
                }
            }
        }
    }
}

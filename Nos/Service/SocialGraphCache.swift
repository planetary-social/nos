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
        guard let key, let userKey else {
            return false
        }
        
        return twoHopKeys.contains(key) || oneHopKeys.contains(key) || userKey == key
    }
    
    func follows(_ key: HexadecimalString?) -> Bool {
        guard let key, let userKey else {
            return false
        }
        
        return oneHopKeys.contains(key) || userKey == key
    }
    
    // MARK: - Private properties
    
    private let userKey: HexadecimalString?
    private let context: NSManagedObjectContext
    
    private var userWatcher: NSFetchedResultsController<Author>?
    private var oneHopWatcher: NSFetchedResultsController<Author>?
    
    private(set) var oneHopKeys: Set<HexadecimalString>
    private(set) var twoHopKeys: Set<HexadecimalString>
    
    private var twoHopReferences: [HexadecimalString: Int]

    init(userKey: HexadecimalString?, context: NSManagedObjectContext) {
        self.userKey = userKey
        self.context = context
        self.oneHopKeys = Set()
        self.twoHopKeys = Set()
        self.twoHopReferences = [:]
        
        guard let userKey else {
            super.init()
            return
        }
        
        super.init()

        do {
            try context.performAndWait {
                let user = try Author.findOrCreate(by: userKey, context: context)
                followedKeys.append(userKey)
                userWatcher = NSFetchedResultsController(
                    fetchRequest: Author.request(by: userKey),
                    managedObjectContext: context,
                    sectionNameKeyPath: nil,
                    cacheName: "SocialGraphCache.userWatcher"
                )
                oneHopWatcher = NSFetchedResultsController(
                    fetchRequest: Author.oneHopRequest(for: user),
                    managedObjectContext: context,
                    sectionNameKeyPath: nil,
                    cacheName: "SocialGraphCache.oneHopWatcher"
                )
            }
        } catch {
            Log.error(error.localizedDescription)
        }
        
        userWatcher?.delegate = self
        oneHopWatcher?.delegate = self
        do {
            try self.userWatcher?.performFetch()
            try self.oneHopWatcher?.performFetch()
            context.performAndWait {
                self.oneHopWatcher?.fetchedObjects?.forEach { author in
                    guard let followedKey = author.hexadecimalPublicKey else {
                        return
                    }
                    let twoHopsKeys = author.followedKeys
                    self.process(user: userKey, followed: followedKey, whoFollows: twoHopsKeys)
                }
            }
        } catch {
            Log.error(error.localizedDescription)
            return
        }
    }
    
    // MARK: - Processing Changes
    
    /// Takes an author that the `user` has followed and updates our cache of one-hop and two-hop authors appropriately.
    /// - Parameters:
    ///   - user: the key of the user at the center of the social graph  
    ///   - followedKey: the key of the author the user has followed
    ///   - follows: the keys of the authors `followedKey` has followed
    private func process(
        user: HexadecimalString,
        followed followedKey: HexadecimalString, 
        whoFollows follows: [HexadecimalString]
    ) {
        let oneHopKeysCount = oneHopKeys.count
        let twoHopKeysCount = twoHopKeys.count
        
        oneHopKeys.insert(followedKey)
        follows.forEach { followedKey in
            twoHopKeys.insert(followedKey)
            var referenceCount = twoHopReferences[followedKey] ?? 0
            referenceCount += 1
            twoHopReferences[followedKey] = referenceCount
        }
        
        let defaultArray = [user]
        if oneHopKeysCount != oneHopKeys.count {
            followedKeys = defaultArray + Array(oneHopKeys) 
            inNetworkKeys = defaultArray + Array(oneHopKeys) + Array(twoHopKeys)
        } else if twoHopKeysCount != twoHopKeys.count {
            inNetworkKeys = defaultArray + Array(oneHopKeys) + Array(twoHopKeys)
        }
    }
    
    /// Takes an author that the `user` has unfollowed and updates our cache of one-hop and two-hop 
    /// authors appropriately.
    /// - Parameters:
    ///   - user: the key of the user at the center of the social graph  
    ///   - unfollowedKey: the key of the author the user has unfollowed
    ///   - follows: the keys of the authors `unfollowedKey` has followed
    private func process(
        user: HexadecimalString,
        unfollowed unfollowedKey: HexadecimalString, 
        whoFollows follows: [HexadecimalString]
    ) {
        let oneHopKeysCount = oneHopKeys.count
        let twoHopKeysCount = twoHopKeys.count
        
        oneHopKeys.remove(unfollowedKey)
        follows.forEach { followedKey in
            let referenceCount = twoHopReferences[followedKey] ?? 1
            if referenceCount <= 1 {
                twoHopKeys.remove(followedKey)
                twoHopReferences.removeValue(forKey: followedKey)
            }
        }
        
        let defaultArray = [user]
        if oneHopKeysCount != oneHopKeys.count {
            followedKeys = defaultArray + Array(oneHopKeys) 
            inNetworkKeys = defaultArray + Array(oneHopKeys) + Array(twoHopKeys)
        } else if twoHopKeysCount != twoHopKeys.count {
            inNetworkKeys = defaultArray + Array(oneHopKeys) + Array(twoHopKeys)
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
        guard let userKey, 
            let changedAuthor = anObject as? Author,
            let authorKey = changedAuthor.hexadecimalPublicKey else {
            return
        }
        let twoHopsKeys = changedAuthor.followedKeys
        
        Task { @MainActor in
            if controller === self.oneHopWatcher {
                switch type {
                case .insert:
                    self.process(user: userKey, followed: authorKey, whoFollows: twoHopsKeys)
                case .delete:
                    self.process(user: userKey, unfollowed: authorKey, whoFollows: twoHopsKeys)
                case .update:
                    self.process(user: userKey, unfollowed: authorKey, whoFollows: twoHopsKeys)
                    self.process(user: userKey, followed: authorKey, whoFollows: twoHopsKeys)
                case .move:
                    return
                @unknown default:
                    return
                }
            } else if controller === self.userWatcher {
                twoHopsKeys.forEach {
                    self.process(user: authorKey, followed: $0, whoFollows: [])
                }
            }
        }
    }
}

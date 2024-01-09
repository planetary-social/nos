//
//  SocialGraphCache.swift
//  Nos
//
//  Created by Matthew Lorentz on 4/18/23.
//

import Foundation
import CoreData
import Logger
import UIKit

/// A representation of the people a given user follows and the people they follow designed to cache this data in 
/// memory and make it cheap to access. This class watches the database for changes to the social graph and updates 
/// itself accordingly.
actor SocialGraphCache: NSObject, NSFetchedResultsControllerDelegate {
    
    // MARK: Public interface 
    
    private(set) var followedKeys = Set<HexadecimalString>()
    
    func isInNetwork(_ key: HexadecimalString?) -> Bool {
        guard let key, let userKey else {
            return false
        }
        
        if followedKeys.contains(key) || twoHopKeys.contains(key) {
            Log.debug("cache hit: inNetwork")
            return true
        }
        
        if outOfNetworkKeys.contains(key) {
            Log.debug("cache hit: outOfNetwork")
            return false
        }
        
        // We haven't cached this key. Make a db request
        Log.debug("cache miss")
        do {
            let inNetwork = try context.performAndWait {
                guard let currentUser = try Author.find(by: userKey, context: context) else {
                    outOfNetworkKeys.insert(key)
                    return false
                }
                let fetchRequest = NSFetchRequest<Author>(entityName: "Author")
                fetchRequest.predicate = NSPredicate(
                    format: "hexadecimalPublicKey = %@ AND ANY followers.source IN %@.follows.destination",
                    key,
                    currentUser
                )
                return try context.count(for: fetchRequest) > 0
            }
            
            if inNetwork {
                twoHopKeys.insert(key)
            } else {
                outOfNetworkKeys.insert(key)
            }
            
            return inNetwork
        } catch {
            Log.optional(error, "Could not figure out if \(key) is inNetwork")
            return false
        }
    }
    
    func follows(_ key: HexadecimalString?) -> Bool {
        guard let key, let userKey else {
            return false
        }
        
        return followedKeys.contains(key) || userKey == key
    }
    
    // MARK: - Private properties
    
    private let userKey: HexadecimalString?
    private let context: NSManagedObjectContext
    
    private var userWatcher: NSFetchedResultsController<Author>?
    private var oneHopWatcher: NSFetchedResultsController<Author>?
    private var twoHopKeys = Set<HexadecimalString>()
    private var outOfNetworkKeys = Set<HexadecimalString>()
    
    // MARK: - Setup
    
    init(userKey: HexadecimalString?, context: NSManagedObjectContext) {
        self.userKey = userKey
        self.context = context
        super.init()
        
        Task {
            await initializeFollowList()
        }
        
        Task { @MainActor in
            NotificationCenter.default.addObserver(
                self, 
                selector: #selector(didReceiveMemoryWarning), 
                name: UIApplication.didReceiveMemoryWarningNotification, 
                object: nil
            )
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc nonisolated func didReceiveMemoryWarning() {
        Task {
            await clearCache()
        }
    }
    
    // MARK: - Processing changes
    
    func clearCache() {
        twoHopKeys.removeAll()
        outOfNetworkKeys.removeAll()
    }
    
    func initializeFollowList() async {
        guard let userKey else {
            return
        }
        let startDate = Date.now
        followedKeys.insert(userKey)
        
        do {
            try await context.perform { [self] in
                let authorRequest = Author.request(by: userKey) 
                authorRequest.relationshipKeyPathsForPrefetching = ["follows.destination.hexadecimalPublicKey"]
                self.userWatcher = NSFetchedResultsController(
                    fetchRequest: authorRequest,
                    managedObjectContext: self.context,
                    sectionNameKeyPath: nil,
                    cacheName: "SocialGraphCache.userWatcher"
                )
                if let user = try Author.find(by: userKey, context: self.context) {
                    self.oneHopWatcher = NSFetchedResultsController(
                        fetchRequest: Author.oneHopRequest(for: user),
                        managedObjectContext: self.context,
                        sectionNameKeyPath: nil,
                        cacheName: "SocialGraphCache.oneHopWatcher"
                    )
                }
                self.userWatcher?.delegate = self
                self.oneHopWatcher?.delegate = self
                try self.userWatcher?.performFetch()
                try self.oneHopWatcher?.performFetch()
                if let author = self.userWatcher?.fetchedObjects?.first {
                    process(user: userKey, followed: Set(author.followedKeys))
                }
            }
        } catch {
            Log.error(error.localizedDescription)
            return
        }
        
        let elapsedTime = Date.now.timeIntervalSince1970 - startDate.timeIntervalSince1970 
        Log.info("Finished SocialGraphCache init in \(elapsedTime) seconds.")
    }
    
    /// Takes the new set of authors that the `user` has followed and updates our cache appropriately.
    /// - Parameters:
    ///   - user: the key of the user at the center of the social graph  
    ///   - followedKey: the key of the author the user has followed
    ///   - follows: the keys of the authors `followedKey` has followed
    private func process(
        user: HexadecimalString,
        followed newFollowedKeys: Set<HexadecimalString>
    ) {
        let unfollowedKeys = followedKeys.subtracting(newFollowedKeys)
        if !unfollowedKeys.isEmpty {
            clearCache()
        }
        followedKeys = newFollowedKeys
        followedKeys.insert(user)
        outOfNetworkKeys = outOfNetworkKeys.subtracting(newFollowedKeys)
    }
    
    private func process(
        followedAuthor: HexadecimalString,
        followed newFollowedKeys: Set<HexadecimalString>
    ) async {
        outOfNetworkKeys.subtract(newFollowedKeys)
        twoHopKeys.formUnion(newFollowedKeys)
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
            let changedAuthorKey = changedAuthor.hexadecimalPublicKey else {
            return
        }
        let newFollowedKeys = Set(changedAuthor.followedKeys)
        
        Task {
            if await controller === self.oneHopWatcher {
                await process(followedAuthor: changedAuthorKey, followed: newFollowedKeys)
            } else if await controller === self.userWatcher {
                await process(user: userKey, followed: newFollowedKeys)
            }
        }
    }
}

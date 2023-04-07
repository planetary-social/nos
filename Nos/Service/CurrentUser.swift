//
//  CurrentUser.shared.swift
//  Nos
//
//  Created by Christopher Jorgensen on 2/21/23.
//

import Foundation
import CoreData
import Logger
import Dependencies

// swiftlint:disable type_body_length
class CurrentUser: NSObject, ObservableObject, NSFetchedResultsControllerDelegate {
    
    static let shared = CurrentUser(persistenceController: PersistenceController.shared)
    
    @Dependency(\.analytics) private var analytics
    
    // TODO: it's time to cache this
    var keyPair: KeyPair? {
        if let privateKey = privateKeyHex, let keyPair = KeyPair.init(privateKeyHex: privateKey) {
            return keyPair
        }
        return nil
    }
    
    func setKeyPair(_ newValue: KeyPair?) async {
        await setPrivateKeyHex(newValue?.privateKeyHex)
    }
    
    private var _privateKeyHex: String?
    
    var privateKeyHex: String? {
        _privateKeyHex
    }

    @MainActor func setPrivateKeyHex(_ newValue: String?) async {
        guard let privateKeyHex = newValue else {
            let publicStatus = KeyChain.delete(key: KeyChain.keychainPrivateKey)
            _privateKeyHex = nil
            reset()
            print("Deleted private key from keychain with status: \(publicStatus)")
            return
        }
        
        guard let keyPair = KeyPair(privateKeyHex: privateKeyHex) else {
            Log.error("CurrentUser could not initialize KeyPair from privateKeyHex.")
            return
        }
        
        let privateKeyData = Data(privateKeyHex.utf8)
        let publicStatus = KeyChain.save(key: KeyChain.keychainPrivateKey, data: privateKeyData)
        Log.info("Saved private key to keychain for user: " +
            "\(keyPair.publicKeyHex) / \(keyPair.npub). Keychain storage status: \(publicStatus)")
        _privateKeyHex = privateKeyHex
        analytics.identify(with: keyPair)
        
        reset()
    }
    
    // TODO: this is fragile
    // Reset CurrentUser state
    @MainActor func reset() {
        onboardingRelays = []
        relayService?.sendClose(subscriptions: subscriptions)
        subscriptions = []
        inNetworkAuthors = []
        if let keyPair {
            author = try? Author.findOrCreate(by: keyPair.publicKeyHex, context: viewContext)
            authorWatcher = NSFetchedResultsController(
                fetchRequest: Author.request(by: keyPair.publicKeyHex),
                managedObjectContext: viewContext,
                sectionNameKeyPath: nil,
                cacheName: nil
            )
            authorWatcher?.delegate = self
            try? authorWatcher?.performFetch()
            
            Task {
                await subscribe()
                await updateInNetworkAuthors()
                refreshFriendMetadata()
            }
        } else {
            author = nil
        }
    }
    
    var publicKeyHex: String? {
        keyPair?.publicKey.hex
    }
    
    // swiftlint:disable implicitly_unwrapped_optional
    @MainActor var viewContext: NSManagedObjectContext
    var backgroundContext: NSManagedObjectContext
    
    var relayService: RelayService! {
        didSet {
            Task {
                await subscribe()
                await updateInNetworkAuthors()
                await refreshFriendMetadata()
            }
        }
    }
    // swiftlint:enable implicitly_unwrapped_optional
    
    var subscriptions: [String] = []

    var editing = false

    var onboardingRelays: [Relay] = []

    // TODO: prevent this from being accessed from contexts other than the view context. Or maybe just get rid of it.
    @MainActor var author: Author?
    
    @MainActor var follows: Set<Follow>? {
        let followSet = author?.follows as? Set<Follow>
        let umutedSet = followSet?.filter({
            if let author = $0.destination {
                return author.muted == false
            }
            return false
        })
        return umutedSet
    }
    
    @MainActor @Published var inNetworkAuthors = [Author]()
    
    private var authorWatcher: NSFetchedResultsController<Author>?
                                             
    init(persistenceController: PersistenceController) {
        self.viewContext = persistenceController.viewContext
        self.backgroundContext = persistenceController.newBackgroundContext()
        super.init()
        if let privateKeyData = KeyChain.load(key: KeyChain.keychainPrivateKey) {
            Log.info("CurrentUser loaded a private key from keychain")
            let hexString = String(decoding: privateKeyData, as: UTF8.self)
            _privateKeyHex = hexString
            Task { @MainActor in self.reset() }
            if let keyPair {
                Log.info("CurrentUser logged in \(keyPair.publicKeyHex) / \(keyPair.npub)")
                analytics.identify(with: keyPair)
            } else {
                Log.error("CurrentUser found bad data in the keychain")
            }
        }
    }
    
    @MainActor func createAccount() async {
        let keyPair = KeyPair()!
        let author = try! Author.findOrCreate(by: keyPair.publicKeyHex, context: viewContext)
        try! viewContext.save()

        await setKeyPair(keyPair)
        analytics.generatedKey()
        
        // Recommended Relays for new user
        for address in Relay.recommended {
            _ = try? Relay(
                context: viewContext,
                address: address,
                author: author
            )
        }
        try! viewContext.save()
        
        await publishContactList(tags: [])
    }

    @MainActor func subscribe() async {
        
        var overrideRelays: [URL]?
        let userRelays = author?.relays?.allObjects as? [Relay] ?? []
        if userRelays.isEmpty {
            overrideRelays = Relay.allKnown
                .compactMap {
                    try? Relay.findOrCreate(by: $0, context: viewContext)
                }
                .compactMap { $0.addressURL }
            try? viewContext.save()
        }
        
        // Always listen to my changes
        if let key = publicKeyHex {
            // Close out stale requests
            if !subscriptions.isEmpty {
                relayService.sendCloseToAll(subscriptions: subscriptions)
                subscriptions.removeAll()
            }

            let metaFilter = Filter(authorKeys: [key], kinds: [.metaData], limit: 1)
            let metaSub = relayService.requestEventsFromAll(filter: metaFilter, overrideRelays: overrideRelays)
            subscriptions.append(metaSub)
            
            let contactFilter = Filter(authorKeys: [key], kinds: [.contactList], limit: 1)
            let contactSub = relayService.requestEventsFromAll(filter: contactFilter, overrideRelays: overrideRelays)
            subscriptions.append(contactSub)
            
            let muteListFilter = Filter(authorKeys: [key], kinds: [.mute], limit: 1)
            let muteSub = relayService.requestEventsFromAll(filter: muteListFilter, overrideRelays: overrideRelays)
            subscriptions.append(muteSub)
        }
    }
    
    @MainActor func refreshFriendMetadata() {
        guard let publicKeyHex else {
            Log.info("Skipping refreshFriendMetadata because we have no logged in user.")
            return
        }
        
        Task.detached(priority: .background) { [weak self, publicKeyHex] in
            guard let backgroundContext = self?.backgroundContext else {
                return
            }
            
            let followData = await self?.backgroundContext.perform {
                let follows = try? Author.findOrCreate(
                    by: publicKeyHex,
                    context: backgroundContext
                ).follows as? Set<Follow>
                return follows?
                    .shuffled()
                    .map { ($0.destination?.hexadecimalPublicKey, $0.destination?.lastUpdatedMetadata) }
            } ?? [(String?, Date?)]()
            
            for followData in followData {
                guard let followedKey = followData.0 else {
                    continue
                }
                let lastUpdated = followData.1
                let metaFilter = Filter(
                    authorKeys: [followedKey],
                    kinds: [.metaData],
                    limit: 1,
                    since: lastUpdated
                )
                _ = self?.relayService.requestEventsFromAll(filter: metaFilter)
                
                let contactFilter = Filter(
                    authorKeys: [followedKey],
                    kinds: [.contactList],
                    limit: 1,
                    since: lastUpdated
                )
                _ = self?.relayService.requestEventsFromAll(filter: contactFilter)
                
                // TODO: check cancellation
                // Do this slowly so we don't get rate limited
                try await Task.sleep(for: .seconds(2))
            }
        }
    }
    
    @MainActor func isFollowing(author profile: Author) -> Bool {
        guard let following = author?.follows as? Set<Follow>, let key = profile.hexadecimalPublicKey else {
            return false
        }
        
        let followKeys = following.keys
        return followKeys.contains(key)
    }
    
    @MainActor func publishMetaData() async {
        guard let pubKey = publicKeyHex else {
            Log.debug("Error: no pubKey")
            return
        }

        var metaEvent = MetadataEventJSON(
            displayName: author!.displayName,
            name: author!.name,
            nip05: author!.nip05,
            uns: author!.uns,
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
                
        if let pair = keyPair {
            do {
                try jsonEvent.sign(withKey: pair)
                let event = try EventProcessor.parse(jsonEvent: jsonEvent, from: nil, in: viewContext)
                relayService.publishToAll(event: event, context: viewContext)
            } catch {
                Log.debug("failed to update Follows \(error.localizedDescription)")
            }
        }
    }
    
    @MainActor func publishMuteList(keys: [String]) async {
        guard let pubKey = publicKeyHex else {
            Log.debug("Error: no pubKey")
            return
        }
        
        let time = Int64(Date.now.timeIntervalSince1970)
        let kind = EventKind.mute.rawValue
        var jsonEvent = JSONEvent(pubKey: pubKey, createdAt: time, kind: kind, tags: keys.pTags, content: "")
        
        if let pair = keyPair {
            do {
                try jsonEvent.sign(withKey: pair)
                let event = try EventProcessor.parse(jsonEvent: jsonEvent, from: nil, in: viewContext)
                relayService.publishToAll(event: event, context: viewContext)
            } catch {
                Log.debug("Failed to update mute list \(error.localizedDescription)")
            }
    }
    }
    
    @MainActor func publishDelete(for identifiers: [String], reason: String = "") async {
        guard let pubKey = publicKeyHex else {
            Log.debug("Error: no pubKey")
            return
        }
        
        let tags = identifiers.eTags
        let time = Int64(Date.now.timeIntervalSince1970)
        let kind = EventKind.delete.rawValue
        var jsonEvent = JSONEvent(pubKey: pubKey, createdAt: time, kind: kind, tags: tags, content: reason)
        
        if let pair = keyPair {
            do {
                try jsonEvent.sign(withKey: pair)
                let event = try EventProcessor.parse(jsonEvent: jsonEvent, from: nil, in: viewContext)
                relayService.publishToAll(event: event, context: viewContext)
            } catch {
                Log.debug("Failed to delete events \(error.localizedDescription)")
            }
        }
    }
    
    @MainActor func publishContactList(tags: [[String]]) async {
        guard let pubKey = publicKeyHex else {
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
        
        if let pair = keyPair {
            do {
                try jsonEvent.sign(withKey: pair)
                let event = try EventProcessor.parse(jsonEvent: jsonEvent, from: nil, in: viewContext)
                relayService.publishToAll(event: event, context: viewContext)
            } catch {
                Log.debug("failed to update Follows \(error.localizedDescription)")
            }
        }
    }
    
    /// Follow by public hex key
    @MainActor func follow(author toFollow: Author) async {
        guard let followKey = toFollow.hexadecimalPublicKey else {
            Log.debug("Error: followKey is nil")
            return
        }

        Log.debug("Following \(followKey)")

        var followKeys = follows?.keys ?? []
        followKeys.append(followKey)
        
        // Update author to add the new follow
        if let followedAuthor = try? Author.find(by: followKey, context: viewContext), let currentUser = author {
            let follow = try! Follow.findOrCreate(
                source: currentUser,
                destination: followedAuthor,
                context: viewContext
            )

            // Add to the current user's follows
            currentUser.follows = (currentUser.follows ?? NSSet()).adding(follow)

            // Add from the current user to the author's followers
            followedAuthor.followers = (followedAuthor.followers ?? NSSet()).adding(follow)
        }
        
        try! viewContext.save()
        await publishContactList(tags: followKeys.pTags)
    }
    
    /// Unfollow by public hex key
    @MainActor func unfollow(author toUnfollow: Author) async {
        guard let unfollowedKey = toUnfollow.hexadecimalPublicKey else {
            Log.debug("Error: unfollowedKey is nil")
            return
        }

        Log.debug("Unfollowing \(unfollowedKey)")
        
        let stillFollowingKeys = (follows ?? [])
            .keys
            .filter { $0 != unfollowedKey }
        
        // Update author to only follow those still following
        if let unfollowedAuthor = try? Author.find(by: unfollowedKey, context: viewContext), let currentUser = author {
            // Remove from the current user's follows
            let unfollows = Follow.follows(source: currentUser, destination: unfollowedAuthor, context: viewContext)

            for unfollow in unfollows {
                // Remove current user's follows
                currentUser.follows = currentUser.follows?.removing(unfollow)
                
                // Remove from the unfollowed author's followers
                unfollowedAuthor.followers = unfollowedAuthor.followers?.removing(unfollow)
            }
        }

        try! viewContext.save()
        await publishContactList(tags: stillFollowingKeys.pTags)
    }
    
    @MainActor func updateInNetworkAuthors(for user: Author? = nil) async {
        do {
            inNetworkAuthors = try viewContext.fetch(Author.inNetworkRequest(for: user))
        } catch {
            Log.error("Error updating in network authors: \(error.localizedDescription)")
        }
    }
    
    // MARK: - NSFetchedResultsControllerDelegate
    
    @MainActor func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        author = controller.fetchedObjects?.first as? Author
    }
}
// swiftlint:enable type_body_length

//
//  CurrentUser.swift
//  Nos
//
//  Created by Christopher Jorgensen on 2/21/23.
//

import Foundation
import CoreData
import Logger
import Dependencies

enum CurrentUserError: Error {
    case authorNotFound

    var description: String? {
        switch self {
        case .authorNotFound:
            return "Current user's author not found"
        }
    }
}

// swiftlint:disable type_body_length superfluous_disable_command
class CurrentUser: NSObject, ObservableObject, NSFetchedResultsControllerDelegate {
    
    @Dependency(\.analytics) private var analytics
    @Dependency(\.crashReporting) private var crashReporting
    @Dependency(\.persistenceController) private var persistenceController
    @Dependency(\.pushNotificationService) private var pushNotificationService
    @Dependency(\.relayService) private var relayService
    
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
        let status = KeyChain.save(key: KeyChain.keychainPrivateKey, data: privateKeyData)
        let hex = keyPair.publicKeyHex
        let npub = keyPair.npub
        Log.info("Saved private key to keychain for user: " + "\(hex) / \(npub). Keychain storage status: \(status)")
        _privateKeyHex = privateKeyHex
        analytics.identify(with: keyPair)
        crashReporting.identify(with: keyPair)
        
        reset()
    }
    
    var publicKeyHex: String? {
        keyPair?.publicKey.hex
    }
    
    // swiftlint:disable implicitly_unwrapped_optional
    @MainActor var viewContext: NSManagedObjectContext!
    var backgroundContext: NSManagedObjectContext!
    @Published var socialGraph: SocialGraphCache!
    // swiftlint:enable implicitly_unwrapped_optional
    
    var subscriptions: [String] = []

    var editing = false

    var onboardingRelays: [Relay] = []

    // TODO: prevent this from being accessed from contexts other than the view context. Or maybe just get rid of it.
    @MainActor @Published var author: Author?
    
    @MainActor @Published var inNetworkAuthors = [Author]()
    
    private var authorWatcher: NSFetchedResultsController<Author>?

    @MainActor override init() {
        super.init()
        self.viewContext = persistenceController.viewContext
        self.backgroundContext = persistenceController.newBackgroundContext()
        self.socialGraph = SocialGraphCache(userKey: nil, context: backgroundContext)
        if let privateKeyData = KeyChain.load(key: KeyChain.keychainPrivateKey) {
            Log.info("CurrentUser loaded a private key from keychain")
            let hexString = String(decoding: privateKeyData, as: UTF8.self)
            _privateKeyHex = hexString
            setUp()
            if let keyPair {
                Log.info("CurrentUser logged in \(keyPair.publicKeyHex) / \(keyPair.npub)")
                analytics.identify(with: keyPair)
                crashReporting.identify(with: keyPair)
            } else {
                Log.error("CurrentUser found bad data in the keychain")
            }
        }
    }
    
    // TODO: this is fragile
    // Reset CurrentUser state
    @MainActor func reset() {
        onboardingRelays = []
        Task { await relayService.decrementSubscriptionCount(for: subscriptions) }
        subscriptions = []
        inNetworkAuthors = []
        setUp()
    }
    
    @MainActor func setUp() {
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
            
            socialGraph = SocialGraphCache(userKey: keyPair.publicKeyHex, context: backgroundContext)
            
            Task {
                await subscribe()
                refreshFriendMetadata()
            }
            
            Task(priority: .background) {
                let dbStatistics = try await backgroundContext.perform {
                    try self.persistenceController.databaseStatistics(from: self.backgroundContext)
                }
                analytics.databaseStatistics(dbStatistics)
            }
        } else {
            author = nil
        }
    }
    
    @MainActor func createAccount() async throws {
        let keyPair = KeyPair()!
        let author = try Author.findOrCreate(by: keyPair.publicKeyHex, context: viewContext)
        try viewContext.save()

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
        try viewContext.save()
        
        await publishContactList(tags: [])
    }

    @MainActor func subscribe() async {
        guard let key = publicKeyHex, let author else {
            return
        }
        
        let overrideRelays: [URL]?
        let userRelays = author.relays 
        if userRelays.isEmpty {
            overrideRelays = Relay.allKnown
                .compactMap {
                    try? Relay.findOrCreate(by: $0, context: viewContext)
                }
                .compactMap { $0.addressURL }
            try? viewContext.saveIfNeeded()
        } else {
            overrideRelays = nil
        }
        
        // Close out stale requests
        if !subscriptions.isEmpty {
            await relayService.decrementSubscriptionCount(for: subscriptions)
            subscriptions.removeAll()
        }
        
        // Subscribe to our own events of all kinds.
        let latestRecievedEvent = try? viewContext.fetch(Event.lastReceived(for: author)).first
        let allEventsFilter = Filter(authorKeys: [key], since: latestRecievedEvent?.receivedAt)
        subscriptions.append(await relayService.openSubscription(with: allEventsFilter))
        
        // Always make a one time request for the latest contact list
        let contactFilter = Filter(
            authorKeys: [key],
            kinds: [.contactList],
            limit: 1,
            since: author.lastUpdatedContactList
        )
        subscriptions.append(await relayService.openSubscription(with: contactFilter, to: overrideRelays))
        
        // Listen for notifications
        await pushNotificationService.listen(for: self)
    }
    
    private var friendMetadataTask: Task<Void, any Error>?
    
    @MainActor func refreshFriendMetadata() {
        guard let publicKeyHex else {
            Log.info("Skipping refreshFriendMetadata because we have no logged in user.")
            return
        }
        
        if let friendMetadataTask {
            friendMetadataTask.cancel()
        }
        
        friendMetadataTask = Task.detached(priority: .background) { [weak self, publicKeyHex] in
            guard let backgroundContext = self?.backgroundContext else {
                return
            }
            
            let followData = await self?.backgroundContext.perform {
                let follows = try? Author.findOrCreate(
                    by: publicKeyHex,
                    context: backgroundContext
                ).follows
                return follows?
                    .shuffled()
                    .compactMap { $0.destination }
                    .map { ($0.hexadecimalPublicKey, $0.lastUpdatedMetadata, $0.lastUpdatedContactList) }
            } ?? [(String?, Date?, Date?)]()
            
            for followData in followData {
                guard let followedKey = followData.0 else {
                    continue
                }
                let lastUpdatedMetadata = followData.1
                let lastUpdatedContactList = followData.2
                let metaFilter = Filter(
                    authorKeys: [followedKey],
                    kinds: [.metaData],
                    limit: 1,
                    since: lastUpdatedMetadata
                )
                _ = await self?.relayService.openSubscription(with: metaFilter)
                
                let contactFilter = Filter(
                    authorKeys: [followedKey],
                    kinds: [.contactList],
                    limit: 1,
                    since: lastUpdatedContactList
                )
                _ = await self?.relayService.openSubscription(with: contactFilter)
                
                // Do this slowly so we don't get rate limited
                try await Task.sleep(for: .seconds(5))
                try Task.checkCancellation()
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

    @MainActor func isBeingFollowedBy(author profile: Author) -> Bool {
        let following = profile.follows
        guard let key = author?.hexadecimalPublicKey else {
            return false
        }

        let followKeys = following.keys
        return followKeys.contains(key)
    }
    
    @MainActor func publishMetaData() async {
        guard let pubKey = publicKeyHex, let author else {
            Log.debug("Error: no pubKey")
            return
        }

        var metaEvent = MetadataEventJSON(
            displayName: author.displayName,
            name: author.name,
            nip05: author.nip05,
            uns: author.uns,
            about: author.about,
            website: author.website,
            picture: author.profilePhotoURL?.absoluteString
        ).dictionary

        guard let rawData = author.rawMetadata else {
            Log.debug("Error: no author metadata")
            return
        }
        // Tack on any unsupported fields back onto the dictionary before publish
        let rawJson = try? JSONSerialization.jsonObject(with: rawData)
        if let rawJson, let rawDictionary = rawJson as? [String: AnyObject] {
            for key in rawDictionary.keys {
                if metaEvent[key] == nil, let rawValue = rawDictionary[key] as? String {
                    metaEvent[key] = rawValue
                    Log.debug("Added \(key) : \(rawValue)")
                }
            }
        }

        let metaData = try? JSONSerialization.data(withJSONObject: metaEvent)
        guard let metaData, let metaString = String(data: metaData, encoding: .utf8) else {
            Log.debug("Error: Invalid meta data")
            return
        }

        let jsonEvent = JSONEvent(pubKey: pubKey, kind: .metaData, tags: [], content: metaString)

        if let pair = keyPair {
            do {
                try await relayService.publishToAll(event: jsonEvent, signingKey: pair, context: viewContext)
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
        
        let jsonEvent = JSONEvent(pubKey: pubKey, kind: .mute, tags: keys.pTags, content: "")
        
        if let pair = keyPair {
            do {
                try await relayService.publishToAll(event: jsonEvent, signingKey: pair, context: viewContext)
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
        let jsonEvent = JSONEvent(pubKey: pubKey, kind: .delete, tags: tags, content: reason)
        
        if let pair = keyPair {
            do {
                try await relayService.publishToAll(event: jsonEvent, signingKey: pair, context: viewContext)
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
        
        guard let relays = author?.relays else {
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
        
        let jsonEvent = JSONEvent(pubKey: pubKey, kind: .contactList, tags: tags, content: relayString)
        
        if let pair = keyPair {
            do {
                try await relayService.publishToAll(event: jsonEvent, signingKey: pair, context: viewContext)
            } catch {
                Log.debug("failed to update Follows \(error.localizedDescription)")
            }
        }
    }
    
    /// Follow by public hex key
    @MainActor func follow(author toFollow: Author) async throws {
        guard let followKey = toFollow.hexadecimalPublicKey else {
            Log.debug("Error: followKey is nil")
            return
        }

        Log.debug("Following \(followKey)")

        var followKeys = socialGraph.followedKeys
        followKeys.append(followKey)
        
        // Update author to add the new follow
        if let followedAuthor = try? Author.find(by: followKey, context: viewContext), let currentUser = author {
            let follow = try Follow.findOrCreate(
                source: currentUser,
                destination: followedAuthor,
                context: viewContext
            )

            // Add to the current user's follows
            currentUser.follows.insert(follow)
        }
        
        try viewContext.save()
        await publishContactList(tags: followKeys.pTags)
    }
    
    /// Unfollow by public hex key
    @MainActor func unfollow(author toUnfollow: Author) async throws {
        guard let unfollowedKey = toUnfollow.hexadecimalPublicKey else {
            Log.debug("Error: unfollowedKey is nil")
            return
        }

        Log.debug("Unfollowing \(unfollowedKey)")
        
        let stillFollowingKeys = socialGraph.followedKeys
            .filter { $0 != unfollowedKey }
        
        // Update author to only follow those still following
        if let unfollowedAuthor = try? Author.find(by: unfollowedKey, context: viewContext), let currentUser = author {
            // Remove from the current user's follows
            let unfollows = Follow.follows(source: currentUser, destination: unfollowedAuthor, context: viewContext)

            for unfollow in unfollows {
                // Remove current user's follows
                currentUser.follows.remove(unfollow)
            }
        }

        try viewContext.save()
        await publishContactList(tags: stillFollowingKeys.pTags)
    }
    
    // MARK: - NSFetchedResultsControllerDelegate
    
    @MainActor func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        author = controller.fetchedObjects?.first as? Author
    }
}
// swiftlint:enable type_body_length superfluous_disable_command

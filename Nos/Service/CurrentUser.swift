import Foundation
import CoreData
import Logger
import Dependencies

// swiftlint:disable type_body_length
@Observable class CurrentUser: NSObject, NSFetchedResultsControllerDelegate {
    
    @ObservationIgnored @Dependency(\.analytics) private var analytics
    @ObservationIgnored @Dependency(\.crashReporting) private var crashReporting
    @ObservationIgnored @Dependency(\.persistenceController) private var persistenceController
    @ObservationIgnored @Dependency(\.pushNotificationService) private var pushNotificationService
    @ObservationIgnored @Dependency(\.relayService) private var relayService
    @ObservationIgnored @Dependency(\.keychain) private var keychain
    
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
            let publicStatus = keychain.delete(key: keychain.keychainPrivateKey)
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
        let status = keychain.save(key: keychain.keychainPrivateKey, data: privateKeyData)
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
    var socialGraph: SocialGraphCache!
    // swiftlint:enable implicitly_unwrapped_optional
    
    var subscriptions = SubscriptionCancellables()

    var onboardingRelays: [Relay] = []

    // TODO: prevent this from being accessed from contexts other than the view context. Or maybe just get rid of it.
    @MainActor var author: Author?
    
    private var authorWatcher: NSFetchedResultsController<Author>?

    @MainActor override init() {
        super.init()
        self.viewContext = persistenceController.viewContext
        self.backgroundContext = persistenceController.newBackgroundContext()
        self.socialGraph = SocialGraphCache(userKey: nil, context: persistenceController.newBackgroundContext())
        if let privateKeyData = keychain.load(key: keychain.keychainPrivateKey) {
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
        subscriptions = []
        setUp()
    }
    
    @MainActor func setUp() {
        if let keyPair {
            do {
                author = try Author.findOrCreate(by: keyPair.publicKeyHex, context: viewContext)
                try viewContext.saveIfNeeded()
                authorWatcher = NSFetchedResultsController(
                    fetchRequest: Author.request(by: keyPair.publicKeyHex),
                    managedObjectContext: viewContext,
                    sectionNameKeyPath: nil,
                    cacheName: nil
                )
                authorWatcher?.delegate = self
                try authorWatcher?.performFetch()
                
                socialGraph = SocialGraphCache(userKey: keyPair.publicKeyHex, context: backgroundContext)
                
                Task {
                    await subscribe()
                }
            } catch {
                crashReporting.report("Serious error in CurrentUser.setUp(): \(error.localizedDescription)")
                Log.optional(error)
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
            let relay = try? Relay.findOrCreate(by: address, context: viewContext)
            relay?.addToAuthors(author)
        }
        try viewContext.save()

        await followRecommendedAccounts()
    }
    
    /// Follows the nos.social and Tagr-bot accounts. Should only be called when creating a new account.
    @MainActor private func followRecommendedAccounts() async {
        let recommendedAccounts = [
            "npub1pu3vqm4vzqpxsnhuc684dp2qaq6z69sf65yte4p39spcucv5lzmqswtfch", // nos.social
            "npub12m2t8433p7kmw22t0uzp426xn30lezv3kxcmxvvcrwt2y3hk4ejsvre68j" // Tagr-bot
        ]
        for recommendedAccount in recommendedAccounts {
            do {
                guard let publicKey = PublicKey(npub: recommendedAccount) else {
                    assertionFailure(
                        "Could create public key for npub: \(recommendedAccount)\n" +
                        "Fix this invalid npub in CurrentUser.followRecommendedAccounts()"
                    )
                    continue
                }
                let author = try Author.findOrCreate(by: publicKey.hex, context: viewContext)
                try await follow(author: author)
            } catch {
                Log.error("Could not find, create, or follow author for npub: \(recommendedAccount)")
            }
        }
    }

    /// Subscribes to relays for important events concerning the current user like their latest contact list, 
    /// notifications, reports, mutes, zaps, etc.
    @MainActor func subscribe() async {
        guard let key = publicKeyHex, let author else {
            return
        }
       
        // Close out stale requests
        subscriptions.removeAll()
        
        // Always make a request for the latest contact list
        subscriptions.append(
            await relayService.requestContactList(for: key, since: author.lastUpdatedContactList)
        )
        
        // Subscribe to important events we may not get incidentally while browsing the feed
        let latestReceivedEvent = try? viewContext.fetch(Event.lastReceived(for: author)).first
        let importantEventsFilter = Filter(
            authorKeys: [key],
            kinds: [.mute, .delete, .report, .contactList, .zapRequest],
            limit: 100,
            since: latestReceivedEvent?.receivedAt,
            keepSubscriptionOpen: true
        )
        subscriptions.append(
            await relayService.fetchEvents(matching: importantEventsFilter)
        )
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
                _ = await self?.relayService.fetchEvents(matching: metaFilter)

                let contactFilter = Filter(
                    authorKeys: [followedKey],
                    kinds: [.contactList],
                    limit: 1,
                    since: lastUpdatedContactList
                )
                await self?.relayService.fetchEvents(matching: contactFilter)

                // Do this slowly so we don't get rate limited
                try await Task.sleep(for: .seconds(5))
                try Task.checkCancellation()
            }
        }
    }
    
    /// You probably shouldn't use this. It's slow and blocks the main thread. Try to use `SocialGraphCache.follows(:)`
    /// instead.
    @MainActor func isFollowing(author profile: Author) -> Bool {
        guard let following = author?.follows as? Set<Follow>, let key = profile.hexadecimalPublicKey else {
            return false
        }
        
        let followKeys = following.keys
        return followKeys.contains(key)
    }

    /// Use this sparingly. It's slow and it blocks the main thread. Try to use an `NSFetchRequest` instead.
    @MainActor func isBeingFollowedBy(author profile: Author) -> Bool {
        let following = profile.follows
        guard let key = author?.hexadecimalPublicKey else {
            return false
        }

        let followKeys = following.keys
        return followKeys.contains(key)
    }
    
    /// Builds a dictionary to be used as content when publishing a kind 0
    /// event.
    private func buildMetadataJSONObject(author: Author) -> [String: String] {
        var metaEvent = MetadataEventJSON(
            displayName: author.displayName,
            name: author.name,
            nip05: author.nip05,
            uns: author.uns,
            about: author.about,
            website: author.website,
            picture: author.profilePhotoURL?.absoluteString
        ).dictionary
        if let rawData = author.rawMetadata {
            // Tack on any unsupported fields back onto the dictionary before
            // publish.
            do {
                let rawJson = try JSONSerialization.jsonObject(with: rawData)
                if let rawDictionary = rawJson as? [String: AnyObject] {
                    for key in rawDictionary.keys {
                        guard metaEvent[key] == nil else {
                            continue
                        }
                        if let rawValue = rawDictionary[key] as? String {
                            metaEvent[key] = rawValue
                            Log.debug("Added \(key) : \(rawValue)")
                        }
                    }
                }
            } catch {
                Log.debug("Couldn't parse a JSON from the user raw metadata")
                // Continue with the metaEvent object we built previously
            }
        }
        return metaEvent
    }

    @MainActor func publishMetadata() async throws {
        guard let pubKey = publicKeyHex else {
            Log.debug("Error: no publicKeyHex")
            throw CurrentUserError.authorNotFound
        }
        guard let pair = keyPair else {
            Log.debug("Error: no keyPair")
            throw CurrentUserError.authorNotFound
        }
        guard let context = viewContext else {
            Log.debug("Error: no context")
            throw CurrentUserError.authorNotFound
        }
        guard let author = try Author.find(by: pubKey, context: context) else {
            Log.debug("Error: no author in DB")
            throw CurrentUserError.authorNotFound
        }

        self.author = author
        
        let jsonObject = buildMetadataJSONObject(author: author)
        let data = try JSONSerialization.data(withJSONObject: jsonObject)
        let content = String(decoding: data, as: UTF8.self) 

        let jsonEvent = JSONEvent(
            pubKey: pubKey,
            kind: .metaData,
            tags: [],
            content: content
        )

        do {
            try await relayService.publishToAll(
                event: jsonEvent,
                signingKey: pair,
                context: viewContext
            )
        } catch {
            Log.error(error.localizedDescription)
            throw CurrentUserError.errorWhilePublishingToRelays
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
        
        let jsonEvent = JSONEvent(pubKey: pubKey, kind: .friendList, tags: tags, content: relayString)
        
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

        var followKeys = await Array(socialGraph.followedKeys)
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
        
        let stillFollowingKeys = await Array(socialGraph.followedKeys)
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
// swiftlint:enable type_body_length

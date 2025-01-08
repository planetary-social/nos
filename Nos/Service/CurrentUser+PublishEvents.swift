import Foundation
import Logger

extension CurrentUser {
    
    /// Builds a dictionary to be used as content when publishing a kind 0
    /// event.
    private func buildMetadataJSONObject(author: Author) -> [String: String] {
        var metaEvent = MetadataEventJSON(
            displayName: author.displayName,
            name: author.name,
            nip05: author.nip05,
            about: author.about,
            website: author.website,
            picture: author.profilePhotoURL?.absoluteString,
            pronouns: author.pronouns
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
    
    @MainActor func publishNewList(
        withTitle title: String,
        description: String?,
        replaceableID: RawReplaceableID? = nil,
        authorIDs: [RawAuthorID]
    ) async {
        guard let keyPair else {
            Log.debug("Error: no pubKey")
            return
        }
        
        let jsonEvent = JSONEvent.followSet(
            pubKey: keyPair.publicKeyHex,
            title: title,
            description: description,
            replaceableID: replaceableID,
            authorIDs: authorIDs
        )
        
        do {
            try await relayService.publishToAll(event: jsonEvent, signingKey: keyPair, context: viewContext)
        } catch {
            Log.debug("Failed to create new list \(error.localizedDescription)")
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
        guard let keyPair else {
            Log.error("Error: Failed to publish contact list because there was no key pair")
            return
        }
        
        let pubKey = keyPair.publicKey.hex
        
        guard let relays = author?.relays.compactMap({ $0.address }) else {
            Log.debug("Error: No relay service")
            return
        }
        
        let jsonEvent = JSONEvent.contactList(pubKey: pubKey, tags: tags, relayAddresses: relays)
        
        do {
            let signedEvent = try await relayService.publishToAll(
                event: jsonEvent, 
                signingKey: keyPair, 
                context: viewContext
            )
            analytics.published(contactList: signedEvent)
        } catch {
            Log.debug("failed to update Follows \(error.localizedDescription)")
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
    
    @MainActor func publishAccountDeletedMetadata() async throws {
        guard let author else {
            Log.error("Error: Failed to publish account deleted metadata because there was no Author")
            return
        }
        
        author.about = nil
        author.displayName = "Account deleted"
        author.name = "Account deleted"
        author.website = nil
        author.nip05 = nil
        author.profilePhotoURL = nil
        author.rawMetadata = nil
        author.pronouns = nil
        
        try viewContext.save()
        try await publishMetadata()
    }
    
    @MainActor func publishEmptyFollowList() async throws {
        guard let author else {
            Log.error("Error: Failed to publish empty follow list because there was no Author")
            return
        }
        
        author.relays = Set()
        
        try viewContext.save()
        await publishContactList(tags: [])
    }
    
    @MainActor func publishRequestToVanish(reason: String? = nil) async throws {
        guard let keyPair else {
            Log.debug("Error: no key pair")
            return
        }
        
        let pubKey = keyPair.publicKey.hex
        let jsonEvent = JSONEvent.requestToVanish(pubKey: pubKey, reason: reason)
        
        do {
            try await relayService.publishToAll(event: jsonEvent, signingKey: keyPair, context: viewContext)
            
            if let authorRelays = author?.relays.compactMap({ $0.addressURL }),
                !authorRelays.contains(Relay.nosAddress) {
                // Make sure the NIP-62 event is always published to relay.nos.social - even if it isn't in
                // the user's relay list. This will ensure that our servers see the request and can delete their
                // data across all our web services: the relay, our push notification database, the follow
                // database, etc.
                try await relayService.publish(
                    event: jsonEvent,
                    to: Relay.nosAddress,
                    signingKey: keyPair,
                    context: viewContext
                )
            }
        } catch {
            Log.debug("Failed to publish request to vanish \(error.localizedDescription)")
        }
    }
}

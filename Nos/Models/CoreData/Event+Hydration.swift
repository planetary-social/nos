import CoreData
import Logger

extension Event {
    
    /// Populates an event stub (with only its ID set) using the data in the given JSON.
    func hydrate(from jsonEvent: JSONEvent, relay: Relay?, in context: NSManagedObjectContext) throws {
        assert(isStub, "Tried to hydrate an event that isn't a stub. This is a programming error")
        
        // if this stub was created with a replaceableIdentifier and author, it won't have an identifier yet
        identifier = jsonEvent.id

        // Meta data
        createdAt = Date(timeIntervalSince1970: TimeInterval(jsonEvent.createdAt))
        if let createdAt, createdAt > .now {
            self.createdAt = .now
        }
        content = jsonEvent.content
        kind = jsonEvent.kind
        signature = jsonEvent.signature
        sendAttempts = 0
        
        // Tags
        allTags = jsonEvent.tags as NSObject
        for tag in jsonEvent.tags {
            if tag[safe: 0] == "expiration",
                let expirationDateString = tag[safe: 1],
                let expirationDateUnix = TimeInterval(expirationDateString),
                expirationDateUnix != 0 {
                let expirationDate = Date(timeIntervalSince1970: expirationDateUnix)
                self.expirationDate = expirationDate
                if isExpired {
                    throw EventError.expiredEvent
                }
            } else if tag[safe: 0] == "d",
                let dTag = tag[safe: 1] {
                replaceableIdentifier = dTag
            }
        }
        
        // Author
        guard let newAuthor = try? Author.findOrCreate(by: jsonEvent.pubKey, context: context) else {
            throw EventError.missingAuthor
        }
        
        author = newAuthor
        
        // Relay
        relay.unwrap { markSeen(on: $0) }
        
        guard let eventKind = EventKind(rawValue: kind) else {
            throw EventError.unrecognizedKind
        }
        
        switch eventKind {
        case .contactList:
            hydrateContactList(from: jsonEvent, author: newAuthor, context: context)
            
        case .metaData:
            hydrateMetaData(from: jsonEvent, author: newAuthor, context: context)
            
        case .mute:
            try hydrateMuteList(from: jsonEvent, context: context)
        case .repost:
            
            hydrateDefault(from: jsonEvent, context: context)
            parseContent(from: jsonEvent, context: context)
            
        default:
            hydrateDefault(from: jsonEvent, context: context)
        }
    }
    
    private func hydrateContactList(
        from jsonEvent: JSONEvent,
        author newAuthor: Author,
        context: NSManagedObjectContext
    ) {
        guard createdAt! > newAuthor.lastUpdatedContactList ?? Date.distantPast else {
            return
        }
        
        newAuthor.lastUpdatedContactList = Date(timeIntervalSince1970: TimeInterval(jsonEvent.createdAt))

        // Put existing follows into a dictionary so we can avoid doing a fetch request to look up each one.
        var originalFollows = [RawAuthorID: Follow]()
        for follow in newAuthor.follows {
            if let pubKey = follow.destination?.hexadecimalPublicKey {
                originalFollows[pubKey] = follow
            }
        }
        
        var newFollows = Set<Follow>()
        for jsonTag in jsonEvent.tags where jsonTag[safe: 0] == "p" {
            if let followedKey = jsonTag[safe: 1],
                let existingFollow = originalFollows[followedKey] {
                // We already have a Core Data Follow model for this user
                newFollows.insert(existingFollow)
            } else {
                do {
                    newFollows.insert(try Follow.upsert(by: newAuthor, jsonTag: jsonTag, context: context))
                } catch {
                    Log.error("Error: could not parse Follow from: \(jsonTag)")
                }
            }
        }
        
        // Did we unfollow someone? If so, remove them from core data
        let removedFollows = Set(originalFollows.values).subtracting(newFollows)
        if !removedFollows.isEmpty {
            Log.info("Removing \(removedFollows.count) follows")
            Follow.deleteFollows(in: removedFollows, context: context)
        }
        
        newAuthor.follows = newFollows
        
        // Get the user's active relays out of the content property
        if let data = jsonEvent.content.data(using: .utf8, allowLossyConversion: false),
            let relayEntries = try? JSONSerialization.jsonObject(with: data, options: .mutableContainers),
            let relays = (relayEntries as? [String: Any])?.keys {
            newAuthor.relays = Set()

            for address in relays {
                if let relay = try? Relay.findOrCreate(by: address, context: context) {
                    newAuthor.add(relay: relay)
                }
            }
        }
    }
    
    private func hydrateDefault(from jsonEvent: JSONEvent, context: NSManagedObjectContext) {
        let newEventReferences = NSMutableOrderedSet()
        let newAuthorReferences = NSMutableOrderedSet()
        for jsonTag in jsonEvent.tags {
            if jsonTag.first == "e" {
                // TODO: validate that the tag looks like an event ref
                do {
                    let eTag = try EventReference(jsonTag: jsonTag, context: context)
                    newEventReferences.add(eTag)
                } catch {
                    print("error parsing e tag: \(error.localizedDescription)")
                }
            } else if jsonTag.first == "p" {
                // TODO: validate that the tag looks like a pubkey
                let authorReference = AuthorReference(context: context)
                authorReference.pubkey = jsonTag[safe: 1]
                authorReference.recommendedRelayUrl = jsonTag[safe: 2]
                newAuthorReferences.add(authorReference)
            }
        }
        eventReferences = newEventReferences
        authorReferences = newAuthorReferences
    }
    
    private func hydrateMetaData(from jsonEvent: JSONEvent, author newAuthor: Author, context: NSManagedObjectContext) {
        guard createdAt! > newAuthor.lastUpdatedMetadata ?? Date.distantPast else {
            // This is old data
            return
        }
        
        if let contentData = jsonEvent.content.data(using: .utf8) {
            newAuthor.lastUpdatedMetadata = Date(timeIntervalSince1970: TimeInterval(jsonEvent.createdAt))
            // There may be unsupported metadata. Store it to send back later in metadata publishes.
            newAuthor.rawMetadata = contentData

            do {
                let metadata = try JSONDecoder().decode(MetadataEventJSON.self, from: contentData)
                
                // Every event has an author created, so it just needs to be populated
                newAuthor.name = metadata.name
                newAuthor.displayName = metadata.displayName
                newAuthor.about = metadata.about
                newAuthor.profilePhotoURL = metadata.profilePhotoURL
                newAuthor.website = metadata.website
                newAuthor.nip05 = metadata.nip05
            } catch {
                print("Failed to decode metaData event with ID \(String(describing: identifier))")
            }
        }
    }
    
    private func hydrateMuteList(from jsonEvent: JSONEvent, context: NSManagedObjectContext) throws {
        guard createdAt! > author?.lastUpdatedMuteList ?? Date.distantPast else {
            return
        }
        
        author?.lastUpdatedMuteList = Date(timeIntervalSince1970: TimeInterval(jsonEvent.createdAt))
        
        let mutedKeys = Set(jsonEvent.tags.map { $0[1] })
        
        let request = Author.allAuthorsRequest(muted: true)
        
        // Un-Mute anyone (locally only) who is muted but not in the mutedKeys
        if let authors = try? context.fetch(request) {
            for author in authors where !mutedKeys.contains(author.hexadecimalPublicKey!) {
                author.muted = false
                Log.info("Parse-Un-Muted \(author.hexadecimalPublicKey ?? "")")
            }
        }
        
        // Mute anyone (locally only) in the mutedKeys
        for key in mutedKeys {
            if let author = try? Author.findOrCreate(by: key, context: context) {
                author.muted = true
                Log.info("Parse-Muted \(author.hexadecimalPublicKey ?? "")")
            }
        }
        
        // Force ensure current user never was muted
        if let signedInUserID = currentUser.publicKeyHex {
            let currentUser = try Author.find(by: signedInUserID, context: context)
            currentUser?.muted = false
        }
    }
}

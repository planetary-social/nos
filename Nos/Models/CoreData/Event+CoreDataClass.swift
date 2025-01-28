// swiftlint:disable file_length
import secp256k1
import CoreData
import Logger
import Dependencies

@objc(Event)
@Observable
public class Event: NosManagedObject, VerifiableEvent {
    @Dependency(\.currentUser) @ObservationIgnored var currentUser

    var pubKey: String { author?.hexadecimalPublicKey ?? "" }

    /// Event identifier for the note created by ``NoteComposer`` when displaying previews.
    static let previewIdentifier = "preview"
    
    class func all(context: NSManagedObjectContext) -> [Event] {
        let allRequest = Event.allPostsRequest()
        
        do {
            let results = try context.fetch(allRequest)
            return results
        } catch let error as NSError {
            print("Failed to fetch events. Error: \(error.description)")
            return []
        }
    }
    
    class func unpublishedEvents(for user: Author, context: NSManagedObjectContext) -> [Event] {
        let allRequest = Event.unpublishedEventsRequest(for: user)
        
        do {
            let results = try context.fetch(allRequest)
            return results
        } catch let error as NSError {
            print("Failed to fetch events. Error: \(error.description)")
            return []
        }
    }
    
    class func find(by identifier: RawEventID, context: NSManagedObjectContext) -> Event? {
        if let existingEvent = try? context.fetch(Event.event(by: identifier)).first {
            return existingEvent
        }

        return nil
    }
    
    // MARK: - Creating

    static func createIfNecessary(
        jsonEvent: JSONEvent,
        relay: Relay?, 
        context: NSManagedObjectContext
    ) throws -> Event? {
        // Optimization: check that no record exists before doing any fetching
        guard try context.count(for: Event.hydratedEvent(by: jsonEvent.id)) == 0 else {
            return nil
        }

        if let existingEvent = try context.fetch(Event.event(by: jsonEvent.id)).first {
            if existingEvent.isStub {
                try existingEvent.hydrate(from: jsonEvent, relay: relay, in: context)
            }
            return existingEvent
        } else {
            if let replaceableID = jsonEvent.replaceableID {
                let author = try Author.findOrCreate(by: jsonEvent.pubKey, context: context)
                let request = Event.event(by: replaceableID, author: author, kind: jsonEvent.kind)
                if let existingEvent = try context.fetch(request).first {
                    if existingEvent.isStub {
                        try existingEvent.hydrate(from: jsonEvent, relay: relay, in: context)
                    }
                    return existingEvent
                }
            }

            let event = Event(context: context)
            event.identifier = jsonEvent.id
            event.receivedAt = .now
            try event.hydrate(from: jsonEvent, relay: relay, in: context)
            return event
        }
    }

    /// Fetches the event with the given ID out of the database, and otherwise creates a stubbed Event.
    /// A stubbed event created here only has an `identifier`. We know an event with this identifier exists but we don't
    /// have its content or tags yet.
    ///  
    /// - Parameters:
    ///   - id: The hexadecimal Nostr ID of the event.
    /// - Returns: The Event model with the given ID.
    class func findOrCreateStubBy(id: RawEventID, context: NSManagedObjectContext) throws -> Event {
        if let existingEvent = try context.fetch(Event.event(by: id)).first {
            return existingEvent
        } else {
            let event = Event(context: context)
            event.identifier = id
            return event
        }
    }

    /// Fetches the event with the given replaceable ID and author ID out of the database, and otherwise
    /// creates a stubbed Event.
    /// A stubbed event created here will only have a `replaceableIdentifier` and an author. We know an event with this
    /// `replaceableIdentifier` and author exists but we don't have its content or tags yet.
    ///
    /// - Parameters:
    ///   - replaceableID: The replaceable ID of the event. This is encoded in the `d` tag.
    ///   - authorID: The public key of the author associated with the event.
    ///   - kind: The kind of the event. If this is `nil`, it's ignored. Defaults to `nil`.
    ///   - context: The managed object context to use.
    /// - Returns: The Event model with the given ID.
    class func findOrCreateStubBy(
        replaceableID: RawReplaceableID,
        authorID: RawAuthorID,
        kind: Int64,
        context: NSManagedObjectContext
    ) throws -> Event {
        let author = try Author.findOrCreate(by: authorID, context: context)
        if let existingEvent = try context.fetch(Event.event(by: replaceableID, author: author, kind: kind)).first {
            return existingEvent
        } else {
            let event = Event(context: context)
            event.replaceableIdentifier = replaceableID
            event.author = author
            event.kind = kind
            return event
        }
    }

    func markSeen(on relay: Relay) {
        seenOnRelays.insert(relay) 
    }

    /// Tries to parse a new event out of the given jsonEvent's `content` field.
    func parseContent(from jsonEvent: JSONEvent, context: NSManagedObjectContext) {
        do {
            if let contentData = jsonEvent.content.data(using: .utf8) {
                let jsonEvent = try JSONDecoder().decode(JSONEvent.self, from: contentData)
                _ = try Event.createIfNecessary(jsonEvent: jsonEvent, relay: nil, context: context)
            }
        } catch {
            Log.error("Could not parse content for jsonEvent: \(jsonEvent)")
        }
    }
    
    // MARK: - Preloading and Caching
    // Probably should refactor this stuff into a view model
    
    @MainActor var loadingViewData = false
    @MainActor var attributedContent = LoadingContent<AttributedString>.loading
    @MainActor var contentLinks = [URL]()
    @MainActor private(set) var quotedNoteID: RawEventID?
    @MainActor var relaySubscriptions = SubscriptionCancellables()
    
    /// Instructs this event to load supplementary data like author name and photo, reference events, and produce
    /// formatted `content` and cache it on this object. Idempotent.
    @MainActor func loadViewData() async {
        guard !loadingViewData else {
            return
        }
        
        loadingViewData = true
        Log.debug("\(identifier ?? "null") loading view data")
        
        await withTaskGroup(of: Void.self) { group in
            if isStub {
                group.addTask {
                    await self.loadContent()
                }
                // TODO: how do we load details for the event again after we hydrate the stub?
            } else {
                group.addTask {
                    await self.loadReferencedNote()
                }
                group.addTask {
                    await self.loadAuthorMetadata()
                }
                group.addTask {
                    await self.loadAttributedContent()
                }
            }
            
            await group.waitForAll()
        }
        loadingViewData = false
    }
    
    /// Tries to download this event from relays.
    @MainActor private func loadContent() async {
        @Dependency(\.relayService) var relayService
        if let identifier {
            relaySubscriptions.append(await relayService.requestEvent(with: identifier))
        } else if let replaceableIdentifier, let authorKey = author?.hexadecimalPublicKey {
            relaySubscriptions.append(
                await relayService.requestEvent(with: replaceableIdentifier, authorKey: authorKey)
            )
        }
    }

    /// Requests any missing metadata for authors referenced by this note from relays.
    @MainActor private func loadAuthorMetadata() async {
        @Dependency(\.relayService) var relayService
        @Dependency(\.persistenceController) var persistenceController
        let backgroundContext = persistenceController.backgroundViewContext
        relaySubscriptions.append(await Event.requestAuthorsMetadataIfNeeded(
            noteID: identifier, 
            using: relayService, 
            in: backgroundContext
        ))
    }
    
    /// Tries to load the note this note is reposting or replying to from relays.
    @MainActor private func loadReferencedNote() async {
        let referencedNote = referencedNote() ?? rootNote()
        await referencedNote?.loadViewData()
    }
    
    @MainActor private var loadingAttributedContent = false
    
    /// Processes the note `content` to populate mentions and extract links. The results are saved in 
    /// `attributedContent` and `contentLinks`. Idempotent.
    @MainActor func loadAttributedContent() async {
        guard !loadingAttributedContent else {
            return
        }
        loadingAttributedContent = true
        
        @Dependency(\.persistenceController) var persistenceController
        let backgroundContext = persistenceController.backgroundViewContext
        if let components = await Event.parsedComponents(
            note: self,
            context: backgroundContext
        ) {
            self.attributedContent = .loaded(components.attributedContent)
            self.contentLinks = components.contentLinks
            self.quotedNoteID = components.quotedNoteID
            Task { await loadFirstQuotedNote() }
        } else {
            self.attributedContent = .loaded(AttributedString(content ?? ""))
        }
        loadingAttributedContent = false
    }
    
    @MainActor func loadFirstQuotedNote() async {
        guard let quotedNoteID else {
            return
        }
        
        @Dependency(\.persistenceController) var persistenceController
        let context = persistenceController.backgroundViewContext
        
        await context.perform {
            _ = try? Event.findOrCreateStubBy(id: quotedNoteID, context: context)
            try? context.save()
        }
        
        @Dependency(\.relayService) var relayService
        relaySubscriptions.append(await relayService.requestEvent(with: quotedNoteID))
    }
    
    // MARK: - Helpers
    
    var serializedEventForSigning: [Any?] {
        [
            0,
            author?.hexadecimalPublicKey,
            Int64(createdAt!.timeIntervalSince1970),
            kind,
            allTags,
            content
        ]
    }
    
    func calculateIdentifier() throws -> String {
        let serializedEventData = try JSONSerialization.data(
            withJSONObject: serializedEventForSigning,
            options: [.withoutEscapingSlashes]
        )
        return serializedEventData.sha256
    }
    
    func sign(withKey privateKey: KeyPair) throws {
        if allTags == nil {
            allTags = [[String]]() as NSObject
        }
        identifier = try calculateIdentifier()
        if let identifier {
            var serializedBytes = try identifier.bytes
            signature = try privateKey.sign(bytes: &serializedBytes)
        } else {
            Log.error("Couldn't calculate identifier when signing a private key")
        }
    }
    
    var jsonRepresentation: [String: Any]? {
        if let jsonEvent = codable {
            do {
                let data = try JSONEncoder().encode(jsonEvent)
                return try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
            } catch {
                print("Error encoding event as JSON: \(error.localizedDescription)\n\(self)")
            }
        }
        
        return nil
    }
    
    var jsonString: String? {
        guard let jsonRepresentation,  
            let data = try? JSONSerialization.data(withJSONObject: jsonRepresentation) else {
            return nil
        }
        return String(decoding: data, as: UTF8.self)
    }
    
    var codable: JSONEvent? {
        guard let identifier = identifier,
            let pubKey = author?.hexadecimalPublicKey,
            let createdAt = createdAt,
            let content = content,
            let signature = signature else {
            return nil
        }
        
        let allTags = (allTags as? [[String]]) ?? []
        
        return JSONEvent(
            id: identifier,
            pubKey: pubKey,
            createdAt: Int64(createdAt.timeIntervalSince1970),
            kind: kind,
            tags: allTags,
            content: content,
            signature: signature
        )
    }
    
    var bech32NoteID: String? {
        guard let identifier = self.identifier,
            let identifierBytes = try? identifier.bytes else {
            return nil
        }
        return Bech32.encode(NostrIdentifierPrefix.note, baseEightData: Data(identifierBytes))
    }
    
    var seenOnRelayURLs: [String] {
        seenOnRelays.compactMap { $0.addressURL?.absoluteString }
    }
    
    class func attributedContent(
        noteID: String?,
        noteParser: NoteParser = NoteParser(),
        context: NSManagedObjectContext
    ) async -> AttributedString {
        guard let noteID else {
            return AttributedString()
        }
        
        return await context.perform {
            guard let note = try? Event.findOrCreateStubBy(id: noteID, context: context),
                let content = note.content else {
                return AttributedString()
            }
            try? context.saveIfNeeded()
            let tags = note.allTags as? [[String]] ?? []
            return noteParser.parse(
                content: content,
                tags: tags,
                context: context
            )
        }
    }
   
    /// This function formats an Event's content for display in the UI. It does things like replacing raw npub links
    /// with the author's name, and extracting any URLs so that previews can be displayed for them.
    ///
    /// The given note should be initialized in a main queue NSManagedObjectContext (probably viewContext).
    /// 
    /// - Parameter note: the note whose content should be processed.
    /// - Parameter context: the context to use for database queries - this does not need to be the same context that
    ///     `note` is in.
    /// - Returns: A tuple where the first object is the note content formatted for display, and the second is a list
    ///     of HTTP links found in the note's context.  
    @MainActor class func parsedComponents(
        note: Event,
        noteParser: NoteParser = NoteParser(),
        context: NSManagedObjectContext
    ) async -> NoteParser.NoteDisplayComponents? {
        guard let content = note.content else {
            return nil
        }
        let tags = note.allTags as? [[String]] ?? []
        
        return await context.perform {
            noteParser.components(from: content, tags: tags, context: context)
        }
    }
    
    class func deleteAll(context: NSManagedObjectContext) {
        let deleteRequest = Event.deleteAllEvents()
        
        do {
            try context.execute(deleteRequest)
        } catch let error as NSError {
            print("Failed to delete events. Error: \(error.description)")
        }
    }
    
    /// Returns true if this event tagged the given author.
    func references(author: Author) -> Bool {
        authorReferences.contains(where: { element in
            (element as? AuthorReference)?.pubkey == author.hexadecimalPublicKey
        })
    }
    
    /// Returns true if this event is a reply to an event by the given author.
    func isReply(to author: Author) -> Bool {
        eventReferences.contains(where: { element in
            let rootEvent = (element as? EventReference)?.referencedEvent
            return rootEvent?.author?.hexadecimalPublicKey == author.hexadecimalPublicKey
        })
    }
    
    /// Returns true if this event is a zap request targeting the given author.
    func isProfileZap(to author: Author) -> Bool {
        kind == EventKind.zapRequest.rawValue && references(author: author)
    }
    
    var isReply: Bool {
        rootNote() != nil || referencedNote() != nil
    }

    /// Returns `true` if this event is meant to be used to preview a note.
    ///
    /// Used by ``NoteComposer``.
    var isPreview: Bool {
        identifier == Event.previewIdentifier
    }

    var isExpired: Bool {
        if let expirationDate {
            return expirationDate <= .now
        } else {
            return false
        }
    }
    
    /// Returns the event this note is directly replying to, or nil if there isn't one.
    func referencedNote() -> Event? {
        if let rootReference = eventReferences.first(where: {
            ($0 as? EventReference)?.type == .reply
        }) as? EventReference,
            let referencedNote = rootReference.referencedEvent {
            return referencedNote
        }
        
        if let lastReference = eventReferences.lastObject as? EventReference,
            lastReference.marker == nil,
            let referencedNote = lastReference.referencedEvent {
            return referencedNote
        }
        return nil
    }
    
    /// Returns the root event of the thread that this note is replying to, or nil if there isn't one.
    func rootNote() -> Event? {
        let rootReference = eventReferences.first(where: {
            ($0 as? EventReference)?.type == .root
        }) as? EventReference
        
        if let rootReference, let rootNote = rootReference.referencedEvent {
            return rootNote
        }
        return nil
    }
    
    /// Returns the event this note is reposting, if this note is a kind 6 repost.
    func repostedNote() -> Event? {
        guard kind == EventKind.repost.rawValue else {
            return nil
        }
        
        if let reference = eventReferences.firstObject as? EventReference,
            let repostedNote = reference.referencedEvent {
            return repostedNote
        }
        
        return nil
    }

    /// This tracks which relays this event is deleted on. Hide posts with deletedOn.count > 0
    func trackDelete(on relay: Relay, context: NSManagedObjectContext) throws {
        guard EventKind(rawValue: kind) == .delete,
            let tags = allTags as? [[String]] else {
            return
        }
        
        let eTags = tags.filter { $0.first == "e" && $0.count >= 2 }
        
        for deletedEventId in eTags.map({ $0[1] }) {
            if let deletedEvent = Event.find(by: deletedEventId, context: context),
                deletedEvent.author?.hexadecimalPublicKey == author?.hexadecimalPublicKey {
                print("\(deletedEvent.identifier ?? "n/a") was deleted on \(relay.address ?? "unknown")")
                deletedEvent.deletedOn.insert(relay)
            }
        }
        
        // track deleted replaceable events
        // ["a", "<kind>:<pubkey>:<d-identifier>"]
        if let author, let createdAt {
            let aTags = tags.filter { $0.first == "a" && $0.count >= 2 }
            
            for aTag in aTags.map({ $0[1] }) {
                let components = aTag.split(separator: ":").map { String($0) }
                guard let pubkey = components[safe: 1],
                    pubkey == author.hexadecimalPublicKey else {
                    // ensure that this delete event only affects events with the author's pubkey
                    continue
                }
                
                guard let kind = Int64(components[0]) else {
                    continue
                }
                
                let replaceableID = components[2]
                let request = Event.event(by: replaceableID, author: author, kind: kind, before: createdAt)
                
                let results = try context.fetch(request)
                for event in results {
                    print("\(event.identifier ?? "n/a") was deleted on \(relay.address ?? "unknown")")
                    event.deletedOn.insert(relay)
                }
            }
        }
    }
    
    class func requestAuthorsMetadataIfNeeded(
        noteID: RawEventID?,
        using relayService: RelayService,
        in context: NSManagedObjectContext
    ) async -> SubscriptionCancellable {
        guard let noteID else {
            return SubscriptionCancellable(subscriptionIDs: [], relayService: relayService)
        }
        
        let requestData: [(RawAuthorID?, Date?)] = await context.perform {
            guard let note = try? Event.findOrCreateStubBy(id: noteID, context: context),
                let authorKey = note.author?.hexadecimalPublicKey else {
                return []
            }
        
            var requestData = [(RawAuthorID?, Date?)]()
            
            guard let author = try? Author.findOrCreate(by: authorKey, context: context) else {
                Log.debug("Author not found when requesting metadata of a note's author")
                return []
            }
            
            if author.needsMetadata {
                requestData.append((author.hexadecimalPublicKey, author.lastUpdatedMetadata))
            }
            
            note.authorReferences.forEach { reference in
                if let reference = reference as? AuthorReference,
                    let pubKey = reference.pubkey,
                    let author = try? Author.findOrCreate(by: pubKey, context: context),
                    author.needsMetadata {
                    requestData.append((author.hexadecimalPublicKey, author.lastUpdatedMetadata))
                }
            }
            
            try? context.saveIfNeeded()
            return requestData
        }
        
        var cancellables = [SubscriptionCancellable]()
        for requestDatum in requestData {
            let authorKey = requestDatum.0
            let sinceDate = requestDatum.1
            cancellables.append(await relayService.requestMetadata(for: authorKey, since: sinceDate))
        }
        
        return SubscriptionCancellable(cancellables: cancellables, relayService: relayService)
    }

    /// Gets a list of `Author` objects based on the current `authorReferences`
    /// by using their public keys in the provided context.
    ///
    /// - Parameter context: The `NSManagedObjectContext` used to find or create `Author` objects.
    /// - Returns: An array of `Author` objects that correspond to the `authorReferences`.
    func loadAuthorsFromReferences(in context: NSManagedObjectContext) -> [Author] {
        var authors: [Author] = []
        authorReferences.forEach { reference in
            if let reference = reference as? AuthorReference,
            let pubKey = reference.pubkey,
            let author = try? Author.findOrCreate(by: pubKey, context: context) {
                authors.append(author)
            }
        }
        return authors
    }

    var webLink: String {
        if let bech32NoteID {
            return "https://njump.me/\(bech32NoteID)"
        } else {
            Log.error("Couldn't find a bech32note key when generating web link")
            return "https://njump.me"
        }
    }
    
    /// Returns true if this event doesn't have content. Usually this means we saw it referenced by another event
    /// but we haven't actually downloaded it yet.
    var isStub: Bool {
        author == nil || createdAt == nil || identifier == nil
    }
    
    /// Converts an event back to a stubbed event by resetting most properties and leaving the `identifier` in place.
    func resetToStub() {
        allTags = nil
        content = nil
        createdAt = nil
        isVerified = false
        receivedAt = nil
        sendAttempts = 0
        signature = nil
        author = nil
        authorReferences = NSOrderedSet()
        deletedOn = Set()
        eventReferences = NSOrderedSet()
        publishedTo = Set()
        seenOnRelays = Set()
        shouldBePublishedTo = Set()
    }
}
// swiftlint:enable file_length

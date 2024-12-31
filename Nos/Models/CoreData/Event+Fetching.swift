import CoreData

extension Event {
    
    @nonobjc public class func allEventsRequest() -> NSFetchRequest<Event> {
        let fetchRequest = NSFetchRequest<Event>(entityName: "Event")
        fetchRequest.sortDescriptors = [
            NSSortDescriptor(keyPath: \Event.createdAt, ascending: true),
            NSSortDescriptor(keyPath: \Event.receivedAt, ascending: true)
        ]
        return fetchRequest
    }
    
    @nonobjc public class func allPostsRequest(_ eventKind: EventKind = .text) -> NSFetchRequest<Event> {
        let fetchRequest = NSFetchRequest<Event>(entityName: "Event")
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \Event.createdAt, ascending: false)]
        fetchRequest.predicate = NSPredicate(format: "kind = %i", eventKind.rawValue)
        return fetchRequest
    }
    
    @nonobjc public class func allMentionsPredicate(for user: Author) -> NSPredicate {
        guard let publicKey = user.hexadecimalPublicKey, !publicKey.isEmpty else {
            return NSPredicate.false
        }
        
        return NSPredicate(
            format: "kind = %i AND ANY authorReferences.pubkey = %@ AND deletedOn.@count = 0",
            EventKind.text.rawValue,
            publicKey
        )
    }

    @nonobjc public class func unpublishedEventsRequest(for user: Author) -> NSFetchRequest<Event> {
        let fetchRequest = NSFetchRequest<Event>(entityName: "Event")
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \Event.createdAt, ascending: false)]
        fetchRequest.predicate = NSPredicate(
            format: "author.hexadecimalPublicKey = %@ AND " +
            "SUBQUERY(shouldBePublishedTo, $relay, TRUEPREDICATE).@count > " +
            "SUBQUERY(publishedTo, $relay, TRUEPREDICATE).@count AND " +
            "deletedOn.@count = 0",
            user.hexadecimalPublicKey ?? ""
        )
        return fetchRequest
    }
    
    @nonobjc public class func allRepliesPredicate(for user: Author) -> NSPredicate {
        NSPredicate(
            format: "kind = 1 AND ANY eventReferences.referencedEvent.author = %@ AND deletedOn.@count = 0",
            user
        )
    }
    
    @nonobjc public class func allZapsPredicate(for user: Author) -> NSPredicate {
        guard let publicKey = user.hexadecimalPublicKey, !publicKey.isEmpty else {
            return NSPredicate.false
        }
        
        return NSPredicate(
            format: "kind = %i AND ANY authorReferences.pubkey = %@ AND deletedOn.@count = 0",
            EventKind.zapRequest.rawValue,
            publicKey
        )
    }
    
    /// A request for all events that the given user should receive a notification for.
    /// - Parameters:
    ///   - user: the author you want to view notifications for.
    ///   - since: a date that will be used as a lower bound for the request.
    ///   - limit: a max number of events to fetch.
    /// - Returns: A fetch request for the events described.
    @nonobjc public class func all(
        notifying user: Author,
        since: Date? = nil,
        limit: Int? = nil
    ) -> NSFetchRequest<Event> {
        let fetchRequest = NSFetchRequest<Event>(entityName: "Event")
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \Event.createdAt, ascending: false)]
        if let limit {
            fetchRequest.fetchLimit = limit
        }
        
        let mentionsPredicate = allMentionsPredicate(for: user)
        let repliesPredicate = allRepliesPredicate(for: user)
        let zapsPredicate = allZapsPredicate(for: user)
        let notSelfPredicate = NSPredicate(format: "author != %@", user)
        let notMuted = NSPredicate(format: "author.muted == 0", user)
        let allNotificationsPredicate = NSCompoundPredicate(
            orPredicateWithSubpredicates: [mentionsPredicate, repliesPredicate, zapsPredicate]
        )
        var andPredicates = [allNotificationsPredicate, notSelfPredicate, notMuted]
        if let since {
            let sincePredicate = NSPredicate(format: "receivedAt >= %@", since as CVarArg)
            andPredicates.append(sincePredicate)
        }
        fetchRequest.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: andPredicates)
        
        return fetchRequest
    }
    
    @nonobjc public class func lastReceived(for user: Author) -> NSFetchRequest<Event> {
        let fetchRequest = NSFetchRequest<Event>(entityName: "Event")
        fetchRequest.predicate = NSPredicate(format: "author != %@", user)
        fetchRequest.fetchLimit = 1
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \Event.receivedAt, ascending: false)]
        return fetchRequest
    }
    
    @nonobjc public class func allReplies(to rootEvent: Event) -> NSFetchRequest<Event> {
        allReplies(toNoteWith: rootEvent.identifier)
    }
        
    @nonobjc public class func allReplies(toNoteWith noteID: String?) -> NSFetchRequest<Event> {
        guard let noteID else {
            return emptyRequest()
        }
        
        let replyNoteReferences = "kind = 1 " +
            "AND ANY eventReferences.referencedEvent.identifier == %@ " +
            "AND author.muted = false"
        
        let fetchRequest = NSFetchRequest<Event>(entityName: "Event")
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \Event.receivedAt, ascending: false)]
        fetchRequest.predicate = NSPredicate(
            format: replyNoteReferences,
            noteID
        )
        return fetchRequest
    }

    /// A request for all events that responded to a specific note.
    ///
    /// - Parameter noteID: ID of the note to retrieve replies for.
    ///
    /// Intended to be used primarily to compute the number of replies and for
    /// building a set of author avatars.
    @nonobjc public class func replies(to noteID: RawEventID) -> NSFetchRequest<Event> {
        let format = """
            SUBQUERY(
                eventReferences,
                $e,
                $e.referencedEvent.identifier = %@ AND
                    ($e.marker = 'reply' OR $e.marker = 'root')
            ).@count > 0
        """

        let predicate = NSCompoundPredicate(
            andPredicateWithSubpredicates: [
                NSPredicate(format: "kind = 1"),
                NSPredicate(
                    format: format,
                    noteID,
                    noteID
                ),
                NSPredicate(format: "deletedOn.@count = 0"),
                NSPredicate(format: "author.muted = false")
            ]
        )

        let fetchRequest = Event.fetchRequest()
        fetchRequest.includesPendingChanges = false
        fetchRequest.includesSubentities = false
        fetchRequest.sortDescriptors = [
            NSSortDescriptor(keyPath: \Event.identifier, ascending: true)
        ]

        fetchRequest.predicate = predicate
        fetchRequest.relationshipKeyPathsForPrefetching = ["author"]
        return fetchRequest
    }

    /// A fetch request for all the events that should be cleared out of the database by
    /// `DatabaseCleaner.cleanupEntities(...)`.
    ///
    /// It will save the events for the given `user`, as well as other important events matching various other
    /// criteria.
    /// - Parameter before: The date before which events will be considered for cleanup.
    /// - Parameter user: The Author record for the currently logged in user. Special treatment is given to their data.
    @nonobjc public class func cleanupRequest(before date: Date, for user: Author) -> NSFetchRequest<Event> {
        let oldStoryCutoff = Calendar.current.date(byAdding: .day, value: -2, to: .now) ?? .now
        
        let request = NSFetchRequest<Event>(entityName: "Event")
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Event.receivedAt, ascending: true)]
        let oldUnreferencedEventsClause = "(receivedAt < %@ OR receivedAt == nil) AND referencingEvents.@count = 0"
        let notOwnEventClause = "(author != %@)"
        let readStoryClause = "(isRead = 1 AND receivedAt > %@)"
        let userReportClause = "(kind == \(EventKind.report.rawValue) AND " +
        "authorReferences.@count > 0 AND eventReferences.@count == 0)"
        let clauses = "\(oldUnreferencedEventsClause) AND" +
        "\(notOwnEventClause) AND " +
        "NOT \(readStoryClause) AND " +
        "NOT \(userReportClause)"
        request.predicate = NSPredicate(
            format: clauses,
            date as CVarArg,
            user,
            oldStoryCutoff as CVarArg
        )
        
        return request
    }
    
    /// This constructs a predicate for events that should be protected from deletion when we are purging the database.
    /// - Parameter user: The Author record for the currently logged in user. Special treatment is given to their data.
    /// - Parameter asSubquery: If true then each attribute in the predicate will prefixed with "$event." so the
    ///   predicate can be used in a SUBQUERY.
    @nonobjc public class func protectedFromCleanupPredicate(
        for user: Author,
        asSubquery: Bool = false
    ) -> NSPredicate {
        guard let userKey = user.hexadecimalPublicKey else {
            return NSPredicate.false
        }
        
        // The string we use to reference the current event if we are constructing this predicate to be used in a
        // subquery
        let eventReference = asSubquery ? "$event." : ""
        
        // protect all events authored by the current user
        let userEventsPredicate = NSPredicate(format: "\(eventReference)author.hexadecimalPublicKey = '\(userKey)'")
        
        // protect stories that were read recently, so we don't redownload and show them as unread again
        let oldStoryCutoffDate = Calendar.current.date(byAdding: .day, value: -2, to: .now) ?? .now
        let recentlyReadStoriesPredicate = NSPredicate(
            format: "(\(eventReference)isRead = 1 AND \(eventReference)receivedAt > %@)",
            oldStoryCutoffDate as CVarArg
        )
        
        // keep author reports from people we follow
        let userReportPredicate = NSPredicate(
            format: "(\(eventReference)kind == \(EventKind.report.rawValue) AND " +
                "SUBQUERY(\(eventReference)authorReferences, $references, TRUEPREDICATE).@count > 0 AND " +
                "SUBQUERY(\(eventReference)eventReferences, $references, TRUEPREDICATE).@count == 0 AND " +
                "ANY \(eventReference)author.followers.source.hexadecimalPublicKey == %@)",
            userKey
        )
        
        return NSCompoundPredicate(
            orPredicateWithSubpredicates: [
                userEventsPredicate,
                recentlyReadStoriesPredicate,
                userReportPredicate
            ]
        )
    }
    
    @nonobjc public class func expiredRequest() -> NSFetchRequest<Event> {
        let fetchRequest = NSFetchRequest<Event>(entityName: "Event")
        fetchRequest.predicate = NSPredicate(format: "expirationDate <= %@", Date.now as CVarArg)
        return fetchRequest
    }

    /// Builds a query that returns an Event with "preview" as its `identifier` if it exists.
    /// - Returns: A Fetch Request with the necessary query inside.
    @nonobjc public class func previewRequest() -> NSFetchRequest<Event> {
        let fetchRequest = NSFetchRequest<Event>(entityName: "Event")
        fetchRequest.predicate = NSPredicate(
            format: "identifier = %@",
            Event.previewIdentifier as CVarArg
        )
        return fetchRequest
    }

    @nonobjc public class func event(by identifier: RawEventID) -> NSFetchRequest<Event> {
        let fetchRequest = NSFetchRequest<Event>(entityName: "Event")
        fetchRequest.predicate = NSPredicate(format: "identifier = %@", identifier)
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \Event.identifier, ascending: true)]
        fetchRequest.fetchLimit = 1
        return fetchRequest
    }
    
    @nonobjc public class func event(
        by replaceableID: RawReplaceableID,
        author: Author,
        kind: Int64
    ) -> NSFetchRequest<Event> {
        let fetchRequest = NSFetchRequest<Event>(entityName: "Event")
        fetchRequest.predicate = NSPredicate(
            format: "replaceableIdentifier = %@ AND author = %@ AND kind = %i",
            replaceableID,
            author,
            kind
        )
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \Event.replaceableIdentifier, ascending: true)]
        fetchRequest.fetchLimit = 1
        return fetchRequest
    }
    
    @nonobjc public class func hydratedEvent(by identifier: String) -> NSFetchRequest<Event> {
        let fetchRequest = NSFetchRequest<Event>(entityName: "Event")
        fetchRequest.predicate = NSPredicate(
            format: "identifier = %@ AND createdAt != nil AND author != nil", identifier
        )
        fetchRequest.fetchLimit = 1
        return fetchRequest
    }
    
    @nonobjc public class func event(by identifier: String, seenOn relay: Relay) -> NSFetchRequest<Event> {
        guard let relayAddress = relay.address else {
            return Event.emptyRequest()
        }
        
        let fetchRequest = NSFetchRequest<Event>(entityName: "Event")
        fetchRequest.predicate = NSPredicate(
            format: "identifier = %@ AND ANY seenOnRelays.address = %@",
            identifier,
            relayAddress
        )
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \Relay.createdAt, ascending: true)]
        fetchRequest.fetchLimit = 1
        return fetchRequest
    }
    
    /// Returns a predicate that can be used to fetch the given user's home feed.
    /// - Parameters:
    ///   - user: The user whose home feed should appear.
    ///   - before: Only fetch events that were created before this date. Defaults to `nil`.
    ///   - after: Only fetch events that were created after this date. Defaults to `nil`.
    ///   - relay: Only fetch events on this relay. Defaults to `nil`, which uses all the user's relays.
    /// - Returns: A predicate matching the given parameters that can be used to fetch the user's home feed.
    @nonobjc private class func homeFeedPredicate(
        for user: Author,
        before: Date? = nil,
        after: Date? = nil,
        seenOn relay: Relay? = nil,
        from authors: Set<Author>? = nil
    ) -> NSPredicate {
        let kind1Predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
            NSPredicate(format: "kind = 1"),
            NSPredicate(
                format: "SUBQUERY(" +
                "eventReferences, $reference, $reference.marker = 'root'" +
                " OR $reference.marker = 'reply'" +
                " OR $reference.marker = nil" +
                ").@count = 0"
            ),
            NSPredicate(
                format: "identifier != %@",
                Event.previewIdentifier as CVarArg
            )
        ])
        let kind6Predicate = NSPredicate(format: "kind = 6")
        let kind30023Predicate = NSPredicate(format: "kind = 30023")

        let kindsPredicate = NSCompoundPredicate(orPredicateWithSubpredicates: [
            kind1Predicate,
            kind6Predicate,
            kind30023Predicate
        ])

        let notMutedPredicate = NSPredicate(format: "author.muted = 0")
        let notDeletedPredicate = NSPredicate(format: "deletedOn.@count = 0")

        var andPredicates = [kindsPredicate, notMutedPredicate, notDeletedPredicate]

        if let before {
            andPredicates.append(NSPredicate(format: "createdAt <= %@", before as CVarArg))
        }

        if let after {
            andPredicates.append(NSPredicate(format: "createdAt > %@", after as CVarArg))
        }

        if let relay {
            andPredicates.append(NSPredicate(format: "ANY seenOnRelays = %@", relay as CVarArg))
        } else {
            andPredicates.append(
                NSPredicate(format: "(ANY author.followers.source = %@ OR author = %@)", user, user)
            )
        }
        
        if let authors {
            andPredicates.append(
                NSPredicate(format: "author IN %@", authors)
            )
        }

        return NSCompoundPredicate(andPredicateWithSubpredicates: andPredicates)
    }

    @nonobjc public class func homeFeed(
        for user: Author,
        before: Date,
        seenOn relay: Relay? = nil,
        from authors: Set<Author>? = nil
    ) -> NSFetchRequest<Event> {
        let fetchRequest = NSFetchRequest<Event>(entityName: "Event")
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \Event.createdAt, ascending: false)]
        fetchRequest.predicate = homeFeedPredicate(for: user, before: before, seenOn: relay, from: authors)
        return fetchRequest
    }

    @nonobjc public class func homeFeed(
        for user: Author,
        after: Date,
        seenOn relay: Relay? = nil,
        from authors: Set<Author>? = nil
    ) -> NSFetchRequest<Event> {
        let fetchRequest = NSFetchRequest<Event>(entityName: "Event")
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \Event.createdAt, ascending: false)]
        fetchRequest.predicate = homeFeedPredicate(for: user, after: after, seenOn: relay, from: authors)
        return fetchRequest
    }

    @nonobjc public class func likes(noteID: String) -> NSFetchRequest<Event> {
        let fetchRequest = NSFetchRequest<Event>(entityName: "Event")
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \Event.createdAt, ascending: false)]
        let noteIsLikedByUserPredicate = NSPredicate(
            // swiftlint:disable line_length
            format: "kind = \(String(EventKind.like.rawValue)) AND SUBQUERY(eventReferences, $reference, $reference.eventId = %@).@count > 0 AND deletedOn.@count = 0",
            // swiftlint:enable line_length
            noteID
        )
        fetchRequest.predicate = noteIsLikedByUserPredicate
        return fetchRequest
    }
    
    @nonobjc public class func reposts(noteID: String) -> NSFetchRequest<Event> {
        let fetchRequest = NSFetchRequest<Event>(entityName: "Event")
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \Event.createdAt, ascending: false)]
        let noteIsLikedByUserPredicate = NSPredicate(
            // swiftlint:disable line_length
            format: "kind = \(String(EventKind.repost.rawValue)) AND SUBQUERY(eventReferences, $reference, $reference.eventId = %@).@count > 0 AND deletedOn.@count = 0",
            // swiftlint:enable line_length
            noteID
        )
        fetchRequest.predicate = noteIsLikedByUserPredicate
        return fetchRequest
    }
    
    @nonobjc public class func emptyRequest() -> NSFetchRequest<Event> {
        let fetchRequest = NSFetchRequest<Event>(entityName: "Event")
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \Event.createdAt, ascending: true)]
        fetchRequest.predicate = NSPredicate.false
        return fetchRequest
    }
    
    @nonobjc public class func deleteAllEvents() -> NSBatchDeleteRequest {
        let fetchRequest: NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: "Event")
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
        return deleteRequest
    }
    
    @nonobjc public class func deleteAllPosts(by author: Author) -> NSBatchDeleteRequest {
        let fetchRequest: NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: "Event")
        let kind = EventKind.text.rawValue
        let key = author.hexadecimalPublicKey ?? "notakey"
        fetchRequest.predicate = NSPredicate(format: "kind = %i AND author.hexadecimalPublicKey = %@", kind, key)
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
        return deleteRequest
    }
    
    func reportsRequest() -> NSFetchRequest<Event> {
        let request = NSFetchRequest<Event>(entityName: "Event")
        request.predicate = NSPredicate(
            format: "kind = %i AND ANY eventReferences.referencedEvent = %@ AND deletedOn.@count = 0",
            EventKind.report.rawValue,
            self
        )
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Event.identifier, ascending: true)]
        return request
    }
}

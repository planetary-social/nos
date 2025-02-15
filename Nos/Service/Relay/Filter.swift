import Foundation

/// Describes a set of Nostr Events, usually so we can ask relay servers for them. 
/// See [NIP-01](https://github.com/nostr-protocol/nips/blob/master/01.md#communication-between-clients-and-relays).
struct Filter: Hashable, Identifiable {
    
    /// List of author identifiers the Filter should be constrained to.
    var authorKeys: [RawAuthorID]

    /// List of event identifiers the Filter should be constrained to.
    let eventIDs: [RawEventID]

    /// List of Note kinds to filter.
    let kinds: [EventKind]

    /// An array of replaceable identifiers, or `"d"` tags, to match.
    let dTags: [RawReplaceableID]

    /// Ask the relay to return events mentioned in the `tags` field.
    let eTags: [RawEventID]

    /// Ask the relay to return authors mentioned in the `tags` field.
    let pTags: [RawAuthorID]

    /// Query string to use in the search parameter.
    let search: String?

    /// Maximum number of items the relay can return.
    var limit: Int?

    /// Ask the relay to return notes posted after a given date.
    var since: Date?

    /// Ask relays to return notes posted before a given date.
    var until: Date?

    /// Whether the subscription should remain open listening for content
    /// updates or should close after receiving a response from the relay.
    var keepSubscriptionOpen: Bool

    /// Initializes a Filter object
    ///
    /// - Parameter authorKeys: List of author identifiers the Filter should be
    /// constrained to. Defaults to `[]`.
    /// - Parameter eventIDs: List of event identifiers the Filter should be
    /// constrained to. Defaults to `[]`.
    /// - Parameter kinds: List of Note kinds to filter. Defaults to `[]`.
    /// - Parameter dTags: An array of replaceable identifiers, or `"d"` tags, to match. Defaults to `[]`.
    /// - Parameter eTags: Ask the relay to return events mentioned in the
    /// `tags` field. Defaults to `[]`.
    /// - Parameter pTags: Ask the relay to return authors mentioned in the
    /// `tags` field. Defaults to `[]`.
    /// - Parameter search: List of author identifiers the Filter should be
    /// constrained to. Defaults to `nil`.
    /// - Parameter limit: Maximum number of items the relay can return.
    /// Defaults to `nil` (no limit).
    /// - Parameter since: Ask the relay to return notes posted after a
    /// given date. Defaults to `nil`.
    /// - Parameter until: Ask relays to return notes posted before a given
    /// date. Defaults to `nil`.
    /// - Parameter keepSubscriptionOpen: Whether the subscription should remain
    /// open listening for content updates or should close after receiving a
    /// response from the relay. Defaults to `false`.
    init(
        authorKeys: [RawAuthorID] = [],
        eventIDs: [RawEventID] = [],
        kinds: [EventKind] = [],
        dTags: [RawReplaceableID] = [],
        eTags: [RawEventID] = [],
        pTags: [RawAuthorID] = [],
        search: String? = nil,
        limit: Int? = nil,
        since: Date? = nil,
        until: Date? = nil,
        keepSubscriptionOpen: Bool = false
    ) {
        self.authorKeys = authorKeys.sorted()
        self.eventIDs = eventIDs
        self.kinds = kinds.sorted(by: { $0.rawValue > $1.rawValue })
        self.dTags = dTags
        self.eTags = eTags
        self.pTags = pTags
        self.search = search
        self.limit = limit
        self.since = since
        self.until = until
        self.keepSubscriptionOpen = keepSubscriptionOpen
    }
    
    var dictionary: [String: Any] {
        var filterDict = [String: Any]()
        
        if let limit {
            filterDict["limit"] = limit
        }

        if !authorKeys.isEmpty {
            filterDict["authors"] = authorKeys
        }
        
        if !eventIDs.isEmpty {
            filterDict["ids"] = eventIDs
        }
        
        if !dTags.isEmpty {
            filterDict["#d"] = dTags
        }

        if !eTags.isEmpty {
            filterDict["#e"] = eTags
        }
        
        if !pTags.isEmpty {
            filterDict["#p"] = pTags
        }
        
        if let search {
            filterDict["search"] = search
        }
        
        if let since {
            filterDict["since"] = Int(since.timeIntervalSince1970)
        }
        
        if let until {
            filterDict["until"] = Int(until.timeIntervalSince1970)
        }

        return filterDict
    }

    static func == (lhs: Filter, rhs: Filter) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(authorKeys)
        hasher.combine(eventIDs)
        hasher.combine(kinds)
        hasher.combine(limit)
        hasher.combine(dTags)
        hasher.combine(eTags)
        hasher.combine(pTags)
        hasher.combine(search)
        hasher.combine(since)
        hasher.combine(until)
        hasher.combine(keepSubscriptionOpen)
    }
    
    var id: String {
        hashValue.description
    }
}

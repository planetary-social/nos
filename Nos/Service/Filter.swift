//
//  Filter.swift
//  Nos
//
//  Created by Christopher Jorgensen on 2/17/23.
//

import Foundation

/// Describes a set of Nostr Events, usually so we can ask relay servers for them.
struct Filter: Hashable, Identifiable {
    
    let authorKeys: [String]
    let kinds: [EventKind]
    let eTags: [String]
    let limit: Int
    let since: Date?
    
    var id: String {
        String(hashValue)
    }

    init(
        authorKeys: [String] = [],
        kinds: [EventKind] = [],
        eTags: [String] = [],
        limit: Int = 100,
        since: Date? = nil
    ) {
        self.authorKeys = authorKeys.sorted(by: { $0 > $1 })
        self.kinds = kinds.sorted(by: { $0.rawValue > $1.rawValue })
        self.eTags = eTags
        self.limit = limit
        self.since = since
    }
    
    var dictionary: [String: Any] {
        var filterDict: [String: Any] = ["limit": limit]

        if !authorKeys.isEmpty {
            filterDict["authors"] = authorKeys
        }

        if !kinds.isEmpty {
            filterDict["kinds"] = kinds.map({ $0.rawValue })
        }
        
        if !eTags.isEmpty {
            filterDict["#e"] = eTags
        }
        
        if let since {
            filterDict["since"] = Int(since.timeIntervalSince1970)
        }

        return filterDict
    }

    static func == (lhs: Filter, rhs: Filter) -> Bool {
        lhs.hashValue == rhs.hashValue
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(authorKeys)
        hasher.combine(kinds)
        hasher.combine(limit)
        hasher.combine(eTags)
        hasher.combine(since)
    }
    
    func isFulfilled(by event: Event) -> Bool {
        guard limit == 1 else {
            return false
        }
        
        if kinds.count == 1,
            event.kind == kinds.first?.rawValue,
            !authorKeys.isEmpty,
            let authorKey = event.author?.hexadecimalPublicKey {
            return authorKeys.contains(authorKey)
        }
        
        return false
    }
}

//
//  Filter.swift
//  Nos
//
//  Created by Christopher Jorgensen on 2/17/23.
//

import Foundation

/// Describes a set of Nostr Events, usually so we can ask relay servers for them.
struct Filter: Hashable, Identifiable {
    
    let authorKeys: [HexadecimalString]
    let eventIDs: [HexadecimalString]
    let kinds: [EventKind]
    let eTags: [HexadecimalString]
    let pTags: [HexadecimalString]
    let search: String?
    let inNetwork: Bool
    let limit: Int?
    var since: Date?
    var until: Date?
    
    init(
        authorKeys: [HexadecimalString] = [],
        eventIDs: [HexadecimalString] = [],
        kinds: [EventKind] = [],
        eTags: [HexadecimalString] = [],
        pTags: [HexadecimalString] = [],
        search: String? = nil,
        inNetwork: Bool = false,
        limit: Int? = nil,
        since: Date? = nil,
        until: Date? = nil
    ) {
        self.authorKeys = authorKeys.sorted(by: { $0 > $1 })
        self.eventIDs = eventIDs
        self.kinds = kinds.sorted(by: { $0.rawValue > $1.rawValue })
        self.eTags = eTags
        self.pTags = pTags
        self.search = search
        self.inNetwork = inNetwork
        self.limit = limit
        self.since = since
        self.until = until
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

        if !kinds.isEmpty {
            filterDict["kinds"] = kinds.map({ $0.rawValue })
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
        hasher.combine(eTags)
        hasher.combine(pTags)
        hasher.combine(search)
        hasher.combine(since)
        hasher.combine(until)
        hasher.combine(inNetwork)
    }
    
    var id: String {
        let intermediate: [String] = [
            authorKeys.joined(separator: ","),
            eventIDs.joined(separator: ","),
            kinds.map { String($0.rawValue) }.joined(separator: ","),
            limit?.description ?? "nil",
            eTags.joined(separator: ","),
            pTags.joined(separator: ","),
            search ?? "nil",
            since?.timeIntervalSince1970.description ?? "nil",
            until?.timeIntervalSince1970.description ?? "nil",
            inNetwork.description,
        ]
        
        return intermediate
            .joined(separator: "|")
            .data(using: .utf8)!
            .sha256
    }
}

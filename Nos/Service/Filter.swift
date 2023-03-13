//
//  Filter.swift
//  Nos
//
//  Created by Christopher Jorgensen on 2/17/23.
//

import Foundation

/// For REQ
final class Filter: Hashable {
    private var authorKeys: [String] {
        didSet {
            print("Override author keys to: \(authorKeys)")
        }
    }
    private var kinds: [EventKind]
    let limit: Int

    // For closing requests; not part of hash
    var subscriptionId: String = ""
    var subscriptionStartDate: Date?
    
    private var eTags: [String]

    init(
        authorKeys: [String] = [],
        kinds: [EventKind] = [],
        eTags: [String] = [],
        limit: Int = 100
    ) {
        self.authorKeys = authorKeys.sorted(by: { $0 > $1 })
        self.kinds = kinds.sorted(by: { $0.rawValue > $1.rawValue })
        self.eTags = eTags
        self.limit = limit
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

        return filterDict
    }

    static func == (lhs: Filter, rhs: Filter) -> Bool {
        lhs.authorKeys == rhs.authorKeys && lhs.kinds == rhs.kinds && lhs.limit == rhs.limit
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(authorKeys)
        hasher.combine(kinds)
        hasher.combine(limit)
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

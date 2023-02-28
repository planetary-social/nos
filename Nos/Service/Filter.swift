//
//  Filter.swift
//  Nos
//
//  Created by Christopher Jorgensen on 2/17/23.
//

import Foundation

/// For REQ
final class Filter {
    private var authorKeys: [String]
    private var kinds: [EventKind]
    private var limit: Int

    init(authorKeys: [String] = [], kinds: [EventKind] = [], pTags: [String] = [], limit: Int = 100) {
        self.authorKeys = authorKeys
        self.kinds = kinds
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
        
        return filterDict
    }
}

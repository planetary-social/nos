//
//  Filter.swift
//  Nos
//
//  Created by Christopher Jorgensen on 2/17/23.
//

import Foundation

final class Filter {
    private var authorPublicKeys: [String]
    var kinds: [EventKind]
    var limit: Int

    init(publicKeys: [String] = [], kinds: [EventKind] = [], limit: Int = 100) {
        self.authorPublicKeys = publicKeys
        self.kinds = kinds
        self.limit = limit
    }
    
    var dictionary: [String: Any] {
        var filterDict: [String: Any] = ["limit": limit]

        if !authorPublicKeys.isEmpty {
            filterDict["authors"] = authorPublicKeys
        }

        if !kinds.isEmpty {
            filterDict["kinds"] = kinds.map({ $0.rawValue })
        }
        
        return filterDict
    }
}

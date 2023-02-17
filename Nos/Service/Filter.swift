//
//  Filter.swift
//  Nos
//
//  Created by Christopher Jorgensen on 2/17/23.
//

import Foundation

final class Filter {
    var authors: [Author]
    var kinds: [EventKind]
    var limit: Int
    
    init(authors: [Author] = [], kinds: [EventKind] = [], limit: Int = 100) {
        self.authors = authors
        self.kinds = kinds
        self.limit = limit
    }
    
    var dictionary: [String: Any] {
        var filterDict: [String: Any] = ["limit": limit]

        if !authors.isEmpty {
            filterDict["authors"] = authors.map({ $0.hexadecimalPublicKey })
        }

        if !kinds.isEmpty {
            filterDict["kinds"] = kinds.map({ $0.rawValue })
        }
        
        return filterDict
    }
}

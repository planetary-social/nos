//
//  Collection+SafeSubscript.swift
//  Nos
//
//  Created by Shane Bielefeld on 2/22/23.
//

import Foundation

extension Collection where Indices.Iterator.Element == Index {
    // https://wendyliga.medium.com/say-goodbye-to-index-out-of-range-swift-eca7c4c7b6ca
    /// returns nil if index is out of range
    public subscript(safe index: Index) -> Iterator.Element? {
        (startIndex <= index && index < endIndex) ? self[index] : nil
    }
}

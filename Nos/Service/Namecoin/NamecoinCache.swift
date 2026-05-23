//
//  NamecoinCache.swift
//  Nos
//
//  Small in-memory cache for Namecoin resolution results.
//  Matches the semantics used by Amethyst (1h TTL, 500 entries).
//
//  Ported from nostur-com/nostur-ios-public PR #60.
//

import Foundation

public actor NamecoinCache {
    public struct Entry: Sendable {
        public let result: NamecoinNostrResult?
        public let timestamp: Date
    }

    public static let shared = NamecoinCache()

    private let maxEntries: Int
    private let ttl: TimeInterval
    private var storage: [String: Entry] = [:]
    private var order: [String] = [] // LRU order, front = oldest

    public init(maxEntries: Int = 500, ttl: TimeInterval = 86_400) {
        self.maxEntries = maxEntries
        self.ttl = ttl
    }

    private func key(_ identifier: String) -> String {
        identifier.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }

    public func get(_ identifier: String) -> Entry? {
        let k = key(identifier)
        guard let entry = storage[k] else { return nil }
        if Date().timeIntervalSince(entry.timestamp) > ttl {
            storage.removeValue(forKey: k)
            order.removeAll { $0 == k }
            return nil
        }
        return entry
    }

    public func put(_ identifier: String, result: NamecoinNostrResult?) {
        let k = key(identifier)
        storage[k] = Entry(result: result, timestamp: Date())
        order.removeAll { $0 == k }
        order.append(k)
        while order.count > maxEntries {
            let evict = order.removeFirst()
            storage.removeValue(forKey: evict)
        }
    }

    public func invalidate(_ identifier: String) {
        let k = key(identifier)
        storage.removeValue(forKey: k)
        order.removeAll { $0 == k }
    }

    public func clear() {
        storage.removeAll()
        order.removeAll()
    }
}

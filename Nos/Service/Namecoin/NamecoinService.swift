//
//  NamecoinService.swift
//  Nos
//
//  Shared singleton: resolver + cache. Provides a simple async API for
//  callers that don't care about detailed error outcomes.
//
//  Ported from nostur-com/nostur-ios-public PR #60.
//

import Foundation

public actor NamecoinService {
    public static let shared = NamecoinService()

    private let resolver: NamecoinResolver
    private let cache: NamecoinCache

    public init(
        client: IElectrumXClient = ElectrumXClient(),
        cache: NamecoinCache = NamecoinCache.shared,
        serverListProvider: @escaping () -> [ElectrumXServer] = { DEFAULT_ELECTRUMX_SERVERS }
    ) {
        self.resolver = NamecoinResolver(client: client, serverListProvider: serverListProvider)
        self.cache = cache
    }

    /// Resolve a .bit identifier, using the cache when available.
    /// Returns nil if the name doesn't exist or can't be resolved.
    public func resolve(_ identifier: String) async -> NamecoinNostrResult? {
        if let cached = await cache.get(identifier) {
            return cached.result
        }
        let result = await resolver.resolve(identifier)
        await cache.put(identifier, result: result)
        return result
    }

    /// Detailed variant with cache passthrough on success/failure.
    public func resolveDetailed(_ identifier: String) async -> NamecoinResolveOutcome {
        if let cached = await cache.get(identifier) {
            if let result = cached.result {
                return .success(result)
            }
            return .nameNotFound(name: identifier)
        }
        let outcome = await resolver.resolveDetailed(identifier)
        switch outcome {
        case .success(let r):
            await cache.put(identifier, result: r)
        case .nameNotFound, .noNostrField:
            await cache.put(identifier, result: nil)
        default:
            break
        }
        return outcome
    }
}

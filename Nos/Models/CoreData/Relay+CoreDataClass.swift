import Foundation
import CoreData

enum RelayError: Error {
    case invalidAddress
    case parseError
    case missingSignatureOrKey
}

@objc(Relay)
final class Relay: NosManagedObject {

    static var recommended: [String] {
        [
        nosAddress.absoluteString,
        "wss://news.nos.social",
        "wss://relay.mostr.pub",
        ]
    }
    
    static var allKnown: [String] {
        [
        "wss://eden.nostr.land",
        "wss://nostr.fmt.wiz.biz",
        "wss://relay.damus.io",
        "wss://nostr-pub.wellorder.net",
        "wss://relay.nostr.info",
        "wss://offchain.pub",
        "wss://nos.lol",
        "wss://brb.io",
        "wss://relay.snort.social",
        "wss://relay.current.fyi",
        "wss://nostr.relayer.se",
        "wss://e.nos.lol",
        "wss://purplepag.es",
        "wss://soloco.nl",
        "wss://relayable.org",
        nosAddress.absoluteString,
        "wss://relay.causes.com",
        ]
    }

    /// Relays that should be used for NIP-50 search and will be excluded from other requests.
    /// In the future we should use the kind 10007 search relays list instead of this hardcoded list.
    static var searchOnly: [URL] = { 
        ["wss://relay.nostr.band"].compactMap { URL(string: $0) } 
    }()
    
    // swiftlint:disable:next force_unwrapping
    static var nosAddress = URL(string: "wss://relay.nos.social")!

    @nonobjc static func relay(by address: String) -> NSFetchRequest<Relay> {
        let fetchRequest = NSFetchRequest<Relay>(entityName: "Relay")
        fetchRequest.predicate = NSPredicate(format: "address = %@", address)
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \Relay.createdAt, ascending: true)]
        fetchRequest.fetchLimit = 1
        return fetchRequest
    }
    
    @nonobjc static func relays(for user: Author) -> NSFetchRequest<Relay> {
        let fetchRequest = NSFetchRequest<Relay>(entityName: "Relay")
        fetchRequest.predicate = NSPredicate(format: "ANY authors = %@", user)
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \Relay.address, ascending: true)]
        return fetchRequest
    }
    
    /// Retreives all the Relays that are no longer referenced by anyone in the db.
    static func orphanedRequest() -> NSFetchRequest<Relay> {
        let fetchRequest = NSFetchRequest<Relay>(entityName: "Relay")
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \Relay.address, ascending: false)]
        fetchRequest.predicate = NSPredicate(
            format: "SUBQUERY(authors, $a, TRUEPREDICATE).@count = 0 AND " +
                "SUBQUERY(deletedEvents, $d, TRUEPREDICATE).@count = 0 AND " +
                "SUBQUERY(events, $e, TRUEPREDICATE).@count = 0 AND " +
                "SUBQUERY(publishedEvents, $e, TRUEPREDICATE).@count = 0 AND " +
                "SUBQUERY(shouldBePublishedEvents, $r, TRUEPREDICATE).@count = 0"
        )
            
        return fetchRequest
    }
    
    @discardableResult
    static func findOrCreate(by address: String, context: NSManagedObjectContext) throws -> Relay {
        if let existingRelay = try context.fetch(Relay.relay(by: address)).first {
            return existingRelay
        } else {
            let relay = try Relay(context: context, address: address)
            return relay
        }
    }

    static func find(
        supporting nipNumber: Int,
        for author: Author,
        context: NSManagedObjectContext
    ) async throws -> [Relay] {
        try await context.perform {
            let relays = try context.fetch(Relay.relays(for: author))
            return relays.filter { $0.supportedNIPs?.contains(nipNumber) ?? false }
        }
    }

    /// Populates metadata using the data in the given JSON.
    func hydrate(from jsonMetadata: JSONRelayMetadata) throws {
        name = jsonMetadata.name
        relayDescription = jsonMetadata.description
        supportedNIPs = jsonMetadata.supportedNIPs
        pubkey = jsonMetadata.pubkey
        contact = jsonMetadata.contact
        software = jsonMetadata.software
        version = jsonMetadata.version
        metadataFetchedAt = Date.now
    }

    private convenience init(context: NSManagedObjectContext, address: String, author: Author? = nil) throws {
        guard let addressURL = URL(string: address),
            addressURL.scheme == "wss" else {
            throw RelayError.invalidAddress
        }
        
        self.init(context: context)
        self.address = addressURL.strippingTrailingSlash()
        self.createdAt = Date.now
        if let author {
            authors.insert(author)
            author.add(relay: self)
        }
    }
    
    var addressURL: URL? {
        if let address {
            return URL(string: address)
        }
        return nil
    }
    
    var host: String? {
        addressURL?.host
    }

    var hasMetadata: Bool {
        metadataFetchedAt != nil
    }
}

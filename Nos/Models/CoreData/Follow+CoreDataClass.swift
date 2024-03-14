import Foundation
import CoreData

typealias Followed = [Follow]

extension Set where Element == Follow {
    var keys: [String] {
        compactMap { $0.destination?.hexadecimalPublicKey }
    }
}

extension Array where Element == String {
    var eTags: [[String]] {
        map { ["e", $0] }
    }

    var pTags: [[String]] {
        map { ["p", $0] }
    }
}

@objc(Follow)
public class Follow: NosManagedObject {
    
    // swiftlint:disable:next function_body_length
    class func upsert(
        by author: Author,
        jsonTag: [String],
        context: NSManagedObjectContext
    ) throws -> Follow {
        guard let followedKey = jsonTag[safe: 1] else {
            throw DecodingError.valueNotFound(
                Follow.self,
                DecodingError.Context(
                    codingPath: [],
                    debugDescription: "Encoded tags did not have a key at position 1"
                )
            )
        }
        guard followedKey.isValid else {
            throw DecodingError.valueNotFound(
                Follow.self,
                DecodingError.Context(
                    codingPath: [],
                    debugDescription: "Tag \(followedKey) is not a valid hexadecimal public key"
                )
            )
        }
        guard let authorHexPublicKey = author.hexadecimalPublicKey else {
            throw DecodingError.valueNotFound(
                Author.self,
                DecodingError.Context(
                    codingPath: [],
                    debugDescription: "Author did not have a hexadecimal public key"
                )
            )
        }
        var follow: Follow
        let fetchRequest = NSFetchRequest<Follow>(entityName: "Follow")
        fetchRequest.predicate = NSPredicate(
            format: "source.hexadecimalPublicKey = %@ AND destination.hexadecimalPublicKey = %@",
            authorHexPublicKey,
            followedKey
        )
        fetchRequest.fetchLimit = 1
        if let existingFollow = try context.fetch(fetchRequest).first {
            return existingFollow
        } else {
            follow = Follow(context: context)
        }
        
        follow.source = author

        let followedAuthor = try Author.findOrCreate(by: followedKey, context: context)
        follow.destination = followedAuthor
        
        if jsonTag.count > 2, !jsonTag[2].isEmpty {
            if let relay = try? Relay.findOrCreate(by: jsonTag[2], context: context) {
                author.add(relay: relay)
            }
        }
        
        if jsonTag.count > 3 {
            follow.petName = jsonTag[3]
        }
        
        return follow
    }
    
    @nonobjc public class func followsRequest(sources authors: [Author]) -> NSFetchRequest<Follow> {
        let fetchRequest = NSFetchRequest<Follow>(entityName: "Follow")
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \Follow.petName, ascending: true)]
        fetchRequest.predicate = NSPredicate(format: "source IN %@", authors)
        return fetchRequest
    }
    
    @nonobjc public class func followsRequest(source: Author, destination: Author) -> NSFetchRequest<Follow> {
        let fetchRequest = NSFetchRequest<Follow>(entityName: "Follow")
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \Follow.petName, ascending: true)]
        fetchRequest.predicate = NSPredicate(format: "source = %@ AND destination = %@", source, destination)
        return fetchRequest
    }

    @nonobjc public class func followsRequest(destination authors: [Author]) -> NSFetchRequest<Follow> {
        let fetchRequest = NSFetchRequest<Follow>(entityName: "Follow")
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \Follow.petName, ascending: true)]
        fetchRequest.predicate = NSPredicate(format: "destination IN %@", authors)
        return fetchRequest
    }
    
    @nonobjc public class func emptyRequest() -> NSFetchRequest<Follow> {
        let fetchRequest = NSFetchRequest<Follow>(entityName: "Follow")
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \Follow.petName, ascending: true)]
        fetchRequest.fetchLimit = 0
        return fetchRequest
    }
    
    /// Retreives all the Follows whose source Author has been deleted.
    static func orphanedRequest() -> NSFetchRequest<Follow> {
        let fetchRequest = NSFetchRequest<Follow>(entityName: "Follow")
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \Follow.destination, ascending: false)]
        fetchRequest.predicate = NSPredicate(format: "source = nil")
        return fetchRequest
    }
    
    class func follows(source: Author, destination: Author, context: NSManagedObjectContext) -> [Follow] {
        let fetchRequest = Follow.followsRequest(source: source, destination: destination)
        
        do {
            return try context.fetch(fetchRequest)
        } catch let error as NSError {
            print("Failed to fetch follows. Error: \(error.description)")
        }
        
        return []
    }
    
    class func deleteFollows(in follows: Set<Follow>, context: NSManagedObjectContext) {
        for follow in follows {
            context.delete(follow)
        }
    }
    
    class func find(source: Author, destination: Author, context: NSManagedObjectContext) throws -> Follow? {
        let fetchRequest = Follow.followsRequest(source: source, destination: destination)
        fetchRequest.fetchLimit = 1
        if let follow = try context.fetch(fetchRequest).first {
            return follow
        }
        
        return nil
    }
    
    class func findOrCreate(source: Author, destination: Author, context: NSManagedObjectContext) throws -> Follow {
        if let follow = try? Follow.find(source: source, destination: destination, context: context) {
            return follow
        } else {
            let follow = Follow(context: context)
            follow.source = source
            follow.destination = destination
            return follow
        }
    }
}

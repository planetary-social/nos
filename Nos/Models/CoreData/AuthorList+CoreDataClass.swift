import Foundation
import CoreData
import NostrSDK

/// This class is needed only as a utility. The protocol functions only work on instances,
/// (as opposed to classes in static functions).
fileprivate final class TagInterpreter: PrivateTagInterpreting, DirectMessageEncrypting {
}

extension Keypair {
    static func withNosKeyPair(_ keyPair: KeyPair) -> Keypair? {
        Keypair(nsec: keyPair.nsec)
    }
}

@objc(AuthorList)
final class AuthorList: Event {
    static func createOrUpdate(
        from jsonEvent: JSONEvent,
        keyPair: KeyPair? = nil,
        in context: NSManagedObjectContext
    ) throws -> AuthorList {
        guard jsonEvent.kind == EventKind.followSet.rawValue else { throw AuthorListError.invalidKind }
        guard let replaceableID = jsonEvent.replaceableID else { throw AuthorListError.missingReplaceableID }
        let owner = try Author.findOrCreate(by: jsonEvent.pubKey, context: context)

        // Fetch existing AuthorList if it exists
        let fetchRequest = AuthorList.authorList(by: replaceableID, owner: owner, kind: EventKind.followSet.rawValue)
        let existingAuthorList = try context.fetch(fetchRequest).first
        existingAuthorList?.authors = Set()

        let authorList = existingAuthorList ?? AuthorList(context: context)
        authorList.createdAt = jsonEvent.createdDate
        authorList.author = owner
        authorList.owner = owner
        authorList.identifier = jsonEvent.id
        authorList.replaceableIdentifier = replaceableID
        authorList.kind = jsonEvent.kind
        authorList.signature = jsonEvent.signature
        authorList.allTags = jsonEvent.tags as NSObject
        authorList.content = jsonEvent.content

        let tags = jsonEvent.tags

        for tag in tags {
            if tag[safe: 0] == "p", let authorID = tag[safe: 1] {
                let author = try Author.findOrCreate(by: authorID, context: context)
                authorList.addToAuthors(author)
            } else if tag[safe: 0] == "title" {
                authorList.title = tag[safe: 1]
            } else if tag[safe: 0] == "image" {
                if let urlString = tag[safe: 1] {
                    authorList.image = URL(string: urlString)
                } else {
                    authorList.image = nil
                }
            } else if tag[safe: 0] == "description" {
                authorList.listDescription = tag[safe: 1]
            }
        }
        
        if !jsonEvent.content.isEmpty,
            let keyPair,
            let nostrSDKKeypair = Keypair.withNosKeyPair(keyPair) {
            let authorIDs = TagInterpreter().valuesForPrivateTags(
                from: jsonEvent.content,
                withName: .pubkey,
                using: nostrSDKKeypair
            )
            for authorID in authorIDs {
                let author = try Author.findOrCreate(by: authorID, context: context)
                authorList.addToPrivateAuthors(author)
            }
        }
        
        return authorList
    }

    @nonobjc static func authorList(
        by replaceableID: RawReplaceableID,
        owner: Author,
        kind: Int64
    ) -> NSFetchRequest<AuthorList> {
        let fetchRequest = NSFetchRequest<AuthorList>(entityName: "AuthorList")
        fetchRequest.predicate = NSPredicate(
            format: "replaceableIdentifier = %@ AND owner = %@ AND kind = %i",
            replaceableID,
            owner,
            kind
        )
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \Event.createdAt, ascending: false)]
        fetchRequest.fetchLimit = 1
        return fetchRequest
    }
    
    var allAuthors: Set<Author> {
        authors.union(privateAuthors)
    }
    
    static func authorLists(ownedBy owner: Author) -> NSFetchRequest<AuthorList> {
        let request = NSFetchRequest<AuthorList>(entityName: "AuthorList")
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Event.createdAt, ascending: false)]
        request.predicate = NSPredicate(
            format: "kind = %i AND author = %@ AND title != nil AND title != '' AND deletedOn.@count = 0",
            EventKind.followSet.rawValue,
            owner
        )
        return request
    }
}

import Foundation
import CoreData

@objc(AuthorList)
public class AuthorList: NSManagedObject {
    static func createOrUpdate(
        from jsonEvent: JSONEvent,
        in context: NSManagedObjectContext
    ) throws -> AuthorList {
        guard jsonEvent.kind == EventKind.followSet.rawValue else { throw AuthorListError.invalidKind }
        guard let replaceableID = jsonEvent.replaceableID else { throw AuthorListError.missingReplaceableID }
        let owner = try Author.findOrCreate(by: jsonEvent.pubKey, context: context)

        // Fetch existing AuthorList if it exists
        let fetchRequest = AuthorList.authorList(by: replaceableID, owner: owner, kind: EventKind.followSet.rawValue)
        let existingAuthorList = try context.fetch(fetchRequest).first
        existingAuthorList?.authors.removeAll()

        let authorList = existingAuthorList ?? AuthorList(context: context)
        authorList.createdAt = jsonEvent.createdDate
        authorList.owner = owner
        authorList.identifier = jsonEvent.id
        authorList.replaceableIdentifier = replaceableID
        authorList.kind = EventKind.followSet.rawValue
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

        return authorList
    }

    @nonobjc public class func authorList(
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
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \AuthorList.identifier, ascending: true)]
        fetchRequest.fetchLimit = 1
        return fetchRequest
    }
}

extension AuthorList: VerifiableEvent {
    var pubKey: String { owner.hexadecimalPublicKey ?? "" }

    var serializedListForSigning: [Any?] {
        [
            0,
            owner.hexadecimalPublicKey,
            Int64(createdAt.timeIntervalSince1970),
            kind,
            allTags,
            content
        ]
    }

    func calculateIdentifier() throws -> String {
        let serializedEventData = try JSONSerialization.data(
            withJSONObject: serializedListForSigning,
            options: [.withoutEscapingSlashes]
        )
        return serializedEventData.sha256
    }
}

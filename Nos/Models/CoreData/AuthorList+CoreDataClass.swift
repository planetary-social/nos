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
        authorList.identifier = replaceableID
        authorList.kind = EventKind.followSet.rawValue

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
            format: "identifier = %@ AND owner = %@ AND kind = %i",
            replaceableID,
            owner,
            kind
        )
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \AuthorList.identifier, ascending: true)]
        fetchRequest.fetchLimit = 1
        return fetchRequest
    }
}

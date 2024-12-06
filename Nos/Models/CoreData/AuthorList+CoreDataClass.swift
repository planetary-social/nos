import Foundation
import CoreData

@objc(AuthorList)
public class AuthorList: NSManagedObject {
    static func create(
        from jsonEvent: JSONEvent,
        in context: NSManagedObjectContext
    ) throws -> AuthorList? {
        guard let replaceableID = jsonEvent.replaceableID else { return nil }
        let owner = try Author.findOrCreate(by: jsonEvent.pubKey, context: context)

        let authorList = AuthorList(context: context)
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

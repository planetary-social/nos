import Foundation
import CoreData

extension AuthorList {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<AuthorList> {
        NSFetchRequest<AuthorList>(entityName: "AuthorList")
    }

    @NSManaged public var allTags: NSObject?
    @NSManaged public var content: String?
    @NSManaged public var createdAt: Date
    @NSManaged public var identifier: RawEventID?
    @NSManaged public var image: URL?
    @NSManaged public var isVerified: Bool
    @NSManaged public var kind: Int64
    @NSManaged public var listDescription: String?
    @NSManaged public var replaceableIdentifier: String
    @NSManaged public var signature: String?
    @NSManaged public var title: String?

    @NSManaged public var authors: Set<Author>
    @NSManaged public var owner: Author
}

// MARK: Generated accessors for authors
extension AuthorList {

    @objc(addAuthorsObject:)
    @NSManaged public func addToAuthors(_ value: Author)

    @objc(removeAuthorsObject:)
    @NSManaged public func removeFromAuthors(_ value: Author)

    @objc(addAuthors:)
    @NSManaged public func addToAuthors(_ values: NSSet)

    @objc(removeAuthors:)
    @NSManaged public func removeFromAuthors(_ values: NSSet)
}

extension AuthorList: Identifiable {}

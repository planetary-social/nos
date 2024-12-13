import Foundation
import CoreData

extension AuthorList {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<AuthorList> {
        NSFetchRequest<AuthorList>(entityName: "AuthorList")
    }

    @NSManaged public var image: URL?
    @NSManaged public var listDescription: String?
    @NSManaged public var title: String?
    @NSManaged public var authors: Set<Author>
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

import Foundation
import CoreData

extension AuthorList {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<AuthorList> {
        NSFetchRequest<AuthorList>(entityName: "AuthorList")
    }

    /// The URL of an image representing the list.
    @NSManaged public var image: URL?

    /// The description of the list.
    @NSManaged public var listDescription: String?

    /// The title of the list.
    @NSManaged public var title: String?

    /// The owner of the list; the ``Author`` who created it.
    /// Duplicates ``author`` but Core Data won't allow for multiple relationships to have the same inverse.
    @NSManaged public var owner: Author?

    /// The set of unique authors in this list.
    @NSManaged public var authors: Set<Author>
    
    /// The set of privately listed unique authors.
    @NSManaged public var privateAuthors: Set<Author>
    
    /// Whether or not this list should be visible in the ``FeedPicker``.
    @NSManaged public var isFeedEnabled: Bool
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
    
    @objc(addPrivateAuthorsObject:)
    @NSManaged public func addToPrivateAuthors(_ value: Author)

    @objc(removePrivateAuthorsObject:)
    @NSManaged public func removeFromPrivateAuthors(_ value: Author)

    @objc(addPrivateAuthors:)
    @NSManaged public func addToPrivateAuthors(_ values: NSSet)

    @objc(removePrivateAuthors:)
    @NSManaged public func removeFromPrivateAuthors(_ values: NSSet)
}

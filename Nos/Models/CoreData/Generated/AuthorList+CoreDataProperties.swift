import Foundation
import CoreData

extension AuthorList {

    @nonobjc static func fetchRequest() -> NSFetchRequest<AuthorList> {
        NSFetchRequest<AuthorList>(entityName: "AuthorList")
    }

    /// The URL of an image representing the list.
    @NSManaged var image: URL?

    /// The description of the list.
    @NSManaged var listDescription: String?

    /// The title of the list.
    @NSManaged var title: String?

    /// The owner of the list; the ``Author`` who created it.
    /// Duplicates ``author`` but Core Data won't allow for multiple relationships to have the same inverse.
    @NSManaged var owner: Author?

    /// The set of unique authors in this list.
    @NSManaged var authors: Set<Author>
    
    /// The set of privately listed unique authors.
    @NSManaged var privateAuthors: Set<Author>
    
    /// Whether or not this list should be visible in the ``FeedPicker``.
    @NSManaged var isFeedEnabled: Bool
}

// MARK: Generated accessors for authors
extension AuthorList {

    @objc(addAuthorsObject:)
    @NSManaged func addToAuthors(_ value: Author)

    @objc(removeAuthorsObject:)
    @NSManaged func removeFromAuthors(_ value: Author)

    @objc(addAuthors:)
    @NSManaged func addToAuthors(_ values: NSSet)

    @objc(removeAuthors:)
    @NSManaged func removeFromAuthors(_ values: NSSet)
    
    @objc(addPrivateAuthorsObject:)
    @NSManaged func addToPrivateAuthors(_ value: Author)

    @objc(removePrivateAuthorsObject:)
    @NSManaged func removeFromPrivateAuthors(_ value: Author)

    @objc(addPrivateAuthors:)
    @NSManaged func addToPrivateAuthors(_ values: NSSet)

    @objc(removePrivateAuthors:)
    @NSManaged func removeFromPrivateAuthors(_ values: NSSet)
}

import Foundation
import CoreData

extension FollowSet {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<FollowSet> {
        return NSFetchRequest<FollowSet>(entityName: "FollowSet")
    }

    @NSManaged public var title: String?
    @NSManaged public var setDescription: String?
    @NSManaged public var identifier: String?
    @NSManaged public var image: URL?
    @NSManaged public var authors: NSSet?
}

// MARK: Generated accessors for authors
extension FollowSet {

    @objc(addAuthorsObject:)
    @NSManaged public func addToAuthors(_ value: Author)

    @objc(removeAuthorsObject:)
    @NSManaged public func removeFromAuthors(_ value: Author)

    @objc(addAuthors:)
    @NSManaged public func addToAuthors(_ values: NSSet)

    @objc(removeAuthors:)
    @NSManaged public func removeFromAuthors(_ values: NSSet)
}

extension FollowSet: Identifiable {}

import Foundation
import CoreData

extension Author {
    @NSManaged public var about: String?
    @NSManaged public var displayName: String?
    @NSManaged public var hexadecimalPublicKey: RawAuthorID?
    @NSManaged public var lastUpdatedContactList: Date?
    @NSManaged public var lastUpdatedMetadata: Date?
    @NSManaged public var muted: Bool
    @NSManaged public var name: String?
    @NSManaged public var website: String?
    @NSManaged public var nip05: String?
    @NSManaged public var profilePhotoURL: URL?
    @NSManaged public var rawMetadata: Data?
    @NSManaged public var uns: String?
    @NSManaged public var events: Set<Event>
    @NSManaged public var followers: Set<Follow>
    @NSManaged public var follows: Set<Follow>
    @NSManaged public var relays: Set<Relay>
    @NSManaged public var notifications: Set<NosNotification>
}

// MARK: Generated accessors for followers
extension Author {
    @objc(addFollowersObject:)
    @NSManaged public func addToFollowers(_ value: Follow)
}

extension Author: Identifiable {}

import Foundation
import CoreData

extension Author {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Author> {
        NSFetchRequest<Author>(entityName: "Author")
    }

    @NSManaged public var about: String?
    @NSManaged public var displayName: String?
    @NSManaged public var hexadecimalPublicKey: RawAuthorID?
    @NSManaged public var lastUpdatedContactList: Date?
    @NSManaged public var lastUpdatedMuteList: Date?
    @NSManaged public var lastUpdatedMetadata: Date?
    @NSManaged public var muted: Bool
    @NSManaged public var name: String?
    @NSManaged public var website: String?
    @NSManaged public var nip05: String?
    @NSManaged public var pronouns: String?
    @NSManaged public var profilePhotoURL: URL?
    @NSManaged public var rawMetadata: Data?
    @NSManaged public var events: Set<Event>
    @NSManaged public var followers: Set<Follow>
    
    /// All follow notifications ("This user is now following you") where this Author is the follower. 
    @NSManaged public var followNotifications: NSSet
    @NSManaged public var follows: Set<Follow>
    @NSManaged public var relays: Set<Relay>
    
    /// All notifications that should notify this Author if they are the logged in user.
    /// The notifications are intended for the current author to be received.
    @NSManaged public var incomingNotifications: Set<NosNotification>
}

// MARK: Generated accessors for events
extension Author {

    @objc(addEventsObject:)
    @NSManaged public func addToEvents(_ value: Event)

    @objc(removeEventsObject:)
    @NSManaged public func removeFromEvents(_ value: Event)

    @objc(addEvents:)
    @NSManaged public func addToEvents(_ values: NSSet)

    @objc(removeEvents:)
    @NSManaged public func removeFromEvents(_ values: NSSet)
}

// MARK: Generated accessors for followers
extension Author {

    @objc(addFollowersObject:)
    @NSManaged public func addToFollowers(_ value: Follow)

    @objc(removeFollowersObject:)
    @NSManaged public func removeFromFollowers(_ value: Follow)

    @objc(addFollowers:)
    @NSManaged public func addToFollowers(_ values: NSSet)

    @objc(removeFollowers:)
    @NSManaged public func removeFromFollowers(_ values: NSSet)
}

// MARK: Generated accessors for follows
extension Author {

    @objc(addFollowsObject:)
    @NSManaged public func addToFollows(_ value: Follow)

    @objc(removeFollowsObject:)
    @NSManaged public func removeFromFollows(_ value: Follow)

    @objc(addFollows:)
    @NSManaged public func addToFollows(_ values: NSSet)

    @objc(removeFollows:)
    @NSManaged public func removeFromFollows(_ values: NSSet)
}

// MARK: Generated accessors for followNotifications
extension Author {
    
    @objc(addFollowNotificationsObject:)
    @NSManaged public func addToFollowNotifications(_ value: NosNotification)
    
    @objc(removeFollowNotificationsObject:)
    @NSManaged public func removeFromFollowNotifications(_ value: NosNotification)
    
    @objc(addFollowNotifications:)
    @NSManaged public func addToFollowNotifications(_ values: NSSet)
    
    @objc(removeFollowNotifications:)
    @NSManaged public func removeFromFollowNotifications(_ values: NSSet)
}

// MARK: Generated accessors for relays
extension Author {

    @objc(addRelaysObject:)
    @NSManaged public func addToRelays(_ value: Relay)

    @objc(removeRelaysObject:)
    @NSManaged public func removeFromRelays(_ value: Relay)

    @objc(addRelays:)
    @NSManaged public func addToRelays(_ values: NSSet)

    @objc(removeRelays:)
    @NSManaged public func removeFromRelays(_ values: NSSet)
}

extension Author: Identifiable {}

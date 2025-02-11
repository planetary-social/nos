import Foundation
import CoreData

extension Author {

    @nonobjc static func fetchRequest() -> NSFetchRequest<Author> {
        NSFetchRequest<Author>(entityName: "Author")
    }

    @NSManaged var about: String?
    @NSManaged var displayName: String?
    @NSManaged var hexadecimalPublicKey: RawAuthorID?
    @NSManaged var lastUpdatedContactList: Date?
    @NSManaged var lastUpdatedMuteList: Date?
    @NSManaged var lastUpdatedMetadata: Date?
    @NSManaged var muted: Bool
    @NSManaged var name: String?
    @NSManaged var website: String?
    @NSManaged var nip05: String?
    @NSManaged var pronouns: String?
    @NSManaged var profilePhotoURL: URL?
    @NSManaged var rawMetadata: Data?
    @NSManaged var events: Set<Event>
    @NSManaged var followers: Set<Follow>
    
    /// All follow notifications ("This user is now following you") where this Author is the follower. 
    @NSManaged var followNotifications: NSSet
    @NSManaged var follows: Set<Follow>
    @NSManaged var relays: Set<Relay>
    
    /// All notifications that should notify this Author if they are the logged in user.
    /// The notifications are intended for the current author to be received.
    @NSManaged var incomingNotifications: Set<NosNotification>
}

// MARK: Generated accessors for events
extension Author {

    @objc(addEventsObject:)
    @NSManaged func addToEvents(_ value: Event)

    @objc(removeEventsObject:)
    @NSManaged func removeFromEvents(_ value: Event)

    @objc(addEvents:)
    @NSManaged func addToEvents(_ values: NSSet)

    @objc(removeEvents:)
    @NSManaged func removeFromEvents(_ values: NSSet)
}

// MARK: Generated accessors for followers
extension Author {

    @objc(addFollowersObject:)
    @NSManaged func addToFollowers(_ value: Follow)

    @objc(removeFollowersObject:)
    @NSManaged func removeFromFollowers(_ value: Follow)

    @objc(addFollowers:)
    @NSManaged func addToFollowers(_ values: NSSet)

    @objc(removeFollowers:)
    @NSManaged func removeFromFollowers(_ values: NSSet)
}

// MARK: Generated accessors for follows
extension Author {

    @objc(addFollowsObject:)
    @NSManaged func addToFollows(_ value: Follow)

    @objc(removeFollowsObject:)
    @NSManaged func removeFromFollows(_ value: Follow)

    @objc(addFollows:)
    @NSManaged func addToFollows(_ values: NSSet)

    @objc(removeFollows:)
    @NSManaged func removeFromFollows(_ values: NSSet)
}

// MARK: Generated accessors for followNotifications
extension Author {
    
    @objc(addFollowNotificationsObject:)
    @NSManaged func addToFollowNotifications(_ value: NosNotification)
    
    @objc(removeFollowNotificationsObject:)
    @NSManaged func removeFromFollowNotifications(_ value: NosNotification)
    
    @objc(addFollowNotifications:)
    @NSManaged func addToFollowNotifications(_ values: NSSet)
    
    @objc(removeFollowNotifications:)
    @NSManaged func removeFromFollowNotifications(_ values: NSSet)
}

// MARK: Generated accessors for relays
extension Author {

    @objc(addRelaysObject:)
    @NSManaged func addToRelays(_ value: Relay)

    @objc(removeRelaysObject:)
    @NSManaged func removeFromRelays(_ value: Relay)

    @objc(addRelays:)
    @NSManaged func addToRelays(_ values: NSSet)

    @objc(removeRelays:)
    @NSManaged func removeFromRelays(_ values: NSSet)
}

extension Author: Identifiable {}

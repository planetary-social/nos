import CoreData

/// A protocol that defines the common interface for displaying notifications in the app.
/// Both `Event` and `NosNotification` types conform to this protocol to enable unified
/// handling in notification views.
///
/// Conforming types must be `NSManagedObject`s and `Identifiable` to support CoreData
/// persistence and unique identification in SwiftUI lists.
protocol NotificationDisplayable: NSManagedObject, Identifiable {
    var createdAt: Date? { get }

    /// The associated event, if any. For `Event` types, this is the event itself.
    /// For `NosNotification` types, this is the associated event if one exists.
    var event: Event? { get }

    /// The author associated with this notification. For `Event` types, this is the event author.
    /// For `NosNotification` types, this is the follower who generated the notification.
    var author: Author? { get }
}

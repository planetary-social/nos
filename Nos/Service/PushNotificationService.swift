import Foundation
import Logger
import Dependencies
import UIKit
import CoreData
import Combine
import SwiftUI

// Key for notification preference storage
private let notificationPreferenceKey = "com.verse.nos.settings.notificationPreference"

/// Enum representing notification filtering preferences
public enum NotificationPreference: String, CaseIterable, Identifiable {
    case allMentions
    case fromFollowsOnly
    case friendsOfFriends
    
    public var id: String {
        rawValue
    }
    
    public var description: String {
        switch self {
        case .allMentions:
            return String(localized: "All replies and mentions")
        case .fromFollowsOnly:
            return String(localized: "Only from people I follow")
        case .friendsOfFriends:
            return String(localized: "Only from my network")
        }
    }
}

// Key for muted notifications storage
private let notifyOnThreadRepliesKey = "com.verse.nos.settings.notifyOnThreadReplies"

/// A toggle setting to control whether to show notifications for thread replies that don't mention the user
extension PushNotificationService {
    var notifyOnThreadReplies: Bool {
        get {
            userDefaults.bool(forKey: notifyOnThreadRepliesKey)
        }
        set {
            userDefaults.set(newValue, forKey: notifyOnThreadRepliesKey)
        }
    }
}

extension NotificationPreference: NosSegmentedPickerItem {
    public var titleKey: LocalizedStringKey {
        switch self {
        case .allMentions:
            "allMentions"
        case .fromFollowsOnly:
            "fromFollowsOnly"
        case .friendsOfFriends:
            "friendsOfFriends"
        }
    }
    
    public var image: Image {
        switch self {
        case .allMentions:
            Image(systemName: "bell.fill")
        case .fromFollowsOnly:
            Image(systemName: "person.fill")
        case .friendsOfFriends:
            Image(systemName: "person.2.fill") 
        }
    }
}

/// A class that abstracts our interactions with push notification infrastructure and iOS permissions. It can handle
/// UNUserNotificationCenterDelegate callbacks for receiving and displaying notifications, and it watches the db for
/// all new events and creates `NosNotification`s and displays them when appropriate.
@MainActor @Observable class PushNotificationService:
    NSObject, NSFetchedResultsControllerDelegate, UNUserNotificationCenterDelegate {
    
    // MARK: - Public Properties
    
    /// The number of unread notifications that should be displayed as a badge
    private(set) var badgeCount = 0
    
    /// User preference for notification filtering
    var notificationPreference: NotificationPreference {
        get {
            guard let savedValue = userDefaults.string(forKey: notificationPreferenceKey),
                  let preference = NotificationPreference(rawValue: savedValue) else {
                return .allMentions
            }
            return preference
        }
        set {
            userDefaults.set(newValue.rawValue, forKey: notificationPreferenceKey)
        }
    }

    private let showPushNotificationsAfterKey = "PushNotificationService.notificationCutoff"

    /// Used to limit which notifications are displayed to the user as push notifications.
    /// 
    /// When the user first opens the app it is initialized to Date.now.
    /// This is to prevent us showing tons of push notifications on first login.
    /// Then after that it is set to the date of the last notification that we showed.
    var showPushNotificationsAfter: Date {
        get {
            let unixTimestamp = userDefaults.double(forKey: showPushNotificationsAfterKey)
            if unixTimestamp == 0 {
                userDefaults.set(Date.now.timeIntervalSince1970, forKey: showPushNotificationsAfterKey)
                return .now
            } else {
                return Date(timeIntervalSince1970: unixTimestamp)
            }
        }
        set {
            userDefaults.set(newValue.timeIntervalSince1970, forKey: showPushNotificationsAfterKey)
        }
    }
    
    // MARK: - Private Properties
    
    @ObservationIgnored @Dependency(\.relayService) private var relayService
    @ObservationIgnored @Dependency(\.persistenceController) private var persistenceController
    @ObservationIgnored @Dependency(\.router) private var router
    @ObservationIgnored @Dependency(\.analytics) private var analytics
    @ObservationIgnored @Dependency(\.crashReporting) private var crashReporting
    @ObservationIgnored @Dependency(\.userDefaults) private var userDefaults
    @ObservationIgnored @Dependency(\.currentUser) private var currentUser
    
    private var notificationWatcher: NSFetchedResultsController<Event>?
    private var relaySubscription: SubscriptionCancellable?
    private var currentAuthor: Author? 
    @ObservationIgnored private lazy var modelContext = persistenceController.newBackgroundContext()
    
    @ObservationIgnored private lazy var registrar = PushNotificationRegistrar()
    
    // MARK: - Setup
    
    func listen(for user: CurrentUser) async {
        relaySubscription = nil
        
        guard let author = user.author,
            let authorKey = author.hexadecimalPublicKey else {
            notificationWatcher = NSFetchedResultsController(
                fetchRequest: Event.emptyRequest(), 
                managedObjectContext: modelContext,
                sectionNameKeyPath: nil,
                cacheName: nil
            )
            return
        }
        
        currentAuthor = author
        notificationWatcher = NSFetchedResultsController(
            fetchRequest: Event.all(notifying: author, since: showPushNotificationsAfter), 
            managedObjectContext: modelContext,
            sectionNameKeyPath: nil,
            cacheName: nil
        )
        notificationWatcher?.delegate = self
        await modelContext.perform { [weak self] in
            do { 
                try self?.notificationWatcher?.performFetch()
            } catch {
                Log.error("Error watching notifications:")
                self?.crashReporting.report(error)
            }
        }
        
        let userMentionsFilter = Filter(
            kinds: [.text], 
            pTags: [authorKey], 
            limit: 50,
            keepSubscriptionOpen: true
        )
        relaySubscription = await relayService.fetchEvents(
            matching: userMentionsFilter
        )

        await updateBadgeCount()
        
        do {
            try await registrar.register(user, context: modelContext)
        } catch {
            Log.optional(error, "failed to register for push notifications")
        }
    }
    
    func registerForNotifications(_ user: CurrentUser, with deviceToken: Data) async throws {
        try await registrar.register(user, with: deviceToken, context: modelContext)
    }
    
    // MARK: - Helpers

    func requestNotificationPermissionsFromUser() {
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            if granted {
                Task { @MainActor in UIApplication.shared.registerForRemoteNotifications() }
            }
            if let error {
                Log.error("apns error asking for permissions to show notifications \(error.localizedDescription)")
            }
        }
    }
    
    /// Recomputes the number of unread notifications for the `currentAuthor`, publishes the new value to
    /// `badgeCount`, and updates the application badge icon.
    func updateBadgeCount() async {
        var badgeCount = 0
        if currentAuthor != nil {
            badgeCount = await self.modelContext.perform {
                (try? NosNotification.unreadCount(in: self.modelContext)) ?? 0
            }
        }
        
        self.badgeCount = badgeCount
        try? await UNUserNotificationCenter.current().setBadgeCount(badgeCount)
    }
    
    // MARK: - Internal
    
    /// Determines if the user is explicitly mentioned in the content of an event
    func isUserExplicitlyMentioned(event: Event, userPubKey: String) -> Bool {
        guard let content = event.content else { return false }
        
        // Check for nostr: protocol mentions (e.g., nostr:npub...)
        if content.contains("nostr:npub\(userPubKey)") {
            return true
        }
        
        // Check for @npub mentions
        if content.contains("@npub\(userPubKey)") {
            return true
        }
        
        // Check for hex key mentions
        if content.contains(userPubKey) {
            return true
        }
        
        return false
    }
    
    /// Checks if the current user follows the given author
    @MainActor private func checkIfFollowing(author: Author?) -> Bool {
        guard let currentAuthor = currentAuthor,
              let authorToCheck = author,
              let authorKey = authorToCheck.hexadecimalPublicKey else {
            return false
        }
        
        // Check if the author is in the current user's follows
        for follow in currentAuthor.follows {
            if follow.destination?.hexadecimalPublicKey == authorKey {
                return true
            }
        }
        
        return false
    }
    
    /// Checks if the author is followed by someone the current user follows (friend of friend)
    @MainActor private func checkIfFriendOfFriend(author: Author?) -> Bool {
        guard let currentAuthor = currentAuthor,
              let authorToCheck = author,
              let authorKey = authorToCheck.hexadecimalPublicKey else {
            return false
        }
        
        // Get list of people the current user follows
        let followedByUser = currentAuthor.follows.compactMap { $0.destination }
        
        // For each person the user follows, check if they follow the target author
        for followedAuthor in followedByUser {
            for follow in followedAuthor.follows {
                if follow.destination?.hexadecimalPublicKey == authorKey {
                    return true
                }
            }
        }
        
        return false
    }
    
    /// Tells the system to display a notification for the given event if it's appropriate. This will create a 
    /// NosNotification record in the database.
    @MainActor private func showNotificationIfNecessary(for eventID: RawEventID) async {
        guard let authorKey = currentAuthor?.hexadecimalPublicKey else {
            return
        }
        
        // First, get event and create notification if needed
        let eventAndNotification = await modelContext.perform { () -> (Event?, NosNotification?) in
            guard let event = Event.find(by: eventID, context: self.modelContext),
                let eventCreated = event.createdAt,
                let coreDataNotification = try? NosNotification.createIfNecessary(
                    from: eventID,
                    date: eventCreated,
                    authorKey: authorKey,
                    in: self.modelContext
                ) else {
                // We already have a notification for this event.
                return (nil, nil)
            }
            
            // Don't alert for old notifications or muted authors
            guard let eventCreated = event.createdAt, 
                eventCreated > self.showPushNotificationsAfter,
                event.author?.muted == false else { 
                coreDataNotification.isRead = true
                try? self.modelContext.save()
                return (nil, nil)
            }
            
            // Don't show notifications from muted authors
            if event.author?.muted == true {
                coreDataNotification.isRead = true
                try? self.modelContext.save()
                return (nil, nil)
            }
            
            return (event, coreDataNotification)
        }
        
        // Destructure the tuple
        guard let event = eventAndNotification.0, 
              let coreDataNotification = eventAndNotification.1 else {
            return
        }
        
        var shouldShowNotification = true
        
        // First, check if it's a thread reply without an explicit mention
        let isThreadReply = currentAuthor != nil ? event.isReply(to: currentAuthor!) : false
        let isExplicitlyMentioned = self.isUserExplicitlyMentioned(event: event, userPubKey: authorKey)
        
        // If it's just a thread reply with no explicit mention, apply the thread replies preference
        if isThreadReply && !isExplicitlyMentioned {
            shouldShowNotification = self.notifyOnThreadReplies
        }
        
        // Then apply source filtering based on user preference
        switch self.notificationPreference {
        case .allMentions:
            // Keep shouldShowNotification as is - we already determined if it's a thread reply we should show
            break
            
        case .fromFollowsOnly:
            // Only show notifications from people the user follows
            let isFollowed = await checkIfFollowing(author: event.author)
            shouldShowNotification = shouldShowNotification && isFollowed
            
        case .friendsOfFriends:
            // Only show notifications from people who are followed by people the user follows
            let isDirectlyFollowed = await checkIfFollowing(author: event.author)
            
            // If not directly followed, we need to check if they're followed by someone the user follows
            if !isDirectlyFollowed {
                let isFriendOfFriend = await checkIfFriendOfFriend(author: event.author)
                shouldShowNotification = shouldShowNotification && (isDirectlyFollowed || isFriendOfFriend)
            }
        }
        
        // Mark as read if filtering rules say not to show it
        if !shouldShowNotification {
            await modelContext.perform {
                coreDataNotification.isRead = true
                try? self.modelContext.save()
            }
            return
        }
        
        // Otherwise, create a view model for the notification
        let viewModel: NotificationViewModel? = await modelContext.perform {
            return NotificationViewModel(coreDataModel: coreDataNotification, context: self.modelContext)
        }
        
        if let viewModel {
            // Leave an hour of margin on the showPushNotificationsAfter date to allow for events arriving slightly 
            // out of order.
            showPushNotificationsAfter = viewModel.date.addingTimeInterval(-60 * 60)
            await viewModel.loadContent(in: self.persistenceController.backgroundViewContext)
            
            do {
                try await UNUserNotificationCenter.current().add(viewModel.notificationCenterRequest)
                await updateBadgeCount()
            } catch {
                Log.optional(error, "Failed to show local notification for event \(eventID)")
            }
        }
    }
    
    // MARK: - UNUserNotificationCenterDelegate
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse) async {
        if response.actionIdentifier == UNNotificationDefaultActionIdentifier {
            analytics.tappedNotification()
            
            let userInfo = response.notification.request.content.userInfo
            if let eventID = userInfo["eventID"] as? String,
                !eventID.isEmpty {
                
                Task { @MainActor in
                    guard let event = Event.find(by: eventID, context: self.persistenceController.viewContext) else {
                        return
                    }
                    self.router.selectedTab = .notifications
                    self.router.push(event.referencedNote() ?? event)
                }
            } else if let data = userInfo["data"] as? [AnyHashable: Any] {
                if let followPubkeys = data["follows"] as? [String],
                    let firstPubkey = followPubkeys.first,
                    let publicKey = PublicKey.build(npubOrHex: firstPubkey) {
                    Task { @MainActor in
                        self.router.pushAuthor(id: publicKey.hex)
                    }
                }
            }
        }
    }
    
    func userNotificationCenter(
        _ center: UNUserNotificationCenter, 
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        analytics.displayedNotification()
        return [.list, .banner, .badge, .sound]
    }
    
    // MARK: - NSFetchedResultsControllerDelegate
    
    nonisolated func controller(
        _ controller: NSFetchedResultsController<NSFetchRequestResult>, 
        didChange anObject: Any, 
        at indexPath: IndexPath?, 
        for type: NSFetchedResultsChangeType, 
        newIndexPath: IndexPath?
    ) {
        guard type == .insert else {
            return
        }
        
        guard let event = anObject as? Event,
            let eventID = event.identifier else {
            return
        }
        
        Task { await showNotificationIfNecessary(for: eventID) }
    }
}

final class MockPushNotificationService: PushNotificationService {
    override func listen(for user: CurrentUser) async { }
    override func registerForNotifications(_ user: CurrentUser, with deviceToken: Data) async throws { }
    override func requestNotificationPermissionsFromUser() { }
}

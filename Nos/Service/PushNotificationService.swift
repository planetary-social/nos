import Foundation
import Logger
import Dependencies
import UIKit
import CoreData
import Combine

/// A class that abstracts our interactions with push notification infrastructure and iOS permissions. It can handle
/// UNUserNotificationCenterDelegate callbacks for receiving and displaying notifications, and it watches the db for
/// all new events and creates `NosNotification`s and displays them when appropriate.
@MainActor @Observable class PushNotificationService:
    NSObject, NSFetchedResultsControllerDelegate, UNUserNotificationCenterDelegate {

    // MARK: - Public Properties

    /// The number of unread notifications that should be displayed as a badge
    private(set) var badgeCount = 0

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
    /// Tells the system to display a notification for the given event if it's appropriate. This will create a
    /// NosNotification record in the database.
    @MainActor private func showNotificationIfNecessary(for eventID: RawEventID) async {
        guard let authorKey = currentAuthor?.hexadecimalPublicKey else {
            return
        }

        let viewModel: NotificationViewModel? = await modelContext.perform { () -> NotificationViewModel? in
            guard let event = Event.find(by: eventID, context: self.modelContext),
                let eventCreated = event.createdAt else {
                return nil
            }

            // For follow events, create a follow notification
            if event.kind == EventKind.contactList.rawValue {
                return self.handleFollowEvent(
                    event: event,
                    authorKey: authorKey,
                    eventCreated: eventCreated
                )
            }

            // Handle other event notifications
            return self.handleGenericNotificationEvent(
                eventID: eventID,
                event: event,
                authorKey: authorKey,
                eventCreated: eventCreated
            )
        }

        if let viewModel {
            // Leave an hour of margin on the showPushNotificationsAfter date to allow for events arriving slightly
            // out of order.
            guard let date = viewModel.date else { return }
            showPushNotificationsAfter = date.addingTimeInterval(-60 * 60)
            await viewModel.loadContent(in: self.persistenceController.backgroundViewContext)

            do {
                try await UNUserNotificationCenter.current().add(viewModel.notificationCenterRequest)
                await updateBadgeCount()
            } catch {
                Log.optional(error, "Failed to show local notification for event \(eventID)")
            }
        }
    }

    /// Processes a contact list event and creates a notification for new followers
    /// - Parameters:
    ///   - event: The Nostr event containing the contact list information
    ///   - authorKey: The public key of the author receiving the follow
    ///   - eventCreated: The timestamp when the event was created
    /// - Returns: A `NotificationViewModel` if the notification should be displayed, nil otherwise
    private func handleFollowEvent(event: Event, authorKey: String, eventCreated: Date) -> NotificationViewModel? {
        guard let follower = event.author else { return nil }

        // Get the current author in this context
        guard let currentAuthorInContext = try? Author.findOrCreate(by: authorKey, context: self.modelContext) else {
            return nil
        }

        let notification = NosNotification(context: self.modelContext)
        notification.user = currentAuthorInContext
        notification.follower = follower
        notification.createdAt = eventCreated

        try? self.modelContext.save()

        // Don't alert for old notifications or muted authors
        guard eventCreated > self.showPushNotificationsAfter, follower.muted == false else {
            notification.isRead = true
            return nil
        }

        return NotificationViewModel(coreDataModel: notification, context: self.modelContext, createdAt: eventCreated)
    }

    /// Processes a generic notification event and creates a notification if necessary
    /// - Parameters:
    ///   - eventID: The unique identifier of the Nostr event
    ///   - event: The Nostr event to process
    ///   - authorKey: The public key of the author receiving the notification
    ///   - eventCreated: The timestamp when the event was created
    /// - Returns: A `NotificationViewModel` if the notification should be displayed, nil otherwise
    private func handleGenericNotificationEvent(
        eventID: String,
        event: Event,
        authorKey: String,
        eventCreated: Date
    ) -> NotificationViewModel? {
        guard let coreDataNotification = try? NosNotification.createIfNecessary(
            from: eventID,
            date: eventCreated,
            authorKey: authorKey,
            in: self.modelContext
        ) else {
            // We already have a notification for this event.
            return nil
        }

        defer { try? self.modelContext.save() }

        // Don't alert for old notifications or muted authors
        guard eventCreated > self.showPushNotificationsAfter,
            event.author?.muted == false else {
            coreDataNotification.isRead = true
            return nil
        }

        return NotificationViewModel(
            coreDataModel: coreDataNotification,
            context: self.modelContext,
            createdAt: eventCreated
        )
    }

    // MARK: - UNUserNotificationCenterDelegate

    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse) async {
        if response.actionIdentifier == UNNotificationDefaultActionIdentifier {
            analytics.tappedNotification()

            let userInfo = response.notification.request.content.userInfo
            if let eventID = userInfo["eventID"] as? String,
            !eventID.isEmpty {

                Task { @MainActor in
                    if let follower = try? Author.find(by: eventID, context: self.persistenceController.viewContext) {
                        self.router.selectedTab = .notifications
                        self.router.push(follower)
                    } else if let event = Event.find(by: eventID, context: self.persistenceController.viewContext) {
                        self.router.selectedTab = .notifications
                        self.router.push(event.referencedNote() ?? event)
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

    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any]) async {
        if let data = userInfo["data"] as? [AnyHashable: Any], let followPubkeys = data["follows"] as? [String],
        let firstPubkey = followPubkeys.first,
        let followerKey = PublicKey.build(npubOrHex: firstPubkey)?.hex {

            // Create Event for the follow
            await modelContext.perform { [weak self] in
                guard let self else { return }

                do {
                    let event = Event(context: self.modelContext)
                    event.identifier = UUID().uuidString
                    event.author = try Author.findOrCreate(by: followerKey, context: self.modelContext)
                    event.kind = EventKind.contactList.rawValue
                    event.createdAt = .now

                    try self.modelContext.save()

                    // Show notification for the follow
                    Task { @MainActor in
                        guard let identifier = event.identifier else { return }
                        await self.showNotificationIfNecessary(for: identifier)
                    }
                } catch {
                    Log.optional(error, "Error creating follow notification for \(followerKey)")
                }
            }
        }
    }
}

final class MockPushNotificationService: PushNotificationService {
    override func listen(for user: CurrentUser) async { }
    override func registerForNotifications(_ user: CurrentUser, with deviceToken: Data) async throws { }
    override func requestNotificationPermissionsFromUser() { }
}

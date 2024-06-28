import Foundation
import Logger
import Dependencies
import UIKit
import CoreData
import Combine

/// A class that abstracts our interactions with push notification infrastructure and iOS permissions. It can handle
/// UNUserNotificationCenterDelegate callbacks for receiving and displaying notifications, and it watches the db for
/// all new events and creates `NosNotification`s and displays them when appropriate.
@MainActor class PushNotificationService: 
    NSObject, ObservableObject, NSFetchedResultsControllerDelegate, UNUserNotificationCenterDelegate {

    enum PushNotificationError: LocalizedError {
        case unexpected
        var errorDescription: String? {
            "Something unexpected happened"
        }
    }
    
    // MARK: - Public Properties
    
    /// The number of unread notifications that should be displayed as a badge
    @Published var badgeCount = 0

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
    
    @Dependency(\.relayService) private var relayService
    @Dependency(\.persistenceController) private var persistenceController
    @Dependency(\.router) private var router
    @Dependency(\.analytics) private var analytics
    @Dependency(\.userDefaults) private var userDefaults
    @Dependency(\.currentUser) private var currentUser
    
    #if DEBUG
    private let notificationServiceAddress = "wss://dev-notifications.nos.social"
    #else
    private let notificationServiceAddress = "wss://notifications.nos.social"
    #endif
    
    private var notificationWatcher: NSFetchedResultsController<Event>?
    private var relaySubscription: SubscriptionCancellable?
    private var currentAuthor: Author? 
    private lazy var modelContext: NSManagedObjectContext = {
        persistenceController.newBackgroundContext()
    }()
    
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
        try? await modelContext.perform {
            try self.notificationWatcher?.performFetch()
        }
        
        let userMentionsFilter = Filter(
            kinds: [.text, .longFormContent, .like], 
            pTags: [authorKey], 
            limit: 50
        )
        relaySubscription = await relayService.subscribeToEvents(matching: userMentionsFilter)
        
        await updateBadgeCount()
    }
    
    func registerForNotifications(with token: Data, user: CurrentUser) async throws {
        guard let userKey = user.publicKeyHex, let keyPair = user.keyPair else {
            // TODO: throw
            return
        }
        
        do {
            let jsonEvent = JSONEvent(
                pubKey: userKey,
                kind: EventKind.notificationServiceRegistration,
                tags: [],
                content: try await createRegistrationContent(deviceToken: token, user: user)
            )
            try await self.relayService.publish(
                event: jsonEvent, 
                to: URL(string: self.notificationServiceAddress)!, 
                signingKey: keyPair, 
                context: self.modelContext
            )
        } catch {
            analytics.pushNotificationRegistrationFailed(reason: error.localizedDescription)
            throw error
        }
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
    
    /// Recomputes the number of unread notifications for the `currentAuthor` and published the new new value to 
    /// `badgeCount` and updates the application badge icon. 
    func updateBadgeCount() async {
        var badgeCount = 0
        if let currentAuthor {
            badgeCount = await self.modelContext.perform {
                (try? NosNotification.unreadCount(
                    for: currentAuthor, 
                    in: self.modelContext
                )) ?? 0
            }
        }
        
        self.badgeCount = badgeCount
        try? await UNUserNotificationCenter.current().setBadgeCount(badgeCount)
    }
    
    // MARK: - Internal
    
    /// Builds the string needed for the `content` field in the special 
    private func createRegistrationContent(deviceToken: Data, user: CurrentUser) async throws -> String {
        guard let publicKeyHex = currentUser.publicKeyHex else {
            throw PushNotificationError.unexpected
        }
        let relays: [RegistrationRelayAddress] = await relayService.relayAddresses(for: user).map {
            RegistrationRelayAddress(address: $0.absoluteString)
        }
        let content = Registration(
            apnsToken: deviceToken.hexString,
            publicKey: publicKeyHex,
            relays: relays
        )
        guard let string = String(data: try JSONEncoder().encode(content), encoding: .utf8) else {
            throw PushNotificationError.unexpected
        }
        return string
    }
    
    /// Tells the system to display a notification for the given event if it's appropriate. This will create a 
    /// NosNotification record in the database.
    @MainActor private func showNotificationIfNecessary(for eventID: RawEventID) async {
        guard let authorKey = currentAuthor?.hexadecimalPublicKey else {
            return
        }
        
        let viewModel: NotificationViewModel? = await modelContext.perform { () -> NotificationViewModel? in
            guard let event = Event.find(by: eventID, context: self.modelContext),
                let eventCreated = event.createdAt,
                let coreDataNotification = try? NosNotification.createIfNecessary(
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
            guard let eventCreated = event.createdAt, 
                eventCreated > self.showPushNotificationsAfter,
                event.author?.muted == false else { 
                coreDataNotification.isRead = true
                return nil
            }
            
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

class MockPushNotificationService: PushNotificationService {
    override func listen(for user: CurrentUser) async { }
    override func registerForNotifications(with token: Data, user: CurrentUser) async throws { }
    override func requestNotificationPermissionsFromUser() { }
}

fileprivate struct Registration: Codable {
    var apnsToken: String
    var publicKey: String
    var relays: [RegistrationRelayAddress]
}

fileprivate struct RegistrationRelayAddress: Codable {
    var address: String
}

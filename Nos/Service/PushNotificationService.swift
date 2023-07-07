//
//  PushNotificationService.swift
//  Nos
//
//  Created by Matthew Lorentz on 6/28/23.
//

import Foundation
import Logger
import Dependencies
import UIKit
import CoreData
import Combine

/// A class that abstracts our interactions with our push notification server.
@MainActor class PushNotificationService: 
    NSObject, ObservableObject, NSFetchedResultsControllerDelegate, UNUserNotificationCenterDelegate {
    
    // MARK: - Public Properties
    
    /// The number of unread notifications that should be displayed as a badge
    @Published var badgeCount = 0
    private(set) var oldNotificationCutoff: Date
    
    // MARK: - Private Properties
    
    @Dependency(\.relayService) private var relayService
    @Dependency(\.persistenceController) private var persistenceController
    @Dependency(\.router) private var router
    @Dependency(\.analytics) private var analytics
    private let notificationServiceAddress = "wss://notifications.nos.social"
    private var notificationWatcher: NSFetchedResultsController<Event>?
    private var relaySubscription: RelaySubscription.ID?
    private var currentAuthor: Author? 
    private lazy var modelContext: NSManagedObjectContext = {
        persistenceController.newBackgroundContext()
    }()
    
    // MARK: - Setup
    
    override init() {
        oldNotificationCutoff = .now
        super.init()
        
        do {
            let oldestEvent = try persistenceController.viewContext.fetch(Event.oldest()).first
            oldNotificationCutoff = oldestEvent?.receivedAt ?? .now
        } catch {
            Log.error("Error fetching oldest event \(error.localizedDescription)")
        }
    }
    
    func listen(for user: CurrentUser) async {
        if let relaySubscription {
            await relayService.decrementSubscriptionCount(for: relaySubscription)
        }
        
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
            // TODO: we shouldn't reprocess all notifications every time this is called
            fetchRequest: Event.all(notifying: author, since: oldNotificationCutoff), 
            managedObjectContext: modelContext,
            sectionNameKeyPath: nil,
            cacheName: nil
        )
        notificationWatcher?.delegate = self
        try? notificationWatcher?.performFetch()
        
        let userMentionsFilter = Filter(
            kinds: [.text, .longFormContent, .like], 
            pTags: [authorKey], 
            limit: 50
        )
        relaySubscription = await relayService.openSubscription(with: userMentionsFilter)
        
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
        UIApplication.shared.applicationIconBadgeNumber = badgeCount
    }
    
    // MARK: - Internal
    
    /// Builds the string needed for the `content` field in the special 
    private func createRegistrationContent(deviceToken: Data, user: CurrentUser) async throws -> String {
        let publicKeyHex = CurrentUser.shared.publicKeyHex
        let relays: [RegistrationRelayAddress] = await relayService.relays(for: user).map {
            RegistrationRelayAddress(address: $0.absoluteString)
        }
        let content = Registration(
            apnsToken: deviceToken.hexString,
            publicKey: publicKeyHex!,
            relays: relays
        )
        return String(data: try JSONEncoder().encode(content), encoding: .utf8)!
    }
    
    /// Tells the system to display a notification for the given event if it's appropriate. This will create a 
    /// NosNotification record in the database.
    @MainActor private func showNotificationIfNecessary(for eventID: HexadecimalString) async {
        guard let authorKey = currentAuthor?.hexadecimalPublicKey else {
            return
        }
        
        let viewModel: NotificationViewModel? = await modelContext.perform { 
            guard let event = Event.find(by: eventID, context: self.modelContext),
                let coreDataNotification = try? NosNotification.createIfNecessary(
                    from: eventID, 
                    authorKey: authorKey, 
                    in: self.modelContext
                ) else {
                // We already have a notification for this event.
                return nil
            }
            
            // Don't alert for old notifications
            guard let notificationCreated = event.createdAt, 
                notificationCreated > self.oldNotificationCutoff else { 
                return nil
            }
            
            return NotificationViewModel(coreDataModel: coreDataNotification, context: self.modelContext) 
        }
        
        if let viewModel {
            await viewModel.loadContent(in: self.modelContext)
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
                self.router.notificationsPath.append(event.referencedNote() ?? event)
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

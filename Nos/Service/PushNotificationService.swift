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
    NSObject, NSFetchedResultsControllerDelegate, UNUserNotificationCenterDelegate {
    
    @Dependency(\.relayService) private var relayService
    @Dependency(\.persistenceController) private var persistenceController
    lazy var modelContext: NSManagedObjectContext = {
        persistenceController.newBackgroundContext()
    }()
    
    var oldNotificationCutoff: Date
    
    private let notificationServiceAddress = "ws://127.0.0.1:8009"
    private var notificationWatcher: NSFetchedResultsController<Event>?
    private var relaySubscription: RelaySubscription.ID?
    private var currentAuthor: Author? 
    
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
            fetchRequest: Event.allNotifications(for: author), // TODO: we should reprocess all notifications every time this is called
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
    }
    
    func registerForNotifications(with token: Data, user: CurrentUser) async throws {
        guard let userKey = user.publicKeyHex, let keyPair = user.keyPair else {
            // TODO: throw
            return
        }
        
        let jsonEvent = JSONEvent(
            pubKey: userKey,
            kind: EventKind.notificationServiceRegistration,
            tags: [],
            content: try await createContent(deviceToken: token, user: user)
        )
        try await modelContext.perform {
            let relay = try Relay.findOrCreate(by: self.notificationServiceAddress, context: self.modelContext)
            try self.modelContext.saveIfNeeded()
            Task {
                try await self.relayService.publish(
                    event: jsonEvent, 
                    to: relay, 
                    signingKey: keyPair, 
                    context: self.modelContext
                )
            }
        }
    }

    func requestNotificationPermissionsFromUser() {
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert]) { granted, error in
            if granted {
                Task { @MainActor in UIApplication.shared.registerForRemoteNotifications() }
            }
            if let error {
                Log.error("apns error asking for permissions to show notifications \(error.localizedDescription)")
            }
        }
    }
    
    private func createContent(deviceToken: Data, user: CurrentUser) async throws -> String {
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
    
    // MARK: - UNUserNotificationCenter
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse) async {
        print(response)
    }
    
    func userNotificationCenter(
        _ center: UNUserNotificationCenter, 
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        [.banner, .badge, .sound]
    }
    
    // MARK: - NSFetchedResultsControllerDelegate
    
    nonisolated func controller(
        _ controller: NSFetchedResultsController<NSFetchRequestResult>, 
        didChange anObject: Any, 
        at indexPath: IndexPath?, 
        for type: NSFetchedResultsChangeType, 
        newIndexPath: IndexPath?
    ) {
        guard let event = anObject as? Event,
            let eventID = event.identifier else {
            return
        }
        
        Task { @MainActor in
            guard let authorKey = self.currentAuthor?.hexadecimalPublicKey else {
                return
            }
            
            await modelContext.perform {
                switch type {
                case .insert:
                    guard let event = Event.find(by: eventID, context: self.modelContext),
                        let _ = try? NosNotification.createIfNecessary(
                            from: eventID, 
                            authorKey: authorKey, 
                            in: self.modelContext
                        ) else {
                            // We already have a notification for this event.
                            return
                        }
                    
                    guard let notificationCreated = event.createdAt, 
                        notificationCreated > self.oldNotificationCutoff else { 
                        return
                    }
                    
                    // TODO: analytics
                    let content = UNMutableNotificationContent()
                    content.title = "Notification"
                    content.body = event.content ?? "null"
                    let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
                    let request = UNNotificationRequest(identifier: eventID, content: content, trigger: trigger)
                    UNUserNotificationCenter.current().add(request) { error in
                        if let error {
                            Log.optional(error, "Error showing notification")
                        }
                    }
                case .delete, .update, .move:
                    fallthrough
                @unknown default:
                    return
                }
            }
        }
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

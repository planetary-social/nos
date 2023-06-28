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

/// A class that abstracts our interactions with our push notification server.
@MainActor class PushNotificationService {
    
    @Dependency(\.relayService) private var relayService
    let viewContext = PersistenceController.shared.viewContext
    
    private let notificationServiceAddress = "ws://192.168.0.10:8008"
    
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
        let relay = try Relay.findOrCreate(by: notificationServiceAddress, context: viewContext)
        try viewContext.saveIfNeeded()
        try await relayService.publish(event: jsonEvent, to: relay, signingKey: keyPair, context: viewContext)
    }

    func askToDisplayNotifications() {
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert]) { _, error in
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
}

class MockPushNotificationService: PushNotificationService {
    override func registerForNotifications(with token: Data, user: CurrentUser) async throws { }
    override func askToDisplayNotifications() { }
}

fileprivate struct Registration: Codable {
    var apnsToken: String
    var publicKey: String
    var relays: [RegistrationRelayAddress]
}

fileprivate struct RegistrationRelayAddress: Codable {
    var address: String
}

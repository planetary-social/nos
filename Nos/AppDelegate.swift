import Foundation
import SwiftUI
import UIKit
import Dependencies

class AppDelegate: NSObject, UIApplicationDelegate {

    private var notificationRegistrationEventType: Int64 = 6666
    private var notificationServiceAddress: URL = URL(string: "ws://192.168.0.10:8008")!
    
    @Dependency(\.relayService) private var relayService
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        askToDisplayNotifications()
        application.registerForRemoteNotifications()
        return true
    }
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        Task{
            do {
                try await sendDeviceTokenToServer(deviceToken: deviceToken)
            }
            catch {
                print("error sending apns token to server: \(error)")
            }
        }
    }
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("apns error", error)
    }
    
    private func askToDisplayNotifications() {
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert]) {
            granted, error in
            if let err = error {
                print("apns error asking for permissions to show notifications", err)
            }
        }
    }
    
    private func sendDeviceTokenToServer(deviceToken: Data) async throws {
        if CurrentUser.shared.keyPair == nil {
            return
        }
        
        var jsonEvent = JSONEvent(
            pubKey: CurrentUser.shared.keyPair!.publicKeyHex,
            kind: EventKind.notificationServiceRegistration,
            tags: [],
            content: try await createContent(deviceToken: deviceToken)
        )
        try jsonEvent.sign(withKey: CurrentUser.shared.keyPair!)
        
        try await relayService.connectToRelayAndSendAnEventToIt(
            relayAddress: notificationServiceAddress,
            signedEvent: jsonEvent
        )
    }

    private func createContent(deviceToken: Data) async throws -> String {
        let publicKeyHex = CurrentUser.shared.publicKeyHex
        let relays: [RegistrationRelayAddress] = await relayService.getUsersRelays(user: CurrentUser.shared).map{
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

struct Registration: Codable {
    var apnsToken: String
    var publicKey: String
    var relays: [RegistrationRelayAddress]
    
    enum CodingKeys: String, CodingKey {
        case apnsToken = "apnsToken"
        case publicKey = "publicKey"
        case relays = "relays"
    }
}

struct RegistrationRelayAddress: Codable {
    var address: String
    
    enum CodingKeys: String, CodingKey {
        case address = "address"
    }
}

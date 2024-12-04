import CoreData
import Dependencies
import Foundation

/// Registers for push notifications.
final class PushNotificationRegistrar {
    
    enum PushNotificationError: LocalizedError {
        case missingPubkey
        case missingDeviceToken
        case unexpected
        
        var errorDescription: String? {
            switch self {
            case .missingPubkey:        "The pubkey is required"
            case .missingDeviceToken:   "Device token is required"
            case .unexpected:           "Something unexpected happened"
            }
        }
    }
    
#if DEBUG
    private static let notificationServiceRelayURL = URL(string: "wss://dev-notifications.nos.social")!
#else
    private static let notificationServiceRelayURL = URL(string: "wss://notifications.nos.social")!
#endif
    
    @Dependency(\.relayService) private var relayService
    @Dependency(\.analytics) private var analytics
    @Dependency(\.currentUser) private var currentUser
    
    private var deviceToken: Data?
    private var registeredPubkey: String?
    private var registrationTask: Task<Void, Error>?
    
    /// Registers a user for push notifications by publishing a registration event. Calls to
    /// this function are handled serially.
    /// - Parameters:
    ///   - user: The user to register for notifications.
    ///   - deviceToken: The device token to register with. A cached token will be used if none is passed in.
    ///   - context: The Core Data context to use.
    func register(_ user: CurrentUser, with deviceToken: Data? = nil, context: NSManagedObjectContext) async throws {
        guard let userKey = user.publicKeyHex, let keyPair = user.keyPair else {
            throw PushNotificationError.missingPubkey
        }
        
        try await registrationTask?.value   // wait for the previous task to finish
        
        guard let token = deviceToken ?? self.deviceToken else {
            throw PushNotificationError.missingDeviceToken
        }
        
        self.deviceToken = token
        
        guard userKey != registeredPubkey else {
            return  // already registered this user
        }
        
        registrationTask = Task {
            do {
                let jsonEvent = JSONEvent(
                    pubKey: userKey,
                    kind: .notificationServiceRegistration,
                    tags: [],
                    content: try await registrationContent(deviceToken: token, user: user)
                )
                try await relayService.publish(
                    event: jsonEvent,
                    to: Self.notificationServiceRelayURL,
                    signingKey: keyPair,
                    context: context
                )
                registeredPubkey = userKey
            } catch {
                analytics.pushNotificationRegistrationFailed(reason: error.localizedDescription)
                throw error
            }
        }
        
        try await registrationTask?.value
    }
    
    /// Builds the string needed for the `content` field.
    private func registrationContent(deviceToken: Data, user: CurrentUser) async throws -> String {
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
}

fileprivate struct Registration: Encodable {
    let apnsToken: String
    let publicKey: String
    let relays: [RegistrationRelayAddress]
}

fileprivate struct RegistrationRelayAddress: Encodable {
    let address: String
}

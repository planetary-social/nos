import Foundation
import UIKit
import Logger
import Dependencies

class AppDelegate: NSObject, UIApplicationDelegate {
    
    @Dependency(\.currentUser) private var currentUser
    @Dependency(\.pushNotificationService) private var pushNotificationService
    @Dependency(\.analytics) private var analytics

    func application(
        _ application: UIApplication, 
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        application.registerForRemoteNotifications()
        UNUserNotificationCenter.current().delegate = pushNotificationService
        return true
    }
    
    func application(
        _ application: UIApplication, 
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        Task { 
            do {
                try await PushNotificationService().registerForNotifications(with: deviceToken, user: currentUser)
                Log.info("PushNotifications: registered \(deviceToken.hexString)")
            } catch {
                Log.optional(error, "failed to register for push notifications")
            }
        }
    }
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        Log.error("apns error \(error.localizedDescription)")
    }
    
    func application(
        _ application: UIApplication, 
        didReceiveRemoteNotification userInfo: [AnyHashable: Any]
    ) async -> UIBackgroundFetchResult {
        do {
            Log.info("PushNotifications: Received background notification. Subscribing to relays.")
            analytics.receivedNotification()
            await currentUser.subscribe()
            try await Task.sleep(for: .seconds(10))
            Log.info("PushNotifications: Sync complete")
            return .newData
        } catch {
            return .failed
        }
    }
}

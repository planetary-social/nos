import Foundation
import UIKit
import Logger
import Dependencies
import SDWebImage
import SDWebImageWebPCoder

@MainActor
class AppDelegate: NSObject, UIApplicationDelegate {

    @Dependency(\.currentUser) private var currentUser
    @Dependency(\.pushNotificationService) private var pushNotificationService
    @Dependency(\.analytics) private var analytics

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        setUpWebPCoder()
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
                try await pushNotificationService.registerForNotifications(currentUser, with: deviceToken)
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

extension AppDelegate {
    /// Sets up the WebP coder for SDWebImage so we can determine whether WebP images are static or animated.
    func setUpWebPCoder() {
        let webPCoder = SDImageWebPCoder.shared
        SDImageCodersManager.shared.addCoder(webPCoder)
    }
}

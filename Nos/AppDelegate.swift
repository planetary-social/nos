import Foundation
import UIKit
import Logger
import Dependencies

class AppDelegate: NSObject, UIApplicationDelegate {
    
    @Dependency(\.currentUser) private var currentUser

    func application(
        _ application: UIApplication, 
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        application.registerForRemoteNotifications()
        return true
    }
    
    func application(
        _ application: UIApplication, 
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        Task { try await PushNotificationService().registerForNotifications(with: deviceToken, user: currentUser) }
    }
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        Log.error("apns error \(error.localizedDescription)")
    }
}

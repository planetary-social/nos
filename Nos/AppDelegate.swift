import Foundation
import SwiftUI
import UIKit

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        application.registerForRemoteNotifications()
        return true
    }
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        print("apns registered", deviceToken.base64EncodedString())
        self.sendDeviceTokenToServer(deviceToken: deviceToken)
    }
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("apns error", error)
    }
    
    private func sendDeviceTokenToServer(deviceToken: Data) {
        // todo how to get our public key?
        // todo how to get our locale?
        // todo how to get our relays?
        // todo how to connect to a relay and send an event to it?
    }
}

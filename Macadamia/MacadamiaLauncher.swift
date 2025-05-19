import Foundation
import SwiftUI

// This file provides a launcher for the Macadamia wallet
// It works independently of package dependencies

/// MacadamiaLauncher provides platform-independent methods to launch the Macadamia wallet
public enum MacadamiaLauncher {
    
    /// Launches the Macadamia wallet
    /// - Returns: True if launching was successful
    @discardableResult
    public static func launch() -> Bool {
        #if os(iOS)
        return launchOnIOS()
        #elseif os(macOS)
        return launchOnMacOS()
        #else
        return false
        #endif
    }
    
    /// Checks if Macadamia is installed
    /// - Returns: True if the wallet is installed
    public static func isInstalled() -> Bool {
        #if os(iOS)
        if let url = URL(string: "macadamia://wallet") {
            return UIApplication.shared.canOpenURL(url)
        }
        #endif
        return false
    }
    
    /// Opens the Macadamia web wallet
    /// - Returns: True if opening was successful
    @discardableResult
    public static func openWebWallet() -> Bool {
        if let webURL = URL(string: "https://macadamia.nos.cash") {
            #if os(iOS)
            UIApplication.shared.open(webURL, options: [:], completionHandler: nil)
            return true
            #elseif os(macOS)
            NSWorkspace.shared.open(webURL)
            return true
            #else
            return false
            #endif
        }
        return false
    }
    
    // MARK: - Private Methods
    
    #if os(iOS)
    private static func launchOnIOS() -> Bool {
        if let macadamiaURL = URL(string: "macadamia://wallet") {
            UIApplication.shared.open(macadamiaURL, options: [:]) { success in
                if !success {
                    // Try web version
                    _ = openWebWallet()
                }
            }
            return true
        } else {
            // URL scheme failed, try web version
            return openWebWallet()
        }
    }
    #endif
    
    #if os(macOS)
    private static func launchOnMacOS() -> Bool {
        let appPath = "/Applications/Macadamia.app"
        
        if FileManager.default.fileExists(atPath: appPath) {
            let process = Process()
            process.launchPath = "/usr/bin/open"
            process.arguments = [appPath]
            
            do {
                try process.run()
                return true
            } catch {
                print("Error launching Macadamia: \(error)")
                return openWebWallet()
            }
        } else {
            return openWebWallet()
        }
    }
    #endif
}
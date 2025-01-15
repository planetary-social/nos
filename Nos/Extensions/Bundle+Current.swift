import Foundation

private class CurrentBundle {}

extension Bundle {
    enum InstallationSource: String {
        case testFlight = "TestFlight"
        case appStore = "App Store"
        case debug = "Debug"
    }

    static let current = Bundle(for: CurrentBundle.self)
    
    var version: String {
        let version = self.infoDictionary?["CFBundleShortVersionString"] as? String ?? ""
        return version
    }

    var build: String {
        let build = self.infoDictionary?["CFBundleVersion"] as? String ?? ""
        return build
    }

    /// Returns a string from the bundle version and short version
    /// formatted as 1.2.3 (123).
    var versionAndBuild: String {
        "\(self.version) (\(self.build))"
    }

    /// Checks the app's receipt URL to determine if it contains the TestFlight-specific
    /// "sandboxReceipt" identifier.
    /// - Returns: `true` if the app was installed through TestFlight, `false` otherwise.
    private var isTestFlight: Bool {
        Bundle.main.appStoreReceiptURL?.lastPathComponent == "sandboxReceipt"
    }

    /// Returns the app's installation source: debug, TestFlight, or App Store.
    var installationSource: InstallationSource {
    #if DEBUG
        return .debug
    #else
        return isTestFlight ? .testFlight : .appStore
    #endif
    }
}

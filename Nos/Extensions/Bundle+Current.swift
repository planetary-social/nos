import Foundation
import Security

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

    /// > Warning: This method relies on undocumented implementation details to determine the installation source
    /// and may break in future iOS releases.
    /// https://gist.github.com/lukaskubanek/cbfcab29c0c93e0e9e0a16ab09586996
    /// Checks the app's receipt URL to determine if it contains the TestFlight-specific
    /// "sandboxReceipt" identifier.
    /// - Returns: `true` if the app was installed through TestFlight, `false` otherwise.
    private var isIosTestFlight: Bool {
        Bundle.main.appStoreReceiptURL?.lastPathComponent == "sandboxReceipt"
    }

    /// Returns whether the bundle was signed for TestFlight beta distribution by checking
    /// the existence of a specific extension (marker OID) on the code signing certificate.
    ///
    /// This routine is inspired by the source code from ProcInfo, the underlying library
    /// of the WhatsYourSign code signature checking tool developed by Objective-See. Initially,
    /// it checked the common name but was changed to an extension check to make it more
    /// future-proof.
    ///
    /// For more information, see the following references:
    /// - https://github.com/objective-see/ProcInfo/blob/master/procInfo/Signing.m#L184-L247
    /// - https://gist.github.com/lukaskubanek/cbfcab29c0c93e0e9e0a16ab09586996#gistcomment-3993808
    private var isMacTestFlight: Bool {
    #if os(macOS)
        var status = noErr

        var code: SecStaticCode?
        status = SecStaticCodeCreateWithPath(bundleURL as CFURL, [], &code)

        guard status == noErr, let code = code else { return false }

        var requirement: SecRequirement?
        status = SecRequirementCreateWithString(
            "anchor apple generic and certificate leaf[field.1.2.840.113635.100.6.1.25.1]" as CFString,
            [], // default
            &requirement
        )

        guard status == noErr, let requirement = requirement else { return false }

        status = SecStaticCodeCheckValidity(
            code,
            [], // default
            requirement
        )

        return status == errSecSuccess
    #else
        return false
    #endif
    }

    /// Returns the app's installation source: debug, TestFlight, or App Store.
    var installationSource: InstallationSource {
    #if DEBUG
        return .debug
    #else
        #if os(iOS)
            return isIosTestFlight ? .testFlight : .appStore
        #elseif os(macOS)
            return isMacTestFlight ? .testFlight : .appStore
        #else
            return .debug
        #endif
    #endif
    }
}

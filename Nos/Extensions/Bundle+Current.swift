import Foundation

private class CurrentBundle {}

extension Bundle {

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
}

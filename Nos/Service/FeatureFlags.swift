import Foundation
import Dependencies

/// The set of feature flags used by the app.
protocol FeatureFlags {
    /// Whether the new media display should be enabled or not.
    var newMediaDisplayEnabled: Bool { get }

    // MARK: - Additional requirements for debug mode

    #if DEBUG
    func setNewMediaDisplayEnabled(_ enabled: Bool)
    #endif
}

/// The default set of feature flag values for the app.
class DefaultFeatureFlags: FeatureFlags, DependencyKey {
    /// The one and only instance of `DefaultFeatureFlags`.
    static let liveValue = DefaultFeatureFlags()

    fileprivate init() {}

    private(set) var newMediaDisplayEnabled = false
}

#if DEBUG
extension DefaultFeatureFlags {
    func setNewMediaDisplayEnabled(_ enabled: Bool) {
        newMediaDisplayEnabled = enabled
    }
}
#endif

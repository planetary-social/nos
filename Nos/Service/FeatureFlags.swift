import Foundation
import Dependencies

/// The set of feature flags used by the app.
protocol FeatureFlags {
    /// Whether the new media display should be enabled or not.
    /// - Note: See [#1177](https://github.com/planetary-social/nos/issues/1177) for details on the new media display.
    var newMediaDisplayEnabled: Bool { get }

    // MARK: - Additional requirements for debug mode

    #if DEBUG || STAGING
    /// Sets the value of `newMediaDisplayEnabled`.
    func setNewMediaDisplayEnabled(_ enabled: Bool)
    #endif
}

/// The default set of feature flag values for the app.
class DefaultFeatureFlags: FeatureFlags, DependencyKey {
    /// The one and only instance of `DefaultFeatureFlags`.
    static let liveValue = DefaultFeatureFlags()

    private init() {}

    private(set) var newMediaDisplayEnabled = false
}

#if DEBUG || STAGING
extension DefaultFeatureFlags {
    func setNewMediaDisplayEnabled(_ enabled: Bool) {
        newMediaDisplayEnabled = enabled
    }
}
#endif

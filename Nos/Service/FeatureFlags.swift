import Foundation
import Dependencies

/// Enum to represent each feature flag. Add new feature flags here easily.
enum FeatureFlag: String {
    /// Whether the new media display should be enabled or not.
    /// - Note: See [#1177](https://github.com/planetary-social/nos/issues/1177) for details on the new media display.
    case newMediaDisplay
    /// Whether the new moderation flow should be enabled or not.
    /// - Note: See [#1489](https://github.com/planetary-social/nos/issues/1489) for details on the new moderation flow.
    case newModerationFlow
}

/// The set of feature flags used by the app.
protocol FeatureFlags {
    /// Retrieves the value of the specified feature flag.
    func isEnabled(_ feature: FeatureFlag) -> Bool

    // MARK: - Additional requirements for debug mode
    #if DEBUG || STAGING
    /// Sets the value of the specified feature flag.
    func setEnabled(_ feature: FeatureFlag, enabled: Bool)
    #endif
}

/// The default set of feature flag values for the app.
class DefaultFeatureFlags: FeatureFlags, DependencyKey {
    /// The one and only instance of `DefaultFeatureFlags`.
    static let liveValue = DefaultFeatureFlags()

    private init() {}

    /// A dictionary to store the values of feature flags.
    private var featureFlags: [FeatureFlag: Bool] = [
        .newMediaDisplay: false,
        .newModerationFlow: false
    ]

    func isEnabled(_ feature: FeatureFlag) -> Bool {
        featureFlags[feature] ?? false
    }

    #if DEBUG || STAGING
    func setEnabled(_ feature: FeatureFlag, enabled: Bool) {
        featureFlags[feature] = enabled
    }
    #endif
}

import Foundation
import Dependencies
import SwiftUI

/// Feature flags for enabling experimental or beta features.
enum FeatureFlag {
    /// Whether the new moderation flow should be enabled or not.
    /// - Note: See [#1489](https://github.com/planetary-social/nos/issues/1489) for details on the new moderation flow.
    case newModerationFlow
    /// Whether delete account UI is enabled or not.
    /// - Note: See [#80](https://github.com/planetary-social/nos/issues/80) for details on deleting accounts.
    case deleteAccount
}

/// The set of feature flags used by the app.
protocol FeatureFlags {
    /// Retrieves the value of the specified feature flag.
    func isEnabled(_ feature: FeatureFlag) -> Bool

    // MARK: - Additional requirements for debug mode
    #if DEBUG || STAGING
    /// Sets the value of the specified feature flag.
    func setFeature(_ feature: FeatureFlag, enabled: Bool)
    #endif
}

/// The default set of feature flag values for the app.
@Observable class DefaultFeatureFlags: FeatureFlags, DependencyKey {
    /// The one and only instance of `DefaultFeatureFlags`.
    static let liveValue = DefaultFeatureFlags()

    private init() {}

    /// Feature flags and their values.
    private var featureFlags: [FeatureFlag: Bool] = [
        .newModerationFlow: false,
        .deleteAccount: false
    ]

    /// Returns true if the feature is enabled.
    func isEnabled(_ feature: FeatureFlag) -> Bool {
        featureFlags[feature] ?? false
    }

    #if DEBUG || STAGING
    func setFeature(_ feature: FeatureFlag, enabled: Bool) {
        featureFlags[feature] = enabled
    }
    #endif
}

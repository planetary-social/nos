import Foundation
import Dependencies
import SwiftUI

/// Feature flags for enabling experimental or beta features.
enum FeatureFlag {
    /// Whether the new onboarding flow should be enabled or not.
    /// - Note: See [Figma](https://www.figma.com/design/6MeujQUXzC1AuviHEHCs0J/Nos---In-Progress?node-id=9221-8504)
    ///         for the new flow.
    case newOnboardingFlow
    
    case sensitiveContentOutgoing
    case sensitiveContentIncoming
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
        .newOnboardingFlow: true,
        .sensitiveContentOutgoing: false,
        .sensitiveContentIncoming: false
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

import Foundation
import Dependencies
import SwiftUI

/// Feature flags for enabling experimental or beta features.
enum FeatureFlag {
    /// Whether the new onboarding flow should be enabled or not.
    /// - Note: See [Figma](https://www.figma.com/design/6MeujQUXzC1AuviHEHCs0J/Nos---In-Progress?node-id=9221-8504)
    ///         for the new flow.
    case newOnboardingFlow
    
    /// Whether to use the Macadamia wallet integration.
    /// When enabled, the wallet button will launch the Macadamia external wallet.
    /// When disabled, it will use the built-in wallet UI.
    case useMacadamiaWallet
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
@Observable final class DefaultFeatureFlags: FeatureFlags, DependencyKey {
    /// The one and only instance of `DefaultFeatureFlags`.
    static let liveValue = DefaultFeatureFlags()

    private init() {}

    /// Feature flags and their values.
    private var featureFlags: [FeatureFlag: Bool] = [
        .newOnboardingFlow: true,
        .useMacadamiaWallet: true // Enabled - using the real Macadamia wallet integration
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

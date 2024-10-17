/// A set of feature flag values used for testing that can be customized.
class MockFeatureFlags: FeatureFlags {
    /// Mock feature flags and their values.
    private var featureFlags: [FeatureFlag: Bool] = [
        .newOnboardingFlow: true
    ]

    func isEnabled(_ feature: FeatureFlag) -> Bool {
        featureFlags[feature] ?? false
    }
    
    func setFeature(_ feature: FeatureFlag, enabled: Bool) {
        featureFlags[feature] = enabled
    }
}

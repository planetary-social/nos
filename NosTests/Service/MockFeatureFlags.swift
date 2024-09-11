/// A set of feature flag values used for testing that can be customized.
class MockFeatureFlags: FeatureFlags {
    /// A dictionary to store the mock values for feature flags.
    private var featureFlags: [FeatureFlag: Bool] = [
        .newMediaDisplay: false,
        .newModerationFlow: false
    ]

    func isEnabled(_ feature: FeatureFlag) -> Bool {
        featureFlags[feature] ?? false
    }
    
    func setEnabled(_ feature: FeatureFlag, enabled: Bool) {
        featureFlags[feature] = enabled
    }
}

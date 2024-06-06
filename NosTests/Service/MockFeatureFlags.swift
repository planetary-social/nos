/// A set of feature flag values used for testing that can be customized.
class MockFeatureFlags: FeatureFlags {
    var newMediaDisplayEnabled = false

    func setNewMediaDisplayEnabled(_ enabled: Bool) {
        newMediaDisplayEnabled = enabled
    }
}

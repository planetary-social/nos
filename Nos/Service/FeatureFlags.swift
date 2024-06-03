import Foundation

/// The set of feature flags used by the app.
protocol FeatureFlags {
    var newMediaDisplayEnabled: Bool { get }
}

/// The default set of feature flag values for the app.
struct DefaultFeatureFlags: FeatureFlags {
    let newMediaDisplayEnabled = false
}

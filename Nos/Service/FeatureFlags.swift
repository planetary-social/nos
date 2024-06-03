import Foundation

protocol FeatureFlags {
    var newMediaDisplayEnabled: Bool { get }
}

struct DefaultFeatureFlags: FeatureFlags {
    let newMediaDisplayEnabled = false
}

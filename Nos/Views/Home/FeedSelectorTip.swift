import Dependencies
import SwiftUI

struct FeedSelectorTip {
    @Dependency(\.userDefaults) private var userDefaults
    
    static let hasShownFeedTipKey = "com.verse.nos.Home.hasShownFeedTip"
    
    static let minimumScrollOffset: CGFloat = 1500
    static let maximumDelay: TimeInterval = 30
    
    var hasShown: Bool {
        get {
            userDefaults.bool(forKey: Self.hasShownFeedTipKey)
        }
        set {
            userDefaults.set(newValue, forKey: Self.hasShownFeedTipKey)
        }
    }
}

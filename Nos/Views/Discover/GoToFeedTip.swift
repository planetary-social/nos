import TipKit

/// A tip that's displayed on the Discover view after the user has followed three accounts.
struct GoToFeedTip: Tip {
    /// A TipKit Event that tracks the number of accounts that have been followed.
    static let followedAccount = Tips.Event(id: "followedAccount")

    /// A TipKit Event that tracks how many times the Feed has been displayed.
    static let viewedFeed = Tips.Event(id: "viewedFeed")

    var title: Text {
        Text("goToYourFeed")
    }

    var rules: [Rule] {
        // Each rule here is combined using the logical AND, so all rules must return true for the tip to display.

        #Rule(Self.followedAccount) {
            $0.donations.count >= 3
        }

        #Rule(Self.viewedFeed) {
            $0.donations.count < 1
        }
    }
}

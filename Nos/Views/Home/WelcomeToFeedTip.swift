import TipKit

/// A tip that's displayed on the Feed view, also known as the Home view.
struct WelcomeToFeedTip: Tip {
    var title: Text {
        Text("welcomeToYourFeed")
    }

    var message: Text? {
        Text("nosDoesNotUseAlgorithms")
    }
}

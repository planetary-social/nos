import Dependencies
import Foundation
import Logger
import SwiftUI

@Observable class AppController {

    enum CurrentState {
        case onboarding
        case loggedIn
    }

    private(set) var currentState: CurrentState?

    @ObservationIgnored @Dependency(\.analytics) private var analytics
    @ObservationIgnored @Dependency(\.router) private var router
    @ObservationIgnored @Dependency(\.currentUser) private var currentUser

    init() {
        Log.info("App Version: \(Bundle.current.versionAndBuild)")
    }

    func configureCurrentState() {
        currentState = currentUser.keyPair == nil ? .onboarding : .loggedIn
        Task { @MainActor in
            let signedInAuthor = currentUser.author
            if currentState == .loggedIn, let signedInAuthor, signedInAuthor.lastUpdatedContactList == nil {
                router.selectedTab = .discover
            }
        }
    }

    @MainActor func completeOnboarding() {
        router.sideMenuPath = NavigationPath()
        router.closeSideMenu()
        router.selectedTab = .discover
        currentState = .loggedIn
        analytics.completedOnboarding()
    }
}

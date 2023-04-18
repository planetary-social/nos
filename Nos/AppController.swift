//
//  AppController.swift
//  Nos
//
//  Created by Shane Bielefeld on 2/15/23.
//

import Foundation
import Dependencies
import SwiftUI
import Logger

class AppController: ObservableObject {
    
    enum CurrentState {
        case onboarding
        case loggedIn
    }
    
    @Published private(set) var currentState: CurrentState?
    
    @Dependency(\.analytics) private var analytics
    
    var router: Router
    var currentUser: CurrentUser
    
    init(currentUser: CurrentUser, router: Router) {
        self.router = router
        self.currentUser = currentUser
        Log.info("App Version: \(Bundle.current.versionAndBuild)")
    }
    
    func configureCurrentState() {
        currentState = currentUser.keyPair == nil ? .onboarding : .loggedIn
    }
    
    func completeOnboarding() {
        router.sideMenuPath = NavigationPath()
        router.closeSideMenu()
        router.selectedTab = .discover
        currentState = .loggedIn
        analytics.completedOnboarding()
    }
}

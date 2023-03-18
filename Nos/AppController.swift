//
//  AppController.swift
//  Nos
//
//  Created by Shane Bielefeld on 2/15/23.
//

import Foundation
import Dependencies
import SwiftUI

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
        print("Initializing analytics. This is hack to get the dependency initialzed by printing it: \(analytics)")
    }
    
    func configureCurrentState() {
        currentState = currentUser.keyPair == nil ? .onboarding : .loggedIn
    }
    
    func completeOnboarding() {
        currentState = .loggedIn

        router.sideMenuPath = NavigationPath()
        router.closeSideMenu()
        router.selectedTab = .discover

        analytics.completedOnboarding()
    }
}

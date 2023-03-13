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
    
    init(router: Router) {
        self.router = router
    }
    
    func configureCurrentState() {
        currentState = KeyChain.load(key: KeyChain.keychainPrivateKey) == nil ? .onboarding : .loggedIn
    }
    
    func completeOnboarding() {
        currentState = .loggedIn
        CurrentUser.subscribe(relays: CurrentUser.onboardingRelays)

        router.sideMenuPath = NavigationPath()
        router.closeSideMenu()
        router.selectedTab = .discover

        analytics.completedOnboarding()
    }
}

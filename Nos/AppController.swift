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
    @Dependency(\.router) private var router
    @Dependency(\.currentUser) private var currentUser
    
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
    
    func completeOnboarding() {
        router.sideMenuPath = NavigationPath()
        router.closeSideMenu()
        router.selectedTab = .discover
        currentState = .loggedIn
        analytics.completedOnboarding()
    }
    
    func openOSSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url, options: [:], completionHandler: nil)
    }
}

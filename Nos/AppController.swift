//
//  AppController.swift
//  Nos
//
//  Created by Shane Bielefeld on 2/15/23.
//

import Foundation

class AppController: ObservableObject {
    enum CurrentState {
        case onboarding
        case loggedIn
    }
    
    @Published private(set) var currentState: CurrentState?
    
    func configureCurrentState() {
        currentState = KeyChain.load(key: KeyChain.keychainPrivateKey) == nil ? .onboarding : .loggedIn
    }
    
    func completeOnboarding() {
        currentState = .loggedIn
    }
}

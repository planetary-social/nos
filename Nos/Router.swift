//
//  Router.swift
//  Nos
//
//  Created by Jason Cheatham on 2/21/23.
//

import SwiftUI

// Used in the NavigationStack and added as an environmentObject so that it can be used for multiple views
class Router: ObservableObject {
    @Published var path = NavigationPath()
    /// Sets the title when navigating to a view
    @Published var navigationTitle = ""
}

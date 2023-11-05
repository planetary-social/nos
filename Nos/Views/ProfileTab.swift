//
//  ProfileTab.swift
//  Nos
//
//  Created by Matthew Lorentz on 3/9/23.
//

import Combine
import SwiftUI

/// A version of the ProfileView that is displayed in the main tab bar
struct ProfileTab: View {
    
    @Environment(CurrentUser.self) var currentUser
    @ObservedObject var author: Author
    
    @Binding var path: NavigationPath
    
    @Environment(Router.self) private var router

    var body: some View {
        NavigationStack(path: $path) {
            ProfileView(author: author)
                .navigationBarItems(leading: SideMenuButton())
                .navigationDestination(for: Author.self) { profile in
                    if profile == currentUser.author, currentUser.editing {
                        ProfileEditView(author: author)
                    } else {
                        ProfileView(author: profile)
                    }
                }
                .doubleTapToPop(tab: .profile)
        }
    }
}

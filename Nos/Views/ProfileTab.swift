//
//  ProfileTab.swift
//  Nos
//
//  Created by Matthew Lorentz on 3/9/23.
//

import SwiftUI

/// A version of the ProfileView that is displayed in the main tab bar
struct ProfileTab: View {
    
    @EnvironmentObject var currentUser: CurrentUser
    
    @Binding var path: NavigationPath
    
    @EnvironmentObject private var router: Router

    var body: some View {
        NavigationStack(path: $path) {
            if let author = currentUser.author {
                ProfileView(author: author)
                    .navigationBarItems(leading: SideMenuButton())
                    .navigationDestination(for: Author.self) { profile in
                        if currentUser.editing {
                            ProfileEditView(author: author)
                        } else {
                            ProfileView(author: author)
                        }
                    }
            }
        }
    }
}

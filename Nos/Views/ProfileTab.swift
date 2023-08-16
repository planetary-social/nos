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
    
    @EnvironmentObject var currentUser: CurrentUser
    @ObservedObject var author: Author
    
    @Binding var path: NavigationPath
    
    @EnvironmentObject private var router: Router

    @State private var concecutiveTapsCancellable: AnyCancellable?

    var body: some View {
        NavigationStack(path: $path) {
            ProfileView(author: author)
                .navigationBarItems(leading: SideMenuButton())
                .navigationDestination(for: Author.self) { profile in
                    if profile == currentUser.author, currentUser.editing {
                        ProfileEditView(author: profile)
                    } else {
                        ProfileView(author: profile)
                    }
                }
                .task {
                    if concecutiveTapsCancellable == nil {
                        concecutiveTapsCancellable = router.consecutiveTaps(on: .profile)
                            .sink {
                                if router.profilePath.isEmpty {
                                    // This is a good place to scroll to the top
                                } else {
                                    router.profilePath.removeLast(router.profilePath.count)
                                }
                            }
                    }
                }
        }
    }
}

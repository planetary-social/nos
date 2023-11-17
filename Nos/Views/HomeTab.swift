//
//  HomeTab.swift
//  Nos
//
//  Created by Matthew Lorentz on 3/23/23.
//

import SwiftUI
import Dependencies

struct HomeTab: View {
    
    @ObservedObject var user: Author
    
    @Environment(Router.self) var router
    @Environment(CurrentUser.self) var currentUser
    
    var body: some View {
        @Bindable var router = router
        NavigationStack(path: $router.homeFeedPath) {
            HomeFeedView(user: user)
                .navigationDestination(for: Event.self) { note in
                    RepliesView(note: note)
                }
                .navigationDestination(for: Author.self) { author in
                    if router.currentPath.wrappedValue.count == 1 {
                        ProfileView(author: author)
                    } else {
                        if author == currentUser.author, currentUser.editing {
                            ProfileEditView(author: author)
                        } else {
                            ProfileView(author: author)
                        }
                    }
                }
                .navigationDestination(for: ReplyToNavigationDestination.self) { destination in
                    RepliesView(note: destination.note, showKeyboard: true)
                }
        }
    }
}

struct HomeTab_Previews: PreviewProvider {
    
    static var previewData = PreviewData()
    
    static var previews: some View {
        NavigationView {
            HomeFeedView(user: previewData.currentUser.author!)
                .inject(previewData: previewData)
        }
    }
}

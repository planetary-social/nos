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
    
    @State private var showStories = false
    @State private var storiesIconRotation: Angle = .zero
    
    @EnvironmentObject var router: Router
    @EnvironmentObject var currentUser: CurrentUser
    
    var body: some View {
        NavigationStack(path: $router.homeFeedPath) {
            VStack {
                if showStories {
                    StoriesView(user: user)
                } else {
                    HomeFeedView(user: user)
                }
            }
            .navigationBarItems(
                leading: SideMenuButton(),
                trailing: Button {
                    storiesIconRotation += .degrees(90)
                    withAnimation {
                        showStories.toggle()
                    }
                } label: {
                    Image.stories
                        .rotationEffect(storiesIconRotation)
                        .animation(
                            .interactiveSpring(),
                            value: storiesIconRotation
                        )
                }
            )
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

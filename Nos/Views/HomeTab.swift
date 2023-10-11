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
    @State private var storiesCutoffDate = Calendar.current.date(byAdding: .day, value: -2, to: .now)!
    
    @EnvironmentObject var router: Router
    @EnvironmentObject var currentUser: CurrentUser
    
    var body: some View {
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
            .navigationDestination(for: StoriesDestination.self) { stories in
                StoriesView(user: user, cutoffDate: $storiesCutoffDate, selectedAuthor: stories.author)
                    .navigationBarBackButtonHidden(true)
                    .navigationBarItems(
                        leading: SideMenuButton(),
                        trailing: Button {
                            var transaction = Transaction()
                            transaction.disablesAnimations = true
                            withTransaction(transaction) {
                                router.pop()
                            }
                        } label: {
                            Image.stories.rotationEffect(Angle(degrees: 90))
                        }
                    )
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

//
//  HomeTab.swift
//  Nos
//
//  Created by Matthew Lorentz on 3/23/23.
//

import SwiftUI

struct HomeTab: View {
    
    @ObservedObject var user: Author
    
    @State private var showStories = false
    @State private var storiesIconRotation: Angle = .zero
    
    @EnvironmentObject var router: Router
    
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
                    if author == CurrentUser.shared.author, CurrentUser.shared.editing {
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
    
    static var persistenceController = PersistenceController.preview
    static var previewContext = persistenceController.container.viewContext
    static var relayService = RelayService(persistenceController: persistenceController)
    
    static var emptyPersistenceController = PersistenceController.empty
    static var emptyPreviewContext = emptyPersistenceController.container.viewContext
    static var emptyRelayService = RelayService(persistenceController: emptyPersistenceController)
    
    static var router = Router()
    
    static var currentUser: CurrentUser = {
        let currentUser = CurrentUser()
        currentUser.context = previewContext
        currentUser.relayService = relayService
        currentUser.keyPair = KeyFixture.keyPair
        return currentUser
    }()
    
    static var previews: some View {
        NavigationView {
            HomeFeedView(user: currentUser.author!) .environment(\.managedObjectContext, previewContext) .environmentObject(relayService) .environmentObject(router) .environmentObject(currentUser)
        }
    }
}

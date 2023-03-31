//
//  ProfileView.swift
//  Nos
//
//  Created by Matthew Lorentz on 2/16/23.
//

import SwiftUI
import CoreData
import Dependencies

struct ProfileView: View {
    
    @ObservedObject var author: Author
    
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject private var relayService: RelayService
    @EnvironmentObject private var router: Router
    @Dependency(\.analytics) private var analytics
    
    @State private var showingOptions = false
    
    @State private var subscriptionIds: [String] = []
    
    @FetchRequest
    private var events: FetchedResults<Event>
    
    init(author: Author) {
        self.author = author
        _events = FetchRequest(fetchRequest: author.allPostsRequest())
    }
    
    func refreshProfileFeed() {
        // Close out stale requests
        if !subscriptionIds.isEmpty {
            relayService.sendCloseToAll(subscriptions: subscriptionIds)
            subscriptionIds.removeAll()
        }
        
        let authors = [author.hexadecimalPublicKey!]
        let textFilter = Filter(authorKeys: authors, kinds: [.text], limit: 100)
        let textSub = relayService.requestEventsFromAll(filter: textFilter)
        subscriptionIds.append(textSub)
        
        let metaFilter = Filter(
            authorKeys: authors,
            kinds: [.metaData],
            limit: 1,
            since: author.lastUpdatedMetadata
        )
        let metaSub = relayService.requestEventsFromAll(filter: metaFilter)
        subscriptionIds.append(metaSub)
       
        if let currentUser = CurrentUser.shared.author {
            let currentUserAuthorKeys = [currentUser.hexadecimalPublicKey!]
            let userLikesFilter = Filter(
                authorKeys: currentUserAuthorKeys,
                kinds: [.like],
                limit: 100
            )
            let userLikesSub = relayService.requestEventsFromAll(filter: userLikesFilter)
            subscriptionIds.append(userLikesSub)
        }
        
        let contactFilter = Filter(
            authorKeys: authors,
            kinds: [.contactList],
            limit: 1,
            since: author.lastUpdatedContactList
        )
        let contactSub = relayService.requestEventsFromAll(filter: contactFilter)
        subscriptionIds.append(contactSub)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            ScrollView(.vertical) {
                ProfileHeader(author: author)
                    .compositingGroup()
                    .shadow(color: .profileShadow, radius: 10, x: 0, y: 4)
                
                LazyVStack {
                    ForEach(events.unmuted) { event in
                        VStack {
                            NoteButton(note: event, hideOutOfNetwork: false)
                                .padding(.horizontal)
                        }
                    }
                }
            }
            .padding(.top, 1)
            .background(Color.appBg)
            .overlay(Group {
                if !events.contains(where: { !$0.author!.muted }) {
                    Localized.noEventsOnProfile.view
                        .padding()
                }
            })
        }
        .nosNavigationBar(title: .profile)
        .navigationDestination(for: Event.self) { note in
            RepliesView(note: note)
        }
        .navigationBarItems(
            trailing:
                Group {
                    Button(
                        action: {
                            showingOptions = true
                        },
                        label: {
                            Image(systemName: "ellipsis")
                        }
                    )
                    .confirmationDialog(Localized.share.string, isPresented: $showingOptions) {
                        Button(Localized.copyUserIdentifier.string) {
                            UIPasteboard.general.string = router.viewedAuthor?.publicKey?.npub ?? ""
                        }
                        Button(Localized.copyLink.string) {
                            UIPasteboard.general.string = router.viewedAuthor?.webLink ?? ""
                        }
                        if let author = router.viewedAuthor {
                            if author == CurrentUser.shared.author {
                                Button(
                                    action: {
                                        CurrentUser.shared.editing = true
                                        router.push(author)
                                    },
                                    label: {
                                        Text(Localized.editProfile.string)
                                    }
                                )
                            } else {
                                if author.muted {
                                    Button(Localized.unmuteUser.string) {
                                        Task {
                                            await router.viewedAuthor?.unmute(context: viewContext)
                                        }
                                    }
                                } else {
                                    Button(Localized.muteUser.string) {
                                        Task {
                                            await router.viewedAuthor?.mute(context: viewContext)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
        )
        .task {
            refreshProfileFeed()
        }
        .onAppear {
            router.viewedAuthor = author
            analytics.showedProfile()
        }
        .refreshable {
            refreshProfileFeed()
        }
        .onDisappear {
            relayService.sendCloseToAll(subscriptions: subscriptionIds)
            subscriptionIds.removeAll()
        }
    }
}

struct IdentityView_Previews: PreviewProvider {
    
    static var persistenceController = PersistenceController.preview
    static var previewContext = persistenceController.container.viewContext
    
    static var author: Author = {
        let author = try! Author.findOrCreate(
            by: "d0a1ffb8761b974cec4a3be8cbcb2e96a7090dcf465ffeac839aa4ca20c9a59e",
            context: previewContext
        )
        // TODO: derive from private key
        author.name = "Fred"
        author.about = "Reach for the stars. Someday you just might catch one."
        try! previewContext.save()
        return author
    }()
    
    static var previews: some View {
        NavigationStack {
            ProfileView(author: author)
        }
        .environment(\.managedObjectContext, previewContext)
    }
}

//
//  ProfileView.swift
//  Nos
//
//  Created by Matthew Lorentz on 2/16/23.
//

import SwiftUI
import CoreData

struct ProfileView: View {
    @EnvironmentObject private var router: Router
    
    @ObservedObject var author: Author
    
    @Environment(\.managedObjectContext) private var viewContext
    
    @EnvironmentObject private var relayService: RelayService
    
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

        if let currentUserPublicKey = CurrentUser.author?.hexadecimalPublicKey {
            let authors = [currentUserPublicKey]
            let textFilter = Filter(authorKeys: authors, kinds: [.text], limit: 100)
            let textSub = relayService.requestEventsFromAll(filter: textFilter)
            subscriptionIds.append(textSub)
            
            let metaFilter = Filter(authorKeys: authors, kinds: [.metaData], limit: 1)
            let metaSub = relayService.requestEventsFromAll(filter: metaFilter)
            subscriptionIds.append(metaSub)
            
            let contactFilter = Filter(authorKeys: authors, kinds: [.contactList], limit: 1)
            let contactSub = relayService.requestEventsFromAll(filter: contactFilter)
            subscriptionIds.append(contactSub)
        }
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
                            NoteButton(note: event)
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
        .navigationBarTitle(Localized.profile.rawValue, displayMode: .inline)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarBackground(Color.cardBgBottom, for: .navigationBar)
        .navigationDestination(for: Event.self) { note in
            RepliesView(note: note)
        }
        .navigationDestination(for: Author.self) { author in
            ProfileView(author: author)
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
                        if let author = router.viewedAuthor {
                            if author.muted {
                                Button(Localized.unmuteUser.string) {
                                    router.viewedAuthor?.unmute()
                                }
                            } else {
                                Button(Localized.muteUser.string) {
                                    router.viewedAuthor?.mute(context: viewContext)
                                }
                            }
                        }
                    }
                }
        )
        .onAppear {
            router.viewedAuthor = author
        }
        .task {
            refreshProfileFeed()
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

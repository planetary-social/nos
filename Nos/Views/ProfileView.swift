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
    @State private var showingReportMenu = false
    
    @State private var subscriptionIds: [String] = []
    
    @FetchRequest
    private var events: FetchedResults<Event>
    
    init(author: Author) {
        self.author = author
        _events = FetchRequest(fetchRequest: author.allPostsRequest())
    }
    
    func refreshProfileFeed() {
        Task(priority: .userInitiated) {
            // Close out stale requests
            if !subscriptionIds.isEmpty {
                await relayService.decrementSubscriptionCount(for: subscriptionIds)
                subscriptionIds.removeAll()
            }
            
            let authors = [author.hexadecimalPublicKey!]
            let textFilter = Filter(authorKeys: authors, kinds: [.text, .delete, .repost, .longFormContent], limit: 50)
            async let textSub = relayService.openSubscription(with: textFilter)
            
            let metaFilter = Filter(
                authorKeys: authors,
                kinds: [.metaData],
                since: author.lastUpdatedMetadata
            )
            async let metaSub = relayService.openSubscription(with: metaFilter)
            
            let contactFilter = Filter(
                authorKeys: authors,
                kinds: [.contactList],
                since: author.lastUpdatedContactList
            )
            async let contactSub = relayService.openSubscription(with: contactFilter)
            
            subscriptionIds.append(await textSub)
            subscriptionIds.append(await metaSub)
            subscriptionIds.append(await contactSub)
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
                            NoteButton(note: event, hideOutOfNetwork: false)
                                .padding(.bottom, 15)
                        }
                    }
                }
                .padding(.top, 10)
            }
            .background(Color.appBg)
            .overlay(Group {
                if !events.contains(where: { !$0.author!.muted }) {
                    Localized.noEventsOnProfile.view
                        .padding()
                }
            })
        }
        .nosNavigationBar(title: .profileTitle)
        .navigationDestination(for: Event.self) { note in
            RepliesView(note: note)
        }                  
        .navigationDestination(for: URL.self) { url in URLView(url: url) }
        .navigationDestination(for: ReplyToNavigationDestination.self) { destination in 
            RepliesView(note: destination.note, showKeyboard: true)
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
                                    Button(Localized.mute.string) {
                                        Task {
                                            await router.viewedAuthor?.mute(context: viewContext)
                                        }
                                    }
                                }
                                
                                Button(Localized.reportUser.string, role: .destructive) {
                                    showingReportMenu = true
                                }
                            }
                        }
                    }
                }
        )
        .reportMenu($showingReportMenu, reportedObject: .author(author))
        .task(priority: .userInitiated) {
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
            Task(priority: .userInitiated) {
                await relayService.decrementSubscriptionCount(for: subscriptionIds)
                subscriptionIds.removeAll()
            }
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
            ProfileView(author: PreviewData.previewAuthor)
        }
        .environment(\.managedObjectContext, PreviewData.previewContext)
        .environmentObject(PreviewData.relayService)
        .environmentObject(PreviewData.router)
        .environmentObject(PreviewData.currentUser)
    }
}

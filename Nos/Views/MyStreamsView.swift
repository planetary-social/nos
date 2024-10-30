import SwiftUI

struct MyStreamsView: View {
    
    var author: Author
    
    @EnvironmentObject private var router: Router
    @Environment(\.managedObjectContext) private var viewContext
    
    @FetchRequest<Hashtag>(
        entity: Hashtag.entity(), 
        sortDescriptors: [NSSortDescriptor(keyPath: \Hashtag.name, ascending: true)]
    ) private var hashtags
    
    @State private var showNewStreamView = false
    @State private var newStreamName = ""
    
    var body: some View {
        NosNavigationStack(path: $router.profilePath) { 
            ScrollView(.vertical) {
                ProfileHeader(author: author, selectedTab: .constant(.activity))
                LazyVStack(spacing: 8) {
                    ForEach(hashtags) { hashtag in
                        HorizontalStreamCarousel(streamName: hashtag.name!, showComposeButtonFor: author)
                    }
                }
            }
            .nosNavigationBar("My Streams")
            .navigationBarItems(leading: SideMenuButton())
            .background(Color.appBg)
            .padding(.top, 1)
            .navigationDestination(for: EditProfileDestination.self) { destination in
                ProfileEditView(author: destination.profile)
            }
            .toolbar { 
                ToolbarItem(placement: .topBarTrailing) { 
                    SecondaryActionButton("+ New") { 
                        showNewStreamView = true
                    }
                }
            }
            .overlay(content: { 
                VStack {
                    if showNewStreamView {
                        newStreamView
                    }
                }
                .transition(.fade(duration: 0.2))
                .animation(.easeInOut, value: showNewStreamView)
            })
        }
    }
    
    var newStreamView: some View { 
        VStack {
            VStack {
                Spacer()
                
                VStack {
                    VStack(spacing: 16) {
                        Text("New Stream")
                            .bold()
                            .font(.title2)
                        BeveledSeparator()
                        TextField("Stream Name", text: $newStreamName)
                            .padding(.bottom, 16)
                            .padding(.horizontal, 16)
                        HStack(spacing: 24) {
                            SecondaryActionButton("Cancel") {
                                newStreamName = ""
                                showNewStreamView = false
                            }
                            ActionButton("Create") { 
                                showNewStreamView = false
                                createStream()
                            }
                        }
                    }
                    .padding()
                }
                .background(LinearGradient.cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: 15))
                .mimicCardButtonStyle()
                
                Spacer()
            }
            .readabilityPadding()
            .padding()
        }
        .background(Color.white.opacity(0.3).ignoresSafeArea())
    }
    
    func createStream() {
        let newStream = try! Hashtag.findOrCreate(by: newStreamName, context: viewContext)
        try! viewContext.saveIfNeeded()
        newStreamName = ""
    }
}

#Preview {
    var previewData = PreviewData()
    
    func createTestData() {
        let user = previewData.alice
        let addresses = Relay.recommended
        addresses.forEach { address in
            let relay = try? Relay.findOrCreate(by: address, context: previewData.previewContext)
            relay?.relayDescription = "A Nostr relay that aims to cultivate a healthy community."
            relay?.addToAuthors(user)
        }
        
        Task { try await previewData.currentUser.follow(author: previewData.bob) }
        
        _ = previewData.streamImageOne
        _ = previewData.streamImageTwo
        _ = previewData.streamImageThree
    }
    
    return MyStreamsView(author: previewData.previewAuthor)
        .inject(previewData: previewData)
        .onAppear { createTestData() }
}

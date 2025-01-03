import SwiftUI
import Dependencies

/// A view that details some interaction (reply, like, follow, etc.) with one of your notes.
struct NotificationCard: View {
    
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject private var router: Router
    @Environment(RelayService.self) private var relayService
    @Dependency(\.persistenceController) private var persistenceController
    
    let viewModel: NotificationViewModel
    @State private var relaySubscriptions = SubscriptionCancellables()
    @State private var content: AttributedString?
    
    func showNote() {
        guard let note = Event.find(by: viewModel.noteID, context: viewContext) else {
            return 
        }
        router.push(note.referencedNote() ?? note)
    }
    
    var body: some View {
        Button {
            showNote()
        } label: {
            HStack {
                AvatarView(imageUrl: viewModel.authorProfilePhotoURL, size: 40)
                    .shadow(radius: 10, y: 4)
                
                VStack {
                    HStack {
                        Text(viewModel.actionText)
                            .lineLimit(2)
                        Spacer()
                    }
                    if let content, !content.characters.isEmpty {
                        HStack {
                            let contentText = Text(content.wrappingWithQuotationMarks())
                                .lineLimit(2)
                                .font(.body)
                                .foregroundColor(.primaryTxt)
                                .tint(.accent)
                                .handleURLsInRouter()
                            
                            if viewModel.content == nil {
                                contentText.redacted(reason: .placeholder)
                            } else {
                                contentText
                            }
                            Spacer()
                        }
                    }
                }
                .frame(maxWidth: .infinity)
                
                VStack {
                    Spacer()
                    Text(viewModel.date.distanceString())
                        .lineLimit(1)
                        .font(.clarity(.regular))
                        .foregroundColor(.secondaryTxt)
                }
                .fixedSize()
            }
            .padding(10)
            .background(
                LinearGradient(
                    colors: [Color.cardBgTop, Color.cardBgBottom],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .cornerRadius(20)
        }
        .buttonStyle(CardButtonStyle(style: .compact))
        .onAppear {
            Task(priority: .userInitiated) {
                let backgroundContext = persistenceController.backgroundViewContext
                await relaySubscriptions.append(Event.requestAuthorsMetadataIfNeeded(
                    noteID: viewModel.id,
                    using: relayService,
                    in: backgroundContext
                ))
            }
        }
        .onDisappear { relaySubscriptions.removeAll() }
        .task(priority: .userInitiated) {
            self.content = await viewModel.loadContent(in: persistenceController.viewContext)
        }
    }
}

#Preview {
    var previewData = PreviewData()
    
    let previewContext = previewData.previewContext
    
    var alice: Author {
        previewData.alice
    }
    
    var bob: Author {
        previewData.bob
    }
    
    let note: Event = {
        let mentionNote = Event(context: previewContext)
        mentionNote.content = "Hello, bob!"
        mentionNote.kind = 1
        mentionNote.createdAt = .now
        mentionNote.author = alice
        let authorRef = AuthorReference(context: previewContext)
        authorRef.pubkey = bob.hexadecimalPublicKey
        mentionNote.authorReferences = NSMutableOrderedSet(array: [authorRef])
        try? mentionNote.sign(withKey: KeyFixture.alice)
        try? previewContext.save()
        return mentionNote
    }()
        
    return VStack {
        Spacer()
        NotificationCard(viewModel: NotificationViewModel(note: note, user: bob))
        Spacer()
    }
    .inject(previewData: previewData)
}

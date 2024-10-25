import SwiftUI
import Dependencies

struct MostRecentPostView: View {
    
    let author: Author
    
    @Environment(\.managedObjectContext) private var viewContext
    @Dependency(\.relayService) private var relayService
    
    @FetchRequest private var posts: FetchedResults<Event>
    @State var subscriptionCancellables = [SubscriptionCancellable]()
    
    init(author: Author) {
        self.author = author
        self._posts = FetchRequest(fetchRequest: Event.mostRecentPosts(from: author))
    }
    
    var body: some View {
        VStack {
            ForEach(posts) { post in 
                NoteButton(note: post)
            }
        }
        .onAppear {
            guard let authorKey = author.hexadecimalPublicKey else {
                return
            }
            Task {
                let filter = Filter(authorKeys: [authorKey], kinds: [.text], limit: 1)
                let cancellable = await relayService.fetchEvents(matching: filter)
                subscriptionCancellables.append(cancellable)
            }
        }
    }
}

#Preview {
    var previewData = PreviewData()
    
    return MostRecentPostView(author: previewData.previewAuthor)
        .inject(previewData: previewData)
        .onAppear { 
            _ = previewData.shortNote
        }
}

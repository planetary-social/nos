import SwiftUI

struct AddFriendView: View {
    
    @Environment(CurrentUser.self) private var currentUser
    @Environment(\.managedObjectContext) private var viewContext
    
    let user: Author
    
    @FetchRequest private var friends: FetchedResults<Author>
    
    @State var friendID: String = ""
    
    init(user: Author) {
        self.user = user
        self._friends = FetchRequest(fetchRequest: Author.followed(by: user))
    }
    
    var body: some View {
        ScrollView {
            Text("Your ID is \(currentUser.keyPair?.npub ?? "error").")
            Text("Enter a friend's ID to add them:")
            TextField("ID:", text: $friendID)
                .border(Color.white)
            Button("Add Friend") { 
                addFriendPressed()
            }
            Text("Friends:")
            ForEach(friends) { friend in 
                AuthorCard(author: friend)
            }
        }
    }
    
    func addFriendPressed() {
        do {
            if case let .npub(friendPubKey) = try NostrIdentifier.decode(bech32String: friendID) {
                let author = try Author.findOrCreate(by: friendPubKey, context: viewContext)
                Task { 
                    try await currentUser.follow(author: author)
                    try viewContext.saveIfNeeded()
                }
            }
        } catch {
            // TODO:
        }
    }
}

#Preview {
    var previewData = PreviewData()
    
    return AddFriendView(user: previewData.alice)
        .inject(previewData: previewData)
}

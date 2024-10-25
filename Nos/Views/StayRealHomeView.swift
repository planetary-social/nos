import SwiftUI

struct StayRealHomeView: View {
    
    @EnvironmentObject private var router: Router
    @Environment(\.managedObjectContext) private var viewContext
    
    let user: Author
    
    @FetchRequest private var friends: FetchedResults<Author>
    
    init(user: Author) {
        self.user = user
        self._friends = FetchRequest(fetchRequest: Author.followed(by: user))
    }
    
    var body: some View {
        NavigationStack(path: $router.homeFeedPath) { 
            ScrollView {
                VStack {
                    ForEach(friends) { friend in 
                        MostRecentPostView(author: friend)
                    }
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Add friend") { 
                        router.push(AppDestination.addFriend)
                    }
                }
            }
            .navigationDestination(for: AppDestination.self) { destination in
                switch destination {
                case .addFriend:
                    AddFriendView(user: user)
                default:
                    Text("error")
                }
            }
        }
    }
}

#Preview {
    var previewData = PreviewData()
    
    return StayRealHomeView(user: previewData.alice)
        .inject(previewData: previewData)
}

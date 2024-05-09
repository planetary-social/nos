import SwiftUI
import Dependencies

struct HomeTab: View {
    
    @ObservedObject var user: Author
    
    @EnvironmentObject private var router: Router
    @Environment(CurrentUser.self) var currentUser
    
    var body: some View {
        NavigationStack(path: $router.homeFeedPath) {
            HomeFeedView(user: user)
                .navigationDestination(for: Event.self) { note in
                    RepliesView(note: note)
                }
                .navigationDestination(for: Author.self) { author in
                    ProfileView(author: author)
                }
                .navigationDestination(for: EditProfileDestination.self) { destination in
                    ProfileEditView(author: destination.profile)
                }
                .navigationDestination(for: ReplyToNavigationDestination.self) { destination in
                    RepliesView(note: destination.note, showKeyboard: true)
                }
                .navigationDestination(for: URL.self) { url in URLView(url: url) }
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

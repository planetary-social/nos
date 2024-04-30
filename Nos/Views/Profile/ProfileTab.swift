import Combine
import SwiftUI

/// A version of the ProfileView that is displayed in the main tab bar
struct ProfileTab: View {
    
    @Environment(CurrentUser.self) var currentUser
    @ObservedObject var author: Author
    
    @Binding var path: NavigationPath

    var body: some View {
        NavigationStack(path: $path) {
            ProfileView(author: author, addDoubleTapToPop: true)
                .navigationBarItems(leading: SideMenuButton())
                .navigationDestination(for: Author.self) { profile in
                    ProfileView(author: profile)
                }
                .navigationDestination(for: EditProfileDestination.self) { destination in
                    ProfileEditView(author: destination.profile)
                }
        }
    }
}

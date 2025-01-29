import Combine
import SwiftUI

/// A version of the ProfileView that is displayed in the main tab bar
struct ProfileTab: View {
    
    @Environment(CurrentUser.self) var currentUser
    var author: Author
    
    @Binding var path: NavigationPath

    var body: some View {
        NosNavigationStack(path: $path) {
            ProfileView(author: author, addDoubleTapToPop: true)
                .navigationBarItems(leading: SideMenuButton())
        }
    }
}

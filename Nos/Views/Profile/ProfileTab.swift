import Combine
import SwiftUI
import Dependencies

/// A version of the ProfileView that is displayed in the main tab bar
struct ProfileTab: View {
    
    @Environment(CurrentUser.self) var currentUser
    @EnvironmentObject private var router: Router
    @Dependency(\.analytics) private var analytics
    @ObservedObject var author: Author

    var body: some View {
        NosNavigationStack(path: $router.profilePath) {
            ProfileView(author: author, addDoubleTapToPop: true)
                .navigationBarItems(leading: SideMenuButton())
                .onTabAppear(.profile) {
                    analytics.showedProfileTab()
                }
        }
    }
}

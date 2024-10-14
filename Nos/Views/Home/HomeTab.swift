import Dependencies
import SwiftUI

struct HomeTab: View {

    @ObservedObject var user: Author

    @EnvironmentObject private var router: Router

    var body: some View {
        NosNavigationStack(path: $router.homeFeedPath) {
            HomeFeedView(user: user)
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

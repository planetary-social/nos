import SwiftUI

struct MutesDestination: Hashable { }

struct MutesView: View {
    @FetchRequest
    private var authors: FetchedResults<Author>

    init() {
        _authors = FetchRequest(fetchRequest: Author.allAuthorsRequest(muted: true))
    }

    var body: some View {
        ScrollView(.vertical) {
            LazyVStack {
                ForEach(authors) { author in
                    CompactAuthorCard(author: author)
                        .padding(.horizontal)
                        .readabilityPadding()
                }
            }
            .padding(.top)
        }
        .background(Color.appBg)
        .nosNavigationBar("mutedUsers")
    }
}

struct MutesView_Previews: PreviewProvider {
    static var previews: some View {
        MutesView()
    }
}

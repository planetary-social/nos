import Foundation
import SwiftUI

struct AuthorListView: View {
    
    @Binding var isPresented: Bool
    
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(CurrentUser.self) private var currentUser

    @StateObject private var searchController = SearchController(searchOrigin: .mentions)

    @FocusState private var isSearching: Bool
    @State private var filteredAuthors: [Author] = []

    /// The authors who replied under the note the user is replying if any.
    var threadAuthors: [Author]?

    var didSelectGesture: ((Author) -> Void)?

    var body: some View {
        ScrollView(.vertical) {
            SearchBar(text: $searchController.query, isSearching: $isSearching)
                .readabilityPadding()
                .padding(.top, 10)
                .onSubmit {
                    searchController.submitSearch(query: searchController.query)
                }
            LazyVStack {
                ForEach(filteredAuthors) { author in
                    AuthorCard(author: author, showsFollowButton: false) {
                        didSelectGesture?(author)
                    }
                    .padding(.horizontal, 13)
                    .padding(.top, 5)
                    .readabilityPadding()
                }
            }
        }
        .background(Color.appBg)
        .nosNavigationBar(title: .localizable.mention)
        .onAppear {
            isSearching = true

            guard let threadAuthors = threadAuthors else { return }
            filteredAuthors += threadAuthors
        }
        .onChange(of: searchController.authorResults) { _, newValue in
            filteredAuthors = []

            guard let currentAuthor = currentUser.author else { return }
            let sortedAuthors = newValue.sortByMutualFollowees(with: currentAuthor)
            filteredAuthors += sortedAuthors

            guard let threadAuthors = threadAuthors else { return }
            filteredAuthors += threadAuthors
        }
        .disableAutocorrection(true)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button(action: {
                    isPresented = false
                }, label: {
                    Text(.localizable.cancel)
                        .foregroundColor(.primaryTxt)
                })
            }
        }
    }
}

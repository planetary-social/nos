import Foundation
import SwiftUI

struct AuthorListView: View {
    
    @Binding var isPresented: Bool
    
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(CurrentUser.self) private var currentUser

    @StateObject private var searchController = SearchController(searchOrigin: .mentions)

    @FocusState private var isSearching: Bool
    @State private var filteredAuthors: [Author] = []

    /// The authors are referenced in a note / who replied under the note the user is replying if any.
    var relatedAuthors: [Author]?

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

            guard let relatedAuthors = relatedAuthors else { return }
            filteredAuthors = relatedAuthors
        }
        .onChange(of: searchController.authorResults) { _, newValue in
            filteredAuthors = []

            guard let currentAuthor = currentUser.author else {
                filteredAuthors = newValue
                return
            }
            let sortedAuthors = newValue.sortedByMutualFollowees(with: currentAuthor)
            filteredAuthors += sortedAuthors

            guard let relatedAuthors = relatedAuthors else { return }
            filteredAuthors += relatedAuthors
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

import Foundation
import SwiftUI

struct AuthorListView: View {
    
    @Binding var isPresented: Bool
    
    @Environment(\.managedObjectContext) private var viewContext

    @State private var authors: [Author]?

    @State private var filteredAuthors: [Author]?

    @StateObject private var searchController = SearchController()

    @FocusState private var isSearching: Bool

    var didSelectGesture: ((Author) -> Void)?

    var body: some View {
        ScrollView(.vertical) {
            SearchBar(text: $searchController.query, isSearching: $isSearching)
                .readabilityPadding()
                .padding(.top, 10)
            LazyVStack {
                if let authors = filteredAuthors {
                    ForEach(authors) { author in
                        AuthorCard(author: author, showsFollowButton: false) {
                            didSelectGesture?(author)
                        }
                        .padding(.horizontal, 13)
                        .padding(.top, 5)
                        .readabilityPadding()
                    }
                } else {
                    ProgressView()
                }
            }
        }
        .background(Color.appBg)
        .nosNavigationBar(title: .localizable.mention)
        .onChange(of: searchController.query) { _, newValue in
            search(for: newValue)
        }
        .onAppear {
            isSearching = true
        }
        .disableAutocorrection(true)
        .task {
            refreshAuthors()
        }
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

    private func refreshAuthors() {
        let request = Author.allAuthorsWithNameOrDisplayNameRequest(muted: false)
        authors = try? viewContext.fetch(request)
        search(for: searchController.query)
    }

    private func search(for query: String) {
        guard !query.isEmpty else {
            filteredAuthors = authors
            return
        }

        /// Search the relays for query.
        searchController.submitSearch(query: query)

        let lowercasedQuery = query.lowercased()
        filteredAuthors = searchController.authorResults.filter { author in
            if author.name?.lowercased().contains(lowercasedQuery) == true {
                return true
            }
            if author.displayName?.lowercased().contains(lowercasedQuery) == true {
                return true
            }
            if author.hexadecimalPublicKey?.lowercased().contains(lowercasedQuery) == true {
                return true
            }
            return false
        }
    }
}

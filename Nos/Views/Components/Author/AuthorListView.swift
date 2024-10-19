import Foundation
import SwiftUI

struct AuthorListView: View {
    
    @Binding var isPresented: Bool
    
    @Environment(\.managedObjectContext) private var viewContext

    @State private var searchController = SearchController(searchOrigin: .mentions)

    @FocusState private var isSearching: Bool

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
                ForEach(searchController.authorResults) { author in
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

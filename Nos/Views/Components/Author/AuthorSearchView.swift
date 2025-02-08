import Foundation
import SwiftUI

struct AuthorSearchView<EmptyPlaceholder: View>: View {
    
    @Environment(\.dismiss) private var dismiss
    
    @Environment(\.managedObjectContext) private var viewContext

    @State private var searchController: SearchController

    @FocusState private var isSearching: Bool
    @State private var filteredAuthors: [Author] = []
    
    let title: LocalizedStringKey?
    let isModal: Bool
    let avatarOverlayMode: AvatarOverlayMode
    
    /// The view to show when the search bar is empty.
    let emptyPlaceholder: () -> EmptyPlaceholder?
    
    /// The authors are referenced in a note / who replied under the note the user is replying if any.
    let relatedAuthors: [Author]?

    let didSelectGesture: ((Author) -> Void)?

    init(
        searchOrigin: SearchOrigin,
        title: LocalizedStringKey? = nil,
        isModal: Bool,
        avatarOverlayMode: AvatarOverlayMode = .follows,
        relatedAuthors: [Author]? = nil,
        routesMatchesAutomatically: Bool = true,
        @ViewBuilder emptyPlaceholder: @escaping () -> EmptyPlaceholder? = { nil },
        didSelectGesture: ((Author) -> Void)? = nil
    ) {
        self.title = title
        self.isModal = isModal
        self.avatarOverlayMode = avatarOverlayMode
        self.relatedAuthors = relatedAuthors
        self.didSelectGesture = didSelectGesture
        self.emptyPlaceholder = emptyPlaceholder
        _searchController = State(
            initialValue: SearchController(
                searchOrigin: searchOrigin,
                routesMatchesAutomatically: routesMatchesAutomatically
            )
        )
    }
    
    var body: some View {
        ScrollView(.vertical) {
            SearchBar(text: $searchController.query, isSearching: $isSearching)
                .readabilityPadding()
                .padding(.top, 10)
                .onSubmit {
                    searchController.submitSearch(query: searchController.query)
                }
            
            if filteredAuthors.isEmpty {
                emptyPlaceholder()
            } else {
                LazyVStack {
                    ForEach(filteredAuthors) { author in
                        row(forAuthor: author)
                    }
                }
            }
        }
        .background(Color.appBg)
        .nosNavigationBar(title ?? "")
        .onAppear {
            isSearching = true

            guard let relatedAuthors = relatedAuthors else { return }
            filteredAuthors = relatedAuthors
        }
        .onChange(of: searchController.authorResults) { _, newValue in
            // Empty the array, so the search result can be at the top of the related authors.
            filteredAuthors = []
            // Add search result first.
            filteredAuthors += newValue
            // Add related authors to the end of the search result.
            guard let relatedAuthors = relatedAuthors else { return }
            filteredAuthors += relatedAuthors
        }
        .disableAutocorrection(true)
        .toolbar {
            if isModal {
                ToolbarItem(placement: .cancellationAction) {
                    Button(action: {
                        dismiss()
                    }, label: {
                        Text("cancel")
                            .foregroundColor(.primaryTxt)
                    })
                }
            }
        }
    }
    
    private func row(forAuthor author: Author) -> some View {
        AuthorCard(
            author: author,
            avatarOverlayView: {
                switch avatarOverlayMode {
                case .follows:
                    AnyView(CircularFollowButton(author: author))
                case .alwaysSelected:
                    AnyView(UserSelectionCircle(diameter: 30, selected: true))
                case .inSet(let authors):
                    AnyView(UserSelectionCircle(diameter: 30, selected: authors.contains(author)))
                }
            },
            onTap: {
                didSelectGesture?(author)
            }
        )
        .padding(.horizontal, 13)
        .padding(.top, 5)
        .readabilityPadding()
    }
}

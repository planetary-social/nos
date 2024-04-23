import SwiftUI

struct DiscoverGrid: View {
    
    @EnvironmentObject private var router: Router
    @FetchRequest(fetchRequest: Event.emptyDiscoverRequest()) var events: FetchedResults<Event>
    @FetchRequest(fetchRequest: Author.fetchRequest()) var authors: FetchedResults<Author>
    @ObservedObject var searchController: SearchController
    
    @Binding var columns: Int
    @State private var gridSize: CGSize = .zero {
        didSet {
            // Initialize columns based on width of the grid
            if columns == 0, gridSize.width > 0 {
                columns = Int(floor(gridSize.width / 172))
            }
        }
    }
    
    @Namespace private var animation

    init(featuredAuthors: [String], predicate: NSPredicate, searchController: SearchController, columns: Binding<Int>) {
        let authorPublicKeys = featuredAuthors.compactMap { PublicKey(npub: $0)?.hex }
        _authors = FetchRequest(fetchRequest: Author.authors(in: authorPublicKeys))
        let fetchRequest = Event.emptyDiscoverRequest()
        fetchRequest.predicate = predicate
        fetchRequest.fetchLimit = 1000
        _events = FetchRequest(fetchRequest: fetchRequest)
        _columns = columns
        self.searchController = searchController
    }
    
    var body: some View {
        VStack {
            GeometryReader { geometry in
                Group {
                    switch searchController.state {
                    case .noQuery:
                        ScrollView {
                            LazyVStack {
                                ForEach(authors) { author in
                                    AuthorCard(author: author, showsFollowButton: false) {
//                                        didSelectGesture?(author)
                                    }
                                    .padding(.horizontal, 13)
                                    .padding(.top, 5)
                                    .readabilityPadding()
                                }
                            }
                        }
                        .doubleTapToPop(tab: .discover) { proxy in
                            if let firstNote = events.first {
                                proxy.scrollTo(firstNote.id)
                            }
                        }
                    case .empty:
                        EmptyView()
                    case .loading, .stillLoading:
                        FullscreenProgressView(
                            isPresented: .constant(true),
                            text: searchController.state == .stillLoading ?
                            String(localized: .localizable.notFindingResults) : nil
                        )
                    case .results:
                        ScrollView {
                            LazyVStack {
                                ForEach(searchController.authorResults) { author in
                                    AuthorCard(author: author) {
                                        router.push(author)
                                    }
                                    .padding(.horizontal, 15)
                                    .padding(.top, 10)
                                    .readabilityPadding()
                                }
                            }
                            .padding(.top, 5)
                        }
                        .doubleTapToPop(tab: .discover) { proxy in
                            if let firstAuthor = searchController.authorResults.first {
                                proxy.scrollTo(firstAuthor.id)
                            }
                        }
                    }
                }
                .preference(key: SizePreferenceKey.self, value: geometry.size)
            }
            .onPreferenceChange(SizePreferenceKey.self) { preference in
                gridSize = preference
            }
        }
    }
}

import SwiftUI
import Dependencies

struct DiscoverGrid: View {
    
    @EnvironmentObject private var router: Router
    @FetchRequest(fetchRequest: Event.emptyDiscoverRequest()) var events: FetchedResults<Event>
    @FetchRequest(fetchRequest: Author.fetchRequest()) var authors: FetchedResults<Author>
    @ObservedObject var searchController: SearchController
    @Dependency(\.relayService) private var relayService

    // TODO: What's a better way to do this?
    @State private var subscriptions = [ObjectIdentifier: SubscriptionCancellable]()

    @State private var pickerSelection = DiscoverTab.FeaturedAuthorCategory.all

    var filteredAuthors: [Author] {
        if pickerSelection == .all {
            return Array(authors)
        }
        return authors.filter {
            guard let npub = $0.npubString else {
                return false
            }
            guard let categories = DiscoverTab.featuredAuthorNpubs[npub] else {
                return false
            }
            return categories.contains(pickerSelection)
        }
    }

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
        let authorsRequest = Author.request(matchingNpubs: featuredAuthors)
        authorsRequest.fetchLimit = 1000
        _authors = FetchRequest(fetchRequest: authorsRequest)

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
                                ScrollView(.horizontal) {
                                    HStack(spacing: 2) {
                                        ForEach(DiscoverTab.FeaturedAuthorCategory.allValues, id: \.self) { category in
                                            Button(action: {
                                                pickerSelection = category
                                            }, label: {
                                                Text(category.text)
                                                    .font(.footnote)
                                                    .padding(.vertical, 4)
                                                    .padding(.horizontal, 8)
                                                    .background(
                                                        pickerSelection == category ?
                                                        Color.pickerBackgroundSelected :
                                                        Color.clear
                                                    )
                                                    .foregroundColor(
                                                        pickerSelection == category ?
                                                        Color.primaryTxt :
                                                        Color.secondaryTxt
                                                    )
                                                    .cornerRadius(20)
                                                    .padding(4)
                                            })
                                        }
                                    }
                                    .padding(.leading, 10)
                                }
                                .scrollIndicatorsFlash(onAppear: true)
                                .background(Color.profileBgTop)

                                ForEach(filteredAuthors) { author in
                                    AuthorCard(author: author) {
                                        router.push(author)
                                    }
                                    .padding(.horizontal, 13)
                                    .padding(.top, 5)
                                    .readabilityPadding()
                                    .task {
                                        // TODO: optimize. Probably only needed once per author.
                                        subscriptions[author.id] =
                                            await relayService.requestMetadata(
                                                for: author.hexadecimalPublicKey,
                                                since: author.lastUpdatedMetadata
                                            )
                                    }
                                }
                            }
                            .padding(.bottom, 12)
                        }
                        .doubleTapToPop(tab: .discover) { proxy in
                            if let firstAuthor = authors.first {
                                proxy.scrollTo(firstAuthor.id)
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

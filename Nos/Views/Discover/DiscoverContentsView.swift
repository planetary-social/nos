import Logger
import SwiftUI
import Dependencies

struct DiscoverContentsView: View {
    @ObservedObject var searchController: SearchController

    @EnvironmentObject private var router: Router

    @Environment(\.managedObjectContext) private var viewContext

    @Dependency(\.relayService) private var relayService
    @Dependency(\.crashReporting) private var crashReporting
    @Dependency(\.analytics) private var analytics

    /// The IDs of the authors we will display when we aren't searching.
    @State private var featuredAuthorIDs = [RawAuthorID]()
    @State private var subscriptions = [ObjectIdentifier: SubscriptionCancellable]()
    @State private var selectedCategory: FeaturedAuthorCategory = .all
    
    @State private var featuredAuthorsPerformingInitialLoad = true
    let featuredAuthorsInitialLoadTime = 1

    /// Initializes a DiscoverContentsView with the selected category and a search controller.
    /// - Parameters:
    ///   - featuredAuthorCategory: The initial category of featured authors to display until
    ///   the user changes the selection. Defaults to `.all` to show all featured authors.
    ///   - searchController: The search controller to use for searching.
    init(featuredAuthorCategory: FeaturedAuthorCategory = .all, searchController: SearchController) {
        self.searchController = searchController
        self.selectedCategory = featuredAuthorCategory
    }
    
    var body: some View {
        VStack {
            GeometryReader { geometry in
                Group {
                    switch searchController.state {
                    case .noQuery:
                        featuredAuthorsView
                    case .empty:
                        EmptyView()
                    case .loading, .stillLoading:
                        FullscreenProgressView(
                            isPresented: .constant(true),
                            text: searchController.state == .stillLoading ?
                            String(localized: "notFindingResults") : nil
                        )
                    case .results:
                        ScrollView {
                            LazyVStack {
                                ForEach(searchController.authorResults) { author in
                                    AuthorCard(author: author) {
                                        let resultsCount = searchController.authorResults.count
                                        analytics.displayedAuthorFromDiscoverSearch(
                                            resultsCount: resultsCount
                                        )
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
                                proxy.scrollTo(firstAuthor.id, anchor: .bottom)
                            }
                        }
                    }
                }
                .preference(key: SizePreferenceKey.self, value: geometry.size)
            }
        }
    }
    
    var featuredAuthorsView: some View {
        ZStack {
            ScrollView {
                LazyVStack {
                    categoryPicker
                    
                    ForEach(featuredAuthorIDs) { authorID in
                        AuthorObservationView(authorID: authorID) { author in
                            VStack {
                                if author.lastUpdatedMetadata != nil {
                                    AuthorCard(author: author) {
                                        router.push(author)
                                    }
                                    .padding(.horizontal, 13)
                                    .padding(.top, 5)
                                    .readabilityPadding()
                                }
                            }
                            .task {
                                subscriptions[author.id] =
                                await relayService.requestMetadata(
                                    for: author.hexadecimalPublicKey,
                                    since: author.lastUpdatedMetadata
                                )
                            }
                        }
                    }
                }
                .padding(.bottom, 16)
            }
            .doubleTapToPop(tab: .discover) { proxy in
                if let firstAuthorID = featuredAuthorIDs.first {
                    proxy.scrollTo(firstAuthorID, anchor: .bottom)
                }
            }
            
            if featuredAuthorsPerformingInitialLoad {
                FullscreenProgressView(
                    isPresented: $featuredAuthorsPerformingInitialLoad, 
                    hideAfter: .now() + .seconds(featuredAuthorsInitialLoadTime)
                )
                .onAppear {
                    updateDisplayedFeaturedAuthors()
                }
            }
        }
    }

    var categoryPicker: some View {
        ViewThatFits {
            categoriesStack

            ScrollView(.horizontal) {
                categoriesStack
            }
            .scrollIndicators(.never)
        }
        .background(Color.cardBgBottom)
    }

    var categoriesStack: some View {
        HStack(spacing: 2) {
            Spacer()
            ForEach(FeaturedAuthorCategory.allCases, id: \.self) { category in
                Button(action: {
                    selectedCategory = category
                }, label: {
                    Text(category.text)
                        .font(.callout)
                        .padding(.vertical, 4)
                        .padding(.horizontal, 8)
                        .background(
                            selectedCategory == category ?
                            Color.pickerBackgroundSelected :
                                Color.clear
                        )
                        .foregroundColor(
                            selectedCategory == category ?
                            Color.primaryTxt :
                                Color.secondaryTxt
                        )
                        .cornerRadius(20)
                        .padding(4)
                        .frame(minWidth: 44, minHeight: 44)
                })
                .onChange(of: selectedCategory) { _, _ in
                    updateDisplayedFeaturedAuthors()
                }
            }
            Spacer()
        }
        .padding(.leading, 10)
    }

    private func updateDisplayedFeaturedAuthors() {
        do {
            try selectedCategory.rawIDs.forEach { authorID in
                _ = try Author.findOrCreate(by: authorID, context: viewContext)
            }
            self.featuredAuthorIDs = selectedCategory.rawIDs
        } catch {
            crashReporting.report("Failed to create Discover tab authors \(error.localizedDescription)")
            Log.optional(error, "Failed to create Discover tab authors")
        }
    }
}

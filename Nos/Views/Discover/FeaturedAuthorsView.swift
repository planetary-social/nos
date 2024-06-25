import Logger
import SwiftUI
import Dependencies

struct FeaturedAuthorsView: View {
    @ObservedObject var searchController: SearchController

    @EnvironmentObject private var router: Router

    @Environment(\.managedObjectContext) private var viewContext

    @Dependency(\.relayService) private var relayService

    @FetchRequest(fetchRequest: Author.matching(npubs: FeaturedAuthorCategory.all.npubs)) private var authors

    @State private var subscriptions = [ObjectIdentifier: SubscriptionCancellable]()
    @State private var selectedCategory: FeaturedAuthorCategory = .all

    private var sortedAuthors: [Author] {
        authors.sorted { authorA, authorB in
            let allFeatured = FeaturedAuthor.all
            guard let indexA = allFeatured.firstIndex(where: { $0.npub == authorA.npubString }),
                let indexB = allFeatured.firstIndex(where: { $0.npub == authorB.npubString }) else {
                return false
            }
            return indexA < indexB
        }
    }

    private var filteredAuthors: [Author] {
        sortedAuthors.filter { author in
            guard let npubString = author.npubString else { return false }
            return selectedCategory.npubs.contains(npubString)
        }
    }

    /// Initializes a FeaturedAuthorsView with the selected category and a search controller.
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
                        ScrollView {
                            LazyVStack {
                                categoryPicker

                                ForEach(filteredAuthors) { author in
                                    AuthorCard(author: author) {
                                        router.push(author)
                                    }
                                    .padding(.horizontal, 13)
                                    .padding(.top, 5)
                                    .readabilityPadding()
                                    .task {
                                        subscriptions[author.id] =
                                            await relayService.requestMetadata(
                                                for: author.hexadecimalPublicKey,
                                                since: author.lastUpdatedMetadata
                                            )
                                    }
                                }
                            }
                            .padding(.bottom, 16)
                        }
                        .doubleTapToPop(tab: .discover) { proxy in
                            if let firstAuthor = sortedAuthors.first {
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
        }
        .task {
            findOrCreateAuthors()
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
        .background(Color.profileBgTop)
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
            }
            Spacer()
        }
        .padding(.leading, 10)
    }

    private func findOrCreateAuthors() {
        for featuredAuthorNpub in FeaturedAuthorCategory.all.npubs {
            do {
                guard let publicKey = PublicKey(npub: featuredAuthorNpub) else {
                    assertionFailure(
                        "Could create public key for npub: \(featuredAuthorNpub)\n" +
                        "Fix this invalid npub in FeaturedAuthorCategory."
                    )
                    continue
                }
                try Author.findOrCreate(by: publicKey.hex, context: viewContext)
            } catch {
                Log.error("Could not find or create author for npub: \(featuredAuthorNpub)")
            }
        }
        try? viewContext.saveIfNeeded()
    }
}

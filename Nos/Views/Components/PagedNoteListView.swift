import SwiftUI
import CoreData
import Dependencies
import Logger

/// The PagedNoteListView is designed to display an infinite list of notes in reverse-chronological order.
/// It takes two filters: one to load events from our local database (Core Data) and one to load them from the 
/// relays. As the user scrolls down we will keep adjusting the relay filter to get older events.
/// 
/// Under the hood PagedNoteListView is using UICollectionView and NSFetchedResultsController. We leverage the
/// UICollectionViewDataSourcePrefetching protocol to call Event.loadViewData() on events in advanced of them being 
/// shown, which allows us to perform expensive tasks like downloading images, calculating attributed text, fetching
/// author metadata and linked notes, etc. before the view is displayed.
struct PagedNoteListView<Header: View, EmptyPlaceholder: View>: UIViewRepresentable {

    /// Set the UIViewType to make the compiler happy as we implement `dismantleUIView`.
    typealias UIViewType = UICollectionView

    /// Allows us to refresh the PagedNoteListView from outside this view itself, such as with a separate button.
    @Binding var refreshController: RefreshController

    /// Allows parent views to act when the offset reaches a certain point.
    @Binding var scrollOffsetY: CGFloat
    
    /// A fetch request that specifies the events that should be shown. The events should be sorted in
    /// reverse-chronological order and should match the events returned by `relayFilter`.
    let databaseFilter: NSFetchRequest<Event>
    
    /// A Filter that specifies the events that should be shown. The Filter should not have `limit`, `since`, or `until`
    /// set as they will be overmanaged internally. The events downloaded by this filter should match the ones returned
    /// by the `databaseFilter`. 
    let relayFilter: Filter
    
    /// The relay to load data from. If `nil` then all the relays in the user's list will be used.
    let relay: Relay? 
    
    /// The managed object context used to fetch events from Core Data.
    let managedObjectContext: NSManagedObjectContext

    /// The tab in which this PagedNoteListView appears.
    /// Used to determine whether to scroll this view to the top when the tab is tapped.
    let tab: AppDestination

    /// A view that will be displayed as the collection view header.
    let header: () -> Header
    
    /// A view that will be displayed below the header when no notes are being shown.
    let emptyPlaceholder: () -> EmptyPlaceholder

    func makeCoordinator() -> Coordinator<Header, EmptyPlaceholder> {
        Coordinator(refreshController: refreshController, scrollOffsetY: $scrollOffsetY)
    }

    func makeUIView(context: Context) -> UICollectionView {
        let layout = Self.buildLayout()
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .clear
        collectionView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        collectionView.contentInset = .zero
        collectionView.layoutMargins = .zero
        let dataSource = context.coordinator.dataSource(
            databaseFilter: databaseFilter, 
            relayFilter: relayFilter,
            relay: relay,
            collectionView: collectionView, 
            managedObjectContext: self.managedObjectContext,
            header: header,
            emptyPlaceholder: emptyPlaceholder
        )
        collectionView.dataSource = dataSource
        collectionView.delegate = context.coordinator
        collectionView.prefetchDataSource = dataSource

        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(
            context.coordinator, 
            action: #selector(Coordinator.refreshData(_:)), 
            for: .valueChanged
        )
        collectionView.refreshControl = refreshControl

        Self.setUpObservers(
            uiView: collectionView,
            coordinator: context.coordinator,
            tab: tab
        )

        return collectionView
    }
    
    func updateUIView(_ collectionView: UICollectionView, context: Context) {
        if let dataSource = collectionView.dataSource as? PagedNoteDataSource<Header, EmptyPlaceholder> {
            if relayFilter != dataSource.relayFilter || relay != dataSource.relay {
                dataSource.subscribeToEvents(matching: relayFilter, from: relay)
            }
            
            if !areFetchRequestsEquivalent(databaseFilter, dataSource.databaseFilter) {
                dataSource.updateFetchRequest(databaseFilter)
            }
            
            if refreshController.startRefresh {
                refreshController.startRefresh = false

                guard let refreshControl = collectionView.refreshControl else { return }
                collectionView.scrollRectToVisible(refreshControl.frame, animated: true)
                refreshControl.beginRefreshing()
                context.coordinator.refreshData(refreshControl)
            }
        }
    }
    
    static func dismantleUIView(_ uiView: UICollectionView, coordinator: Coordinator<Header, EmptyPlaceholder>) {
        tearDownObservers(coordinator: coordinator)
    }

    private static func setUpObservers(
        uiView: UICollectionView,
        coordinator: Coordinator<Header, EmptyPlaceholder>,
        tab: AppDestination
    ) {
        let notificationCenter = NotificationCenter.default
        coordinator.scrollToTopObserver = notificationCenter.addObserver(
            forName: .scrollToTop,
            object: nil,
            queue: .main
        ) { [weak uiView] notification in
            // if the tab that's selected is the tab in which this `PagedNoteListView` is displayed, scroll to the top
            guard let selectedTab = notification.userInfo?["tab"] as? AppDestination,
                selectedTab == tab else {
                return
            }
            // scrolling to CGRect.zero does not work, so this seems to be the best we can do
            uiView?.scrollRectToVisible(CGRect(x: 0, y: 0, width: 1, height: 1), animated: true)
        }
    }

    private static func tearDownObservers(
        coordinator: Coordinator<Header, EmptyPlaceholder>
    ) {
        let notificationCenter = NotificationCenter.default
        if let observer = coordinator.scrollToTopObserver {
            notificationCenter.removeObserver(observer)
        }
    }

    /// Builds a one section, one column layout with dynamic cell sizes and a header and footer view.
    private static func buildLayout() -> UICollectionViewLayout {
        let size = NSCollectionLayoutSize(
            widthDimension: NSCollectionLayoutDimension.fractionalWidth(1),
            heightDimension: NSCollectionLayoutDimension.estimated(140)
        )
        let item = NSCollectionLayoutItem(layoutSize: size)
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: size, subitems: [item])

        let section = NSCollectionLayoutSection(group: group)
        section.contentInsets = .zero
        section.interGroupSpacing = 16
        
        let headerSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .estimated(300))
        let headerItem = NSCollectionLayoutBoundarySupplementaryItem(
            layoutSize: headerSize, 
            elementKind: UICollectionView.elementKindSectionHeader, 
            alignment: .top
        )
        headerItem.edgeSpacing = .none
        
        let footerSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .estimated(300))
        let footerItem = NSCollectionLayoutBoundarySupplementaryItem(
            layoutSize: footerSize, 
            elementKind: UICollectionView.elementKindSectionFooter, 
            alignment: .bottom
        )
        headerItem.edgeSpacing = .none
        
        section.boundarySupplementaryItems = [headerItem, footerItem]
        
        return UICollectionViewCompositionalLayout(section: section)
    }
    
    // swiftlint:disable generic_type_name
    /// The coordinator mainly holds a strong reference to the `dataSource` and proxies pull-to-refresh events.
    class Coordinator<CoordinatorHeader: View, CoordinatorEmptyPlaceholder: View>: NSObject, UICollectionViewDelegate {
        // swiftlint:enable generic_type_name
        
        /// Controls refresh actions. Used for setting the `lastRefreshDate` whenever the data is refreshed.
        let refreshController: RefreshController
        @Binding var scrollOffsetY: CGFloat

        var dataSource: PagedNoteDataSource<CoordinatorHeader, CoordinatorEmptyPlaceholder>?
        var collectionView: UICollectionView?
        var scrollToTopObserver: NSObjectProtocol?

        /// Initializes a coordinator with the given refresh controller.
        /// - Parameter refreshController: Controls refresh actions. Used for setting the `lastRefreshDate`
        ///                                whenever the data is refreshed.
        init(refreshController: RefreshController, scrollOffsetY: Binding<CGFloat>) {
            self.refreshController = refreshController
            self._scrollOffsetY = scrollOffsetY
        }

        func dataSource(
            databaseFilter: NSFetchRequest<Event>,
            relayFilter: Filter,
            relay: Relay?,
            collectionView: UICollectionView,
            managedObjectContext: NSManagedObjectContext,
            @ViewBuilder header: @escaping () -> CoordinatorHeader,
            @ViewBuilder emptyPlaceholder: @escaping () -> CoordinatorEmptyPlaceholder
        ) -> PagedNoteDataSource<CoordinatorHeader, CoordinatorEmptyPlaceholder> {
            if let dataSource {
                return dataSource 
            }
            self.collectionView = collectionView

            let dataSource = PagedNoteDataSource(
                databaseFilter: databaseFilter, 
                relayFilter: relayFilter,
                relay: relay,
                collectionView: collectionView, 
                managedObjectContext: managedObjectContext,
                header: header,
                emptyPlaceholder: emptyPlaceholder
            )
            self.dataSource = dataSource
            return dataSource
        }
    
        @objc func refreshData(_ sender: Any) {
            DispatchQueue.main.async { [weak refreshController] in
                refreshController?.lastRefreshDate = .now
            }

            if let refreshControl = sender as? UIRefreshControl {
                // Dismiss the refresh control
                DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(1)) {
                    refreshControl.endRefreshing()
                }
            }
        }
        
        func scrollViewDidScroll(_ scrollView: UIScrollView) {
            scrollOffsetY = scrollView.contentOffset.y
        }
    }
}

extension Notification.Name {
    /// Instructs the receiver to scroll its list to the top
    static let scrollToTop = Notification.Name("scrollToTop")
}

#Preview {
    var previewData = PreviewData()
    @State var refreshController = RefreshController()

    return PagedNoteListView(
        refreshController: $refreshController,
        scrollOffsetY: .constant(0),
        databaseFilter: previewData.alice.allPostsRequest(onlyRootPosts: false),
        relayFilter: Filter(), 
        relay: nil,
        managedObjectContext: previewData.previewContext,
        tab: .home,
        header: {
            ProfileHeader(author: previewData.alice, selectedTab: .constant(.activity))
                .compositingGroup()
                .shadow(color: .profileShadow, radius: 10, x: 0, y: 4)
                .id(previewData.alice.id)
        },
        emptyPlaceholder: {
            Text("empty")
        }
    )
    .background(Color.appBg)
    .inject(previewData: previewData)
    .onAppear {
        for i in 0..<100 {
            let note = Event(context: previewData.previewContext)
            note.identifier = "ProfileNotesView-\(i)"
            note.kind = EventKind.text.rawValue
            note.content = "\(i)"
            note.author = previewData.alice
            note.createdAt = Date(timeIntervalSince1970: Date.now.timeIntervalSince1970 - Double(i))
        }
    }
}

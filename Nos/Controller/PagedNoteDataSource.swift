import SwiftUI
import CoreData
import Dependencies
import Logger

/// Works with ``PagedNoteListView`` to paginate reverse-chronological events from CoreData and relays simultaneously.
final class PagedNoteDataSource<Header: View, EmptyPlaceholder: View>: NSObject, UICollectionViewDataSource,
    NSFetchedResultsControllerDelegate, UICollectionViewDataSourcePrefetching {
    
    private var fetchedResultsController: NSFetchedResultsController<Event>
    private var collectionView: UICollectionView
    
    @Dependency(\.relayService) private var relayService: RelayService
    private(set) var databaseFilter: NSFetchRequest<Event>
    private(set) var relayFilter: Filter
    private(set) var relay: Relay?
    private var pager: PagedRelaySubscription?
    private var managedObjectContext: NSManagedObjectContext
    private var header: () -> Header
    private var emptyPlaceholder: () -> EmptyPlaceholder
    private let pageSize = 20
    
    // We intentionally generate unique IDs for cell reuse to get around 
    // [this issue](https://github.com/planetary-social/nos/issues/873)
    private lazy var headerReuseID = { "Header-\(self.description)" }()
    private lazy var footerReuseID = { "Footer-\(self.description)" }()
    
    init(
        databaseFilter: NSFetchRequest<Event>, 
        relayFilter: Filter, 
        relay: Relay?, 
        collectionView: UICollectionView, 
        managedObjectContext: NSManagedObjectContext,
        @ViewBuilder header: @escaping () -> Header,
        @ViewBuilder emptyPlaceholder: @escaping () -> EmptyPlaceholder
    ) {
        self.databaseFilter = databaseFilter
        self.fetchedResultsController = NSFetchedResultsController<Event>(
            fetchRequest: databaseFilter,
            managedObjectContext: managedObjectContext,
            sectionNameKeyPath: nil,
            cacheName: nil
        )
        self.collectionView = collectionView
        self.managedObjectContext = managedObjectContext
        self.relayFilter = relayFilter
        self.relay = relay
        self.header = header
        self.emptyPlaceholder = emptyPlaceholder

        super.init()
        
        collectionView.register(
            UICollectionViewCell.self, 
            forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, 
            withReuseIdentifier: headerReuseID
        )
        collectionView.register(
            UICollectionViewCell.self, 
            forSupplementaryViewOfKind: UICollectionView.elementKindSectionFooter, 
            withReuseIdentifier: footerReuseID
        )
        
        self.fetchedResultsController.delegate = self
        
        do {
            try self.fetchedResultsController.performFetch()
        } catch {
            @Dependency(\.crashReporting) var crashReporter
            crashReporter.report(error)
            Log.error(error)
        }
        
        subscribeToEvents(matching: relayFilter, from: relay)
    }
    
    func subscribeToEvents(matching filter: Filter, from relay: Relay?) {
        self.relayFilter = filter
        self.relay = relay
        
        Task { 
            var limitedFilter = filter
            limitedFilter.limit = pageSize
            self.pager = await relayService.subscribeToPagedEvents(matching: limitedFilter, from: relay?.addressURL)
            loadMoreIfNeeded(for: IndexPath(row: 0, section: 0))
        }
    }
    
    func updateFetchRequest(_ fetchRequest: NSFetchRequest<Event>) {
        self.databaseFilter = fetchRequest
        self.fetchedResultsController = NSFetchedResultsController<Event>(
            fetchRequest: fetchRequest,
            managedObjectContext: managedObjectContext,
            sectionNameKeyPath: nil,
            cacheName: nil
        )
        self.fetchedResultsController.delegate = self
        try? self.fetchedResultsController.performFetch()
        loadMoreIfNeeded(for: IndexPath(row: 0, section: 0))
        collectionView.reloadData()
        collectionView.setContentOffset(.zero, animated: false)
    }
    
    // MARK: - UICollectionViewDataSource
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        let numberOfFetchedObjects = fetchedResultsController.fetchedObjects?.count ?? 0
        // because we batch updates together to reduce animations but this function is called in between batches we
        // need to account for the number of items queued for insertion or deletion. FetchedResultsController sees them
        // but the collectionView doesn't yet.
        let numberOfItemsInView = numberOfFetchedObjects - insertedIndexes.count + deletedIndexes.count
        return numberOfItemsInView
    }
    
    func collectionView(
        _ collectionView: UICollectionView, 
        cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {
        loadMoreIfNeeded(for: indexPath)
        
        let note = fetchedResultsController.object(at: indexPath)

        // We intentionally generate unique IDs for cell reuse to get around 
        // [this issue](https://github.com/planetary-social/nos/issues/873)
        let cellReuseID = note.identifier ?? "error"
        collectionView.register(UICollectionViewCell.self, forCellWithReuseIdentifier: cellReuseID)
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellReuseID, for: indexPath) 
        
        cell.contentConfiguration = UIHostingConfiguration { 
            NoteButton(
                note: note,
                hideOutOfNetwork: false,
                repliesDisplayType: .discussion,
                showsLikeCount: false,
                showsRepostCount: false,
                fetchReplies: true,
                displayRootMessage: true
            )
        }
        .margins(.horizontal, 0)

        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, prefetchItemsAt indexPaths: [IndexPath]) {
        for indexPath in indexPaths {
            let note = fetchedResultsController.object(at: indexPath)
            Task { await note.loadViewData() }
        }
    }
    
    func collectionView(
        _ collectionView: UICollectionView, 
        viewForSupplementaryElementOfKind kind: String, 
        at indexPath: IndexPath
    ) -> UICollectionReusableView {
        switch kind {
        case UICollectionView.elementKindSectionHeader:
            guard let header = collectionView.dequeueReusableSupplementaryView(
                ofKind: kind,
                withReuseIdentifier: headerReuseID,
                for: indexPath
            ) as? UICollectionViewCell else {
                return UICollectionViewCell()
            }

            header.contentConfiguration = UIHostingConfiguration {
                self.header()
            }
            .margins(.horizontal, 0)
            .margins(.top, 0)

            return header
            
        case UICollectionView.elementKindSectionFooter:
            guard let footer = collectionView.dequeueReusableSupplementaryView(
                ofKind: kind, 
                withReuseIdentifier: footerReuseID, 
                for: indexPath
            ) as? UICollectionViewCell else {
                return UICollectionViewCell()
            }
            
            footer.contentConfiguration = UIHostingConfiguration { 
                if self.fetchedResultsController.fetchedObjects?.isEmpty == true {
                    self.emptyPlaceholder()
                }
            }
            .margins(.horizontal, 0)
            .margins(.top, 0)
            return footer
        default:
            return UICollectionViewCell()
        }
    }
    
    // MARK: - Loading data
    
    /// Instructs the pager to load more data if we are getting close to the end of the object in the list.
    /// - Parameter indexPath: the indexPath last loaded by the collection view.
    private func loadMoreIfNeeded(for indexPath: IndexPath) {
        largestLoadedRowIndex = max(largestLoadedRowIndex, indexPath.row)
        let lastPageStartIndex = (fetchedResultsController.fetchedObjects?.count ?? 0) - pageSize
        if indexPath.row > lastPageStartIndex {
            // we are on the last page, load aggressively
            startAggressivePaging()
            return
        } else if indexPath.row.isMultiple(of: pageSize / 2) {
            let displayedDate = displayedDate(for: indexPath.row)
            Task {
                await pager?.loadMore(displayingContentAt: displayedDate)
            }
        } 
    }
    
    /// A timer used for aggressive paging when we reach the end of the data. See `startAggressivePaging()`.
    private var aggressivePagingTimer: Timer?
    
    /// The largest row index seen by `loadMoreIfNeeded(for:)`
    private var largestLoadedRowIndex: Int = 0
    
    /// This function puts the data source into "aggressive paging" mode, which basically changes the paging 
    /// code from executing when the user scrolls (more efficient) to executing on a repeating timer. This timer will 
    /// automatically call `stopAggressivePaging` when it has loaded enough data.
    /// 
    /// We need to use this mode when we have an empty or nearly empty list of notes, or when the user reaches the end 
    /// of the results before more have loaded. We can't just wait on the existing paging requests to return (like a 
    /// normal REST paging API) because often we can't request exactly the notes we want from relays. For instance when 
    /// we are fetching root notes only on the profile screen we can only ask relays for all kind 1 notes. This means 
    /// we could get a page full of reply notes from the relays, none of which will match our NSFetchRequest and show 
    /// up in the UICollectionViewDataSource - meaning `cellForRowAtIndexPath` won't be called which means 
    /// `loadMoreIfNeeded(for:)` won't be called which means we'll never ask for the next page. So we need the timer.
    private func startAggressivePaging() {
        if aggressivePagingTimer == nil {
            
            aggressivePagingTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] timer in
                guard let self else { 
                    timer.invalidate()
                    return 
                }
                
                let lastPageStartIndex = (self.fetchedResultsController.fetchedObjects?.count ?? 0) - self.pageSize

                if self.largestLoadedRowIndex > lastPageStartIndex {
                    // we are still on the last page of results, keep loading
                    let displayedDate = self.displayedDate(for: largestLoadedRowIndex)
                    Task {
                        await self.pager?.loadMore(displayingContentAt: displayedDate)
                    }
                } else {
                    // we've loaded enough, go back to normal paging
                    self.stopAggressivePaging()
                }
            }
            
            // Fire manually once because the timer doesn't fire immediately
            aggressivePagingTimer?.fire()
        }
    }
    
    /// Takes this data source out of "aggressive paging" mode. See `startAggressivePaging()`.
    private func stopAggressivePaging() {
        if let aggressivePagingTimer {
            aggressivePagingTimer.invalidate()
            self.aggressivePagingTimer = nil
        }
    }
    
    /// Returns the `created_at` date of the event at the given index, if one exists.
    private func displayedDate(for index: Int) -> Date? {
        fetchedResultsController.fetchedObjects?[safe: index]?.createdAt
    }
    
    // MARK: - NSFetchedResultsControllerDelegate
    
    private var insertedIndexes = [IndexPath]()
    private var deletedIndexes = [IndexPath]()
    private var movedIndexes = [(IndexPath, IndexPath)]()
    
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        collectionView.performBatchUpdates({
            insertedIndexes = [IndexPath]()
            deletedIndexes = [IndexPath]()
            movedIndexes = [(IndexPath, IndexPath)]()
        })
    }
    
    func controller(
        _ controller: NSFetchedResultsController<NSFetchRequestResult>, 
        didChange anObject: Any, 
        at indexPath: IndexPath?, 
        for type: NSFetchedResultsChangeType, 
        newIndexPath: IndexPath?
    ) {

        // Note: I tried using UICollectionViewDiffableDatasource but it didn't seem to work well with SwiftUI views
        // as it kept reloading cells with animations when nothing was visually changing.
        switch type {
        case .insert:
            if let newIndexPath = newIndexPath {
                insertedIndexes.append(newIndexPath)
            }
        case .delete:
            if let indexPath = indexPath {
                deletedIndexes.append(indexPath)
            }
        case .update:
            // The SwiftUI cells are observing their source Core Data objects already so we don't need to notify
            // them of updates through the collectionView.
            return
        case .move:
            if let oldIndexPath = indexPath, let newIndexPath {
                movedIndexes.append((oldIndexPath, newIndexPath)) 
            }
        @unknown default:
            fatalError("Unexpected NSFetchedResultsChangeType: \(type)")
        }
    }
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        if !deletedIndexes.isEmpty { // it doesn't seem like this check should be necessary but it crashes otherwise
            let deletedIndexesCopy = deletedIndexes
            deletedIndexes = [] // clear indexes so numberOfItemsInSection can calculate the correct number
            collectionView.deleteItems(at: deletedIndexesCopy)
        }
        if !insertedIndexes.isEmpty {
            let insertedIndexesCopy = insertedIndexes
            insertedIndexes = [] // clear indexes so numberOfItemsInSection can calculate the correct number
            collectionView.insertItems(at: insertedIndexesCopy)
        }
        
        movedIndexes.forEach { indexPair in 
            let (oldIndex, newIndex) = indexPair
            collectionView.moveItem(at: oldIndex, to: newIndex)
        }
    }
}

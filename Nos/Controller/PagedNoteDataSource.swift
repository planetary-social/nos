import SwiftUI
import CoreData
import Dependencies
import Logger

/// Works with PagesNoteListView to paginate a reverse-chronological events from CoreData and relays simultaneously.
class PagedNoteDataSource<Header: View, EmptyPlaceholder: View>: NSObject, UICollectionViewDataSource, 
    NSFetchedResultsControllerDelegate, UICollectionViewDataSourcePrefetching {
    
    var fetchedResultsController: NSFetchedResultsController<Event>
    var collectionView: UICollectionView
    
    @Dependency(\.relayService) private var relayService: RelayService
    private var relayFilter: Filter
    private var pager: PagedRelaySubscription?
    private var context: NSManagedObjectContext
    private var header: () -> Header
    private var emptyPlaceholder: () -> EmptyPlaceholder
    let pageSize = 20
    
    // We intentionally generate unique IDs for cell reuse to get around 
    // [this issue](https://github.com/planetary-social/nos/issues/873)
    lazy var headerReuseID = { "Header-\(self.description)" }()
    lazy var footerReuseID = { "Footer-\(self.description)" }()
    
    init(
        databaseFilter: NSFetchRequest<Event>, 
        relayFilter: Filter, 
        collectionView: UICollectionView, 
        context: NSManagedObjectContext,
        @ViewBuilder header: @escaping () -> Header,
        @ViewBuilder emptyPlaceholder: @escaping () -> EmptyPlaceholder
    ) {
        self.fetchedResultsController = NSFetchedResultsController<Event>(
            fetchRequest: databaseFilter,
            managedObjectContext: context,
            sectionNameKeyPath: nil,
            cacheName: nil
        )
        self.collectionView = collectionView
        self.context = context
        self.relayFilter = relayFilter
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
        
        Task {
            var limitedFilter = relayFilter
            limitedFilter.limit = pageSize
            self.pager = await relayService.subscribeToPagedEvents(matching: limitedFilter)
        }
    }
    
    func updateFetchRequest(_ fetchRequest: NSFetchRequest<Event>) {
        self.fetchedResultsController = NSFetchedResultsController<Event>(
            fetchRequest: fetchRequest,
            managedObjectContext: context,
            sectionNameKeyPath: nil,
            cacheName: nil
        )
        self.fetchedResultsController.delegate = self
        try? self.fetchedResultsController.performFetch()
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
            NoteButton(note: note, hideOutOfNetwork: false, displayRootMessage: true)
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
    func loadMoreIfNeeded(for indexPath: IndexPath) {
        let lastPageStartIndex = (fetchedResultsController.fetchedObjects?.count ?? 0) - pageSize
        if indexPath.row > lastPageStartIndex {
            // we are at the end of the list, load aggressively
            pager?.loadMore()
        } else if indexPath.row.isMultiple(of: pageSize / 2) {
            pager?.loadMore()
        }        
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
        }, completion: { (success) in
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

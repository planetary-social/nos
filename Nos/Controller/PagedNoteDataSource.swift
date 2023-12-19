//
//  PagedNoteDataSource.swift
//  Nos
//
//  Created by Matthew Lorentz on 11/27/23.
//

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
    private var subscriptionIDs: [RelaySubscription.ID] = []
    private var relayFilter: Filter
    private var pager: PagedRelaySubscription?
    private var context: NSManagedObjectContext
    private var header: () -> Header
    private var emptyPlaceholder: () -> EmptyPlaceholder
    let pageSize = 10
    
    private var cellReuseID = "Cell"
    private var headerReuseID = "Header"
    private var footerReuseID = "Footer"
    
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
        
        collectionView.register(UICollectionViewCell.self, forCellWithReuseIdentifier: cellReuseID)
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

        super.init()
        
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
            self.pager = await relayService.openPagedSubscription(with: limitedFilter)
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
        fetchedResultsController.fetchedObjects?.count ?? 0
    }
    
    func collectionView(
        _ collectionView: UICollectionView, 
        cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {
        if indexPath.row.isMultiple(of: pageSize) {
            pager?.loadMore()
        }        
        
        let note = fetchedResultsController.object(at: indexPath) 
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
                self.emptyPlaceholder()
            }
            .margins(.horizontal, 0)
            .margins(.top, 0)
            return footer
        default:
            return UICollectionViewCell()
        }
    }
    
    // MARK: - NSFetchedResultsControllerDelegate
    
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        collectionView.performBatchUpdates(nil, completion: nil)
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
                collectionView.insertItems(at: [newIndexPath])
            }
        case .delete:
            if let indexPath = indexPath {
                collectionView.deleteItems(at: [indexPath])
            }
        case .update:
            // The SwiftUI cells are observing their source Core Data objects already so we don't need to notify
            // them of updates through the collectionView.
            return
        case .move:
            if let indexPath = indexPath, let newIndexPath = newIndexPath {
                collectionView.moveItem(at: indexPath, to: newIndexPath)
            }
        @unknown default:
            fatalError("Unexpected NSFetchedResultsChangeType: \(type)")
        }
    }
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        collectionView.performBatchUpdates(nil, completion: nil)
    }
}

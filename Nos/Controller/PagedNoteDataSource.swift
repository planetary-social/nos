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
class PagedNoteDataSource: UICollectionViewDiffableDataSource<Int, NSManagedObjectID>, 
    NSFetchedResultsControllerDelegate, UICollectionViewDataSourcePrefetching {
    
    let fetchedResultsController: NSFetchedResultsController<Event>
    
    @Dependency(\.relayService) private var relayService: RelayService
    private var subscriptionIDs: [RelaySubscription.ID] = []
    private var relayFilter: Filter
    private var pager: PagedRelaySubscription?
    let pageSize = 10
    
    init(
        databaseFilter: NSFetchRequest<Event>, 
        relayFilter: Filter, 
        collectionView: UICollectionView, 
        context: NSManagedObjectContext
    ) {
        self.fetchedResultsController = NSFetchedResultsController<Event>(
            fetchRequest: databaseFilter,
            managedObjectContext: context,
            sectionNameKeyPath: nil,
            cacheName: nil
        )
        self.relayFilter = relayFilter
        
        super.init(collectionView: collectionView) { (collectionView, indexPath, objectID) in
            guard let note = try? context.existingObject(with: objectID) as? Event else {
                return UICollectionViewCell()
            }
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "NoteButtonCell", for: indexPath) 
            cell.contentConfiguration = UIHostingConfiguration { 
                NoteButton(note: note, hideOutOfNetwork: false, displayRootMessage: true)
            }
            .margins(.horizontal, 0)
            
            return cell
        }
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
    
    // MARK: - UICollectionViewDataSource
    
    override func collectionView(
        _ collectionView: UICollectionView, 
        cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {
        if indexPath.row.isMultiple(of: pageSize) {
            pager?.loadMore()
        }        
        return super.collectionView(collectionView, cellForItemAt: indexPath)
    }
    
    func collectionView(_ collectionView: UICollectionView, prefetchItemsAt indexPaths: [IndexPath]) {
        for indexPath in indexPaths {
            let note = fetchedResultsController.object(at: indexPath)
            if !note.loadingViewData {
                Task { await note.loadViewData() }
            }
        }
    }
    
    // MARK: - NSFetchedResultsControllerDelegate
    
    func controller(
        _ controller: NSFetchedResultsController<NSFetchRequestResult>, 
        didChangeContentWith snapshot: NSDiffableDataSourceSnapshotReference
    ) {
        let snapshot = snapshot as NSDiffableDataSourceSnapshot<Int, NSManagedObjectID>
        apply(snapshot, animatingDifferences: false)
    }
}

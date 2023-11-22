//
//  NoteListView.swift
//  Nos
//
//  Created by Matthew Lorentz on 11/20/23.
//

import SwiftUI
import CoreData
import Dependencies

struct NoteListView: UIViewRepresentable {
    
    let fetchRequest: NSFetchRequest<Event>
    let context: NSManagedObjectContext
    let author: Author
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    func makeUIView(context: Context) -> UICollectionView {
        let size = NSCollectionLayoutSize(
            widthDimension: NSCollectionLayoutDimension.fractionalWidth(1),
            heightDimension: NSCollectionLayoutDimension.estimated(140)
        )
        let item = NSCollectionLayoutItem(layoutSize: size)
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: size, subitems: [item])
        
        let section = NSCollectionLayoutSection(group: group)
        section.contentInsets = .zero
        section.interGroupSpacing = 0
        
        let layout = UICollectionViewCompositionalLayout(section: section)
        
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .clear
        collectionView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        collectionView.contentInset = .zero
        collectionView.layoutMargins = .zero
        let dataSource = context.coordinator.diffableDataSource(
            fetchRequest: fetchRequest, 
            author: author,
            collectionView: collectionView, 
            context: self.context
        )
        collectionView.dataSource = dataSource
        collectionView.prefetchDataSource = dataSource
        collectionView.register(UICollectionViewCell.self, forCellWithReuseIdentifier: "NoteButtonCell")
        return collectionView
    }
    
    func updateUIView(_ collectionView: UICollectionView, context: Context) {}
    
    class Coordinator {
        
        var dataSource: NoteDiffableDataSource?
        
        func diffableDataSource(
            fetchRequest: NSFetchRequest<Event>, 
            author: Author,
            collectionView: UICollectionView,
            context: NSManagedObjectContext
        ) -> NoteDiffableDataSource {
            if let dataSource {
                return dataSource 
            } 
            
            let dataSource = NoteDiffableDataSource(
                fetchRequest: fetchRequest, 
                author: author,
                collectionView: collectionView, 
                context: context
            )
            self.dataSource = dataSource
            return dataSource
        }
    }
}

class RelayPager {
    
    @Dependency(\.relayService) private var relayService: RelayService
    private var subscriptionIDs: [RelaySubscription.ID] = []
    private var author: Author
    private var pager: PagedRelaySubscription?
    let pageSize = 10
    
    init(author: Author) {
        self.author = author
        
        Task {
            // Close out stale requests
            if !subscriptionIDs.isEmpty {
                await relayService.decrementSubscriptionCount(for: subscriptionIDs)
                subscriptionIDs.removeAll()
            }
            
            guard let authorKey = author.hexadecimalPublicKey else {
                return
            }
            
            // Posts
            let authors = [authorKey]
            let textFilter = Filter(authorKeys: authors, kinds: [.text, .delete, .repost, .longFormContent], limit: pageSize)
            self.pager = await relayService.openPagedSubscription(with: textFilter)
            
            // Profile data
            subscriptionIDs.append(
                contentsOf: await relayService.requestProfileData(
                    for: authorKey, 
                    lastUpdateMetadata: author.lastUpdatedMetadata, 
                    lastUpdatedContactList: nil // always grab contact list because we purge follows aggressively
                )
            )
            
            // reports
            let reportFilter = Filter(kinds: [.report], pTags: [authorKey])
            subscriptionIDs.append(contentsOf: await relayService.openSubscriptions(with: reportFilter)) 
        }
    }
    
    func prefetch(indexPath: IndexPath) {
        if indexPath.row % pageSize == 0 {
            pager?.loadMore()
        }
    }
}

class NoteDiffableDataSource: UICollectionViewDiffableDataSource<Int, NSManagedObjectID>, 
    NSFetchedResultsControllerDelegate, UICollectionViewDataSourcePrefetching {
    
    let fetchedResultsController: NSFetchedResultsController<Event>
    var relayPager: RelayPager
    
    init(fetchRequest: NSFetchRequest<Event>, author: Author, collectionView: UICollectionView, context: NSManagedObjectContext) {
        self.fetchedResultsController = NSFetchedResultsController<Event>(
            fetchRequest: fetchRequest,
            managedObjectContext: context,
            sectionNameKeyPath: nil,
            cacheName: nil
        )
        self.relayPager = RelayPager(author: author)
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
        
        try! self.fetchedResultsController.performFetch()
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        relayPager.prefetch(indexPath: indexPath)
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
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChangeContentWith snapshot: NSDiffableDataSourceSnapshotReference) {
        let snapshot = snapshot as NSDiffableDataSourceSnapshot<Int, NSManagedObjectID>
        apply(snapshot, animatingDifferences: false)
    }
}

#Preview {
    var previewData = PreviewData()
    
    return NoteListView(fetchRequest: previewData.alice.allPostsRequest(), context: previewData.previewContext, author: previewData.alice)
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

//
//  PagedNoteListView.swift
//  Nos
//
//  Created by Matthew Lorentz on 11/20/23.
//

import SwiftUI
import CoreData
import Dependencies
import Logger

/// The paged note list view is designed to display an infinite list of notes in reverse-chronological order.
/// It takes two filters: one to load events from our local database (Core Data) and one to load them from the 
/// relays. As the user scrolls down we will keep adjusting the relay filter to get older events.
/// 
/// Under the hood PagedNoteListView is using UICollectionView and NSFetchedResultsController. We leverage the
/// UICollectionViewDataSourcePrefetching protocol to call Event.loadViewData() on events in advanced of them being 
/// shown, which allows us to perform expensive tasks like downloading images, calculating attributed text, fetching
/// author metadata and linked notes, etc. before the view is displayed.
struct PagedNoteListView: UIViewRepresentable {
    
    /// A fetch request that specifies the events that should be shown. The events should be sorted in 
    /// reverse-chronological order and should match the events returned by `relayFilter`.
    let databaseFilter: NSFetchRequest<Event>
    
    /// A Filter that specifies the events that should be shown. The Filter should not have `limit`, `since`, or `until`
    /// set as they will be overmanaged internally. The events downloaded by this filter should match the ones returned
    /// by the `databaseFilter`. 
    let relayFilter: Filter
    
    let context: NSManagedObjectContext
    
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
        let dataSource = context.coordinator.dataSource(
            databaseFilter: databaseFilter, 
            relayFilter: relayFilter,
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
        
        var dataSource: PagedNoteDataSource?
        
        func dataSource(
            databaseFilter: NSFetchRequest<Event>, 
            relayFilter: Filter,
            collectionView: UICollectionView,
            context: NSManagedObjectContext
        ) -> PagedNoteDataSource {
            if let dataSource {
                return dataSource 
            } 
            
            let dataSource = PagedNoteDataSource(
                databaseFilter: databaseFilter, 
                relayFilter: relayFilter,
                collectionView: collectionView, 
                context: context
            )
            self.dataSource = dataSource
            return dataSource
        }
    }
}

#Preview {
    var previewData = PreviewData()
    
    return PagedNoteListView(
        databaseFilter: previewData.alice.allPostsRequest(), 
        relayFilter: Filter(),
        context: previewData.previewContext
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

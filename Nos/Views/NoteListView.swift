//
//  NoteListView.swift
//  Nos
//
//  Created by Matthew Lorentz on 11/20/23.
//

import SwiftUI
import CoreData

struct NoteListView: UIViewRepresentable {
    
    let fetchRequest: NSFetchRequest<Event>
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
        let dataSource = context.coordinator.diffableDataSource(
            fetchRequest: fetchRequest, 
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
            collectionView: UICollectionView,
            context: NSManagedObjectContext
        ) -> NoteDiffableDataSource {
            if let dataSource {
                return dataSource 
            } 
            
            let dataSource = NoteDiffableDataSource(
                fetchRequest: fetchRequest, 
                collectionView: collectionView, 
                context: context
            )
            self.dataSource = dataSource
            return dataSource
        }
    }
}

class NoteDiffableDataSource: UICollectionViewDiffableDataSource<Int, NSManagedObjectID>, 
    NSFetchedResultsControllerDelegate, UICollectionViewDataSourcePrefetching {
    
    let fetchedResultsController: NSFetchedResultsController<Event>
    
    init(fetchRequest: NSFetchRequest<Event>, collectionView: UICollectionView, context: NSManagedObjectContext) {
        self.fetchedResultsController = NSFetchedResultsController<Event>(
            fetchRequest: fetchRequest,
            managedObjectContext: context,
            sectionNameKeyPath: nil,
            cacheName: nil
        )
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
    
    return NoteListView(fetchRequest: previewData.alice.allPostsRequest(), context: previewData.previewContext)
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

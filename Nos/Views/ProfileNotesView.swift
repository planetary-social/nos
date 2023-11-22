//
//  ProfileNotesView.swift
//  Nos
//
//  Created by Matthew Lorentz on 11/20/23.
//

import SwiftUI
import CoreData

struct NoteList: UIViewRepresentable {
    
    let fetchRequest: NSFetchRequest<Event>
    let context: NSManagedObjectContext
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    func makeUIView(context: Context) -> UICollectionView {
//        let layout = UICollectionViewFlowLayout()
//        layout.scrollDirection = .vertical
//        layout.estimatedItemSize = UICollectionViewFlowLayout.automaticSize
//        layout.sectionInset = .zero
//        layout.minimumInteritemSpacing = 15
//        layout.minimumLineSpacing = 15
        
        let size = NSCollectionLayoutSize(
            widthDimension: NSCollectionLayoutDimension.fractionalWidth(1),
            heightDimension: NSCollectionLayoutDimension.estimated(44)
        )
        let item = NSCollectionLayoutItem(layoutSize: size)
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: size, subitem: item, count: 1)
        
        let section = NSCollectionLayoutSection(group: group)
        section.contentInsets = .zero
        section.interGroupSpacing = 15
        
        let layout = UICollectionViewCompositionalLayout(section: section)
        
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .clear
        collectionView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        collectionView.contentInset = .zero
        collectionView.layoutMargins = .zero
        collectionView.backgroundColor = .red
        collectionView.dataSource = context.coordinator.diffableDataSource(fetchRequest: fetchRequest, collectionView: collectionView, context: self.context)
        collectionView.register(UICollectionViewCell.self, forCellWithReuseIdentifier: "NoteButtonCell")
        return collectionView
    }
    
    func updateUIView(_ collectionView: UICollectionView, context: Context) {
//        collectionView.reloadData()
    }
    
    class Coordinator {
        
        var dataSource: UICollectionViewDiffableDataSource<Int, NSManagedObjectID>?
        
        func diffableDataSource(
            fetchRequest: NSFetchRequest<Event>, 
            collectionView: UICollectionView,
            context: NSManagedObjectContext
        ) -> UICollectionViewDiffableDataSource<Int, NSManagedObjectID> {
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

class NoteDiffableDataSource: UICollectionViewDiffableDataSource<Int, NSManagedObjectID>, NSFetchedResultsControllerDelegate {
    
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
                fatalError("Managed object should be available")
            }
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "NoteButtonCell", for: indexPath) 
            cell.contentConfiguration = UIHostingConfiguration(content: { 
                NoteButton(note: note, hideOutOfNetwork: false, displayRootMessage: true)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.blue)
            })
            
            return cell
        }
        self.fetchedResultsController.delegate = self
        
        try! self.fetchedResultsController.performFetch()
    }
    
    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        let number = super.numberOfSections(in: collectionView)
        return number
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        let number = super.collectionView(collectionView, numberOfItemsInSection: section)
        return number
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        super.collectionView(collectionView, cellForItemAt: indexPath)
    }
    
    // MARK: - NSFetchedResultsControllerDelegate
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChangeContentWith snapshot: NSDiffableDataSourceSnapshotReference) {
       
        var snapshot = snapshot as NSDiffableDataSourceSnapshot<Int, NSManagedObjectID>
        let currentSnapshot = self.snapshot() as NSDiffableDataSourceSnapshot<Int, NSManagedObjectID>
        
        let reloadIdentifiers: [NSManagedObjectID] = snapshot.itemIdentifiers.compactMap { itemIdentifier in
            guard let currentIndex = currentSnapshot.indexOfItem(itemIdentifier), let index = snapshot.indexOfItem(itemIdentifier), index == currentIndex else {
                return nil
            }
            guard let existingObject = try? controller.managedObjectContext.existingObject(with: itemIdentifier), existingObject.isUpdated else { return nil }
            return itemIdentifier
        }
        snapshot.reloadItems(reloadIdentifiers)
        
        let shouldAnimate = true //collectionView?.numberOfSections != 0
        apply(snapshot as NSDiffableDataSourceSnapshot<Int, NSManagedObjectID>, animatingDifferences: shouldAnimate)
    }
}

#Preview {
    var previewData = PreviewData()
    
    return NoteList(fetchRequest: previewData.alice.allPostsRequest(), context: previewData.previewContext)
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

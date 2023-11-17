//
//  NoteWarningController.swift
//  Nos
//
//  Created by Matthew Lorentz on 10/26/23.
//

import Foundation
import Dependencies
import Combine
import CoreData

extension Publisher {
    func asyncMap<T>(
        _ transform: @escaping (Output) async -> T
    ) -> Publishers.FlatMap<Future<T, Never>, Self> {
        flatMap { value in
            Future { promise in
                Task {
                    let output = await transform(value)
                    promise(.success(output))
                }
            }
        }
    }
}

class NoteWarningController: NSObject, ObservableObject {
    
    @Published var showWarning = false
    @Published var userHidWarning = false
    @Published var outOfNetwork = false
    
    @Published var note: Event?
    @Published var shouldHideOutOfNetwork = true
    @Published private var showReportWarnings = true
    @Published private var showOutOfNetworkWarning = true
    
    @Dependency(\.currentUser) var currentUser
    @Dependency(\.persistenceController) var persistenceController
    @Dependency(\.userDefaults) var userDefaults
    
    @Published var noteReports = [Event]()
    @Published var authorReports = [Event]()
    private var cancellables = [AnyCancellable]()
    private var noteReportsWatcher: NSFetchedResultsController<Event>?
    private var authorReportsWatcher: NSFetchedResultsController<Event>?
    
    // swiftlint:disable:next implicitly_unwrapped_optional
    private var objectContext: NSManagedObjectContext!
    
    // This function is too long, I should break it up into nicely named functions.
    // swiftlint:disable:next cyclomatic_complexity function_body_length
    override init() {
        super.init()
        self.objectContext = persistenceController.viewContext
        
        /// Watch for new reports when the note is set
        $note
            .receive(on: DispatchQueue.main)
            .sink { [weak self] note in
                guard let self else {
                    return
                }
                
                guard let note else {
                    self.noteReportsWatcher = nil
                    self.authorReportsWatcher = nil
                    return
                }
                
                let noteReportsWatcher = NSFetchedResultsController(
                    fetchRequest: note.reportsRequest(), 
                    managedObjectContext: objectContext, 
                    sectionNameKeyPath: nil, 
                    cacheName: "NoteWarningController.noteReportsWatcher.\(String(describing: note.identifier))"
                )
                self.noteReportsWatcher = noteReportsWatcher
                
                FetchedResultsControllerPublisher(fetchedResultsController: noteReportsWatcher)
                    .publisher
                    .asyncMap { (events: [Event]?) -> [Event] in
                        await MainActor.run {
                            var eventsFromFollowedAuthors = [Event]()
                            for event in events ?? [] where
                                self.currentUser.socialGraph.follows(event.author?.hexadecimalPublicKey) {
                                    eventsFromFollowedAuthors.append(event)
                            }
                            return eventsFromFollowedAuthors
                        }
                    } 
                    .receive(on: DispatchQueue.main)
                    .sink(receiveValue: { [weak self] followedReports in
                        self?.noteReports = followedReports
                    })
                    .store(in: &self.cancellables)
                
                if let author = note.author {
                    let authorReportsWatcher = NSFetchedResultsController(
                        fetchRequest: author.reportsReferencingFetchRequest(), 
                        managedObjectContext: objectContext, 
                        sectionNameKeyPath: nil, 
                        cacheName: "NoteWarningController.authorReportsWatcher.\(String(describing: note.identifier))"
                    )
                    self.authorReportsWatcher = authorReportsWatcher
                    
                    FetchedResultsControllerPublisher(fetchedResultsController: authorReportsWatcher)
                        .publisher
                        .asyncMap { (events: [Event]?) -> [Event] in
                            await MainActor.run {
                                var eventsFromFollowedAuthors = [Event]()
                                for event in events ?? [] where 
                                self.currentUser.socialGraph.follows(event.author?.hexadecimalPublicKey) {
                                    eventsFromFollowedAuthors.append(event)
                                }
                                return eventsFromFollowedAuthors
                            }
                        } 
                        .receive(on: DispatchQueue.main)
                        .sink(receiveValue: { [weak self] followedReports in
                            self?.authorReports = followedReports
                        })
                        .store(in: &self.cancellables)
                }
            }
            .store(in: &cancellables)
        
        $note
            .sink { note in
                Task { @MainActor in 
                    if let authorKey = note?.author?.hexadecimalPublicKey {
                        self.outOfNetwork = !self.currentUser.socialGraph.contains(authorKey)
                    } else {
                        self.outOfNetwork = false
                    }
                }
            }
            .store(in: &cancellables)
        
        /// Update the `showWarning` property when any of the inputs change
        $userHidWarning
            .combineLatest($noteReports, $authorReports, $outOfNetwork)
            .sink { [weak self] (combined) in
                let (userHidWarning, noteReports, authorReports, outOfNetwork) = combined
                
                guard let self else {
                    return 
                }
                
                if userHidWarning {
                    self.showWarning = false
                } else if showReportWarnings && !(noteReports.isEmpty || !authorReports.isEmpty) {
                    self.showWarning = true
                } else if shouldHideOutOfNetwork && showOutOfNetworkWarning && outOfNetwork {
                    self.showWarning = true
                } else {
                    self.showWarning = false
                }
            }
            .store(in: &cancellables)
        
        // Read latest user preferences from user defaults
        showReportWarnings = userDefaults.object(forKey: showReportWarningsKey) as? Bool ?? true
        showOutOfNetworkWarning = userDefaults.object(forKey: showOutOfNetworkWarningKey) as? Bool ?? true
        NotificationCenter.default
            .publisher(for: UserDefaults.didChangeNotification)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                guard let self else {
                    return
                }
                
                showReportWarnings = userDefaults.object(forKey: showReportWarningsKey) as? Bool ?? true
                showOutOfNetworkWarning = userDefaults.object(forKey: showOutOfNetworkWarningKey) as? Bool ?? true
            }
            .store(in: &cancellables)
    }
}

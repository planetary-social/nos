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

@Observable @MainActor final class NoteWarningController {
    
    var showWarning: Bool {
        if userHidWarning {
            return false
        } else if showReportWarnings && (!noteReports.isEmpty || !authorReports.isEmpty) {
            return true
        } else if shouldHideOutOfNetwork && showOutOfNetworkWarning && outOfNetwork {
            return true
        } else {
            return false
        }
    }
    var userHidWarning = false 
    private(set) var outOfNetwork = false
    
    var note: Event? {
        didSet { 
            notePublisher.send(note)
        }
    }
    var shouldHideOutOfNetwork = true
    private var showReportWarnings = true
    private var showOutOfNetworkWarning = true
    
    @ObservationIgnored @Dependency(\.currentUser) var currentUser
    @ObservationIgnored @Dependency(\.persistenceController) var persistenceController
    @ObservationIgnored @Dependency(\.userDefaults) var userDefaults
    
    private(set) var noteReports = [Event]()
    private(set) var authorReports = [Event]()
    private var cancellables = [AnyCancellable]()
    private var noteReportsWatcher: NSFetchedResultsController<Event>?
    private var authorReportsWatcher: NSFetchedResultsController<Event>?
    private var notePublisher = CurrentValueSubject<Event?, Never>(nil)
    
    // swiftlint:disable:next implicitly_unwrapped_optional
    private var objectContext: NSManagedObjectContext!
    
    // This function is too long, I should break it up into nicely named functions.
    // swiftlint:disable:next function_body_length
    init() {
        self.objectContext = persistenceController.viewContext
        
        /// Watch for new reports when the note is set
        notePublisher
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
                        var eventsFromFollowedAuthors = [Event]()
                        for event in events ?? [] where
                        await self.currentUser.socialGraph.follows(event.author?.hexadecimalPublicKey) {
                            eventsFromFollowedAuthors.append(event)
                        }
                        return eventsFromFollowedAuthors
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
                            var eventsFromFollowedAuthors = [Event]()
                            for event in events ?? [] where 
                            await self.currentUser.socialGraph.follows(event.author?.hexadecimalPublicKey) {
                                eventsFromFollowedAuthors.append(event)
                            }
                            return eventsFromFollowedAuthors
                        } 
                        .receive(on: DispatchQueue.main)
                        .sink(receiveValue: { [weak self] followedReports in
                            self?.authorReports = followedReports
                        })
                        .store(in: &self.cancellables)
                }
            }
            .store(in: &cancellables)
        
        notePublisher
            .sink { note in
                Task { @MainActor in 
                    if let authorKey = note?.author?.hexadecimalPublicKey {
                        self.outOfNetwork = await !self.currentUser.socialGraph.isInNetwork(authorKey)
                    } else {
                        self.outOfNetwork = false
                    }
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

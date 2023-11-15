//
//  Persistence.swift
//  Nos
//
//  Created by Matthew Lorentz on 1/31/23.
//

import CoreData
import Logger
import Dependencies

class PersistenceController {
    
    @Dependency(\.currentUser) var currentUser
    
    /// Increment this to delete core data on update
    static let version = 3
    static let versionKey = "NosPersistenceControllerVersion"

    static var preview: PersistenceController = {
        let controller = PersistenceController(inMemory: true)
        let viewContext = controller.container.viewContext
        return controller
    }()
    
    static var empty: PersistenceController = {
        let result = PersistenceController(inMemory: true)
        let viewContext = result.container.viewContext
        return result
    }()
    
    var viewContext: NSManagedObjectContext {
        container.viewContext
    }
    
    /// A context to synchronize creation of Events and Authors so we don't end up with duplicates.
    lazy var creationContext = {
        newBackgroundContext()
    }()
    
    /// A context for parsing Nostr events from relays.
    lazy var parseContext = {
        self.newBackgroundContext()
    }()
    
    /// A context for Views to do expensive queries that we want to keep off the viewContext.
    lazy var backgroundViewContext = {
        self.newBackgroundContext()
    }()
    
    private(set) var container: NSPersistentContainer
    private var model: NSManagedObjectModel
    private var inMemory: Bool

    init(containerName: String = "Nos", inMemory: Bool = false) {
        self.inMemory = inMemory
        let modelURL = Bundle.current.url(forResource: "Nos", withExtension: "momd")!
        model = NSManagedObjectModel(contentsOf: modelURL)!
        container = NSPersistentContainer(name: containerName, managedObjectModel: model)
        setUp()
    }
    
    func setUp() {
        if inMemory {
            container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
        }
        
        loadPersistentStores(from: container)
        
        container.viewContext.automaticallyMergesChangesFromParent = true
        let mergeType = NSMergePolicyType.mergeByPropertyStoreTrumpMergePolicyType
        container.viewContext.mergePolicy = NSMergePolicy(merge: mergeType)
    }
    
    #if DEBUG
    func resetForTesting() {
        container = NSPersistentContainer(name: "Nos", managedObjectModel: model)
        if !inMemory {
            container.loadPersistentStores(completionHandler: { (storeDescription, error) in
                guard let storeURL = storeDescription.url else {
                    Log.error("Could not get store URL")
                    return
                }
                Self.clearCoreData(store: storeURL, in: self.container)
            })
        }
        setUp()
        viewContext.reset()
        creationContext = newBackgroundContext()
        backgroundViewContext = newBackgroundContext()
        parseContext = newBackgroundContext()
    }
    #endif
    
    private func loadPersistentStores(from container: NSPersistentContainer) {
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            
            // Drop database if necessary
            if Self.loadVersionFromDisk() < Self.version {
                guard let storeURL = storeDescription.url else {
                    Log.error("need to delete core data due to version change but could not get store URL")
                    return
                }
                Self.clearCoreData(store: storeURL, in: container)
                Self.saveVersionToDisk(Self.version)
                self.loadPersistentStores(from: container)
                return
            }
            
            if let error = error as NSError? {
                if error.domain == NSCocoaErrorDomain, error.code == 134_110 {
                    Log.error("Could not migrate data model. Did you change the xcdatamodel and forget to make a " +
                        "new version?")
                }
                fatalError("Could not initialize database \(error), \(error.userInfo)")
            }
        })
    }
    
    func saveAll() throws {
        try viewContext.saveIfNeeded()
        try backgroundViewContext.saveIfNeeded()
    }
    
    static func clearCoreData(store storeURL: URL, in container: NSPersistentContainer) {
        Log.info("Dropping Core Data...")
        do {
            try container.persistentStoreCoordinator.destroyPersistentStore(at: storeURL, type: .sqlite)
        } catch {
            fatalError("Could not erase database \(error.localizedDescription)")
        }
    }
    
    func loadSampleData(context: NSManagedObjectContext) async throws {
        guard let sampleFile = Bundle.current.url(forResource: "sample_data", withExtension: "json") else {
            Log.error("Error: bad sample file location")
            return
        }
    
        guard let sampleData = try? Data(contentsOf: sampleFile) else {
            print("Error: Debug data not found")
            return
        }

        Event.deleteAll(context: context)
        context.reset()
        
        guard let events = try? EventProcessor.parse(jsonData: sampleData, from: nil, in: context) else {
            print("Error: Could not parse events")
            return
        }
        
        print("Successfully preloaded \(events.count) events")
        
        let verifiedEvents = Event.all(context: context)
        print("Successfully fetched \(verifiedEvents.count) events")
        
        // Force follow sample data users; This will be wiped if you sync with a relay.
        let authors = Author.all(context: context)
        let follows = try context.fetch(Follow.followsRequest(sources: authors))
        
        if let publicKey = currentUser.publicKeyHex {
            let currentAuthor = try Author.findOrCreate(by: publicKey, context: context)
            currentAuthor.follows = Set(follows)
        }
    }
    
    func newBackgroundContext() -> NSManagedObjectContext {
        let context = container.newBackgroundContext()
        context.automaticallyMergesChangesFromParent = true
        let mergeType = NSMergePolicyType.mergeByPropertyStoreTrumpMergePolicyType
        context.mergePolicy = NSMergePolicy(merge: mergeType)
        return context
    }
    
    static func loadVersionFromDisk() -> Int {
        UserDefaults.standard.integer(forKey: Self.versionKey)
    }
    
    static func saveVersionToDisk(_ newVersion: Int) {
        UserDefaults.standard.set(newVersion, forKey: Self.versionKey)
    }
    
    var cleanupTask: Task<Void, Error>?
    
    // swiftlint:disable function_body_length 
    
    /// Deletes unneeded entities from Core Data.
    /// The general strategy here is to:
    /// - keep some max number of events, delete the others 
    /// - delete authors outside the user's network 
    /// - delete any other models that are orphaned by the previous deletions
    /// - fix EventReferences whose referencedEvent was deleted by createing a stubbed Event
    @MainActor func cleanupEntities() {
        return
        // this function was written in a hurry and probably should be refactored and tested thorougly.
        guard cleanupTask == nil else {
            Log.info("Core Data cleanup task already running. Aborting.")
            return
        }
        
        guard let authorKey = currentUser.author?.hexadecimalPublicKey else {
            return
        }
        
        cleanupTask = Task {
            defer { self.cleanupTask = nil }
            let context = parseContext
            let startTime = Date.now
            Log.info("Starting Core Data cleanup...")
            
            Log.info("Database statistics: \(try databaseStatistics(from: context).sorted(by: { $0.key < $1.key }))")
            
            // Delete all but the most recent n events
            let eventsToKeep = 1000
            let fetchFirstEventToDelete = Event.allEventsRequest()
            fetchFirstEventToDelete.sortDescriptors = [NSSortDescriptor(keyPath: \Event.receivedAt, ascending: false)]
            fetchFirstEventToDelete.fetchLimit = 1
            fetchFirstEventToDelete.fetchOffset = eventsToKeep
            fetchFirstEventToDelete.predicate = NSPredicate(format: "receivedAt != nil")
            var deleteBefore = Date.distantPast
            try await context.perform {
                
                guard let currentAuthor = try? Author.find(by: authorKey, context: context) else {
                    return
                }
                
                if let firstEventToDelete = try context.fetch(fetchFirstEventToDelete).first,
                    let receivedAt = firstEventToDelete.receivedAt {
                    deleteBefore = receivedAt
                }
                   
                // Delete events older than `deleteBefore`
                let oldEventsRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Event")
                oldEventsRequest.sortDescriptors = [NSSortDescriptor(keyPath: \Event.receivedAt, ascending: true)]
                oldEventsRequest.predicate = NSPredicate(
                    format: "(receivedAt <= %@ OR receivedAt == nil) AND (author.hexadecimalPublicKey != %@)", 
                    deleteBefore as CVarArg,
                    authorKey
                )
                
                let deleteRequests: [NSPersistentStoreRequest] = [
                    oldEventsRequest,
                    Event.expiredRequest(),
                    EventReference.orphanedRequest(),
                    AuthorReference.orphanedRequest(),
                    Author.outOfNetwork(for: currentAuthor),
                    Follow.orphanedRequest(),
                    Relay.orphanedRequest(),
                    // TODO: delete old notifications
                ]
                
                for request in deleteRequests {
                    guard let fetchRequest = request as? NSFetchRequest<any NSFetchRequestResult> else {
                        Log.error("Bad fetch request: \(request)")
                        continue
                    }
                    
                    let batchDeleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
                    batchDeleteRequest.resultType = .resultTypeCount
                    let deleteResult = try context.execute(batchDeleteRequest) as? NSBatchDeleteResult
                    if let entityName = fetchRequest.entityName {
                        Log.info("Deleted \(deleteResult?.result ?? 0) of type \(entityName)")
                    }
                }
                
                // Heal EventReferences
                let brokenEventReferencesRequest = NSFetchRequest<EventReference>(entityName: "EventReference")
                brokenEventReferencesRequest.sortDescriptors = [
                    NSSortDescriptor(keyPath: \EventReference.eventId, ascending: false)
                ]
                brokenEventReferencesRequest.predicate = NSPredicate(format: "referencedEvent = nil")
                let brokenEventReferences = try context.fetch(brokenEventReferencesRequest)
                Log.info("Healing \(brokenEventReferences.count) EventReferences")
                for eventReference in brokenEventReferences {
                    guard let eventID = eventReference.eventId else {
                        Log.error("Found an EventReference with no eventID")
                        continue
                    }
                    let referencedEvent = try Event.findOrCreateStubBy(id: eventID, context: context)
                    eventReference.referencedEvent = referencedEvent
                }
                
                try context.saveIfNeeded()
                context.refreshAllObjects()
            }
            
            Log.info("Database statistics: \(try databaseStatistics(from: context).sorted(by: { $0.key < $1.key }))")
            
            let elapsedTime = Date.now.timeIntervalSince1970 - startTime.timeIntervalSince1970 
            Log.info("Finished Core Data cleanup in \(elapsedTime) seconds.")
        }
    }
    // swiftlint:enable function_body_length 
    
    func databaseStatistics(from context: NSManagedObjectContext) throws -> [String: Int] {
        var statistics = [String: Int]()
        if let managedObjectModel = context.persistentStoreCoordinator?.managedObjectModel {
            let entitiesByName = managedObjectModel.entitiesByName
            
            for entityName in entitiesByName.keys {
                let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: entityName)
                let count = try context.performAndWait {
                    try context.count(for: fetchRequest)
                }
                statistics[entityName] = count
            }
        }
        
        return statistics
    }
}

import CoreData
import Logger
import Dependencies
import BackgroundTasks

final class PersistenceController {
    
    @Dependency(\.currentUser) var currentUser
    @Dependency(\.crashReporting) var crashReporting
    
    /// Increment this to delete core data on update
    private static let version = 3
    private static let versionKey = "NosPersistenceControllerVersion"
    private static let createdNosNotifications = "CreatedNosNotifications"

    static var preview: PersistenceController = {
        let controller = PersistenceController(inMemory: true)
        let viewContext = controller.viewContext
        return controller
    }()
    
    static var empty: PersistenceController = {
        let result = PersistenceController(inMemory: true)
        let viewContext = result.viewContext
        return result
    }()
    
    var viewContext: NSManagedObjectContext {
        container.viewContext
    }
    
    /// A context for parsing Nostr events from relays.
    private(set) lazy var parseContext = newBackgroundContext()
    
    /// A context for Views to do expensive queries that we want to keep off the viewContext.
    private(set) lazy var backgroundViewContext = newBackgroundContext()

    var sqliteURL: URL? {
        container.persistentStoreDescriptions.first?.url
    }

    private(set) var container: NSPersistentContainer
    private let model: NSManagedObjectModel
    private let inMemory: Bool
    private var recreateNosNotifications: Bool {
        get {
            UserDefaults.standard.bool(forKey: Self.createdNosNotifications)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: Self.createdNosNotifications)
        }
    }

    init(containerName: String = "Nos", inMemory: Bool = false, erase: Bool = false) {
        self.inMemory = inMemory
        let modelURL = Bundle.current.url(forResource: "Nos", withExtension: "momd")!
        model = NSManagedObjectModel(contentsOf: modelURL)!
        container = NSPersistentContainer(name: containerName, managedObjectModel: model)
        setUp(erasingPrevious: erase)

        if !recreateNosNotifications {
            Task {
                let context = newBackgroundContext()
                try await DatabaseCleaner.deleteNotificationsAndEvents(in: context)
                recreateNosNotifications = true
            }
        }
    }
    
    private func setUp(erasingPrevious: Bool) {
        if inMemory {
            container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
        } 
        
        loadPersistentStores(from: container, erasingPrevious: erasingPrevious)
        
        viewContext.automaticallyMergesChangesFromParent = true
        viewContext.mergePolicy = NSMergePolicy.mergeByPropertyStoreTrump
    }
    
    private func loadPersistentStores(from container: NSPersistentContainer, erasingPrevious: Bool) {
        container.loadPersistentStores { storeDescription, error in
            
            // Drop database if necessary
            if Self.loadVersionFromDisk() < Self.version || erasingPrevious {
                guard let storeURL = storeDescription.url else {
                    Log.error("need to delete core data due to version change but could not get store URL")
                    return
                }
                Self.clearCoreData(store: storeURL, in: container)
                Self.saveVersionToDisk(Self.version)
                self.loadPersistentStores(from: container, erasingPrevious: false)
                return
            }
            
            if let error = error as NSError? {
                if error.domain == NSCocoaErrorDomain, error.code == 134_110 {
                    Log.error("Could not migrate data model. Did you change the xcdatamodel and forget to make a " +
                        "new version?")
                }
                fatalError("Could not initialize database \(error), \(error.userInfo)")
            }
        }
    }
    
    @MainActor
    func saveAll() async throws {
        try viewContext.saveIfNeeded()
        try await backgroundViewContext.perform {
            try self.backgroundViewContext.saveIfNeeded()
        }
    }
    
    /// Deletes all entities in this object's container.
    func deleteAll() async throws {
        await container.deleteAllEntities()
    }
    
    private static func clearCoreData(store storeURL: URL, in container: NSPersistentContainer) {
        Log.info("Dropping Core Data...")
        do {
            try container.persistentStoreCoordinator.destroyPersistentStore(at: storeURL, type: .sqlite)
        } catch {
            fatalError("Could not erase database \(error.localizedDescription)")
        }
    }
    
    func newBackgroundContext() -> NSManagedObjectContext {
        let context = container.newBackgroundContext()
        context.automaticallyMergesChangesFromParent = true
        context.mergePolicy = NSMergePolicy.mergeByPropertyStoreTrump
        return context
    }
    
    private static func loadVersionFromDisk() -> Int {
        UserDefaults.standard.integer(forKey: Self.versionKey)
    }
    
    private static func saveVersionToDisk(_ newVersion: Int) {
        UserDefaults.standard.set(newVersion, forKey: Self.versionKey)
    }
}

// MARK: - Maintenance & Cleanup

extension PersistenceController {
    
    /// The ID of the background task that runs the `DatabaseCleaner`. Needs to match the value in Info.plist.
    static let cleanupBackgroundTaskID = "com.verse.nos.database-cleaner"
    
    /// Cleans up unneeded entities from the database. Our local database is really just a cache, and we need to
    /// invalidate old items to keep it from growing indefinitely.
    /// 
    /// This should only be called once right at app launch.
    @MainActor func cleanupEntities() async {
        guard let authorKey = currentUser.author?.hexadecimalPublicKey else {
            return
        }
        
        let context = newBackgroundContext()
        do {
            try await DatabaseCleaner.cleanupEntities(for: authorKey, in: context)
        } catch {
            Log.optional(error)
            crashReporting.report("Error in database cleanup: \(error.localizedDescription)")
        }
    }
    
    /// Tells iOS to wake our app up in the background to run `cleanupEntities()` periodically. This tends to run 
    /// once a day when the device is connected to power.
    func scheduleBackgroundCleanupTask() {
        @Dependency(\.analytics) var analytics
        @Dependency(\.crashReporting) var crashReporting
        let scheduler = BGTaskScheduler.shared
        
        scheduler.register(forTaskWithIdentifier: Self.cleanupBackgroundTaskID, using: nil) { task in
            
            task.expirationHandler = {
                analytics.databaseCleanupTaskExpired()
            }
            
            Task {
                await self.cleanupEntities()
                task.setTaskCompleted(success: true)
            }
        } 
        
        let request = BGProcessingTaskRequest(identifier: Self.cleanupBackgroundTaskID)
        request.requiresNetworkConnectivity = false  
        request.requiresExternalPower = false
        
        do {
            try scheduler.submit(request)
        } catch {
            crashReporting.report("Unable to schedule background task: \(error)")
        }
    }
    
    static func databaseStatistics(from context: NSManagedObjectContext) async throws -> [(String, Int)] {
        try await context.perform { 
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
            
            return statistics.sorted(by: { $0.key < $1.key })
        }
    }
}

// MARK: - Testing & Debug

#if DEBUG
extension PersistenceController {
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
    
    func resetForTesting() {
        container = NSPersistentContainer(name: "Nos", managedObjectModel: model)
        if !inMemory {
            container.loadPersistentStores(completionHandler: { (storeDescription, _) in
                guard let storeURL = storeDescription.url else {
                    Log.error("Could not get store URL")
                    return
                }
                Self.clearCoreData(store: storeURL, in: self.container)
            })
        }
        setUp(erasingPrevious: true)
        viewContext.reset()
        backgroundViewContext.reset()
        parseContext.reset()
    }
}
#endif

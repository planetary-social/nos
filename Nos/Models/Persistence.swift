//
//  Persistence.swift
//  Nos
//
//  Created by Matthew Lorentz on 1/31/23.
//

import CoreData
import Logger

struct PersistenceController {
    static let shared = PersistenceController()
    
    /// Increment this to delete core data on update
    static let version = 1
    static let versionKey = "NosPersistenceControllerVersion"

    // swiftlint:disable force_try
    static var preview: PersistenceController = {
        let controller = PersistenceController(inMemory: true)
        let viewContext = controller.container.viewContext
        Task {
            await PersistenceController.loadSampleData(context: viewContext)
            try! viewContext.save()
        }
        return controller
    }()
    // swiftlint:enable force_try
    
    static var empty: PersistenceController = {
        let result = PersistenceController(inMemory: true)
        let viewContext = result.container.viewContext
        return result
    }()
    
    var viewContext: NSManagedObjectContext {
        container.viewContext
    }
    
    static var backgroundViewContext = {
        PersistenceController.shared.newBackgroundContext()
    }()
    
    var container: NSPersistentContainer

    init(inMemory: Bool = false) {
        let modelURL = Bundle.current.url(forResource: "Nos", withExtension: "momd")!
        container = NSPersistentContainer(
            name: "Nos",
            managedObjectModel: NSManagedObjectModel(contentsOf: modelURL)!
        )
        if inMemory {
            container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
        }
        
        var needsReload = false
        container.loadPersistentStores(completionHandler: { [container] (storeDescription, error) in
            
            if Self.loadVersionFromDisk() < Self.version {
                guard let storeURL = storeDescription.url else {
                    Log.error("need to delete core data due to version change but could not get store URL")
                    return
                }
                Self.clearCoreData(store: storeURL, in: container)
                needsReload = true
                Self.saveVersionToDisk(Self.version)
            }
            
            if let error = error as NSError? {
                if error.domain == NSCocoaErrorDomain, error.code == 134_110 {
                    Log.error("Could not migrate data model. Did you change the xcdatamodel and forget to make a " +
                        "new version?")
                }
                fatalError("Could not initialize database \(error), \(error.userInfo)")
            }
        })
        
        container.viewContext.automaticallyMergesChangesFromParent = true
        let mergeType = NSMergePolicyType.mergeByPropertyObjectTrumpMergePolicyType
        container.viewContext.mergePolicy = NSMergePolicy(merge: mergeType)
        
        if needsReload {
            self = PersistenceController(inMemory: inMemory)
        }
    }
    
    static func clearCoreData(store storeURL: URL, in container: NSPersistentContainer) {
        Log.info("Dropping Core Data...")
        do {
            try container.persistentStoreCoordinator.destroyPersistentStore(at: storeURL, type: .sqlite)
        } catch {
            fatalError("Could not erase database \(error.localizedDescription)")
        }
    }
    
    static func loadSampleData(context: NSManagedObjectContext) async {
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
        let follows = try! context.fetch(Follow.followsRequest(sources: authors))
        
        if let publicKey = CurrentUser.shared.publicKeyHex {
            let currentAuthor = try! Author.findOrCreate(by: publicKey, context: context)
            currentAuthor.follows = NSSet(array: follows)
        }
    }
    
    func newBackgroundContext() -> NSManagedObjectContext {
        let context = container.newBackgroundContext()
        context.automaticallyMergesChangesFromParent = true
        let mergeType = NSMergePolicyType.mergeByPropertyObjectTrumpMergePolicyType
        context.mergePolicy = NSMergePolicy(merge: mergeType)
        return context
    }
    
    static func loadVersionFromDisk() -> Int {
        UserDefaults.standard.integer(forKey: Self.versionKey)
    }
    
    static func saveVersionToDisk(_ newVersion: Int) {
        UserDefaults.standard.set(newVersion, forKey: Self.versionKey)
    }
}

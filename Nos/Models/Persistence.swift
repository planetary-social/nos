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

    // swiftlint:disable force_try
    static var preview: PersistenceController = {
        let controller = PersistenceController(inMemory: true)
        let viewContext = controller.container.viewContext
        PersistenceController.loadSampleData(context: viewContext)
        
        do {
            try viewContext.save()
        } catch {
            // Replace this implementation with code to handle the error appropriately.
            // fatalError() causes the application to generate a crash log and terminate. You should not use this
            // function in a shipping application, although it may be useful during development.
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
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
            
            if let error = error as NSError? {
                if error.domain == NSCocoaErrorDomain, error.code == 134_110, let storeURL = storeDescription.url {
                    // The data model changed. Clear core data.
                    do {
                        try container.persistentStoreCoordinator.destroyPersistentStore(at: storeURL, type: .sqlite)
                        needsReload = true
                    } catch {
                        fatalError("Could not erase database \(error.localizedDescription)")
                    }
                } else {
                    fatalError("Could not initialize database \(error), \(error.userInfo)")
                }
            }
        })
        
        container.viewContext.automaticallyMergesChangesFromParent = true
        let mergeType = NSMergePolicyType.mergeByPropertyObjectTrumpMergePolicyType
        container.viewContext.mergePolicy = NSMergePolicy(merge: mergeType)
        
        if needsReload {
            self = PersistenceController(inMemory: inMemory)
        }
    }
    
    static func loadSampleData(context: NSManagedObjectContext) {
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
        
        guard let events = try? EventProcessor.parse(jsonData: sampleData, in: context) else {
            print("Error: Could not parse events")
            return
        }
        
        print("Successfully preloaded \(events.count) events")
        
        let verifiedEvents = Event.all(context: context)
        print("Successfully fetched \(verifiedEvents.count) events")
        
        // Force follow sample data users; This will be wiped if you sync with a relay.
        let authors = Author.all(context: context)
        let follows = try! context.fetch(Follow.followsRequest(sources: authors))
        
        if let publicKey = CurrentUser.shared.publicKey {
            let currentAuthor = try! Author.findOrCreate(by: publicKey, context: context)
            // swiftlint:disable legacy_objc_type
            currentAuthor.follows = NSSet(array: follows)
            // swiftlint:enable legacy_objc_type
        }
    }
    
    func newBackgroundContext() -> NSManagedObjectContext {
        container.newBackgroundContext()
    }
}

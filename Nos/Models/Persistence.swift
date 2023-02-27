//
//  Persistence.swift
//  Nos
//
//  Created by Matthew Lorentz on 1/31/23.
//

import CoreData

struct PersistenceController {
    static let shared = PersistenceController()

    // swiftlint:disable force_try
    static var preview: PersistenceController = {
        let result = PersistenceController(inMemory: true)
        let viewContext = result.container.viewContext
        let sampleData = try! Data(contentsOf: Bundle.current.url(forResource: "sample_data", withExtension: "json")!)
        try! _ = EventProcessor.parse(jsonData: sampleData, in: result)
        let relay = Relay(context: viewContext)
        relay.address = "wss://dev-relay.nos.social"
        
        do {
            try viewContext.save()
        } catch {
            // Replace this implementation with code to handle the error appropriately.
            // fatalError() causes the application to generate a crash log and terminate. You should not use this
            // function in a shipping application, although it may be useful during development.
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
        return result
    }()
    // swiftlint:enable force_try
    
    static var empty: PersistenceController = {
        let result = PersistenceController(inMemory: true)
        let viewContext = result.container.viewContext
        return result
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
        
        if needsReload {
            self = PersistenceController(inMemory: inMemory)
        }
    }
}

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
        let controller = PersistenceController(inMemory: true)
        let viewContext = controller.container.viewContext
        PersistenceController.loadSampleData()
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
        return controller
    }()
    // swiftlint:enable force_try
    
    static var empty: PersistenceController = {
        let result = PersistenceController(inMemory: true)
        let viewContext = result.container.viewContext
        return result
    }()

    let container: NSPersistentContainer

    init(inMemory: Bool = false) {
        let modelURL = Bundle.current.url(forResource: "Nos", withExtension: "momd")!
        container = NSPersistentContainer(name: "Nos", managedObjectModel: NSManagedObjectModel(contentsOf: modelURL)!)
        if inMemory {
            container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
        }
        container.loadPersistentStores(completionHandler: { (_, error) in
            if let error = error as NSError? {
                // swiftlint:disable indentation_width line_length
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this
                // function in a shipping application, although it may be useful during development.

                /*
                 Typical reasons for an error here include:
                 * The parent directory does not exist, cannot be created, or disallows writing.
                 * The persistent store is not accessible, due to permissions or data protection when the device is locked.
                 * The device is out of space.
                 * The store could not be migrated to the current model version.
                 Check the error message to determine what the actual problem was.
                 */
                // swiftlint:enable indentation_width line_length
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        container.viewContext.automaticallyMergesChangesFromParent = true
    }
    
    static func loadSampleData() {
        guard let sampleFile = Bundle.current.url(forResource: "sample_data", withExtension: "json") else {
            print("Error: bad sample file location")
            return
        }
    
        guard let sampleData = try? Data(contentsOf: sampleFile) else {
            print("Error: Debug data not found")
            return
        }
        
        let controller = PersistenceController(inMemory: true)
        
        guard let events = try? EventProcessor.parse(jsonData: sampleData, in: controller) else {
            print("Error: Could not parse events")
            return
        }
        
        print("Successfully preloaded \(events.count) events")
        
        // Force follow the user in the sample data, so we see posts on the home feed
        let controller = PersistenceController(inMemory: true)
        let viewContext = controller.container.viewContext
        let sampleKey = "d0a1ffb8761b974cec4a3be8cbcb2e96a7090dcf465ffeac839aa4ca20c9a59e"
        if let sampleFollow = try? Follow.findOrCreate(by: sampleKey, context: viewContext) {
            CurrentUser.follows = [sampleFollow]
        }
    }
}

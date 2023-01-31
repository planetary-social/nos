//
//  NosApp.swift
//  Nos
//
//  Created by Matthew Lorentz on 1/31/23.
//

import SwiftUI

@main
struct NosApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}

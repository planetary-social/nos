//
//  NosApp.swift
//  Nos
//
//  Created by Matthew Lorentz on 1/31/23.
//

import SwiftUI

@main
struct NosApp: App {
    
    @ObservedObject var router = Router()
    let persistenceController = PersistenceController.shared
    let relayService = RelayService(persistenceController: PersistenceController.shared)
    let currentUser = CurrentUser.shared

    var body: some Scene {
        WindowGroup {
            AppView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .environmentObject(relayService)
                .environmentObject(router)
                .environmentObject(AppController(currentUser: currentUser, router: router))
                .environmentObject(currentUser)
                .task {
                    currentUser.relayService = relayService
                }
        }
    }
}

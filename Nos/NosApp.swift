//
//  NosApp.swift
//  Nos
//
//  Created by Matthew Lorentz on 1/31/23.
//

import SwiftUI
import Logger
import Dependencies

private enum CurrentUserKey: DependencyKey {
    static let liveValue = CurrentUser.shared
    static let testValue = CurrentUser.shared
    static let previewValue = CurrentUser.shared
}

extension DependencyValues {
    var currentUser: CurrentUser {
        get { self[CurrentUserKey.self] }
        set { self[CurrentUserKey.self] = newValue }
    }
}

private enum RouterKey: DependencyKey {
    static let liveValue = Router()
    static let testValue = Router()
    static let previewValue = Router()
}

extension DependencyValues {
    var router: Router {
        get { self[RouterKey.self] }
        set { self[RouterKey.self] = newValue }
    }
}

private enum RelayServiceKey: DependencyKey {
    static let liveValue = RelayService(persistenceController: PersistenceController.shared)
    static let testValue = RelayService(persistenceController: PersistenceController.shared)
    static let previewValue = RelayService(persistenceController: PersistenceController.shared)
}

extension DependencyValues {
    var relayService: RelayService {
        get { self[RelayServiceKey.self] }
        set { self[RelayServiceKey.self] = newValue }
    }
}

@main
struct NosApp: App {
    
    let persistenceController = PersistenceController.shared
    @Dependency(\.relayService) private var relayService
    @Dependency(\.router) private var router
    @Dependency(\.currentUser) private var currentUser
    private let appController = AppController()
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            AppView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .environmentObject(relayService)
                .environmentObject(router)
                .environmentObject(appController)
                .environmentObject(currentUser)
                .task {
                    currentUser.relayService = relayService
                    await relayService.publishFailedEvents()
                }
                .onChange(of: scenePhase) { newPhase in
                    // TODO: save all contexts, not just the view and background.
                    if newPhase == .inactive {
                        Log.info("Scene change: inactive")
                        try? persistenceController.saveAll()
                    } else if newPhase == .active {
                        Log.info("Scene change: active")
                    } else if newPhase == .background {
                        Log.info("Scene change: background")
                        try? persistenceController.saveAll()
                    }
                }
        }
    }
}

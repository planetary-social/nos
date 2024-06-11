import SwiftUI
import Logger
import Dependencies

@main
struct NosApp: App {
    
    @Dependency(\.crashReporting) private var crashReporting
    @Dependency(\.persistenceController) private var persistenceController
    @Dependency(\.relayService) private var relayService
    @Dependency(\.router) private var router
    @Dependency(\.currentUser) private var currentUser
    @Dependency(\.pushNotificationService) private var pushNotificationService
    private let appController = AppController()
    @Environment(\.scenePhase) private var scenePhase
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    init() {
        _ = crashReporting // force crash reporting init as early as possible
    }
    
    var body: some Scene {
        WindowGroup {
            AppView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .environmentObject(relayService)
                .environmentObject(router)
                .environment(appController)
                .environment(currentUser)
                .environmentObject(pushNotificationService)
                .onOpenURL { DeepLinkService.handle($0, router: router) }
                .task {
                    await persistenceController.cleanupEntities()
                }
                .onChange(of: scenePhase) { _, newPhase in
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

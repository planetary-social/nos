import SwiftUI
import Logger
import Dependencies

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
        
        // hack to fix confirmationDialog color issue
        // https://github.com/planetary-social/nos/issues/1064
        UIView.appearance(whenContainedInInstancesOf: [UIAlertController.self]).tintColor = .systemBlue
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
                .onChange(of: scenePhase) { _, newPhase in
                    switch newPhase {
                    case .inactive:
                        Log.info("Scene change: inactive")
                    case .active:
                        Log.info("Scene change: active")
                    case .background:
                        Log.info("Scene change: background")
                        Task {
                            // TODO: save all contexts, not just the view and background.
                            try await persistenceController.saveAll()
                        }
                    @unknown default:
                        Log.info("Scene change: unknown type")
                    }
                }
        }
    }
}

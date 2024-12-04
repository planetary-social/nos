import SwiftUI
import Dependencies

struct AppView: View {

    @State var showNewPost = false
    @State var newPostContents: String?

    @Environment(AppController.self) var appController
    @EnvironmentObject private var router: Router
    @Environment(PushNotificationService.self) private var pushNotificationService
    @Dependency(\.analytics) private var analytics
    @Dependency(\.crashReporting) private var crashReporting
    @Dependency(\.userDefaults) private var userDefaults
    @Environment(CurrentUser.self) var currentUser
    @Environment(RelayService.self) private var relayService

    @State private var lastSelectedTab = AppDestination.home
    @State private var showNIP05Wizard = false

    var body: some View {
        ZStack {
            switch appController.currentState {
            case .loading:
                SplashScreenView()
                    .ignoresSafeArea()
            case .onboarding:
                OnboardingView(completion: appController.completeOnboarding)
            case .loggedIn:
                tabView

                SideMenu(
                    menuWidth: 300,
                    menuOpened: router.sideMenuOpened,
                    toggleMenu: router.toggleSideMenu,
                    closeMenu: router.closeSideMenu
                )
            }
        }
        .onAppear(perform: appController.configureCurrentState)
        .task {
            UITabBar.appearance().unselectedItemTintColor = .secondaryTxt
            UITabBar.appearance().tintColor = .primaryTxt
        }
        .sheet(isPresented: $showNIP05Wizard) {
            CreateUsernameWizard(isPresented: $showNIP05Wizard)
        }
        .task { await presentNIP05SheetIfNeeded() }
        .tint(.primaryTxt)
    }

    private var tabView: some View {
        TabBarController(selectedIndex: $router.selectedTab, viewControllers: makeViewControllers())
            .onChange(of: router.selectedTab) { _, newTab in
                if case let AppDestination.noteComposer(contents) = newTab {
                    newPostContents = contents
                    showNewPost = true
                    router.selectedTab = lastSelectedTab
                } else if !showNewPost {
                    lastSelectedTab = newTab
                }
            }
            .overlay {
                if router.isLoading {
                    ZStack {
                        Rectangle().fill(.black.opacity(0.4))
                        ProgressView()
                    }
                }
            }
            .sheet(isPresented: $showNewPost) {
                NoteComposer(initialContents: newPostContents, isPresented: $showNewPost)
                    .environment(currentUser)
                    .environment(relayService)
                    .interactiveDismissDisabled()
            }
            .ignoresSafeArea()
    }

    private func makeViewControllers() -> [UIViewController] {
        guard let author = currentUser.author else { return [] }

        var controllers: [UIViewController] = []

        let homeVC = UIHostingController(rootView: HomeTab(user: author)
            .onAppear {
                if let keyPair = currentUser.keyPair {
                    analytics.identify(
                        with: keyPair,
                        nip05: currentUser.author?.nip05
                    )
                    crashReporting.identify(with: keyPair)
                }
            })
        homeVC.tabBarItem = UITabBarItem(
            title: String(localized: "homeFeed"),
            image: UIImage.tabIconHome,
            selectedImage: UIImage.tabIconHomeSelected
        )
        controllers.append(homeVC)

        let discoverVC = UIHostingController(rootView: DiscoverTab())
        discoverVC.tabBarItem = UITabBarItem(
            title: String(localized: "discover"),
            image: UIImage.tabIconEveryone,
            selectedImage: UIImage.tabIconEveryoneSelected
        )
        controllers.append(discoverVC)

        let composerVC = UIViewController()
        composerVC.tabBarItem = UITabBarItem(
            title: String(localized: "post"),
            image: UIImage.newPostButton,
            selectedImage: UIImage.newPostButton
        )
        controllers.append(composerVC)

        let notificationsVC = UIHostingController(rootView: NotificationsView(user: currentUser.author))
        notificationsVC.tabBarItem = UITabBarItem(
            title: String(localized: "notifications"),
            image: UIImage.tabIconNotifications,
            selectedImage: UIImage.tabIconNotificationsSelected
        )
        notificationsVC.tabBarItem.badgeValue =
        pushNotificationService.badgeCount > 0 ? "\(pushNotificationService.badgeCount)" : nil
        controllers.append(notificationsVC)

        let profileVC = UIHostingController(rootView: ProfileTab(author: author, path: $router.profilePath))
        profileVC.tabBarItem = UITabBarItem(
            title: String(localized: "profileTitle"),
            image: UIImage.tabProfile,
            selectedImage: UIImage.tabProfileSelected
        )
        controllers.append(profileVC)

        return controllers
    }
}

extension AppView {

    private func presentNIP05SheetIfNeeded() async {
        guard let author = currentUser.author, let npub = author.npubString else {
            return
        }

        // Sleep for half a second to allow the app to initialize
        try? await Task.sleep(nanoseconds: 500_000_000)

        guard currentUser.author?.needsMetadata == false else {
            // We don't have metadata for this author, the app is still probably fetching .metaData events from the
            // relays. Let's wait for next time.
            return
        }

        // We store the npub for the user we last presented the sheet for so that
        // the behavior resets if the user creates a new account
        let key = "didPresentNIP05SheetForNpub"
        let didPresentSheetForNpub = userDefaults.string(forKey: key)
        let shouldShowSheet: Bool
        if let didPresentSheetForNpub {
            shouldShowSheet = didPresentSheetForNpub != npub && author.nip05 == nil
        } else {
            shouldShowSheet = author.nip05 == nil
        }
        if shouldShowSheet {
            showNIP05Wizard = true
            userDefaults.setValue(npub, forKey: key)
        }
    }
}

struct AppView_Previews: PreviewProvider {
    
    static var previewData = PreviewData()
    static var persistenceController = PersistenceController.preview
    static var previewContext = persistenceController.viewContext
    static var relayService = previewData.relayService
    static var router = Router()
    static var currentUser = previewData.currentUser 
    static var pushNotificationService = DependencyValues().pushNotificationService

    static var loggedInAppController: AppController = {
        let appController = AppController()
        appController.completeOnboarding()
        return appController
    }()
    
    static var routerWithSideMenuOpened: Router = {
        let router = Router()
        router.toggleSideMenu()
        return router
    }()
    
    static var previews: some View {
        AppView()
            .environment(\.managedObjectContext, previewContext)
            .environment(relayService)
            .environmentObject(router)
            .environment(loggedInAppController)
            .environment(currentUser)
            .environment(pushNotificationService)

        AppView()
            .environment(\.managedObjectContext, previewContext)
            .environment(relayService)
            .environmentObject(router)
            .environment(AppController())
            .environment(currentUser)
            .environment(pushNotificationService)

        AppView()
            .environment(\.managedObjectContext, previewContext)
            .environment(relayService)
            .environmentObject(routerWithSideMenuOpened)
            .environment(AppController())
            .environment(currentUser)
            .environment(pushNotificationService)
    }
}

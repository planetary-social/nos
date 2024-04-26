import SwiftUI
import Dependencies

struct AppView: View {

    @State var showNewPost = false
    @State var newPostContents: String? 

    @Environment(AppController.self) var appController
    @EnvironmentObject private var router: Router
    @EnvironmentObject var pushNotificationService: PushNotificationService
    @Dependency(\.analytics) private var analytics
    @Dependency(\.crashReporting) private var crashReporting
    @Dependency(\.userDefaults) private var userDefaults
    @Environment(CurrentUser.self) var currentUser
    
    @State private var lastSelectedTab = AppDestination.home
    @State private var showNIP05Wizard = false

    var body: some View {
        ZStack {
            if appController.currentState == .onboarding {
                OnboardingView(completion: appController.completeOnboarding)
            } else {
                TabView(selection: $router.selectedTab) {
                    if let author = currentUser.author {
                        HomeTab(user: author)
                            .tabItem {
                                VStack {
                                    let text = Text(.localizable.homeFeed)
                                    if $router.selectedTab.wrappedValue == .home {
                                        Image.tabIconHomeSelected
                                        text
                                    } else {
                                        Image.tabIconHome
                                        text.foregroundColor(.secondaryTxt)
                                    }
                                }
                            }
                            .toolbarBackground(.visible, for: .tabBar)
                            .toolbarBackground(Color.cardBgBottom, for: .tabBar)
                            .tag(AppDestination.home)
                            .onAppear {
                                // TODO: Move this somewhere better like CurrentUser when it becomes the source of truth
                                // for who is logged in
                                if let keyPair = currentUser.keyPair {
                                    analytics.identify(with: keyPair)
                                    crashReporting.identify(with: keyPair)
                                }
                            }
                    }
                    
                    DiscoverTab()
                        .tabItem {
                            VStack {
                                let text = Text(.localizable.discover)
                                if $router.selectedTab.wrappedValue == .discover {
                                    Image.tabIconEveryoneSelected
                                    text.foregroundColor(.primaryTxt)
                                } else {
                                    Image.tabIconEveryone
                                    text.foregroundColor(.secondaryTxt)
                                }
                            }
                        }
                        .toolbarBackground(.visible, for: .tabBar)
                        .toolbarBackground(Color.cardBgBottom, for: .tabBar)
                        .tag(AppDestination.discover)
                    
                    VStack {}
                        .tabItem {
                            VStack {
                                Image.newPostButton
                                Text(.localizable.post)
                            }
                        }
                    .tag(AppDestination.newNote(nil))
                    
                    NotificationsView(user: currentUser.author)
                        .tabItem {
                            VStack {
                                let text = Text(.localizable.notifications)
                                if $router.selectedTab.wrappedValue == .notifications {
                                    Image.tabIconNotificationsSelected
                                    text.foregroundColor(.primaryTxt)
                                } else {
                                    Image.tabIconNotifications
                                    text.foregroundColor(.secondaryTxt)
                                }
                            }
                        }
                        .toolbarBackground(.visible, for: .tabBar)
                        .toolbarBackground(Color.cardBgBottom, for: .tabBar)
                        .tag(AppDestination.notifications)
                        .badge(pushNotificationService.badgeCount)
                    
                    if let author = currentUser.author {
                        ProfileTab(author: author, path: $router.profilePath)
                            .tabItem {
                                VStack {
                                    let text = Text(.localizable.profileTitle)
                                    if $router.selectedTab.wrappedValue == .profile {
                                        Image.tabProfileSelected
                                        text.foregroundColor(.primaryTxt)
                                    } else {
                                        Image.tabProfile
                                        text.foregroundColor(.secondaryTxt)
                                    }
                                }
                            }
                            .toolbarBackground(.visible, for: .tabBar)
                            .toolbarBackground(Color.cardBgBottom, for: .tabBar)
                            .tag(AppDestination.profile)
                    }
                }
                .onChange(of: router.selectedTab) { _, newTab in
                    if case let AppDestination.newNote(contents) = newTab {
                        newPostContents = contents
                        showNewPost = true
                        router.selectedTab = lastSelectedTab
                    } else if !showNewPost {
                        lastSelectedTab = newTab
                    }
                }
                .sheet(isPresented: $showNewPost, content: {
                    NewNoteView(initialContents: newPostContents, isPresented: $showNewPost)
                        .environment(currentUser)
                })
                
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

    private func presentNIP05SheetIfNeeded() async {
        // Sleep for half a second
        try? await Task.sleep(nanoseconds: 500_000_000)
        guard let author = currentUser.author, let npub = author.npubString else {
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
    static var previewContext = persistenceController.container.viewContext
    static var relayService = previewData.relayService
    static var router = Router()
    static var currentUser = previewData.currentUser 
    
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
            .environmentObject(relayService)
            .environmentObject(router)
            .environment(loggedInAppController)
        
        AppView()
            .environment(\.managedObjectContext, previewContext)
            .environmentObject(relayService)
            .environmentObject(router)
            .environment(AppController())
        
        AppView()
            .environment(\.managedObjectContext, previewContext)
            .environmentObject(relayService)
            .environmentObject(routerWithSideMenuOpened)
            .environment(AppController())
    }
}

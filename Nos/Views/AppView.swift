//
//  AppView.swift
//  Nos
//
//  Created by Matthew Lorentz on 2/3/23.
//

import SwiftUI

struct AppView: View {

    @EnvironmentObject private var appController: AppController
    
    @State var isCreatingNewPost = false
    
    @State var showNewPost = false

    @EnvironmentObject var router: Router
    
    @Environment(\.managedObjectContext) private var viewContext
    
    @State private var showingOptions = false
    @State private var lastSelectedTab = Destination.home
    
    /// An enumeration of the destinations for AppView.
    enum Destination: String, Hashable, Equatable {
        case home
        case discover
        case notifications
        case newNote
        case profile
        
        var label: some View {
            switch self {
            case .home:
                return Text(Localized.homeFeed.string)
            case .discover:
                return Localized.discover.view
            case .notifications:
                return Localized.notifications.view
            case .newNote:
                return Localized.newNote.view
            case .profile:
                return Localized.profile.view
            }
        }
        
        var destinationString: String {
            switch self {
            case .home:
                return Localized.homeFeed.string
            case .discover:
                return Localized.discover.string
            case .notifications:
                return Localized.notifications.string
            case .newNote:
                return Localized.newNote.string
            case .profile:
                return Localized.profile.string
            }
        }
    }
    
    var body: some View {
        
        ZStack {
            if appController.currentState == .onboarding {
                OnboardingView(completion: appController.completeOnboarding)
            } else {
                TabView(selection: $router.selectedTab) {
                    if let author = CurrentUser.author {
                        HomeFeedView(user: author)
                            .tabItem {
                                VStack {
                                    let text = Localized.homeFeed.view
                                    if $router.selectedTab.wrappedValue == .home {
                                        Image.tabIconHomeSelected
                                        text
                                    } else {
                                        Image.tabIconHome
                                        text.foregroundColor(.secondaryTxt)
                                    }
                                }
                            }
                            .toolbarBackground(Color.cardBgBottom, for: .tabBar)
                            .tag(Destination.home)
                    }
                    
                    DiscoverView()
                        .tabItem {
                            VStack {
                                let text = Localized.discover.view
                                if $router.selectedTab.wrappedValue == .discover {
                                    Image.tabIconEveryoneSelected
                                    text.foregroundColor(.textColor)
                                } else {
                                    Image.tabIconEveryone
                                    text.foregroundColor(.secondaryTxt)
                                }
                            }
                        }
                        .toolbarBackground(Color.cardBgBottom, for: .tabBar)
                        .tag(Destination.discover)
                    
                    VStack {}
                        .tabItem {
                            VStack {
                                Image.newPostButton
                                Localized.post.view
                            }
                        }
                    .tag(Destination.newNote)
                    
                    NotificationsView(user: CurrentUser.author)
                        .tabItem {
                            VStack {
                                let text = Localized.notifications.view
                                if $router.selectedTab.wrappedValue == .notifications {
                                    Image.tabIconNotificationsSelected
                                    text.foregroundColor(.textColor)
                                } else {
                                    Image.tabIconNotifications
                                    text.foregroundColor(.secondaryTxt)
                                }
                            }
                        }
                        .toolbarBackground(Color.cardBgBottom, for: .tabBar)
                        .tag(Destination.notifications)
                    
                    if let author = CurrentUser.author {
                        ProfileTab(author: author, path: $router.profilePath)
                            .tabItem {
                                VStack {
                                    let text = Localized.profile.view
                                    if $router.selectedTab.wrappedValue == .profile {
                                        text.foregroundColor(.textColor)
                                    } else {
                                        text.foregroundColor(.secondaryTxt)
                                    }
                                }
                            }
                            .toolbarBackground(Color.cardBgBottom, for: .tabBar)
                            .tag(Destination.profile)
                    }
                }
                .onChange(of: router.selectedTab) { newTab in
                    if newTab == Destination.newNote {
                        showNewPost = true
                        router.selectedTab = lastSelectedTab
                    } else if !showNewPost {
                        lastSelectedTab = newTab
                    }
                }
                .sheet(isPresented: $showNewPost, content: {
                    NewNoteView(isPresented: $showNewPost)
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
            // This navigation bar stuff doesn't seem to be working. I can't figure out why.
            let nosAppearance = UINavigationBarAppearance()
            nosAppearance.titleTextAttributes = [.foregroundColor: UIColor.systemPink]
            nosAppearance.largeTitleTextAttributes = [.foregroundColor: UIColor.systemPink]
            UINavigationBar.appearance().standardAppearance = nosAppearance
            UINavigationBar.appearance().compactAppearance = nosAppearance
            UINavigationBar.appearance().scrollEdgeAppearance = nosAppearance
            
            UITabBar.appearance().unselectedItemTintColor = .secondaryText
            UITabBar.appearance().tintColor = .primaryTxt
        }
        .accentColor(.primaryTxt)
    }
}

struct AppView_Previews: PreviewProvider {
    
    static var persistenceController = PersistenceController.preview
    static var previewContext = persistenceController.container.viewContext
    static var relayService = RelayService(persistenceController: persistenceController)
    static var router = Router()
    static var loggedInAppController: AppController = {
        let appController = AppController(router: router)
        KeyChain.save(key: KeyChain.keychainPrivateKey, data: Data(KeyFixture.alice.privateKeyHex.utf8))
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
            .environmentObject(loggedInAppController)
        
        AppView()
            .environment(\.managedObjectContext, previewContext)
            .environmentObject(relayService)
            .environmentObject(router)
            .environmentObject(AppController(router: router))
        
        AppView()
            .environment(\.managedObjectContext, previewContext)
            .environmentObject(relayService)
            .environmentObject(routerWithSideMenuOpened)
            .environmentObject(AppController(router: routerWithSideMenuOpened))
    }
}

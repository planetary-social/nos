//
//  AppView.swift
//  Nos
//
//  Created by Matthew Lorentz on 2/3/23.
//

import SwiftUI
import Dependencies

struct AppView: View {

    @State var showNewPost = false
    @State var newPostContents: String? 

    @EnvironmentObject private var appController: AppController
    @EnvironmentObject var router: Router
    @EnvironmentObject var pushNotificationService: PushNotificationService
    @Environment(\.managedObjectContext) private var viewContext
    @Dependency(\.analytics) private var analytics
    @Dependency(\.crashReporting) private var crashReporting
    @EnvironmentObject var currentUser: CurrentUser
    
    @State private var showingOptions = false
    @State private var lastSelectedTab = Destination.home
    
    /// An enumeration of the destinations for AppView.
    enum Destination: Hashable, Equatable {
        case home
        case discover
        case notifications
        case newNote(String?)
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
                return Localized.profileTitle.view
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
                return Localized.profileTitle.string
            }
        }
        
        func hash(into hasher: inout Hasher) {
            hasher.combine(destinationString)
        }
    }
    
    var body: some View {
        
        ZStack {
            if appController.currentState == .onboarding {
                OnboardingView(completion: appController.completeOnboarding)
            } else {
                TabView(selection: $router.selectedTab) {
                    if let author = currentUser.author {
                        HomeFeedView(user: author)
                            .tabItem {
                                VStack {
                                    let text = Localized.homeFeed.view
                                    if $router.selectedTab.wrappedValue == .home {
                                        Image.tabIconHomeSelected
                                        text
                                    } else {
                                        Image.tabIconHome
                                        text.foregroundColor(.secondaryText)
                                    }
                                }
                            }
                            .toolbarBackground(.visible, for: .tabBar)
                            .toolbarBackground(Color.cardBgBottom, for: .tabBar)
                            .tag(Destination.home)
                            .onAppear {
                                // TODO: Move this somewhere better like CurrentUser when it becomes the source of truth
                                // for who is logged in
                                if let keyPair = currentUser.keyPair {
                                    analytics.identify(with: keyPair)
                                    crashReporting.identify(with: keyPair)
                                }
                            }
                    }
                    
                    DiscoverView()
                        .tabItem {
                            VStack {
                                let text = Localized.discover.view
                                if $router.selectedTab.wrappedValue == .discover {
                                    Image.tabIconEveryoneSelected
                                    text.foregroundColor(.primaryTxt)
                                } else {
                                    Image.tabIconEveryone
                                    text.foregroundColor(.secondaryText)
                                }
                            }
                        }
                        .toolbarBackground(.visible, for: .tabBar)
                        .toolbarBackground(Color.cardBgBottom, for: .tabBar)
                        .tag(Destination.discover)
                    
                    VStack {}
                        .tabItem {
                            VStack {
                                Image.newPostButton
                                Localized.post.view
                            }
                        }
                    .tag(Destination.newNote(nil))
                    
                    NotificationsView(user: currentUser.author)
                        .tabItem {
                            VStack {
                                let text = Localized.notifications.view
                                if $router.selectedTab.wrappedValue == .notifications {
                                    Image.tabIconNotificationsSelected
                                    text.foregroundColor(.primaryTxt)
                                } else {
                                    Image.tabIconNotifications
                                    text.foregroundColor(.secondaryText)
                                }
                            }
                        }
                        .toolbarBackground(.visible, for: .tabBar)
                        .toolbarBackground(Color.cardBgBottom, for: .tabBar)
                        .tag(Destination.notifications)
                        .badge(pushNotificationService.badgeCount)
                    
                    if let author = currentUser.author {
                        ProfileTab(author: author, path: $router.profilePath)
                            .tabItem {
                                VStack {
                                    let text = Localized.profileTitle.view
                                    if $router.selectedTab.wrappedValue == .profile {
                                        Image.tabProfileSelected
                                        text.foregroundColor(.primaryTxt)
                                    } else {
                                        Image.tabProfile
                                        text.foregroundColor(.secondaryText)
                                    }
                                }
                            }
                            .toolbarBackground(.visible, for: .tabBar)
                            .toolbarBackground(Color.cardBgBottom, for: .tabBar)
                            .tag(Destination.profile)
                    }
                }
                .onChange(of: router.selectedTab) { newTab in
                    if case let Destination.newNote(contents) = newTab {
                        newPostContents = contents
                        showNewPost = true
                        router.selectedTab = lastSelectedTab
                    } else if !showNewPost {
                        lastSelectedTab = newTab
                    }
                }
                .sheet(isPresented: $showNewPost, content: {
                    NewNoteView(initialContents: newPostContents, isPresented: $showNewPost)
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
            UITabBar.appearance().unselectedItemTintColor = .secondaryText
            UITabBar.appearance().tintColor = .primaryTxt
        }
        .accentColor(.primaryTxt)
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
            .environmentObject(loggedInAppController)
        
        AppView()
            .environment(\.managedObjectContext, previewContext)
            .environmentObject(relayService)
            .environmentObject(router)
            .environmentObject(AppController())
        
        AppView()
            .environment(\.managedObjectContext, previewContext)
            .environmentObject(relayService)
            .environmentObject(routerWithSideMenuOpened)
            .environmentObject(AppController())
    }
}

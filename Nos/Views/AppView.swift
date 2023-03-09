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

    @EnvironmentObject var router: Router
    
    @Environment(\.managedObjectContext) private var viewContext
    
    @State
    private var showingOptions = false
    
    /// An enumeration of the destinations for AppView.
    enum Destination: String, Hashable {
        case home
        case discover
        case relays
        case notifications
        case newNote
        
        var label: some View {
            switch self {
            case .home:
                return Text(Localized.homeFeed.string)
            case .discover:
                return Localized.discover.view
            case .relays:
                return Text(Localized.relays.string)
            case .notifications:
                return Localized.notifications.view
            case .newNote:
                return Localized.newNote.view
            }
        }
        
        var destinationString: String {
            switch self {
            case .home:
                return Localized.homeFeed.string
            case .discover:
                return Localized.discover.string
            case .relays:
                return Localized.relays.string
            case .notifications:
                return Localized.notifications.string
            case .newNote:
                return Localized.newNote.string
            }
        }
    }
    
    var body: some View {
        
        ZStack {
            if appController.currentState == .onboarding {
                OnboardingView(completion: appController.completeOnboarding)
            } else {
                TabView(selection: $router.selectedTab) {
                    HomeFeedView(user: CurrentUser.author(in: viewContext))
                        .tabItem { Label(Localized.homeFeed.string, systemImage: "house") }
                        .toolbarBackground(Color.cardBgBottom, for: .tabBar)
                        .tag(Destination.home)
                    
                    DiscoverView()
                        .tabItem { Label(Localized.discover.string, systemImage: "magnifyingglass") }
                        .toolbarBackground(Color.cardBgBottom, for: .tabBar)
                        .tag(Destination.discover)
                    
                    NewPostView(isPresented: .constant(true))
                        .tabItem {
                            Label(Localized.newNote.string, systemImage: "plus.circle")
                        }
                        .toolbarBackground(Color.cardBgBottom, for: .tabBar)
                        .tag(Destination.newNote)
                    
                    NotificationsView(user: CurrentUser.author(in: viewContext))
                        .tabItem { Label(Localized.notifications.string, systemImage: "bell") }
                        .toolbarBackground(Color.cardBgBottom, for: .tabBar)
                        .tag(Destination.notifications)
                    
                    RelayView()
                        .tabItem {
                            Label(Localized.relays.string, systemImage: "antenna.radiowaves.left.and.right")
                        }
                        .toolbarBackground(Color.cardBgBottom, for: .tabBar)
                        .tag(Destination.relays)
                }
                
                SideMenu(
                    menuWidth: UIScreen.main.bounds.width / 1.3,
                    menuOpened: router.sideMenuOpened,
                    toggleMenu: router.toggleSideMenu,
                    closeMenu: router.closeSideMenu
                )
            }
        }
        .onAppear(perform: appController.configureCurrentState)
        .onAppear {
            let nosAppearance = UINavigationBarAppearance()
            nosAppearance.titleTextAttributes = [.foregroundColor: UIColor.primaryTxt]
            nosAppearance.largeTitleTextAttributes = [.foregroundColor: UIColor.primaryTxt]
            UINavigationBar.appearance().standardAppearance = nosAppearance
            UINavigationBar.appearance().compactAppearance = nosAppearance
            UINavigationBar.appearance().scrollEdgeAppearance = nosAppearance
        }
    }
}

struct AppView_Previews: PreviewProvider {
    
    static var persistenceController = PersistenceController.preview
    static var previewContext = persistenceController.container.viewContext
    static var relayService = RelayService(persistenceController: persistenceController)
    static var router = Router()
    static var loggedInAppController: AppController = {
        let appController = AppController()
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
            .environmentObject(AppController())
        
        AppView()
            .environment(\.managedObjectContext, previewContext)
            .environmentObject(relayService)
            .environmentObject(routerWithSideMenuOpened)
            .environmentObject(AppController())
    }
}

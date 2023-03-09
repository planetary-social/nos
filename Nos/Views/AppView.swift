//
//  AppView.swift
//  Nos
//
//  Created by Matthew Lorentz on 2/3/23.
//

import SwiftUI

struct AppView: View {

    @StateObject private var appController = AppController()
    
    @State var isCreatingNewPost = false

    @State var sideMenuOpened = false

    @State var selectedTab = Destination.home
    
    @EnvironmentObject var router: Router
    
    @Environment(\.managedObjectContext) private var viewContext
    
    @State
    private var showingOptions = false
    
    /// An enumeration of the destinations for AppView.
    enum Destination: String, Hashable {
        case home
        case discover
        case relays
        case settings
        case notifications
        
        var label: some View {
            switch self {
            case .home:
                return Text(Localized.homeFeedLinkTitle.string)
            case .discover:
                return Localized.discover.view
            case .relays:
                return Text(Localized.relaysLinkTitle.string)
            case .settings:
                return Text(Localized.settingsLinkTitle.string)
            case .notifications:
                return Localized.notifications.view
            }
        }
        var destinationString: String {
            switch self {
            case .home:
                return Localized.homeFeedLinkTitle.string
            case .discover:
                return Localized.discover.string
            case .relays:
                return Localized.relaysLinkTitle.string
            case .settings:
                return Localized.settingsLinkTitle.string
            case .notifications:
                return Localized.notifications.string
            }
        }
    }
    
    var body: some View {
        
        ZStack {
            if appController.currentState == .onboarding {
                OnboardingView(completion: appController.completeOnboarding)
            } else {
                NavigationView {
                    ZStack {
                        TabView(selection: $selectedTab) {
                            HomeFeedView(user: CurrentUser.author(in: viewContext))
                                .tabItem { Label(Localized.homeFeed.string, systemImage: "house") }
                                .tag(Destination.home)
                            
                            DiscoverView()
                                .tabItem { Label(Localized.discover.string, systemImage: "magnifyingglass") }
                                .tag(Destination.discover)
                            
                            NotificationsView(user: CurrentUser.author(in: viewContext))
                                .tabItem { Label(Localized.notifications.string, systemImage: "bell") }
                                .tag(Destination.notifications)

                            RelayView(author: CurrentUser.author)
                                .tabItem {
                                    Label(Localized.relays.string, systemImage: "antenna.radiowaves.left.and.right")
                                }
                                .tag(Destination.relays)
                        }
                        .onChange(of: selectedTab) { _ in
                            if router.path.count > 0 {
                                router.path.removeLast(router.path.count)
                            }
                        }
              
                        .navigationBarTitleDisplayMode(.inline)
                        .navigationTitle(router.path.count > 0 ? router.navigationTitle : selectedTab.destinationString)
                        .navigationBarItems(
                            leading:
                                Group {
                                    if router.path.count > 0 {
                                        Button(
                                            action: {
                                                router.path.removeLast()
                                            },
                                            label: {
                                                Image(systemName: "chevron.left")
                                            }
                                        )
                                    } else {
                                        Button(
                                            action: {
                                                toggleMenu()
                                            },
                                            label: {
                                                Image(systemName: "person.crop.circle")
                                            }
                                        )
                                    }
                                }
                            ,
                            trailing:
                                Group {
                                    if router.path.count > 0 {
                                        Button(
                                            action: {
                                                showingOptions = true
                                            },
                                            label: {
                                                Image(systemName: "ellipsis")
                                            }
                                        )
                                        .confirmationDialog(Localized.share.string, isPresented: $showingOptions) {
                                            Button(Localized.copyUserIdentifier.string) {
                                                UIPasteboard.general.string = router.viewedAuthor?.publicKey?.npub ?? ""
                                            }
                                            if let author = router.viewedAuthor {
                                                if author.muted {
                                                    Button(Localized.unmuteUser.string) {
                                                        router.viewedAuthor?.unmute()
                                                    }
                                                } else {
                                                    Button(Localized.muteUser.string) {
                                                        router.viewedAuthor?.mute(context: viewContext)
                                                    }
                                                }
                                            }
                                        }
                                    } else {
                                        Button(
                                            action: {
                                                isCreatingNewPost.toggle()
                                            },
                                            label: {
                                                Image(systemName: "plus")
                                            }
                                        )
                                    }
                                }
                        )
                        .sheet(isPresented: $isCreatingNewPost, content: {
                            NewNoteView(isPresented: $isCreatingNewPost)
                        })
                    }
                }
                .navigationViewStyle(.stack)
                
                SideMenu(
                    width: UIScreen.main.bounds.width / 1.3,
                    menuOpened: sideMenuOpened,
                    toggleMenu: toggleMenu,
                    closeMenu: closeMenu
                )
            }
        }
        .onAppear(perform: appController.configureCurrentState)
    }
    func toggleMenu() {
        sideMenuOpened.toggle()
    }
    func closeMenu() {
        sideMenuOpened = false
    }
}

struct AppView_Previews: PreviewProvider {
    
    static var persistenceController = PersistenceController.preview
    static var previewContext = persistenceController.container.viewContext
    static var relayService = RelayService(persistenceController: persistenceController)
    static var router = Router()
    
    static var previews: some View {
        AppView()
            .environment(\.managedObjectContext, previewContext)
            .environmentObject(relayService)
            .environmentObject(router)
    }
}

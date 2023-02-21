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
    
    /// An enumeration of the destinations for AppView.
    enum Destination: String, Hashable {
        case home
        case relays
        case settings
        
        var label: some View {
            switch self {
            case .home:
                return Text(Localized.homeFeedLinkTitle.string)
            case .relays:
                return Text(Localized.relaysLinkTitle.string)
            case .settings:
                return Text(Localized.settingsLinkTitle.string)
            }
        }
        var destinationString: String {
            switch self {
            case .home:
                return Localized.homeFeedLinkTitle.string
            case .relays:
                return Localized.relaysLinkTitle.string
            case .settings:
                return Localized.settingsLinkTitle.string
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
                            HomeFeedView()
                                .tabItem {
                                    Label("Home Feed", systemImage: "house")
                                }
                                .tag(Destination.home)

                            RelayView()
                                .tabItem {
                                    Label("Relays", systemImage: "antenna.radiowaves.left.and.right")
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
                                            },
                                            label: {
                                                Image(systemName: "ellipsis")
                                            }
                                        )
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
                            NewPostView(isPresented: $isCreatingNewPost)
                        })
                    }
                }
                
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

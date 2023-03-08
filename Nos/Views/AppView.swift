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

    @EnvironmentObject var router: Router
    
    @Environment(\.managedObjectContext) private var viewContext
    
    @State
    private var showingOptions = false
    
    /// An enumeration of the destinations for AppView.
    
    var body: some View {
        
        ZStack {
            if appController.currentState == .onboarding {
                OnboardingView(completion: appController.completeOnboarding)
            } else {
                NavigationView {
                    ZStack {
                        TabView(selection: $router.selectedTab) {
                            HomeFeedView(user: CurrentUser.author(in: viewContext))
                                .tabItem { Label(Localized.homeFeed.string, systemImage: "house") }
                                .tag(Destination.home)
                            
                            DiscoverView()
                                .tabItem { Label(Localized.discover.string, systemImage: "magnifyingglass") }
                                .tag(Destination.discover)
                            
                            NotificationsView(user: CurrentUser.author(in: viewContext))
                                .tabItem { Label(Localized.notifications.string, systemImage: "bell") }
                                .tag(Destination.notifications)

                            RelayView()
                                .tabItem {
                                    Label(Localized.relays.string, systemImage: "antenna.radiowaves.left.and.right")
                                }
                                .tag(Destination.relays)
                        }
                        .onChange(of: router.selectedTab) { _ in
                            if router.path.count > 0 {
                                router.path.removeLast(router.path.count)
                            }
                        }
              
                        .navigationBarTitleDisplayMode(.inline)
                        .navigationTitle(
                            router.path.count > 0 ? router.navigationTitle : router.selectedTab.destinationString
                        )
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
                                                UIPasteboard.general.string = router.userNpubPublicKey
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
                            NewPostView(isPresented: $isCreatingNewPost)
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

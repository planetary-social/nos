//
//  AppView.swift
//  Nos
//
//  Created by Matthew Lorentz on 2/3/23.
//

import SwiftUI

// Used in the NavigationStack and added as an environmentObject so that it can be used for multiple views
class Router: ObservableObject {
    @Published var displayNavigationView = true
    @Published var path = NavigationPath()
}

struct AppView: View {

    @StateObject private var appController = AppController()
   
    @State var isCreatingNewPost = false
    
    @State var menuOpened = false
    
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
                                .tabItem { Label("Home Feed", systemImage: "house") }
                                .tag(Destination.home)
                            RelayView()
                                .tabItem { Label("Relays", systemImage: "antenna.radiowaves.left.and.right") }
                                .tag(Destination.relays)
                        }
                        .navigationBarHidden(router.path.count != 0)
                        .navigationBarTitleDisplayMode(.inline)
                        .navigationTitle(selectedTab.destinationString)
                        .navigationBarItems(
                            leading:
                                Button(
                                    action: {
                                        toggleMenu()
                                    },
                                    label: {
                                        Image(systemName: "person.crop.circle")
                                    }
                                )
                            ,
                            trailing:
                                Button(
                                    action: {
                                        isCreatingNewPost.toggle()
                                    },
                                    label: {
                                        Image(systemName: "plus")
                                    }
                                )
                        )

                        .sheet(isPresented: $isCreatingNewPost, content: {
                            NewPostView(isPresented: $isCreatingNewPost)
                        })
                    }
                }
                
                SideMenu(
                    width: UIScreen.main.bounds.width / 1.3,
                    menuOpened: menuOpened,
                    toggleMenu: toggleMenu
                )
            }
        }
        .onAppear(perform: appController.configureCurrentState)
    }
    func toggleMenu() {
        menuOpened.toggle()
    }
}

struct MenuItem: Identifiable {
    var id = UUID()
    let text: String
}

struct MenuContent: View {
    var body: some View {
        ZStack {
            Color(UIColor(red: 255 / 255.0, green: 255 / 255.0, blue: 255 / 255.0, alpha: 1))
            
            VStack(alignment: .leading, spacing: 0, content: {
                HStack {
                    Button {
                    } label: {
                        HStack(alignment: .center) {
                            Image(systemName: "person.crop.circle")
                            Text("Your Profile")
                        }
                    }
                    
                    Spacer()
                }
                .padding()
                HStack {
                    Button {
                    } label: {
                        HStack(alignment: .center) {
                            Image(systemName: "gear")
                            Text("Settings")
                        }
                    }
                    
                    Spacer()
                }
                .padding()
                HStack {
                    Button {
                    } label: {
                        HStack(alignment: .center) {
                            Image(systemName: "questionmark.circle")
                            Text("Help and Support")
                        }
                    }
                    
                    Spacer()
                }
                .padding()
                HStack {
                    Button {
                    } label: {
                        HStack(alignment: .center) {
                            Image(systemName: "ant.circle.fill")
                            Text("Report a Bug")
                        }
                    }
                    
                    Spacer()
                }
                .padding()
            })
        }
    }
}
struct SideMenu: View {
    let width: CGFloat
    let menuOpened: Bool
    
    let toggleMenu: () -> Void
    var body: some View {
        ZStack {
            GeometryReader { _ in
                EmptyView()
            }
            .background(Color.gray.opacity(0.5))
            .opacity(self.menuOpened ? 1 : 0)
            .animation(Animation.easeIn.delay(0.15))
            .onTapGesture {
                self.toggleMenu()
            }
        }
        HStack {
            MenuContent()
                .frame(width: width, height: UIScreen.main.bounds.height)
                .offset(x: menuOpened ? 0 : -width, y: -0.015*UIScreen.main.bounds.height)
                .animation(.default)
            Spacer()
        }
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

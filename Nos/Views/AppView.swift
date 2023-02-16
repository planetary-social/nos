//
//  AppView.swift
//  Nos
//
//  Created by Matthew Lorentz on 2/3/23.
//

import SwiftUI

// Used in the NavigationStack and added as an environmentObject so that it can be used for multiple views
class Router: ObservableObject {
    @Published var path = NavigationPath()
}

struct AppView: View {

    @StateObject private var appController = AppController()
    
    /// An enumeration of the navigation destinations for AppView.
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
    }
    
    var body: some View {
        
        ZStack {
            if appController.currentState == .onboarding {
                OnboardingView(completion: appController.completeOnboarding)
            } else {
//                NavigationStack(path: $router.path) {
//                    List {
//                        NavigationLink(value: Destination.home) { Destination.home.label }
//                        NavigationLink(value: Destination.relays) { Destination.relays.label }
//                        NavigationLink(value: Destination.settings) { Destination.settings.label }
//                    }
//                    .navigationDestination(for: Destination.self, destination: { destination in
//                        switch destination {
//                        case .home:
//                            HomeFeedView()
//                        case .relays:
//                            RelayView()
//                        case .settings:
//                            SettingsView()
//                        }
//                    })
//                    .navigationDestination(for: Event.self) { note in
//                        ThreadView(note: note)
//                    }
//                    .navigationTitle(Localized.nos.string)
//                }
                TabView {
                    HomeFeedView()
                        .tabItem { Label("Home Feed", systemImage: "house") }
                    RelayView()
                        .tabItem { Label("Relays", systemImage: "satellite") }
                }
            }
        }
        .onAppear(perform: appController.configureCurrentState)
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

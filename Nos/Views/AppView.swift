//
//  AppView.swift
//  Nos
//
//  Created by Matthew Lorentz on 2/3/23.
//

import SwiftUI

class Router: ObservableObject {
    @Published var path = NavigationPath()
}

struct AppView: View {
    
    /// An enumeration of the navigation destinations for AppView.
    enum Destination: String, Hashable {
        case home
        case relays
        case settings
        
        var label: some View {
            switch self {
            case .home:
                return Text("🏠 Home Feed")
            case .relays:
                return Text("📡 Relays")
            case .settings:
                return Text("⚙️ Settings")
            }
        }
    }
    
    @EnvironmentObject var router: Router
    
    var body: some View {
        NavigationStack(path: $router.path) {
            List {
                NavigationLink(value: Destination.home) { Destination.home.label }
                NavigationLink(value: Destination.relays) { Destination.relays.label }
                NavigationLink(value: Destination.settings) { Destination.settings.label }
            }
            .navigationDestination(for: Destination.self, destination: { destination in
                switch destination {
                case .home:
                    HomeFeedView()
                case .relays:
                    RelayView()
                case .settings:
                    SettingsView()
                }
            })
            .navigationDestination(for: Event.self) { note in
                ThreadView(note: note)
            }
            .navigationTitle("Nos")
        }
    }
}

struct AppView_Previews: PreviewProvider {
    
    static var persistenceController = PersistenceController.preview
    static var previewContext = persistenceController.container.viewContext
    static var relayService = RelayService(persistenceController: persistenceController)
    
    static var previews: some View {
        AppView()
            .environment(\.managedObjectContext, previewContext)
            .environmentObject(relayService)
    }
}

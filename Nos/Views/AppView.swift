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
    
    @EnvironmentObject var router: Router
    
    var body: some View {
        NavigationStack(path: $router.path) {
            List {
                NavigationLink("🏠 Home Feed") {
                    HomeFeedView()
                }
                NavigationLink("📡 Relays") {
                    RelayView()
                }
                NavigationLink("⚙️ Settings") {
                    SettingsView()
                }
            }
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

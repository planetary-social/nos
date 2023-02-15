//
//  AppView.swift
//  Nos
//
//  Created by Matthew Lorentz on 2/3/23.
//

import SwiftUI

struct AppView: View {
    
    @State var path = NavigationPath()
    
    var body: some View {
        NavigationStack(path: $path) {
            List {
                NavigationLink(Localized.homeFeedLinkTitle.string) {
                    HomeFeedView()
                }
                NavigationLink(Localized.relaysLinkTitle.string) {
                    RelayView()
                }
                NavigationLink(Localized.settingsLinkTitle.string) {
                    SettingsView()
                }
            }
            .navigationTitle(Localized.nos.string)
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

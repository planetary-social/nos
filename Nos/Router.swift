//
//  Router.swift
//  Nos
//
//  Created by Jason Cheatham on 2/21/23.
//

import SwiftUI
import Combine
import CoreData
import Logger
import Dependencies

// Manages the app's navigation state.
@MainActor @Observable class Router {
    
    var homeFeedPath = NavigationPath()
    var discoverPath = NavigationPath()
    var notificationsPath = NavigationPath()
    var profilePath = NavigationPath()
    var sideMenuPath = NavigationPath()
    var selectedTab = AppDestination.home
    @Dependency(\.persistenceController) @ObservationIgnored private var persistenceController
    
    var currentPath: Binding<NavigationPath> {
        if sideMenuOpened {
            return Binding(get: { self.sideMenuPath }, set: { self.sideMenuPath = $0 })
        }

        return path(for: selectedTab)
    }
    
    var userNpubPublicKey = ""
    
    private(set) var sideMenuOpened = false

    func toggleSideMenu() {
        withAnimation(.easeIn(duration: 0.2)) {
            sideMenuOpened.toggle()
        }
    }
    
    func closeSideMenu() {
        withAnimation(.easeIn(duration: 0.2)) {
            sideMenuOpened = false
        }
    }
    
    /// Pushes the given destination item onto the current NavigationPath.
    func push<D: Hashable>(_ destination: D) {
        currentPath.wrappedValue.append(destination)
    }
    
    func pop() {
        currentPath.wrappedValue.removeLast()
    }
    
    func openOSSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url, options: [:], completionHandler: nil)
    }
    
    func showNewNoteView(contents: String?) {
        selectedTab = .newNote(contents)
    }


    func path(for destination: AppDestination) -> Binding<NavigationPath> {
        switch destination {
        case .home:
            return Binding(get: { self.homeFeedPath }, set: { self.homeFeedPath = $0 })
        case .discover:
            return Binding(get: { self.discoverPath }, set: { self.discoverPath = $0 })
        case .newNote:
            return Binding(get: { self.homeFeedPath }, set: { self.homeFeedPath = $0 })
        case .notifications:
            return Binding(get: { self.notificationsPath }, set: { self.notificationsPath = $0 })
        case .profile:
            return Binding(get: { self.profilePath }, set: { self.profilePath = $0 })
        }
    }
}

extension Router {
    
    nonisolated func open(url: URL, with context: NSManagedObjectContext) {
        let link = url.absoluteString
        let identifier = String(link[link.index(after: link.startIndex)...])
        
        Task { @MainActor in
            do {
                // handle mentions. mention link will be prefixed with "@" followed by
                // the hex format pubkey of the mentioned author
                if link.hasPrefix("@") {
                    push(try Author.findOrCreate(by: identifier, context: context))
                } else if link.hasPrefix("%") {
                    push(try Event.findOrCreateStubBy(id: identifier, context: context))
                } else if url.scheme == "http" || url.scheme == "https" {
                    push(url)
                } else {
                    UIApplication.shared.open(url)
                }
            } catch {
                Log.optional(error)
            } 
        }
    }
}

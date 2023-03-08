//
//  Router.swift
//  Nos
//
//  Created by Jason Cheatham on 2/21/23.
//

import SwiftUI
import CoreData

// Used in the NavigationStack and added as an environmentObject so that it can be used for multiple views
class Router: ObservableObject {
    @Published var path = NavigationPath()
    /// Sets the title when navigating to a view
    @Published var navigationTitle = ""
    
    @Published var userNpubPublicKey = ""
}

extension Router {
    
    func open(url: URL, with context: NSManagedObjectContext) {
        let link = url.absoluteString
        let identifier = String(link[link.index(after: link.startIndex)...])
        // handle mentions. mention link will be prefixed with "@" followed by
        // the hex format pubkey of the mentioned author
        if link.hasPrefix("@") {
            if let author = try? Author.find(by: identifier, context: context) {
                self.path.append(author)
            }
        } else if link.hasPrefix("%") {
            if let event = Event.find(by: identifier, context: context) {
                self.path.append(event)
            }
        }
    }
}

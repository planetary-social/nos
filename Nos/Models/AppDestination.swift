//
//  AppDestination.swift
//  Nos
//
//  Created by Matthew Lorentz on 10/18/23.
//

import Foundation
import SwiftUI

/// An enumeration of the destinations for AppView.
enum AppDestination: Hashable, Equatable {
    case home
    case discover
    case notifications
    case newNote(String?)
    case profile
    
    var label: some View {
        switch self {
        case .home:
            return Text(Localized.homeFeed.string)
        case .discover:
            return Localized.discover.view
        case .notifications:
            return Localized.notifications.view
        case .newNote:
            return Localized.newNote.view
        case .profile:
            return Localized.profileTitle.view
        }
    }
    
    var destinationString: String {
        switch self {
        case .home:
            return Localized.homeFeed.string
        case .discover:
            return Localized.discover.string
        case .notifications:
            return Localized.notifications.string
        case .newNote:
            return Localized.newNote.string
        case .profile:
            return Localized.profileTitle.string
        }
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(destinationString)
    }
}

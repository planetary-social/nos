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
            return Text(.localizable.homeFeed)
        case .discover:
            return Text(.localizable.discover)
        case .notifications:
            return Text(.localizable.notifications)
        case .newNote:
            return Text(.localizable.newNote)
        case .profile:
            return Text(.localizable.profileTitle)
        }
    }
    
    var destinationString: String {
        switch self {
        case .home:
            return String(localized: .localizable.homeFeed)
        case .discover:
            return String(localized: .localizable.discover)
        case .notifications:
            return String(localized: .localizable.notifications)
        case .newNote:
            return String(localized: .localizable.newNote)
        case .profile:
            return String(localized: .localizable.profileTitle)
        }
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(destinationString)
    }
}

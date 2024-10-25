import Foundation
import SwiftUI

/// An enumeration of the destinations for AppView.
enum AppDestination: Hashable, Equatable {
    case home
    case discover
    case notifications
    case noteComposer(String?)
    case profile
    case addFriend
    
    var destinationString: String {
        switch self {
        case .home:
            return String(localized: .localizable.homeFeed)
        case .discover:
            return String(localized: .localizable.discover)
        case .notifications:
            return String(localized: .localizable.notifications)
        case .noteComposer:
            return String(localized: .localizable.newNote)
        case .profile:
            return String(localized: .localizable.profileTitle)
        case .addFriend:
            return "Add friend"
        }
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(destinationString)
    }
}

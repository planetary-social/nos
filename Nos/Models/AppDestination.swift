import Foundation
import SwiftUI

/// An enumeration of the destinations for AppView.
enum AppDestination: Hashable, Equatable {
    case home
    case discover
    case notifications
    case noteComposer(String?)
    case profile
    
    static var tabDestinations: [AppDestination] {
        [.home, .discover, .noteComposer(nil), .notifications, .profile]
    }
    
    var destinationString: String {
        switch self {
        case .home:
            return String(localized: "homeFeed")
        case .discover:
            return String(localized: "discover")
        case .notifications:
            return String(localized: "notifications")
        case .noteComposer:
            return String(localized: "newNote")
        case .profile:
            return String(localized: "profileTitle")
        }
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(destinationString)
    }
    
    var tabIndex: Int {
        switch self {
        case .home: return 0
        case .discover: return 1
        case .noteComposer: return 2
        case .notifications: return 3
        case .profile: return 4
        }
    }
}

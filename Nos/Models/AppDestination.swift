import Foundation
import SwiftUI

/// An enumeration of the destinations for AppView.
enum AppDestination: Hashable, Equatable {
    case home
    case discover
    case notifications
    case noteComposer(String?)
    case profile
    case myStreams
    
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
        case .myStreams:
            return String(localized: "myStreams")
        }
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(destinationString)
    }
}

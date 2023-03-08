//
//  Destination.swift
//  Nos
//
//  Created by Jason Cheatham on 3/8/23.
//

import Foundation
import SwiftUI
enum Destination: String, Hashable {
    case home
    case discover
    case relays
    case settings
    case notifications
    
    var label: some View {
        switch self {
        case .home:
            return Text(Localized.homeFeedLinkTitle.string)
        case .discover:
            return Localized.discover.view
        case .relays:
            return Text(Localized.relaysLinkTitle.string)
        case .settings:
            return Text(Localized.settingsLinkTitle.string)
        case .notifications:
            return Localized.notifications.view
        }
    }
    var destinationString: String {
        switch self {
        case .home:
            return Localized.homeFeedLinkTitle.string
        case .discover:
            return Localized.discover.string
        case .relays:
            return Localized.relaysLinkTitle.string
        case .settings:
            return Localized.settingsLinkTitle.string
        case .notifications:
            return Localized.notifications.string
        }
    }
}

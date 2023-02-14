//
//  Localized.swift
//  Nos
//
//  Created by Matthew Lorentz on 2/14/23.
//

import Foundation

// swiftlint:disable line_length identifier_name

// provide the types of any new Localizable enums
// in order to automatically export their strings to the localization files
extension Localized {
    static var localizableTypes: [any Localizable.Type] {
        // TODO: Can we compute this using CaseIterable and recursion?
        [Localized.self]
    }
}

// MARK: - Generic

/// Localized is an enumeration of all the strings in our app that can be translated into supported languages.
enum Localized: String, Localizable, CaseIterable {
    
    case nos = "Nos"
    
    case error = "Error"
    case noEvents = "No Events Yet! Add a relay to get started"
    case addItem = "Add Item"
    case homeFeed = "Home Feed"
    case homeFeedLinkTitle = "🏠 Home Feed"
    case relaysLinkTitle = "📡 Relays"
    case settingsLinkTitle = "⚙️ Settings"
    
    case keys = "Keys"
    case keyEncryptionWarning = "Warning: your private key will be stored unencrypted on disk."
    case privateKeyPlaceholder = "Private Key (in hex format)"
    case save = "Save"
    case settings = "Settings"
    case invalidKey = "Invalid Key"
    case couldNotReadPrivateKeyMessage = "Could not read your private key. Make sure it is in hex format."
    
    case publish = "Publish"
    case newNote = "New Note"
    case cancel = "Cancel"
    case youNeedToEnterAPrivateKeyBeforePosting = "You need to enter a private key in Settings before you can publish posts."
    
    case relays = "Relays"
    case noRelaysMessage = "No relays yet! Add one below to get started"
    case addRelay = "Add relay"
}

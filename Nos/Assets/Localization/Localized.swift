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
///
///    Use as follows:
///
///    enum Text: String, Localizable {
///        case hello = "Hello!"
///        case greeting = "Hello {{ name }}!"
///    }
///
///    Text.hello.string
///        Hello!
///
///    Text.greeting.string(["name": "friend"])
///        Hello friend!
///
///    To create a localizable strings file, you can conform your enum to CaseIterable,
///    and then call the following:
///
///    Text.exportForStringsFile()
///        "Text.hello" = "Hello.";
///        "Text.greeting" = "Hello {{ name }}.";
///
///    Then simply implement localization in the `string` function:
///
///        var string: String {
///            return NSLocalizedString(key, comment: "")
///        }
///
enum Localized: String, Localizable, CaseIterable {
    
    case nos = "Nos"
    
    case error = "Error"
    case noEvents = "No notes to show! Add a relay to get started."
    case addItem = "Add Item"
    case homeFeed = "Home Feed"
    case homeFeedLinkTitle = "🏠 Home Feed"
    case relaysLinkTitle = "📡 Relays"
    case settingsLinkTitle = "⚙️ Settings"
    
    case keys = "Keys"
    case keyEncryptionWarning = "Warning: Never share your private key with anyone."
    case privateKeyPlaceholder = "nsec..."
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
    case recommendedRelays = "Recommended Relays"
    
    case profile = "Profile"
    case follow = "Follow"
    case following = "Following"
    case unfollow = "Unfollow"
    case readMore = "Read more"
    case threadView = "Thread View"
    case bio = "Bio"
    case noEventsOnProfile = "We don't see any notes for this profile, but we'll keep looking!"
    
    case debug = "Debug"
    case loadSampleData = "Load Sample Data"
    case sampleDataInstructions = "This will delete all events and load those in sample_data.json"
    
    case discover = "Discover"
    case notifications = "Notifications"
    case noNotifications = "No notifications (yet)!"
    case copyNoteIdentifier = "Copy Note Identifier"
    case copyUserIdentifier = "Copy User ID"
    case muteUser = "Mute"
    case mutedUser = "Muted"
    case share = "Share"
    case reportPost = "Report this post"
    case unmuteUser = "Un-Mute"
}

// MARK: - Onboarding

extension Localized {
    
    enum Onboarding: String, Localizable, CaseIterable {
        case getStartedTitle = "Welcome to Nos"
        case getStartedButton = "Let's get started"
        
        case privateKeyTitle = "Private Key"
        case generatePrivateKeyButton = "Generate Private Key"
        case alreadyHaveAPrivateKey = "Already have a private key?"
        case addPrivateKeyTitle = "Add Private Key"
        case privateKeyPrompt = "Private Key:"
    }
}

// MARK: - Replies

extension Localized {
    
    enum Reply: String, Localizable, CaseIterable {
        case one = "{{ count }} reply"
        case many = "{{ count }} replies"
    }
}

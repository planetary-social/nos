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
        [Localized.self, Localized.Reply.self, Localized.ImagePicker.self, ReportCategory.self]
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
    
    case onboardingTitle = "the human network"
    case logInWithYourKeys = "Login with your keys"
    case ageVerificationTitle = "Are you over 16 years old?"
    case ageVerificationSubtitle = "For legal reasons, we need to make sure you're over this age to use Nos"
    case notOldEnoughTitle = "Sorry, but Nos is not for you yet,"
    case notOldEnoughSubtitle = "You need to be 16 years old to be able to use this app."
    case notOldEnoughButton = "Go back (to school)"
    case termsOfServiceTitle = "Terms of Service"
  
    case loginWithKey = "Login with key"
    case pasteYourSecretKey = "Paste your secret key"
    case login = "Login"
    
    case yes = "Yes"
    case no = "No"
    
    case accept = "Accept"
    case reject = "Reject"
    
    case error = "Error"
    case noEvents = "No notes (yet)! Browse the Discover tab and follow some people to get started."
    case addItem = "Add Item"
    case homeFeed = "Feed"
    
    case keys = "Keys"
    case privateKeyWarning = "Never share your private key with anyone. Save your private key in a password manager so you can restore access to your account & data."
    case privateKeyPlaceholder = "nsec or hex..."
    case save = "Save"
    case copy = "Copy"
    case settings = "Settings"
    case invalidKey = "Invalid Key"
    case couldNotReadPrivateKeyMessage = "Could not read your private key. Please verify that it is in nsec or hex format."
    case tryIt = "Try it"
    case shareLogs = "Share logs"
    case failedToExportLogs = "Failed to export logs."
    case appVersion = "App Version:"
    case allPublishedEvents = "All published events"
    
    case privateKey = "Private Key"
    case logout = "Logout"
    case myKeyIsBackedUp = "My key is backed up"
    case backUpYourKeyWarning = "Logging out will delete your private key (nsec) from the app. Make sure you have your private key backed up before you do this or you will lose access to your account!"
    
    case post = "Post" // (verb form)
    case newNote = "New Note"
    case newNotePlaceholder = "Type your post here..."
    case cancel = "Cancel"
    case confirm = "Confirm"
    case clear = "Clear"
    case done = "Done"
    case editProfile = "Edit Profile"
    case completeProfileMessage = "Finish setting up your profile to help people find you."
    case completeProfileButton = "Complete My Profile"
    case youNeedToEnterAPrivateKeyBeforePosting = "You need to enter a private key in Settings before you can publish posts."
    case relayDoesNotSupportNIP40 = "This relay doesn't support expiring messages. Please select another one."
    case anyRelaysSupportingNIP40 = "None of your relays support expiring messages. Please add one and retry."
    case noteDisappearsIn = "Note disappears in a" // Choices like 15 mins, 1 hour, etc. appear after this text.
    case attachMedia = "Attach Media"
    case expirationDate = "Expiration Date"
    case minuteAbbreviated = "min"
    case minute = "minute"
    case hour = "hour"
    case day = "day"
    case week = "week"
    case month = "month"
    case year = "year"
    case sendCode = "Send code"
    case submit = "Submit"
    case setUpUNS = "Reserve Your Name"
    case goBack = "Go back"
    case startOver = "Start over"
    case setUpUniversalName = "Set up your Universal Name"
    case dismiss = "Dismiss"
    
    case relays = "Relays"
    case noRelaysMessage = "No relays yet! Add one below to get started"
    case addRelay = "Add relay"
    case recommendedRelays = "Recommended Relays"
    case invalidURLError = "Please enter a valid websocket URL."
    case saveRelayError = "Could not save relay."
    case ok = "Ok"

    case relay = "Relay"
    case address = "Address"
    case fetchedAt = "Fetched"
    case metadata = "Metadata"
    case description = "Description"
    case supportedNIPs = "Supported NIPs"
    case pubkey = "Public key"
    case contact = "Contact"
    case software = "Software"
    case version = "Version"
    
    case profileTitle = "Profile"
    case profile = "profile"
    case follow = "Follow"
    case follows = "Follows"
    case following = "Following"
    case followedBy = "Followed by"
    case followedByOne = "Followed by **{{ one }}**"
    case followedByOneAndMore = "Followed by **{{ one }}** and **{{ count }} others**"
    case followedByTwo = "Followed by **{{ one }}** and **{{ two }}**"
    case followedByTwoAndMore = "Followed by **{{ one }}**, **{{ two }}** and **{{ count }} others**"
    case unfollow = "Unfollow"
    case uns = "UNS"
    case nip05 = "NIP-05"
    case nip05LearnMore = "Learn more about NIP-05 name verification."
    case learnMore = "Learn more"
    case readMore = "Read more"
    case thread = "Thread"
    case show = "Show" // verb form
    case bio = "Bio"
    case displayName = "Display name"
    case name = "Name"
    case profilePicture = "Profile picture"
    case identityVerification = "Identity verification"
    case url = "URL"
    case noEventsOnProfile = "We don't see any notes for this profile, but we'll keep looking!"
    case uploadProfilePicInstructions = "Go to nostr.build to upload your photo, copy the URL provided and paste it here."
    case basicInfo = "Basic Information"
    case website = "Website"
    case edit = "Edit" // verb form

    case mention = "Mention"
    
    case debug = "Debug"
    case loadSampleData = "Load Sample Data"
    case sampleDataInstructions = "This will delete all events and load those in sample_data.json"
    
    case discover = "Discover"
    case searchBar = "Search for users"
    case notifications = "Notifications"
    case noNotifications = "No notifications (yet)!"
    case copyNoteIdentifier = "Copy Note Identifier"
    case copyNoteText = "Copy Note Text"
    case copyLink = "Copy Link"
    case copyUserIdentifier = "Copy User ID (npub)"
    case deleteNote = "Delete"
    case deleteNoteConfirmation = "This will ask all your relay servers to permanently remove this note. Are you sure?"
    case mute = "Mute"
    case muteUser = "Mute User"
    case muted = "Muted"
    case mutedUsers = "Muted Users"
    case mutePrompt = "Would you like to mute {{ user }}?"
    case share = "Share"
    case reportNote = "Report note"
    case reportUser = "Report user"
    case reportContent = "Report Content"
    case confirmReport = "Confirm Report"
    case reportConfirmation = "Are you sure you want to report this as {{ report_type }}? This report will be public."
    case note = "note"
    case unmuteUser = "Un-Mute"
    case outsideNetwork = "This user is outside your network."
    case allMyRelays = "All My Relays"
    case about = "About"
    case contactUs = "Contact Us"
    case shareNos = "Share Nos"
    case yourProfile = "Your Profile"
    
    case unsTagline = "Universal Name Space brings identity verification you can trust."
    case unsDescription = "The Universal Namespace gives you one name you can use everywhere. Register your Universal Name and connect it to your Nostr profile. Learn more."
    case unsRegister = "Register your Universal Name"
    case unsRegisterDescription = """
    Universal Name Space gives you a name you can use everywhere.
            
    Verify your identity and link your social accounts, government ID, wallets and more.
    """
    case unsLearnMore = "Learn more about UNS."
    case verifyYourIdentity = "Verify your identity"
    case enterCode = "Enter Code"
    case nameLower = "name"
    case chooseYourName = "Choose Your Name"
    case oops = "Oops!"
    case thatNameIsTaken = "That name is taken."
    case success = "Success!"
    case yourNewUNMessage = "is your Universal Name.\n\nWe've created a link between your Nostr profile and your Universal Name and filled your Universal Name into the username field on your profile."
    case anErrorOccurred = "An error occured."
    
    case relayAddressPlaceholder = "wss://yourrelay.com"
    case someone = "someone"
    
    case aboutNos = "Nos is a new social media app built on the Nostr protocol from the team that brought you Planetary. Designed for humans, not algorithms. Learn more at Nos.social."
    case aboutNosHighlight = "Learn more at Nos.social."
    case aboutNostr = "Nostr is an open social media ecosystem that puts you in control of your online relationships. Nos is just one of many apps that speak the Nostr language, and you can pick your servers too. Learn more about why Nostr is great."
    case aboutNostrHighlight = "Learn more about why Nostr is great."
    case nosIsOpenSource = "Nos is open source! You can read the code, contribute new features, or even fork it and build your own Nostr client. No opaque algorithms or secret rules. See the code."
    case nosIsOpenSourceHighlight = "See the code."
    case eventSource = "Raw Event"
    case loading = "Loading..."
    case viewSource = "View Source"
    case reportEventContent = "This content has been reported for {{ report_category }} using NIP-69 vocabulary https://github.com/nostr-protocol/nips/pull/457"
    case select = "Select"
}

// MARK: - Replies

extension Localized {
    
    enum Reply: String, Localizable, CaseIterable {
        case one = "{{ count }} reply"
        case many = "{{ count }} replies"
        
        case replied = "replied"
        case posted = "posted"
        case postAReply = "Post a reply"
        
        case repliedToYourNote = "replied to your note:"
        case mentionedYou = "mentioned you:"
    }
}

// MARK: - ImagePicker

extension Localized {
    
    enum ImagePicker: String, Localizable, CaseIterable {
        case camera = "Camera"
        case cameraNotAvailable = "Camera is not available on this device"
        case openSettingsMessage = "You can allow camera permissions by opening the Settings app."
        case permissionsRequired = "Permissions required for {{ title }}"
        case photoLibrary = "Photo Library"
        case selectFrom = "Select from Photo Library"
        case takePhoto = "Take photo with Camera"
        case errorUploadingFile = "Error uploading the file"
        case errorUploadingFileMessage = "An error was encountered when uploading the file you provided. Please try again."
        case uploading = "Uploading..."
    }
}

// swiftlint:enable line_length identifier_name

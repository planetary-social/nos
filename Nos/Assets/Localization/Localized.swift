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
        [Localized.self, Localized.Reply.self]
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
    case termsOfService = """
    Summary
    This top section summarizes the terms below. This summary is provided to help your understanding of the terms, but be sure to read the entire document, because when you agree to it, you are indicating you accept all of the terms, not just this summary.

    Nos cloud services (the \\"Services\\") are a suite of services provided to you by Verse Communications Inc.
    The Services are provided \\"as is\\" and there are no warranties of any kind. There are significant limits on Verse's liability for any damages arising from your use of the Services.
    Terms of Service
    Introduction

    These Terms of Service (\\"Terms\\") govern your use of Nos cloud services, a suite of online services provided by Verse (the \\"Services\\").

    Nos Accounts

    In order to use some of the Services, you'll need to connect using your nostr identity. During onboarding, this identity will be created and used to connect to all Nos services. You are responsible for keeping your cryptographic identity confidential and for the activity that happens through your Nos account. Verse is not responsible for any losses arising out of unauthorized use of your Nos account.

    Services

    (a) Nos Relay act as a store and forward relay for your posts so your followers can get them when you're not running the application on your phone. .

    (b) Nos Notification Service looks at the posts of your friends which are on the pub's and not encrypted to tell your client to look for new updates

    Privacy Policy

    We use the information we receive through the Services as described in our Nos Privacy Policy. Our Privacy Notices describe in more detail the data we receive from each service:

    Communications

    We send periodic messages to help you get the most from your Nos Account. You may receive these in-product or to the address you signed-up with; they cover onboarding, different Nos Account services, and related offers and surveys. You may also choose to receive other types of email messages.

    You can change your email subscriptions with Verse from our emails (click the link at the bottom) or from the application.

    We may also send you important account information such as updates to legal or privacy terms, or security messages like phone number verification, email verification, and linked devices. These are necessary to our services and cannot be unsubscribed from. You can contact Verse at Verse Communications Attn: Versef – Legal Notices 9450 SW Gemini Dr PMB 21667
    Beverton Oregon 97008-7105 or contact@verse.app

    Your Content in Our Services

    You may upload content to Verse as part of the features of the Services. By uploading content, you hereby grant us a nonexclusive, royalty-free, worldwide license to use your content in connection with the provision of the Services. You hereby represent and warrant that your content will not infringe the rights of any third party and will comply with any content guidelines presented by Verse. Report claims of copyright or trademark infringement at planetarysupport.zendesk.com. To report abusive Screenshots, email us a link to the shot at contact@verse.app.

    Verse's Proprietary Rights

    Verse does not grant you any intellectual property rights in the Services that are not specifically stated in these Terms. For example, these Terms do not provide the right to use any of Verse's copyrights, trade names, trademarks, service marks, logos, domain names, or other distinctive brand features.

    Term; Termination

    These Terms will continue to apply until ended by either you or Verse. You can choose to end them at any time for any reason by deleting your Nos account, discontinuing your use of the Services, and if applicable, unsubscribing from our emails.

    We may suspend or terminate your access to the Services at any time for any reason, including, but not limited to, if we reasonably believe: (i) you have violated these Terms, (ii) you create risk or possible legal exposure for us; or (iii) our provision of the Services to you is no longer commercially viable. We will make reasonable efforts to notify you by the email address or phone number associated with your Nos account or the next time you attempt to access the Services.

    In all such cases, these Terms shall terminate, including, without limitation, your license to use the Services, except that the following sections shall continue to apply: Indemnification, Disclaimer; Limitation of Liability, Miscellaneous.

    Indemnification

    You agree to defend, indemnify and hold harmless Verse, its contractors, contributors, licensors, and partners, and their respective directors, officers, employees and agents (\\"Indemnified Parties\\") from and against any and all third party claims and expenses, including attorneys' fees, arising out of or related to your use of the Services (including, but not limited to, from any content uploaded by you).

    Disclaimer; Limitation of Liability

    THE SERVICES ARE PROVIDED \\"AS IS\\" WITH ALL FAULTS. TO THE EXTENT PERMITTED BY LAW, VERSE AND THE INDEMNIFIED PARTIES HEREBY DISCLAIM ALL WARRANTIES, WHETHER EXPRESS OR IMPLIED, INCLUDING WITHOUT LIMITATION WARRANTIES THAT THE SERVICES ARE FREE OF DEFECTS, MERCHANTABLE, FIT FOR A PARTICULAR PURPOSE, AND NON-INFRINGING. YOU BEAR THE ENTIRE RISK AS TO SELECTING THE SERVICES FOR YOUR PURPOSES AND AS TO THE QUALITY AND PERFORMANCE OF THE SERVICES, INCLUDING WITHOUT LIMITATION THE RISK THAT YOUR CONTENT IS DELETED OR CORRUPTED OR THAT SOMEONE ELSE ACCESSES YOUR ONLINE ACCOUNTS. THIS LIMITATION WILL APPLY NOTWITHSTANDING THE FAILURE OF ESSENTIAL PURPOSE OF ANY REMEDY. SOME JURISDICTIONS DO NOT ALLOW THE EXCLUSION OR LIMITATION OF IMPLIED WARRANTIES, SO THIS DISCLAIMER MAY NOT APPLY TO YOU.

    EXCEPT AS REQUIRED BY LAW, VERSE AND THE INDEMNIFIED PARTIES WILL NOT BE LIABLE FOR ANY INDIRECT, SPECIAL, INCIDENTAL, CONSEQUENTIAL, OR EXEMPLARY DAMAGES ARISING OUT OF OR IN ANY WAY RELATING TO THESE TERMS OR THE USE OF OR INABILITY TO USE THE SERVICES, INCLUDING WITHOUT LIMITATION DIRECT AND INDIRECT DAMAGES FOR LOSS OF GOODWILL, WORK STOPPAGE, LOST PROFITS, LOSS OF DATA, AND COMPUTER FAILURE OR MALFUNCTION, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGES AND REGARDLESS OF THE THEORY (CONTRACT, TORT, OR OTHERWISE) UPON WHICH SUCH CLAIM IS BASED. THE COLLECTIVE LIABILITY OF VERSE AND THE INDEMNIFIED PARTIES UNDER THIS AGREEMENT WILL NOT EXCEED $500 (FIVE HUNDRED DOLLARS). SOME JURISDICTIONS DO NOT ALLOW THE EXCLUSION OR LIMITATION OF INCIDENTAL, CONSEQUENTIAL, OR SPECIAL DAMAGES, SO THIS EXCLUSION AND LIMITATION MAY NOT APPLY TO YOU.

    Modifications to these Terms

    Verse may update these Terms from time to time to address a new feature of the Services or to clarify a provision. The updated Terms will be posted online. If the changes are substantive, we will announce the update through Verse's usual channels for such announcements, such as blog posts and forums. Your continued use of the Services after the effective date of such changes constitutes your acceptance of such changes. To make your review more convenient, we will post an effective date at the top of this page.

    Miscellaneous

    These Terms constitute the entire agreement between you and Verse concerning the Services and are governed by the laws of the state of Oregon, U.S.A., excluding its conflict of law provisions. If any portion of these Terms is held to be invalid or unenforceable, the remaining portions will remain in full force and effect. In the event of a conflict between a translated version of these terms and the English language version, the English language version shall control.

     

    CONTACT US

    In order to resolve a complaint regarding the Site or to receive further information regarding use of the Site, please contact us at:

    Verse Communications Inc

    9450 SW Gemini Dr PMB 21667
    Beverton Oregon 97008-7105

    United States

    help@nos.social
    """
    
    case loginToYourAccount = "Login to your account"
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
    case keyEncryptionWarning = "Warning: Never share your private key with anyone."
    case privateKeyPlaceholder = "nsec or hex..."
    case save = "Save"
    case copy = "Copy"
    case settings = "Settings"
    case invalidKey = "Invalid Key"
    case couldNotReadPrivateKeyMessage = "Could not read your private key. Please verify that it is in nsec or hex format."
    case createAccount = "Create an account"
    
    case post = "Post" // (verb form)
    case newNote = "New Note"
    case newNotePlaceholder = "Type your post here..."
    case cancel = "Cancel"
    case done = "Done"
    case editProfile = "Edit Profile"
    case youNeedToEnterAPrivateKeyBeforePosting = "You need to enter a private key in Settings before you can publish posts."
    case nostrBuildHelp = "Use nostr.build to post image links."
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
    
    case profile = "Profile"
    case follow = "Follow"
    case follows = "Follows"
    case following = "Following"
    case unfollow = "Unfollow"
    case uns = "UNS"
    case nip05 = "NIP-05"
    case readMore = "Read more"
    case thread = "Thread"
    case show = "Show" // verb form
    case bio = "Bio"
    case displayName = "Display name"
    case name = "Name"
    case picUrl = "Profile pic url"
    case noEventsOnProfile = "We don't see any notes for this profile, but we'll keep looking!"
    case basicInfo = "Basic Information"
    case edit = "Edit" // verb form
    
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
    case muteUser = "Mute"
    case mutedUser = "Muted"
    case share = "Share"
    case reportPost = "Report this post"
    case unmuteUser = "Un-Mute"
    case extendedNetwork = "Extended Network"
    case outsideNetwork = "This user is outside your network."
    case allMyRelays = "All My Relays"
    case about = "About"
    case contactUs = "Contact Us"
    case shareNos = "Share Nos"
    case yourProfile = "Your Profile"
    
    case unsTagline = "Universal Name Space brings identity verification you can trust."
    case unsDescription = "The Universal Namespace gives you one name you can use everywhere. You can verify your identity and get your universal name here in Nos. This screen is for demo purposes only, all names will be reset in the future. Learn more."
    case unsLearnMore = "Learn more."
    case verifyYourIdentity = "Verify your identity"
    case enterCode = "Enter Code"
    case nameLower = "name"
    case chooseYourName = "Choose Your Name"
    case oops = "Oops!"
    case thatNameIsTaken = "That name is taken."
    case success = "Success!"
    case yourNewUNMessage = "is your new Nostr username.\n\nThis demo of the Universal Namespace is for testing purposes only. All names will be reset in the future."
    case anErrorOccurred = "An error occured."
    
    case relayAddressPlaceholder = "wss://yourrelay.com"
    case someone = "someone"
    
    case aboutNos = "Nos is a new social media app built on the Nostr protocol from the team that brought you Planetary. Designed for humans, not algorithms. Learn more at Nos.social."
    case aboutNosHighlight = "Learn more at Nos.social."
    case aboutNostr = "Nostr is an open social media ecosystem that puts you in control of your online relationships. Nos is just one of many apps that speak the Nostr language, and you can pick your servers too. Learn more about why Nostr is great."
    case aboutNostrHighlight = "Learn more about why Nostr is great."
    case nosIsOpenSource = "Nos is open source! You can read the code, contribute new features, or even fork it and build your own Nostr client. No opaque algorithms or secret rules. See the code."
    case nosIsOpenSourceHighlight = "See the code."
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
// swiftlint:enable line_length identifier_name

import Foundation

extension String {
    /// A type that represents localized strings from the ‘Localizable‘
    /// strings table.
    ///
    /// Do not initialize instances of this type yourself, instead use one of the static
    /// methods or properties that have been generated automatically.
    ///
    /// ## Usage
    ///
    /// ### Foundation
    ///
    /// In Foundation, you can resolve the localized string using the system language
    /// with the `String`.``Swift/String/init(localizable:locale:)``
    /// intializer:
    ///
    /// ```swift
    /// // Accessing the localized value directly
    /// let value = String(localizable: .about)
    /// value // "About"
    /// ```
    ///
    /// Starting in iOS 16/macOS 13/tvOS 16/watchOS 9, `LocalizedStringResource` can also
    /// be used:
    ///
    /// ```swift
    /// var resource = LocalizedStringResource(localizable: .about)
    /// resource.locale = Locale(identifier: "fr") // customise language
    /// let value = String(localized: resource)    // defer lookup
    /// ```
    ///
    /// ### SwiftUI
    ///
    /// In SwiftUI, it is recommended to use `Text`.``SwiftUI/Text/init(localizable:)``
    /// or `LocalizedStringKey`.``SwiftUI/LocalizedStringKey/localizable(_:)``
    /// in order for localized values to be resolved within the SwiftUI environment:
    ///
    /// ```swift
    /// var body: some View {
    ///     List {
    ///         Text(localizable: .listContent)
    ///     }
    ///     .navigationTitle(.localizable(.navigationTitle))
    ///     .environment(\.locale, Locale(identifier: "fr"))
    /// }
    /// ```
    ///
    /// - SeeAlso: [XCStrings Tool Documentation - Using the generated source code](https://swiftpackageindex.com/liamnichols/xcstrings-tool/0.5.1/documentation/documentation/using-the-generated-source-code)
    internal struct Localizable: Sendable {
        enum BundleDescription: Sendable {
            case main
            case atURL(URL)
            case forClass(AnyClass)

            #if !SWIFT_PACKAGE
            private class BundleLocator {
            }
            #endif

            static var current: BundleDescription {
                #if SWIFT_PACKAGE
                .atURL(Bundle.module.bundleURL)
                #else
                .forClass(BundleLocator.self)
                #endif
            }
        }

        enum Argument: Sendable {
            case int(Int)
            case uint(UInt)
            case float(Float)
            case double(Double)
            case object(String)

            var value: any CVarArg {
                switch self {
                case .int(let value):
                    value
                case .uint(let value):
                    value
                case .float(let value):
                    value
                case .double(let value):
                    value
                case .object(let value):
                    value
                }
            }
        }

        let key: StaticString
        let arguments: [Argument]
        let table: String?
        let bundle: BundleDescription

        fileprivate init(
            key: StaticString,
            arguments: [Argument],
            table: String?,
            bundle: BundleDescription
        ) {
            self.key = key
            self.arguments = arguments
            self.table = table
            self.bundle = bundle
        }

        /// ### Source Localization
        ///
        /// ```
        /// About
        /// ```
        internal static var about: Localizable {
            Localizable(
                key: "about",
                arguments: [],
                table: "Localizable",
                bundle: .current
            )
        }

        /// ### Source Localization
        ///
        /// ```
        /// Nos is a new social media app built on the Nostr protocol from the team that brought you Planetary. Designed for humans, not algorithms. Learn more at Nos.social.
        /// ```
        internal static var aboutNos: Localizable {
            Localizable(
                key: "aboutNos",
                arguments: [],
                table: "Localizable",
                bundle: .current
            )
        }

        /// ### Source Localization
        ///
        /// ```
        /// Learn more at Nos.social.
        /// ```
        internal static var aboutNosHighlight: Localizable {
            Localizable(
                key: "aboutNosHighlight",
                arguments: [],
                table: "Localizable",
                bundle: .current
            )
        }

        /// ### Source Localization
        ///
        /// ```
        /// Nostr is an open social media ecosystem that puts you in control of your online relationships. Nos is just one of many apps that speak the Nostr language, and you can pick your servers too. Learn more about why Nostr is great.
        /// ```
        internal static var aboutNostr: Localizable {
            Localizable(
                key: "aboutNostr",
                arguments: [],
                table: "Localizable",
                bundle: .current
            )
        }

        /// ### Source Localization
        ///
        /// ```
        /// Learn more about why Nostr is great.
        /// ```
        internal static var aboutNostrHighlight: Localizable {
            Localizable(
                key: "aboutNostrHighlight",
                arguments: [],
                table: "Localizable",
                bundle: .current
            )
        }

        /// ### Source Localization
        ///
        /// ```
        /// Accept
        /// ```
        internal static var accept: Localizable {
            Localizable(
                key: "accept",
                arguments: [],
                table: "Localizable",
                bundle: .current
            )
        }

        /// ### Source Localization
        ///
        /// ```
        /// Activity
        /// ```
        internal static var activity: Localizable {
            Localizable(
                key: "activity",
                arguments: [],
                table: "Localizable",
                bundle: .current
            )
        }

        /// ### Source Localization
        ///
        /// ```
        /// Add Item
        /// ```
        internal static var addItem: Localizable {
            Localizable(
                key: "addItem",
                arguments: [],
                table: "Localizable",
                bundle: .current
            )
        }

        /// ### Source Localization
        ///
        /// ```
        /// Add Relay
        /// ```
        internal static var addRelay: Localizable {
            Localizable(
                key: "addRelay",
                arguments: [],
                table: "Localizable",
                bundle: .current
            )
        }

        /// ### Source Localization
        ///
        /// ```
        /// Address
        /// ```
        internal static var address: Localizable {
            Localizable(
                key: "address",
                arguments: [],
                table: "Localizable",
                bundle: .current
            )
        }

        /// ### Source Localization
        ///
        /// ```
        /// For legal reasons, we need to make sure you're over this age to use Nos
        /// ```
        internal static var ageVerificationSubtitle: Localizable {
            Localizable(
                key: "ageVerificationSubtitle",
                arguments: [],
                table: "Localizable",
                bundle: .current
            )
        }

        /// ### Source Localization
        ///
        /// ```
        /// Are you over 16 years old?
        /// ```
        internal static var ageVerificationTitle: Localizable {
            Localizable(
                key: "ageVerificationTitle",
                arguments: [],
                table: "Localizable",
                bundle: .current
            )
        }

        /// ### Source Localization
        ///
        /// ```
        /// All My Relays
        /// ```
        internal static var allMyRelays: Localizable {
            Localizable(
                key: "allMyRelays",
                arguments: [],
                table: "Localizable",
                bundle: .current
            )
        }

        /// ### Source Localization
        ///
        /// ```
        /// All published events
        /// ```
        internal static var allPublishedEvents: Localizable {
            Localizable(
                key: "allPublishedEvents",
                arguments: [],
                table: "Localizable",
                bundle: .current
            )
        }

        /// ### Source Localization
        ///
        /// ```
        /// No, thanks. I already have a NIP-05
        /// ```
        internal static var alreadyHaveANIP05: Localizable {
            Localizable(
                key: "alreadyHaveANIP05",
                arguments: [],
                table: "Localizable",
                bundle: .current
            )
        }

        /// ### Source Localization
        ///
        /// ```
        /// Amount
        /// ```
        internal static var amount: Localizable {
            Localizable(
                key: "amount",
                arguments: [],
                table: "Localizable",
                bundle: .current
            )
        }

        /// ### Source Localization
        ///
        /// ```
        /// An error occured.
        /// ```
        internal static var anErrorOccurred: Localizable {
            Localizable(
                key: "anErrorOccurred",
                arguments: [],
                table: "Localizable",
                bundle: .current
            )
        }

        /// ### Source Localization
        ///
        /// ```
        /// None of your relays support expiring messages. Please add one and retry.
        /// ```
        internal static var anyRelaysSupportingNIP40: Localizable {
            Localizable(
                key: "anyRelaysSupportingNIP40",
                arguments: [],
                table: "Localizable",
                bundle: .current
            )
        }

        /// ### Source Localization
        ///
        /// ```
        /// App Version:
        /// ```
        internal static var appVersion: Localizable {
            Localizable(
                key: "appVersion",
                arguments: [],
                table: "Localizable",
                bundle: .current
            )
        }

        /// ### Source Localization
        ///
        /// ```
        /// Attach Media
        /// ```
        internal static var attachMedia: Localizable {
            Localizable(
                key: "attachMedia",
                arguments: [],
                table: "Localizable",
                bundle: .current
            )
        }

        /// ### Source Localization
        ///
        /// ```
        /// Logging out will delete your private key (nsec) from the app. Make sure you have your private key backed up before you do this or you will lose access to your account!
        /// ```
        internal static var backUpYourKeyWarning: Localizable {
            Localizable(
                key: "backUpYourKeyWarning",
                arguments: [],
                table: "Localizable",
                bundle: .current
            )
        }

        /// ### Source Localization
        ///
        /// ```
        /// Basic Information
        /// ```
        internal static var basicInfo: Localizable {
            Localizable(
                key: "basicInfo",
                arguments: [],
                table: "Localizable",
                bundle: .current
            )
        }

        /// ### Source Localization
        ///
        /// ```
        /// Bio
        /// ```
        internal static var bio: Localizable {
            Localizable(
                key: "bio",
                arguments: [],
                table: "Localizable",
                bundle: .current
            )
        }

        /// ### Source Localization
        ///
        /// ```
        /// This user hasn't written a bio yet 👻
        /// ```
        internal static var bioMissing: Localizable {
            Localizable(
                key: "bioMissing",
                arguments: [],
                table: "Localizable",
                bundle: .current
            )
        }

        /// ### Source Localization
        ///
        /// ```
        /// Cancel
        /// ```
        internal static var cancel: Localizable {
            Localizable(
                key: "cancel",
                arguments: [],
                table: "Localizable",
                bundle: .current
            )
        }

        /// ### Source Localization
        ///
        /// ```
        /// Choose from your existing names, or register a new one:
        /// ```
        internal static var chooseNameOrRegister: Localizable {
            Localizable(
                key: "chooseNameOrRegister",
                arguments: [],
                table: "Localizable",
                bundle: .current
            )
        }

        /// ### Source Localization
        ///
        /// ```
        /// Choose your handle
        /// ```
        internal static var chooseYourHandle: Localizable {
            Localizable(
                key: "chooseYourHandle",
                arguments: [],
                table: "Localizable",
                bundle: .current
            )
        }

        /// ### Source Localization
        ///
        /// ```
        /// This is how others will see you on Nos, and also a public URL to your profile.
        ///
        /// You can change this later.
        /// ```
        internal static var chooseYourHandleDescription: Localizable {
            Localizable(
                key: "chooseYourHandleDescription",
                arguments: [],
                table: "Localizable",
                bundle: .current
            )
        }

        /// ### Source Localization
        ///
        /// ```
        /// Choose your name
        /// ```
        internal static var chooseYourName: Localizable {
            Localizable(
                key: "chooseYourName",
                arguments: [],
                table: "Localizable",
                bundle: .current
            )
        }

        /// ### Source Localization
        ///
        /// ```
        /// This will be your Universal Name. You can register more later. Valid names
        /// ```
        internal static var chooseYourNameDescription: Localizable {
            Localizable(
                key: "chooseYourNameDescription",
                arguments: [],
                table: "Localizable",
                bundle: .current
            )
        }

        /// ### Source Localization
        ///
        /// ```
        /// Welcome to Nos, where your voice matters. Begin your journey by securing your unique **@username**.nos.social
        ///
        /// Stand out in the decentralized world!
        /// ```
        internal static var claimUniqueUsernameDescription: Localizable {
            Localizable(
                key: "claimUniqueUsernameDescription",
                arguments: [],
                table: "Localizable",
                bundle: .current
            )
        }

        /// ### Source Localization
        ///
        /// ```
        /// Claim your unique identity on Nostr
        /// ```
        internal static var claimUniqueUsernameTitle: Localizable {
            Localizable(
                key: "claimUniqueUsernameTitle",
                arguments: [],
                table: "Localizable",
                bundle: .current
            )
        }

        /// ### Source Localization
        ///
        /// ```
        /// Get it now
        /// ```
        internal static var claimYourUsernameButton: Localizable {
            Localizable(
                key: "claimYourUsernameButton",
                arguments: [],
                table: "Localizable",
                bundle: .current
            )
        }

        /// ### Source Localization
        ///
        /// ```
        /// Claim your @username and stand out on the decentralized world!
        /// ```
        internal static var claimYourUsernameText: Localizable {
            Localizable(
                key: "claimYourUsernameText",
                arguments: [],
                table: "Localizable",
                bundle: .current
            )
        }

        /// ### Source Localization
        ///
        /// ```
        /// Clear
        /// ```
        internal static var clear: Localizable {
            Localizable(
                key: "clear",
                arguments: [],
                table: "Localizable",
                bundle: .current
            )
        }

        /// ### Source Localization
        ///
        /// ```
        /// Complete My Profile
        /// ```
        internal static var completeProfileButton: Localizable {
            Localizable(
                key: "completeProfileButton",
                arguments: [],
                table: "Localizable",
                bundle: .current
            )
        }

        /// ### Source Localization
        ///
        /// ```
        /// Finish setting up your profile to help people find you.
        /// ```
        internal static var completeProfileMessage: Localizable {
            Localizable(
                key: "completeProfileMessage",
                arguments: [],
                table: "Localizable",
                bundle: .current
            )
        }

        /// ### Source Localization
        ///
        /// ```
        /// Confirm
        /// ```
        internal static var confirm: Localizable {
            Localizable(
                key: "confirm",
                arguments: [],
                table: "Localizable",
                bundle: .current
            )
        }

        /// ### Source Localization
        ///
        /// ```
        /// Confirm Delete
        /// ```
        internal static var confirmDelete: Localizable {
            Localizable(
                key: "confirmDelete",
                arguments: [],
                table: "Localizable",
                bundle: .current
            )
        }

        /// ### Source Localization
        ///
        /// ```
        /// Confirm Flag
        /// ```
        internal static var confirmFlag: Localizable {
            Localizable(
                key: "confirmFlag",
                arguments: [],
                table: "Localizable",
                bundle: .current
            )
        }

        /// ### Source Localization
        ///
        /// ```
        /// Connect GlobaliD app
        /// ```
        internal static var connectGlobalID: Localizable {
            Localizable(
                key: "connectGlobalID",
                arguments: [],
                table: "Localizable",
                bundle: .current
            )
        }

        /// ### Source Localization
        ///
        /// ```
        /// Connect your GlobaliD wallet to send USBC
        /// ```
        internal static var connectGlobalIDTitle: Localizable {
            Localizable(
                key: "connectGlobalIDTitle",
                arguments: [],
                table: "Localizable",
                bundle: .current
            )
        }

        /// ### Source Localization
        ///
        /// ```
        /// Connect Wallet
        /// ```
        internal static var connectWallet: Localizable {
            Localizable(
                key: "connectWallet",
                arguments: [],
                table: "Localizable",
                bundle: .current
            )
        }

        /// ### Source Localization
        ///
        /// ```
        /// Contact
        /// ```
        internal static var contact: Localizable {
            Localizable(
                key: "contact",
                arguments: [],
                table: "Localizable",
                bundle: .current
            )
        }

        /// ### Source Localization
        ///
        /// ```
        /// Contact Us
        /// ```
        internal static var contactUs: Localizable {
            Localizable(
                key: "contactUs",
                arguments: [],
                table: "Localizable",
                bundle: .current
            )
        }

        /// ### Source Localization
        ///
        /// ```
        /// Nos is committed to fostering safe and respectful community. To achieve this we display content warnings when someone you follow flags a note. You can change this in the settings menu.
        /// ```
        internal static var contentWarningExplanation: Localizable {
            Localizable(
                key: "contentWarningExplanation",
                arguments: [],
                table: "Localizable",
                bundle: .current
            )
        }

        /// ### Source Localization
        ///
        /// ```
        /// Copied!
        /// ```
        internal static var copied: Localizable {
            Localizable(
                key: "copied",
                arguments: [],
                table: "Localizable",
                bundle: .current
            )
        }

        /// ### Source Localization
        ///
        /// ```
        /// Copy
        /// ```
        internal static var copy: Localizable {
            Localizable(
                key: "copy",
                arguments: [],
                table: "Localizable",
                bundle: .current
            )
        }

        /// ### Source Localization
        ///
        /// ```
        /// Copy Link
        /// ```
        internal static var copyLink: Localizable {
            Localizable(
                key: "copyLink",
                arguments: [],
                table: "Localizable",
                bundle: .current
            )
        }

        /// ### Source Localization
        ///
        /// ```
        /// Copy Note Identifier
        /// ```
        internal static var copyNoteIdentifier: Localizable {
            Localizable(
                key: "copyNoteIdentifier",
                arguments: [],
                table: "Localizable",
                bundle: .current
            )
        }

        /// ### Source Localization
        ///
        /// ```
        /// Copy Note Text
        /// ```
        internal static var copyNoteText: Localizable {
            Localizable(
                key: "copyNoteText",
                arguments: [],
                table: "Localizable",
                bundle: .current
            )
        }

        /// ### Source Localization
        ///
        /// ```
        /// Copy QR link
        /// ```
        internal static var copyQRLink: Localizable {
            Localizable(
                key: "copyQRLink",
                arguments: [],
                table: "Localizable",
                bundle: .current
            )
        }

        /// ### Source Localization
        ///
        /// ```
        /// Copy User ID (npub)
        /// ```
        internal static var copyUserIdentifier: Localizable {
            Localizable(
                key: "copyUserIdentifier",
                arguments: [],
                table: "Localizable",
                bundle: .current
            )
        }

        /// ### Source Localization
        ///
        /// ```
        /// Could not read your private key. Please verify that it is in nsec or hex format.
        /// ```
        internal static var couldNotReadPrivateKeyMessage: Localizable {
            Localizable(
                key: "couldNotReadPrivateKeyMessage",
                arguments: [],
                table: "Localizable",
                bundle: .current
            )
        }

        /// ### Source Localization
        ///
        /// ```
        /// Create a new name
        /// ```
        internal static var createNewName: Localizable {
            Localizable(
                key: "createNewName",
                arguments: [],
                table: "Localizable",
                bundle: .current
            )
        }

        /// ### Source Localization
        ///
        /// ```
        /// day
        /// ```
        internal static var dayAbbreviated: Localizable {
            Localizable(
                key: "dayAbbreviated",
                arguments: [],
                table: "Localizable",
                bundle: .current
            )
        }

        /// ### Source Localization
        ///
        /// ```
        /// days
        /// ```
        internal static var daysAbbreviated: Localizable {
            Localizable(
                key: "daysAbbreviated",
                arguments: [],
                table: "Localizable",
                bundle: .current
            )
        }

        /// ### Source Localization
        ///
        /// ```
        /// Debug
        /// ```
        internal static var debug: Localizable {
            Localizable(
                key: "debug",
                arguments: [],
                table: "Localizable",
                bundle: .current
            )
        }

        /// ### Source Localization
        ///
        /// ```
        /// Delete
        /// ```
        internal static var deleteNote: Localizable {
            Localizable(
                key: "deleteNote",
                arguments: [],
                table: "Localizable",
                bundle: .current
            )
        }

        /// ### Source Localization
        ///
        /// ```
        /// This will ask all your relay servers to permanently remove this note. Are you sure?
        /// ```
        internal static var deleteNoteConfirmation: Localizable {
            Localizable(
                key: "deleteNoteConfirmation",
                arguments: [],
                table: "Localizable",
                bundle: .current
            )
        }

        /// ### Source Localization
        ///
        /// ```
        /// Delete repost
        /// ```
        internal static var deleteRepost: Localizable {
            Localizable(
                key: "deleteRepost",
                arguments: [],
                table: "Localizable",
                bundle: .current
            )
        }

        /// ### Source Localization
        ///
        /// ```
        /// Yes, delete my NIP-05
        /// ```
        internal static var deleteUsername: Localizable {
            Localizable(
                key: "deleteUsername",
                arguments: [],
                table: "Localizable",
                bundle: .current
            )
        }

        /// ### Source Localization
        ///
        /// ```
        /// Are you sure you want to delete your NIP-05?
        /// ```
        internal static var deleteUsernameConfirmation: Localizable {
            Localizable(
                key: "deleteUsernameConfirmation",
                arguments: [],
                table: "Localizable",
                bundle: .current
            )
        }

        /// ### Source Localization
        ///
        /// ```
        /// Changing or removing your handle may cause web links to disconnect from your identity. **Proceed with caution.**
        /// ```
        internal static var deleteUsernameDescription: Localizable {
            Localizable(
                key: "deleteUsernameDescription",
                arguments: [],
                table: "Localizable",
                bundle: .current
            )
        }

        /// ### Source Localization
        ///
        /// ```
        /// Description
        /// ```
        internal static var description: Localizable {
            Localizable(
                key: "description",
                arguments: [],
                table: "Localizable",
                bundle: .current
            )
        }

        /// ### Source Localization
        ///
        /// ```
        /// Discover
        /// ```
        internal static var discover: Localizable {
            Localizable(
                key: "discover",
                arguments: [],
                table: "Localizable",
                bundle: .current
            )
        }

        /// ### Source Localization
        ///
        /// ```
        /// Dismiss
        /// ```
        internal static var dismiss: Localizable {
            Localizable(
                key: "dismiss",
                arguments: [],
                table: "Localizable",
                bundle: .current
            )
        }

        /// ### Source Localization
        ///
        /// ```
        /// Display name
        /// ```
        internal static var displayName: Localizable {
            Localizable(
                key: "displayName",
                arguments: [],
                table: "Localizable",
                bundle: .current
            )
        }

        /// ### Source Localization
        ///
        /// ```
        /// Done
        /// ```
        internal static var done: Localizable {
            Localizable(
                key: "done",
                arguments: [],
                table: "Localizable",
                bundle: .current
            )
        }

        /// ### Source Localization
        ///
        /// ```
        /// Edit
        /// ```
        internal static var edit: Localizable {
            Localizable(
                key: "edit",
                arguments: [],
                table: "Localizable",
                bundle: .current
            )
        }

        /// ### Source Localization
        ///
        /// ```
        /// Edit Profile
        /// ```
        internal static var editProfile: Localizable {
            Localizable(
                key: "editProfile",
                arguments: [],
                table: "Localizable",
                bundle: .current
            )
        }

        /// Setting for new media feature flag
        ///
        /// ### Source Localization
        ///
        /// ```
        /// Enable new media display
        /// ```
        internal static var enableNewMediaDisplay: Localizable {
            Localizable(
                key: "enableNewMediaDisplay",
                arguments: [],
                table: "Localizable",
                bundle: .current
            )
        }

        /// ### Source Localization
        ///
        /// ```
        /// Enter Code
        /// ```
        internal static var enterCode: Localizable {
            Localizable(
                key: "enterCode",
                arguments: [],
                table: "Localizable",
                bundle: .current
            )
        }

        /// ### Source Localization
        ///
        /// ```
        /// Error
        /// ```
        internal static var error: Localizable {
            Localizable(
                key: "error",
                arguments: [],
                table: "Localizable",
                bundle: .current
            )
        }

        /// ### Source Localization
        ///
        /// ```
        /// Raw Event
        /// ```
        internal static var eventSource: Localizable {
            Localizable(
                key: "eventSource",
                arguments: [],
                table: "Localizable",
                bundle: .current
            )
        }

        /// ### Source Localization
        ///
        /// ```
        /// Excellent choice! 🎉
        /// ```
        internal static var excellentChoice: Localizable {
            Localizable(
                key: "excellentChoice",
                arguments: [],
                table: "Localizable",
                bundle: .current
            )
        }

        /// ### Source Localization
        ///
        /// ```
        /// Expiration Date
        /// ```
        internal static var expirationDate: Localizable {
            Localizable(
                key: "expirationDate",
                arguments: [],
                table: "Localizable",
                bundle: .current
            )
        }

        /// ### Source Localization
        ///
        /// ```
        /// Failed to export logs.
        /// ```
        internal static var failedToExportLogs: Localizable {
            Localizable(
                key: "failedToExportLogs",
                arguments: [],
                table: "Localizable",
                bundle: .current
            )
        }

        /// ### Source Localization
        ///
        /// ```
        /// Activists
        /// ```
        internal static var featuredAuthorCategoryActivists: Localizable {
            Localizable(
                key: "featuredAuthorCategoryActivists",
                arguments: [],
                table: "Localizable",
                bundle: .current
            )
        }

        /// ### Source Localization
        ///
        /// ```
        /// All
        /// ```
        internal static var featuredAuthorCategoryAll: Localizable {
            Localizable(
                key: "featuredAuthorCategoryAll",
                arguments: [],
                table: "Localizable",
                bundle: .current
            )
        }

        /// ### Source Localization
        ///
        /// ```
        /// Art
        /// ```
        internal static var featuredAuthorCategoryArt: Localizable {
            Localizable(
                key: "featuredAuthorCategoryArt",
                arguments: [],
                table: "Localizable",
                bundle: .current
            )
        }

        /// ### Source Localization
        ///
        /// ```
        /// Gaming
        /// ```
        internal static var featuredAuthorCategoryGaming: Localizable {
            Localizable(
                key: "featuredAuthorCategoryGaming",
                arguments: [],
                table: "Localizable",
                bundle: .current
            )
        }

        /// ### Source Localization
        ///
        /// ```
        /// Health
        /// ```
        internal static var featuredAuthorCategoryHealth: Localizable {
            Localizable(
                key: "featuredAuthorCategoryHealth",
                arguments: [],
                table: "Localizable",
                bundle: .current
            )
        }

        /// ### Source Localization
        ///
        /// ```
        /// Music
        /// ```
        internal static var featuredAuthorCategoryMusic: Localizable {
            Localizable(
                key: "featuredAuthorCategoryMusic",
                arguments: [],
                table: "Localizable",
                bundle: .current
            )
        }

        /// ### Source Localization
        ///
        /// ```
        /// New
        /// ```
        internal static var featuredAuthorCategoryNew: Localizable {
            Localizable(
                key: "featuredAuthorCategoryNew",
                arguments: [],
                table: "Localizable",
                bundle: .current
            )
        }

        /// ### Source Localization
        ///
        /// ```
        /// News
        /// ```
        internal static var featuredAuthorCategoryNews: Localizable {
            Localizable(
                key: "featuredAuthorCategoryNews",
                arguments: [],
                table: "Localizable",
                bundle: .current
            )
        }

        /// ### Source Localization
        ///
        /// ```
        /// Sports
        /// ```
        internal static var featuredAuthorCategorySports: Localizable {
            Localizable(
                key: "featuredAuthorCategorySports",
                arguments: [],
                table: "Localizable",
                bundle: .current
            )
        }

        /// ### Source Localization
        ///
        /// ```
        /// Tech
        /// ```
        internal static var featuredAuthorCategoryTech: Localizable {
            Localizable(
                key: "featuredAuthorCategoryTech",
                arguments: [],
                table: "Localizable",
                bundle: .current
            )
        }

        /// ### Source Localization
        ///
        /// ```
        /// Feed Settings
        /// ```
        internal static var feedSettings: Localizable {
            Localizable(
                key: "feedSettings",
                arguments: [],
                table: "Localizable",
                bundle: .current
            )
        }

        /// ### Source Localization
        ///
        /// ```
        /// Fetched
        /// ```
        internal static var fetchedAt: Localizable {
            Localizable(
                key: "fetchedAt",
                arguments: [],
                table: "Localizable",
                bundle: .current
            )
        }

        /// ### Source Localization
        ///
        /// ```
        /// Flag this user
        /// ```
        internal static var flagUser: Localizable {
            Localizable(
                key: "flagUser",
                arguments: [],
                table: "Localizable",
                bundle: .current
            )
        }

        /// ### Source Localization
        ///
        /// ```
        /// Create a flag for this user that other users in the network can see.
        /// ```
        internal static var flagUserMessage: Localizable {
            Localizable(
                key: "flagUserMessage",
                arguments: [],
                table: "Localizable",
                bundle: .current
            )
        }

        /// ### Source Localization
        ///
        /// ```
        /// Follow
        /// ```
        internal static var follow: Localizable {
            Localizable(
                key: "follow",
                arguments: [],
                table: "Localizable",
                bundle: .current
            )
        }

        /// ### Source Localization
        ///
        /// ```
        /// Followed by **%@**
        /// ```
        internal static func followedByOne(_ arg1: String) -> Localizable {
            Localizable(
                key: "followedByOne",
                arguments: [
                    .object(arg1)
                ],
                table: "Localizable",
                bundle: .current
            )
        }

        /// ### Source Localization
        ///
        /// ```
        /// Followed by **%1$@** and **%2$lld others**
        /// ```
        internal static func followedByOneAndMore(_ arg1: String, _ arg2: Int) -> Localizable {
            Localizable(
                key: "followedByOneAndMore",
                arguments: [
                    .object(arg1),
                    .int(arg2)
                ],
                table: "Localizable",
                bundle: .current
            )
        }

        /// ### Source Localization
        ///
        /// ```
        /// Followed by **%1$@** and **%2$@**
        /// ```
        internal static func followedByTwo(_ arg1: String, _ arg2: String) -> Localizable {
            Localizable(
                key: "followedByTwo",
                arguments: [
                    .object(arg1),
                    .object(arg2)
                ],
                table: "Localizable",
                bundle: .current
            )
        }

        /// ### Source Localization
        ///
        /// ```
        /// Followed by **%1$@**, **%2$@** and **%3$lld others**
        /// ```
        internal static func followedByTwoAndMore(_ arg1: String, _ arg2: String, _ arg3: Int) -> Localizable {
            Localizable(
                key: "followedByTwoAndMore",
                arguments: [
                    .object(arg1),
                    .object(arg2),
                    .int(arg3)
                ],
                table: "Localizable",
                bundle: .current
            )
        }

        /// ### Source Localization
        ///
        /// ```
        /// Followers
        /// ```
        internal static var followers: Localizable {
            Localizable(
                key: "followers",
                arguments: [],
                table: "Localizable",
                bundle: .current
            )
        }

        /// ### Source Localization
        ///
        /// ```
        /// Followers you know
        /// ```
        internal static var followersYouKnow: Localizable {
            Localizable(
                key: "followersYouKnow",
                arguments: [],
                table: "Localizable",
                bundle: .current
            )
        }

        /// ### Source Localization
        ///
        /// ```
        /// Following
        /// ```
        internal static var following: Localizable {
            Localizable(
                key: "following",
                arguments: [],
                table: "Localizable",
                bundle: .current
            )
        }

        /// ### Source Localization
        ///
        /// ```
        /// Follows
        /// ```
        internal static var follows: Localizable {
            Localizable(
                key: "follows",
                arguments: [],
                table: "Localizable",
                bundle: .current
            )
        }

        /// ### Source Localization
        ///
        /// ```
        /// Get My Handle
        /// ```
        internal static var getMyHandle: Localizable {
            Localizable(
                key: "getMyHandle",
                arguments: [],
                table: "Localizable",
                bundle: .current
            )
        }

        /// ### Source Localization
        ///
        /// ```
        /// Go back
        /// ```
        internal static var goBack: Localizable {
            Localizable(
                key: "goBack",
                arguments: [],
                table: "Localizable",
                bundle: .current
            )
        }

        /// ### Source Localization
        ///
        /// ```
        /// You may want to go back and register a different name
        /// ```
        internal static var goBackAndRegister: Localizable {
            Localizable(
                key: "goBackAndRegister",
                arguments: [],
                table: "Localizable",
                bundle: .current
            )
        }

        /// ### Source Localization
        ///
        /// ```
        /// Feed
        /// ```
        internal static var homeFeed: Localizable {
            Localizable(
                key: "homeFeed",
                arguments: [],
                table: "Localizable",
                bundle: .current
            )
        }

        /// ### Source Localization
        ///
        /// ```
        /// hour
        /// ```
        internal static var hourAbbreviated: Localizable {
            Localizable(
                key: "hourAbbreviated",
                arguments: [],
                table: "Localizable",
                bundle: .current
            )
        }

        /// ### Source Localization
        ///
        /// ```
        /// hours
        /// ```
        internal static var hoursAbbreviated: Localizable {
            Localizable(
                key: "hoursAbbreviated",
                arguments: [],
                table: "Localizable",
                bundle: .current
            )
        }

        /// ### Source Localization
        ///
        /// ```
        /// Identity verification
        /// ```
        internal static var identityVerification: Localizable {
            Localizable(
                key: "identityVerification",
                arguments: [],
                table: "Localizable",
                bundle: .current
            )
        }

        /// ### Source Localization
        ///
        /// ```
        /// Invalid Key
        /// ```
        internal static var invalidKey: Localizable {
            Localizable(
                key: "invalidKey",
                arguments: [],
                table: "Localizable",
                bundle: .current
            )
        }

        /// ### Source Localization
        ///
        /// ```
        /// Please enter a valid websocket URL.
        /// ```
        internal static var invalidURLError: Localizable {
            Localizable(
                key: "invalidURLError",
                arguments: [],
                table: "Localizable",
                bundle: .current
            )
        }

        /// ### Source Localization
        ///
        /// ```
        /// Keys
        /// ```
        internal static var keys: Localizable {
            Localizable(
                key: "keys",
                arguments: [],
                table: "Localizable",
                bundle: .current
            )
        }

        /// ### Source Localization
        ///
        /// ```
        /// Learn more
        /// ```
        internal static var learnMore: Localizable {
            Localizable(
                key: "learnMore",
                arguments: [],
                table: "Localizable",
                bundle: .current
            )
        }

        /// ### Source Localization
        ///
        /// ```
        /// 🔗 Link to note
        /// ```
        internal static var linkToNote: Localizable {
            Localizable(
                key: "linkToNote",
                arguments: [],
                table: "Localizable",
                bundle: .current
            )
        }

        /// ### Source Localization
        ///
        /// ```
        /// Enter your existing NIP-05 here:
        /// ```
        internal static var linkYourNIP05Description: Localizable {
            Localizable(
                key: "linkYourNIP05Description",
                arguments: [],
                table: "Localizable",
                bundle: .current
            )
        }

        /// ### Source Localization
        ///
        /// ```
        /// Already have a NIP-05?
        /// ```
        internal static var linkYourNIP05Title: Localizable {
            Localizable(
                key: "linkYourNIP05Title",
                arguments: [],
                table: "Localizable",
                bundle: .current
            )
        }

        /// ### Source Localization
        ///
        /// ```
        /// Loading...
        /// ```
        internal static var loading: Localizable {
            Localizable(
                key: "loading",
                arguments: [],
                table: "Localizable",
                bundle: .current
            )
        }

        /// ### Source Localization
        ///
        /// ```
        /// Load Sample Data
        /// ```
        internal static var loadSampleData: Localizable {
            Localizable(
                key: "loadSampleData",
                arguments: [],
                table: "Localizable",
                bundle: .current
            )
        }

        /// ### Source Localization
        ///
        /// ```
        /// Login
        /// ```
        internal static var login: Localizable {
            Localizable(
                key: "login",
                arguments: [],
                table: "Localizable",
                bundle: .current
            )
        }

        /// ### Source Localization
        ///
        /// ```
        /// Login with key
        /// ```
        internal static var loginWithKey: Localizable {
            Localizable(
                key: "loginWithKey",
                arguments: [],
                table: "Localizable",
                bundle: .current
            )
        }

        /// ### Source Localization
        ///
        /// ```
        /// Login with your keys
        /// ```
        internal static var logInWithYourKeys: Localizable {
            Localizable(
                key: "logInWithYourKeys",
                arguments: [],
                table: "Localizable",
                bundle: .current
            )
        }

        /// ### Source Localization
        ///
        /// ```
        /// Logout
        /// ```
        internal static var logout: Localizable {
            Localizable(
                key: "logout",
                arguments: [],
                table: "Localizable",
                bundle: .current
            )
        }

        /// ### Source Localization
        ///
        /// ```
        /// Manage your Universal Name
        /// ```
        internal static var manageUniversalName: Localizable {
            Localizable(
                key: "manageUniversalName",
                arguments: [],
                table: "Localizable",
                bundle: .current
            )
        }

        /// ### Source Localization
        ///
        /// ```
        /// Mention
        /// ```
        internal static var mention: Localizable {
            Localizable(
                key: "mention",
                arguments: [],
                table: "Localizable",
                bundle: .current
            )
        }

        /// ### Source Localization
        ///
        /// ```
        /// Metadata
        /// ```
        internal static var metadata: Localizable {
            Localizable(
                key: "metadata",
                arguments: [],
                table: "Localizable",
                bundle: .current
            )
        }

        /// ### Source Localization
        ///
        /// ```
        /// min
        /// ```
        internal static var minuteAbbreviated: Localizable {
            Localizable(
                key: "minuteAbbreviated",
                arguments: [],
                table: "Localizable",
                bundle: .current
            )
        }

        /// ### Source Localization
        ///
        /// ```
        /// Mute
        /// ```
        internal static var mute: Localizable {
            Localizable(
                key: "mute",
                arguments: [],
                table: "Localizable",
                bundle: .current
            )
        }

        /// ### Source Localization
        ///
        /// ```
        /// Muted
        /// ```
        internal static var muted: Localizable {
            Localizable(
                key: "muted",
                arguments: [],
                table: "Localizable",
                bundle: .current
            )
        }

        /// ### Source Localization
        ///
        /// ```
        /// Muted Users
        /// ```
        internal static var mutedUsers: Localizable {
            Localizable(
                key: "mutedUsers",
                arguments: [],
                table: "Localizable",
                bundle: .current
            )
        }

        /// ### Source Localization
        ///
        /// ```
        /// Would you like to mute %@?
        /// ```
        internal static func mutePrompt(_ arg1: String) -> Localizable {
            Localizable(
                key: "mutePrompt",
                arguments: [
                    .object(arg1)
                ],
                table: "Localizable",
                bundle: .current
            )
        }

        /// ### Source Localization
        ///
        /// ```
        /// Mute User
        /// ```
        internal static var muteUser: Localizable {
            Localizable(
                key: "muteUser",
                arguments: [],
                table: "Localizable",
                bundle: .current
            )
        }

        /// ### Source Localization
        ///
        /// ```
        /// My key is backed up
        /// ```
        internal static var myKeyIsBackedUp: Localizable {
            Localizable(
                key: "myKeyIsBackedUp",
                arguments: [],
                table: "Localizable",
                bundle: .current
            )
        }

        /// ### Source Localization
        ///
        /// ```
        /// Name
        /// ```
        internal static var name: Localizable {
            Localizable(
                key: "name",
                arguments: [],
                table: "Localizable",
                bundle: .current
            )
        }

        /// ### Source Localization
        ///
        /// ```
        /// name
        /// ```
        internal static var nameLower: Localizable {
            Localizable(
                key: "nameLower",
                arguments: [],
                table: "Localizable",
                bundle: .current
            )
        }

        /// ### Source Localization
        ///
        /// ```
        /// New
        /// ```
        internal static var new: Localizable {
            Localizable(
                key: "new",
                arguments: [],
                table: "Localizable",
                bundle: .current
            )
        }

        /// ### Source Localization
        ///
        /// ```
        /// New Note
        /// ```
        internal static var newNote: Localizable {
            Localizable(
                key: "newNote",
                arguments: [],
                table: "Localizable",
                bundle: .current
            )
        }

        /// ### Source Localization
        ///
        /// ```
        /// Type your post here...
        /// ```
        internal static var newNotePlaceholder: Localizable {
            Localizable(
                key: "newNotePlaceholder",
                arguments: [],
                table: "Localizable",
                bundle: .current
            )
        }

        /// ### Source Localization
        ///
        /// ```
        /// Next
        /// ```
        internal static var next: Localizable {
            Localizable(
                key: "next",
                arguments: [],
                table: "Localizable",
                bundle: .current
            )
        }

        /// ### Source Localization
        ///
        /// ```
        /// Nice work!
        /// ```
        internal static var niceWork: Localizable {
            Localizable(
                key: "niceWork",
                arguments: [],
                table: "Localizable",
                bundle: .current
            )
        }

        /// ### Source Localization
        ///
        /// ```
        /// NIP-05
        /// ```
        internal static var nip05: Localizable {
            Localizable(
                key: "nip05",
                arguments: [],
                table: "Localizable",
                bundle: .current
            )
        }

        /// ### Source Localization
        ///
        /// ```
        /// Your NIP-05 is now connected to your npub in the Nostr network.
        /// ```
        internal static var nip05Connected: Localizable {
            Localizable(
                key: "nip05Connected",
                arguments: [],
                table: "Localizable",
                bundle: .current
            )
        }

        /// ### Source Localization
        ///
        /// ```
        /// user@server.com
        /// ```
        internal static var nip05Example: Localizable {
            Localizable(
                key: "nip05Example",
                arguments: [],
                table: "Localizable",
                bundle: .current
            )
        }

        /// ### Source Localization
        ///
        /// ```
        /// Learn more about NIP-05 name verification.
        /// ```
        internal static var nip05LearnMore: Localizable {
            Localizable(
                key: "nip05LearnMore",
                arguments: [],
                table: "Localizable",
                bundle: .current
            )
        }

        /// ### Source Localization
        ///
        /// ```
        /// **The NIP05 entered does not match the records of the NIP-05 provider.**
        ///
        /// Please verify the entry of the NIP-05 and try again. Or reach out to the NIP05 provider directly to verify your NIP05 is live.
        /// ```
        internal static var nip05LinkFailed: Localizable {
            Localizable(
                key: "nip05LinkFailed",
                arguments: [],
                table: "Localizable",
                bundle: .current
            )
        }

        /// ### Source Localization
        ///
        /// ```
        /// No
        /// ```
        internal static var no: Localizable {
            Localizable(
                key: "no",
                arguments: [],
                table: "Localizable",
                bundle: .current
            )
        }

        /// ### Source Localization
        ///
        /// ```
        /// No notes (yet)! Browse the Discover tab and follow some people to get started.
        /// ```
        internal static var noEvents: Localizable {
            Localizable(
                key: "noEvents",
                arguments: [],
                table: "Localizable",
                bundle: .current
            )
        }

        /// ### Source Localization
        ///
        /// ```
        /// We don't see any notes for this profile, but we'll keep looking!
        /// ```
        internal static var noEventsOnProfile: Localizable {
            Localizable(
                key: "noEventsOnProfile",
                arguments: [],
                table: "Localizable",
                bundle: .current
            )
        }

        /// ### Source Localization
        ///
        /// ```
        /// No notifications (yet)!
        /// ```
        internal static var noNotifications: Localizable {
            Localizable(
                key: "noNotifications",
                arguments: [],
                table: "Localizable",
                bundle: .current
            )
        }

        /// ### Source Localization
        ///
        /// ```
        /// No relays yet! Add one below to get started
        /// ```
        internal static var noRelaysMessage: Localizable {
            Localizable(
                key: "noRelaysMessage",
                arguments: [],
                table: "Localizable",
                bundle: .current
            )
        }

        /// ### Source Localization
        ///
        /// ```
        /// Nos
        /// ```
        internal static var nos: Localizable {
            Localizable(
                key: "nos",
                arguments: [],
                table: "Localizable",
                bundle: .current
            )
        }

        /// ### Source Localization
        ///
        /// ```
        /// Nos is open source! You can read the code, contribute new features, or even fork it and build your own Nostr client. No opaque algorithms or secret rules. See the code.
        /// ```
        internal static var nosIsOpenSource: Localizable {
            Localizable(
                key: "nosIsOpenSource",
                arguments: [],
                table: "Localizable",
                bundle: .current
            )
        }

        /// ### Source Localization
        ///
        /// ```
        /// See the code.
        /// ```
        internal static var nosIsOpenSourceHighlight: Localizable {
            Localizable(
                key: "nosIsOpenSourceHighlight",
                arguments: [],
                table: "Localizable",
                bundle: .current
            )
        }

        /// ### Source Localization
        ///
        /// ```
        /// note
        /// ```
        internal static var note: Localizable {
            Localizable(
                key: "note",
                arguments: [],
                table: "Localizable",
                bundle: .current
            )
        }

        /// ### Source Localization
        ///
        /// ```
        /// Note disappears in
        /// ```
        internal static var noteDisappearsIn: Localizable {
            Localizable(
                key: "noteDisappearsIn",
                arguments: [],
                table: "Localizable",
                bundle: .current
            )
        }

        /// ### Source Localization
        ///
        /// ```
        /// This note has been flagged by **%1$@** for %2$@.
        /// ```
        internal static func noteReportedByOne(_ arg1: String, _ arg2: String) -> Localizable {
            Localizable(
                key: "noteReportedByOne",
                arguments: [
                    .object(arg1),
                    .object(arg2)
                ],
                table: "Localizable",
                bundle: .current
            )
        }

        /// ### Source Localization
        ///
        /// ```
        /// This note has been flagged by **%1$@** and **%2$lld others** for %3$@.
        /// ```
        internal static func noteReportedByOneAndMore(_ arg1: String, _ arg2: Int, _ arg3: String) -> Localizable {
            Localizable(
                key: "noteReportedByOneAndMore",
                arguments: [
                    .object(arg1),
                    .int(arg2),
                    .object(arg3)
                ],
                table: "Localizable",
                bundle: .current
            )
        }

        /// ### Source Localization
        ///
        /// ```
        /// Notes
        /// ```
        internal static var notes: Localizable {
            Localizable(
                key: "notes",
                arguments: [],
                table: "Localizable",
                bundle: .current
            )
        }

        /// ### Source Localization
        ///
        /// ```
        /// We are not finding results on your relays. You can continue waiting or try another search term.
        /// ```
        internal static var notFindingResults: Localizable {
            Localizable(
                key: "notFindingResults",
                arguments: [],
                table: "Localizable",
                bundle: .current
            )
        }

        /// ### Source Localization
        ///
        /// ```
        /// Notifications
        /// ```
        internal static var notifications: Localizable {
            Localizable(
                key: "notifications",
                arguments: [],
                table: "Localizable",
                bundle: .current
            )
        }

        /// ### Source Localization
        ///
        /// ```
        /// Go back (to school)
        /// ```
        internal static var notOldEnoughButton: Localizable {
            Localizable(
                key: "notOldEnoughButton",
                arguments: [],
                table: "Localizable",
                bundle: .current
            )
        }

        /// ### Source Localization
        ///
        /// ```
        /// You need to be 16 years old to be able to use this app.
        /// ```
        internal static var notOldEnoughSubtitle: Localizable {
            Localizable(
                key: "notOldEnoughSubtitle",
                arguments: [],
                table: "Localizable",
                bundle: .current
            )
        }

        /// ### Source Localization
        ///
        /// ```
        /// Sorry, but Nos is not for you yet,
        /// ```
        internal static var notOldEnoughTitle: Localizable {
            Localizable(
                key: "notOldEnoughTitle",
                arguments: [],
                table: "Localizable",
                bundle: .current
            )
        }

        /// ### Source Localization
        ///
        /// ```
        /// now
        /// ```
        internal static var now: Localizable {
            Localizable(
                key: "now",
                arguments: [],
                table: "Localizable",
                bundle: .current
            )
        }

        /// ### Source Localization
        ///
        /// ```
        /// Ok
        /// ```
        internal static var ok: Localizable {
            Localizable(
                key: "ok",
                arguments: [],
                table: "Localizable",
                bundle: .current
            )
        }

        /// ### Source Localization
        ///
        /// ```
        /// the human network
        /// ```
        internal static var onboardingTitle: Localizable {
            Localizable(
                key: "onboardingTitle",
                arguments: [],
                table: "Localizable",
                bundle: .current
            )
        }

        /// ### Source Localization
        ///
        /// ```
        /// Oops!
        /// ```
        internal static var oops: Localizable {
            Localizable(
                key: "oops",
                arguments: [],
                table: "Localizable",
                bundle: .current
            )
        }

        /// ### Source Localization
        ///
        /// ```
        /// This user is outside your network.
        /// ```
        internal static var outsideNetwork: Localizable {
            Localizable(
                key: "outsideNetwork",
                arguments: [],
                table: "Localizable",
                bundle: .current
            )
        }

        /// ### Source Localization
        ///
        /// ```
        /// This note originates from someone beyond your 'friends of friends' network. Nos hides these by default. You can change this in the settings menu.
        /// ```
        internal static var outsideNetworkExplanation: Localizable {
            Localizable(
                key: "outsideNetworkExplanation",
                arguments: [],
                table: "Localizable",
                bundle: .current
            )
        }

        /// ### Source Localization
        ///
        /// ```
        /// Paste your secret key
        /// ```
        internal static var pasteYourSecretKey: Localizable {
            Localizable(
                key: "pasteYourSecretKey",
                arguments: [],
                table: "Localizable",
                bundle: .current
            )
        }

        /// ### Source Localization
        ///
        /// ```
        /// Your **@username** is your identity in the Nos community.
        ///
        /// Choose a name that reflects you or your organization. Make it memorable and distinct!
        /// ```
        internal static var pickYourUsernameDescription: Localizable {
            Localizable(
                key: "pickYourUsernameDescription",
                arguments: [],
                table: "Localizable",
                bundle: .current
            )
        }

        /// ### Source Localization
        ///
        /// ```
        /// Pick your @username
        /// ```
        internal static var pickYourUsernameTitle: Localizable {
            Localizable(
                key: "pickYourUsernameTitle",
                arguments: [],
                table: "Localizable",
                bundle: .current
            )
        }

        /// ### Source Localization
        ///
        /// ```
        /// Post
        /// ```
        internal static var post: Localizable {
            Localizable(
                key: "post",
                arguments: [],
                table: "Localizable",
                bundle: .current
            )
        }

        /// ### Source Localization
        ///
        /// ```
        /// This is a Premium name
        /// ```
        internal static var premiumName: Localizable {
            Localizable(
                key: "premiumName",
                arguments: [],
                table: "Localizable",
                bundle: .current
            )
        }

        /// ### Source Localization
        ///
        /// ```
        /// You'll be redirected to the UNS website where you can register a premium name.
        /// ```
        internal static var premiumNameDescription: Localizable {
            Localizable(
                key: "premiumNameDescription",
                arguments: [],
                table: "Localizable",
                bundle: .current
            )
        }

        /// ### Source Localization
        ///
        /// ```
        /// Private Key
        /// ```
        internal static var privateKey: Localizable {
            Localizable(
                key: "privateKey",
                arguments: [],
                table: "Localizable",
                bundle: .current
            )
        }

        /// ### Source Localization
        ///
        /// ```
        /// nsec or hex...
        /// ```
        internal static var privateKeyPlaceholder: Localizable {
            Localizable(
                key: "privateKeyPlaceholder",
                arguments: [],
                table: "Localizable",
                bundle: .current
            )
        }

        /// ### Source Localization
        ///
        /// ```
        /// Never share your private key with anyone. Save your private key in a password manager so you can restore access to your account & data.
        /// ```
        internal static var privateKeyWarning: Localizable {
            Localizable(
                key: "privateKeyWarning",
                arguments: [],
                table: "Localizable",
                bundle: .current
            )
        }

        /// ### Source Localization
        ///
        /// ```
        /// Profile picture
        /// ```
        internal static var profilePicture: Localizable {
            Localizable(
                key: "profilePicture",
                arguments: [],
                table: "Localizable",
                bundle: .current
            )
        }

        /// ### Source Localization
        ///
        /// ```
        /// Profile
        /// ```
        internal static var profileTitle: Localizable {
            Localizable(
                key: "profileTitle",
                arguments: [],
                table: "Localizable",
                bundle: .current
            )
        }

        /// ### Source Localization
        ///
        /// ```
        /// Public key
        /// ```
        internal static var pubkey: Localizable {
            Localizable(
                key: "pubkey",
                arguments: [],
                table: "Localizable",
                bundle: .current
            )
        }

        /// ### Source Localization
        ///
        /// ```
        /// Read more
        /// ```
        internal static var readMore: Localizable {
            Localizable(
                key: "readMore",
                arguments: [],
                table: "Localizable",
                bundle: .current
            )
        }

        /// ### Source Localization
        ///
        /// ```
        /// Recommended Relays
        /// ```
        internal static var recommendedRelays: Localizable {
            Localizable(
                key: "recommendedRelays",
                arguments: [],
                table: "Localizable",
                bundle: .current
            )
        }

        /// ### Source Localization
        ///
        /// ```
        /// Reconnect wallet
        /// ```
        internal static var reconnectWallet: Localizable {
            Localizable(
                key: "reconnectWallet",
                arguments: [],
                table: "Localizable",
                bundle: .current
            )
        }

        /// ### Source Localization
        ///
        /// ```
        /// register a different name
        /// ```
        internal static var registerADifferentName: Localizable {
            Localizable(
                key: "registerADifferentName",
                arguments: [],
                table: "Localizable",
                bundle: .current
            )
        }

        /// ### Source Localization
        ///
        /// ```
        /// Register Premium Name
        /// ```
        internal static var registerPremiumName: Localizable {
            Localizable(
                key: "registerPremiumName",
                arguments: [],
                table: "Localizable",
                bundle: .current
            )
        }

        /// ### Source Localization
        ///
        /// ```
        /// Registration
        /// ```
        internal static var registration: Localizable {
            Localizable(
                key: "registration",
                arguments: [],
                table: "Localizable",
                bundle: .current
            )
        }

        /// ### Source Localization
        ///
        /// ```
        /// Enter your phone number so we can send you an SMS code.
        /// ```
        internal static var registrationDescription: Localizable {
            Localizable(
                key: "registrationDescription",
                arguments: [],
                table: "Localizable",
                bundle: .current
            )
        }

        /// ### Source Localization
        ///
        /// ```
        /// Reject
        /// ```
        internal static var reject: Localizable {
            Localizable(
                key: "reject",
                arguments: [],
                table: "Localizable",
                bundle: .current
            )
        }

        /// ### Source Localization
        ///
        /// ```
        /// Relay
        /// ```
        internal static var relay: Localizable {
            Localizable(
                key: "relay",
                arguments: [],
                table: "Localizable",
                bundle: .current
            )
        }

        /// ### Source Localization
        ///
        /// ```
        /// wss://yourrelay.com
        /// ```
        internal static var relayAddressPlaceholder: Localizable {
            Localizable(
                key: "relayAddressPlaceholder",
                arguments: [],
                table: "Localizable",
                bundle: .current
            )
        }

        /// ### Source Localization
        ///
        /// ```
        /// This relay doesn't support expiring messages. Please select another one.
        /// ```
        internal static var relayDoesNotSupportNIP40: Localizable {
            Localizable(
                key: "relayDoesNotSupportNIP40",
                arguments: [],
                table: "Localizable",
                bundle: .current
            )
        }

        /// ### Source Localization
        ///
        /// ```
        /// Relays
        /// ```
        internal static var relays: Localizable {
            Localizable(
                key: "relays",
                arguments: [],
                table: "Localizable",
                bundle: .current
            )
        }

        /// ### Source Localization
        ///
        /// ```
        /// Important! Nos works best with 5 or fewer relays.
        /// ```
        internal static var relaysImportantMessage: Localizable {
            Localizable(
                key: "relaysImportantMessage",
                arguments: [],
                table: "Localizable",
                bundle: .current
            )
        }

        /// ### Source Localization
        ///
        /// ```
        /// [ %@ ]
        /// Send to Nos or Flag Publicly
        /// ```
        internal static func reportActionTitle(_ arg1: String) -> Localizable {
            Localizable(
                key: "reportActionTitle",
                arguments: [
                    .object(arg1)
                ],
                table: "Localizable",
                bundle: .current
            )
        }

        /// ### Source Localization
        ///
        /// ```
        /// Nos will review this flag and apply it anonymously if the review matches the category.
        /// ```
        internal static var reportAuthorSendToNosConfirmation: Localizable {
            Localizable(
                key: "reportAuthorSendToNosConfirmation",
                arguments: [],
                table: "Localizable",
                bundle: .current
            )
        }

        /// ### Source Localization
        ///
        /// ```
        /// Report Content
        /// ```
        internal static var reportContent: Localizable {
            Localizable(
                key: "reportContent",
                arguments: [],
                table: "Localizable",
                bundle: .current
            )
        }

        /// ### Source Localization
        ///
        /// ```
        /// Create a content flag for this post that other users in the network can see
        /// ```
        internal static var reportContentMessage: Localizable {
            Localizable(
                key: "reportContentMessage",
                arguments: [],
                table: "Localizable",
                bundle: .current
            )
        }

        /// ### Source Localization
        ///
        /// ```
        /// This content has been flagged for %@.
        /// ```
        internal static func reportEventContent(_ arg1: String) -> Localizable {
            Localizable(
                key: "reportEventContent",
                arguments: [
                    .object(arg1)
                ],
                table: "Localizable",
                bundle: .current
            )
        }

        /// ### Source Localization
        ///
        /// ```
        /// Are you sure you want to flag this as %@? This flag will be public.
        /// ```
        internal static func reportFlagPubliclyConfirmation(_ arg1: String) -> Localizable {
            Localizable(
                key: "reportFlagPubliclyConfirmation",
                arguments: [
                    .object(arg1)
                ],
                table: "Localizable",
                bundle: .current
            )
        }

        /// ### Source Localization
        ///
        /// ```
        /// Flag This Content
        /// ```
        internal static var reportNote: Localizable {
            Localizable(
                key: "reportNote",
                arguments: [],
                table: "Localizable",
                bundle: .current
            )
        }

        /// ### Source Localization
        ///
        /// ```
        /// The Nos moderation team will analyze the note for %@ content and may publish a report from our own account, concealing your identity.
        /// ```
        internal static func reportNoteSendToNosConfirmation(_ arg1: String) -> Localizable {
            Localizable(
                key: "reportNoteSendToNosConfirmation",
                arguments: [
                    .object(arg1)
                ],
                table: "Localizable",
                bundle: .current
            )
        }

        /// ### Source Localization
        ///
        /// ```
        /// Repost
        /// ```
        internal static var repost: Localizable {
            Localizable(
                key: "repost",
                arguments: [],
                table: "Localizable",
                bundle: .current
            )
        }

        /// ### Source Localization
        ///
        /// ```
        /// Retry
        /// ```
        internal static var retry: Localizable {
            Localizable(
                key: "retry",
                arguments: [],
                table: "Localizable",
                bundle: .current
            )
        }

        /// ### Source Localization
        ///
        /// ```
        /// Return to the choose name step and choose your registered name.
        /// ```
        internal static var returnToChooseName: Localizable {
            Localizable(
                key: "returnToChooseName",
                arguments: [],
                table: "Localizable",
                bundle: .current
            )
        }

        /// ### Source Localization
        ///
        /// ```
        /// This will delete all events and load those in sample_data.json
        /// ```
        internal static var sampleDataInstructions: Localizable {
            Localizable(
                key: "sampleDataInstructions",
                arguments: [],
                table: "Localizable",
                bundle: .current
            )
        }

        /// ### Source Localization
        ///
        /// ```
        /// Save
        /// ```
        internal static var save: Localizable {
            Localizable(
                key: "save",
                arguments: [],
                table: "Localizable",
                bundle: .current
            )
        }

        /// ### Source Localization
        ///
        /// ```
        /// Could not save relay.
        /// ```
        internal static var saveRelayError: Localizable {
            Localizable(
                key: "saveRelayError",
                arguments: [],
                table: "Localizable",
                bundle: .current
            )
        }

        /// ### Source Localization
        ///
        /// ```
        /// Scan the QR code or download the Global ID app to send USBC to your friends!
        /// ```
        internal static var scanTheWalletConnectQR: Localizable {
            Localizable(
                key: "scanTheWalletConnectQR",
                arguments: [],
                table: "Localizable",
                bundle: .current
            )
        }

        /// ### Source Localization
        ///
        /// ```
        /// Search people on Nostr or the Fediverse
        /// ```
        internal static var searchBar: Localizable {
            Localizable(
                key: "searchBar",
                arguments: [],
                table: "Localizable",
                bundle: .current
            )
        }

        /// ### Source Localization
        ///
        /// ```
        /// See profile
        /// ```
        internal static var seeProfile: Localizable {
            Localizable(
                key: "seeProfile",
                arguments: [],
                table: "Localizable",
                bundle: .current
            )
        }

        /// ### Source Localization
        ///
        /// ```
        /// Select
        /// ```
        internal static var select: Localizable {
            Localizable(
                key: "select",
                arguments: [],
                table: "Localizable",
                bundle: .current
            )
        }

        /// ### Source Localization
        ///
        /// ```
        /// Send
        /// ```
        internal static var send: Localizable {
            Localizable(
                key: "send",
                arguments: [],
                table: "Localizable",
                bundle: .current
            )
        }

        /// ### Source Localization
        ///
        /// ```
        /// Send SMS code
        /// ```
        internal static var sendCode: Localizable {
            Localizable(
                key: "sendCode",
                arguments: [],
                table: "Localizable",
                bundle: .current
            )
        }

        /// ### Source Localization
        ///
        /// ```
        /// Send to
        /// ```
        internal static var sendTo: Localizable {
            Localizable(
                key: "sendTo",
                arguments: [],
                table: "Localizable",
                bundle: .current
            )
        }

        /// ### Source Localization
        ///
        /// ```
        /// Send USBC
        /// ```
        internal static var sendUSBC: Localizable {
            Localizable(
                key: "sendUSBC",
                arguments: [],
                table: "Localizable",
                bundle: .current
            )
        }

        /// ### Source Localization
        ///
        /// ```
        /// Settings
        /// ```
        internal static var settings: Localizable {
            Localizable(
                key: "settings",
                arguments: [],
                table: "Localizable",
                bundle: .current
            )
        }

        /// ### Source Localization
        ///
        /// ```
        /// Set up my @username
        /// ```
        internal static var setUpMyUsername: Localizable {
            Localizable(
                key: "setUpMyUsername",
                arguments: [],
                table: "Localizable",
                bundle: .current
            )
        }

        /// ### Source Localization
        ///
        /// ```
        /// Reserve Your Name
        /// ```
        internal static var setUpUNS: Localizable {
            Localizable(
                key: "setUpUNS",
                arguments: [],
                table: "Localizable",
                bundle: .current
            )
        }

        /// ### Source Localization
        ///
        /// ```
        /// Share
        /// ```
        internal static var share: Localizable {
            Localizable(
                key: "share",
                arguments: [],
                table: "Localizable",
                bundle: .current
            )
        }

        /// ### Source Localization
        ///
        /// ```
        /// Share logs
        /// ```
        internal static var shareLogs: Localizable {
            Localizable(
                key: "shareLogs",
                arguments: [],
                table: "Localizable",
                bundle: .current
            )
        }

        /// ### Source Localization
        ///
        /// ```
        /// Share Nos
        /// ```
        internal static var shareNos: Localizable {
            Localizable(
                key: "shareNos",
                arguments: [],
                table: "Localizable",
                bundle: .current
            )
        }

        /// ### Source Localization
        ///
        /// ```
        /// Show
        /// ```
        internal static var show: Localizable {
            Localizable(
                key: "show",
                arguments: [],
                table: "Localizable",
                bundle: .current
            )
        }

        /// ### Source Localization
        ///
        /// ```
        /// Show Out of Network warnings
        /// ```
        internal static var showOutOfNetworkWarnings: Localizable {
            Localizable(
                key: "showOutOfNetworkWarnings",
                arguments: [],
                table: "Localizable",
                bundle: .current
            )
        }

        /// ### Source Localization
        ///
        /// ```
        /// Hide notes from users outside my friends of friends circle behind a content warning.
        /// ```
        internal static var showOutOfNetworkWarningsDescription: Localizable {
            Localizable(
                key: "showOutOfNetworkWarningsDescription",
                arguments: [],
                table: "Localizable",
                bundle: .current
            )
        }

        /// ### Source Localization
        ///
        /// ```
        /// Software
        /// ```
        internal static var software: Localizable {
            Localizable(
                key: "software",
                arguments: [],
                table: "Localizable",
                bundle: .current
            )
        }

        /// ### Source Localization
        ///
        /// ```
        /// someone
        /// ```
        internal static var someone: Localizable {
            Localizable(
                key: "someone",
                arguments: [],
                table: "Localizable",
                bundle: .current
            )
        }

        /// ### Source Localization
        ///
        /// ```
        /// Something went wrong.
        /// ```
        internal static var somethingWentWrong: Localizable {
            Localizable(
                key: "somethingWentWrong",
                arguments: [],
                table: "Localizable",
                bundle: .current
            )
        }

        /// ### Source Localization
        ///
        /// ```
        /// Start
        /// ```
        internal static var start: Localizable {
            Localizable(
                key: "start",
                arguments: [],
                table: "Localizable",
                bundle: .current
            )
        }

        /// ### Source Localization
        ///
        /// ```
        /// Start over
        /// ```
        internal static var startOver: Localizable {
            Localizable(
                key: "startOver",
                arguments: [],
                table: "Localizable",
                bundle: .current
            )
        }

        /// ### Source Localization
        ///
        /// ```
        /// Stories
        /// ```
        internal static var stories: Localizable {
            Localizable(
                key: "stories",
                arguments: [],
                table: "Localizable",
                bundle: .current
            )
        }

        /// ### Source Localization
        ///
        /// ```
        /// Submit
        /// ```
        internal static var submit: Localizable {
            Localizable(
                key: "submit",
                arguments: [],
                table: "Localizable",
                bundle: .current
            )
        }

        /// ### Source Localization
        ///
        /// ```
        /// Success!
        /// ```
        internal static var success: Localizable {
            Localizable(
                key: "success",
                arguments: [],
                table: "Localizable",
                bundle: .current
            )
        }

        /// ### Source Localization
        ///
        /// ```
        /// Supported NIPs
        /// ```
        internal static var supportedNIPs: Localizable {
            Localizable(
                key: "supportedNIPs",
                arguments: [],
                table: "Localizable",
                bundle: .current
            )
        }

        /// ### Source Localization
        ///
        /// ```
        /// Terms of Service
        /// ```
        internal static var termsOfServiceTitle: Localizable {
            Localizable(
                key: "termsOfServiceTitle",
                arguments: [],
                table: "Localizable",
                bundle: .current
            )
        }

        /// ### Source Localization
        ///
        /// ```
        /// That name is taken.
        /// ```
        internal static var thatNameIsTaken: Localizable {
            Localizable(
                key: "thatNameIsTaken",
                arguments: [],
                table: "Localizable",
                bundle: .current
            )
        }

        /// ### Source Localization
        ///
        /// ```
        /// Thread
        /// ```
        internal static var thread: Localizable {
            Localizable(
                key: "thread",
                arguments: [],
                table: "Localizable",
                bundle: .current
            )
        }

        /// ### Source Localization
        ///
        /// ```
        /// Please try again or contact support.
        /// ```
        internal static var tryAgainOrContactSupport: Localizable {
            Localizable(
                key: "tryAgainOrContactSupport",
                arguments: [],
                table: "Localizable",
                bundle: .current
            )
        }

        /// ### Source Localization
        ///
        /// ```
        /// Please try with a different name.
        /// ```
        internal static var tryAnotherName: Localizable {
            Localizable(
                key: "tryAnotherName",
                arguments: [],
                table: "Localizable",
                bundle: .current
            )
        }

        /// ### Source Localization
        ///
        /// ```
        /// Try it
        /// ```
        internal static var tryIt: Localizable {
            Localizable(
                key: "tryIt",
                arguments: [],
                table: "Localizable",
                bundle: .current
            )
        }

        /// ### Source Localization
        ///
        /// ```
        /// Unfollow
        /// ```
        internal static var unfollow: Localizable {
            Localizable(
                key: "unfollow",
                arguments: [],
                table: "Localizable",
                bundle: .current
            )
        }

        /// ### Source Localization
        ///
        /// ```
        /// Universal name
        /// ```
        internal static var universalName: Localizable {
            Localizable(
                key: "universalName",
                arguments: [],
                table: "Localizable",
                bundle: .current
            )
        }

        /// ### Source Localization
        ///
        /// ```
        /// unknown
        /// ```
        internal static var unknownAuthor: Localizable {
            Localizable(
                key: "unknownAuthor",
                arguments: [],
                table: "Localizable",
                bundle: .current
            )
        }

        /// ### Source Localization
        ///
        /// ```
        /// Un-Mute
        /// ```
        internal static var unmuteUser: Localizable {
            Localizable(
                key: "unmuteUser",
                arguments: [],
                table: "Localizable",
                bundle: .current
            )
        }

        /// ### Source Localization
        ///
        /// ```
        /// The Universal Namespace gives you one name you can use everywhere. Register your Universal Name and connect it to your Nostr profile. Learn more.
        /// ```
        internal static var unsDescription: Localizable {
            Localizable(
                key: "unsDescription",
                arguments: [],
                table: "Localizable",
                bundle: .current
            )
        }

        /// ### Source Localization
        ///
        /// ```
        /// Learn more about UNS.
        /// ```
        internal static var unsLearnMore: Localizable {
            Localizable(
                key: "unsLearnMore",
                arguments: [],
                table: "Localizable",
                bundle: .current
            )
        }

        /// ### Source Localization
        ///
        /// ```
        /// Register your Universal Name
        /// ```
        internal static var unsRegister: Localizable {
            Localizable(
                key: "unsRegister",
                arguments: [],
                table: "Localizable",
                bundle: .current
            )
        }

        /// ### Source Localization
        ///
        /// ```
        /// Universal Name Space gives you a name you can use everywhere.
        ///
        /// Verify your identity and link your social accounts, government ID, wallets and more.
        /// ```
        internal static var unsRegisterDescription: Localizable {
            Localizable(
                key: "unsRegisterDescription",
                arguments: [],
                table: "Localizable",
                bundle: .current
            )
        }

        /// ### Source Localization
        ///
        /// ```
        /// You have successfully linked your Universal Name to your Nostr profile.
        /// ```
        internal static var unsSuccessDescription: Localizable {
            Localizable(
                key: "unsSuccessDescription",
                arguments: [],
                table: "Localizable",
                bundle: .current
            )
        }

        /// ### Source Localization
        ///
        /// ```
        /// Universal Name Space brings identity verification you can trust.
        /// ```
        internal static var unsTagline: Localizable {
            Localizable(
                key: "unsTagline",
                arguments: [],
                table: "Localizable",
                bundle: .current
            )
        }

        /// ### Source Localization
        ///
        /// ```
        /// Go to nostr.build to upload your photo, copy the URL provided and paste it here.
        /// ```
        internal static var uploadProfilePicInstructions: Localizable {
            Localizable(
                key: "uploadProfilePicInstructions",
                arguments: [],
                table: "Localizable",
                bundle: .current
            )
        }

        /// ### Source Localization
        ///
        /// ```
        /// URL
        /// ```
        internal static var url: Localizable {
            Localizable(
                key: "url",
                arguments: [],
                table: "Localizable",
                bundle: .current
            )
        }

        /// ### Source Localization
        ///
        /// ```
        /// Use reports from my follows
        /// ```
        internal static var useReportsFromFollows: Localizable {
            Localizable(
                key: "useReportsFromFollows",
                arguments: [],
                table: "Localizable",
                bundle: .current
            )
        }

        /// ### Source Localization
        ///
        /// ```
        /// When someone you follow flags a note or user, we'll add a content warning to their notes.
        /// ```
        internal static var useReportsFromFollowsDescription: Localizable {
            Localizable(
                key: "useReportsFromFollowsDescription",
                arguments: [],
                table: "Localizable",
                bundle: .current
            )
        }

        /// ### Source Localization
        ///
        /// ```
        /// Username
        /// ```
        internal static var username: Localizable {
            Localizable(
                key: "username",
                arguments: [],
                table: "Localizable",
                bundle: .current
            )
        }

        /// ### Source Localization
        ///
        /// ```
        /// Looks like someone's already claimed that @username.
        /// ```
        internal static var usernameAlreadyClaimed: Localizable {
            Localizable(
                key: "usernameAlreadyClaimed",
                arguments: [],
                table: "Localizable",
                bundle: .current
            )
        }

        /// ### Source Localization
        ///
        /// ```
        /// Well done, you've successfully claimed your **@username**!
        ///
        /// You can share this name with other people in the Nostr and Fediverse communities to make it easy to find you.
        /// ```
        internal static var usernameClaimedNotice: Localizable {
            Localizable(
                key: "usernameClaimedNotice",
                arguments: [],
                table: "Localizable",
                bundle: .current
            )
        }

        /// ### Source Localization
        ///
        /// ```
        /// Changing or removing your handle may cause web links to disconnect from your identity.
        /// ```
        internal static var usernameWarningMessage: Localizable {
            Localizable(
                key: "usernameWarningMessage",
                arguments: [],
                table: "Localizable",
                bundle: .current
            )
        }

        /// ### Source Localization
        ///
        /// ```
        /// This user has been flagged by **%1$@** for %2$@.
        /// ```
        internal static func userReportedByOne(_ arg1: String, _ arg2: String) -> Localizable {
            Localizable(
                key: "userReportedByOne",
                arguments: [
                    .object(arg1),
                    .object(arg2)
                ],
                table: "Localizable",
                bundle: .current
            )
        }

        /// ### Source Localization
        ///
        /// ```
        /// This user has been flagged by **%1$@** and **%2$lld others** for %3$@.
        /// ```
        internal static func userReportedByOneAndMore(_ arg1: String, _ arg2: Int, _ arg3: String) -> Localizable {
            Localizable(
                key: "userReportedByOneAndMore",
                arguments: [
                    .object(arg1),
                    .int(arg2),
                    .object(arg3)
                ],
                table: "Localizable",
                bundle: .current
            )
        }

        /// ### Source Localization
        ///
        /// ```
        /// Verification
        /// ```
        internal static var verification: Localizable {
            Localizable(
                key: "verification",
                arguments: [],
                table: "Localizable",
                bundle: .current
            )
        }

        /// ### Source Localization
        ///
        /// ```
        /// Enter the 6-digit code we sent to %@
        /// ```
        internal static func verificationDescription(_ arg1: String) -> Localizable {
            Localizable(
                key: "verificationDescription",
                arguments: [
                    .object(arg1)
                ],
                table: "Localizable",
                bundle: .current
            )
        }

        /// ### Source Localization
        ///
        /// ```
        /// Verify your identity
        /// ```
        internal static var verifyYourIdentity: Localizable {
            Localizable(
                key: "verifyYourIdentity",
                arguments: [],
                table: "Localizable",
                bundle: .current
            )
        }

        /// ### Source Localization
        ///
        /// ```
        /// Version
        /// ```
        internal static var version: Localizable {
            Localizable(
                key: "version",
                arguments: [],
                table: "Localizable",
                bundle: .current
            )
        }

        /// ### Source Localization
        ///
        /// ```
        /// View Source
        /// ```
        internal static var viewSource: Localizable {
            Localizable(
                key: "viewSource",
                arguments: [],
                table: "Localizable",
                bundle: .current
            )
        }

        /// ### Source Localization
        ///
        /// ```
        /// View this post anyway
        /// ```
        internal static var viewThisPostAnyway: Localizable {
            Localizable(
                key: "viewThisPostAnyway",
                arguments: [],
                table: "Localizable",
                bundle: .current
            )
        }

        /// ### Source Localization
        ///
        /// ```
        /// Website
        /// ```
        internal static var website: Localizable {
            Localizable(
                key: "website",
                arguments: [],
                table: "Localizable",
                bundle: .current
            )
        }

        /// ### Source Localization
        ///
        /// ```
        /// Yes
        /// ```
        internal static var yes: Localizable {
            Localizable(
                key: "yes",
                arguments: [],
                table: "Localizable",
                bundle: .current
            )
        }

        /// ### Source Localization
        ///
        /// ```
        /// You need to enter a private key in Settings before you can publish posts.
        /// ```
        internal static var youNeedToEnterAPrivateKeyBeforePosting: Localizable {
            Localizable(
                key: "youNeedToEnterAPrivateKeyBeforePosting",
                arguments: [],
                table: "Localizable",
                bundle: .current
            )
        }

        /// ### Source Localization
        ///
        /// ```
        /// is your Universal Name.
        ///
        /// We've created a link between your Nostr profile and your Universal Name and filled your Universal Name into the username field on your profile.
        /// ```
        internal static var yourNewUNMessage: Localizable {
            Localizable(
                key: "yourNewUNMessage",
                arguments: [],
                table: "Localizable",
                bundle: .current
            )
        }

        /// ### Source Localization
        ///
        /// ```
        /// Your Profile
        /// ```
        internal static var yourProfile: Localizable {
            Localizable(
                key: "yourProfile",
                arguments: [],
                table: "Localizable",
                bundle: .current
            )
        }

        @available(macOS 12, iOS 15, tvOS 15, watchOS 8, *)
        fileprivate var defaultValue: String.LocalizationValue {
            var stringInterpolation = String.LocalizationValue.StringInterpolation(literalCapacity: 0, interpolationCount: arguments.count)
            for argument in arguments {
                switch argument {
                case .int(let value):
                    stringInterpolation.appendInterpolation(value)
                case .uint(let value):
                    stringInterpolation.appendInterpolation(value)
                case .float(let value):
                    stringInterpolation.appendInterpolation(value)
                case .double(let value):
                    stringInterpolation.appendInterpolation(value)
                case .object(let value):
                    stringInterpolation.appendInterpolation(value)
                }
            }
            let makeDefaultValue = String.LocalizationValue.init(stringInterpolation:)
            return makeDefaultValue(stringInterpolation)
        }
    }

    internal init(localizable: Localizable, locale: Locale? = nil) {
        let bundle: Bundle = .from(description: localizable.bundle) ?? .main
        let key = String(describing: localizable.key)
        self.init(
            format: bundle.localizedString(forKey: key, value: nil, table: localizable.table),
            locale: locale,
            arguments: localizable.arguments.map(\.value)
        )
    }
}

extension Bundle {
    static func from(description: String.Localizable.BundleDescription) -> Bundle? {
        switch description {
        case .main:
            Bundle.main
        case .atURL(let url):
            Bundle(url: url)
        case .forClass(let anyClass):
            Bundle(for: anyClass)
        }
    }
}

@available(macOS 13, iOS 16, tvOS 16, watchOS 9, *)
private extension LocalizedStringResource.BundleDescription {
    static func from(description: String.Localizable.BundleDescription) -> Self {
        switch description {
        case .main:
            .main
        case .atURL(let url):
            .atURL(url)
        case .forClass(let anyClass):
            .forClass(anyClass)
        }
    }
}

@available(macOS 13, iOS 16, tvOS 16, watchOS 9, *)
extension LocalizedStringResource {
    /// Constant values for the Localizable Strings Catalog
    ///
    /// ```swift
    /// // Accessing the localized value directly
    /// let value = String(localized: .localizable.about)
    /// value // "About"
    ///
    /// // Working with SwiftUI
    /// Text(.localizable.about)
    /// ```
    ///
    /// - Note: Using ``LocalizedStringResource.Localizable`` requires iOS 16/macOS 13 or later. See ``String.Localizable`` for a backwards compatible API.
    internal struct Localizable: Sendable {
        /// ### Source Localization
        ///
        /// ```
        /// About
        /// ```
        @available(*, deprecated, message: "Use `String.Localizable.about` instead. This property will be removed in the future.")
        internal var about: LocalizedStringResource {
            LocalizedStringResource(localizable: .about)
        }

        /// ### Source Localization
        ///
        /// ```
        /// Nos is a new social media app built on the Nostr protocol from the team that brought you Planetary. Designed for humans, not algorithms. Learn more at Nos.social.
        /// ```
        @available(*, deprecated, message: "Use `String.Localizable.aboutNos` instead. This property will be removed in the future.")
        internal var aboutNos: LocalizedStringResource {
            LocalizedStringResource(localizable: .aboutNos)
        }

        /// ### Source Localization
        ///
        /// ```
        /// Learn more at Nos.social.
        /// ```
        @available(*, deprecated, message: "Use `String.Localizable.aboutNosHighlight` instead. This property will be removed in the future.")
        internal var aboutNosHighlight: LocalizedStringResource {
            LocalizedStringResource(localizable: .aboutNosHighlight)
        }

        /// ### Source Localization
        ///
        /// ```
        /// Nostr is an open social media ecosystem that puts you in control of your online relationships. Nos is just one of many apps that speak the Nostr language, and you can pick your servers too. Learn more about why Nostr is great.
        /// ```
        @available(*, deprecated, message: "Use `String.Localizable.aboutNostr` instead. This property will be removed in the future.")
        internal var aboutNostr: LocalizedStringResource {
            LocalizedStringResource(localizable: .aboutNostr)
        }

        /// ### Source Localization
        ///
        /// ```
        /// Learn more about why Nostr is great.
        /// ```
        @available(*, deprecated, message: "Use `String.Localizable.aboutNostrHighlight` instead. This property will be removed in the future.")
        internal var aboutNostrHighlight: LocalizedStringResource {
            LocalizedStringResource(localizable: .aboutNostrHighlight)
        }

        /// ### Source Localization
        ///
        /// ```
        /// Accept
        /// ```
        @available(*, deprecated, message: "Use `String.Localizable.accept` instead. This property will be removed in the future.")
        internal var accept: LocalizedStringResource {
            LocalizedStringResource(localizable: .accept)
        }

        /// ### Source Localization
        ///
        /// ```
        /// Activity
        /// ```
        @available(*, deprecated, message: "Use `String.Localizable.activity` instead. This property will be removed in the future.")
        internal var activity: LocalizedStringResource {
            LocalizedStringResource(localizable: .activity)
        }

        /// ### Source Localization
        ///
        /// ```
        /// Add Item
        /// ```
        @available(*, deprecated, message: "Use `String.Localizable.addItem` instead. This property will be removed in the future.")
        internal var addItem: LocalizedStringResource {
            LocalizedStringResource(localizable: .addItem)
        }

        /// ### Source Localization
        ///
        /// ```
        /// Add Relay
        /// ```
        @available(*, deprecated, message: "Use `String.Localizable.addRelay` instead. This property will be removed in the future.")
        internal var addRelay: LocalizedStringResource {
            LocalizedStringResource(localizable: .addRelay)
        }

        /// ### Source Localization
        ///
        /// ```
        /// Address
        /// ```
        @available(*, deprecated, message: "Use `String.Localizable.address` instead. This property will be removed in the future.")
        internal var address: LocalizedStringResource {
            LocalizedStringResource(localizable: .address)
        }

        /// ### Source Localization
        ///
        /// ```
        /// For legal reasons, we need to make sure you're over this age to use Nos
        /// ```
        @available(*, deprecated, message: "Use `String.Localizable.ageVerificationSubtitle` instead. This property will be removed in the future.")
        internal var ageVerificationSubtitle: LocalizedStringResource {
            LocalizedStringResource(localizable: .ageVerificationSubtitle)
        }

        /// ### Source Localization
        ///
        /// ```
        /// Are you over 16 years old?
        /// ```
        @available(*, deprecated, message: "Use `String.Localizable.ageVerificationTitle` instead. This property will be removed in the future.")
        internal var ageVerificationTitle: LocalizedStringResource {
            LocalizedStringResource(localizable: .ageVerificationTitle)
        }

        /// ### Source Localization
        ///
        /// ```
        /// All My Relays
        /// ```
        @available(*, deprecated, message: "Use `String.Localizable.allMyRelays` instead. This property will be removed in the future.")
        internal var allMyRelays: LocalizedStringResource {
            LocalizedStringResource(localizable: .allMyRelays)
        }

        /// ### Source Localization
        ///
        /// ```
        /// All published events
        /// ```
        @available(*, deprecated, message: "Use `String.Localizable.allPublishedEvents` instead. This property will be removed in the future.")
        internal var allPublishedEvents: LocalizedStringResource {
            LocalizedStringResource(localizable: .allPublishedEvents)
        }

        /// ### Source Localization
        ///
        /// ```
        /// No, thanks. I already have a NIP-05
        /// ```
        @available(*, deprecated, message: "Use `String.Localizable.alreadyHaveANIP05` instead. This property will be removed in the future.")
        internal var alreadyHaveANIP05: LocalizedStringResource {
            LocalizedStringResource(localizable: .alreadyHaveANIP05)
        }

        /// ### Source Localization
        ///
        /// ```
        /// Amount
        /// ```
        @available(*, deprecated, message: "Use `String.Localizable.amount` instead. This property will be removed in the future.")
        internal var amount: LocalizedStringResource {
            LocalizedStringResource(localizable: .amount)
        }

        /// ### Source Localization
        ///
        /// ```
        /// An error occured.
        /// ```
        @available(*, deprecated, message: "Use `String.Localizable.anErrorOccurred` instead. This property will be removed in the future.")
        internal var anErrorOccurred: LocalizedStringResource {
            LocalizedStringResource(localizable: .anErrorOccurred)
        }

        /// ### Source Localization
        ///
        /// ```
        /// None of your relays support expiring messages. Please add one and retry.
        /// ```
        @available(*, deprecated, message: "Use `String.Localizable.anyRelaysSupportingNIP40` instead. This property will be removed in the future.")
        internal var anyRelaysSupportingNIP40: LocalizedStringResource {
            LocalizedStringResource(localizable: .anyRelaysSupportingNIP40)
        }

        /// ### Source Localization
        ///
        /// ```
        /// App Version:
        /// ```
        @available(*, deprecated, message: "Use `String.Localizable.appVersion` instead. This property will be removed in the future.")
        internal var appVersion: LocalizedStringResource {
            LocalizedStringResource(localizable: .appVersion)
        }

        /// ### Source Localization
        ///
        /// ```
        /// Attach Media
        /// ```
        @available(*, deprecated, message: "Use `String.Localizable.attachMedia` instead. This property will be removed in the future.")
        internal var attachMedia: LocalizedStringResource {
            LocalizedStringResource(localizable: .attachMedia)
        }

        /// ### Source Localization
        ///
        /// ```
        /// Logging out will delete your private key (nsec) from the app. Make sure you have your private key backed up before you do this or you will lose access to your account!
        /// ```
        @available(*, deprecated, message: "Use `String.Localizable.backUpYourKeyWarning` instead. This property will be removed in the future.")
        internal var backUpYourKeyWarning: LocalizedStringResource {
            LocalizedStringResource(localizable: .backUpYourKeyWarning)
        }

        /// ### Source Localization
        ///
        /// ```
        /// Basic Information
        /// ```
        @available(*, deprecated, message: "Use `String.Localizable.basicInfo` instead. This property will be removed in the future.")
        internal var basicInfo: LocalizedStringResource {
            LocalizedStringResource(localizable: .basicInfo)
        }

        /// ### Source Localization
        ///
        /// ```
        /// Bio
        /// ```
        @available(*, deprecated, message: "Use `String.Localizable.bio` instead. This property will be removed in the future.")
        internal var bio: LocalizedStringResource {
            LocalizedStringResource(localizable: .bio)
        }

        /// ### Source Localization
        ///
        /// ```
        /// This user hasn't written a bio yet 👻
        /// ```
        @available(*, deprecated, message: "Use `String.Localizable.bioMissing` instead. This property will be removed in the future.")
        internal var bioMissing: LocalizedStringResource {
            LocalizedStringResource(localizable: .bioMissing)
        }

        /// ### Source Localization
        ///
        /// ```
        /// Cancel
        /// ```
        @available(*, deprecated, message: "Use `String.Localizable.cancel` instead. This property will be removed in the future.")
        internal var cancel: LocalizedStringResource {
            LocalizedStringResource(localizable: .cancel)
        }

        /// ### Source Localization
        ///
        /// ```
        /// Choose from your existing names, or register a new one:
        /// ```
        @available(*, deprecated, message: "Use `String.Localizable.chooseNameOrRegister` instead. This property will be removed in the future.")
        internal var chooseNameOrRegister: LocalizedStringResource {
            LocalizedStringResource(localizable: .chooseNameOrRegister)
        }

        /// ### Source Localization
        ///
        /// ```
        /// Choose your handle
        /// ```
        @available(*, deprecated, message: "Use `String.Localizable.chooseYourHandle` instead. This property will be removed in the future.")
        internal var chooseYourHandle: LocalizedStringResource {
            LocalizedStringResource(localizable: .chooseYourHandle)
        }

        /// ### Source Localization
        ///
        /// ```
        /// This is how others will see you on Nos, and also a public URL to your profile.
        ///
        /// You can change this later.
        /// ```
        @available(*, deprecated, message: "Use `String.Localizable.chooseYourHandleDescription` instead. This property will be removed in the future.")
        internal var chooseYourHandleDescription: LocalizedStringResource {
            LocalizedStringResource(localizable: .chooseYourHandleDescription)
        }

        /// ### Source Localization
        ///
        /// ```
        /// Choose your name
        /// ```
        @available(*, deprecated, message: "Use `String.Localizable.chooseYourName` instead. This property will be removed in the future.")
        internal var chooseYourName: LocalizedStringResource {
            LocalizedStringResource(localizable: .chooseYourName)
        }

        /// ### Source Localization
        ///
        /// ```
        /// This will be your Universal Name. You can register more later. Valid names
        /// ```
        @available(*, deprecated, message: "Use `String.Localizable.chooseYourNameDescription` instead. This property will be removed in the future.")
        internal var chooseYourNameDescription: LocalizedStringResource {
            LocalizedStringResource(localizable: .chooseYourNameDescription)
        }

        /// ### Source Localization
        ///
        /// ```
        /// Welcome to Nos, where your voice matters. Begin your journey by securing your unique **@username**.nos.social
        ///
        /// Stand out in the decentralized world!
        /// ```
        @available(*, deprecated, message: "Use `String.Localizable.claimUniqueUsernameDescription` instead. This property will be removed in the future.")
        internal var claimUniqueUsernameDescription: LocalizedStringResource {
            LocalizedStringResource(localizable: .claimUniqueUsernameDescription)
        }

        /// ### Source Localization
        ///
        /// ```
        /// Claim your unique identity on Nostr
        /// ```
        @available(*, deprecated, message: "Use `String.Localizable.claimUniqueUsernameTitle` instead. This property will be removed in the future.")
        internal var claimUniqueUsernameTitle: LocalizedStringResource {
            LocalizedStringResource(localizable: .claimUniqueUsernameTitle)
        }

        /// ### Source Localization
        ///
        /// ```
        /// Get it now
        /// ```
        @available(*, deprecated, message: "Use `String.Localizable.claimYourUsernameButton` instead. This property will be removed in the future.")
        internal var claimYourUsernameButton: LocalizedStringResource {
            LocalizedStringResource(localizable: .claimYourUsernameButton)
        }

        /// ### Source Localization
        ///
        /// ```
        /// Claim your @username and stand out on the decentralized world!
        /// ```
        @available(*, deprecated, message: "Use `String.Localizable.claimYourUsernameText` instead. This property will be removed in the future.")
        internal var claimYourUsernameText: LocalizedStringResource {
            LocalizedStringResource(localizable: .claimYourUsernameText)
        }

        /// ### Source Localization
        ///
        /// ```
        /// Clear
        /// ```
        @available(*, deprecated, message: "Use `String.Localizable.clear` instead. This property will be removed in the future.")
        internal var clear: LocalizedStringResource {
            LocalizedStringResource(localizable: .clear)
        }

        /// ### Source Localization
        ///
        /// ```
        /// Complete My Profile
        /// ```
        @available(*, deprecated, message: "Use `String.Localizable.completeProfileButton` instead. This property will be removed in the future.")
        internal var completeProfileButton: LocalizedStringResource {
            LocalizedStringResource(localizable: .completeProfileButton)
        }

        /// ### Source Localization
        ///
        /// ```
        /// Finish setting up your profile to help people find you.
        /// ```
        @available(*, deprecated, message: "Use `String.Localizable.completeProfileMessage` instead. This property will be removed in the future.")
        internal var completeProfileMessage: LocalizedStringResource {
            LocalizedStringResource(localizable: .completeProfileMessage)
        }

        /// ### Source Localization
        ///
        /// ```
        /// Confirm
        /// ```
        @available(*, deprecated, message: "Use `String.Localizable.confirm` instead. This property will be removed in the future.")
        internal var confirm: LocalizedStringResource {
            LocalizedStringResource(localizable: .confirm)
        }

        /// ### Source Localization
        ///
        /// ```
        /// Confirm Delete
        /// ```
        @available(*, deprecated, message: "Use `String.Localizable.confirmDelete` instead. This property will be removed in the future.")
        internal var confirmDelete: LocalizedStringResource {
            LocalizedStringResource(localizable: .confirmDelete)
        }

        /// ### Source Localization
        ///
        /// ```
        /// Confirm Flag
        /// ```
        @available(*, deprecated, message: "Use `String.Localizable.confirmFlag` instead. This property will be removed in the future.")
        internal var confirmFlag: LocalizedStringResource {
            LocalizedStringResource(localizable: .confirmFlag)
        }

        /// ### Source Localization
        ///
        /// ```
        /// Connect GlobaliD app
        /// ```
        @available(*, deprecated, message: "Use `String.Localizable.connectGlobalID` instead. This property will be removed in the future.")
        internal var connectGlobalID: LocalizedStringResource {
            LocalizedStringResource(localizable: .connectGlobalID)
        }

        /// ### Source Localization
        ///
        /// ```
        /// Connect your GlobaliD wallet to send USBC
        /// ```
        @available(*, deprecated, message: "Use `String.Localizable.connectGlobalIDTitle` instead. This property will be removed in the future.")
        internal var connectGlobalIDTitle: LocalizedStringResource {
            LocalizedStringResource(localizable: .connectGlobalIDTitle)
        }

        /// ### Source Localization
        ///
        /// ```
        /// Connect Wallet
        /// ```
        @available(*, deprecated, message: "Use `String.Localizable.connectWallet` instead. This property will be removed in the future.")
        internal var connectWallet: LocalizedStringResource {
            LocalizedStringResource(localizable: .connectWallet)
        }

        /// ### Source Localization
        ///
        /// ```
        /// Contact
        /// ```
        @available(*, deprecated, message: "Use `String.Localizable.contact` instead. This property will be removed in the future.")
        internal var contact: LocalizedStringResource {
            LocalizedStringResource(localizable: .contact)
        }

        /// ### Source Localization
        ///
        /// ```
        /// Contact Us
        /// ```
        @available(*, deprecated, message: "Use `String.Localizable.contactUs` instead. This property will be removed in the future.")
        internal var contactUs: LocalizedStringResource {
            LocalizedStringResource(localizable: .contactUs)
        }

        /// ### Source Localization
        ///
        /// ```
        /// Nos is committed to fostering safe and respectful community. To achieve this we display content warnings when someone you follow flags a note. You can change this in the settings menu.
        /// ```
        @available(*, deprecated, message: "Use `String.Localizable.contentWarningExplanation` instead. This property will be removed in the future.")
        internal var contentWarningExplanation: LocalizedStringResource {
            LocalizedStringResource(localizable: .contentWarningExplanation)
        }

        /// ### Source Localization
        ///
        /// ```
        /// Copied!
        /// ```
        @available(*, deprecated, message: "Use `String.Localizable.copied` instead. This property will be removed in the future.")
        internal var copied: LocalizedStringResource {
            LocalizedStringResource(localizable: .copied)
        }

        /// ### Source Localization
        ///
        /// ```
        /// Copy
        /// ```
        @available(*, deprecated, message: "Use `String.Localizable.copy` instead. This property will be removed in the future.")
        internal var copy: LocalizedStringResource {
            LocalizedStringResource(localizable: .copy)
        }

        /// ### Source Localization
        ///
        /// ```
        /// Copy Link
        /// ```
        @available(*, deprecated, message: "Use `String.Localizable.copyLink` instead. This property will be removed in the future.")
        internal var copyLink: LocalizedStringResource {
            LocalizedStringResource(localizable: .copyLink)
        }

        /// ### Source Localization
        ///
        /// ```
        /// Copy Note Identifier
        /// ```
        @available(*, deprecated, message: "Use `String.Localizable.copyNoteIdentifier` instead. This property will be removed in the future.")
        internal var copyNoteIdentifier: LocalizedStringResource {
            LocalizedStringResource(localizable: .copyNoteIdentifier)
        }

        /// ### Source Localization
        ///
        /// ```
        /// Copy Note Text
        /// ```
        @available(*, deprecated, message: "Use `String.Localizable.copyNoteText` instead. This property will be removed in the future.")
        internal var copyNoteText: LocalizedStringResource {
            LocalizedStringResource(localizable: .copyNoteText)
        }

        /// ### Source Localization
        ///
        /// ```
        /// Copy QR link
        /// ```
        @available(*, deprecated, message: "Use `String.Localizable.copyQRLink` instead. This property will be removed in the future.")
        internal var copyQRLink: LocalizedStringResource {
            LocalizedStringResource(localizable: .copyQRLink)
        }

        /// ### Source Localization
        ///
        /// ```
        /// Copy User ID (npub)
        /// ```
        @available(*, deprecated, message: "Use `String.Localizable.copyUserIdentifier` instead. This property will be removed in the future.")
        internal var copyUserIdentifier: LocalizedStringResource {
            LocalizedStringResource(localizable: .copyUserIdentifier)
        }

        /// ### Source Localization
        ///
        /// ```
        /// Could not read your private key. Please verify that it is in nsec or hex format.
        /// ```
        @available(*, deprecated, message: "Use `String.Localizable.couldNotReadPrivateKeyMessage` instead. This property will be removed in the future.")
        internal var couldNotReadPrivateKeyMessage: LocalizedStringResource {
            LocalizedStringResource(localizable: .couldNotReadPrivateKeyMessage)
        }

        /// ### Source Localization
        ///
        /// ```
        /// Create a new name
        /// ```
        @available(*, deprecated, message: "Use `String.Localizable.createNewName` instead. This property will be removed in the future.")
        internal var createNewName: LocalizedStringResource {
            LocalizedStringResource(localizable: .createNewName)
        }

        /// ### Source Localization
        ///
        /// ```
        /// day
        /// ```
        @available(*, deprecated, message: "Use `String.Localizable.dayAbbreviated` instead. This property will be removed in the future.")
        internal var dayAbbreviated: LocalizedStringResource {
            LocalizedStringResource(localizable: .dayAbbreviated)
        }

        /// ### Source Localization
        ///
        /// ```
        /// days
        /// ```
        @available(*, deprecated, message: "Use `String.Localizable.daysAbbreviated` instead. This property will be removed in the future.")
        internal var daysAbbreviated: LocalizedStringResource {
            LocalizedStringResource(localizable: .daysAbbreviated)
        }

        /// ### Source Localization
        ///
        /// ```
        /// Debug
        /// ```
        @available(*, deprecated, message: "Use `String.Localizable.debug` instead. This property will be removed in the future.")
        internal var debug: LocalizedStringResource {
            LocalizedStringResource(localizable: .debug)
        }

        /// ### Source Localization
        ///
        /// ```
        /// Delete
        /// ```
        @available(*, deprecated, message: "Use `String.Localizable.deleteNote` instead. This property will be removed in the future.")
        internal var deleteNote: LocalizedStringResource {
            LocalizedStringResource(localizable: .deleteNote)
        }

        /// ### Source Localization
        ///
        /// ```
        /// This will ask all your relay servers to permanently remove this note. Are you sure?
        /// ```
        @available(*, deprecated, message: "Use `String.Localizable.deleteNoteConfirmation` instead. This property will be removed in the future.")
        internal var deleteNoteConfirmation: LocalizedStringResource {
            LocalizedStringResource(localizable: .deleteNoteConfirmation)
        }

        /// ### Source Localization
        ///
        /// ```
        /// Delete repost
        /// ```
        @available(*, deprecated, message: "Use `String.Localizable.deleteRepost` instead. This property will be removed in the future.")
        internal var deleteRepost: LocalizedStringResource {
            LocalizedStringResource(localizable: .deleteRepost)
        }

        /// ### Source Localization
        ///
        /// ```
        /// Yes, delete my NIP-05
        /// ```
        @available(*, deprecated, message: "Use `String.Localizable.deleteUsername` instead. This property will be removed in the future.")
        internal var deleteUsername: LocalizedStringResource {
            LocalizedStringResource(localizable: .deleteUsername)
        }

        /// ### Source Localization
        ///
        /// ```
        /// Are you sure you want to delete your NIP-05?
        /// ```
        @available(*, deprecated, message: "Use `String.Localizable.deleteUsernameConfirmation` instead. This property will be removed in the future.")
        internal var deleteUsernameConfirmation: LocalizedStringResource {
            LocalizedStringResource(localizable: .deleteUsernameConfirmation)
        }

        /// ### Source Localization
        ///
        /// ```
        /// Changing or removing your handle may cause web links to disconnect from your identity. **Proceed with caution.**
        /// ```
        @available(*, deprecated, message: "Use `String.Localizable.deleteUsernameDescription` instead. This property will be removed in the future.")
        internal var deleteUsernameDescription: LocalizedStringResource {
            LocalizedStringResource(localizable: .deleteUsernameDescription)
        }

        /// ### Source Localization
        ///
        /// ```
        /// Description
        /// ```
        @available(*, deprecated, message: "Use `String.Localizable.description` instead. This property will be removed in the future.")
        internal var description: LocalizedStringResource {
            LocalizedStringResource(localizable: .description)
        }

        /// ### Source Localization
        ///
        /// ```
        /// Discover
        /// ```
        @available(*, deprecated, message: "Use `String.Localizable.discover` instead. This property will be removed in the future.")
        internal var discover: LocalizedStringResource {
            LocalizedStringResource(localizable: .discover)
        }

        /// ### Source Localization
        ///
        /// ```
        /// Dismiss
        /// ```
        @available(*, deprecated, message: "Use `String.Localizable.dismiss` instead. This property will be removed in the future.")
        internal var dismiss: LocalizedStringResource {
            LocalizedStringResource(localizable: .dismiss)
        }

        /// ### Source Localization
        ///
        /// ```
        /// Display name
        /// ```
        @available(*, deprecated, message: "Use `String.Localizable.displayName` instead. This property will be removed in the future.")
        internal var displayName: LocalizedStringResource {
            LocalizedStringResource(localizable: .displayName)
        }

        /// ### Source Localization
        ///
        /// ```
        /// Done
        /// ```
        @available(*, deprecated, message: "Use `String.Localizable.done` instead. This property will be removed in the future.")
        internal var done: LocalizedStringResource {
            LocalizedStringResource(localizable: .done)
        }

        /// ### Source Localization
        ///
        /// ```
        /// Edit
        /// ```
        @available(*, deprecated, message: "Use `String.Localizable.edit` instead. This property will be removed in the future.")
        internal var edit: LocalizedStringResource {
            LocalizedStringResource(localizable: .edit)
        }

        /// ### Source Localization
        ///
        /// ```
        /// Edit Profile
        /// ```
        @available(*, deprecated, message: "Use `String.Localizable.editProfile` instead. This property will be removed in the future.")
        internal var editProfile: LocalizedStringResource {
            LocalizedStringResource(localizable: .editProfile)
        }

        /// Setting for new media feature flag
        ///
        /// ### Source Localization
        ///
        /// ```
        /// Enable new media display
        /// ```
        @available(*, deprecated, message: "Use `String.Localizable.enableNewMediaDisplay` instead. This property will be removed in the future.")
        internal var enableNewMediaDisplay: LocalizedStringResource {
            LocalizedStringResource(localizable: .enableNewMediaDisplay)
        }

        /// ### Source Localization
        ///
        /// ```
        /// Enter Code
        /// ```
        @available(*, deprecated, message: "Use `String.Localizable.enterCode` instead. This property will be removed in the future.")
        internal var enterCode: LocalizedStringResource {
            LocalizedStringResource(localizable: .enterCode)
        }

        /// ### Source Localization
        ///
        /// ```
        /// Error
        /// ```
        @available(*, deprecated, message: "Use `String.Localizable.error` instead. This property will be removed in the future.")
        internal var error: LocalizedStringResource {
            LocalizedStringResource(localizable: .error)
        }

        /// ### Source Localization
        ///
        /// ```
        /// Raw Event
        /// ```
        @available(*, deprecated, message: "Use `String.Localizable.eventSource` instead. This property will be removed in the future.")
        internal var eventSource: LocalizedStringResource {
            LocalizedStringResource(localizable: .eventSource)
        }

        /// ### Source Localization
        ///
        /// ```
        /// Excellent choice! 🎉
        /// ```
        @available(*, deprecated, message: "Use `String.Localizable.excellentChoice` instead. This property will be removed in the future.")
        internal var excellentChoice: LocalizedStringResource {
            LocalizedStringResource(localizable: .excellentChoice)
        }

        /// ### Source Localization
        ///
        /// ```
        /// Expiration Date
        /// ```
        @available(*, deprecated, message: "Use `String.Localizable.expirationDate` instead. This property will be removed in the future.")
        internal var expirationDate: LocalizedStringResource {
            LocalizedStringResource(localizable: .expirationDate)
        }

        /// ### Source Localization
        ///
        /// ```
        /// Failed to export logs.
        /// ```
        @available(*, deprecated, message: "Use `String.Localizable.failedToExportLogs` instead. This property will be removed in the future.")
        internal var failedToExportLogs: LocalizedStringResource {
            LocalizedStringResource(localizable: .failedToExportLogs)
        }

        /// ### Source Localization
        ///
        /// ```
        /// Activists
        /// ```
        @available(*, deprecated, message: "Use `String.Localizable.featuredAuthorCategoryActivists` instead. This property will be removed in the future.")
        internal var featuredAuthorCategoryActivists: LocalizedStringResource {
            LocalizedStringResource(localizable: .featuredAuthorCategoryActivists)
        }

        /// ### Source Localization
        ///
        /// ```
        /// All
        /// ```
        @available(*, deprecated, message: "Use `String.Localizable.featuredAuthorCategoryAll` instead. This property will be removed in the future.")
        internal var featuredAuthorCategoryAll: LocalizedStringResource {
            LocalizedStringResource(localizable: .featuredAuthorCategoryAll)
        }

        /// ### Source Localization
        ///
        /// ```
        /// Art
        /// ```
        @available(*, deprecated, message: "Use `String.Localizable.featuredAuthorCategoryArt` instead. This property will be removed in the future.")
        internal var featuredAuthorCategoryArt: LocalizedStringResource {
            LocalizedStringResource(localizable: .featuredAuthorCategoryArt)
        }

        /// ### Source Localization
        ///
        /// ```
        /// Gaming
        /// ```
        @available(*, deprecated, message: "Use `String.Localizable.featuredAuthorCategoryGaming` instead. This property will be removed in the future.")
        internal var featuredAuthorCategoryGaming: LocalizedStringResource {
            LocalizedStringResource(localizable: .featuredAuthorCategoryGaming)
        }

        /// ### Source Localization
        ///
        /// ```
        /// Health
        /// ```
        @available(*, deprecated, message: "Use `String.Localizable.featuredAuthorCategoryHealth` instead. This property will be removed in the future.")
        internal var featuredAuthorCategoryHealth: LocalizedStringResource {
            LocalizedStringResource(localizable: .featuredAuthorCategoryHealth)
        }

        /// ### Source Localization
        ///
        /// ```
        /// Music
        /// ```
        @available(*, deprecated, message: "Use `String.Localizable.featuredAuthorCategoryMusic` instead. This property will be removed in the future.")
        internal var featuredAuthorCategoryMusic: LocalizedStringResource {
            LocalizedStringResource(localizable: .featuredAuthorCategoryMusic)
        }

        /// ### Source Localization
        ///
        /// ```
        /// New
        /// ```
        @available(*, deprecated, message: "Use `String.Localizable.featuredAuthorCategoryNew` instead. This property will be removed in the future.")
        internal var featuredAuthorCategoryNew: LocalizedStringResource {
            LocalizedStringResource(localizable: .featuredAuthorCategoryNew)
        }

        /// ### Source Localization
        ///
        /// ```
        /// News
        /// ```
        @available(*, deprecated, message: "Use `String.Localizable.featuredAuthorCategoryNews` instead. This property will be removed in the future.")
        internal var featuredAuthorCategoryNews: LocalizedStringResource {
            LocalizedStringResource(localizable: .featuredAuthorCategoryNews)
        }

        /// ### Source Localization
        ///
        /// ```
        /// Sports
        /// ```
        @available(*, deprecated, message: "Use `String.Localizable.featuredAuthorCategorySports` instead. This property will be removed in the future.")
        internal var featuredAuthorCategorySports: LocalizedStringResource {
            LocalizedStringResource(localizable: .featuredAuthorCategorySports)
        }

        /// ### Source Localization
        ///
        /// ```
        /// Tech
        /// ```
        @available(*, deprecated, message: "Use `String.Localizable.featuredAuthorCategoryTech` instead. This property will be removed in the future.")
        internal var featuredAuthorCategoryTech: LocalizedStringResource {
            LocalizedStringResource(localizable: .featuredAuthorCategoryTech)
        }

        /// ### Source Localization
        ///
        /// ```
        /// Feed Settings
        /// ```
        @available(*, deprecated, message: "Use `String.Localizable.feedSettings` instead. This property will be removed in the future.")
        internal var feedSettings: LocalizedStringResource {
            LocalizedStringResource(localizable: .feedSettings)
        }

        /// ### Source Localization
        ///
        /// ```
        /// Fetched
        /// ```
        @available(*, deprecated, message: "Use `String.Localizable.fetchedAt` instead. This property will be removed in the future.")
        internal var fetchedAt: LocalizedStringResource {
            LocalizedStringResource(localizable: .fetchedAt)
        }

        /// ### Source Localization
        ///
        /// ```
        /// Flag this user
        /// ```
        @available(*, deprecated, message: "Use `String.Localizable.flagUser` instead. This property will be removed in the future.")
        internal var flagUser: LocalizedStringResource {
            LocalizedStringResource(localizable: .flagUser)
        }

        /// ### Source Localization
        ///
        /// ```
        /// Create a flag for this user that other users in the network can see.
        /// ```
        @available(*, deprecated, message: "Use `String.Localizable.flagUserMessage` instead. This property will be removed in the future.")
        internal var flagUserMessage: LocalizedStringResource {
            LocalizedStringResource(localizable: .flagUserMessage)
        }

        /// ### Source Localization
        ///
        /// ```
        /// Follow
        /// ```
        @available(*, deprecated, message: "Use `String.Localizable.follow` instead. This property will be removed in the future.")
        internal var follow: LocalizedStringResource {
            LocalizedStringResource(localizable: .follow)
        }

        /// ### Source Localization
        ///
        /// ```
        /// Followed by **%@**
        /// ```
        @available(*, deprecated, message: "Use `String.Localizable.followedByOne(_:)` instead. This method will be removed in the future.")
        internal func followedByOne(_ arg1: String) -> LocalizedStringResource {
            LocalizedStringResource(localizable: .followedByOne(arg1))
        }

        /// ### Source Localization
        ///
        /// ```
        /// Followed by **%1$@** and **%2$lld others**
        /// ```
        @available(*, deprecated, message: "Use `String.Localizable.followedByOneAndMore(_:_:)` instead. This method will be removed in the future.")
        internal func followedByOneAndMore(_ arg1: String, _ arg2: Int) -> LocalizedStringResource {
            LocalizedStringResource(localizable: .followedByOneAndMore(arg1, arg2))
        }

        /// ### Source Localization
        ///
        /// ```
        /// Followed by **%1$@** and **%2$@**
        /// ```
        @available(*, deprecated, message: "Use `String.Localizable.followedByTwo(_:_:)` instead. This method will be removed in the future.")
        internal func followedByTwo(_ arg1: String, _ arg2: String) -> LocalizedStringResource {
            LocalizedStringResource(localizable: .followedByTwo(arg1, arg2))
        }

        /// ### Source Localization
        ///
        /// ```
        /// Followed by **%1$@**, **%2$@** and **%3$lld others**
        /// ```
        @available(*, deprecated, message: "Use `String.Localizable.followedByTwoAndMore(_:_:_:)` instead. This method will be removed in the future.")
        internal func followedByTwoAndMore(_ arg1: String, _ arg2: String, _ arg3: Int) -> LocalizedStringResource {
            LocalizedStringResource(localizable: .followedByTwoAndMore(arg1, arg2, arg3))
        }

        /// ### Source Localization
        ///
        /// ```
        /// Followers
        /// ```
        @available(*, deprecated, message: "Use `String.Localizable.followers` instead. This property will be removed in the future.")
        internal var followers: LocalizedStringResource {
            LocalizedStringResource(localizable: .followers)
        }

        /// ### Source Localization
        ///
        /// ```
        /// Followers you know
        /// ```
        @available(*, deprecated, message: "Use `String.Localizable.followersYouKnow` instead. This property will be removed in the future.")
        internal var followersYouKnow: LocalizedStringResource {
            LocalizedStringResource(localizable: .followersYouKnow)
        }

        /// ### Source Localization
        ///
        /// ```
        /// Following
        /// ```
        @available(*, deprecated, message: "Use `String.Localizable.following` instead. This property will be removed in the future.")
        internal var following: LocalizedStringResource {
            LocalizedStringResource(localizable: .following)
        }

        /// ### Source Localization
        ///
        /// ```
        /// Follows
        /// ```
        @available(*, deprecated, message: "Use `String.Localizable.follows` instead. This property will be removed in the future.")
        internal var follows: LocalizedStringResource {
            LocalizedStringResource(localizable: .follows)
        }

        /// ### Source Localization
        ///
        /// ```
        /// Get My Handle
        /// ```
        @available(*, deprecated, message: "Use `String.Localizable.getMyHandle` instead. This property will be removed in the future.")
        internal var getMyHandle: LocalizedStringResource {
            LocalizedStringResource(localizable: .getMyHandle)
        }

        /// ### Source Localization
        ///
        /// ```
        /// Go back
        /// ```
        @available(*, deprecated, message: "Use `String.Localizable.goBack` instead. This property will be removed in the future.")
        internal var goBack: LocalizedStringResource {
            LocalizedStringResource(localizable: .goBack)
        }

        /// ### Source Localization
        ///
        /// ```
        /// You may want to go back and register a different name
        /// ```
        @available(*, deprecated, message: "Use `String.Localizable.goBackAndRegister` instead. This property will be removed in the future.")
        internal var goBackAndRegister: LocalizedStringResource {
            LocalizedStringResource(localizable: .goBackAndRegister)
        }

        /// ### Source Localization
        ///
        /// ```
        /// Feed
        /// ```
        @available(*, deprecated, message: "Use `String.Localizable.homeFeed` instead. This property will be removed in the future.")
        internal var homeFeed: LocalizedStringResource {
            LocalizedStringResource(localizable: .homeFeed)
        }

        /// ### Source Localization
        ///
        /// ```
        /// hour
        /// ```
        @available(*, deprecated, message: "Use `String.Localizable.hourAbbreviated` instead. This property will be removed in the future.")
        internal var hourAbbreviated: LocalizedStringResource {
            LocalizedStringResource(localizable: .hourAbbreviated)
        }

        /// ### Source Localization
        ///
        /// ```
        /// hours
        /// ```
        @available(*, deprecated, message: "Use `String.Localizable.hoursAbbreviated` instead. This property will be removed in the future.")
        internal var hoursAbbreviated: LocalizedStringResource {
            LocalizedStringResource(localizable: .hoursAbbreviated)
        }

        /// ### Source Localization
        ///
        /// ```
        /// Identity verification
        /// ```
        @available(*, deprecated, message: "Use `String.Localizable.identityVerification` instead. This property will be removed in the future.")
        internal var identityVerification: LocalizedStringResource {
            LocalizedStringResource(localizable: .identityVerification)
        }

        /// ### Source Localization
        ///
        /// ```
        /// Invalid Key
        /// ```
        @available(*, deprecated, message: "Use `String.Localizable.invalidKey` instead. This property will be removed in the future.")
        internal var invalidKey: LocalizedStringResource {
            LocalizedStringResource(localizable: .invalidKey)
        }

        /// ### Source Localization
        ///
        /// ```
        /// Please enter a valid websocket URL.
        /// ```
        @available(*, deprecated, message: "Use `String.Localizable.invalidURLError` instead. This property will be removed in the future.")
        internal var invalidURLError: LocalizedStringResource {
            LocalizedStringResource(localizable: .invalidURLError)
        }

        /// ### Source Localization
        ///
        /// ```
        /// Keys
        /// ```
        @available(*, deprecated, message: "Use `String.Localizable.keys` instead. This property will be removed in the future.")
        internal var keys: LocalizedStringResource {
            LocalizedStringResource(localizable: .keys)
        }

        /// ### Source Localization
        ///
        /// ```
        /// Learn more
        /// ```
        @available(*, deprecated, message: "Use `String.Localizable.learnMore` instead. This property will be removed in the future.")
        internal var learnMore: LocalizedStringResource {
            LocalizedStringResource(localizable: .learnMore)
        }

        /// ### Source Localization
        ///
        /// ```
        /// 🔗 Link to note
        /// ```
        @available(*, deprecated, message: "Use `String.Localizable.linkToNote` instead. This property will be removed in the future.")
        internal var linkToNote: LocalizedStringResource {
            LocalizedStringResource(localizable: .linkToNote)
        }

        /// ### Source Localization
        ///
        /// ```
        /// Enter your existing NIP-05 here:
        /// ```
        @available(*, deprecated, message: "Use `String.Localizable.linkYourNIP05Description` instead. This property will be removed in the future.")
        internal var linkYourNIP05Description: LocalizedStringResource {
            LocalizedStringResource(localizable: .linkYourNIP05Description)
        }

        /// ### Source Localization
        ///
        /// ```
        /// Already have a NIP-05?
        /// ```
        @available(*, deprecated, message: "Use `String.Localizable.linkYourNIP05Title` instead. This property will be removed in the future.")
        internal var linkYourNIP05Title: LocalizedStringResource {
            LocalizedStringResource(localizable: .linkYourNIP05Title)
        }

        /// ### Source Localization
        ///
        /// ```
        /// Loading...
        /// ```
        @available(*, deprecated, message: "Use `String.Localizable.loading` instead. This property will be removed in the future.")
        internal var loading: LocalizedStringResource {
            LocalizedStringResource(localizable: .loading)
        }

        /// ### Source Localization
        ///
        /// ```
        /// Load Sample Data
        /// ```
        @available(*, deprecated, message: "Use `String.Localizable.loadSampleData` instead. This property will be removed in the future.")
        internal var loadSampleData: LocalizedStringResource {
            LocalizedStringResource(localizable: .loadSampleData)
        }

        /// ### Source Localization
        ///
        /// ```
        /// Login
        /// ```
        @available(*, deprecated, message: "Use `String.Localizable.login` instead. This property will be removed in the future.")
        internal var login: LocalizedStringResource {
            LocalizedStringResource(localizable: .login)
        }

        /// ### Source Localization
        ///
        /// ```
        /// Login with key
        /// ```
        @available(*, deprecated, message: "Use `String.Localizable.loginWithKey` instead. This property will be removed in the future.")
        internal var loginWithKey: LocalizedStringResource {
            LocalizedStringResource(localizable: .loginWithKey)
        }

        /// ### Source Localization
        ///
        /// ```
        /// Login with your keys
        /// ```
        @available(*, deprecated, message: "Use `String.Localizable.logInWithYourKeys` instead. This property will be removed in the future.")
        internal var logInWithYourKeys: LocalizedStringResource {
            LocalizedStringResource(localizable: .logInWithYourKeys)
        }

        /// ### Source Localization
        ///
        /// ```
        /// Logout
        /// ```
        @available(*, deprecated, message: "Use `String.Localizable.logout` instead. This property will be removed in the future.")
        internal var logout: LocalizedStringResource {
            LocalizedStringResource(localizable: .logout)
        }

        /// ### Source Localization
        ///
        /// ```
        /// Manage your Universal Name
        /// ```
        @available(*, deprecated, message: "Use `String.Localizable.manageUniversalName` instead. This property will be removed in the future.")
        internal var manageUniversalName: LocalizedStringResource {
            LocalizedStringResource(localizable: .manageUniversalName)
        }

        /// ### Source Localization
        ///
        /// ```
        /// Mention
        /// ```
        @available(*, deprecated, message: "Use `String.Localizable.mention` instead. This property will be removed in the future.")
        internal var mention: LocalizedStringResource {
            LocalizedStringResource(localizable: .mention)
        }

        /// ### Source Localization
        ///
        /// ```
        /// Metadata
        /// ```
        @available(*, deprecated, message: "Use `String.Localizable.metadata` instead. This property will be removed in the future.")
        internal var metadata: LocalizedStringResource {
            LocalizedStringResource(localizable: .metadata)
        }

        /// ### Source Localization
        ///
        /// ```
        /// min
        /// ```
        @available(*, deprecated, message: "Use `String.Localizable.minuteAbbreviated` instead. This property will be removed in the future.")
        internal var minuteAbbreviated: LocalizedStringResource {
            LocalizedStringResource(localizable: .minuteAbbreviated)
        }

        /// ### Source Localization
        ///
        /// ```
        /// Mute
        /// ```
        @available(*, deprecated, message: "Use `String.Localizable.mute` instead. This property will be removed in the future.")
        internal var mute: LocalizedStringResource {
            LocalizedStringResource(localizable: .mute)
        }

        /// ### Source Localization
        ///
        /// ```
        /// Muted
        /// ```
        @available(*, deprecated, message: "Use `String.Localizable.muted` instead. This property will be removed in the future.")
        internal var muted: LocalizedStringResource {
            LocalizedStringResource(localizable: .muted)
        }

        /// ### Source Localization
        ///
        /// ```
        /// Muted Users
        /// ```
        @available(*, deprecated, message: "Use `String.Localizable.mutedUsers` instead. This property will be removed in the future.")
        internal var mutedUsers: LocalizedStringResource {
            LocalizedStringResource(localizable: .mutedUsers)
        }

        /// ### Source Localization
        ///
        /// ```
        /// Would you like to mute %@?
        /// ```
        @available(*, deprecated, message: "Use `String.Localizable.mutePrompt(_:)` instead. This method will be removed in the future.")
        internal func mutePrompt(_ arg1: String) -> LocalizedStringResource {
            LocalizedStringResource(localizable: .mutePrompt(arg1))
        }

        /// ### Source Localization
        ///
        /// ```
        /// Mute User
        /// ```
        @available(*, deprecated, message: "Use `String.Localizable.muteUser` instead. This property will be removed in the future.")
        internal var muteUser: LocalizedStringResource {
            LocalizedStringResource(localizable: .muteUser)
        }

        /// ### Source Localization
        ///
        /// ```
        /// My key is backed up
        /// ```
        @available(*, deprecated, message: "Use `String.Localizable.myKeyIsBackedUp` instead. This property will be removed in the future.")
        internal var myKeyIsBackedUp: LocalizedStringResource {
            LocalizedStringResource(localizable: .myKeyIsBackedUp)
        }

        /// ### Source Localization
        ///
        /// ```
        /// Name
        /// ```
        @available(*, deprecated, message: "Use `String.Localizable.name` instead. This property will be removed in the future.")
        internal var name: LocalizedStringResource {
            LocalizedStringResource(localizable: .name)
        }

        /// ### Source Localization
        ///
        /// ```
        /// name
        /// ```
        @available(*, deprecated, message: "Use `String.Localizable.nameLower` instead. This property will be removed in the future.")
        internal var nameLower: LocalizedStringResource {
            LocalizedStringResource(localizable: .nameLower)
        }

        /// ### Source Localization
        ///
        /// ```
        /// New
        /// ```
        @available(*, deprecated, message: "Use `String.Localizable.new` instead. This property will be removed in the future.")
        internal var new: LocalizedStringResource {
            LocalizedStringResource(localizable: .new)
        }

        /// ### Source Localization
        ///
        /// ```
        /// New Note
        /// ```
        @available(*, deprecated, message: "Use `String.Localizable.newNote` instead. This property will be removed in the future.")
        internal var newNote: LocalizedStringResource {
            LocalizedStringResource(localizable: .newNote)
        }

        /// ### Source Localization
        ///
        /// ```
        /// Type your post here...
        /// ```
        @available(*, deprecated, message: "Use `String.Localizable.newNotePlaceholder` instead. This property will be removed in the future.")
        internal var newNotePlaceholder: LocalizedStringResource {
            LocalizedStringResource(localizable: .newNotePlaceholder)
        }

        /// ### Source Localization
        ///
        /// ```
        /// Next
        /// ```
        @available(*, deprecated, message: "Use `String.Localizable.next` instead. This property will be removed in the future.")
        internal var next: LocalizedStringResource {
            LocalizedStringResource(localizable: .next)
        }

        /// ### Source Localization
        ///
        /// ```
        /// Nice work!
        /// ```
        @available(*, deprecated, message: "Use `String.Localizable.niceWork` instead. This property will be removed in the future.")
        internal var niceWork: LocalizedStringResource {
            LocalizedStringResource(localizable: .niceWork)
        }

        /// ### Source Localization
        ///
        /// ```
        /// NIP-05
        /// ```
        @available(*, deprecated, message: "Use `String.Localizable.nip05` instead. This property will be removed in the future.")
        internal var nip05: LocalizedStringResource {
            LocalizedStringResource(localizable: .nip05)
        }

        /// ### Source Localization
        ///
        /// ```
        /// Your NIP-05 is now connected to your npub in the Nostr network.
        /// ```
        @available(*, deprecated, message: "Use `String.Localizable.nip05Connected` instead. This property will be removed in the future.")
        internal var nip05Connected: LocalizedStringResource {
            LocalizedStringResource(localizable: .nip05Connected)
        }

        /// ### Source Localization
        ///
        /// ```
        /// user@server.com
        /// ```
        @available(*, deprecated, message: "Use `String.Localizable.nip05Example` instead. This property will be removed in the future.")
        internal var nip05Example: LocalizedStringResource {
            LocalizedStringResource(localizable: .nip05Example)
        }

        /// ### Source Localization
        ///
        /// ```
        /// Learn more about NIP-05 name verification.
        /// ```
        @available(*, deprecated, message: "Use `String.Localizable.nip05LearnMore` instead. This property will be removed in the future.")
        internal var nip05LearnMore: LocalizedStringResource {
            LocalizedStringResource(localizable: .nip05LearnMore)
        }

        /// ### Source Localization
        ///
        /// ```
        /// **The NIP05 entered does not match the records of the NIP-05 provider.**
        ///
        /// Please verify the entry of the NIP-05 and try again. Or reach out to the NIP05 provider directly to verify your NIP05 is live.
        /// ```
        @available(*, deprecated, message: "Use `String.Localizable.nip05LinkFailed` instead. This property will be removed in the future.")
        internal var nip05LinkFailed: LocalizedStringResource {
            LocalizedStringResource(localizable: .nip05LinkFailed)
        }

        /// ### Source Localization
        ///
        /// ```
        /// No
        /// ```
        @available(*, deprecated, message: "Use `String.Localizable.no` instead. This property will be removed in the future.")
        internal var no: LocalizedStringResource {
            LocalizedStringResource(localizable: .no)
        }

        /// ### Source Localization
        ///
        /// ```
        /// No notes (yet)! Browse the Discover tab and follow some people to get started.
        /// ```
        @available(*, deprecated, message: "Use `String.Localizable.noEvents` instead. This property will be removed in the future.")
        internal var noEvents: LocalizedStringResource {
            LocalizedStringResource(localizable: .noEvents)
        }

        /// ### Source Localization
        ///
        /// ```
        /// We don't see any notes for this profile, but we'll keep looking!
        /// ```
        @available(*, deprecated, message: "Use `String.Localizable.noEventsOnProfile` instead. This property will be removed in the future.")
        internal var noEventsOnProfile: LocalizedStringResource {
            LocalizedStringResource(localizable: .noEventsOnProfile)
        }

        /// ### Source Localization
        ///
        /// ```
        /// No notifications (yet)!
        /// ```
        @available(*, deprecated, message: "Use `String.Localizable.noNotifications` instead. This property will be removed in the future.")
        internal var noNotifications: LocalizedStringResource {
            LocalizedStringResource(localizable: .noNotifications)
        }

        /// ### Source Localization
        ///
        /// ```
        /// No relays yet! Add one below to get started
        /// ```
        @available(*, deprecated, message: "Use `String.Localizable.noRelaysMessage` instead. This property will be removed in the future.")
        internal var noRelaysMessage: LocalizedStringResource {
            LocalizedStringResource(localizable: .noRelaysMessage)
        }

        /// ### Source Localization
        ///
        /// ```
        /// Nos
        /// ```
        @available(*, deprecated, message: "Use `String.Localizable.nos` instead. This property will be removed in the future.")
        internal var nos: LocalizedStringResource {
            LocalizedStringResource(localizable: .nos)
        }

        /// ### Source Localization
        ///
        /// ```
        /// Nos is open source! You can read the code, contribute new features, or even fork it and build your own Nostr client. No opaque algorithms or secret rules. See the code.
        /// ```
        @available(*, deprecated, message: "Use `String.Localizable.nosIsOpenSource` instead. This property will be removed in the future.")
        internal var nosIsOpenSource: LocalizedStringResource {
            LocalizedStringResource(localizable: .nosIsOpenSource)
        }

        /// ### Source Localization
        ///
        /// ```
        /// See the code.
        /// ```
        @available(*, deprecated, message: "Use `String.Localizable.nosIsOpenSourceHighlight` instead. This property will be removed in the future.")
        internal var nosIsOpenSourceHighlight: LocalizedStringResource {
            LocalizedStringResource(localizable: .nosIsOpenSourceHighlight)
        }

        /// ### Source Localization
        ///
        /// ```
        /// note
        /// ```
        @available(*, deprecated, message: "Use `String.Localizable.note` instead. This property will be removed in the future.")
        internal var note: LocalizedStringResource {
            LocalizedStringResource(localizable: .note)
        }

        /// ### Source Localization
        ///
        /// ```
        /// Note disappears in
        /// ```
        @available(*, deprecated, message: "Use `String.Localizable.noteDisappearsIn` instead. This property will be removed in the future.")
        internal var noteDisappearsIn: LocalizedStringResource {
            LocalizedStringResource(localizable: .noteDisappearsIn)
        }

        /// ### Source Localization
        ///
        /// ```
        /// This note has been flagged by **%1$@** for %2$@.
        /// ```
        @available(*, deprecated, message: "Use `String.Localizable.noteReportedByOne(_:_:)` instead. This method will be removed in the future.")
        internal func noteReportedByOne(_ arg1: String, _ arg2: String) -> LocalizedStringResource {
            LocalizedStringResource(localizable: .noteReportedByOne(arg1, arg2))
        }

        /// ### Source Localization
        ///
        /// ```
        /// This note has been flagged by **%1$@** and **%2$lld others** for %3$@.
        /// ```
        @available(*, deprecated, message: "Use `String.Localizable.noteReportedByOneAndMore(_:_:_:)` instead. This method will be removed in the future.")
        internal func noteReportedByOneAndMore(_ arg1: String, _ arg2: Int, _ arg3: String) -> LocalizedStringResource {
            LocalizedStringResource(localizable: .noteReportedByOneAndMore(arg1, arg2, arg3))
        }

        /// ### Source Localization
        ///
        /// ```
        /// Notes
        /// ```
        @available(*, deprecated, message: "Use `String.Localizable.notes` instead. This property will be removed in the future.")
        internal var notes: LocalizedStringResource {
            LocalizedStringResource(localizable: .notes)
        }

        /// ### Source Localization
        ///
        /// ```
        /// We are not finding results on your relays. You can continue waiting or try another search term.
        /// ```
        @available(*, deprecated, message: "Use `String.Localizable.notFindingResults` instead. This property will be removed in the future.")
        internal var notFindingResults: LocalizedStringResource {
            LocalizedStringResource(localizable: .notFindingResults)
        }

        /// ### Source Localization
        ///
        /// ```
        /// Notifications
        /// ```
        @available(*, deprecated, message: "Use `String.Localizable.notifications` instead. This property will be removed in the future.")
        internal var notifications: LocalizedStringResource {
            LocalizedStringResource(localizable: .notifications)
        }

        /// ### Source Localization
        ///
        /// ```
        /// Go back (to school)
        /// ```
        @available(*, deprecated, message: "Use `String.Localizable.notOldEnoughButton` instead. This property will be removed in the future.")
        internal var notOldEnoughButton: LocalizedStringResource {
            LocalizedStringResource(localizable: .notOldEnoughButton)
        }

        /// ### Source Localization
        ///
        /// ```
        /// You need to be 16 years old to be able to use this app.
        /// ```
        @available(*, deprecated, message: "Use `String.Localizable.notOldEnoughSubtitle` instead. This property will be removed in the future.")
        internal var notOldEnoughSubtitle: LocalizedStringResource {
            LocalizedStringResource(localizable: .notOldEnoughSubtitle)
        }

        /// ### Source Localization
        ///
        /// ```
        /// Sorry, but Nos is not for you yet,
        /// ```
        @available(*, deprecated, message: "Use `String.Localizable.notOldEnoughTitle` instead. This property will be removed in the future.")
        internal var notOldEnoughTitle: LocalizedStringResource {
            LocalizedStringResource(localizable: .notOldEnoughTitle)
        }

        /// ### Source Localization
        ///
        /// ```
        /// now
        /// ```
        @available(*, deprecated, message: "Use `String.Localizable.now` instead. This property will be removed in the future.")
        internal var now: LocalizedStringResource {
            LocalizedStringResource(localizable: .now)
        }

        /// ### Source Localization
        ///
        /// ```
        /// Ok
        /// ```
        @available(*, deprecated, message: "Use `String.Localizable.ok` instead. This property will be removed in the future.")
        internal var ok: LocalizedStringResource {
            LocalizedStringResource(localizable: .ok)
        }

        /// ### Source Localization
        ///
        /// ```
        /// the human network
        /// ```
        @available(*, deprecated, message: "Use `String.Localizable.onboardingTitle` instead. This property will be removed in the future.")
        internal var onboardingTitle: LocalizedStringResource {
            LocalizedStringResource(localizable: .onboardingTitle)
        }

        /// ### Source Localization
        ///
        /// ```
        /// Oops!
        /// ```
        @available(*, deprecated, message: "Use `String.Localizable.oops` instead. This property will be removed in the future.")
        internal var oops: LocalizedStringResource {
            LocalizedStringResource(localizable: .oops)
        }

        /// ### Source Localization
        ///
        /// ```
        /// This user is outside your network.
        /// ```
        @available(*, deprecated, message: "Use `String.Localizable.outsideNetwork` instead. This property will be removed in the future.")
        internal var outsideNetwork: LocalizedStringResource {
            LocalizedStringResource(localizable: .outsideNetwork)
        }

        /// ### Source Localization
        ///
        /// ```
        /// This note originates from someone beyond your 'friends of friends' network. Nos hides these by default. You can change this in the settings menu.
        /// ```
        @available(*, deprecated, message: "Use `String.Localizable.outsideNetworkExplanation` instead. This property will be removed in the future.")
        internal var outsideNetworkExplanation: LocalizedStringResource {
            LocalizedStringResource(localizable: .outsideNetworkExplanation)
        }

        /// ### Source Localization
        ///
        /// ```
        /// Paste your secret key
        /// ```
        @available(*, deprecated, message: "Use `String.Localizable.pasteYourSecretKey` instead. This property will be removed in the future.")
        internal var pasteYourSecretKey: LocalizedStringResource {
            LocalizedStringResource(localizable: .pasteYourSecretKey)
        }

        /// ### Source Localization
        ///
        /// ```
        /// Your **@username** is your identity in the Nos community.
        ///
        /// Choose a name that reflects you or your organization. Make it memorable and distinct!
        /// ```
        @available(*, deprecated, message: "Use `String.Localizable.pickYourUsernameDescription` instead. This property will be removed in the future.")
        internal var pickYourUsernameDescription: LocalizedStringResource {
            LocalizedStringResource(localizable: .pickYourUsernameDescription)
        }

        /// ### Source Localization
        ///
        /// ```
        /// Pick your @username
        /// ```
        @available(*, deprecated, message: "Use `String.Localizable.pickYourUsernameTitle` instead. This property will be removed in the future.")
        internal var pickYourUsernameTitle: LocalizedStringResource {
            LocalizedStringResource(localizable: .pickYourUsernameTitle)
        }

        /// ### Source Localization
        ///
        /// ```
        /// Post
        /// ```
        @available(*, deprecated, message: "Use `String.Localizable.post` instead. This property will be removed in the future.")
        internal var post: LocalizedStringResource {
            LocalizedStringResource(localizable: .post)
        }

        /// ### Source Localization
        ///
        /// ```
        /// This is a Premium name
        /// ```
        @available(*, deprecated, message: "Use `String.Localizable.premiumName` instead. This property will be removed in the future.")
        internal var premiumName: LocalizedStringResource {
            LocalizedStringResource(localizable: .premiumName)
        }

        /// ### Source Localization
        ///
        /// ```
        /// You'll be redirected to the UNS website where you can register a premium name.
        /// ```
        @available(*, deprecated, message: "Use `String.Localizable.premiumNameDescription` instead. This property will be removed in the future.")
        internal var premiumNameDescription: LocalizedStringResource {
            LocalizedStringResource(localizable: .premiumNameDescription)
        }

        /// ### Source Localization
        ///
        /// ```
        /// Private Key
        /// ```
        @available(*, deprecated, message: "Use `String.Localizable.privateKey` instead. This property will be removed in the future.")
        internal var privateKey: LocalizedStringResource {
            LocalizedStringResource(localizable: .privateKey)
        }

        /// ### Source Localization
        ///
        /// ```
        /// nsec or hex...
        /// ```
        @available(*, deprecated, message: "Use `String.Localizable.privateKeyPlaceholder` instead. This property will be removed in the future.")
        internal var privateKeyPlaceholder: LocalizedStringResource {
            LocalizedStringResource(localizable: .privateKeyPlaceholder)
        }

        /// ### Source Localization
        ///
        /// ```
        /// Never share your private key with anyone. Save your private key in a password manager so you can restore access to your account & data.
        /// ```
        @available(*, deprecated, message: "Use `String.Localizable.privateKeyWarning` instead. This property will be removed in the future.")
        internal var privateKeyWarning: LocalizedStringResource {
            LocalizedStringResource(localizable: .privateKeyWarning)
        }

        /// ### Source Localization
        ///
        /// ```
        /// Profile picture
        /// ```
        @available(*, deprecated, message: "Use `String.Localizable.profilePicture` instead. This property will be removed in the future.")
        internal var profilePicture: LocalizedStringResource {
            LocalizedStringResource(localizable: .profilePicture)
        }

        /// ### Source Localization
        ///
        /// ```
        /// Profile
        /// ```
        @available(*, deprecated, message: "Use `String.Localizable.profileTitle` instead. This property will be removed in the future.")
        internal var profileTitle: LocalizedStringResource {
            LocalizedStringResource(localizable: .profileTitle)
        }

        /// ### Source Localization
        ///
        /// ```
        /// Public key
        /// ```
        @available(*, deprecated, message: "Use `String.Localizable.pubkey` instead. This property will be removed in the future.")
        internal var pubkey: LocalizedStringResource {
            LocalizedStringResource(localizable: .pubkey)
        }

        /// ### Source Localization
        ///
        /// ```
        /// Read more
        /// ```
        @available(*, deprecated, message: "Use `String.Localizable.readMore` instead. This property will be removed in the future.")
        internal var readMore: LocalizedStringResource {
            LocalizedStringResource(localizable: .readMore)
        }

        /// ### Source Localization
        ///
        /// ```
        /// Recommended Relays
        /// ```
        @available(*, deprecated, message: "Use `String.Localizable.recommendedRelays` instead. This property will be removed in the future.")
        internal var recommendedRelays: LocalizedStringResource {
            LocalizedStringResource(localizable: .recommendedRelays)
        }

        /// ### Source Localization
        ///
        /// ```
        /// Reconnect wallet
        /// ```
        @available(*, deprecated, message: "Use `String.Localizable.reconnectWallet` instead. This property will be removed in the future.")
        internal var reconnectWallet: LocalizedStringResource {
            LocalizedStringResource(localizable: .reconnectWallet)
        }

        /// ### Source Localization
        ///
        /// ```
        /// register a different name
        /// ```
        @available(*, deprecated, message: "Use `String.Localizable.registerADifferentName` instead. This property will be removed in the future.")
        internal var registerADifferentName: LocalizedStringResource {
            LocalizedStringResource(localizable: .registerADifferentName)
        }

        /// ### Source Localization
        ///
        /// ```
        /// Register Premium Name
        /// ```
        @available(*, deprecated, message: "Use `String.Localizable.registerPremiumName` instead. This property will be removed in the future.")
        internal var registerPremiumName: LocalizedStringResource {
            LocalizedStringResource(localizable: .registerPremiumName)
        }

        /// ### Source Localization
        ///
        /// ```
        /// Registration
        /// ```
        @available(*, deprecated, message: "Use `String.Localizable.registration` instead. This property will be removed in the future.")
        internal var registration: LocalizedStringResource {
            LocalizedStringResource(localizable: .registration)
        }

        /// ### Source Localization
        ///
        /// ```
        /// Enter your phone number so we can send you an SMS code.
        /// ```
        @available(*, deprecated, message: "Use `String.Localizable.registrationDescription` instead. This property will be removed in the future.")
        internal var registrationDescription: LocalizedStringResource {
            LocalizedStringResource(localizable: .registrationDescription)
        }

        /// ### Source Localization
        ///
        /// ```
        /// Reject
        /// ```
        @available(*, deprecated, message: "Use `String.Localizable.reject` instead. This property will be removed in the future.")
        internal var reject: LocalizedStringResource {
            LocalizedStringResource(localizable: .reject)
        }

        /// ### Source Localization
        ///
        /// ```
        /// Relay
        /// ```
        @available(*, deprecated, message: "Use `String.Localizable.relay` instead. This property will be removed in the future.")
        internal var relay: LocalizedStringResource {
            LocalizedStringResource(localizable: .relay)
        }

        /// ### Source Localization
        ///
        /// ```
        /// wss://yourrelay.com
        /// ```
        @available(*, deprecated, message: "Use `String.Localizable.relayAddressPlaceholder` instead. This property will be removed in the future.")
        internal var relayAddressPlaceholder: LocalizedStringResource {
            LocalizedStringResource(localizable: .relayAddressPlaceholder)
        }

        /// ### Source Localization
        ///
        /// ```
        /// This relay doesn't support expiring messages. Please select another one.
        /// ```
        @available(*, deprecated, message: "Use `String.Localizable.relayDoesNotSupportNIP40` instead. This property will be removed in the future.")
        internal var relayDoesNotSupportNIP40: LocalizedStringResource {
            LocalizedStringResource(localizable: .relayDoesNotSupportNIP40)
        }

        /// ### Source Localization
        ///
        /// ```
        /// Relays
        /// ```
        @available(*, deprecated, message: "Use `String.Localizable.relays` instead. This property will be removed in the future.")
        internal var relays: LocalizedStringResource {
            LocalizedStringResource(localizable: .relays)
        }

        /// ### Source Localization
        ///
        /// ```
        /// Important! Nos works best with 5 or fewer relays.
        /// ```
        @available(*, deprecated, message: "Use `String.Localizable.relaysImportantMessage` instead. This property will be removed in the future.")
        internal var relaysImportantMessage: LocalizedStringResource {
            LocalizedStringResource(localizable: .relaysImportantMessage)
        }

        /// ### Source Localization
        ///
        /// ```
        /// [ %@ ]
        /// Send to Nos or Flag Publicly
        /// ```
        @available(*, deprecated, message: "Use `String.Localizable.reportActionTitle(_:)` instead. This method will be removed in the future.")
        internal func reportActionTitle(_ arg1: String) -> LocalizedStringResource {
            LocalizedStringResource(localizable: .reportActionTitle(arg1))
        }

        /// ### Source Localization
        ///
        /// ```
        /// Nos will review this flag and apply it anonymously if the review matches the category.
        /// ```
        @available(*, deprecated, message: "Use `String.Localizable.reportAuthorSendToNosConfirmation` instead. This property will be removed in the future.")
        internal var reportAuthorSendToNosConfirmation: LocalizedStringResource {
            LocalizedStringResource(localizable: .reportAuthorSendToNosConfirmation)
        }

        /// ### Source Localization
        ///
        /// ```
        /// Report Content
        /// ```
        @available(*, deprecated, message: "Use `String.Localizable.reportContent` instead. This property will be removed in the future.")
        internal var reportContent: LocalizedStringResource {
            LocalizedStringResource(localizable: .reportContent)
        }

        /// ### Source Localization
        ///
        /// ```
        /// Create a content flag for this post that other users in the network can see
        /// ```
        @available(*, deprecated, message: "Use `String.Localizable.reportContentMessage` instead. This property will be removed in the future.")
        internal var reportContentMessage: LocalizedStringResource {
            LocalizedStringResource(localizable: .reportContentMessage)
        }

        /// ### Source Localization
        ///
        /// ```
        /// This content has been flagged for %@.
        /// ```
        @available(*, deprecated, message: "Use `String.Localizable.reportEventContent(_:)` instead. This method will be removed in the future.")
        internal func reportEventContent(_ arg1: String) -> LocalizedStringResource {
            LocalizedStringResource(localizable: .reportEventContent(arg1))
        }

        /// ### Source Localization
        ///
        /// ```
        /// Are you sure you want to flag this as %@? This flag will be public.
        /// ```
        @available(*, deprecated, message: "Use `String.Localizable.reportFlagPubliclyConfirmation(_:)` instead. This method will be removed in the future.")
        internal func reportFlagPubliclyConfirmation(_ arg1: String) -> LocalizedStringResource {
            LocalizedStringResource(localizable: .reportFlagPubliclyConfirmation(arg1))
        }

        /// ### Source Localization
        ///
        /// ```
        /// Flag This Content
        /// ```
        @available(*, deprecated, message: "Use `String.Localizable.reportNote` instead. This property will be removed in the future.")
        internal var reportNote: LocalizedStringResource {
            LocalizedStringResource(localizable: .reportNote)
        }

        /// ### Source Localization
        ///
        /// ```
        /// The Nos moderation team will analyze the note for %@ content and may publish a report from our own account, concealing your identity.
        /// ```
        @available(*, deprecated, message: "Use `String.Localizable.reportNoteSendToNosConfirmation(_:)` instead. This method will be removed in the future.")
        internal func reportNoteSendToNosConfirmation(_ arg1: String) -> LocalizedStringResource {
            LocalizedStringResource(localizable: .reportNoteSendToNosConfirmation(arg1))
        }

        /// ### Source Localization
        ///
        /// ```
        /// Repost
        /// ```
        @available(*, deprecated, message: "Use `String.Localizable.repost` instead. This property will be removed in the future.")
        internal var repost: LocalizedStringResource {
            LocalizedStringResource(localizable: .repost)
        }

        /// ### Source Localization
        ///
        /// ```
        /// Retry
        /// ```
        @available(*, deprecated, message: "Use `String.Localizable.retry` instead. This property will be removed in the future.")
        internal var retry: LocalizedStringResource {
            LocalizedStringResource(localizable: .retry)
        }

        /// ### Source Localization
        ///
        /// ```
        /// Return to the choose name step and choose your registered name.
        /// ```
        @available(*, deprecated, message: "Use `String.Localizable.returnToChooseName` instead. This property will be removed in the future.")
        internal var returnToChooseName: LocalizedStringResource {
            LocalizedStringResource(localizable: .returnToChooseName)
        }

        /// ### Source Localization
        ///
        /// ```
        /// This will delete all events and load those in sample_data.json
        /// ```
        @available(*, deprecated, message: "Use `String.Localizable.sampleDataInstructions` instead. This property will be removed in the future.")
        internal var sampleDataInstructions: LocalizedStringResource {
            LocalizedStringResource(localizable: .sampleDataInstructions)
        }

        /// ### Source Localization
        ///
        /// ```
        /// Save
        /// ```
        @available(*, deprecated, message: "Use `String.Localizable.save` instead. This property will be removed in the future.")
        internal var save: LocalizedStringResource {
            LocalizedStringResource(localizable: .save)
        }

        /// ### Source Localization
        ///
        /// ```
        /// Could not save relay.
        /// ```
        @available(*, deprecated, message: "Use `String.Localizable.saveRelayError` instead. This property will be removed in the future.")
        internal var saveRelayError: LocalizedStringResource {
            LocalizedStringResource(localizable: .saveRelayError)
        }

        /// ### Source Localization
        ///
        /// ```
        /// Scan the QR code or download the Global ID app to send USBC to your friends!
        /// ```
        @available(*, deprecated, message: "Use `String.Localizable.scanTheWalletConnectQR` instead. This property will be removed in the future.")
        internal var scanTheWalletConnectQR: LocalizedStringResource {
            LocalizedStringResource(localizable: .scanTheWalletConnectQR)
        }

        /// ### Source Localization
        ///
        /// ```
        /// Search people on Nostr or the Fediverse
        /// ```
        @available(*, deprecated, message: "Use `String.Localizable.searchBar` instead. This property will be removed in the future.")
        internal var searchBar: LocalizedStringResource {
            LocalizedStringResource(localizable: .searchBar)
        }

        /// ### Source Localization
        ///
        /// ```
        /// See profile
        /// ```
        @available(*, deprecated, message: "Use `String.Localizable.seeProfile` instead. This property will be removed in the future.")
        internal var seeProfile: LocalizedStringResource {
            LocalizedStringResource(localizable: .seeProfile)
        }

        /// ### Source Localization
        ///
        /// ```
        /// Select
        /// ```
        @available(*, deprecated, message: "Use `String.Localizable.select` instead. This property will be removed in the future.")
        internal var select: LocalizedStringResource {
            LocalizedStringResource(localizable: .select)
        }

        /// ### Source Localization
        ///
        /// ```
        /// Send
        /// ```
        @available(*, deprecated, message: "Use `String.Localizable.send` instead. This property will be removed in the future.")
        internal var send: LocalizedStringResource {
            LocalizedStringResource(localizable: .send)
        }

        /// ### Source Localization
        ///
        /// ```
        /// Send SMS code
        /// ```
        @available(*, deprecated, message: "Use `String.Localizable.sendCode` instead. This property will be removed in the future.")
        internal var sendCode: LocalizedStringResource {
            LocalizedStringResource(localizable: .sendCode)
        }

        /// ### Source Localization
        ///
        /// ```
        /// Send to
        /// ```
        @available(*, deprecated, message: "Use `String.Localizable.sendTo` instead. This property will be removed in the future.")
        internal var sendTo: LocalizedStringResource {
            LocalizedStringResource(localizable: .sendTo)
        }

        /// ### Source Localization
        ///
        /// ```
        /// Send USBC
        /// ```
        @available(*, deprecated, message: "Use `String.Localizable.sendUSBC` instead. This property will be removed in the future.")
        internal var sendUSBC: LocalizedStringResource {
            LocalizedStringResource(localizable: .sendUSBC)
        }

        /// ### Source Localization
        ///
        /// ```
        /// Settings
        /// ```
        @available(*, deprecated, message: "Use `String.Localizable.settings` instead. This property will be removed in the future.")
        internal var settings: LocalizedStringResource {
            LocalizedStringResource(localizable: .settings)
        }

        /// ### Source Localization
        ///
        /// ```
        /// Set up my @username
        /// ```
        @available(*, deprecated, message: "Use `String.Localizable.setUpMyUsername` instead. This property will be removed in the future.")
        internal var setUpMyUsername: LocalizedStringResource {
            LocalizedStringResource(localizable: .setUpMyUsername)
        }

        /// ### Source Localization
        ///
        /// ```
        /// Reserve Your Name
        /// ```
        @available(*, deprecated, message: "Use `String.Localizable.setUpUNS` instead. This property will be removed in the future.")
        internal var setUpUNS: LocalizedStringResource {
            LocalizedStringResource(localizable: .setUpUNS)
        }

        /// ### Source Localization
        ///
        /// ```
        /// Share
        /// ```
        @available(*, deprecated, message: "Use `String.Localizable.share` instead. This property will be removed in the future.")
        internal var share: LocalizedStringResource {
            LocalizedStringResource(localizable: .share)
        }

        /// ### Source Localization
        ///
        /// ```
        /// Share logs
        /// ```
        @available(*, deprecated, message: "Use `String.Localizable.shareLogs` instead. This property will be removed in the future.")
        internal var shareLogs: LocalizedStringResource {
            LocalizedStringResource(localizable: .shareLogs)
        }

        /// ### Source Localization
        ///
        /// ```
        /// Share Nos
        /// ```
        @available(*, deprecated, message: "Use `String.Localizable.shareNos` instead. This property will be removed in the future.")
        internal var shareNos: LocalizedStringResource {
            LocalizedStringResource(localizable: .shareNos)
        }

        /// ### Source Localization
        ///
        /// ```
        /// Show
        /// ```
        @available(*, deprecated, message: "Use `String.Localizable.show` instead. This property will be removed in the future.")
        internal var show: LocalizedStringResource {
            LocalizedStringResource(localizable: .show)
        }

        /// ### Source Localization
        ///
        /// ```
        /// Show Out of Network warnings
        /// ```
        @available(*, deprecated, message: "Use `String.Localizable.showOutOfNetworkWarnings` instead. This property will be removed in the future.")
        internal var showOutOfNetworkWarnings: LocalizedStringResource {
            LocalizedStringResource(localizable: .showOutOfNetworkWarnings)
        }

        /// ### Source Localization
        ///
        /// ```
        /// Hide notes from users outside my friends of friends circle behind a content warning.
        /// ```
        @available(*, deprecated, message: "Use `String.Localizable.showOutOfNetworkWarningsDescription` instead. This property will be removed in the future.")
        internal var showOutOfNetworkWarningsDescription: LocalizedStringResource {
            LocalizedStringResource(localizable: .showOutOfNetworkWarningsDescription)
        }

        /// ### Source Localization
        ///
        /// ```
        /// Software
        /// ```
        @available(*, deprecated, message: "Use `String.Localizable.software` instead. This property will be removed in the future.")
        internal var software: LocalizedStringResource {
            LocalizedStringResource(localizable: .software)
        }

        /// ### Source Localization
        ///
        /// ```
        /// someone
        /// ```
        @available(*, deprecated, message: "Use `String.Localizable.someone` instead. This property will be removed in the future.")
        internal var someone: LocalizedStringResource {
            LocalizedStringResource(localizable: .someone)
        }

        /// ### Source Localization
        ///
        /// ```
        /// Something went wrong.
        /// ```
        @available(*, deprecated, message: "Use `String.Localizable.somethingWentWrong` instead. This property will be removed in the future.")
        internal var somethingWentWrong: LocalizedStringResource {
            LocalizedStringResource(localizable: .somethingWentWrong)
        }

        /// ### Source Localization
        ///
        /// ```
        /// Start
        /// ```
        @available(*, deprecated, message: "Use `String.Localizable.start` instead. This property will be removed in the future.")
        internal var start: LocalizedStringResource {
            LocalizedStringResource(localizable: .start)
        }

        /// ### Source Localization
        ///
        /// ```
        /// Start over
        /// ```
        @available(*, deprecated, message: "Use `String.Localizable.startOver` instead. This property will be removed in the future.")
        internal var startOver: LocalizedStringResource {
            LocalizedStringResource(localizable: .startOver)
        }

        /// ### Source Localization
        ///
        /// ```
        /// Stories
        /// ```
        @available(*, deprecated, message: "Use `String.Localizable.stories` instead. This property will be removed in the future.")
        internal var stories: LocalizedStringResource {
            LocalizedStringResource(localizable: .stories)
        }

        /// ### Source Localization
        ///
        /// ```
        /// Submit
        /// ```
        @available(*, deprecated, message: "Use `String.Localizable.submit` instead. This property will be removed in the future.")
        internal var submit: LocalizedStringResource {
            LocalizedStringResource(localizable: .submit)
        }

        /// ### Source Localization
        ///
        /// ```
        /// Success!
        /// ```
        @available(*, deprecated, message: "Use `String.Localizable.success` instead. This property will be removed in the future.")
        internal var success: LocalizedStringResource {
            LocalizedStringResource(localizable: .success)
        }

        /// ### Source Localization
        ///
        /// ```
        /// Supported NIPs
        /// ```
        @available(*, deprecated, message: "Use `String.Localizable.supportedNIPs` instead. This property will be removed in the future.")
        internal var supportedNIPs: LocalizedStringResource {
            LocalizedStringResource(localizable: .supportedNIPs)
        }

        /// ### Source Localization
        ///
        /// ```
        /// Terms of Service
        /// ```
        @available(*, deprecated, message: "Use `String.Localizable.termsOfServiceTitle` instead. This property will be removed in the future.")
        internal var termsOfServiceTitle: LocalizedStringResource {
            LocalizedStringResource(localizable: .termsOfServiceTitle)
        }

        /// ### Source Localization
        ///
        /// ```
        /// That name is taken.
        /// ```
        @available(*, deprecated, message: "Use `String.Localizable.thatNameIsTaken` instead. This property will be removed in the future.")
        internal var thatNameIsTaken: LocalizedStringResource {
            LocalizedStringResource(localizable: .thatNameIsTaken)
        }

        /// ### Source Localization
        ///
        /// ```
        /// Thread
        /// ```
        @available(*, deprecated, message: "Use `String.Localizable.thread` instead. This property will be removed in the future.")
        internal var thread: LocalizedStringResource {
            LocalizedStringResource(localizable: .thread)
        }

        /// ### Source Localization
        ///
        /// ```
        /// Please try again or contact support.
        /// ```
        @available(*, deprecated, message: "Use `String.Localizable.tryAgainOrContactSupport` instead. This property will be removed in the future.")
        internal var tryAgainOrContactSupport: LocalizedStringResource {
            LocalizedStringResource(localizable: .tryAgainOrContactSupport)
        }

        /// ### Source Localization
        ///
        /// ```
        /// Please try with a different name.
        /// ```
        @available(*, deprecated, message: "Use `String.Localizable.tryAnotherName` instead. This property will be removed in the future.")
        internal var tryAnotherName: LocalizedStringResource {
            LocalizedStringResource(localizable: .tryAnotherName)
        }

        /// ### Source Localization
        ///
        /// ```
        /// Try it
        /// ```
        @available(*, deprecated, message: "Use `String.Localizable.tryIt` instead. This property will be removed in the future.")
        internal var tryIt: LocalizedStringResource {
            LocalizedStringResource(localizable: .tryIt)
        }

        /// ### Source Localization
        ///
        /// ```
        /// Unfollow
        /// ```
        @available(*, deprecated, message: "Use `String.Localizable.unfollow` instead. This property will be removed in the future.")
        internal var unfollow: LocalizedStringResource {
            LocalizedStringResource(localizable: .unfollow)
        }

        /// ### Source Localization
        ///
        /// ```
        /// Universal name
        /// ```
        @available(*, deprecated, message: "Use `String.Localizable.universalName` instead. This property will be removed in the future.")
        internal var universalName: LocalizedStringResource {
            LocalizedStringResource(localizable: .universalName)
        }

        /// ### Source Localization
        ///
        /// ```
        /// unknown
        /// ```
        @available(*, deprecated, message: "Use `String.Localizable.unknownAuthor` instead. This property will be removed in the future.")
        internal var unknownAuthor: LocalizedStringResource {
            LocalizedStringResource(localizable: .unknownAuthor)
        }

        /// ### Source Localization
        ///
        /// ```
        /// Un-Mute
        /// ```
        @available(*, deprecated, message: "Use `String.Localizable.unmuteUser` instead. This property will be removed in the future.")
        internal var unmuteUser: LocalizedStringResource {
            LocalizedStringResource(localizable: .unmuteUser)
        }

        /// ### Source Localization
        ///
        /// ```
        /// The Universal Namespace gives you one name you can use everywhere. Register your Universal Name and connect it to your Nostr profile. Learn more.
        /// ```
        @available(*, deprecated, message: "Use `String.Localizable.unsDescription` instead. This property will be removed in the future.")
        internal var unsDescription: LocalizedStringResource {
            LocalizedStringResource(localizable: .unsDescription)
        }

        /// ### Source Localization
        ///
        /// ```
        /// Learn more about UNS.
        /// ```
        @available(*, deprecated, message: "Use `String.Localizable.unsLearnMore` instead. This property will be removed in the future.")
        internal var unsLearnMore: LocalizedStringResource {
            LocalizedStringResource(localizable: .unsLearnMore)
        }

        /// ### Source Localization
        ///
        /// ```
        /// Register your Universal Name
        /// ```
        @available(*, deprecated, message: "Use `String.Localizable.unsRegister` instead. This property will be removed in the future.")
        internal var unsRegister: LocalizedStringResource {
            LocalizedStringResource(localizable: .unsRegister)
        }

        /// ### Source Localization
        ///
        /// ```
        /// Universal Name Space gives you a name you can use everywhere.
        ///
        /// Verify your identity and link your social accounts, government ID, wallets and more.
        /// ```
        @available(*, deprecated, message: "Use `String.Localizable.unsRegisterDescription` instead. This property will be removed in the future.")
        internal var unsRegisterDescription: LocalizedStringResource {
            LocalizedStringResource(localizable: .unsRegisterDescription)
        }

        /// ### Source Localization
        ///
        /// ```
        /// You have successfully linked your Universal Name to your Nostr profile.
        /// ```
        @available(*, deprecated, message: "Use `String.Localizable.unsSuccessDescription` instead. This property will be removed in the future.")
        internal var unsSuccessDescription: LocalizedStringResource {
            LocalizedStringResource(localizable: .unsSuccessDescription)
        }

        /// ### Source Localization
        ///
        /// ```
        /// Universal Name Space brings identity verification you can trust.
        /// ```
        @available(*, deprecated, message: "Use `String.Localizable.unsTagline` instead. This property will be removed in the future.")
        internal var unsTagline: LocalizedStringResource {
            LocalizedStringResource(localizable: .unsTagline)
        }

        /// ### Source Localization
        ///
        /// ```
        /// Go to nostr.build to upload your photo, copy the URL provided and paste it here.
        /// ```
        @available(*, deprecated, message: "Use `String.Localizable.uploadProfilePicInstructions` instead. This property will be removed in the future.")
        internal var uploadProfilePicInstructions: LocalizedStringResource {
            LocalizedStringResource(localizable: .uploadProfilePicInstructions)
        }

        /// ### Source Localization
        ///
        /// ```
        /// URL
        /// ```
        @available(*, deprecated, message: "Use `String.Localizable.url` instead. This property will be removed in the future.")
        internal var url: LocalizedStringResource {
            LocalizedStringResource(localizable: .url)
        }

        /// ### Source Localization
        ///
        /// ```
        /// Use reports from my follows
        /// ```
        @available(*, deprecated, message: "Use `String.Localizable.useReportsFromFollows` instead. This property will be removed in the future.")
        internal var useReportsFromFollows: LocalizedStringResource {
            LocalizedStringResource(localizable: .useReportsFromFollows)
        }

        /// ### Source Localization
        ///
        /// ```
        /// When someone you follow flags a note or user, we'll add a content warning to their notes.
        /// ```
        @available(*, deprecated, message: "Use `String.Localizable.useReportsFromFollowsDescription` instead. This property will be removed in the future.")
        internal var useReportsFromFollowsDescription: LocalizedStringResource {
            LocalizedStringResource(localizable: .useReportsFromFollowsDescription)
        }

        /// ### Source Localization
        ///
        /// ```
        /// Username
        /// ```
        @available(*, deprecated, message: "Use `String.Localizable.username` instead. This property will be removed in the future.")
        internal var username: LocalizedStringResource {
            LocalizedStringResource(localizable: .username)
        }

        /// ### Source Localization
        ///
        /// ```
        /// Looks like someone's already claimed that @username.
        /// ```
        @available(*, deprecated, message: "Use `String.Localizable.usernameAlreadyClaimed` instead. This property will be removed in the future.")
        internal var usernameAlreadyClaimed: LocalizedStringResource {
            LocalizedStringResource(localizable: .usernameAlreadyClaimed)
        }

        /// ### Source Localization
        ///
        /// ```
        /// Well done, you've successfully claimed your **@username**!
        ///
        /// You can share this name with other people in the Nostr and Fediverse communities to make it easy to find you.
        /// ```
        @available(*, deprecated, message: "Use `String.Localizable.usernameClaimedNotice` instead. This property will be removed in the future.")
        internal var usernameClaimedNotice: LocalizedStringResource {
            LocalizedStringResource(localizable: .usernameClaimedNotice)
        }

        /// ### Source Localization
        ///
        /// ```
        /// Changing or removing your handle may cause web links to disconnect from your identity.
        /// ```
        @available(*, deprecated, message: "Use `String.Localizable.usernameWarningMessage` instead. This property will be removed in the future.")
        internal var usernameWarningMessage: LocalizedStringResource {
            LocalizedStringResource(localizable: .usernameWarningMessage)
        }

        /// ### Source Localization
        ///
        /// ```
        /// This user has been flagged by **%1$@** for %2$@.
        /// ```
        @available(*, deprecated, message: "Use `String.Localizable.userReportedByOne(_:_:)` instead. This method will be removed in the future.")
        internal func userReportedByOne(_ arg1: String, _ arg2: String) -> LocalizedStringResource {
            LocalizedStringResource(localizable: .userReportedByOne(arg1, arg2))
        }

        /// ### Source Localization
        ///
        /// ```
        /// This user has been flagged by **%1$@** and **%2$lld others** for %3$@.
        /// ```
        @available(*, deprecated, message: "Use `String.Localizable.userReportedByOneAndMore(_:_:_:)` instead. This method will be removed in the future.")
        internal func userReportedByOneAndMore(_ arg1: String, _ arg2: Int, _ arg3: String) -> LocalizedStringResource {
            LocalizedStringResource(localizable: .userReportedByOneAndMore(arg1, arg2, arg3))
        }

        /// ### Source Localization
        ///
        /// ```
        /// Verification
        /// ```
        @available(*, deprecated, message: "Use `String.Localizable.verification` instead. This property will be removed in the future.")
        internal var verification: LocalizedStringResource {
            LocalizedStringResource(localizable: .verification)
        }

        /// ### Source Localization
        ///
        /// ```
        /// Enter the 6-digit code we sent to %@
        /// ```
        @available(*, deprecated, message: "Use `String.Localizable.verificationDescription(_:)` instead. This method will be removed in the future.")
        internal func verificationDescription(_ arg1: String) -> LocalizedStringResource {
            LocalizedStringResource(localizable: .verificationDescription(arg1))
        }

        /// ### Source Localization
        ///
        /// ```
        /// Verify your identity
        /// ```
        @available(*, deprecated, message: "Use `String.Localizable.verifyYourIdentity` instead. This property will be removed in the future.")
        internal var verifyYourIdentity: LocalizedStringResource {
            LocalizedStringResource(localizable: .verifyYourIdentity)
        }

        /// ### Source Localization
        ///
        /// ```
        /// Version
        /// ```
        @available(*, deprecated, message: "Use `String.Localizable.version` instead. This property will be removed in the future.")
        internal var version: LocalizedStringResource {
            LocalizedStringResource(localizable: .version)
        }

        /// ### Source Localization
        ///
        /// ```
        /// View Source
        /// ```
        @available(*, deprecated, message: "Use `String.Localizable.viewSource` instead. This property will be removed in the future.")
        internal var viewSource: LocalizedStringResource {
            LocalizedStringResource(localizable: .viewSource)
        }

        /// ### Source Localization
        ///
        /// ```
        /// View this post anyway
        /// ```
        @available(*, deprecated, message: "Use `String.Localizable.viewThisPostAnyway` instead. This property will be removed in the future.")
        internal var viewThisPostAnyway: LocalizedStringResource {
            LocalizedStringResource(localizable: .viewThisPostAnyway)
        }

        /// ### Source Localization
        ///
        /// ```
        /// Website
        /// ```
        @available(*, deprecated, message: "Use `String.Localizable.website` instead. This property will be removed in the future.")
        internal var website: LocalizedStringResource {
            LocalizedStringResource(localizable: .website)
        }

        /// ### Source Localization
        ///
        /// ```
        /// Yes
        /// ```
        @available(*, deprecated, message: "Use `String.Localizable.yes` instead. This property will be removed in the future.")
        internal var yes: LocalizedStringResource {
            LocalizedStringResource(localizable: .yes)
        }

        /// ### Source Localization
        ///
        /// ```
        /// You need to enter a private key in Settings before you can publish posts.
        /// ```
        @available(*, deprecated, message: "Use `String.Localizable.youNeedToEnterAPrivateKeyBeforePosting` instead. This property will be removed in the future.")
        internal var youNeedToEnterAPrivateKeyBeforePosting: LocalizedStringResource {
            LocalizedStringResource(localizable: .youNeedToEnterAPrivateKeyBeforePosting)
        }

        /// ### Source Localization
        ///
        /// ```
        /// is your Universal Name.
        ///
        /// We've created a link between your Nostr profile and your Universal Name and filled your Universal Name into the username field on your profile.
        /// ```
        @available(*, deprecated, message: "Use `String.Localizable.yourNewUNMessage` instead. This property will be removed in the future.")
        internal var yourNewUNMessage: LocalizedStringResource {
            LocalizedStringResource(localizable: .yourNewUNMessage)
        }

        /// ### Source Localization
        ///
        /// ```
        /// Your Profile
        /// ```
        @available(*, deprecated, message: "Use `String.Localizable.yourProfile` instead. This property will be removed in the future.")
        internal var yourProfile: LocalizedStringResource {
            LocalizedStringResource(localizable: .yourProfile)
        }
    }

    @available(*, deprecated, message: "Use the `localizable(_:)` static method instead. This property will be removed in the future.") internal static let localizable = Localizable()

    internal init(localizable: String.Localizable) {
        self.init(
            localizable.key,
            defaultValue: localizable.defaultValue,
            table: localizable.table,
            bundle: .from(description: localizable.bundle)
        )
    }

    /// Creates a `LocalizedStringResource` that represents a localized value in the ‘Localizable‘ strings table.
    internal static func localizable(_ localizable: String.Localizable) -> LocalizedStringResource {
        LocalizedStringResource(localizable: localizable)
    }
}

#if canImport(SwiftUI)
import SwiftUI

@available(macOS 10.5, iOS 13, tvOS 13, watchOS 6, *)
extension Text {
    /// Creates a text view that displays a localized string defined in the ‘Localizable‘ strings table.
    internal init(localizable: String.Localizable) {
        if #available(macOS 13, iOS 16, tvOS 16, watchOS 9, *) {
            self.init(LocalizedStringResource(localizable: localizable))
            return
        }

        var stringInterpolation = LocalizedStringKey.StringInterpolation(literalCapacity: 0, interpolationCount: localizable.arguments.count)
        for argument in localizable.arguments {
            switch argument {
            case .int(let value):
                stringInterpolation.appendInterpolation(value)
            case .uint(let value):
                stringInterpolation.appendInterpolation(value)
            case .float(let value):
                stringInterpolation.appendInterpolation(value)
            case .double(let value):
                stringInterpolation.appendInterpolation(value)
            case .object(let value):
                stringInterpolation.appendInterpolation(value)
            }
        }
        let makeKey = LocalizedStringKey.init(stringInterpolation:)

        var key = makeKey(stringInterpolation)
        key.overrideKeyForLookup(using: localizable.key)

        self.init(key, tableName: localizable.table, bundle: .from(description: localizable.bundle))
    }
}

@available(macOS 10.5, iOS 13, tvOS 13, watchOS 6, *)
extension LocalizedStringKey {
    /// Creates a localized string key that represents a localized value in the ‘Localizable‘ strings table.
    @available(macOS 11, iOS 14, tvOS 14, watchOS 7, *)
    internal init(localizable: String.Localizable) {
        var stringInterpolation = LocalizedStringKey.StringInterpolation(literalCapacity: 0, interpolationCount: 1)

        if #available(macOS 13, iOS 16, tvOS 16, watchOS 9, *) {
            stringInterpolation.appendInterpolation(LocalizedStringResource(localizable: localizable))
        } else {
            stringInterpolation.appendInterpolation(Text(localizable: localizable))
        }

        let makeKey = LocalizedStringKey.init(stringInterpolation:)
        self = makeKey(stringInterpolation)
    }

    /// Creates a `LocalizedStringKey` that represents a localized value in the ‘Localizable‘ strings table.
    @available(macOS 11, iOS 14, tvOS 14, watchOS 7, *)
    internal static func localizable(_ localizable: String.Localizable) -> LocalizedStringKey {
        LocalizedStringKey(localizable: localizable)
    }

    /// Updates the underlying `key` used when performing localization lookups.
    ///
    /// By default, an instance of `LocalizedStringKey` can only be created
    /// using string interpolation, so if arguments are included, the format
    /// specifiers make up part of the key.
    ///
    /// This method allows you to change the key after initialization in order
    /// to match the value that might be defined in the strings table.
    fileprivate mutating func overrideKeyForLookup(using key: StaticString) {
        withUnsafeMutablePointer(to: &self) { pointer in
            let raw = UnsafeMutableRawPointer(pointer)
            let bound = raw.assumingMemoryBound(to: String.self)
            bound.pointee = String(describing: key)
        }
    }
}
#endif

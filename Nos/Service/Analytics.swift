import Dependencies
import Logger
import PostHog
import Starscream
import UIKit

/// An object to manage analytics data, currently wired up to send data to PostHog and registered as a global
/// dependency using the Dependencies library.
class Analytics {

    private let postHog: PostHogSDK?

    /// When an analytics event is tracked, we also create a breadcrumb in our crash reporter.
    @Dependency(\.crashReporting) private var crashReporting

    required init(mock: Bool = false) {
        let apiKey = Bundle.main.infoDictionary?["POSTHOG_API_KEY"] as? String ?? ""
        if !mock && !apiKey.isEmpty {
            let configuration = PostHogConfig(apiKey: apiKey, host: "https://posthog.planetary.tools")

            configuration.captureApplicationLifecycleEvents = true
            configuration.captureScreenViews = false
            // TODO: write screen views to log

            PostHogSDK.shared.setup(configuration)
            postHog = PostHogSDK.shared
        } else {
            postHog = nil
        }
    }

    func published(note: JSONEvent) {
        track("Published Note", properties: ["length": note.content.count])
    }

    func published(reply: JSONEvent) {
        track("Published Reply", properties: ["length": reply.content.count])
    }

    // MARK: - Screens
    
    func startedOnboarding() {
        track("Started Onboarding")
    }
    
    func completedOnboarding() {
        track("Completed Onboarding")
    }

    func showedHome() {
        track("Home Tab Tapped")
    }
    
    func showedDiscover() {
        track("Discover Tab Tapped")
    }
    
    func showedNoteComposer() {
        track("New Note Tapped")
    }
    
    func showedNotifications() {
        track("Notifications Tab Tapped")
    }
    
    func showedProfile() {
        track("Profile View Opened")
    }
    
    func showedThread() {
        track("Thread View Opened")
    }
    
    func showedSideMenu() {
        track("Contact Support Tapped")
    }
    
    func showedRelays() {
        track("Relay View Opened")
    }
    
    func showedSettings() {
        track("Settings View Opened")
    }
    
    func showedSupport() {
        track("Contact Support Tapped")
    }

    // MARK: - Actions
    
    func generatedKey() {
        track("Generated Private Key")
    }
    
    func importedKey() {
        track("Imported Private Key")
    }
    
    func added(_ relay: Relay) {
        track("Added Relay", properties: ["relay_address": relay.address ?? ""])
    }
    
    func removed(_ relay: Relay) {
        track("Removed Relay", properties: ["relay_address": relay.address ?? ""])
    }
    
    func followed(_ author: Author) {
        track("Followed", properties: ["followed": author.publicKey?.npub ?? ""])
    }
    
    func unfollowed(_ author: Author) {
        track("Unfollowed", properties: ["unfollowed": author.publicKey?.npub ?? ""])
    }
    
    func reported(_ reportedObject: ReportTarget) {
        track("Reported", properties: ["type": reportedObject.analyticsString])
    }
    
    func identify(with keyPair: KeyPair, nip05: String? = nil) {
        let npub = keyPair.npub
        Log.info("Analytics: Identified \(npub)")
        var userProperties: [String: Any] = ["npub": npub]
        if let nip05 {
            userProperties["NIP-05"] = nip05
        }
        postHog?.identify(keyPair.npub, userProperties: userProperties)
    }
    
    func databaseStatistics(_ statistics: [(String, Int)]) {
        let properties = Dictionary(uniqueKeysWithValues: statistics)
        track("Database Statistics", properties: properties)
    }
    
    func databaseCleanupStarted() {
        track("Database Cleanup Started")
    }
    
    func databaseCleanupTaskExpired() {
        track("Database Cleanup Task Expired")
    }
    
    func databaseCleanupCompleted(duration: TimeInterval) {
        track("Database Cleanup Completed", properties: ["duration": duration])
    }
    
    func logout() {
        track("Logged out")
        postHog?.reset()
    }

    /// Tracks the source of the app download when the user launches the app.
    func trackInstallationSourceIfNeeded() {
        let source = Bundle.main.installationSource
        // Make sure we don't track in debug mode.
        guard source != .debug else { return }

        let installSourceKey = "TrackedAppInstallationSource"

        // Check if we've already tracked this installation.
        if UserDefaults.standard.bool(forKey: installSourceKey) {
            return
        }

        track(
            "Installation Source",
            properties: [
                "source": source.rawValue,
                "platform": UIDevice.platformName,
                "app_version": Bundle.current.versionAndBuild
            ]
        )
        // Mark as tracked so we don't track again
        UserDefaults.standard.set(true, forKey: installSourceKey)
    }

    /// Tracks when the user submits a search on the Discover screen.
    func searchedDiscover() {
        track("Discover Search Started")
    }

    /// Tracks when the user submits a search on the Mentions screen.
    func mentionsAutocompleteCharactersEntered() {
        track("Mentions Autocomplete Characters Entered")
    }

    /// Tracks when the user taps on a search result on the Discover screen.
    func displayedAuthorFromDiscoverSearch(resultsCount: Int) {
        track(
            "Discover Search Displayed Author",
            properties: ["Number of results": resultsCount]
        )
    }

    /// Tracks when the user navigates to a note from the Discover search screen.
    func displayedNoteFromDiscoverSearch() {
        track(
            "Discover Search Displayed Note"
        )
    }
    
    /// Call this when publishing a new contact list for the user. 
    /// This is part of our solution to detect if Nos overwrites a user's contact list.
    /// https://github.com/planetary-social/cleanstr/issues/51
    func published(contactList: JSONEvent) {
        let properties: [String: Any] = [
            "date": contactList.createdAt, 
            "identifier": contactList.identifier ?? "null"
        ]
        
        track("Published Contact List", properties: properties)
    }

    // MARK: - Relays
    
    func rateLimited(by socket: WebSocket, requestCount: Int) {
        track(
            "Rate Limited", 
            properties: [
                "relay": socket.request.url?.absoluteString ?? "null",
                "count": requestCount,
            ]
        )
    }
    
    func badRequest(from socket: WebSocket, message: String) {
        track(
            "Bad Request to Relay", 
            properties: [
                "relay": socket.request.url?.absoluteString ?? "null",
                "details": message
            ]
        )
    }
    
    // MARK: - Notifications
    
    func receivedNotification() {
        track("Push Notification Received")
    }
    
    func displayedNotification() {
        track("Push Notification Displayed")
    }
    
    func tappedNotification() {
        track("Push Notification Tapped")
    }
    
    func pushNotificationRegistrationFailed(reason: String) {
        track("Push Notification Registration Failed", properties: ["reason": reason])
    }
    
    // MARK: - NIP-05 Usernames

    func showedNIP05Wizard() {
        track("Showed NIP-05 Wizard")
    }

    func registeredNIP05Username() {
        track("Registered NIP-05 Username")
    }

    func linkedNIP05Username() {
        track("Linked NIP-05 Username")
    }

    func deletedNIP05Username() {
        track("Deleted NIP-05 Username")
    }

    // MARK: - Message Actions

    func copiedNoteIdentifier() {
        track("Copied Note Identifier")
    }
    
    func sharedNoteLink() {
        track("Shared Note Link")
    }
    
    func copiedNoteText() {
        track("Copied Note Text")
    }
    
    func viewedNoteSource() {
        track("Viewed Note Source")
    }
    
    func deletedNote() {
        track("Deleted Note")
    }

    func likedNote() {
        track("Liked Note")
    }

    // MARK: - Uploads

    func selectedUploadFromCamera() {
        track("Selected Upload From Camera")
    }
    
    func selectedUploadFromPhotoLibrary() {
        track("Selected Upload From Photo Library")
    }
    
    func selectedImage() {
        track("Selected Image")
    }
    
    func cancelledImageSelection() {
        track("Cancelled Image Selection")
    }
    
    func cancelledUploadSourceSelection() {
        track("Cancelled Upload Source Selection")
    }

    func mentionsAutocompleteOpened() {
        track("Mentions Autocomplete Opened")
    }
    
    // MARK: - Feed Source
    
    /// Tracks when the user selects a list from the feed picker at the top of the home feed.
    func listFeedOpened() {
        track("List Feed Opened")
    }
    
    /// Tracks when the user selects a relay from the feed picker at the top of the home feed.
    func relayFeedOpened() {
        track("Relay Feed Opened")
    }
    
    /// Tracks when the user selects the Following feed at the top of the home feed.
    func followFeedOpened() {
        track("Follow Feed Opened")
    }
    
    /// Tracks when the user opens the ``FeedCustomizerView``.
    func feedCustomizerOpened() {
        track("Feed Customizer Opened")
    }
    
    /// Tracks when the user closes the ``FeedCustomizerView``.
    func feedCustomizerClosed() {
        track("Feed Customizer Closed")
    }
    
    /// Tracks when the user toggles on a list in the ``FeedCustomizerView``.
    func listPinned() {
        track("List Pinned")
    }
    
    /// Tracks when the user toggles off a list in the ``FeedCustomizerView``.
    func listUnpinned() {
        track("List Unpinned")
    }
    
    /// Tracks when the user toggles on a relay in the ``FeedCustomizerView``.
    func relayPinned() {
        track("Relay Pinned")
    }
    
    /// Tracks when the user toggles off a relay in the ``FeedCustomizerView``.
    func relayUnpinned() {
        track("Relay Unpinned")
    }
    
    // MARK: - Lists
    
    /// Tracks when the user creates a new list.
    func listCreated() {
        track("List Created")
    }
    
    /// Tracks when the user edits a list.
    /// - Parameter numberOfUsers: The number of users in the list.
    func listEdited(numberOfUsers: Int) {
        track(
            "List Edited",
            properties: ["Number of users": numberOfUsers]
        )
    }
}

extension Analytics {
    /// Tracks the event with the given properties in the analytics provider.
    /// Also calls ``CrashReporting/trackBreadcrumb(_:)`` to track this event as a breadcrumb in our crash reporter.
    /// - Parameters:
    ///   - eventName: The event name to track.
    ///   - properties: The properties to include with the event.
    private func track(_ eventName: String, properties: [String: Any] = [:]) {
        if properties.isEmpty {
            Log.info("Analytics: \(eventName)")
        } else {
            Log.info("Analytics: \(eventName): \(properties)")
        }
        postHog?.capture(eventName, properties: properties)

        crashReporting.trackBreadcrumb(eventName)
    }
}

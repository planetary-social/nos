//
//  Analytics.swift
//  Nos
//
//  Created by Matthew Lorentz on 3/7/23.
//

import PostHog
import Dependencies
import Logger
import Starscream

private enum AnalyticsKey: DependencyKey {
    static let liveValue = Analytics()
    static let testValue = Analytics(mock: true)
    static let previewValue = Analytics(mock: true)
}

extension DependencyValues {
    var analytics: Analytics {
        get { self[AnalyticsKey.self] }
        set { self[AnalyticsKey.self] = newValue }
    }
}

/// An object to manage analytics data, currently wired up to send data to PostHog and registered as a global
/// dependency using the Dependencies library.
class Analytics {

    private let postHog: PHGPostHog?

    required init(mock: Bool = false) {
        let apiKey = Bundle.main.infoDictionary?["POSTHOG_API_KEY"] as? String ?? ""
        if !mock && !apiKey.isEmpty {
            let configuration = PHGPostHogConfiguration(apiKey: apiKey, host: "https://posthog.planetary.tools")
            
            configuration.captureApplicationLifecycleEvents = true
            configuration.recordScreenViews = true
            // TODO: write screen views to log

            PHGPostHog.setup(with: configuration)
            postHog = PHGPostHog.shared()!
        } else {
            postHog = nil
        }
    }

    func published(note: Event) {
        track("Published Note", properties: ["length": note.content?.count ?? 0])
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
    
    func showedNewNote() {
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
    
    func changedKey() {
        track("Changed Private Key")
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
    
    func identify(with keyPair: KeyPair) {
        Log.info("Analytics: Identified \(keyPair.npub)")
        postHog?.identify(keyPair.npub)
    }
    
    func logout() {
        Log.info("Analytics: User logged out")
        postHog?.reset()
    }
    
    private func track(_ eventName: String, properties: [String: Any] = [:]) {
        Log.info("Analytics: \(eventName)")
        postHog?.capture(eventName, properties: properties)
    }
    
    // MARK: - Relays
    
    func rateLimited(by socket: WebSocket) {
        track("Rate Limited", properties: ["relay": socket.request.url?.absoluteString ?? "null"])
    }
}

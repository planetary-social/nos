//
//  Analytics.swift
//  Nos
//
//  Created by Matthew Lorentz on 3/7/23.
//

import PostHog
import Dependencies
import Logger

//protocol Analytics {
//    init()
//
//    func published(note: Event)
//}

private enum AnalyticsKey: DependencyKey {
    static let liveValue: Analytics = Analytics()
    static let testValue: Analytics = Analytics(mock: true)
    static let previewValue: Analytics = Analytics(mock: true)
}

extension DependencyValues {
    var analytics: Analytics {
        get { self[AnalyticsKey.self] }
        set { self[AnalyticsKey.self] = newValue }
    }
}

//class MockAnalytics: Analytics {
//    required init() {}
//    func published(note: Event) { }
//}
//
//class PostHogAnalytics: Analytics {
//
//    private let postHog: PHGPostHog
//
//    required init() {
//        // `host` is optional if you use PostHog Cloud (app.posthog.com)
//        let configuration = PHGPostHogConfiguration(apiKey: "<ph_project_api_key>", host: "<ph_instance_address>")
//
//        configuration.captureApplicationLifecycleEvents = true; // Record certain application events automatically!
//        configuration.recordScreenViews = true; // Record screen views automatically!
//
//        postHog = PHGPostHog(configuration: configuration)
//    }
//
//    func published(note: Event) {
//        postHog.capture("Published Note", properties: ["length": note.content?.count ?? 0])
//    }
//}

class Analytics {

    private let postHog: PHGPostHog

    required init(mock: Bool = false) {
        // `host` is optional if you use PostHog Cloud (app.posthog.com)
        var configuration: PHGPostHogConfiguration
        if mock {
            configuration = PHGPostHogConfiguration(apiKey: "none", host: "/dev/null")
        } else {
            configuration = PHGPostHogConfiguration(apiKey: "<ph_project_api_key>", host: "<ph_instance_address>")
        }

        configuration.captureApplicationLifecycleEvents = true; // Record certain application events automatically!
        configuration.recordScreenViews = true; // Record screen views automatically!

        PHGPostHog.setup(with: configuration)
        postHog = PHGPostHog.shared()!
    }

    func published(note: Event) {
        track("Published Note", properties: ["length": note.content?.count ?? 0])
    }
    
    private func track(_ eventName: String, properties: [String: Any]) {
        Log.info("Analytics: \(eventName)")
        postHog.capture(eventName, properties: properties)
    }
}

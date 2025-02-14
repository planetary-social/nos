import Foundation
import Logger
import Sentry

/// An abstraction of an external crash reporting service, like Sentry.io
final class CrashReporting {
    
    private let sentry: SentrySDK.Type
    
    init(mock: Bool = false) {
        sentry = SentrySDK.self
        let dsn = Bundle.main.infoDictionary?["SENTRY_DSN"] as? String ?? ""

        #if DEBUG
        let debug = true
        #else
        let debug = false
        #endif
        
        guard !mock && !debug && !dsn.isEmpty else {
            return
        }
        
        sentry.start { options in
            options.dsn = dsn
            #if STAGING
            options.environment = "staging"
            #elseif DEV
            options.environment = "debug"
            #endif
            // Enable all experimental features
            options.attachViewHierarchy = true
            options.enablePreWarmedAppStartTracing = true
            options.enableMetricKit = true
            options.enableTimeToFullDisplayTracing = true
            options.swiftAsyncStacktraces = true
        }
    }
    
    func identify(with keyPair: KeyPair) {
        let user = User(userId: keyPair.npub)
        sentry.setUser(user)
    }

    func report(_ error: Error) {
        Log.error("Reporting error to Crash Reporting service: \(error.localizedDescription)")
        sentry.capture(error: error)
    }
    
    func report(_ errorMessage: String) {
        Log.error("Reporting error to Crash Reporting service: \(errorMessage)")
        sentry.capture(message: errorMessage)
    }

    /// Adds a breadcrumb for the given event name for tracking in our error reporting tool (Sentry).
    /// - Parameter eventName: The event for which to add a breadcrumb.
    func trackBreadcrumb(_ eventName: String) {
        let crumb = Breadcrumb()
        crumb.level = SentryLevel.info
        crumb.category = "analytics"
        crumb.message = eventName
        SentrySDK.addBreadcrumb(crumb)
    }

    func logout() {
        SentrySDK.setUser(nil)
    }
}

//
//  CrashReporting.swift
//  Nos
//
//  Created by Matthew Lorentz on 8/18/23.
//

import Foundation
import Sentry

/// An abstraction of an external crash reporting service, like Sentry.io
class CrashReporting {
    
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
            
            options.enableTracing = true
            options.tracesSampleRate = 0.3 // tracing must be enabled for profiling
            options.profilesSampleRate = 0.3 // see also `profilesSampler` if you need custom sampling logic
            
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
        sentry.capture(error: error)
    }
    
    func logout() {
        SentrySDK.setUser(nil)
    }
}

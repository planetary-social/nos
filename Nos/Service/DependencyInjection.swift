//
//  DependencyInjection.swift
//  Nos
//
//  Created by Matthew Lorentz on 4/18/23.
//

import Dependencies
import Foundation

/// We use the Dependencies package to enable testability for our global variables. It is modeled after SwiftUI's
/// @Environment.
/// [Docs](https://pointfreeco.github.io/swift-dependencies/main/documentation/dependencies/)
extension DependencyValues {
    var analytics: Analytics {
        get { self[AnalyticsKey.self] }
        set { self[AnalyticsKey.self] = newValue }
    }
    
    var currentUser: CurrentUser {
        get { self[CurrentUserKey.self] }
        set { self[CurrentUserKey.self] = newValue }
    }
    
    var router: Router {
        get { self[RouterKey.self] }
        set { self[RouterKey.self] = newValue }
    }
    
    var relayService: RelayService {
        get { self[RelayServiceKey.self] }
        set { self[RelayServiceKey.self] = newValue }
    }
    
    var pushNotificationService: PushNotificationService {
        get { self[PushNotificationServiceKey.self] }
        set { self[PushNotificationServiceKey.self] = newValue }
    }
    
    var persistenceController: PersistenceController {
        get { self[PersistenceControllerKey.self] }
        set { self[PersistenceControllerKey.self] = newValue }
    }
    
    var userDefaults: UserDefaults {
        get { self[UserDefaultsKey.self] }
        set { self[UserDefaultsKey.self] = newValue }
    }
    
    var crashReporting: CrashReporting {
        get { self[CrashReportingKey.self] }
        set { self[CrashReportingKey.self] = newValue }
    }
}

fileprivate enum AnalyticsKey: DependencyKey {
    static let liveValue = Analytics()
    static let testValue = Analytics(mock: true)
    static let previewValue = Analytics(mock: true)
}

@MainActor private enum CurrentUserKey: DependencyKey {
    static let liveValue = CurrentUser()
    static let testValue = CurrentUser()
    static let previewValue = CurrentUser()
}

fileprivate enum RouterKey: DependencyKey {
    static let liveValue = Router()
    static let testValue = Router()
    static let previewValue = Router()
}

private enum RelayServiceKey: DependencyKey {
    static let liveValue = RelayService()
    static let testValue = RelayService()
    static let previewValue = RelayService()
}

@MainActor
fileprivate enum PushNotificationServiceKey: DependencyKey {
    typealias Value = PushNotificationService
    static let liveValue = PushNotificationService()
    static let testValue = MockPushNotificationService()
    static let previewValue = MockPushNotificationService()
}

fileprivate enum PersistenceControllerKey: DependencyKey {
    static let liveValue = PersistenceController()
    static let testValue = PersistenceController(inMemory: true)
    static let previewValue = PersistenceController(inMemory: true)
}

fileprivate enum UserDefaultsKey: DependencyKey {
    static let liveValue = UserDefaults.standard
    static let testValue = UserDefaults()
    static let previewValue = UserDefaults()
}

fileprivate enum CrashReportingKey: DependencyKey {
    static let liveValue = CrashReporting()
    static let testValue = CrashReporting(mock: true)
    static let previewValue = CrashReporting(mock: true)
}

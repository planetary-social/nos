//
//  DependencyInjection.swift
//  Nos
//
//  Created by Matthew Lorentz on 4/18/23.
//

import Dependencies

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
}

private enum AnalyticsKey: DependencyKey {
    static let liveValue = Analytics()
    static let testValue = Analytics(mock: true)
    static let previewValue = Analytics(mock: true)
}

private enum CurrentUserKey: DependencyKey {
    static let liveValue = CurrentUser.shared
    static let testValue = CurrentUser.shared
    static let previewValue = CurrentUser.shared
}

private enum RouterKey: DependencyKey {
    static let liveValue = Router()
    static let testValue = Router()
    static let previewValue = Router()
}

private enum RelayServiceKey: DependencyKey {
    static let liveValue = RelayService(persistenceController: PersistenceController.shared)
    static let testValue = RelayService(persistenceController: PersistenceController.shared)
    static let previewValue = RelayService(persistenceController: PersistenceController.shared)
}

@MainActor
private enum PushNotificationServiceKey: DependencyKey {
    typealias Value = PushNotificationService
    static let liveValue = PushNotificationService()
    static let testValue = MockPushNotificationService()
    static let previewValue = MockPushNotificationService()
}

private enum PersistenceControllerKey: DependencyKey {
    static let liveValue = PersistenceController.shared
    static let testValue = PersistenceController.preview
    static let previewValue = PersistenceController.preview
}

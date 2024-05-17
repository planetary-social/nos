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
    
    var unsAPI: UNSAPI {
        get { self[UNSAPIKey.self] }
        set { self[UNSAPIKey.self] = newValue }
    }

    var namesAPI: NamesAPI {
        get { self[NamesAPIKey.self] }
        set { self[NamesAPIKey.self] = newValue }
    }

    var urlParser: URLParser {
        get { self[URLParserKey.self] }
        set { self[URLParserKey.self] = newValue }
    }

    var noteParser: NoteParser {
        get { self[NoteParserKey.self] }
        set { self[NoteParserKey.self] = newValue }
    }
}

fileprivate enum AnalyticsKey: DependencyKey {
    static let liveValue = Analytics()
    static let testValue = Analytics(mock: true)
    static let previewValue = Analytics(mock: true)
}

private enum CurrentUserKey: DependencyKey {
    @MainActor static let liveValue = CurrentUser()
    @MainActor static let testValue = CurrentUser()
    @MainActor static let previewValue = CurrentUser()
}

fileprivate enum RouterKey: DependencyKey {
    @MainActor static let liveValue = Router()
    @MainActor static let testValue = Router()
    @MainActor static let previewValue = Router()
}

private enum RelayServiceKey: DependencyKey {
    static let liveValue = RelayService()
    static let testValue = RelayService()
    static let previewValue = RelayService()
}

fileprivate enum PushNotificationServiceKey: DependencyKey {
    typealias Value = PushNotificationService
    @MainActor static let liveValue = PushNotificationService()
    @MainActor static let testValue = MockPushNotificationService()
    @MainActor static let previewValue = MockPushNotificationService()
}

fileprivate enum PersistenceControllerKey: DependencyKey {
    static let liveValue = PersistenceController()
    static var testValue = PersistenceController(inMemory: true)
    static let previewValue = testValue // context needs to be the same for both
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

fileprivate enum UNSAPIKey: DependencyKey {
    static let liveValue = UNSAPI()!
}

fileprivate enum NamesAPIKey: DependencyKey {
    static let liveValue = NamesAPI()!
    static let previewValue = NamesAPI(host: "localhost")!
}

fileprivate enum URLParserKey: DependencyKey {
    static let liveValue = URLParser()
    static let testValue = URLParser()
    static let previewValue = URLParser()
}

fileprivate enum NoteParserKey: DependencyKey {
    static let liveValue = NoteParser()
    static let testValue = NoteParser()
    static let previewValue = NoteParser()
}

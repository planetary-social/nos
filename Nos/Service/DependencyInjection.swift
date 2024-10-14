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

    var fileStorageAPIClient: FileStorageAPIClient {
        get { self[FileStorageAPIClientKey.self] }
        set { self[FileStorageAPIClientKey.self] = newValue }
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

    var urlSession: URLSessionProtocol {
        get { self[URLSessionProtocolKey.self] }
        set { self[URLSessionProtocolKey.self] = newValue }
    }

    var noteParser: NoteParser {
        get { self[NoteParserKey.self] }
        set { self[NoteParserKey.self] = newValue }
    }

    var featureFlags: FeatureFlags {
        get { self[FeatureFlagsKey.self] }
        set { self[FeatureFlagsKey.self] = newValue }
    }

    var keychain: Keychain {
        get { self[KeychainKey.self] }
        set { self[KeychainKey.self] = newValue }
    }

    var mediaService: MediaService {
        get { self[MediaServiceKey.self] }
        set { self[MediaServiceKey.self] = newValue }
    }

    var openGraphService: OpenGraphService {
        get { self[OpenGraphServiceKey.self] }
        set { self[OpenGraphServiceKey.self] = newValue }
    }

    var previewEventRepository: PreviewEventRepository {
        get { self[PreviewEventRepositoryKey.self] }
        set { self[PreviewEventRepositoryKey.self] = newValue }
    }
}

private enum AnalyticsKey: DependencyKey {
    static let liveValue = Analytics()
    static let testValue = Analytics(mock: true)
    static let previewValue = Analytics(mock: true)
}

private enum CurrentUserKey: DependencyKey {
    @MainActor static let liveValue = CurrentUser()
    @MainActor static let testValue = CurrentUser()
    @MainActor static let previewValue = CurrentUser()
}

private enum FileStorageAPIClientKey: DependencyKey {
    static var liveValue: any FileStorageAPIClient = NostrBuildAPIClient()
}

private enum RouterKey: DependencyKey {
    @MainActor static let liveValue = Router()
    @MainActor static let testValue = Router()
    @MainActor static let previewValue = Router()
}

private enum RelayServiceKey: DependencyKey {
    static let liveValue = RelayService()
    static let testValue: RelayService = MockRelayService()
    static let previewValue: RelayService = MockRelayService()
}

private enum PushNotificationServiceKey: DependencyKey {
    @MainActor static let liveValue = PushNotificationService()
    @MainActor static let testValue: PushNotificationService = MockPushNotificationService()
    @MainActor static let previewValue: PushNotificationService = MockPushNotificationService()
}

private enum PersistenceControllerKey: DependencyKey {
    static let liveValue = PersistenceController()
    static var testValue = PersistenceController(inMemory: true)
    static let previewValue = PersistenceController(inMemory: true)
}

private enum UserDefaultsKey: DependencyKey {
    static let liveValue = UserDefaults.standard
    static let testValue = UserDefaults()
    static let previewValue = UserDefaults()
}

private enum CrashReportingKey: DependencyKey {
    static let liveValue = CrashReporting()
    static let testValue = CrashReporting(mock: true)
    static let previewValue = CrashReporting(mock: true)
}

private enum UNSAPIKey: DependencyKey {
    static let liveValue = UNSAPI()!
}

private enum NamesAPIKey: DependencyKey {
    static let liveValue = NamesAPI()!
    static let previewValue = NamesAPI(host: "localhost")!
}

private enum URLParserKey: DependencyKey {
    static let liveValue = URLParser()
    static let testValue = URLParser()
    static let previewValue = URLParser()
}

private enum URLSessionProtocolKey: DependencyKey {
    static let liveValue: any URLSessionProtocol = URLSession.shared
    static let testValue: any URLSessionProtocol = MockURLSession()
    static let previewValue: any URLSessionProtocol = MockURLSession()
}

private enum NoteParserKey: DependencyKey {
    static let liveValue = NoteParser()
    static let testValue = NoteParser()
    static let previewValue = NoteParser()
}

private enum FeatureFlagsKey: DependencyKey {
    static let liveValue: any FeatureFlags = DefaultFeatureFlags.liveValue
    static let testValue: any FeatureFlags = MockFeatureFlags()
    static let previewValue: any FeatureFlags = MockFeatureFlags()
}

private enum KeychainKey: DependencyKey {
    @MainActor static let liveValue: Keychain = SystemKeychain()
    @MainActor static let testValue: Keychain = InMemoryKeychain()
    @MainActor static let previewValue: Keychain = InMemoryKeychain()
}

private enum MediaServiceKey: DependencyKey {
    static let liveValue: any MediaService = DefaultMediaService()
    static let testValue: any MediaService = MockMediaService()
    static let previewValue: any MediaService = DefaultMediaService()  // enables manual testing with previews
}

private enum OpenGraphServiceKey: DependencyKey {
    static let liveValue: any OpenGraphService = DefaultOpenGraphService()
    static let testValue: any OpenGraphService = MockOpenGraphService()
    static let previewValue: any OpenGraphService = DefaultOpenGraphService()  // enables manual testing with previews
}

private enum PreviewEventRepositoryKey: DependencyKey {
    static let liveValue: any PreviewEventRepository = DefaultPreviewEventRepository()
}

import Combine
import Dependencies
import Foundation
import SensitiveContentAnalysis

extension SCSensitivityAnalysisPolicy {
    var description: String {
        // TODO: Localize
        switch self {
        case .disabled:
            "Sensitive Content Analysis is currently disabled. To enable, go to Settings app -> Privacy & Security -> \"Sensitive Content Warning\"." // swiftlint:disable:this line_length
        default:
            "Sensitive Content Analysis is currently enabled. To disable, go to Settings app -> Privacy & Security -> \"Sensitive Content Warning\"." // swiftlint:disable:this line_length
        }
    }
}

/// An object that analyzes images for nudity and manages and publishes related state.
///
/// > Note: This object is a Swift actor because many images may be analyzed simultaneously, and the analysis state
///         cache needs to be read from and written to with isolated access.
actor SensitiveContentController: FileDownloading {
    
    @Dependency(\.featureFlags) private var featureFlags
    
    /// The state of analysis of content at a given file URL.
    enum AnalysisState: Equatable {
        /// The content is currently being analyzed by the system.
        case analyzing
        /// The content has been analyzed. The associated Bool indicates whether the content has been deemed sensitive.
        case analyzed(Bool) // true == sensitive
        /// The content has been explicitly allowed by the user.
        case allowed
        
        var shouldObfuscate: Bool {
            switch self {
            case .analyzing: true
            case .analyzed(let isSensitive):
                isSensitive
            case .allowed: false
            }
        }
    }
    
    static let shared = SensitiveContentController()
    
    private var cache = [String: AnalysisState]()
    
    private var publishers = [String: CurrentValueSubject<AnalysisState, Never>]()
    
    private let analyzer = SCSensitivityAnalyzer()
    
    /// Indicates whether sensitivity analysis can be performed.
    nonisolated var isSensitivityAnalysisEnabled: Bool {
        analyzer.analysisPolicy != .disabled
    }
    
    /// Analyzes content at the provided URL for nudity.
    /// - Parameter url: The URL to get the content from.
    func analyzeContent(atURL url: URL) async {
        guard isSensitivityAnalysisEnabled && url.isImage else {
            return  // the content cannot be analyzed
        }
        
        if cache[url.absoluteString] != nil {
            return  // the content is already being analyzed
        }
        
        do {
            #if DEBUG
            let shouldOverrideAnalyzer = featureFlags.isEnabled(.sensitiveContentFlagAllAsSensitive)
            if shouldOverrideAnalyzer {
                try await Task.sleep(nanoseconds: 1 * 1_000_000_000)    // simulate time to analyze
                updateState(.analyzed(true), for: url)
                return
            }
            #endif
            
            let fileURLToAnalyze = url.isFileURL ? url : try await file(byDownloadingFrom: url)
            let result = try await analyzer.analyzeImage(at: fileURLToAnalyze)
            updateState(.analyzed(result.isSensitive), for: url)
        } catch {
            print("⚠️ SensitiveContentController: Failed to analyze content at \(url): \(error)")
        }
    }
    
    /// Marks content at a provided URL as allowed.
    /// - Parameter url: The URL to mark as allowed.
    func allowContent(at url: URL) {
        updateState(.allowed, for: url)
    }
    
    /// Analyzes content the user wants to upload for nudity.
    /// - Parameter fileURL: The file URL to analyze.
    /// - Returns: True if the content is sensitive.
    func shouldWarnUserUploadingFile(at fileURL: URL) async -> Bool {
        guard isSensitivityAnalysisEnabled else {
            return false
        }
        
        #if DEBUG
        let shouldOverrideAnalyzer = featureFlags.isEnabled(.sensitiveContentFlagAllAsSensitive)
        if shouldOverrideAnalyzer {
            try? await Task.sleep(nanoseconds: 250_000_000) // simulate time to analyze
            updateState(.analyzed(true), for: fileURL)
            return true
        }
        #endif
        
        do {
            let result = try await analyzer.analyzeImage(at: fileURL)
            return result.isSensitive
        } catch {
            return false
        }
    }
    
    /// A publisher for a listener to monitor for analysis state changes for a given URL.
    /// - Parameter url: The URL to monitor state on.
    /// - Returns: The requested publisher.
    func analysisStatePublisher(for url: URL) -> AnyPublisher<AnalysisState, Never> {
        if let publisher = publishers[url.absoluteString] {
            return publisher.eraseToAnyPublisher()
        } else {
            let publisher = CurrentValueSubject<AnalysisState, Never>(.analyzing)
            publishers[url.absoluteString] = publisher
            cache[url.absoluteString] = .analyzing
            return publisher.eraseToAnyPublisher()
        }
    }

    /// Updates the analysis state for a provided URL.
    /// - Parameters:
    ///   - url: The URL for which to update state.
    ///   - newState: The state to update to.
    ///
    /// The state is cached locally and published to listeners.
    private func updateState(_ state: AnalysisState, for url: URL) {
        cache[url.absoluteString] = state
        if let publisher = publishers[url.absoluteString] {
            publisher.send(state)
        } else {
            let publisher = CurrentValueSubject<AnalysisState, Never>(state)
            publishers[url.absoluteString] = publisher
        }
    }
}

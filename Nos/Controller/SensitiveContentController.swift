import Combine
import Dependencies
import Foundation
import SensitiveContentAnalysis

protocol FileDownloading {}
extension FileDownloading {
    
    func file(byDownloadingFrom url: URL) async throws -> URL {
        let temporaryDirectory = FileManager.default.temporaryDirectory
        let fileURL = temporaryDirectory.appendingPathComponent(url.lastPathComponent)
        let (data, _) = try await URLSession.shared.data(from: url)
        try data.write(to: fileURL)
        return fileURL
    }
}

extension SCSensitivityAnalysisPolicy {
    var description: String {
        switch self {
        case .disabled:
            "Sensitive Content Analysis is currently disabled. To enable, go to Settings app -> Privacy & Security -> \"Sensitive Content Warning\"." // swiftlint:disable:this line_length
        default:
            "Sensitive Content Analysis is currently enabled. To disable, go to Settings app -> Privacy & Security -> \"Sensitive Content Warning\"." // swiftlint:disable:this line_length
        }
    }
}

actor SensitiveContentController: FileDownloading {
    
    @Dependency(\.featureFlags) private var featureFlags
    
    enum AnalysisState: Equatable {
        case analyzing
        case analyzed(Bool) // true == sensitive
        case allowed        // user has okay'ed this content already
        
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
    
    nonisolated var isSensitivityAnalysisEnabled: Bool {
        analyzer.analysisPolicy != .disabled
    }
    
    @discardableResult
    func shouldObfuscateContent(atURL url: URL) async -> Bool {
        assert(!url.isFileURL)
        
        guard isSensitivityAnalysisEnabled && url.isImage else {
            return false
        }
        
        if let analysisState = cache[url.absoluteString] {
            return analysisState.shouldObfuscate
        }
        
        do {
            let tempFileURL = try await file(byDownloadingFrom: url)
            
            #if DEBUG
            let shouldOverrideAnalyzer = featureFlags.isEnabled(.sensitiveContentIncoming)
            if shouldOverrideAnalyzer {
                try await Task.sleep(nanoseconds: 1 * 1_000_000_000)    // simulate time to analyze
                updateState(for: url, to: .analyzed(true))
                return true
            }
            #endif
            
            let result = try await analyzer.analyzeImage(at: tempFileURL)
            updateState(for: url, to: .analyzed(result.isSensitive))
            return result.isSensitive
        } catch {
            return false
        }
    }
    
    func allowContent(at url: URL) {
        updateState(for: url, to: .allowed)
    }
    
    func shouldWarnUserUploadingFile(at fileURL: URL) async -> Bool {
        guard isSensitivityAnalysisEnabled else {
            return false
        }
        
        #if DEBUG
        let shouldOverrideAnalyzer = featureFlags.isEnabled(.sensitiveContentOutgoing)
        if shouldOverrideAnalyzer {
            try? await Task.sleep(nanoseconds: 250_000_000) // simulate time to analyze
            updateState(for: fileURL, to: .analyzed(true))
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
    
    func publisher(for url: URL) -> AnyPublisher<AnalysisState, Never> {
        if let publisher = publishers[url.absoluteString] {
            return publisher.eraseToAnyPublisher()
        } else {
            let publisher = CurrentValueSubject<AnalysisState, Never>(.analyzing)
            publishers[url.absoluteString] = publisher
            cache[url.absoluteString] = .analyzing
            return publisher.eraseToAnyPublisher()
        }
    }

    private func updateState(for url: URL, to newState: AnalysisState) {
        cache[url.absoluteString] = newState
        if let publisher = publishers[url.absoluteString] {
            publisher.send(newState)
        } else {
            let publisher = CurrentValueSubject<AnalysisState, Never>(newState)
            publishers[url.absoluteString] = publisher
        }
    }
}

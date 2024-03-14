import Foundation
import Logger

enum LogHelper {
    static func zipLogs() async throws -> URL {
        let appFileUrls = Log.fileUrls
        let temporaryDirectory = URL(fileURLWithPath: NSTemporaryDirectory())
        let url = temporaryDirectory.appendingPathComponent(UUID().uuidString)
        return try await Task {
            try FileManager.default.createDirectory(at: url, withIntermediateDirectories: false)
            let zipFileURL = temporaryDirectory.appendingPathComponent("\(UUID().uuidString).zip")
            let copy = { (appFileURL: URL) throws in
                let destFileURL = url.appendingPathComponent(appFileURL.lastPathComponent)
                try FileManager.default.copyItem(at: appFileURL, to: destFileURL)
            }
            
            try appFileUrls.forEach { try copy($0) }
            
            let coord = NSFileCoordinator()
            var readError: NSError?
            return try await withCheckedThrowingContinuation { continuation in
                coord.coordinate(
                    readingItemAt: url, 
                    options: .forUploading, 
                    error: &readError
                ) { (zippedURL: URL) -> Void in
                    do {
                        try FileManager.default.copyItem(at: zippedURL, to: zipFileURL)
                        continuation.resume(with: .success(zipFileURL))
                    } catch {
                        continuation.resume(with: .failure(error))
                    }
                }
            }
        }.value
    }
}

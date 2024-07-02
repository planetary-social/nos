import Foundation
import Logger

/// An error that may be thrown by `Zipper`.
enum ZipperError: Error {
    /// The file to zip was not found.
    case fileNotFound
}

/// A utility that knows how to zip.
enum Zipper {
    /// Zips the log files.
    /// - Returns: The file URL of the zip.
    static func zipLogs() async throws -> URL {
        try await zipFiles(Log.fileUrls)
    }

    /// Zips the SQLite database of the given persistence controller.
    /// - Parameter controller: The persistence controller that contains the SQLite database.
    /// - Returns: The file URL of the zipped database.
    static func zipDatabase(controller: PersistenceController) async throws -> URL {
        guard let sqliteURL = controller.sqliteURL else {
            throw ZipperError.fileNotFound
        }
        return try await zipFiles([sqliteURL])
    }
    
    /// Zips the files at the given URLs.
    /// - Parameter fileURLs: the URLs of the files to zip.
    /// - Returns: The file URL of the zip.
    static func zipFiles(_ fileURLs: [URL]) async throws -> URL {
        let temporaryDirectory = URL(fileURLWithPath: NSTemporaryDirectory())
        let url = temporaryDirectory.appendingPathComponent(UUID().uuidString)
        return try await Task {
            try FileManager.default.createDirectory(at: url, withIntermediateDirectories: false)
            let zipFileURL = temporaryDirectory.appendingPathComponent("\(UUID().uuidString).zip")
            let copy = { (appFileURL: URL) throws in
                let destFileURL = url.appendingPathComponent(appFileURL.lastPathComponent)
                try FileManager.default.copyItem(at: appFileURL, to: destFileURL)
            }
            
            try fileURLs.forEach { try copy($0) }

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

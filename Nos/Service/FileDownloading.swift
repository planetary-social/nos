import Foundation

/// Adds file downloading capability to any type.
protocol FileDownloading {}
extension FileDownloading {
    
    /// Downloads a file asynchronously to a temporary directory.
    /// - Parameter url: The URL to download content from.
    /// - Returns: A file URL pointing to the downloaded content.
    func file(byDownloadingFrom url: URL) async throws -> URL {
        let temporaryDirectory = FileManager.default.temporaryDirectory
        let fileURL = temporaryDirectory.appendingPathComponent(url.lastPathComponent)
        let (data, _) = try await URLSession.shared.data(from: url)
        try data.write(to: fileURL)
        return fileURL
    }
}

import AVFoundation
import Foundation
import LinkPresentation
import SDWebImage

/// Determines the preferred ``MediaOrientation`` for a given `URL`.
protocol MediaService {
    /// Returns the preferred orientation for the media at the given URL.
    /// - Parameter url: The URL of the media.
    /// - Returns: The preferred orientation for the media at the given URL.
    /// - Note: For images, the orientation will match the image when possible. For square images, `landscape` is
    ///         returned. For web pages, `landscape` is returned. For videos, we're returning `portrait` until we
    ///         implement [#1425](https://github.com/planetary-social/nos/issues/1425)
    func orientation(for url: URL) async -> MediaOrientation
}

/// Loads media to determine its preferred ``MediaOrientation``.
struct DefaultMediaService: MediaService {

    // MARK: - MediaService protocol

    func orientation(for url: URL) async -> MediaOrientation {
        if url.isImage {
            return await imageOrientation(url: url)
        } else {
            return await videoOrWebPageOrientation(url: url)
        }
    }

    // MARK: - Private

    /// Loads the image at the given URL and returns its orientation.
    /// - Parameter url: The URL of the image to download.
    /// - Returns: The orientation of the image, or `.landscape` if it's square.
    /// - Note: If the image is square or its dimensions can't be determined, returns `.landscape` as a default
    ///         since we only support `.portait` and `.landscape` for the gallery view.
    private func imageOrientation(url: URL) async -> MediaOrientation {
        await withCheckedContinuation { continuation in
            SDWebImageDownloader().downloadImage(with: url) { image, _, _, _ in
                if let image, image.size.height > image.size.width {
                    continuation.resume(returning: .portrait)
                } else {
                    continuation.resume(returning: .landscape)
                }
            }
        }
    }

    /// Loads the content at the given URL and returns its orientation.
    /// - Parameter url: The URL of the data to download.
    /// - Returns: The orientation of the content.
    /// - Note: For web pages, `landscape` is returned. For videos, we're returning `portrait` until we implement
    ///         [#1425](https://github.com/planetary-social/nos/issues/1425)
    private func videoOrWebPageOrientation(url: URL) async -> MediaOrientation {
        let provider = LPMetadataProvider()
        let metadata = try? await provider.startFetchingMetadata(for: url)

        guard let metadata else {
            return .landscape
        }

        if metadata.videoProvider != nil || metadata.remoteVideoURL != nil {
            return .portrait
        } else {
            return .landscape
        }
    }
}

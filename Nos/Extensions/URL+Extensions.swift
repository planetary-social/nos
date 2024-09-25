import Foundation

extension URL {

    /// Returns the URL with the scheme "https" if the URL doesn't have a scheme; othewise, returns self.
    /// Using a URL with a scheme fixes an issue with opening link previews when there's no scheme.
    /// - Returns: The URL with the scheme "https" if the URL doesn't have a scheme; otherwise, returns self.
    func addingSchemeIfNeeded() -> URL {
        guard scheme == nil else {
            return self
        }

        return URL(string: "https://\(absoluteString)") ?? self
    }
    
    /// Returns `true` if the URL is an image, as determined by the path extension.
    /// Currently supports `png`, `jpg`, `jpeg`, and `gif`. For all other path extensions, returns `false`.
    var isImage: Bool {
        let imageExtensions = ["png", "jpg", "jpeg", "gif", "webp"]
        return imageExtensions.contains(pathExtension.lowercased())
    }
    
    /// Returns `true` if the URL is a GIF, as determined by the path extension.
    var isGIF: Bool {
        pathExtension.lowercased() == "gif" || pathExtension.lowercased() == "webp"
    }
    
    /// Returns `absoluteString` but without a trailing slash if one exists. If no trailing slash exists, returns
    /// `absoluteString` as-is.
    /// - Returns: The absolute string of the URL without a trailing slash.
    func strippingTrailingSlash() -> String {
        var string = absoluteString
        if string.last == "/" {
            string.removeLast()
        }
        return string
    }
    
    /// Returns a Markdown-formatted link that can be used for display. The display portion of the Markdown string will
    /// not contain the URL scheme, path, or path extension. In place of the path and path extension, an ellipsis will
    /// appear. For example, with a URL like `https://www.nos.social/about`, this will return
    /// `"[nos.social...](https://www.nos.social/about)"`.
    var truncatedMarkdownLink: String {
        let url = self.addingSchemeIfNeeded()

        guard var host = url.host() else {
            return "[\(url.absoluteString)](\(url.absoluteString))"
        }
        
        if host.hasPrefix("www.") {
            host = String(host.dropFirst(4))
        }
        
        if url.path().isEmpty {
            return "[\(host)](\(url.absoluteString))"
        } else {
            return "[\(host)...](\(url.absoluteString))"
        }
    }
}

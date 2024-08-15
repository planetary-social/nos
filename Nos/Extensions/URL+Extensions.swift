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

    var isImage: Bool {
        let imageExtensions = ["png", "jpg", "jpeg", "gif"]
        return imageExtensions.contains(pathExtension)
    }
    
    func strippingTrailingSlash() -> String {
        var string = absoluteString
        if string.last == "/" {
            string.removeLast()
        }
        return string
    }
    
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
    
    var isValidNoteLink: Bool {
        absoluteString.hasPrefix("%") && String(absoluteString.dropFirst()).isValidHexadecimal
    }
}

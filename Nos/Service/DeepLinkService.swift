import Foundation
import Logger

enum DeepLinkService {
    
    static let nosURLScheme = "nos"
    
    @MainActor static func handle(_ url: URL, router: Router) {
        Log.info("handling link \(url.absoluteString)")
        
        let components = URLComponents(url: url, resolvingAgainstBaseURL: true)
        
        guard let components else {
            return
        }
        
        if components.scheme == nosURLScheme, components.host == "note", components.path == "/new" {
            let noteContents = components
                .queryItems?
                .first(where: { $0.name == "contents" })?
                .value
            
            router.showNewNoteView(contents: noteContents)
        }
    }
}
